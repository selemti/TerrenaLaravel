<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $cabExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='traspaso_cab' LIMIT 1"
        );
        if (! $cabExists) {
            DB::connection('pgsql')->statement("
                CREATE TABLE selemti.traspaso_cab (
                    id BIGSERIAL PRIMARY KEY,
                    from_bodega_id BIGINT NOT NULL,
                    to_bodega_id BIGINT NOT NULL,
                    estado VARCHAR(30) NOT NULL DEFAULT 'SOLICITADA',
                    usuario_id BIGINT NULL,
                    validada_por BIGINT NULL,
                    validada_at TIMESTAMP NULL,
                    posteada_por BIGINT NULL,
                    posteada_at TIMESTAMP NULL,
                    despachada_por INTEGER NULL,
                    despachada_at TIMESTAMP NULL,
                    guia VARCHAR(100) NULL,
                    recibida_por INTEGER NULL,
                    recibida_at TIMESTAMP NULL,
                    meta JSONB NULL,
                    created_at TIMESTAMP NULL,
                    updated_at TIMESTAMP NULL
                )
            ");
        }

        $detExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='traspaso_det' LIMIT 1"
        );
        if (! $detExists) {
            DB::connection('pgsql')->statement("
                CREATE TABLE selemti.traspaso_det (
                    id BIGSERIAL PRIMARY KEY,
                    traspaso_id BIGINT NOT NULL,
                    item_id VARCHAR(50) NOT NULL,
                    qty NUMERIC(14,6) NOT NULL,
                    um_id BIGINT NULL,
                    batch_id BIGINT NULL,
                    cantidad_despachada NUMERIC(14,4) NULL,
                    cantidad_recibida NUMERIC(14,4) NULL,
                    created_at TIMESTAMP NULL,
                    updated_at TIMESTAMP NULL
                )
            ");
        }
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.traspaso_det');
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.traspaso_cab');
    }
};
