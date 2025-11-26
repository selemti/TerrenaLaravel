<?php

namespace Tests\Feature\Purchasing;

use App\Models\ReplenishmentSuggestion;
use App\Models\User;
use App\Services\Replenishment\ReplenishmentService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReplenishmentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->setUpInMemoryDatabase();
    }

    protected function setUpInMemoryDatabase(): void
    {
        config([
            'database.default' => 'pgsql',
            'database.connections.pgsql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
                'foreign_key_constraints' => true,
            ],
        ]);

        DB::purge('pgsql');
        DB::setDefaultConnection('pgsql');
        DB::reconnect('pgsql');
        DB::connection('pgsql')->getPdo()->exec('PRAGMA foreign_keys=ON;');
        DB::connection('pgsql')->statement('ATTACH DATABASE ":memory:" AS selemti');

        $this->createCoreTables();
    }

    protected function createCoreTables(): void
    {
        // Core auth tables
        DB::statement('CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            created_at DATETIME,
            updated_at DATETIME
        )');

        DB::statement('CREATE TABLE personal_access_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tokenable_type TEXT,
            tokenable_id INTEGER,
            name TEXT,
            token TEXT,
            abilities TEXT,
            last_used_at DATETIME,
            created_at DATETIME,
            updated_at DATETIME
        )');

        // Domain tables (schema selemti)
        DB::statement('CREATE TABLE selemti.items (
            id TEXT PRIMARY KEY,
            nombre TEXT,
            unidad_medida TEXT,
            tipo TEXT,
            recipe_id INTEGER NULL,
            costo_promedio NUMERIC,
            proveedor_id INTEGER NULL,
            created_at DATETIME,
            updated_at DATETIME
        )');

        DB::statement('CREATE TABLE selemti.inv_stock_policy (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id TEXT NOT NULL,
            sucursal_id INTEGER NOT NULL,
            min_qty NUMERIC NOT NULL,
            max_qty NUMERIC NOT NULL,
            reorder_qty NUMERIC NOT NULL,
            activo BOOLEAN DEFAULT 1,
            created_at DATETIME,
            updated_at DATETIME
        )');

        DB::statement('CREATE TABLE selemti.mov_inv (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts DATETIME,
            item_id TEXT NOT NULL,
            lote_id INTEGER NULL,
            cantidad NUMERIC NOT NULL,
            qty_original NUMERIC NULL,
            uom_original_id INTEGER NULL,
            costo_unit NUMERIC NULL,
            tipo TEXT NOT NULL,
            ref_tipo TEXT NULL,
            ref_id INTEGER NULL,
            sucursal_id TEXT NULL,
            usuario_id INTEGER NULL,
            created_at DATETIME
        )');

        DB::statement('CREATE TABLE selemti.inv_consumo_pos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sucursal_id INTEGER NULL,
            fecha_proceso DATETIME NULL,
            created_at DATETIME NULL,
            updated_at DATETIME NULL
        )');

        DB::statement('CREATE TABLE selemti.inv_consumo_pos_det (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            consumo_id INTEGER NOT NULL,
            mp_id INTEGER NOT NULL,
            cantidad NUMERIC NOT NULL,
            factor NUMERIC NULL,
            procesado BOOLEAN DEFAULT 1,
            revertido BOOLEAN DEFAULT 0,
            created_at DATETIME NULL,
            updated_at DATETIME NULL
        )');

        DB::statement('CREATE TABLE replenishment_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folio TEXT UNIQUE,
            tipo TEXT,
            prioridad TEXT,
            origen TEXT,
            item_id TEXT,
            sucursal_id INTEGER,
            almacen_id INTEGER NULL,
            stock_actual NUMERIC,
            stock_min NUMERIC,
            stock_max NUMERIC,
            qty_sugerida NUMERIC,
            qty_aprobada NUMERIC NULL,
            uom TEXT,
            consumo_promedio_diario NUMERIC NULL,
            dias_stock_restante INTEGER NULL,
            fecha_agotamiento_estimada DATETIME NULL,
            estado TEXT,
            sugerido_en DATETIME NULL,
            caduca_en DATETIME NULL,
            motivo TEXT NULL,
            motivo_rechazo TEXT NULL,
            notas TEXT NULL,
            meta TEXT NULL,
            revisado_por INTEGER NULL,
            purchase_request_id INTEGER NULL,
            production_order_id INTEGER NULL,
            revisado_en DATETIME NULL,
            convertido_en DATETIME NULL,
            created_at DATETIME NULL,
            updated_at DATETIME NULL
        )');

        DB::statement('CREATE TABLE selemti.replenishment_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folio TEXT UNIQUE,
            tipo TEXT,
            prioridad TEXT,
            origen TEXT,
            item_id TEXT,
            sucursal_id INTEGER,
            almacen_id INTEGER NULL,
            stock_actual NUMERIC,
            stock_min NUMERIC,
            stock_max NUMERIC,
            qty_sugerida NUMERIC,
            qty_aprobada NUMERIC NULL,
            uom TEXT,
            consumo_promedio_diario NUMERIC NULL,
            dias_stock_restante INTEGER NULL,
            fecha_agotamiento_estimada DATETIME NULL,
            estado TEXT,
            sugerido_en DATETIME NULL,
            caduca_en DATETIME NULL,
            motivo TEXT NULL,
            motivo_rechazo TEXT NULL,
            notas TEXT NULL,
            meta TEXT NULL,
            revisado_por INTEGER NULL,
            purchase_request_id INTEGER NULL,
            production_order_id INTEGER NULL,
            revisado_en DATETIME NULL,
            convertido_en DATETIME NULL,
            created_at DATETIME NULL,
            updated_at DATETIME NULL
        )');
    }

    public function test_min_max_generates_purchase_suggestion_when_below_min(): void
    {
        Carbon::setTestNow('2025-01-05 10:00:00');
        $service = new ReplenishmentService();

        DB::connection('pgsql')->table('selemti.items')->insert([
            'id' => 'ITEM-1',
            'nombre' => 'Item MinMax',
            'unidad_medida' => 'UND',
            'tipo' => 'COMPRA',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.inv_stock_policy')->insert([
            'item_id' => 'ITEM-1',
            'sucursal_id' => 1,
            'min_qty' => 10,
            'max_qty' => 20,
            'reorder_qty' => 8,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'ts' => now(),
            'item_id' => 'ITEM-1',
            'cantidad' => 5,
            'tipo' => 'ENTRADA',
            'sucursal_id' => 'SUC-1',
            'created_at' => now(),
        ]);

        $result = $service->generateDailySuggestions([
            'algoritmo' => 'MIN_MAX',
            'dias_analisis' => 7,
        ]);

        $this->assertSame(1, $result['total']);
        $suggestion = ReplenishmentSuggestion::first();
        $this->assertEquals('COMPRA', $suggestion->tipo);
        $this->assertEquals(8, (float) $suggestion->qty_sugerida, 'Usa reorder_qty cuando está presente');
        $this->assertEquals(5, (float) $suggestion->stock_actual);
        $this->assertEquals(10, (float) $suggestion->stock_min);
        $this->assertEquals('BAJA', $suggestion->prioridad);
    }

    public function test_pos_consumption_uses_expanded_consumption_history(): void
    {
        Carbon::setTestNow('2025-01-10 09:00:00');
        $service = new ReplenishmentService();

        DB::connection('pgsql')->table('selemti.items')->insert([
            'id' => 'MP-100',
            'nombre' => 'Materia Prima 100',
            'unidad_medida' => 'UND',
            'tipo' => 'COMPRA',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.inv_stock_policy')->insert([
            'item_id' => 'MP-100',
            'sucursal_id' => 1,
            'min_qty' => 1,
            'max_qty' => 10,
            'reorder_qty' => 6,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.inv_consumo_pos')->insert([
            'id' => 1,
            'sucursal_id' => 1,
            'fecha_proceso' => now()->subDays(2),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.inv_consumo_pos_det')->insert([
            'consumo_id' => 1,
            'mp_id' => 100, // mp_id es entero en BD
            'cantidad' => 10,
            'factor' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $result = $service->generateDailySuggestions([
            'algoritmo' => 'POS_CONSUMPTION',
            'dias_analisis' => 5,
        ]);

        $this->assertSame(1, $result['total']);
        $suggestion = ReplenishmentSuggestion::first();
        $this->assertEquals('COMPRA', $suggestion->tipo);
        $this->assertEquals(6, (float) $suggestion->qty_sugerida, 'Usa reorder_qty como cantidad sugerida');
        $this->assertEquals(2.0, (float) $suggestion->consumo_promedio_diario, 'Consumo POS / días');
        $this->assertEquals('URGENTE', $suggestion->prioridad, 'Sin stock genera prioridad urgente');
    }

    public function test_api_returns_suggestions_structure(): void
    {
        Carbon::setTestNow('2025-01-15 12:00:00');

        $user = User::forceCreate([
            'name' => 'Tester',
            'email' => 'tester@example.com',
            'password' => bcrypt('password'),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        ReplenishmentSuggestion::create([
            'folio' => 'RSC-20250115-0001',
            'tipo' => 'COMPRA',
            'prioridad' => 'NORMAL',
            'origen' => 'AUTO',
            'item_id' => 'ITEM-API',
            'sucursal_id' => 1,
            'stock_actual' => 0,
            'stock_min' => 5,
            'stock_max' => 10,
            'qty_sugerida' => 8,
            'uom' => 'UND',
            'consumo_promedio_diario' => 1.5,
            'dias_stock_restante' => 0,
            'estado' => ReplenishmentSuggestion::ESTADO_PENDIENTE,
            'sugerido_en' => now(),
            'caduca_en' => now()->addDays(7),
            'motivo' => 'Test API',
            'meta' => ['stock_policy_id' => 1],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/purchasing/replenishment/suggestions');

        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
        ]);

        $this->assertArrayHasKey('data', $response->json());
        $this->assertNotEmpty($response->json('data'));
        $this->assertEquals('ITEM-API', $response->json('data.0.item_id'));
    }
}
