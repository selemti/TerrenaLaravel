<?php

namespace Tests\Feature\Services\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Unidad;
use App\Models\Inv\Item;
use App\Models\User;
use App\Services\Inventory\KardexService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class KardexServiceTest extends TestCase
{
    use RefreshDatabase;

    private KardexService $service;

    private Unidad $unit;

    private Item $item;

    private Almacen $almacen;

    private Almacen $otherAlmacen;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(KardexService::class);
        $this->unit = Unidad::query()->create([
            'clave' => 'PZ',
            'nombre' => 'Pieza',
            'activo' => true,
        ]);
        $this->item = Item::query()->create([
            'id' => 'KDX-ITEM-1',
            'item_code' => 'KDX-001',
            'nombre' => 'Producto Kardex',
            'unidad_medida_id' => $this->unit->id,
            'unidad_medida' => 'PZ',
            'activo' => true,
            'costo_promedio' => 10,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $this->almacen = Almacen::query()->create([
            'clave' => 'KDX',
            'nombre' => 'Almacén Kardex',
            'activo' => true,
        ]);
        $this->otherAlmacen = Almacen::query()->create([
            'clave' => 'OTR',
            'nombre' => 'Almacén Alterno',
            'activo' => true,
        ]);
        $this->user = User::factory()->create(['name' => 'Usuario Kardex']);
    }

    public function test_returns_item_summary_with_uom(): void
    {
        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame('KDX-ITEM-1', $result['item']['id']);
        $this->assertSame('KDX-001', $result['item']['code']);
        $this->assertSame('Producto Kardex', $result['item']['nombre']);
        $this->assertSame('PZ', $result['item']['uom_base']);
    }

    public function test_opening_balance_calculated_before_from_date(): void
    {
        $this->movement(['ts' => '2026-04-30 10:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 10]);
        $this->movement(['ts' => '2026-04-30 11:00:00', 'tipo' => 'SALIDA', 'cantidad' => 3]);
        $this->movement(['ts' => '2026-05-01 10:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 5]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame(7.0, $result['opening_balance']);
    }

    public function test_running_balance_computed_correctly(): void
    {
        $this->movement(['ts' => '2026-04-30 10:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 10]);
        $this->movement(['ts' => '2026-05-01 09:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 5]);
        $this->movement(['ts' => '2026-05-02 09:00:00', 'tipo' => 'SALIDA', 'cantidad' => 3]);
        $this->movement(['ts' => '2026-05-03 09:00:00', 'tipo' => 'AJUSTE', 'cantidad' => -2]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame([10.0, 12.0, 15.0], array_column($result['movements'], 'saldo'));
    }

    public function test_closing_balance_matches_opening_plus_net(): void
    {
        $this->movement(['ts' => '2026-04-30 10:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 10]);
        $this->movement(['ts' => '2026-05-01 09:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 5]);
        $this->movement(['ts' => '2026-05-02 09:00:00', 'tipo' => 'SALIDA', 'cantidad' => 3]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame(12.0, $result['closing_balance']);
        $this->assertSame(2.0, $result['totals']['net']);
    }

    public function test_tipo_label_mapped_correctly(): void
    {
        $this->movement([
            'ts' => '2026-05-01 09:00:00',
            'tipo' => 'ENTRADA',
            'ref_tipo' => 'RECEPCION',
            'cantidad' => 5,
        ]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame('Recepción de compra', $result['movements'][0]['tipo_label']);
    }

    public function test_produccion_type_is_negative_by_default(): void
    {
        $this->movement([
            'ts' => '2026-05-01 09:00:00',
            'tipo' => 'PRODUCCION',
            'ref_tipo' => 'PRODUCCION',
            'cantidad' => 4,
        ]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame(-1, $result['movements'][0]['signo']);
        $this->assertSame(-4.0, $result['totals']['net']);
        $this->assertSame(4.0, $result['totals']['salidas']);
    }

    public function test_movement_includes_batch_traceability(): void
    {
        $batchId = (int) DB::connection('pgsql')->table('selemti.inventory_batch')->insertGetId([
            'item_id' => $this->item->id,
            'lote_proveedor' => 'LOT-KDX-001',
            'cantidad_original' => 5,
            'cantidad_actual' => 5,
            'uom_base' => 'PZ',
            'caducidad' => '2026-06-30',
            'estado' => 'ACTIVO',
            'sucursal_id' => '1',
            'almacen_id' => (string) $this->almacen->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->movement([
            'inventory_batch_id' => $batchId,
            'lote_id' => $batchId,
            'ts' => '2026-05-01 09:00:00',
        ]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame($batchId, $result['movements'][0]['lote']['id']);
        $this->assertSame('LOT-KDX-001', $result['movements'][0]['lote']['lote_proveedor']);
        $this->assertSame('2026-06-30', $result['movements'][0]['lote']['fecha_caducidad']);
    }

    public function test_date_filter_applied(): void
    {
        $this->movement(['ts' => '2026-05-01 09:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 5]);
        $this->movement(['ts' => '2026-05-10 09:00:00', 'tipo' => 'ENTRADA', 'cantidad' => 7]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-10',
            'to' => '2026-05-10',
        ]);

        $this->assertCount(1, $result['movements']);
        $this->assertSame(7.0, $result['movements'][0]['qty_base']);
    }

    public function test_almacen_filter_applied(): void
    {
        $this->movement(['almacen_id' => (string) $this->almacen->id, 'cantidad' => 5]);
        $this->movement(['almacen_id' => (string) $this->otherAlmacen->id, 'cantidad' => 7]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
            'almacen_id' => (string) $this->almacen->id,
        ]);

        $this->assertCount(1, $result['movements']);
        $this->assertSame((string) $this->almacen->id, $result['movements'][0]['almacen']['id']);
    }

    public function test_tipo_filter_applied(): void
    {
        $this->movement(['tipo' => 'ENTRADA', 'cantidad' => 5]);
        $this->movement(['tipo' => 'SALIDA', 'cantidad' => 2]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
            'tipo' => 'SALIDA',
        ]);

        $this->assertCount(1, $result['movements']);
        $this->assertSame('SALIDA', $result['movements'][0]['tipo']);
    }

    public function test_pagination_works(): void
    {
        $this->movement(['ts' => '2026-05-01 09:00:00', 'cantidad' => 1]);
        $this->movement(['ts' => '2026-05-02 09:00:00', 'cantidad' => 2]);
        $this->movement(['ts' => '2026-05-03 09:00:00', 'cantidad' => 3]);

        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
            'per_page' => 2,
            'page' => 1,
        ]);

        $this->assertCount(2, $result['movements']);
        $this->assertSame(3, $result['pagination']['total']);
        $this->assertSame(2, $result['pagination']['last_page']);
        $this->assertSame(3.0, $result['movements'][0]['qty_base']);
    }

    public function test_empty_period_returns_zero_totals(): void
    {
        $result = $this->service->getKardex($this->item->id, [
            'from' => '2026-05-01',
            'to' => '2026-05-31',
        ]);

        $this->assertSame([], $result['movements']);
        $this->assertSame(0.0, $result['totals']['entradas']);
        $this->assertSame(0.0, $result['totals']['salidas']);
        $this->assertSame(0.0, $result['totals']['net']);
        $this->assertSame(0.0, $result['totals']['costo_total']);
    }

    public function test_404_for_unknown_item(): void
    {
        Sanctum::actingAs($this->user);

        $this->getJson('/api/inventory/items/UNKNOWN-KDX/kardex?from=2026-05-01&to=2026-05-31')
            ->assertNotFound()
            ->assertJson([
                'ok' => false,
                'error' => 'item_not_found',
            ]);
    }

    private function movement(array $overrides = []): int
    {
        return (int) DB::connection('pgsql')->table('selemti.mov_inv')->insertGetId(array_merge([
            'item_id' => $this->item->id,
            'inventory_batch_id' => null,
            'tipo' => 'ENTRADA',
            'qty' => null,
            'cantidad' => 5,
            'qty_original' => 5,
            'uom' => 'PZ',
            'uom_original_id' => $this->unit->id,
            'costo_unit' => 2,
            'sucursal_id' => '1',
            'almacen_id' => (string) $this->almacen->id,
            'ref_tipo' => 'RECEPCION',
            'ref_id' => 100,
            'usuario_id' => $this->user->id,
            'ts' => '2026-05-01 09:00:00',
            'notas' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));
    }
}
