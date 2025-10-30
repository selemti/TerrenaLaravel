<?php

namespace App\Livewire\Inventory;

use App\Models\InventoryCount;
use App\Models\Item;
use Livewire\Component;
use Livewire\WithPagination;

class InventoryCountsIndex extends Component
{
    use WithPagination;

    public $search = '';
    public $sucursal = '';
    public $estado = '';
    public $fecha_desde = '';
    public $fecha_hasta = '';
    public $perPage = 10;

    protected $queryString = ['search', 'sucursal', 'estado', 'fecha_desde', 'fecha_hasta', 'perPage'];

    public function render()
    {
        $query = InventoryCount::query();

        if ($this->search) {
            $query->where(function($q) {
                $q->where('id', 'like', '%' . $this->search . '%')
                  ->orWhere('sucursal_id', 'like', '%' . $this->search . '%')
                  ->orWhere('estado', 'like', '%' . $this->search . '%');
            });
        }

        if ($this->sucursal) {
            $query->where('sucursal_id', $this->sucursal);
        }

        if ($this->estado) {
            $query->where('estado', $this->estado);
        }

        if ($this->fecha_desde) {
            $query->whereDate('programado_para', '>=', $this->fecha_desde);
        }

        if ($this->fecha_hasta) {
            $query->whereDate('programado_para', '<=', $this->fecha_hasta);
        }

        $counts = $query->orderBy('programado_para', 'desc')
                        ->orderBy('id', 'desc')
                        ->paginate($this->perPage);

        // Obtener valores únicos para filtros
        $sucursales = InventoryCount::distinct('sucursal_id')->pluck('sucursal_id');
        $estados = InventoryCount::distinct('estado')->pluck('estado');

        return view('livewire.inventory.inventory-counts-index', [
            'counts' => $counts,
            'sucursales' => $sucursales,
            'estados' => $estados,
        ]);
    }

    public function closeCount($id)
    {
        $count = InventoryCount::find($id);
        if ($count && in_array($count->estado, ['PROGRAMADO', 'ABIERTO'])) {
            $count->estado = 'CERRADO';
            $count->cerrado_en = now();
            $count->save();
            $this->dispatch('notify', 'Conteo cerrado correctamente');
        }
    }
    
    public function openCount($id)
    {
        $count = InventoryCount::find($id);
        if ($count && $count->estado === 'CERRADO') {
            $count->estado = 'ABIERTO';
            $count->cerrado_en = null;
            $count->save();
            $this->dispatch('notify', 'Conteo reabierto correctamente');
        }
    }
}