<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        // 1) Columna booleana NOT NULL con default
        Schema::table('selemti.item_vendor', function (Blueprint $table) {
            if (!Schema::hasColumn('selemti.item_vendor', 'preferente')) {
                $table->boolean('preferente')->default(false)->nullable(false);
            }
        });

        // 2) Índice único parcial: asegura 1 solo preferente por item_id
        // (Laravel Schema no soporta índices parciales: usamos SQL crudo)
        DB::statement("
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_indexes
                    WHERE schemaname = 'selemti'
                      AND indexname = 'ux_item_vendor_preferente_unique'
                ) THEN
                    CREATE UNIQUE INDEX ux_item_vendor_preferente_unique
                    ON selemti.item_vendor (item_id)
                    WHERE preferente = true;
                END IF;
            END$$;
        ");
    }

    public function down(): void
    {
        // 1) Quita el índice parcial si existe
        DB::statement("
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM pg_indexes
                    WHERE schemaname = 'selemti'
                      AND indexname = 'ux_item_vendor_preferente_unique'
                ) THEN
                    DROP INDEX selemti.ux_item_vendor_preferente_unique;
                END IF;
            END$$;
        ");

        // 2) Quita la columna
        Schema::table('selemti.item_vendor', function (Blueprint $table) {
            if (Schema::hasColumn('selemti.item_vendor', 'preferente')) {
                $table->dropColumn('preferente');
            }
        });
    }
};
