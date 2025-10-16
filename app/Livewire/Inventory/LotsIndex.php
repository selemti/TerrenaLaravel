<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Illuminate\Support\Facades\DB;

class LotsIndex extends Component
{
    public function render()
    {
        $lots = DB::select("
          SELECT b.id, b.item_id, b.lote, b.caducidad, b.estado,
                 (SELECT COALESCE(SUM(CASE WHEN tipo IN ('RECEPCION','ENTRADA','TRASPASO_ENTRADA') THEN qty
                                           WHEN tipo IN ('SALIDA','VENTA','MERMA','TRASPASO_SALIDA') THEN -qty
                                           ELSE 0 END),0)
                  FROM mov_inv m WHERE m.batch_id=b.id) as stock
          FROM inventory_batch b
          ORDER BY b.caducidad NULLS LAST, b.id DESC
          LIMIT 100
        ");
        return view('inventory.lots-index', compact('lots'))
          ->layout('layouts.app', ['title'=>'Lotes']);
    }
}
