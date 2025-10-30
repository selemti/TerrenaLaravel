<?php

namespace App\Livewire\InventoryCount;

use App\Models\InventoryCount;
use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\Auth;

class Index extends Component
{
    use WithPagination;

    // Filtros
    public string $search = '';
    public string $estadoFilter = 'all';
    public string $sucursalFilter = 'all';
    public string $almacenFilter = 'all';

    protected $queryString = [
        'search' => ['except' => ''],
        'estadoFilter' => ['except' => 'all'],
        'sucursalFilter' => ['except' => 'all'],
        'almacenFilter' => ['except' => 'all'],
    ];

    public function render()
    {
        $query = InventoryCount::with(['createdBy', 'closedBy'])
            ->orderBy('created_at', 'desc');

        // Filtro de búsqueda
        if ($this->search) {
            $query->where(function($q) {
                $q->where('folio', 'ILIKE', '%' . $this->search . '%')
                  ->orWhere('notas', 'ILIKE', '%' . $this->search . '%');
            });
        }

        // Filtro de estado
        if ($this->estadoFilter !== 'all') {
            $query->where('estado', $this->estadoFilter);
        }

        // Filtro de sucursal
        if ($this->sucursalFilter !== 'all') {
            $query->where('sucursal_id', $this->sucursalFilter);
        }

        // Filtro de almacén
        if ($this->almacenFilter !== 'all') {
            $query->where('almacen_id', $this->almacenFilter);
        }

        $conteos = $query->paginate(15);

        // Obtener sucursales y almacenes únicos para filtros
        $sucursales = InventoryCount::select('sucursal_id')
            ->distinct()
            ->whereNotNull('sucursal_id')
            ->pluck('sucursal_id')
            ->toArray();

        $almacenes = InventoryCount::select('almacen_id')
            ->distinct()
            ->whereNotNull('almacen_id')
            ->pluck('almacen_id')
            ->toArray();

        return view('livewire.inventory-count.index', [
            'conteos' => $conteos,
            'sucursales' => $sucursales,
            'almacenes' => $almacenes,
        ]);
    }

    public function limpiarFiltros()
    {
        $this->reset(['search', 'estadoFilter', 'sucursalFilter', 'almacenFilter']);
        $this->resetPage();
    }

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingEstadoFilter()
    {
        $this->resetPage();
    }

    public function updatingSucursalFilter()
    {
        $this->resetPage();
    }

    public function updatingAlmacenFilter()
    {
        $this->resetPage();
    }
}
