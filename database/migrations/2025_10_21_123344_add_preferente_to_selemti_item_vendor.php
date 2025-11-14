<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! $this->columnExists('preferente')) {
            Schema::connection('pgsql')->table('selemti.item_vendor', function (Blueprint $table) {
                $table->boolean('preferente')->default(false)->nullable(false);
            });
        }

        // 2) Índice único parcial: asegura 1 solo preferente por item_id
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

        if ($this->columnExists('preferente')) {
            Schema::connection('pgsql')->table('selemti.item_vendor', function (Blueprint $table) {
                $table->dropColumn('preferente');
            });
        }
    }

    private function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = 'item_vendor'
              AND column_name = ?
            LIMIT 1
            SQL,
            [$column]
        );

        return ! empty($result);
    }
};
