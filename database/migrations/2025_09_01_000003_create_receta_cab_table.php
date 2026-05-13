<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='receta_cab' LIMIT 1"
        );
        if ($exists) {
            return;
        }

        // receta_cab lives in the default schema (public in pgsql, or selemti)
        // Receta model has no explicit connection so uses pgsql default
        DB::connection('pgsql')->statement("
            CREATE TABLE IF NOT EXISTS receta_cab (
                id VARCHAR(50) PRIMARY KEY,
                nombre_plato VARCHAR(200) NOT NULL,
                codigo_plato_pos VARCHAR(50) NULL,
                categoria_plato VARCHAR(100) NULL,
                porciones_standard INTEGER NULL DEFAULT 1,
                instrucciones_preparacion TEXT NULL,
                tiempo_preparacion_min INTEGER NULL,
                costo_standard_porcion NUMERIC(14,4) NULL DEFAULT 0,
                precio_venta_sugerido NUMERIC(14,2) NULL DEFAULT 0,
                activo BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMP NULL,
                updated_at TIMESTAMP NULL
            )
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS receta_cab');
    }
};
