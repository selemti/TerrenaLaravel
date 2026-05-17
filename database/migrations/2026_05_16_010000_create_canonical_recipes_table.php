<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->statement(<<<'SQL'
            CREATE TABLE IF NOT EXISTS selemti.recipes (
                id BIGSERIAL PRIMARY KEY,
                codigo VARCHAR(50),
                nombre VARCHAR(255) NOT NULL,
                tipo VARCHAR(30),
                batch_size NUMERIC(14,6) DEFAULT 1,
                yield_portions NUMERIC(14,6) DEFAULT 1,
                uom_salida VARCHAR(20),
                activo BOOLEAN DEFAULT true,
                meta JSONB,
                created_at TIMESTAMP WITHOUT TIME ZONE,
                updated_at TIMESTAMP WITHOUT TIME ZONE
            )
        SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.recipes');
    }
};
