<?php

namespace App\Livewire\Inventory;

use App\Services\Inventory\KardexService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class KardexView extends Component
{
    public string $itemId;

    public string $filterFechaDesde = '';

    public string $filterFechaHasta = '';

    public string $filterAlmacen = '';

    public int $page = 1;

    protected $queryString = [
        'filterFechaDesde' => ['except' => ''],
        'filterFechaHasta' => ['except' => ''],
        'filterAlmacen' => ['except' => ''],
        'page' => ['except' => 1],
    ];

    public function mount(string $itemId): void
    {
        $this->itemId = $itemId;
        $this->filterFechaDesde = $this->filterFechaDesde ?: Carbon::now()->subDays(30)->toDateString();
        $this->filterFechaHasta = $this->filterFechaHasta ?: Carbon::now()->toDateString();
    }

    public function updatingFilterFechaDesde(): void
    {
        $this->page = 1;
    }

    public function updatingFilterFechaHasta(): void
    {
        $this->page = 1;
    }

    public function updatingFilterAlmacen(): void
    {
        $this->page = 1;
    }

    public function limpiarFiltros(): void
    {
        $this->filterFechaDesde = Carbon::now()->subDays(30)->toDateString();
        $this->filterFechaHasta = Carbon::now()->toDateString();
        $this->filterAlmacen = '';
        $this->page = 1;
    }

    public function nextPage(int $lastPage): void
    {
        if ($this->page < $lastPage) {
            $this->page++;
        }
    }

    public function prevPage(): void
    {
        if ($this->page > 1) {
            $this->page--;
        }
    }

    public function render(KardexService $service)
    {
        $filters = [
            'from' => $this->filterFechaDesde ?: null,
            'to' => $this->filterFechaHasta ?: null,
            'almacen_id' => $this->filterAlmacen ?: null,
            'per_page' => 50,
            'page' => $this->page,
        ];

        $kardex = $service->getKardex((string) $this->itemId, $filters);
        $movements = collect($kardex['movements'])
            ->sortBy([
                ['ts', 'asc'],
                ['id', 'asc'],
            ])
            ->values();

        $stockActual = (float) DB::connection('pgsql')
            ->table('selemti.inventory_batch')
            ->where('item_id', (string) $this->itemId)
            ->sum('cantidad_actual');

        $almacenes = DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->select('id', 'clave', 'nombre')
            ->when(
                DB::connection('pgsql')->getSchemaBuilder()->hasColumn('selemti.cat_almacenes', 'activo'),
                fn ($query) => $query->where('activo', true)
            )
            ->orderBy('nombre')
            ->get();

        return view('livewire.inventory.kardex-view', compact('kardex', 'movements', 'stockActual', 'almacenes'))
            ->layout('layouts.terrena', ['active' => 'inventario']);
    }
}
