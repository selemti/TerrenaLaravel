<?php

namespace Tests\Feature\Services\Inventory;

use App\Services\Inventory\StockAlertService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class StockAlertServiceTest extends TestCase
{
    use RefreshDatabase;

    private StockAlertService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->ensureStockPolicyTable();
        $this->service = app(StockAlertService::class);
    }

    public function test_returns_only_items_below_min_qty(): void
    {
        $this->item('LOW', 'Low stock item');
        $this->item('OK', 'Enough stock item');
        $this->policy('LOW', ['min_qty' => 10]);
        $this->policy('OK', ['min_qty' => 10]);
        $this->movement('LOW', 4);
        $this->movement('OK', 11);

        $result = $this->service->getAlerts([]);

        $this->assertSame(['LOW'], array_column($result['alerts'], 'item_id'));
    }

    public function test_critical_severity_when_stock_is_zero(): void
    {
        $this->item('ZERO', 'Zero stock item');
        $this->policy('ZERO', ['min_qty' => 5]);

        $alert = $this->service->getAlerts([])['alerts'][0];

        $this->assertSame('critical', $alert['severity']);
        $this->assertSame(0.0, $alert['current_stock']);
    }

    public function test_low_severity_when_stock_between_zero_and_min(): void
    {
        $this->item('LOW', 'Low stock item');
        $this->policy('LOW', ['min_qty' => 5]);
        $this->movement('LOW', 2);

        $alert = $this->service->getAlerts([])['alerts'][0];

        $this->assertSame('low', $alert['severity']);
    }

    public function test_shortage_qty_calculated_correctly(): void
    {
        $this->item('SHORT', 'Short item');
        $this->policy('SHORT', ['min_qty' => 10]);
        $this->movement('SHORT', 3.25);

        $alert = $this->service->getAlerts([])['alerts'][0];

        $this->assertSame(6.75, $alert['shortage_qty']);
    }

    public function test_reorder_qty_uses_reorder_lote_when_set(): void
    {
        $this->item('LOT', 'Lot item');
        $this->policy('LOT', ['min_qty' => 10, 'max_qty' => 50, 'reorder_lote' => 12]);
        $this->movement('LOT', 4);

        $alert = $this->service->getAlerts([])['alerts'][0];

        $this->assertSame(12.0, $alert['reorder_qty']);
    }

    public function test_reorder_qty_falls_back_to_max_minus_current(): void
    {
        $this->item('MAX', 'Max item');
        $this->policy('MAX', ['min_qty' => 10, 'max_qty' => 50, 'reorder_lote' => null]);
        $this->movement('MAX', 4);

        $alert = $this->service->getAlerts([])['alerts'][0];

        $this->assertSame(46.0, $alert['reorder_qty']);
    }

    public function test_severity_filter_critical_only(): void
    {
        $this->item('ZERO', 'Zero stock item');
        $this->item('LOW', 'Low stock item');
        $this->policy('ZERO', ['min_qty' => 5]);
        $this->policy('LOW', ['min_qty' => 5]);
        $this->movement('LOW', 2);

        $result = $this->service->getAlerts(['severity' => 'critical']);

        $this->assertSame(['ZERO'], array_column($result['alerts'], 'item_id'));
    }

    public function test_severity_filter_low_only(): void
    {
        $this->item('ZERO', 'Zero stock item');
        $this->item('LOW', 'Low stock item');
        $this->policy('ZERO', ['min_qty' => 5]);
        $this->policy('LOW', ['min_qty' => 5]);
        $this->movement('LOW', 2);

        $result = $this->service->getAlerts(['severity' => 'low']);

        $this->assertSame(['LOW'], array_column($result['alerts'], 'item_id'));
    }

    public function test_almacen_filter_scopes_stock_calculation(): void
    {
        $this->item('WH', 'Warehouse scoped item');
        $this->policy('WH', ['min_qty' => 10, 'almacen_id' => '1']);
        $this->policy('WH', ['min_qty' => 10, 'almacen_id' => '2']);
        $this->movement('WH', 4, '1');
        $this->movement('WH', 50, '2');

        $result = $this->service->getAlerts(['almacen_id' => '1']);
        $alert = $result['alerts'][0];

        $this->assertSame(1, $result['summary']['total_alerts']);
        $this->assertSame('1', $alert['almacen']['id']);
        $this->assertSame(4.0, $alert['current_stock']);
    }

    public function test_summary_counts_match_rows(): void
    {
        $this->item('ZERO', 'Zero stock item');
        $this->item('LOW', 'Low stock item');
        $this->policy('ZERO', ['min_qty' => 5]);
        $this->policy('LOW', ['min_qty' => 8]);
        $this->movement('LOW', 3);

        $result = $this->service->getAlerts([]);

        $this->assertCount(2, $result['alerts']);
        $this->assertSame(2, $result['summary']['total_alerts']);
        $this->assertSame(1, $result['summary']['critical']);
        $this->assertSame(1, $result['summary']['low']);
        $this->assertSame(10.0, $result['summary']['total_shortage']);
    }

    public function test_pagination_works(): void
    {
        foreach (['A', 'B', 'C'] as $itemId) {
            $this->item($itemId, "Item {$itemId}");
            $this->policy($itemId, ['min_qty' => 10]);
        }

        $result = $this->service->getAlerts(['per_page' => 2, 'page' => 2]);

        $this->assertCount(1, $result['alerts']);
        $this->assertSame(3, $result['pagination']['total']);
        $this->assertSame(2, $result['pagination']['last_page']);
        $this->assertSame(2, $result['pagination']['page']);
    }

    public function test_inactive_policies_excluded(): void
    {
        $this->item('ACTIVE', 'Active policy item');
        $this->item('INACTIVE', 'Inactive policy item');
        $this->policy('ACTIVE', ['min_qty' => 10]);
        $this->policy('INACTIVE', ['min_qty' => 10, 'activo' => false]);

        $result = $this->service->getAlerts([]);

        $this->assertSame(['ACTIVE'], array_column($result['alerts'], 'item_id'));
    }

    private function ensureStockPolicyTable(): void
    {
        if (! Schema::connection('pgsql')->hasTable('selemti.stock_policy')) {
            Schema::connection('pgsql')->create('selemti.stock_policy', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('item_id', 50);
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->decimal('min_qty', 18, 6);
                $table->decimal('max_qty', 18, 6)->nullable();
                $table->decimal('reorder_lote', 18, 6)->nullable();
                $table->boolean('activo')->default(true);
                $table->timestampsTz();
            });
        }

        DB::table('selemti.cat_unidades')->insert([
            'clave' => 'PZ',
            'nombre' => 'Pieza',
            'activo' => true,
        ]);

        DB::table('selemti.cat_almacenes')->insert([
            ['id' => '1', 'clave' => 'WH1', 'nombre' => 'Almacén 1', 'activo' => true],
            ['id' => '2', 'clave' => 'WH2', 'nombre' => 'Almacén 2', 'activo' => true],
        ]);
    }

    private function item(string $id, string $name): void
    {
        DB::table('selemti.items')->insert([
            'id' => $id,
            'item_code' => $id.'-CODE',
            'nombre' => $name,
            'unidad_medida_id' => 1,
            'unidad_medida' => 'PZ',
            'costo_promedio' => 2.5,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function policy(string $itemId, array $overrides = []): void
    {
        DB::table('selemti.stock_policy')->insert(array_merge([
            'item_id' => $itemId,
            'sucursal_id' => '1',
            'almacen_id' => null,
            'min_qty' => 10,
            'max_qty' => null,
            'reorder_lote' => null,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));
    }

    private function movement(string $itemId, float $quantity, ?string $almacenId = null): void
    {
        DB::table('selemti.mov_inv')->insert([
            'item_id' => $itemId,
            'almacen_id' => $almacenId,
            'cantidad' => $quantity,
            'qty' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
