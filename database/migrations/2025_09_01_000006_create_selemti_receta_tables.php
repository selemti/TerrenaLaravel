<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $versionExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='receta_version' LIMIT 1"
        );
        if (! $versionExists) {
            DB::connection('pgsql')->statement("
                CREATE TABLE selemti.receta_version (
                    id BIGSERIAL PRIMARY KEY,
                    receta_id VARCHAR(50) NOT NULL,
                    version INTEGER NOT NULL DEFAULT 1,
                    descripcion_cambios TEXT NULL,
                    fecha_efectiva DATE NULL,
                    version_publicada BOOLEAN NOT NULL DEFAULT FALSE,
                    usuario_publicador BIGINT NULL,
                    fecha_publicacion TIMESTAMP NULL,
                    created_at TIMESTAMP NULL
                )
            ");
        }

        $detExists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='receta_det' LIMIT 1"
        );
        if (! $detExists) {
            DB::connection('pgsql')->statement("
                CREATE TABLE selemti.receta_det (
                    id BIGSERIAL PRIMARY KEY,
                    receta_id VARCHAR(50) NOT NULL,
                    receta_version_id BIGINT NULL,
                    item_id VARCHAR(50) NULL,
                    receta_id_ingrediente VARCHAR(50) NULL,
                    cantidad NUMERIC(14,4) NOT NULL DEFAULT 1,
                    unidad_id BIGINT NULL,
                    orden INTEGER NULL DEFAULT 0,
                    created_at TIMESTAMP NULL,
                    updated_at TIMESTAMP NULL
                )
            ");
        }
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.receta_det');
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.receta_version');
    }
};
