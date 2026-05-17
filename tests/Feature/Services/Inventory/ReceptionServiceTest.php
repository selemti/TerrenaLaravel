<?php

namespace Tests\Feature\Services\Inventory;

use App\Models\PurchaseOrder;
use App\Models\User;
use App\Services\Inventory\ReceptionService;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Integration tests for ReceptionService against real selemti schema.
 * Uses DB::table directly — no RefreshDatabase (selemti is persistent).
 * All inserted rows are cleaned up in tearDown.
 */
class ReceptionServiceTest extends TestCase
{
    protected ReceptionService $service;

    protected User $user;

    /** Reception IDs created during test, cleaned up after */
    private array $createdReceptionIds = [];

    private array $createdPurchaseOrderIds = [];

    private array $createdBatchIds = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(ReceptionService::class);
        // User model uses pgsql connection — create in selemti.users
        $this->user = User::factory()->create([
            'email' => 'test-reception-'.uniqid().'@terrena.test',
        ]);
        $this->actingAs($this->user);
    }

    protected function tearDown(): void
    {
        // Clean up receptions created during tests
        if ($this->createdReceptionIds) {
            $this->createdBatchIds = array_merge($this->createdBatchIds, DB::connection('pgsql')
                ->table('selemti.recepcion_det')
                ->whereIn('recepcion_id', $this->createdReceptionIds)
                ->whereNotNull('inventory_batch_id')
                ->pluck('inventory_batch_id')
                ->all());

            DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->where('ref_tipo', 'recepcion')
                ->whereIn('ref_id', $this->createdReceptionIds)
                ->delete();
            DB::connection('pgsql')
                ->table('selemti.recepcion_det')
                ->whereIn('recepcion_id', $this->createdReceptionIds)
                ->delete();
            DB::connection('pgsql')
                ->table('selemti.recepcion_cab')
                ->whereIn('id', $this->createdReceptionIds)
                ->delete();
        }
        if ($this->createdBatchIds) {
            DB::connection('pgsql')
                ->table('selemti.inventory_batch')
                ->whereIn('id', array_unique($this->createdBatchIds))
                ->delete();
        }
        if ($this->createdPurchaseOrderIds) {
            DB::connection('pgsql')
                ->table('selemti.purchase_order_lines')
                ->whereIn('order_id', $this->createdPurchaseOrderIds)
                ->delete();
            DB::connection('pgsql')
                ->table('selemti.purchase_orders')
                ->whereIn('id', $this->createdPurchaseOrderIds)
                ->delete();
        }
        // Clean up test user (created in selemti.users via pgsql)
        if (isset($this->user) && $this->user->id) {
            DB::connection('pgsql')->table('selemti.users')->where('id', $this->user->id)->delete();
        }
        parent::tearDown();
    }

    private function buildHeader(array $overrides = []): array
    {
        return array_merge([
            'supplier_id' => 1,
            'branch_id' => null,
            'warehouse_id' => null,
            'user_id' => $this->user->id,
        ], $overrides);
    }

    private function buildLine(array $overrides = []): array
    {
        return array_merge([
            'item_id' => 1,
            'qty_pack' => 10,
            'pack_size' => 1,
            'uom_purchase' => 'PZ',
            'uom_base' => 'PZ',
            'lot' => 'LOTE-TEST',
            'exp_date' => '2027-12-31',
            'temp' => null,
            'doc_url' => null,
            'costo_unit' => 5.00,
        ], $overrides);
    }

    private function createPurchaseOrder(array $lineOverrides = []): PurchaseOrder
    {
        $poId = (int) DB::connection('pgsql')->table('selemti.purchase_orders')->insertGetId([
            'folio' => 'PO-TEST-'.uniqid(),
            'vendor_id' => 1,
            'sucursal_id' => 'SUC-1',
            'estado' => PurchaseOrder::ESTADO_APROBADA,
            'subtotal' => 20,
            'descuento' => 0,
            'impuestos' => 0,
            'total' => 20,
            'creado_por' => $this->user->id,
            'aprobado_por' => $this->user->id,
            'aprobado_en' => now(),
            'meta' => json_encode(['almacen_id' => 'ALM-1']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $this->createdPurchaseOrderIds[] = $poId;

        DB::connection('pgsql')->table('selemti.purchase_order_lines')->insert(array_merge([
            'order_id' => $poId,
            'item_id' => 1,
            'qty' => 4,
            'uom' => 'PZ',
            'precio_unitario' => 5,
            'descuento' => 0,
            'impuestos' => 0,
            'total' => 20,
            'meta' => json_encode(['pack_size' => 1, 'uom_base' => 'PZ']),
            'created_at' => now(),
            'updated_at' => now(),
        ], $lineOverrides));

        return PurchaseOrder::with('lines')->findOrFail($poId);
    }

    public function test_create_draft_reception_inserts_cab_and_det(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(),
            [$this->buildLine()]
        );
        $this->createdReceptionIds[] = $id;

        $this->assertIsInt($id);
        $this->assertGreaterThan(0, $id);

        $cab = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $id)->first();
        $this->assertNotNull($cab);
        $this->assertEquals('BORRADOR', $cab->estado);

        $det = DB::connection('pgsql')->table('selemti.recepcion_det')->where('recepcion_id', $id)->get();
        $this->assertCount(1, $det);
    }

    public function test_validate_reception_transitions_to_validada(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(),
            [$this->buildLine()]
        );
        $this->createdReceptionIds[] = $id;

        $this->service->validateReception($id, $this->user->id);

        $cab = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $id)->first();
        $this->assertEquals('VALIDADA', $cab->estado);
    }

    public function test_validate_throws_if_not_borrador(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(),
            [$this->buildLine()]
        );
        $this->createdReceptionIds[] = $id;

        $this->service->validateReception($id, $this->user->id);

        // Trying to validate again must throw
        $this->expectException(\Throwable::class);
        $this->service->validateReception($id, $this->user->id);
    }

    public function test_post_reception_transitions_to_posteada(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(),
            [$this->buildLine(['qty_pack' => 2, 'pack_size' => 1, 'costo_unit' => 10.0])]
        );
        $this->createdReceptionIds[] = $id;

        $this->service->validateReception($id, $this->user->id);
        $this->service->postReception($id, $this->user->id);

        $cab = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $id)->first();
        $this->assertEquals('POSTEADA', $cab->estado);
    }

    public function test_create_from_purchase_order_creates_draft_and_copies_lines(): void
    {
        $po = $this->createPurchaseOrder();

        $reception = $this->service->createFromPurchaseOrder($po);
        $this->createdReceptionIds[] = $reception->id;

        $this->assertEquals('BORRADOR', $reception->estado);
        $this->assertEquals(1, $reception->proveedor_id);
        $this->assertCount(1, $reception->lines);
        $this->assertEquals('1', $reception->lines->first()->item_id);
        $this->assertEquals(4.0, (float) $reception->lines->first()->qty_presentacion);
        $this->assertEquals($po->id, $reception->meta['purchase_order_id']);
    }

    public function test_set_lines_replaces_draft_reception_lines(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(),
            [$this->buildLine(['item_id' => '1', 'qty_pack' => 1])]
        );
        $this->createdReceptionIds[] = $id;

        $this->service->setLines($id, [
            $this->buildLine(['item_id' => '2', 'qty_pack' => 3, 'pack_size' => 2, 'costo_unit' => 7]),
            $this->buildLine(['item_id' => '3', 'qty_pack' => 5, 'pack_size' => 1, 'costo_unit' => 11]),
        ]);

        $lines = DB::connection('pgsql')->table('selemti.recepcion_det')
            ->where('recepcion_id', $id)
            ->orderBy('id')
            ->get();

        $this->assertCount(2, $lines);
        $this->assertEquals(['2', '3'], $lines->pluck('item_id')->all());

        $cab = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $id)->first();
        $this->assertEquals(8.0, (float) $cab->total_presentaciones);
        $this->assertEquals(11.0, (float) $cab->total_canonico);
    }

    public function test_finalize_costing_posts_inventory_and_locks_reception(): void
    {
        $id = $this->service->createDraftReception(
            $this->buildHeader(['branch_id' => 'SUC-1', 'warehouse_id' => 'ALM-1']),
            [$this->buildLine(['item_id' => '1', 'qty_pack' => 2, 'pack_size' => 1, 'costo_unit' => 10.0])]
        );
        $this->createdReceptionIds[] = $id;

        $this->service->finalizeCosting($id);

        $cab = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $id)->first();
        $this->assertEquals('POSTEADA', $cab->estado);

        $movement = DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('ref_tipo', 'recepcion')
            ->where('ref_id', $id)
            ->first();

        $this->assertNotNull($movement);
        $this->assertEquals('RECEPCION_COMPRA', $movement->tipo);
        $this->assertEquals(2.0, (float) $movement->cantidad);
        $this->assertNotNull($movement->inventory_batch_id);
        $this->createdBatchIds[] = $movement->inventory_batch_id;
    }
}
