<?php

namespace Tests\Feature;

use App\Livewire\Inventory\ReceptionCreate;
use App\Livewire\Inventory\ReceptionDetail;
use App\Models\User;
use App\Services\Inventory\ReceptionService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Mockery;
use Tests\TestCase;

class ReceptionStateTest extends TestCase
{
    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->make(['id' => 1]);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_create_reception_sends_correct_payload_to_service(): void
    {
        Storage::fake('public');
        $this->actingAs($this->user);

        $service = Mockery::mock(ReceptionService::class);
        $service->shouldReceive('createDraftReception')
            ->once()
            ->with(
                Mockery::on(fn ($header) =>
                    $header['supplier_id'] === 5
                    && $header['branch_id'] === 'BR-1'
                    && $header['warehouse_id'] === 'ALM-1'
                    && isset($header['user_id'])
                ),
                Mockery::on(fn ($lines) =>
                    count($lines) === 1
                    && (int) $lines[0]['item_id'] === 100
                    && (float) $lines[0]['costo_unit'] === 10.5
                )
            )
            ->andReturn(77);

        app()->instance(ReceptionService::class, $service);

        $file = UploadedFile::fake()->create('evidencia.jpg', 50, 'image/jpeg');

        $component = app(ReceptionCreate::class);
        $component->mount(true);
        $component->supplier_id = 5;
        $component->branch_id = 'BR-1';
        $component->warehouse_id = 'ALM-1';
        $component->lines = [[
            'item_id'      => '100',
            'qty_pack'     => 2,
            'uom_purchase' => 'PZ',
            'pack_size'    => 1,
            'uom_base'     => 'PZ',
            'lot'          => 'LOTE-1',
            'exp_date'     => '2025-12-31',
            'temp'         => 4,
            'evidence'     => $file,
            'costo_unit'   => 10.5,
        ]];

        $component->save($service);
        $this->addToAssertionCount(1);
    }

    public function test_detail_component_calls_validate_and_post_on_service(): void
    {
        $this->actingAs($this->user);

        $service = Mockery::mock(ReceptionService::class);

        // refreshData() makes a direct DB query — for a non-existent id it sets no estado.
        // We only assert the service methods are called with correct args.
        $service->shouldReceive('validateReception')
            ->once()
            ->with(55, Mockery::type('int'));

        $service->shouldReceive('postReception')
            ->once()
            ->with(55, Mockery::type('int'));

        app()->instance(ReceptionService::class, $service);

        $component = app(ReceptionDetail::class);
        // mount calls refreshData which queries DB — id 55 won't exist in test DB, estado stays default
        $component->mount(55);

        $component->actionValidate($service);
        $component->actionPost($service);

        // Both service methods were called — verified by Mockery expectations
        $this->addToAssertionCount(2);
    }
}
