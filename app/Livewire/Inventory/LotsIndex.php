<?php

namespace App\Livewire\Inventory;

use Illuminate\Support\Facades\DB;
use Livewire\Component;

class LotsIndex extends Component
{
    protected function schema(): string
    {
        return env('DB_SCHEMA', 'public');
    }

    public function render()
    {
        $lots = DB::connection('pgsql')->table(DB::raw('selemti.inventory_batch as b'))
            ->leftJoin(DB::raw('selemti.items as i'), 'i.id', '=', 'b.item_id')
            ->select([
                'b.id',
                'b.item_id',
                'b.lote_proveedor as lote',
                'b.caducidad as fecha_caducidad',
                'b.estado',
                'b.cantidad_actual as stock',
                DB::raw("COALESCE(i.nombre, '') as item_nombre"),
            ])
            ->orderBy('b.caducidad')
            ->orderByDesc('b.id')
            ->limit(100)
            ->get();

        return view('inventory.lots-index', compact('lots'))
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Lotes · Inventario',
            ]);
    }
}
