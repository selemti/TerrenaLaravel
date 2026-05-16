<?php

namespace Tests\Feature\Services\Production;

use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item;
use App\Models\User;
use App\Services\Production\ProductionOrderReadService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ProductionOrderReadServiceTest extends TestCase
{
    use RefreshDatabase;

    private ProductionOrderReadService $service;

    private Almacen $almacen;

    private User $creator;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(ProductionOrderReadService::class);
        $this->creator = User::factory()->create(['name' => 'Chef Producción']);
        $this->almacen = Almacen::query()->create([
            'clave' => 'PROD',
            'nombre' => 'Almacén Producción',
            'activo' => true,
        ]);

        $this->createItem('9001', 'Salsa Base', 'L');
        $this->createItem('1001', 'Jitomate', 'KG');
        $this->createItem('1002', 'Sal', 'KG');
        $this->createRecipe(77, 'Receta Salsa', 3);
    }

    public function test_list_returns_paginated_orders(): void
    {
        $this->createOrder(['folio' => 'PR-001', 'programado_para' => '2026-05-10 09:00:00']);
        $this->createOrder(['folio' => 'PR-002', 'programado_para' => '2026-05-11 09:00:00']);
        $this->createOrder(['folio' => 'PR-003', 'programado_para' => '2026-05-12 09:00:00']);

        $result = $this->service->list(['per_page' => 2, 'page' => 1]);

        $this->assertCount(2, $result['orders']);
        $this->assertSame(3, $result['pagination']['total']);
        $this->assertSame(2, $result['pagination']['last_page']);
        $this->assertSame('PR-003', $result['orders'][0]['folio']);
    }

    public function test_list_filters_by_estado(): void
    {
        $this->createOrder(['folio' => 'PR-BOR', 'estado' => 'BORRADOR']);
        $this->createOrder(['folio' => 'PR-COM', 'estado' => 'COMPLETADO']);

        $result = $this->service->list(['estado' => 'COMPLETADO']);

        $this->assertCount(1, $result['orders']);
        $this->assertSame('PR-COM', $result['orders'][0]['folio']);
    }

    public function test_list_filters_by_date_range(): void
    {
        $this->createOrder(['folio' => 'PR-MAY-01', 'programado_para' => '2026-05-01 09:00:00']);
        $this->createOrder(['folio' => 'PR-MAY-15', 'programado_para' => '2026-05-15 09:00:00']);
        $this->createOrder(['folio' => 'PR-JUN-01', 'programado_para' => '2026-06-01 09:00:00']);

        $result = $this->service->list(['from' => '2026-05-10', 'to' => '2026-05-31']);

        $this->assertCount(1, $result['orders']);
        $this->assertSame('PR-MAY-15', $result['orders'][0]['folio']);
    }

    public function test_list_includes_recipe_and_item_names(): void
    {
        $this->createOrder();

        $result = $this->service->list([]);

        $this->assertSame(['id' => 77, 'nombre' => 'Receta Salsa'], $result['orders'][0]['recipe']);
        $this->assertSame('Salsa Base', $result['orders'][0]['item_producido']['nombre']);
        $this->assertSame('L', $result['orders'][0]['item_producido']['uom_base']);
    }

    public function test_pct_cumplimiento_calculated(): void
    {
        $this->createOrder([
            'qty_programada' => 20,
            'qty_producida' => 15,
        ]);

        $result = $this->service->list([]);

        $this->assertSame(75.0, $result['orders'][0]['pct_cumplimiento']);
    }

    public function test_detail_returns_full_order(): void
    {
        $orderId = $this->createOrder([
            'folio' => 'PR-DETAIL',
            'notas' => 'Orden para detalle',
        ]);

        $result = $this->service->detail($orderId);

        $this->assertSame($orderId, $result['id']);
        $this->assertSame('PR-DETAIL', $result['folio']);
        $this->assertSame('Completado', $result['estado_label']);
        $this->assertSame(['id' => 77, 'nombre' => 'Receta Salsa', 'version' => '3'], $result['recipe']);
        $this->assertSame('Almacén Producción', $result['almacen']['nombre']);
        $this->assertSame('Chef Producción', $result['creado_por']);
        $this->assertSame('Orden para detalle', $result['notas']);
        $this->assertArrayHasKey('updated_at', $result);
    }

    public function test_detail_includes_inputs_and_outputs(): void
    {
        $orderId = $this->createOrder();
        $this->createInput($orderId, '1001', 2.5, 'KG', 123);
        $this->createInput($orderId, '1002', 0.1, 'KG');
        $this->createOutput($orderId, '9001', 10, 'LT', 'LOT-SALSA-001');

        $result = $this->service->detail($orderId);

        $this->assertCount(2, $result['inputs']);
        $this->assertSame('Jitomate', $result['inputs'][0]['item_nombre']);
        $this->assertSame(2.5, $result['inputs'][0]['qty_actual']);
        $this->assertSame(123, $result['inputs'][0]['lote_id']);
        $this->assertNull($result['inputs'][0]['costo_total']);
        $this->assertCount(1, $result['outputs']);
        $this->assertSame('Salsa Base', $result['outputs'][0]['item_nombre']);
        $this->assertSame('LOT-SALSA-001', $result['outputs'][0]['lote_resultado']);
    }

    public function test_detail_throws_not_found_for_unknown_id(): void
    {
        $this->expectException(ModelNotFoundException::class);

        $this->service->detail(999999);
    }

    public function test_estado_label_mapped_correctly(): void
    {
        $this->createOrder(['folio' => 'PR-POST', 'estado' => 'POSTEADO']);

        $result = $this->service->list([]);

        $this->assertSame('Posteado', $result['orders'][0]['estado_label']);
    }

    private function createItem(string $id, string $nombre, string $uom): void
    {
        Item::query()->create([
            'id' => $id,
            'item_code' => $id,
            'nombre' => $nombre,
            'unidad_medida' => $uom,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createRecipe(int $id, string $nombre, int $version): void
    {
        DB::connection('pgsql')->table('selemti.receta_cab')->insert([
            'id' => (string) $id,
            'nombre_plato' => $nombre,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.receta_version')->insert([
            'receta_id' => (string) $id,
            'version' => $version,
            'version_publicada' => true,
            'created_at' => now(),
        ]);
    }

    private function createOrder(array $overrides = []): int
    {
        return (int) DB::connection('pgsql')->table('selemti.production_orders')->insertGetId(array_merge([
            'folio' => 'PR-READ-001',
            'recipe_id' => 77,
            'item_id' => '9001',
            'qty_programada' => 10,
            'qty_producida' => 8,
            'qty_merma' => 0.5,
            'uom_base' => 'L',
            'sucursal_id' => 'SUC-1',
            'almacen_id' => (string) $this->almacen->id,
            'programado_para' => '2026-05-10 09:00:00',
            'iniciado_en' => '2026-05-10 10:00:00',
            'cerrado_en' => '2026-05-10 12:00:00',
            'estado' => 'COMPLETADO',
            'creado_por' => $this->creator->id,
            'aprobado_por' => null,
            'notas' => null,
            'created_at' => '2026-05-09 08:00:00',
            'updated_at' => '2026-05-10 12:00:00',
        ], $overrides));
    }

    private function createInput(int $orderId, string $itemId, float $qty, string $uom, ?int $batchId = null): void
    {
        DB::connection('pgsql')->table('selemti.production_order_inputs')->insert([
            'production_order_id' => $orderId,
            'item_id' => $itemId,
            'inventory_batch_id' => $batchId,
            'qty' => $qty,
            'uom' => $uom,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createOutput(int $orderId, string $itemId, float $qty, string $uom, ?string $lot = null): void
    {
        DB::connection('pgsql')->table('selemti.production_order_outputs')->insert([
            'production_order_id' => $orderId,
            'item_id' => $itemId,
            'lote_producido' => $lot,
            'qty' => $qty,
            'uom' => $uom,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
