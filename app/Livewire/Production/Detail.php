<?php

namespace App\Livewire\Production;

use App\Models\ProductionOrder;
use Illuminate\Contracts\View\View;
use Livewire\Component;

class Detail extends Component
{
    public ProductionOrder $order;

    /** @var array<int, array<string, mixed>> */
    public array $consumos = [];

    /** @var array<int, array<string, mixed>> */
    public array $salidas = [];

    /** @var array<int, array<string, mixed>> */
    public array $mermas = [];

    public function mount(int $id): void
    {
        $this->loadOrder($id);
    }

    public function render(): View
    {
        return view('livewire.production.detail')->layout('layouts.terrena', [
            'active' => 'produccion',
            'title' => 'Detalle de orden de producción',
            'pageTitle' => 'Detalle de Orden',
        ]);
    }

    protected function loadOrder(int $id): void
    {
        $this->order = ProductionOrder::query()
            ->with(['recipe', 'recipeVersion', 'item', 'sucursal', 'almacen', 'creador', 'aprobador'])
            ->findOrFail($id);

        $this->consumos = $this->order->inputs()
            ->with('item')
            ->get()
            ->map(fn ($input) => [
                'item' => $input->item?->nombre ?? $input->item_id,
                'cantidad' => (float) $input->qty,
                'uom' => $input->uom,
                'lote' => $input->inventory_batch_id,
            ])
            ->all();

        $this->salidas = $this->order->outputs()
            ->with('item')
            ->get()
            ->map(fn ($output) => [
                'item' => $output->item?->nombre ?? $output->item_id,
                'cantidad' => (float) $output->qty,
                'uom' => $output->uom,
                'lote' => $output->lote_producido,
                'caducidad' => $output->fecha_caducidad,
            ])
            ->all();

        $this->mermas = $this->order->wastes()
            ->with('item')
            ->get()
            ->map(fn ($waste) => [
                'item' => $waste->item?->nombre ?? $waste->item_id,
                'cantidad' => (float) $waste->qty,
                'uom' => $waste->uom,
                'motivo' => $waste->motivo,
            ])
            ->all();
    }
}

