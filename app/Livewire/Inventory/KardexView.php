<?php

namespace App\Livewire\Inventory;

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class KardexView extends Component
{
    use WithPagination;

    public int $itemId;

    public string $filterTipo = '';

    public string $filterFechaDesde = '';

    public string $filterFechaHasta = '';

    public ?int $filterLote = null;

    protected $queryString = ['filterTipo', 'filterFechaDesde', 'filterFechaHasta', 'filterLote'];

    public function updatingFilterTipo(): void
    {
        $this->resetPage();
    }

    public function updatingFilterFechaDesde(): void
    {
        $this->resetPage();
    }

    public function updatingFilterFechaHasta(): void
    {
        $this->resetPage();
    }

    public function render()
    {
        $item = DB::connection('pgsql')
            ->table('selemti.items as i')
            ->leftJoin('selemti.cat_unidades as u', 'u.id', '=', 'i.unidad_medida_id')
            ->select('i.id', 'i.nombre', 'i.codigo', 'u.clave as uom_base')
            ->where('i.id', $this->itemId)
            ->first();

        $stockActual = DB::connection('pgsql')
            ->table('selemti.inventory_batch')
            ->where('item_id', $this->itemId)
            ->whereNull('deleted_at')
            ->sum('cantidad_actual');

        $query = DB::connection('pgsql')
            ->table('selemti.mov_inv as m')
            ->leftJoin('selemti.inventory_batch as b', 'b.id', '=', 'm.lote_id')
            ->leftJoin('selemti.cat_unidades as uo', 'uo.id', '=', 'm.uom_original_id')
            ->select([
                'm.id',
                'm.ts as fecha',
                'm.tipo',
                'm.cantidad',
                'm.qty_original',
                'm.costo_unit',
                'm.ref_tipo',
                'm.ref_id',
                'm.lote_id',
                'b.lote_proveedor as lote_codigo',
                'uo.clave as uom_original',
            ])
            ->where('m.item_id', $this->itemId)
            ->when($this->filterTipo, fn ($q) => $q->where('m.tipo', $this->filterTipo))
            ->when($this->filterFechaDesde, fn ($q) => $q->where('m.ts', '>=', $this->filterFechaDesde))
            ->when($this->filterFechaHasta, fn ($q) => $q->where('m.ts', '<=', $this->filterFechaHasta.' 23:59:59'))
            ->when($this->filterLote, fn ($q) => $q->where('m.lote_id', $this->filterLote))
            ->orderBy('m.ts')
            ->orderBy('m.id');

        $movimientos = $query->paginate(50);

        // Calcular saldo acumulado para la página actual
        $saldoAnterior = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('item_id', $this->itemId)
            ->where(function ($q) use ($movimientos) {
                $firstId = $movimientos->items() ? $movimientos->items()[0]->id ?? 0 : 0;
                $q->where('id', '<', $firstId);
                if ($this->filterTipo) {
                    $q->where('tipo', $this->filterTipo);
                }
                if ($this->filterFechaDesde) {
                    $q->where('ts', '>=', $this->filterFechaDesde);
                }
            })
            ->sum('cantidad');

        $tipos = ['COMPRA', 'TRANSFER_IN', 'TRANSFER_OUT', 'PROD_IN', 'PROD_OUT', 'MERMA', 'AJUSTE_POS', 'COUNT_ADJ'];

        return view('livewire.inventory.kardex-view', compact('item', 'stockActual', 'movimientos', 'saldoAnterior', 'tipos'))
            ->layout('layouts.terrena', ['active' => 'inventario']);
    }
}
