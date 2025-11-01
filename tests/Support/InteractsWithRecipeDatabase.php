<?php

namespace Tests\Support;

use Illuminate\Support\Facades\DB;

trait InteractsWithRecipeDatabase
{
    protected function setUpRecipeDatabase(): void
    {
        config()->set('database.connections.pgsql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => false,
        ]);

        config()->set('database.default', 'pgsql');

        DB::purge('pgsql');
        DB::reconnect('pgsql');

        $this->attachSelemtiSchema();

        $this->createUsersTable();
        $this->createItemCategoriesTable();
        $this->createItemsTable();
        $this->createRecipesTable();
        $this->createRecipeDetailsTable();
        $this->createSnapshotsTable();
    }

    private function createUsersTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS "users"');
        DB::statement('CREATE TABLE "users" (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            password TEXT,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createItemCategoriesTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS "item_categories"');
        DB::statement('CREATE TABLE "item_categories" (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createItemsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS "items"');
        DB::statement('CREATE TABLE "items" (
            id TEXT PRIMARY KEY,
            codigo TEXT,
            nombre TEXT,
            categoria_id INTEGER,
            perishable INTEGER,
            activo INTEGER,
            costo_promedio REAL,
            factor_conversion REAL,
            factor_compra REAL,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createRecipesTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS "receta_cab"');
        DB::statement('CREATE TABLE "receta_cab" (
            id TEXT PRIMARY KEY,
            nombre_plato TEXT,
            codigo_plato_pos TEXT,
            categoria_plato TEXT,
            porciones_standard REAL DEFAULT 1,
            instrucciones_preparacion TEXT,
            tiempo_preparacion_min INTEGER,
            costo_standard_porcion REAL,
            precio_venta_sugerido REAL,
            activo INTEGER,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createRecipeDetailsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.receta_det');
        DB::statement('CREATE TABLE selemti.receta_det (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            receta_id TEXT NOT NULL,
            item_id TEXT,
            receta_id_ingrediente TEXT,
            cantidad REAL NOT NULL,
            unidad_id TEXT,
            orden INTEGER,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createSnapshotsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.recipe_cost_snapshots');
        DB::statement('CREATE TABLE selemti.recipe_cost_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipe_id TEXT NOT NULL,
            snapshot_date TEXT NOT NULL,
            cost_total REAL NOT NULL DEFAULT 0,
            cost_per_portion REAL NOT NULL DEFAULT 0,
            portions REAL NOT NULL DEFAULT 1,
            cost_breakdown TEXT NOT NULL DEFAULT "[]",
            reason TEXT NOT NULL,
            created_by_user_id INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )');
    }

    private function attachSelemtiSchema(): void
    {
        try {
            DB::statement('DETACH DATABASE selemti');
        } catch (\Throwable $e) {
            // ignore if schema is not attached
        }

        DB::statement("ATTACH DATABASE ':memory:' AS selemti");
    }
}
