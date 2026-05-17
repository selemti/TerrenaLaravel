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
        // ---------------------------------------------------------------------
        // TAREA 1 – Backdate mov_inv.ts (solo schema selemti)
        // ---------------------------------------------------------------------
        // Distribuye los movimientos de la corrida E2E en los últimos 14 días
        // manteniendo orden cronológico basado en el tipo de movimiento.
        // Se asigna 1 minuto entre cada registro para garantizar ts ascendente
        // y coherente con el id (el id sigue siendo la clave primaria).
        DB::unprepared(
            "DO $$
            DECLARE
                rec RECORD;
                base_ts TIMESTAMP := (now() - INTERVAL '14 days');
                seq INTEGER := 0;
            BEGIN
                FOR rec IN
                    SELECT id, tipo
                    FROM selemti.mov_inv
                    ORDER BY
                        CASE tipo
                            WHEN 'APERTURA'               THEN 1
                            WHEN 'RECEPCION_COMPRA'       THEN 2
                            WHEN 'PRODUCCION_SALIDA'      THEN 3
                            WHEN 'PRODUCCION_ENTRADA'     THEN 3
                            WHEN 'PRODUCCION_MERMA'       THEN 3
                            WHEN 'TRASPASO_SALIDA'        THEN 4
                            WHEN 'TRASPASO_ENTRADA'       THEN 4
                            WHEN 'AJUSTE_ENTRADA'         THEN 5
                            WHEN 'AJUSTE_SALIDA'          THEN 5
                            WHEN 'VENTA_POS'              THEN 6
                            ELSE 99
                        END,
                        id
                LOOP
                    seq := seq + 1;
                    UPDATE selemti.mov_inv
                    SET ts = base_ts + (seq * INTERVAL '1 minute')
                    WHERE id = rec.id;
                END LOOP;
            END $$;"
        );

        // ---------------------------------------------------------------------
        // TAREA 3 – Índice faltante (item_id, ts) en selemti.mov_inv
        // ---------------------------------------------------------------------
        DB::unprepared(
            "DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE c.relname = 'mov_inv_item_id_ts_idx'
                      AND n.nspname = 'selemti'
                ) THEN
                    CREATE INDEX mov_inv_item_id_ts_idx ON selemti.mov_inv(item_id, ts);
                END IF;
            END $$;"
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Elimina el índice creado en la migración.
        DB::unprepared(
            'DROP INDEX IF EXISTS selemti.mov_inv_item_id_ts_idx;'
        );
        // No revertimos los timestamps (no es crítico para rollback).
    }
};
