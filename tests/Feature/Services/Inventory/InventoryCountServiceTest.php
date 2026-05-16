<?php

namespace Tests\Feature\Services\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Inventory\InventoryCount;
use App\Models\Inventory\InventoryCountLine;
use App\Models\User;
use App\Services\Inventory\InventoryCountService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class InventoryCountServiceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Almacen $almacen;

    protected Item $item1;

    protected Item $item2;

    protected InventoryCountService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(InventoryCountService::class);

        $this->user = User::factory()->create();
        $this->almacen = Almacen::factory()->create([
            'nombre' => 'Almacén Test',
            'clave' => 'TEST',
        ]);

        $this->item1 = Item::factory()->create([
            'id' => '10001',
            'nombre' => 'Producto Test 1',
            'clave' => 'TEST-001',
        ]);

        $this->item2 = Item::factory()->create([
            'id' => '10002',
            'nombre' => 'Producto Test 2',
            'clave' => 'TEST-002',
        ]);

        // Crear stock inicial desde kardex real.
        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'item_id' => $this->item1->id,
            'tipo' => 'INICIAL',
            'cantidad' => 100,
            'ts' => now(),
            'created_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'item_id' => $this->item2->id,
            'tipo' => 'INICIAL',
            'cantidad' => 50,
            'ts' => now(),
            'created_at' => now(),
        ]);
    }

    /** @test */
    public function test_can_create_inventory_count()
    {
        $count = $this->service->createCount([
            'almacen_id' => $this->almacen->id,
            'sucursal_id' => 1,
            'programado_para' => now()->addDay(),
            'observaciones' => 'Test count',
        ], $this->user->id);

        $this->assertInstanceOf(InventoryCount::class, $count);
        $this->assertEquals(InventoryCount::STATUS_PROGRAMADO, $count->estado);

        $this->assertDatabaseHas('selemti.inventory_counts', [
            'id' => $count->id,
            'almacen_id' => (string) $this->almacen->id,
            'estado' => InventoryCount::STATUS_PROGRAMADO,
        ]);
    }

    /** @test */
    public function test_can_add_items_to_count()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_PROGRAMADO,
            'programado_para' => now()->addDay(),
            'creado_por' => $this->user->id,
        ]);

        $items = [
            ['item_id' => $this->item1->id],
            ['item_id' => $this->item2->id],
        ];

        $result = $this->service->addItemsToCount($count->id, $items);

        $this->assertEquals(count($items), $result['items_added']);

        foreach ($items as $item) {
            $this->assertDatabaseHas('selemti.inventory_count_lines', [
                'inventory_count_id' => $count->id,
                'item_id' => $item['item_id'],
            ]);
        }
    }

    /** @test */
    public function test_can_start_count()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_PROGRAMADO,
            'programado_para' => now()->subDay(), // Para que esté en fecha
            'creado_por' => $this->user->id,
        ]);

        $line1 = InventoryCountLine::create([
            'inventory_count_id' => $count->id,
            'item_id' => $this->item1->id,
            'qty_teorica' => 100,
            'qty_contada' => 0,
            'qty_variacion' => 0,
            'uom' => 'PZ',
        ]);

        $result = $this->service->startCount($count->id, $this->user->id);

        $this->assertEquals(InventoryCount::STATUS_ABIERTO, $result['status']);

        $this->assertDatabaseHas('selemti.inventory_counts', [
            'id' => $count->id,
            'estado' => InventoryCount::STATUS_ABIERTO,
        ]);
    }

    /** @test */
    public function test_can_capture_count_line()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_ABIERTO,
            'programado_para' => now()->subDay(),
            'iniciado_en' => now(),
            'creado_por' => $this->user->id,
        ]);

        $line = InventoryCountLine::create([
            'inventory_count_id' => $count->id,
            'item_id' => $this->item1->id,
            'qty_teorica' => 100,
            'qty_contada' => 0,
            'qty_variacion' => 0,
            'uom' => 'PZ',
        ]);

        $result = $this->service->captureLine($line->id, 98, $this->user->id);

        $this->assertEquals(98, $result['capturado']);

        $this->assertDatabaseHas('selemti.inventory_count_lines', [
            'id' => $line->id,
            'qty_contada' => 98,
        ]);
    }

    /** @test */
    public function test_can_close_count()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_ABIERTO,
            'programado_para' => now()->subDay(),
            'iniciado_en' => now(),
            'creado_por' => $this->user->id,
        ]);

        $line = InventoryCountLine::create([
            'inventory_count_id' => $count->id,
            'item_id' => $this->item1->id,
            'qty_teorica' => 100,
            'qty_contada' => 0,
            'qty_variacion' => 0,
            'uom' => 'PZ',
        ]);

        $this->service->captureLine($line->id, 98, $this->user->id);
        $result = $this->service->closeCount($count->id, $this->user->id);

        $this->assertEquals(InventoryCount::STATUS_CERRADO, $result['status']);

        $this->assertDatabaseHas('selemti.inventory_counts', [
            'id' => $count->id,
            'estado' => InventoryCount::STATUS_CERRADO,
            'cerrado_por' => $this->user->id,
        ]);
    }

    /** @test */
    public function test_cannot_start_count_if_not_programmed()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_CERRADO,
            'programado_para' => now()->subDay(),
            'creado_por' => $this->user->id,
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Count must be in BORRADOR status to be started. Current: CERRADO');

        $this->service->startCount($count->id, $this->user->id);
    }

    /** @test */
    public function test_cannot_capture_line_if_count_not_open()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_PROGRAMADO,
            'programado_para' => now()->subDay(),
            'creado_por' => $this->user->id,
        ]);

        $line = InventoryCountLine::create([
            'inventory_count_id' => $count->id,
            'item_id' => $this->item1->id,
            'qty_teorica' => 100,
            'qty_contada' => 0,
            'qty_variacion' => 0,
            'uom' => 'PZ',
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Count must be in EN_PROCESO status to capture lines. Current: BORRADOR');

        $this->service->captureLine($line->id, 98, $this->user->id);
    }

    /** @test */
    public function test_cannot_close_count_with_uncaptured_lines()
    {
        $count = InventoryCount::create([
            'almacen_id' => (string) $this->almacen->id,
            'sucursal_id' => '1',
            'estado' => InventoryCount::STATUS_ABIERTO,
            'programado_para' => now()->subDay(),
            'iniciado_en' => now(),
            'creado_por' => $this->user->id,
        ]);

        $line = InventoryCountLine::create([
            'inventory_count_id' => $count->id,
            'item_id' => $this->item1->id,
            'qty_teorica' => 100,
            'qty_contada' => 0,
            'qty_variacion' => 0,
            'uom' => 'PZ',
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Cannot close count with uncaptured lines');

        $this->service->closeCount($count->id, $this->user->id);
    }
}
