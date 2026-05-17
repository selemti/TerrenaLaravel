<?php

namespace Tests\Feature\Services\Inventory;

use App\Services\Inventory\InventoryValuationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class InventoryValuationServiceTest extends TestCase
{
    use RefreshDatabase;

    private InventoryValuationService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(InventoryValuationService::class);
        $this->seedCatalogs();
    }

    public function test_returns_items_with_stock_and_cost(): void
    {
        $this->item('ITEM-1', 'Harina', ['costo_promedio' => 12.5]);
        $this->movement('ITEM-1', 8);

        $result = $this->service->getValuation([]);

        $this->assertCount(1, $result['items']);
        $this->assertSame('ITEM-1', $result['items'][0]['item_id']);
        $this->assertSame(8.0, $result['items'][0]['current_stock']);
        $this->assertSame(12.5, $result['items'][0]['costo_promedio']);
    }

    public function test_excludes_items_with_zero_stock_by_default(): void
    {
        $this->item('ZERO', 'Sin stock');

        $result = $this->service->getValuation([]);

        $this->assertSame([], array_column($result['items'], 'item_id'));
        $this->assertSame(0, $result['summary']['total_items']);
    }

    public function test_includes_zero_stock_items_when_flag_false(): void
    {
        $this->item('ZERO', 'Sin stock');

        $result = $this->service->getValuation(['only_with_stock' => false]);

        $this->assertSame(['ZERO'], array_column($result['items'], 'item_id'));
        $this->assertSame(0.0, $result['items'][0]['current_stock']);
    }

    public function test_valor_total_is_stock_times_costo_promedio(): void
    {
        $this->item('VALUE', 'Valorizado', ['costo_promedio' => 4.25]);
        $this->movement('VALUE', 3.5);

        $row = $this->service->getValuation([])['items'][0];

        $this->assertSame(14.875, $row['valor_total']);
    }

    public function test_valor_total_null_when_costo_promedio_is_null(): void
    {
        $this->item('NO-COST', 'Sin costo', ['costo_promedio' => null]);
        $this->movement('NO-COST', 5);

        $row = $this->service->getValuation([])['items'][0];

        $this->assertNull($row['valor_total']);
    }

    public function test_summary_totals_match_all_matching_items_not_just_page(): void
    {
        $this->item('A', 'A', ['costo_promedio' => 10]);
        $this->item('B', 'B', ['costo_promedio' => 5]);
        $this->item('C', 'C', ['costo_promedio' => null]);
        $this->movement('A', 2);
        $this->movement('B', 4);
        $this->movement('C', 6);

        $result = $this->service->getValuation(['per_page' => 1, 'page' => 1]);

        $this->assertCount(1, $result['items']);
        $this->assertSame(3, $result['summary']['total_items']);
        $this->assertSame(40.0, $result['summary']['total_value']);
        $this->assertSame(12.0, $result['summary']['total_qty']);
        $this->assertSame(3, $result['pagination']['last_page']);
    }

    public function test_almacen_filter_scopes_stock_aggregation(): void
    {
        $this->item('WH', 'Por almacen', ['costo_promedio' => 2]);
        $this->movement('WH', 3, '1');
        $this->movement('WH', 20, '2');

        $result = $this->service->getValuation(['almacen_id' => '1']);
        $row = $result['items'][0];

        $this->assertSame(3.0, $row['current_stock']);
        $this->assertSame(6.0, $row['valor_total']);
        $this->assertSame('1', $row['almacen']['id']);
        $this->assertSame('WH1', $row['almacen']['clave']);
    }

    public function test_only_active_items_returned(): void
    {
        $this->item('ACTIVE', 'Activo');
        $this->item('INACTIVE', 'Inactivo', ['activo' => false]);
        $this->movement('ACTIVE', 1);
        $this->movement('INACTIVE', 100);

        $result = $this->service->getValuation([]);

        $this->assertSame(['ACTIVE'], array_column($result['items'], 'item_id'));
    }

    public function test_pagination_works(): void
    {
        foreach (['A', 'B', 'C'] as $index => $itemId) {
            $this->item($itemId, "Item {$itemId}", ['costo_promedio' => 10 - $index]);
            $this->movement($itemId, 1);
        }

        $result = $this->service->getValuation(['per_page' => 2, 'page' => 2]);

        $this->assertCount(1, $result['items']);
        $this->assertSame(3, $result['pagination']['total']);
        $this->assertSame(2, $result['pagination']['last_page']);
        $this->assertSame(2, $result['pagination']['page']);
    }

    public function test_sort_by_valor_total_descending(): void
    {
        $this->item('LOW', 'Bajo', ['costo_promedio' => 2]);
        $this->item('HIGH', 'Alto', ['costo_promedio' => 20]);
        $this->item('NULL', 'Sin valor', ['costo_promedio' => 0]);
        $this->movement('LOW', 5);
        $this->movement('HIGH', 3);
        $this->movement('NULL', 100);

        $result = $this->service->getValuation([]);

        $this->assertSame(['HIGH', 'LOW', 'NULL'], array_column($result['items'], 'item_id'));
        $this->assertNull($result['items'][2]['valor_total']);
    }

    private function seedCatalogs(): void
    {
        DB::connection('pgsql')->table('selemti.cat_unidades')->insert([
            'id' => 1,
            'clave' => 'PZ',
            'nombre' => 'Pieza',
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::connection('pgsql')->table('selemti.cat_almacenes')->insert([
            [
                'id' => 1,
                'clave' => 'WH1',
                'nombre' => 'Almacen 1',
                'activo' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 2,
                'clave' => 'WH2',
                'nombre' => 'Almacen 2',
                'activo' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    private function item(string $id, string $name, array $overrides = []): void
    {
        DB::connection('pgsql')->table('selemti.items')->insert(array_merge([
            'id' => $id,
            'item_code' => $id.'-CODE',
            'nombre' => $name,
            'unidad_medida_id' => 1,
            'unidad_medida' => 'PZ',
            'costo_promedio' => 1,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));
    }

    private function movement(string $itemId, float $quantity, ?string $almacenId = null): void
    {
        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'item_id' => $itemId,
            'tipo' => 'IN',
            'cantidad' => $quantity,
            'qty' => null,
            'uom' => 'PZ',
            'almacen_id' => $almacenId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
