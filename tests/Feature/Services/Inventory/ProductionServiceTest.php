<?php

namespace Tests\Feature\Services\Inventory;

use App\Exceptions\Inventory\InventoryValidationException;
use App\Services\Inventory\ProductionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ProductionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ProductionService $service;

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow('2026-04-15 08:30:00');
        $this->service = app(ProductionService::class);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_create_order_persists_order_lines_batches_waste_and_movements(): void
    {
        $orderId = $this->service->createOrder(
            [
                'recipe_id' => 77,
                'item_id' => 9001,
                'scheduled_qty' => 12,
                'uom' => 'PZ',
                'branch_id' => 'SUC-1',
                'warehouse_id' => 'ALM-1',
                'scheduled_at' => now()->addHour(),
                'user_id' => 55,
                'notes' => 'Produccion de prueba',
                'meta' => ['source' => 'test'],
            ],
            [
                ['item_id' => 1001, 'qty' => 3.5, 'uom' => 'KG'],
            ],
            [
                ['item_id' => 9001, 'qty' => 12, 'uom' => 'PZ', 'lot' => 'LOT-PROD-1'],
            ],
            [
                ['item_id' => 1001, 'qty' => 0.25, 'uom' => 'KG', 'reason' => 'Merma controlada'],
            ]
        );

        $this->assertDatabaseHas('selemti.production_orders', [
            'id' => $orderId,
            'folio' => 'PR-20260415-0001',
            'estado' => 'COMPLETADO',
            'qty_programada' => 12,
            'qty_producida' => 12,
            'qty_merma' => 0.25,
        ]);

        $this->assertDatabaseHas('selemti.production_order_inputs', [
            'production_order_id' => $orderId,
            'item_id' => 1001,
            'qty' => 3.5,
            'uom' => 'KG',
        ]);

        $this->assertDatabaseHas('selemti.production_order_outputs', [
            'production_order_id' => $orderId,
            'item_id' => 9001,
            'qty' => 12,
            'uom' => 'PZ',
        ]);

        $this->assertDatabaseHas('selemti.inventory_wastes', [
            'production_order_id' => $orderId,
            'item_id' => 1001,
            'qty' => 0.25,
            'motivo' => 'Merma controlada',
        ]);

        $this->assertSame(3, DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('ref_tipo', 'production_order')
            ->where('ref_id', $orderId)
            ->count());
    }

    public function test_create_order_requires_inputs(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('Debe registrar al menos un insumo a consumir.');

        $this->service->createOrder(
            ['item_id' => 9001, 'scheduled_qty' => 1, 'uom' => 'PZ'],
            [],
            [['item_id' => 9001, 'qty' => 1, 'uom' => 'PZ']]
        );
    }

    public function test_create_order_requires_outputs(): void
    {
        $this->expectException(InventoryValidationException::class);
        $this->expectExceptionMessage('Debe registrar al menos un producto terminado.');

        $this->service->createOrder(
            ['item_id' => 9001, 'scheduled_qty' => 1, 'uom' => 'PZ'],
            [['item_id' => 1001, 'qty' => 1, 'uom' => 'KG']],
            []
        );
    }
}
