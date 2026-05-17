<?php

namespace Tests\Feature\Services\Inventory;

use App\Services\Inventory\BatchExpiryService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BatchExpiryServiceTest extends TestCase
{
    private BatchExpiryService $service;

    private CarbonImmutable $today;

    private string $expiryColumn;

    private array $itemIds = [];

    private array $batchIds = [];

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = app(BatchExpiryService::class);
        $this->today = CarbonImmutable::parse(
            DB::connection('pgsql')->selectOne('SELECT CURRENT_DATE::date as today')->today
        );
        $this->expiryColumn = Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'fecha_caducidad')
            ? 'fecha_caducidad'
            : 'caducidad';

        $this->ensureUnitCostColumn();
        $this->seedLookupRows();
    }

    protected function tearDown(): void
    {
        if ($this->batchIds) {
            DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->whereIn('id', array_unique($this->batchIds))
                ->delete();
        }

        if ($this->itemIds) {
            DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->whereIn('item_id', array_unique($this->itemIds))
                ->delete();

            DB::connection('pgsql')
                ->table('selemti.items')
                ->whereIn('id', array_unique($this->itemIds))
                ->delete();
        }

        DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->whereIn('id', ['901001', '901002'])
            ->delete();

        parent::tearDown();
    }

    public function test_returns_batches_within_default_7_day_horizon(): void
    {
        $this->item('IN-7', 'Dentro 7');
        $this->item('OUT-8', 'Fuera 8');
        $this->batch('IN-7', 7);
        $this->batch('OUT-8', 8);

        $result = $this->service->getExpiringBatches([]);

        $this->assertSame(['IN-7'], array_column($result['batches'], 'item_id'));
    }

    public function test_respects_custom_days_filter(): void
    {
        $this->item('DAY-10', 'Diez dias');
        $this->item('DAY-11', 'Once dias');
        $this->batch('DAY-10', 10);
        $this->batch('DAY-11', 11);

        $result = $this->service->getExpiringBatches(['days' => 10]);

        $this->assertSame(['DAY-10'], array_column($result['batches'], 'item_id'));
    }

    public function test_excludes_expired_by_default(): void
    {
        $this->item('OLD', 'Vencido');
        $this->item('NEW', 'Vigente');
        $this->batch('OLD', -1);
        $this->batch('NEW', 1);

        $result = $this->service->getExpiringBatches([]);

        $this->assertSame(['NEW'], array_column($result['batches'], 'item_id'));
    }

    public function test_includes_expired_when_flag_true(): void
    {
        $this->item('OLD', 'Vencido');
        $this->item('NEW', 'Vigente');
        $this->batch('OLD', -1);
        $this->batch('NEW', 1);

        $result = $this->service->getExpiringBatches(['include_expired' => true]);

        $this->assertSame(['OLD', 'NEW'], array_column($result['batches'], 'item_id'));
    }

    public function test_excludes_empty_batches_by_default(): void
    {
        $this->item('EMPTY', 'Sin cantidad');
        $this->item('FULL', 'Con cantidad');
        $this->batch('EMPTY', 1, ['cantidad_actual' => 0]);
        $this->batch('FULL', 1, ['cantidad_actual' => 3]);

        $result = $this->service->getExpiringBatches([]);

        $this->assertSame(['FULL'], array_column($result['batches'], 'item_id'));
    }

    public function test_includes_empty_batches_when_flag_false(): void
    {
        $this->item('EMPTY', 'Sin cantidad');
        $this->batch('EMPTY', 1, ['cantidad_actual' => 0]);

        $result = $this->service->getExpiringBatches(['only_with_qty' => false]);

        $this->assertSame(['EMPTY'], array_column($result['batches'], 'item_id'));
        $this->assertSame(0.0, $result['batches'][0]['qty_actual']);
    }

    public function test_estado_vencido_when_past_expiry(): void
    {
        $this->item('OLD', 'Vencido');
        $this->batch('OLD', -1);

        $batch = $this->service->getExpiringBatches(['include_expired' => true])['batches'][0];

        $this->assertSame('VENCIDO', $batch['estado']);
    }

    public function test_estado_critico_within_2_days(): void
    {
        $this->item('CRIT', 'Critico');
        $this->batch('CRIT', 2);

        $batch = $this->service->getExpiringBatches([])['batches'][0];

        $this->assertSame('CRITICO', $batch['estado']);
    }

    public function test_estado_proximo_within_7_days(): void
    {
        $this->item('NEXT', 'Proximo');
        $this->batch('NEXT', 5);

        $batch = $this->service->getExpiringBatches([])['batches'][0];

        $this->assertSame('PROXIMO', $batch['estado']);
    }

    public function test_valor_en_riesgo_is_qty_times_costo(): void
    {
        $this->item('VALUE', 'Valor');
        $this->batch('VALUE', 1, ['cantidad_actual' => 3.5, 'unit_cost' => 12.25]);

        $batch = $this->service->getExpiringBatches([])['batches'][0];

        $this->assertSame(42.875, $batch['valor_en_riesgo']);
    }

    public function test_almacen_filter_works(): void
    {
        $this->item('WH1', 'Almacen 1');
        $this->item('WH2', 'Almacen 2');
        $this->batch('WH1', 1, ['almacen_id' => '901001']);
        $this->batch('WH2', 1, ['almacen_id' => '901002']);

        $result = $this->service->getExpiringBatches(['almacen_id' => '901002']);

        $this->assertSame(['WH2'], array_column($result['batches'], 'item_id'));
        $this->assertSame('901002', $result['batches'][0]['almacen']['id']);
    }

    public function test_sorted_by_fecha_caducidad_ascending(): void
    {
        $this->item('LATE', 'Tarde');
        $this->item('EARLY', 'Temprano');
        $this->item('SAME-HIGH', 'Misma fecha alta');
        $this->batch('LATE', 5);
        $this->batch('EARLY', 1);
        $this->batch('SAME-HIGH', 1, ['cantidad_actual' => 20]);

        $result = $this->service->getExpiringBatches([]);

        $this->assertSame(['SAME-HIGH', 'EARLY', 'LATE'], array_column($result['batches'], 'item_id'));
    }

    public function test_summary_counts_correct(): void
    {
        $this->item('OLD', 'Vencido');
        $this->item('SOON', 'Pronto');
        $this->item('EMPTY', 'Sin cantidad');
        $this->batch('OLD', -1, ['cantidad_actual' => 2, 'unit_cost' => 5]);
        $this->batch('SOON', 3, ['cantidad_actual' => 4, 'unit_cost' => 7]);
        $this->batch('EMPTY', 4, ['cantidad_actual' => 0, 'unit_cost' => 9]);

        $result = $this->service->getExpiringBatches(['include_expired' => true, 'only_with_qty' => false]);

        $this->assertSame(1, $result['summary']['expiring_soon']);
        $this->assertSame(1, $result['summary']['already_expired']);
        $this->assertSame(38.0, $result['summary']['total_exposure']);
    }

    public function test_pagination_works(): void
    {
        foreach (['A', 'B', 'C'] as $index => $itemId) {
            $this->item($itemId, "Item {$itemId}");
            $this->batch($itemId, $index + 1);
        }

        $result = $this->service->getExpiringBatches(['per_page' => 2, 'page' => 2]);

        $this->assertCount(1, $result['batches']);
        $this->assertSame(3, $result['pagination']['total']);
        $this->assertSame(2, $result['pagination']['last_page']);
        $this->assertSame(2, $result['pagination']['page']);
    }

    public function test_null_fecha_caducidad_never_included(): void
    {
        $this->item('NULL-DATE', 'Sin caducidad');
        $this->batch('NULL-DATE', null);

        $result = $this->service->getExpiringBatches(['only_with_qty' => false, 'include_expired' => true]);

        $this->assertSame([], $result['batches']);
    }

    private function seedLookupRows(): void
    {
        DB::connection('pgsql')->table('selemti.cat_almacenes')->updateOrInsert(
            ['id' => 901001],
            ['clave' => 'WHA', 'nombre' => 'Almacen A', 'activo' => true]
        );

        DB::connection('pgsql')->table('selemti.cat_almacenes')->updateOrInsert(
            ['id' => 901002],
            ['clave' => 'WHB', 'nombre' => 'Almacen B', 'activo' => true]
        );
    }

    private function ensureUnitCostColumn(): void
    {
        if (Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'unit_cost')) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.inventory_batch', function (Blueprint $table) {
            $table->decimal('unit_cost', 12, 4)->nullable();
        });
    }

    private function item(string $id, string $name): void
    {
        $this->itemIds[] = $id;

        DB::connection('pgsql')->table('selemti.items')->insert([
            'id' => $id,
            'item_code' => $id.'-CODE',
            'nombre' => $name,
            'unidad_medida' => 'PZ',
            'costo_promedio' => 1,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function batch(string $itemId, ?int $daysFromToday, array $overrides = []): int
    {
        $expiryDate = $daysFromToday === null
            ? null
            : $this->today->addDays($daysFromToday)->toDateString();

        $batchId = (int) DB::connection('pgsql')->table('selemti.inventory_batch')->insertGetId(array_merge([
            'item_id' => $itemId,
            'lote_proveedor' => 'LOT-'.$itemId.'-'.uniqid(),
            'cantidad_original' => 10,
            'cantidad_actual' => 10,
            'uom_base' => 'PZ',
            $this->expiryColumn => $expiryDate,
            'estado' => 'ACTIVO',
            'sucursal_id' => 'SUC-1',
            'almacen_id' => '901001',
            'unit_cost' => 2.5,
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));

        $this->batchIds[] = $batchId;

        return $batchId;
    }
}
