<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='mov_inv' LIMIT 1"
        );
        if (! $exists) {
            return;
        }

        // item_id was created as bigint but Item PKs are strings (ITEM-XXXXX)
        DB::connection('pgsql')->statement("
            ALTER TABLE selemti.mov_inv ALTER COLUMN item_id TYPE VARCHAR(50) USING item_id::text
        ");
    }

    public function down(): void {}
};
