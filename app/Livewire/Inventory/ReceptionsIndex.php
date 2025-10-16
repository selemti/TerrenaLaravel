<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Illuminate\Support\Facades\DB;

class ReceptionsIndex extends Component
{
    public function render()
{
        $rows = DB::select("
            SELECT id, proveedor_id, fecha_recepcion AS ts
            FROM selemti.recepcion_cab
            ORDER BY fecha_recepcion DESC
            LIMIT 50
        ");

        return view('inventory.receptions-index', compact('rows'))
            ->layout('layouts.app', ['title' => 'Recepciones']);
    }
}
