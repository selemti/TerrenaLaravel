<?php

namespace App\Livewire\Inventory;

use Illuminate\Support\Facades\DB;
use Livewire\Attributes\Layout;
use Livewire\Component;
use Livewire\WithPagination;

class ItemsIndex extends Component
{
    use WithPagination;

    public string $q = '';
    public ?string $sucursal = null;
    public int $perPage = 25;

    // Para que Livewire use bootstrap en la paginación (si no lo tienes, añade en AppServiceProvider Paginator::useBootstrapFive())
    protected $paginationTheme = 'bootstrap';

    #[Layout('layouts.terrena', ['active' => 'inventory'])]
    public function render()
    {
        // IMPORTANTÍSIMO: NO llamar ->get() ni métodos de Collection antes de ->paginate()
        $query = DB::table('selemti.v_stock_resumen as v')
            ->select([
                'v.sku',
                'v.nombre as producto',
                'v.udm_base',
                'v.exist_total as existencia',
                'v.min_stock as min',
                'v.max_stock as max',
                'v.costo_base',
                'v.sucursal',
            ]);

        if ($this->q !== '') {
            $q = mb_strtoupper($this->q);
            $query->where(function ($w) use ($q) {
                $w->whereRaw('UPPER(v.sku) LIKE ?', ["%{$q}%"])
                  ->orWhereRaw('UPPER(v.nombre) LIKE ?', ["%{$q}%"]);
            });
        }

        if (!empty($this->sucursal)) {
            $query->where('v.sucursal', $this->sucursal);
        }

        // Orden y paginación en el Query Builder (no toques Collections aquí)
        $rows = $query->orderBy('v.nombre')->paginate($this->perPage);

        return view('livewire.inventory.items-index', compact('rows'));
    }
}
