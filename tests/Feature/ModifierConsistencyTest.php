<?php

namespace Tests\Feature;

use App\Models\Caja\TicketItemModifier;
use App\Services\Inventory\InventoryMovementService;
use App\Services\Inventory\ModifierValidationService;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ModifierConsistencyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        if (! extension_loaded('sqlite3')) {
            $this->markTestSkipped('SQLite driver not available for in-memory modifier tests.');
        }

        $this->setUpInMemoryDatabase();
        $this->seedModifierFixtures();
    }

    public function test_modifier_group_consistency(): void
    {
        $service = new ModifierValidationService();

        $result = $service->getModifierGroup(2);

        $this->assertSame(3, $result);
    }

    public function test_inventory_movement_uses_correct_group(): void
    {
        $movementService = new InventoryMovementService(new ModifierValidationService());

        $movementId = $movementService->recordModifierMovement(2, 1, 'SALE', ['uom' => 'EA']);

        $this->assertGreaterThan(0, $movementId, 'Debe crear un movimiento de inventario');

        $movement = DB::connection('pgsql')->table('selemti.mov_inv')->where('id', $movementId)->first();

        $this->assertNotNull($movement);
        $this->assertSame(500, (int) ($movement->item_id ?? 0), 'Debe consumir el ingrediente de la receta ligada al grupo correcto');
        $this->assertSame(101, (int) ($movement->ref_id ?? 0));
        $this->assertSame('MODIFIER_RECIPE', $movement->tipo);
    }

    public function test_miscellaneous_modifiers_are_considered_consistent(): void
    {
        $tim = new TicketItemModifier([
            'item_id' => 0,
            'group_id' => 99,
        ]);

        $this->assertTrue($tim->is_consistent);
    }

    protected function setUpInMemoryDatabase(): void
    {
        config()->set('database.connections.pgsql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        config()->set('database.default', 'pgsql');

        DB::purge('pgsql');
        DB::reconnect('pgsql');

        DB::statement('CREATE TABLE "public.menu_modifier_group" (id INTEGER PRIMARY KEY, name TEXT)');
        DB::statement('CREATE TABLE "public.menu_modifier" (id INTEGER PRIMARY KEY, name TEXT, group_id INTEGER)');
        DB::statement('CREATE TABLE "selemti.recetas" (id INTEGER PRIMARY KEY, grupo_modificador_id INTEGER, nombre_modificador TEXT)');
        DB::statement('CREATE TABLE "selemti.receta_det" (id INTEGER PRIMARY KEY AUTOINCREMENT, receta_id INTEGER, item_id INTEGER, cantidad REAL)');
        DB::statement('CREATE TABLE "selemti.mov_inv" (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER,
            qty REAL,
            tipo TEXT,
            uom TEXT,
            sucursal_id INTEGER,
            almacen_id INTEGER,
            ref_tipo TEXT,
            ref_id INTEGER,
            user_id INTEGER,
            ts TEXT,
            meta TEXT,
            created_at TEXT,
            updated_at TEXT
        )');
    }

    protected function seedModifierFixtures(): void
    {
        DB::connection('pgsql')->table('public.menu_modifier_group')->insert([
            'id' => 3,
            'name' => 'Relleno Empanada',
        ]);

        DB::connection('pgsql')->table('public.menu_modifier')->insert([
            'id' => 2,
            'name' => 'Picadillo',
            'group_id' => 3,
        ]);

        DB::connection('pgsql')->table('selemti.recetas')->insert([
            'id' => 101,
            'grupo_modificador_id' => 3,
            'nombre_modificador' => 'Picadillo',
        ]);

        DB::connection('pgsql')->table('selemti.receta_det')->insert([
            'receta_id' => 101,
            'item_id' => 500,
            'cantidad' => 1,
        ]);
    }
}
