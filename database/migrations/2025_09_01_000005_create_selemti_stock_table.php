<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='stock' LIMIT 1"
        );
        if ($exists) {
            return;
        }

        DB::connection('pgsql')->statement("
            CREATE TABLE selemti.stock (
                id BIGSERIAL PRIMARY KEY,
                almacen_id BIGINT NOT NULL,
                item_id VARCHAR(50) NOT NULL,
                cantidad_actual NUMERIC(14,6) NOT NULL DEFAULT 0,
                created_at TIMESTAMP NULL,
                updated_at TIMESTAMP NULL,
                UNIQUE (almacen_id, item_id)
            )
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.stock');
    }
};
