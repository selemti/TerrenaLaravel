<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Illuminate\Support\Facades\DB;

class LotsIndex extends Component
{
    protected function schema(): string
    {
        return env('DB_SCHEMA', 'public');
    }

    public function render()
    {
        $lots = DB::table(DB::raw('inventory_batch as b'))
            ->leftJoin(DB::raw('items as i'), 'i.id', '=', 'b.item_id')
            ->select([
                'b.id',
                'b.item_id',
                'b.lote_proveedor as lote',
                'b.fecha_caducidad',
                'b.estado',
                'b.cantidad_actual as stock',
                DB::raw("COALESCE(i.nombre, '') as item_nombre"),
            ])
            ->orderBy('b.fecha_caducidad')
            ->orderByDesc('b.id')
            ->limit(100)
            ->get();

        return view('inventory.lots-index', compact('lots'))
            ->layout('layouts.terrena', ['active' => 'inventario']);
    }
}
