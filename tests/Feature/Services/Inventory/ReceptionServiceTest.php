<?php

namespace Tests\Feature\Services\Inventory;

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

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(ReceptionService::class);
        // User model uses pgsql connection — create in selemti.users
        $this->user = User::factory()->create([
            'email' => 'test-reception-' . uniqid() . '@terrena.test',
        ]);
        $this->actingAs($this->user);
    }

    protected function tearDown(): void
    {
        // Clean up receptions created during tests
        if ($this->createdReceptionIds) {
            DB::connection('pgsql')
                ->table('selemti.recepcion_det')
                ->whereIn('recepcion_id', $this->createdReceptionIds)
                ->delete();
            DB::connection('pgsql')
                ->table('selemti.recepcion_cab')
                ->whereIn('id', $this->createdReceptionIds)
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
            'supplier_id'  => 1,
            'branch_id'    => null,
            'warehouse_id' => null,
            'user_id'      => $this->user->id,
        ], $overrides);
    }

    private function buildLine(array $overrides = []): array
    {
        return array_merge([
            'item_id'      => 1,
            'qty_pack'     => 10,
            'pack_size'    => 1,
            'uom_purchase' => 'PZ',
            'uom_base'     => 'PZ',
            'lot'          => 'LOTE-TEST',
            'exp_date'     => '2027-12-31',
            'temp'         => null,
            'doc_url'      => null,
            'costo_unit'   => 5.00,
        ], $overrides);
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
}
