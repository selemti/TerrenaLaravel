<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement(<<<'SQL'
            ALTER TABLE selemti.transfer_cab
            ADD COLUMN IF NOT EXISTS aprobada_por INTEGER,
            ADD COLUMN IF NOT EXISTS posteada_por INTEGER,
            ADD COLUMN IF NOT EXISTS fecha_solicitada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_aprobada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_despachada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_recibida TIMESTAMP,
            ADD COLUMN IF NOT EXISTS fecha_posteada TIMESTAMP,
            ADD COLUMN IF NOT EXISTS observaciones TEXT,
            ADD COLUMN IF NOT EXISTS observaciones_recepcion TEXT,
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()
        SQL);

        DB::statement("ALTER TABLE selemti.transfer_cab ALTER COLUMN estado SET DEFAULT 'SOLICITADA'");

        DB::statement(<<<'SQL'
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'transfer_cab_estado_check'
                ) THEN
                    ALTER TABLE selemti.transfer_cab
                    ADD CONSTRAINT transfer_cab_estado_check
                    CHECK (estado IN ('SOLICITADA','APROBADA','EN_TRANSITO','RECIBIDA','POSTEADA','CANCELADA'));
                END IF;
            END$$;
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE selemti.transfer_det
            ADD COLUMN IF NOT EXISTS linea INTEGER,
            ADD COLUMN IF NOT EXISTS cantidad_despachada NUMERIC(12,3) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS cantidad_recibida NUMERIC(12,3) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS uom_id INTEGER,
            ADD COLUMN IF NOT EXISTS costo_unitario NUMERIC(12,4),
            ADD COLUMN IF NOT EXISTS lote VARCHAR(64),
            ADD COLUMN IF NOT EXISTS observaciones TEXT
        SQL);

        DB::statement(<<<'SQL'
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'selemti'
                      AND table_name = 'transfer_det'
                      AND column_name = 'cantidad'
                ) THEN
                    ALTER TABLE selemti.transfer_det
                    RENAME COLUMN cantidad TO cantidad_solicitada;
                END IF;
            END$$;
        SQL);

        DB::statement(<<<'SQL'
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'selemti'
                      AND table_name = 'transfer_det'
                      AND column_name = 'item_id'
                      AND data_type <> 'character varying'
                ) THEN
                    ALTER TABLE selemti.transfer_det
                    ALTER COLUMN item_id TYPE VARCHAR(20);
                END IF;
            END$$;
        SQL);

        DB::statement('CREATE INDEX IF NOT EXISTS idx_transfer_cab_estado ON selemti.transfer_cab(estado)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_transfer_cab_origen ON selemti.transfer_cab(origen_almacen_id)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_transfer_cab_destino ON selemti.transfer_cab(destino_almacen_id)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_transfer_cab_fecha_solicitada ON selemti.transfer_cab(fecha_solicitada)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_transfer_det_item ON selemti.transfer_det(item_id)');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS selemti.idx_transfer_cab_estado');
        DB::statement('DROP INDEX IF EXISTS selemti.idx_transfer_cab_origen');
        DB::statement('DROP INDEX IF EXISTS selemti.idx_transfer_cab_destino');
        DB::statement('DROP INDEX IF EXISTS selemti.idx_transfer_cab_fecha_solicitada');
        DB::statement('DROP INDEX IF EXISTS selemti.idx_transfer_det_item');
    }
};
