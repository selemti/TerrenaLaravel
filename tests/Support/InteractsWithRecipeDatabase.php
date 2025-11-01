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
        $this->createRecipeVersionsTable();
        $this->createRecipeDetailsTable();
        $this->createSnapshotsTable();
        $this->seedDefaultCategory();
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
        DB::statement('DROP TABLE IF EXISTS selemti.item_categories');
        DB::statement('CREATE TABLE selemti.item_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo TEXT,
            nombre TEXT NOT NULL,
            slug TEXT,
            prefijo TEXT,
            descripcion TEXT,
            activo INTEGER,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createItemsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.items');
        DB::statement('CREATE TABLE selemti.items (
            id TEXT PRIMARY KEY,
            item_code TEXT,
            nombre TEXT,
            descripcion TEXT,
            categoria_id TEXT NOT NULL,
            unidad_medida TEXT DEFAULT "PZ",
            perishable INTEGER DEFAULT 0,
            costo_promedio REAL DEFAULT 0,
            activo INTEGER DEFAULT 1,
            factor_conversion REAL DEFAULT 1,
            factor_compra REAL DEFAULT 1,
            unidad_medida_id INTEGER,
            unidad_compra_id INTEGER,
            unidad_salida_id INTEGER,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createRecipesTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.receta_cab');
        DB::statement('CREATE TABLE selemti.receta_cab (
            id TEXT PRIMARY KEY,
            nombre_plato TEXT,
            codigo_plato_pos TEXT,
            categoria_plato TEXT,
            porciones_standard INTEGER DEFAULT 1,
            instrucciones_preparacion TEXT,
            tiempo_preparacion_min INTEGER,
            costo_standard_porcion REAL DEFAULT 0,
            precio_venta_sugerido REAL DEFAULT 0,
            activo INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createRecipeVersionsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.receta_version');
        DB::statement('CREATE TABLE selemti.receta_version (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            receta_id TEXT NOT NULL,
            version INTEGER DEFAULT 1,
            descripcion_cambios TEXT,
            fecha_efectiva TEXT,
            version_publicada INTEGER DEFAULT 0,
            usuario_publicador INTEGER,
            fecha_publicacion TEXT,
            created_at TEXT
        )');
    }

    private function createRecipeDetailsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.receta_det');
        DB::statement('CREATE TABLE selemti.receta_det (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            receta_version_id INTEGER NOT NULL,
            item_id TEXT NOT NULL,
            cantidad REAL NOT NULL,
            unidad_medida TEXT NOT NULL,
            merma_porcentaje REAL,
            instrucciones_especificas TEXT,
            orden INTEGER,
            created_at TEXT
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

    private function seedDefaultCategory(): void
    {
        DB::table('selemti.item_categories')->insert([
            'codigo' => 'CAT-TEST',
            'nombre' => 'Categoría Test',
            'slug' => 'categoria-test',
            'prefijo' => 'TES',
            'activo' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
