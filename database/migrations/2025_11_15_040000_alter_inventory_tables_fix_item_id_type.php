<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $tables = ['inventory_batch', 'recepcion_det', 'recepcion_adjuntos'];

        foreach ($tables as $table) {
            $exists = DB::connection('pgsql')->selectOne(
                "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='{$table}' LIMIT 1"
            );
            if (! $exists) {
                continue;
            }

            $colType = DB::connection('pgsql')->selectOne(
                "SELECT data_type FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='{$table}' AND column_name='item_id' LIMIT 1"
            );

            if ($colType && $colType->data_type !== 'character varying') {
                DB::connection('pgsql')->statement("
                    ALTER TABLE selemti.{$table} ALTER COLUMN item_id TYPE VARCHAR(50) USING item_id::text
                ");
            }
        }
    }

    public function down(): void {}
};
