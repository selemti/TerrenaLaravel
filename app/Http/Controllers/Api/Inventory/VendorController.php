<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Inv\ItemVendor;
use Illuminate\Http\Request;

class VendorController extends Controller
{
    // GET /api/inventory/items/{id}/vendors
    public function byItem($itemId)
    {
        return response()->json(
            ItemVendor::where('item_id',$itemId)->orderBy('presentacion')->get()
        );
    }

    // POST /api/inventory/items/{id}/vendors
    public function attach(Request $r, $itemId)
    {
        $data = $r->validate([
            'vendor_id' => 'required|string|max:64',
            'presentacion' => 'required|string|max:120',
            'unidad_presentacion_id' => 'required|integer',
            'factor_a_canonica' => 'required|numeric|min:0.000001',
            'costo_ultimo' => 'nullable|numeric|min:0',
            'moneda' => 'nullable|string|max:3',
            'lead_time_dias' => 'nullable|integer|min:0',
            'codigo_proveedor' => 'nullable|string|max:64',
            'activo' => 'nullable|boolean',
        ]);

        $rec = ItemVendor::updateOrCreate(
            ['item_id'=>$itemId, 'vendor_id'=>$data['vendor_id'], 'presentacion'=>$data['presentacion']],
            $data + ['activo' => $data['activo'] ?? true]
        );
        return response()->json($rec, 201);
    }
}
