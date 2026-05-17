<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Creates the Caja/Cortes tables that exist in production but were never in Laravel migrations.
 * Source: database/BD_SCHEMA_SELEMTI.sql
 * Tables: sesion_cajon, precorte, precorte_efectivo, precorte_otros, postcorte, conciliacion
 */
return new class extends Migration
{
    public function up(): void
    {
        $this->createIfNotExists('sesion_cajon', "
            CREATE TABLE selemti.sesion_cajon (
                id          BIGSERIAL PRIMARY KEY,
                sucursal    TEXT,
                terminal_id INTEGER NOT NULL,
                terminal_nombre TEXT,
                cajero_usuario_id INTEGER NOT NULL,
                apertura_ts TIMESTAMPTZ DEFAULT now() NOT NULL,
                cierre_ts   TIMESTAMPTZ,
                estatus     TEXT DEFAULT 'ACTIVA' NOT NULL,
                opening_float NUMERIC(12,2) DEFAULT 0 NOT NULL,
                closing_float NUMERIC(12,2),
                dah_evento_id INTEGER,
                skipped_precorte BOOLEAN DEFAULT false NOT NULL,
                CONSTRAINT sesion_cajon_estatus_check CHECK (estatus IN (
                    'ACTIVA','LISTO_PARA_CORTE','EN_CORTE','CERRADA','CONCILIADA','OBSERVADA'
                ))
            )
        ");

        $this->createIfNotExists('precorte', "
            CREATE TABLE selemti.precorte (
                id          BIGSERIAL PRIMARY KEY,
                sesion_id   BIGINT NOT NULL REFERENCES selemti.sesion_cajon(id),
                declarado_efectivo NUMERIC(12,2) DEFAULT 0 NOT NULL,
                declarado_otros    NUMERIC(12,2) DEFAULT 0 NOT NULL,
                estatus     TEXT DEFAULT 'PENDIENTE' NOT NULL,
                creado_en   TIMESTAMPTZ DEFAULT now() NOT NULL,
                creado_por  INTEGER,
                ip_cliente  INET,
                notas       TEXT,
                CONSTRAINT precorte_estatus_check CHECK (estatus IN ('PENDIENTE','ENVIADO','APROBADO','RECHAZADO'))
            )
        ");

        // Unique constraint so fn_generar_postcorte can use ON CONFLICT(sesion_id)
        DB::connection('pgsql')->statement("
            DO \$\$ BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'uq_precorte_sesion_id'
                    AND conrelid = 'selemti.precorte'::regclass
                ) THEN
                    ALTER TABLE selemti.precorte ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);
                END IF;
            END \$\$
        ");

        $this->createIfNotExists('precorte_efectivo', "
            CREATE TABLE selemti.precorte_efectivo (
                id           BIGSERIAL PRIMARY KEY,
                precorte_id  BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
                denominacion NUMERIC(12,2) NOT NULL,
                cantidad     INTEGER NOT NULL,
                subtotal     NUMERIC(12,2) DEFAULT 0 NOT NULL
            )
        ");

        $this->createIfNotExists('precorte_otros', "
            CREATE TABLE selemti.precorte_otros (
                id          BIGSERIAL PRIMARY KEY,
                precorte_id BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
                tipo        TEXT NOT NULL,
                monto       NUMERIC(12,2) DEFAULT 0 NOT NULL,
                referencia  TEXT,
                evidencia_url TEXT,
                notas       TEXT,
                creado_en   TIMESTAMPTZ DEFAULT now() NOT NULL
            )
        ");

        $this->createIfNotExists('postcorte', "
            CREATE TABLE selemti.postcorte (
                id          BIGSERIAL PRIMARY KEY,
                sesion_id   BIGINT NOT NULL REFERENCES selemti.sesion_cajon(id),
                sistema_efectivo_esperado  NUMERIC(12,2) DEFAULT 0 NOT NULL,
                declarado_efectivo         NUMERIC(12,2) DEFAULT 0 NOT NULL,
                diferencia_efectivo        NUMERIC(12,2) DEFAULT 0 NOT NULL,
                veredicto_efectivo         TEXT DEFAULT 'CUADRA' NOT NULL,
                sistema_tarjetas           NUMERIC(12,2) DEFAULT 0 NOT NULL,
                declarado_tarjetas         NUMERIC(12,2) DEFAULT 0 NOT NULL,
                diferencia_tarjetas        NUMERIC(12,2) DEFAULT 0 NOT NULL,
                veredicto_tarjetas         TEXT DEFAULT 'CUADRA' NOT NULL,
                sistema_transferencias     NUMERIC(12,2) DEFAULT 0 NOT NULL,
                declarado_transferencias   NUMERIC(12,2) DEFAULT 0 NOT NULL,
                diferencia_transferencias  NUMERIC(12,2) DEFAULT 0 NOT NULL,
                veredicto_transferencias   TEXT DEFAULT 'CUADRA' NOT NULL,
                total_ventas_brutas        NUMERIC(12,2) DEFAULT 0,
                total_descuentos_reales    NUMERIC(12,2) DEFAULT 0,
                total_ventas_netas         NUMERIC(12,2) DEFAULT 0,
                creado_en   TIMESTAMPTZ DEFAULT now() NOT NULL,
                creado_por  INTEGER,
                notas       TEXT,
                validado    BOOLEAN DEFAULT false NOT NULL,
                validado_por INTEGER,
                validado_en  TIMESTAMPTZ,
                requiere_aprobacion BOOLEAN DEFAULT false,
                aprobado_por INTEGER,
                aprobado_en  TIMESTAMPTZ,
                motivo_irregular TEXT,
                rechazado   BOOLEAN DEFAULT false,
                motivo_rechazo TEXT,
                CONSTRAINT postcorte_veredicto_efectivo_check  CHECK (veredicto_efectivo IN ('CUADRA','A_FAVOR','EN_CONTRA')),
                CONSTRAINT postcorte_veredicto_tarjetas_check  CHECK (veredicto_tarjetas  IN ('CUADRA','A_FAVOR','EN_CONTRA')),
                CONSTRAINT postcorte_veredicto_transfer_check  CHECK (veredicto_transferencias IN ('CUADRA','A_FAVOR','EN_CONTRA'))
            )
        ");

        $this->createIfNotExists('conciliacion', "
            CREATE TABLE selemti.conciliacion (
                id              BIGSERIAL PRIMARY KEY,
                postcorte_id    BIGINT NOT NULL UNIQUE REFERENCES selemti.postcorte(id) ON DELETE CASCADE,
                conciliado_por  INTEGER,
                conciliado_en   TIMESTAMPTZ DEFAULT now(),
                estatus         TEXT NOT NULL DEFAULT 'EN_REVISION',
                notas           TEXT,
                CONSTRAINT conciliacion_estatus_check CHECK (estatus IN ('EN_REVISION','CONCILIADO','OBSERVADA'))
            )
        ");

        // Indexes
        DB::connection('pgsql')->unprepared("
            CREATE INDEX IF NOT EXISTS idx_sesion_cajon_terminal_apertura ON selemti.sesion_cajon(terminal_id, apertura_ts);
            CREATE INDEX IF NOT EXISTS idx_precorte_sesion_id             ON selemti.precorte(sesion_id);
            CREATE INDEX IF NOT EXISTS idx_precorte_efectivo_precorte_id  ON selemti.precorte_efectivo(precorte_id);
            CREATE INDEX IF NOT EXISTS idx_precorte_otros_precorte_id     ON selemti.precorte_otros(precorte_id);
            CREATE INDEX IF NOT EXISTS idx_postcorte_sesion_id            ON selemti.postcorte(sesion_id);
        ");

        // Triggers (from 2025_10_17_000001_fix_caja_gaps.sql)
        DB::connection('pgsql')->unprepared("
            CREATE OR REPLACE FUNCTION selemti.fn_precorte_after_insert()
            RETURNS TRIGGER AS \$\$
            BEGIN
                UPDATE selemti.sesion_cajon
                SET estatus = 'EN_CORTE'
                WHERE id = NEW.sesion_id AND estatus = 'LISTO_PARA_CORTE';
                RETURN NEW;
            END;
            \$\$ LANGUAGE plpgsql;

            DROP TRIGGER IF EXISTS trg_precorte_after_insert ON selemti.precorte;
            CREATE TRIGGER trg_precorte_after_insert
            AFTER INSERT ON selemti.precorte
            FOR EACH ROW EXECUTE PROCEDURE selemti.fn_precorte_after_insert();
        ");

        // fn_postcorte_after_insert — full version with sales totals
        DB::connection('pgsql')->unprepared("
            CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
            RETURNS TRIGGER AS \$\$
            DECLARE
                v_apertura_ts   TIMESTAMPTZ;
                v_cierre_ts     TIMESTAMPTZ;
                v_terminal_id   INT;
                v_ventas_brutas NUMERIC(12,2) := 0;
                v_descuentos    NUMERIC(12,2) := 0;
                v_ventas_netas  NUMERIC(12,2) := 0;
            BEGIN
                SELECT apertura_ts, cierre_ts, terminal_id
                INTO v_apertura_ts, v_cierre_ts, v_terminal_id
                FROM selemti.sesion_cajon WHERE id = NEW.sesion_id;

                IF v_cierre_ts IS NULL THEN v_cierre_ts := now(); END IF;

                UPDATE selemti.sesion_cajon
                SET estatus = 'CERRADA', cierre_ts = v_cierre_ts
                WHERE id = NEW.sesion_id;

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

                UPDATE selemti.postcorte
                SET total_ventas_brutas     = v_ventas_brutas,
                    total_descuentos_reales = v_descuentos,
                    total_ventas_netas      = v_ventas_netas
                WHERE id = NEW.id;

                RETURN NEW;
            END;
            \$\$ LANGUAGE plpgsql;

            DROP TRIGGER IF EXISTS trg_postcorte_after_insert ON selemti.postcorte;
            CREATE TRIGGER trg_postcorte_after_insert
            AFTER INSERT ON selemti.postcorte
            FOR EACH ROW EXECUTE PROCEDURE selemti.fn_postcorte_after_insert();
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared('
            DROP TRIGGER IF EXISTS trg_postcorte_after_insert ON selemti.postcorte;
            DROP TRIGGER IF EXISTS trg_precorte_after_insert ON selemti.precorte;
            DROP FUNCTION IF EXISTS selemti.fn_postcorte_after_insert();
            DROP FUNCTION IF EXISTS selemti.fn_precorte_after_insert();
        ');

        foreach (['conciliacion', 'postcorte', 'precorte_otros', 'precorte_efectivo', 'precorte', 'sesion_cajon'] as $table) {
            DB::connection('pgsql')->statement("DROP TABLE IF EXISTS selemti.{$table} CASCADE");
        }
    }

    private function createIfNotExists(string $table, string $sql): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name=? LIMIT 1",
            [$table]
        );

        if (! $exists) {
            DB::connection('pgsql')->unprepared($sql);
        }
    }
};
