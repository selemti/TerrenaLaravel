<?php

namespace Tests\Feature\Services\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\User;
use App\Services\Inventory\PosConsumptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PosConsumptionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Almacen $almacen;

    protected Item $productoFinal;

    protected Item $insumo1;

    protected Item $insumo2;

    protected PosConsumptionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->markTestSkipped('PosConsumptionService: selemti.recetas_componentes table and service not implemented');

        $this->service = app(PosConsumptionService::class);

        $this->user = User::factory()->create();
        $this->almacen = Almacen::factory()->create([
            'nombre' => 'Almacén Principal',
            'clave' => 'ALM-001',
        ]);

        // Crear producto final (producto vendido)
        $this->productoFinal = Item::factory()->create([
            'nombre' => 'Hamburguesa Clásica',
            'clave' => 'HAMB-001',
            'tipo' => 'VENTA', // Producto para venta
        ]);

        // Crear insumos (componentes del producto)
        $this->insumo1 = Item::factory()->create([
            'nombre' => 'Carne molida',
            'clave' => 'CARNE-001',
            'tipo' => 'INSUMO',
        ]);

        $this->insumo2 = Item::factory()->create([
            'nombre' => 'Pan para hamburguesa',
            'clave' => 'PAN-001',
            'tipo' => 'INSUMO',
        ]);

        // Crear stock inicial para los insumos
        DB::connection('pgsql')->table('selemti.stock')->insert([
            'almacen_id' => $this->almacen->id,
            'item_id' => $this->insumo1->id,
            'cantidad_actual' => 50, // 50 kg de carne
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.stock')->insert([
            'almacen_id' => $this->almacen->id,
            'item_id' => $this->insumo2->id,
            'cantidad_actual' => 100, // 100 piezas de pan
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Crear receta para el producto final (componentes)
        DB::connection('pgsql')->table('selemti.recetas_componentes')->insert([
            'item_id' => $this->productoFinal->id,
            'item_componente_id' => $this->insumo1->id, // carne molida
            'cantidad_necesaria' => 0.2, // 0.2 kg de carne por hamburguesa
            'unidad_medida' => 'KG',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.recetas_componentes')->insert([
            'item_id' => $this->productoFinal->id,
            'item_componente_id' => $this->insumo2->id, // pan
            'cantidad_necesaria' => 1, // 1 pan por hamburguesa
            'unidad_medida' => 'PZ',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /** @test */
    public function test_can_calculate_consumption_from_sale()
    {
        $venta = [
            'items' => [
                [
                    'item_id' => $this->productoFinal->id,
                    'cantidad' => 5,
                    'unidad_medida' => 'PZ',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        $consumption = $this->service->calculateConsumptionFromSale($venta);

        // Para 5 hamburguesas:
        // - Cada una requiere 0.2 kg de carne => 5 * 0.2 = 1 kg de carne
        // - Cada una requiere 1 pan => 5 * 1 = 5 panes
        $this->assertCount(2, $consumption['items']);

        $carneConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo1->id);
        $panConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo2->id);

        $this->assertEquals(1.0, $carneConsumo['cantidad']); // 1 kg de carne
        $this->assertEquals(5, $panConsumo['cantidad']);     // 5 panes
    }

    /** @test */
    public function test_can_post_consumption_to_inventory()
    {
        $consumption = [
            'venta_id' => 1001,
            'items' => [
                [
                    'item_id' => $this->insumo1->id, // carne
                    'cantidad' => 1.0,
                    'unidad_medida' => 'KG',
                    'observaciones' => 'Consumo por venta de hamburguesas',
                ],
                [
                    'item_id' => $this->insumo2->id, // pan
                    'cantidad' => 5,
                    'unidad_medida' => 'PZ',
                    'observaciones' => 'Consumo por venta de hamburguesas',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        $result = $this->service->postConsumptionToInventory($consumption, $this->user->id);

        $this->assertArrayHasKey('movimientos_generados', $result);
        $this->assertEquals(2, $result['movimientos_generados']);

        // Verificar que se crearon los movimientos de salida
        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacen->id,
            'item_id' => $this->insumo1->id,
            'tipo_movimiento' => 'SALIDA',
            'cantidad' => -1.0,
            'referencia_tipo' => 'VENTA',
            'referencia_id' => 1001,
        ]);

        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacen->id,
            'item_id' => $this->insumo2->id,
            'tipo_movimiento' => 'SALIDA',
            'cantidad' => -5,
            'referencia_tipo' => 'VENTA',
            'referencia_id' => 1001,
        ]);

        // Verificar que se actualizó el stock
        $carneStock = DB::connection('pgsql')
            ->table('selemti.stock')
            ->where('almacen_id', $this->almacen->id)
            ->where('item_id', $this->insumo1->id)
            ->first();

        $this->assertEquals(49.0, $carneStock->cantidad_actual); // 50 - 1 = 49

        $panStock = DB::connection('pgsql')
            ->table('selemti.stock')
            ->where('almacen_id', $this->almacen->id)
            ->where('item_id', $this->insumo2->id)
            ->first();

        $this->assertEquals(95, $panStock->cantidad_actual); // 100 - 5 = 95
    }

    /** @test */
    public function test_calculate_consumption_respects_recipe()
    {
        $venta = [
            'items' => [
                [
                    'item_id' => $this->productoFinal->id,
                    'cantidad' => 3,
                    'unidad_medida' => 'PZ',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        $consumption = $this->service->calculateConsumptionFromSale($venta);

        // Para 3 hamburguesas:
        // - Carne: 3 * 0.2 = 0.6 kg
        // - Pan: 3 * 1 = 3 panes
        $carneConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo1->id);
        $panConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo2->id);

        $this->assertEquals(0.6, $carneConsumo['cantidad']);
        $this->assertEquals(3, $panConsumo['cantidad']);
    }

    /** @test */
    public function test_validation_fails_if_insufficient_stock()
    {
        // Agregar stock insuficiente para el insumo de prueba
        DB::connection('pgsql')->table('selemti.stock')
            ->where('item_id', $this->insumo1->id)
            ->update(['cantidad_actual' => 0.1]); // Solo 0.1 kg

        $venta = [
            'items' => [
                [
                    'item_id' => $this->productoFinal->id,
                    'cantidad' => 2, // Esto requeriría 0.4 kg de carne, pero solo hay 0.1 kg
                    'unidad_medida' => 'PZ',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Insufficient stock for item: Carne molida');

        $this->service->validateStockBeforeConsumption($venta);
    }

    /** @test */
    public function test_validation_passes_if_sufficient_stock()
    {
        $venta = [
            'items' => [
                [
                    'item_id' => $this->productoFinal->id,
                    'cantidad' => 2, // 2 hamburguesas
                    'unidad_medida' => 'PZ',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        // Validación debería pasar sin excepciones
        $result = $this->service->validateStockBeforeConsumption($venta);
        $this->assertTrue($result); // Debería devolver true si hay stock suficiente
    }

    /** @test */
    public function test_consumption_calculation_excludes_non_recipe_items()
    {
        $otroProducto = Item::factory()->create([
            'nombre' => 'Refresco',
            'clave' => 'REF-001',
            'tipo' => 'VENTA',
        ]);

        $venta = [
            'items' => [
                [
                    'item_id' => $this->productoFinal->id, // Hamburguesa (tiene receta)
                    'cantidad' => 2,
                    'unidad_medida' => 'PZ',
                ],
                [
                    'item_id' => $otroProducto->id, // Refresco (no tiene receta)
                    'cantidad' => 3,
                    'unidad_medida' => 'PZ',
                ],
            ],
            'almacen_id' => $this->almacen->id,
        ];

        $consumption = $this->service->calculateConsumptionFromSale($venta);

        // Debería solo calcular el consumo para los componentes de hamburguesas
        $this->assertCount(2, $consumption['items']); // 2 insumos para hamburguesas

        $carneConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo1->id);
        $panConsumo = collect($consumption['items'])->firstWhere('item_id', $this->insumo2->id);

        // Para 2 hamburguesas
        $this->assertEquals(0.4, $carneConsumo['cantidad']); // 2 * 0.2 kg
        $this->assertEquals(2, $panConsumo['cantidad']);     // 2 * 1 pan
    }
}
