<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $tableExists = DB::connection('pgsql')
            ->table('information_schema.tables')
            ->where('table_schema', 'selemti')
            ->where('table_name', 'item_vendor')
            ->exists();

        if (!$tableExists) {
            return;
        }

        $columnExists = DB::connection('pgsql')
            ->table('information_schema.columns')
            ->where('table_schema', 'selemti')
            ->where('table_name', 'item_vendor')
            ->where('column_name', 'preferente')
            ->exists();

        if (!$columnExists) {
            DB::statement("ALTER TABLE selemti.item_vendor ADD COLUMN preferente boolean DEFAULT false");
        }
    }

    public function down(): void
    {
        $tableExists = DB::connection('pgsql')
            ->table('information_schema.tables')
            ->where('table_schema', 'selemti')
            ->where('table_name', 'item_vendor')
            ->exists();

        if (!$tableExists) {
            return;
        }

        $columnExists = DB::connection('pgsql')
            ->table('information_schema.columns')
            ->where('table_schema', 'selemti')
            ->where('table_name', 'item_vendor')
            ->where('column_name', 'preferente')
            ->exists();

        if ($columnExists) {
            DB::statement("ALTER TABLE selemti.item_vendor DROP COLUMN preferente");
        }
    }
};
