<?php

namespace App\Livewire\Purchasing\Requests;

use App\Models\PurchaseRequest;
use App\Models\Catalogs\Sucursal;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;

    protected $paginationTheme = 'bootstrap';

    public string $search = '';
    public string $estadoFilter = 'all';
    public string $sucursalFilter = 'all';
    public string $fechaDesde = '';
    public string $fechaHasta = '';

    protected $queryString = [
        'search' => ['except' => ''],
        'estadoFilter' => ['except' => 'all'],
        'sucursalFilter' => ['except' => 'all'],
    ];

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

    public function limpiarFiltros()
    {
        $this->reset(['search', 'estadoFilter', 'sucursalFilter', 'fechaDesde', 'fechaHasta']);
        $this->resetPage();
    }

    public function render()
    {
        $query = PurchaseRequest::with(['createdBy', 'requestedBy', 'sucursal'])
            ->orderBy('created_at', 'desc');

        // Filtro de búsqueda (folio o notas)
        if ($this->search) {
            $query->where(function ($q) {
                $q->where('folio', 'ilike', '%' . $this->search . '%')
                  ->orWhere('notas', 'ilike', '%' . $this->search . '%');
            });
        }

        // Filtro por estado
        if ($this->estadoFilter !== 'all') {
            $query->where('estado', $this->estadoFilter);
        }

        // Filtro por sucursal
        if ($this->sucursalFilter !== 'all') {
            $query->where('sucursal_id', $this->sucursalFilter);
        }

        // Filtro por rango de fechas
        if ($this->fechaDesde && $this->fechaHasta) {
            $query->whereBetween('requested_at', [$this->fechaDesde, $this->fechaHasta]);
        }

        $requests = $query->paginate(15);

        // Estadísticas
        $stats = [
            'total' => PurchaseRequest::count(),
            'borrador' => PurchaseRequest::borrador()->count(),
            'cotizada' => PurchaseRequest::cotizada()->count(),
            'aprobada' => PurchaseRequest::aprobada()->count(),
            'ordenada' => PurchaseRequest::ordenada()->count(),
        ];

        $sucursales = Sucursal::orderBy('nombre')->get();

        return view('livewire.purchasing.requests.index', [
            'requests' => $requests,
            'stats' => $stats,
            'sucursales' => $sucursales,
        ]);
    }
}
