<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Creates selemti.recetas — modifier-group → recipe mapping table.
 * Used by InventoryMovementService to find the recipe associated to a POS modifier.
 */
return new class extends Migration
{
    protected $connection = 'pgsql';

    public function up(): void
    {
        DB::statement('
            CREATE TABLE IF NOT EXISTS selemti.recetas (
                id                   BIGSERIAL PRIMARY KEY,
                grupo_modificador_id INTEGER       NOT NULL,
                nombre_modificador   VARCHAR(255)  NOT NULL,
                receta_cab_id        VARCHAR(20)   REFERENCES selemti.receta_cab(id) ON DELETE SET NULL,
                created_at           TIMESTAMP     DEFAULT NOW(),
                updated_at           TIMESTAMP     DEFAULT NOW()
            )
        ');

        DB::statement('
            CREATE INDEX IF NOT EXISTS idx_recetas_grupo_mod
            ON selemti.recetas (grupo_modificador_id, nombre_modificador)
        ');
    }

    public function down(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.recetas');
    }
};
