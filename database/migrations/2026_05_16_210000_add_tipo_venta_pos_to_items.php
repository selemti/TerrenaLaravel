<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
            DO $$ BEGIN
                BEGIN
                    ALTER TABLE selemti.items
                        ADD COLUMN tipo_venta_pos VARCHAR(20)
                        CHECK (tipo_venta_pos IN ('PLATILLO','SELECTOR_DEFINE','PRODUCCION','DIRECTO'));
                EXCEPTION WHEN duplicate_column THEN NULL;
                END;
            END $$;

            COMMENT ON COLUMN selemti.items.tipo_venta_pos IS
                'Comportamiento POS del ítem:
                 PLATILLO       = tiene receta de venta con ingredientes fijos
                 SELECTOR_DEFINE = el modifier SELECTOR define el SKU que se descuenta (Malanga, Suerox, chicles)
                 PRODUCCION     = se produce internamente, no se vende directo en POS
                 DIRECTO        = se vende tal cual sin receta ni selector
                 NULL           = insumo puro, no aparece en POS';
        SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
            ALTER TABLE selemti.items DROP COLUMN IF EXISTS tipo_venta_pos;
        SQL);
    }
};
