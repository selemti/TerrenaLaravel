<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    // GET /api/inventory/stock?item_id=...&ubicacion_id=...
    public function stockByItem(Request $r)
    {
        $q = DB::table('inventory_batch')
            ->selectRaw('item_id, SUM(cantidad_actual) AS stock')
            ->groupBy('item_id');

        if ($r->filled('item_id'))      $q->where('item_id', $r->get('item_id'));
        if ($r->filled('ubicacion_id')) $q->where('ubicacion_id', $r->get('ubicacion_id'));

        return response()->json($q->get());
    }

    // GET /api/inventory/items/{id}/kardex
    public function kardex(Request $r, $itemId)
    {
        $q = DB::table('mov_inv')->where('item_id', $itemId)->orderBy('ts');
        if ($r->filled('lote_id')) $q->where('lote_id', $r->get('lote_id'));
        if ($r->filled('from'))   $q->where('ts','>=',$r->date('from'));
        if ($r->filled('to'))     $q->where('ts','<=',$r->date('to'));
        return response()->json($q->get());
    }

    // GET /api/inventory/items/{id}/batches
    public function batches(Request $r, $itemId)
    {
        $q = DB::table('inventory_batch')->where('item_id', $itemId)->orderByDesc('id');
        if ($r->filled('estado')) $q->where('estado', $r->get('estado'));
        return response()->json($q->paginate($r->integer('per_page',25)));
    }
}
