<?php

namespace Tests\Support;

use Illuminate\Support\Facades\DB;

trait InteractsWithTransferDatabase
{
    protected function setUpTransferDatabase(): void
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
        $this->createAlmacenesTable();
        $this->createUnidadesTable();
        $this->createItemsTable();
        $this->createTransferHeaderTable();
        $this->createTransferLineTable();
        $this->createMovInvTable();

        $this->seedDefaultCatalogs();
    }

    private function attachSelemtiSchema(): void
    {
        try {
            DB::statement('DETACH DATABASE selemti');
        } catch (\Throwable) {
        }

        DB::statement("ATTACH DATABASE ':memory:' AS selemti");
    }

    private function createUsersTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS users');
        DB::statement('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
        DB::table('users')->insert(['name' => 'Test User']);
    }

    private function createAlmacenesTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.cat_almacenes');
        DB::statement('CREATE TABLE selemti.cat_almacenes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clave TEXT,
            nombre TEXT,
            sucursal_id INTEGER,
            activo INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createUnidadesTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.cat_unidades');
        DB::statement('CREATE TABLE selemti.cat_unidades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clave TEXT,
            nombre TEXT,
            activo INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createItemsTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.items');
        DB::statement('CREATE TABLE selemti.items (
            id TEXT PRIMARY KEY,
            nombre TEXT,
            categoria_id TEXT,
            unidad_medida TEXT,
            costo_promedio REAL DEFAULT 0,
            activo INTEGER DEFAULT 1,
            unidad_medida_id INTEGER,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    private function createTransferHeaderTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.transfer_cab');
        DB::statement('CREATE TABLE selemti.transfer_cab (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            origen_almacen_id INTEGER NOT NULL,
            destino_almacen_id INTEGER NOT NULL,
            estado TEXT NOT NULL DEFAULT "SOLICITADA",
            creada_por INTEGER,
            aprobada_por INTEGER,
            despachada_por INTEGER,
            recibida_por INTEGER,
            posteada_por INTEGER,
            guia TEXT,
            fecha_solicitada TEXT,
            fecha_aprobada TEXT,
            fecha_despachada TEXT,
            fecha_recibida TEXT,
            fecha_posteada TEXT,
            observaciones TEXT,
            observaciones_recepcion TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )');
    }

    private function createTransferLineTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.transfer_det');
        DB::statement('CREATE TABLE selemti.transfer_det (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transfer_id INTEGER,
            linea INTEGER,
            item_id TEXT,
            cantidad_solicitada REAL,
            cantidad_despachada REAL,
            cantidad_recibida REAL,
            uom_id INTEGER,
            costo_unitario REAL,
            lote TEXT,
            observaciones TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )');
    }

    private function createMovInvTable(): void
    {
        DB::statement('DROP TABLE IF EXISTS selemti.mov_inv');
        DB::statement('CREATE TABLE selemti.mov_inv (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts TEXT DEFAULT CURRENT_TIMESTAMP,
            item_id TEXT,
            cantidad REAL,
            tipo TEXT,
            ref_tipo TEXT,
            ref_id INTEGER,
            sucursal_id INTEGER,
            usuario_id INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )');
    }

    private function seedDefaultCatalogs(): void
    {
        DB::table('selemti.cat_unidades')->insert([
            ['clave' => 'KG', 'nombre' => 'Kilogramo', 'activo' => 1],
            ['clave' => 'PZ', 'nombre' => 'Pieza', 'activo' => 1],
        ]);

        DB::table('selemti.cat_almacenes')->insert([
            ['clave' => 'ALM-01', 'nombre' => 'General', 'sucursal_id' => 10, 'activo' => 1],
            ['clave' => 'ALM-02', 'nombre' => 'Destino', 'sucursal_id' => 20, 'activo' => 1],
        ]);

        DB::table('selemti.items')->insert([
            ['id' => 'ITEM-001', 'nombre' => 'Harina', 'categoria_id' => 'CAT-TEST', 'unidad_medida' => 'KG', 'unidad_medida_id' => 1],
            ['id' => 'ITEM-002', 'nombre' => 'Queso', 'categoria_id' => 'CAT-TEST', 'unidad_medida' => 'KG', 'unidad_medida_id' => 1],
        ]);
    }
}
