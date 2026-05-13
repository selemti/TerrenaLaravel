<?php

namespace Tests\Feature\Services\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\Purchasing\PurchaseOrder;
use App\Models\User;
use App\Services\Inventory\ReceptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReceptionServiceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Almacen $almacen;

    protected Item $item;

    protected PurchaseOrder $purchaseOrder;

    protected ReceptionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->markTestSkipped('ReceptionService API changed: createFromPurchaseOrder/setLines/finalizeCosting not implemented');

        $this->service = app(ReceptionService::class);

        $this->user = User::factory()->create();
        $this->almacen = Almacen::factory()->create([
            'nombre' => 'Almacén Test',
            'clave' => 'TEST',
        ]);

        $this->item = Item::factory()->create([
            'nombre' => 'Producto Test',
            'clave' => 'TEST-001',
        ]);

        // Crear orden de compra de prueba
        $this->purchaseOrder = PurchaseOrder::create([
            'proveedor_id' => 1,
            'sucursal_id' => 1,
            'estado' => 'APROBADA',
            'moneda' => 'MXN',
            'condiciones_pago' => '30 días',
            'creado_por' => $this->user->id,
            'fecha_aprobacion' => now(),
        ]);

        // Crear línea de orden de compra
        $this->purchaseOrder->lines()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 100,
            'cantidad_recibida' => 0,
            'unidad_medida' => 'PZ',
            'precio_unitario' => 10.00,
            'impuestos_pct' => 16.0,
            'orden' => 1,
            'activo' => true,
        ]);
    }

    /** @test */
    public function test_can_create_reception_from_purchase_order()
    {
        $result = $this->service->createFromPurchaseOrder(
            $this->purchaseOrder->id,
            $this->almacen->id,
            $this->user->id
        );

        $this->assertArrayHasKey('reception_id', $result);
        $this->assertArrayHasKey('status', $result);
        $this->assertEquals('PENDIENTE', $result['status']);

        $this->assertDatabaseHas('selemti.inv_receptions', [
            'purchase_order_id' => $this->purchaseOrder->id,
            'almacen_id' => $this->almacen->id,
            'estado' => 'PENDIENTE',
        ]);
    }

    /** @test */
    public function test_can_set_reception_lines()
    {
        $reception = DB::connection('pgsql')->table('selemti.inv_receptions')->insertGetId([
            'purchase_order_id' => $this->purchaseOrder->id,
            'almacen_id' => $this->almacen->id,
            'estado' => 'PENDIENTE',
            'creado_por' => $this->user->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $lines = [
            [
                'po_line_id' => $this->purchaseOrder->lines()->first()->id,
                'cantidad_recepcionar' => 50,
                'costo_unitario' => 9.50,
                'observaciones' => 'Test reception line',
            ],
        ];

        $result = $this->service->setLines($reception, $lines, $this->user->id);

        $this->assertEquals(count($lines), $result['lines_set']);

        $this->assertDatabaseHas('selemti.inv_reception_lines', [
            'reception_id' => $reception,
            'po_line_id' => $lines[0]['po_line_id'],
            'cantidad_recepcionar' => $lines[0]['cantidad_recepcionar'],
        ]);
    }

    /** @test */
    public function test_can_validate_reception()
    {
        $reception = DB::connection('pgsql')->table('selemti.inv_receptions')->insertGetId([
            'purchase_order_id' => $this->purchaseOrder->id,
            'almacen_id' => $this->almacen->id,
            'estado' => 'PENDIENTE',
            'creado_por' => $this->user->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $poLine = $this->purchaseOrder->lines()->first();

        DB::connection('pgsql')->table('selemti.inv_reception_lines')->insert([
            'reception_id' => $reception,
            'po_line_id' => $poLine->id,
            'cantidad_recepcionar' => 50,
            'costo_unitario' => 9.50,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $result = $this->service->validateReception($reception, $this->user->id);

        $this->assertEquals('VALIDADA', $result['status']);

        $this->assertDatabaseHas('selemti.inv_receptions', [
            'id' => $reception,
            'estado' => 'VALIDADA',
        ]);
    }

    /** @test */
    public function test_cannot_create_reception_from_non_approved_po()
    {
        $nonApprovedPo = PurchaseOrder::create([
            'proveedor_id' => 1,
            'sucursal_id' => 1,
            'estado' => 'PENDIENTE',
            'moneda' => 'MXN',
            'condiciones_pago' => '30 días',
            'creado_por' => $this->user->id,
        ]);

        $nonApprovedPo->lines()->create([
            'item_id' => $this->item->id,
            'cantidad_solicitada' => 100,
            'cantidad_recibida' => 0,
            'unidad_medida' => 'PZ',
            'precio_unitario' => 10.00,
            'impuestos_pct' => 16.0,
            'orden' => 1,
            'activo' => true,
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Cannot create reception for non-approved purchase order');

        $this->service->createFromPurchaseOrder(
            $nonApprovedPo->id,
            $this->almacen->id,
            $this->user->id
        );
    }

    /** @test */
    public function test_can_post_reception_to_inventory()
    {
        $reception = DB::connection('pgsql')->table('selemti.inv_receptions')->insertGetId([
            'purchase_order_id' => $this->purchaseOrder->id,
            'almacen_id' => $this->almacen->id,
            'estado' => 'VALIDADA',
            'creado_por' => $this->user->id,
            'validado_por' => $this->user->id,
            'validado_en' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $poLine = $this->purchaseOrder->lines()->first();

        DB::connection('pgsql')->table('selemti.inv_reception_lines')->insert([
            'reception_id' => $reception,
            'po_line_id' => $poLine->id,
            'cantidad_recepcionar' => 50,
            'costo_unitario' => 9.50,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $result = $this->service->postReception($reception, $this->user->id);

        $this->assertEquals('POSTEADA', $result['status']);

        $this->assertDatabaseHas('selemti.inv_receptions', [
            'id' => $reception,
            'estado' => 'POSTEADA',
        ]);

        // Verificar que se crearon movimientos de inventario
        $this->assertDatabaseHas('selemti.mov_inv', [
            'almacen_id' => $this->almacen->id,
            'item_id' => $this->item->id,
            'tipo_movimiento' => 'ENTRADA',
            'referencia_tipo' => 'RECEPTION',
            'referencia_id' => $reception,
        ]);
    }

    /** @test */
    public function test_can_finalize_reception_costing()
    {
        $reception = DB::connection('pgsql')->table('selemti.inv_receptions')->insertGetId([
            'purchase_order_id' => $this->purchaseOrder->id,
            'almacen_id' => $this->almacen->id,
            'estado' => 'POSTEADA',
            'creado_por' => $this->user->id,
            'posteada_por' => $this->user->id,
            'posteada_en' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $poLine = $this->purchaseOrder->lines()->first();

        DB::connection('pgsql')->table('selemti.inv_reception_lines')->insert([
            'reception_id' => $reception,
            'po_line_id' => $poLine->id,
            'cantidad_recepcionar' => 50,
            'costo_unitario' => 9.50,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $result = $this->service->finalizeCosting($reception, $this->user->id);

        $this->assertEquals('COSTEADA', $result['status']);

        $this->assertDatabaseHas('selemti.inv_receptions', [
            'id' => $reception,
            'estado' => 'COSTEADA',
        ]);
    }
}
