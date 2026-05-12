<?php

namespace App\Livewire\Transfers;

use App\Models\Inventory\TransferHeader;
use App\Services\Inventory\TransferService;
use Livewire\Component;

class TransferReceive extends Component
{
    public int $transferId;

    public string $estado = '';

    public array $lines = [];

    public array $varianzas = [];

    public string $observaciones = '';

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
                $this->lines = $transfer->lineas->map(function ($line) {
                    $cantidadDespachada = $line->cantidad_despachada ?? $line->cantidad_solicitada;

                    return [
                        'id' => $line->id,
                        'item_id' => $line->item_id,
                        'item_nombre' => optional($line->item)->nombre ?? $line->item_id,
                        'cantidad_despachada' => $cantidadDespachada,
                        'cantidad_recibida' => $line->cantidad_recibida ?? $cantidadDespachada,
                        'unidad_medida' => $line->unidad_medida,
                        'observaciones' => $line->observaciones_recepcion ?? null,
                    ];
                })->toArray();

                return;
            }
        } catch (\Throwable $e) {
            // Si la tabla no existe, usar líneas vacías.
        }

        $this->lines = [];
        $this->estado = $this->estado ?: TransferHeader::STATUS_EN_TRANSITO;
    }

    public function receive(TransferService $service): void
    {
        $this->flashMessage = null;
        $this->errorMessage = null;
        $this->varianzas = [];

        $payload = [];
        foreach ($this->lines as $line) {
            if (! isset($line['id'])) {
                continue;
            }

            $payload[] = [
                'line_id' => $line['id'],
                'cantidad_recibida' => isset($line['cantidad_recibida']) ? (float) $line['cantidad_recibida'] : 0,
                'observaciones' => $line['observaciones'] ?? null,
            ];
        }

        try {
            $result = $service->receiveTransfer($this->transferId, $payload, (int) auth()->id());
            $this->varianzas = $result['varianzas'] ?? [];
            $this->estado = $result['status'] ?? $this->estado;
            $this->flashMessage = 'Transferencia recibida.';
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    public function render()
    {
        return view('livewire.transfers.receive')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Recepción de transferencia',
                'pageTitle' => 'Recibir transferencia',
            ]);
    }
}
