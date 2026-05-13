<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='menu_category' LIMIT 1"
        );

        if ($exists) {
            return;
        }

        DB::connection('pgsql')->statement('
            CREATE TABLE public.menu_category (
                id BIGSERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                translated_name VARCHAR(255) NULL,
                visible SMALLINT NOT NULL DEFAULT 1,
                beverage SMALLINT NOT NULL DEFAULT 0,
                sort_order INT NOT NULL DEFAULT 0
            )
        ');
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS public.menu_category');
    }
};
