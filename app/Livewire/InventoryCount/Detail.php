<?php

namespace App\Livewire\InventoryCount;

use App\Models\InventoryCount;
use Livewire\Component;

class Detail extends Component
{
    public $countId;
    public $count;

    public string $filterVariacion = 'all';

    public function mount($id)
    {
        $this->countId = $id;
        $this->loadCount();
    }

    protected function loadCount()
    {
        $this->count = InventoryCount::with(['lines.item', 'createdBy', 'closedBy'])
            ->findOrFail($this->countId);
    }

    public function render()
    {
        $query = $this->count->lines()->with('item');

        // Filtrar según tipo de variación
        switch ($this->filterVariacion) {
            case 'exactos':
                $query->whereRaw('ABS(qty_variacion) < 0.000001');
                break;
            case 'variacion':
                $query->whereRaw('ABS(qty_variacion) >= 0.000001');
                break;
            case 'faltantes':
                $query->where('qty_variacion', '<', 0);
                break;
            case 'sobrantes':
                $query->where('qty_variacion', '>', 0);
                break;
        }

        $lines = $query->get();

        // Estadísticas
        $totalLineas = $this->count->lines()->count();
        $exactos = $this->count->lines()->whereRaw('ABS(qty_variacion) < 0.000001')->count();
        $conVariacion = $this->count->lines()->whereRaw('ABS(qty_variacion) >= 0.000001')->count();
        $faltantes = $this->count->lines()->where('qty_variacion', '<', 0)->count();
        $sobrantes = $this->count->lines()->where('qty_variacion', '>', 0)->count();

        $valorVariacion = $this->count->lines()
            ->whereRaw('ABS(qty_variacion) >= 0.000001')
            ->get()
            ->sum(function($line) {
                // Calcular valor aproximado: variación * costo promedio
                return $line->qty_variacion * ($line->item->costo_promedio ?? 0);
            });

        return view('livewire.inventory-count.detail', [
            'lines' => $lines,
            'totalLineas' => $totalLineas,
            'exactos' => $exactos,
            'conVariacion' => $conVariacion,
            'faltantes' => $faltantes,
            'sobrantes' => $sobrantes,
            'valorVariacion' => $valorVariacion,
        ]);
    }

    public function exportarPDF()
    {
        $this->dispatch('toast',
            type: 'info',
            body: 'Exportación a PDF en desarrollo'
        );
    }

    public function exportarExcel()
    {
        $this->dispatch('toast',
            type: 'info',
            body: 'Exportación a Excel en desarrollo'
        );
    }

    public function volver()
    {
        return redirect()->route('inv.counts.index');
    }
}
