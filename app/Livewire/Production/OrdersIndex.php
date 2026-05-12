<?php

namespace App\Livewire\Production;

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class OrdersIndex extends Component
{
    use WithPagination;

    public string $filterEstado = '';

    public string $filterFechaDesde = '';

    public string $filterFechaHasta = '';

    public string $search = '';

    protected $queryString = ['filterEstado', 'filterFechaDesde', 'filterFechaHasta', 'search'];

    public function updatingFilterEstado(): void
    {
        $this->resetPage();
    }

    public function updatingFechaDesde(): void
    {
        $this->resetPage();
    }

    public function updatingFechaHasta(): void
    {
        $this->resetPage();
    }

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function limpiarFiltros(): void
    {
        $this->filterEstado = '';
        $this->filterFechaDesde = '';
        $this->filterFechaHasta = '';
        $this->search = '';
        $this->resetPage();
    }

    public function render()
    {
        $ordenes = DB::connection('pgsql')
            ->table('selemti.production_orders as po')
            ->leftJoin('selemti.receta_cab as r', 'r.id', '=', 'po.recipe_id')
            ->leftJoin('selemti.items as i', 'i.id', '=', 'po.item_id')
            ->select([
                'po.id',
                'po.folio',
                'po.estado',
                'po.qty_programada',
                'po.qty_producida',
                'po.qty_merma',
                'po.uom_base',
                'po.programado_para',
                'po.iniciado_en',
                'po.cerrado_en',
                'po.created_at',
                'r.nombre as receta_nombre',
                'i.nombre as item_nombre',
            ])
            ->when($this->filterEstado, fn ($q) => $q->where('po.estado', $this->filterEstado))
            ->when($this->filterFechaDesde, fn ($q) => $q->where('po.created_at', '>=', $this->filterFechaDesde))
            ->when($this->filterFechaHasta, fn ($q) => $q->where('po.created_at', '<=', $this->filterFechaHasta.' 23:59:59'))
            ->when($this->search, fn ($q) => $q->where(function ($sub) {
                $sub->whereRaw('LOWER(po.folio) LIKE ?', ['%'.strtolower($this->search).'%'])
                    ->orWhereRaw('LOWER(r.nombre) LIKE ?', ['%'.strtolower($this->search).'%'])
                    ->orWhereRaw('LOWER(i.nombre) LIKE ?', ['%'.strtolower($this->search).'%']);
            }))
            ->orderByDesc('po.created_at')
            ->paginate(25);

        $estados = ['BORRADOR', 'EN_PROCESO', 'COMPLETADA', 'POSTEADA'];

        $resumen = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->selectRaw('estado, COUNT(*) as total')
            ->groupBy('estado')
            ->pluck('total', 'estado');

        return view('livewire.production.orders-index', compact('ordenes', 'estados', 'resumen'))
            ->layout('layouts.terrena', ['active' => 'produccion']);
    }
}
