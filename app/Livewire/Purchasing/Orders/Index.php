<?php

namespace App\Livewire\Purchasing\Orders;

use App\Models\PurchaseOrder;
use App\Models\Catalogs\Proveedor;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;

    protected $paginationTheme = 'bootstrap';

    public string $search = '';
    public string $estadoFilter = 'all';
    public string $vendorFilter = 'all';

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function limpiarFiltros()
    {
        $this->reset(['search', 'estadoFilter', 'vendorFilter']);
        $this->resetPage();
    }

    public function render()
    {
        $query = PurchaseOrder::with(['vendor', 'creadoPor', 'aprobadoPor'])
            ->orderBy('created_at', 'desc');

        if ($this->search) {
            $query->where('folio', 'ilike', '%' . $this->search . '%');
        }

        if ($this->estadoFilter !== 'all') {
            $query->where('estado', $this->estadoFilter);
        }

        if ($this->vendorFilter !== 'all') {
            $query->where('vendor_id', $this->vendorFilter);
        }

        $orders = $query->paginate(15);

        $stats = [
            'total' => PurchaseOrder::count(),
            'borrador' => PurchaseOrder::borrador()->count(),
            'aprobada' => PurchaseOrder::aprobada()->count(),
            'enviada' => PurchaseOrder::enviada()->count(),
            'recibida' => PurchaseOrder::recibida()->count(),
        ];

        $vendors = Proveedor::orderBy('nombre')->get();

        return view('livewire.purchasing.orders.index', [
            'orders' => $orders,
            'stats' => $stats,
            'vendors' => $vendors,
        ]);
    }
}
