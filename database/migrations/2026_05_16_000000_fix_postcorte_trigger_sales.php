<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $postcorteExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='postcorte' LIMIT 1"
        );

        if (! $postcorteExists) {
            return;
        }

        // Add missing columns safely for PG 9.5
        DB::unprepared('
            DO $$ BEGIN
                BEGIN ALTER TABLE selemti.postcorte ADD COLUMN total_ventas_brutas NUMERIC(12,2) DEFAULT 0; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.postcorte ADD COLUMN total_descuentos_reales NUMERIC(12,2) DEFAULT 0; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.postcorte ADD COLUMN total_ventas_netas NUMERIC(12,2) DEFAULT 0; EXCEPTION WHEN duplicate_column THEN NULL; END;
            END $$;
        ');

        // Create or replace the corrected trigger function
        DB::unprepared("
            CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
            RETURNS TRIGGER AS $$
            DECLARE
                v_apertura_ts   TIMESTAMPTZ;
                v_cierre_ts     TIMESTAMPTZ;
                v_terminal_id   INT;
                v_ventas_brutas NUMERIC(12,2) := 0;
                v_descuentos    NUMERIC(12,2) := 0;
                v_ventas_netas  NUMERIC(12,2) := 0;
            BEGIN
                -- 1. Get session data first to avoid RETURNING issues
                SELECT apertura_ts, cierre_ts, terminal_id
                INTO v_apertura_ts, v_cierre_ts, v_terminal_id
                FROM selemti.sesion_cajon
                WHERE id = NEW.sesion_id;
            
                -- If the session wasn't closed yet, use now() for the close time in our queries
                IF v_cierre_ts IS NULL THEN
                    v_cierre_ts := now();
                END IF;
            
                -- 2. Close the session
                UPDATE selemti.sesion_cajon
                SET estatus   = 'CERRADA',
                    cierre_ts = v_cierre_ts
                WHERE id = NEW.sesion_id;
            
                -- 3. Aggregate sales from POS tickets (READ ONLY from public.ticket)
                SELECT
                    COALESCE(SUM(sub_total), 0),
                    COALESCE(SUM(total_discount), 0),
                    COALESCE(SUM(total_price), 0)
                INTO v_ventas_brutas, v_descuentos, v_ventas_netas
                FROM public.ticket
                WHERE terminal_id = v_terminal_id
                  AND create_date >= (v_apertura_ts - interval '1 hour')
                  AND create_date <= (v_cierre_ts + interval '2 hours')
                  AND voided = false;
            
                -- 4. Update totals on the postcorte row (WRITE to selemti.postcorte)
                UPDATE selemti.postcorte
                SET total_ventas_brutas     = v_ventas_brutas,
                    total_descuentos_reales = v_descuentos,
                    total_ventas_netas      = v_ventas_netas
                WHERE id = NEW.id;
            
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        // Re-attach the trigger safely
        DB::unprepared('
            DROP TRIGGER IF EXISTS trg_postcorte_after_insert ON selemti.postcorte;
            CREATE TRIGGER trg_postcorte_after_insert
            AFTER INSERT ON selemti.postcorte
            FOR EACH ROW
            EXECUTE PROCEDURE selemti.fn_postcorte_after_insert();
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $postcorteExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='postcorte' LIMIT 1"
        );

        if (! $postcorteExists) {
            return;
        }

        // Revert to the buggy trigger version
        DB::unprepared("
            CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
            RETURNS TRIGGER AS $$
            BEGIN
              UPDATE selemti.sesion_cajon
              SET estatus = 'CERRADA',
                  cierre_ts = COALESCE(cierre_ts, now())
              WHERE id = NEW.sesion_id;
              RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");
    }
};
