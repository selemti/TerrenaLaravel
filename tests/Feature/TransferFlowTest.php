<?php

namespace Tests\Feature;

use App\Livewire\Transfers\TransferDispatch;
use App\Livewire\Transfers\TransferReceive;
use App\Models\Inventory\TransferHeader;
use App\Models\User;
use App\Services\Inventory\TransferService;
use Livewire\Livewire;
use Mockery;
use Tests\TestCase;

class TransferFlowTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_dispatch_component_marks_in_transit(): void
    {
        $service = Mockery::mock(TransferService::class);
        $service->shouldReceive('markInTransit')
            ->once()
            ->with(123, 7, 'GUIA-1')
            ->andReturn([
                'status' => TransferHeader::STATUS_EN_TRANSITO,
                'transfer_id' => 123,
                'numero_guia' => 'GUIA-1',
            ]);

        app()->instance(TransferService::class, $service);

        $user = User::factory()->make(['id' => 7]);
        $this->actingAs($user);

        Livewire::test(TransferDispatch::class, ['transferId' => 123])
            ->set('estado', TransferHeader::STATUS_APROBADA)
            ->set('numeroGuia', 'GUIA-1')
            ->set('lines', [
                ['id' => 1, 'item_id' => 'SKU-1', 'item_nombre' => 'Item 1', 'cantidad_solicitada' => 2, 'unidad_medida' => 'PZ'],
            ])
            ->call('markInTransit')
            ->assertSet('estado', TransferHeader::STATUS_EN_TRANSITO)
            ->assertSet('flashMessage', 'Transferencia marcada EN_TRANSITO.');
    }

    public function test_receive_component_sends_lines_to_service(): void
    {
        $service = Mockery::mock(TransferService::class);
        $service->shouldReceive('receiveTransfer')
            ->once()
            ->with(321, Mockery::on(function ($lines) {
                return isset($lines[0]['line_id'], $lines[0]['observaciones_generales'])
                    && $lines[0]['line_id'] === 1
                    && $lines[0]['observaciones_generales'] === 'Todo bien'
                    && $lines[1]['line_id'] === 2;
            }), 9)
            ->andReturn([
                'status' => TransferHeader::STATUS_RECIBIDA,
                'varianzas' => [
                    ['line_id' => 1, 'item_id' => 'SKU-1', 'varianza' => -1, 'varianza_porcentaje' => -10],
                ],
            ]);

        app()->instance(TransferService::class, $service);

        $user = User::factory()->make(['id' => 9]);
        $this->actingAs($user);

        Livewire::test(TransferReceive::class, ['transferId' => 321])
            ->set('lines', [
                ['id' => 1, 'item_id' => 'SKU-1', 'item_nombre' => 'Item 1', 'cantidad_despachada' => 10, 'cantidad_recibida' => 9, 'unidad_medida' => 'PZ'],
                ['id' => 2, 'item_id' => 'SKU-2', 'item_nombre' => 'Item 2', 'cantidad_despachada' => 5, 'cantidad_recibida' => 5, 'unidad_medida' => 'PZ'],
            ])
            ->set('observaciones', 'Todo bien')
            ->call('receive')
            ->assertSet('estado', TransferHeader::STATUS_RECIBIDA)
            ->assertSet('varianzas.0.line_id', 1);
    }
}
