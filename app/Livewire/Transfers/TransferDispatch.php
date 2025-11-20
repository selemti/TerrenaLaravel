<?php

namespace App\Livewire\Transfers;

use App\Models\Inventory\TransferHeader;
use App\Services\Inventory\TransferService;
use Livewire\Component;

class TransferDispatch extends Component
{
    public int $transferId;

    public string $numeroGuia = '';

    public string $estado = '';

    public array $lines = [];

    public ?string $flashMessage = null;

    public ?string $errorMessage = null;

    public function mount(int $transferId): void
    {
        $this->transferId = $transferId;
        $this->loadTransfer();
    }

    protected function loadTransfer(): void
    {
        $this->errorMessage = null;

        try {
            $transfer = TransferHeader::with('lineas.item')->find($this->transferId);

            if ($transfer) {
                $this->estado = $transfer->estado;
                $this->numeroGuia = $transfer->numero_guia ?? '';
                $this->lines = $transfer->lineas->map(function ($line) {
                    return [
                        'id' => $line->id,
                        'item_id' => $line->item_id,
                        'item_nombre' => optional($line->item)->nombre ?? $line->item_id,
                        'cantidad_solicitada' => $line->cantidad_solicitada,
                        'unidad_medida' => $line->unidad_medida,
                    ];
                })->toArray();

                return;
            }
        } catch (\Throwable $e) {
            // Si no hay tabla o datos, usar placeholders.
        }

        $this->lines = [];
        $this->estado = $this->estado ?: TransferHeader::STATUS_APROBADA;
    }

    public function markInTransit(TransferService $service): void
    {
        $this->flashMessage = null;
        $this->errorMessage = null;

        try {
            $service->markInTransit($this->transferId, auth()->id() ?? 1, $this->numeroGuia ?: null);
            $this->flashMessage = 'Transferencia marcada EN_TRANSITO.';
            $this->estado = TransferHeader::STATUS_EN_TRANSITO;
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    public function render()
    {
        return view('livewire.transfers.dispatch')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Despacho de transferencia',
                'pageTitle' => 'Despachar transferencia',
            ]);
    }
}
