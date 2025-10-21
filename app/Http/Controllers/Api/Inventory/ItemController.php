<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Inv\Item;
use Illuminate\Http\Request;

class ItemController extends Controller
{
    // GET /api/inventory/items?q=...
    public function index(Request $r)
    {
        $q = Item::query();

        if ($term = $r->string('q')->toString()) {
            $q->where(function ($qq) use ($term) {
                $qq->where('id','ilike',"%{$term}%")
                   ->orWhere('nombre','ilike',"%{$term}%")
                   ->orWhere('descripcion','ilike',"%{$term}%");
            });
        }

        if ($r->filled('activo'))       $q->where('activo', filter_var($r->get('activo'), FILTER_VALIDATE_BOOL));
        if ($r->filled('categoria_id')) $q->where('categoria_id', $r->get('categoria_id'));

        $items = $q->orderBy('nombre')->paginate($r->integer('per_page',25));

        return response()->json([
            'ok' => true,
            'data' => $items,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // GET /api/inventory/items/{id}
    public function show($id)
    {
        $item = Item::with(['uom','uomCompra','uomSalida'])->findOrFail($id);

        return response()->json([
            'ok' => true,
            'data' => $item,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // POST /api/inventory/items
    public function store(Request $r)
    {
        $data = $r->validate([
            'id' => 'required|string|max:64',     // ajusta si tu PK es serial
            'nombre' => 'required|string|max:120',
            'descripcion' => 'nullable|string',
            'categoria_id' => 'nullable|string|max:64',
            'unidad_medida_id' => 'nullable|integer',
            'unidad_compra_id' => 'nullable|integer',
            'unidad_salida_id' => 'nullable|integer',
            'activo' => 'nullable|boolean',
        ]);

        $rec = Item::create($data + ['activo' => $data['activo'] ?? true]);

        return response()->json([
            'ok' => true,
            'data' => $rec,
            'message' => 'Item creado exitosamente',
            'timestamp' => now()->toIso8601String()
        ], 201);
    }

    // PUT /api/inventory/items/{id}
    public function update(Request $r, $id)
    {
        $rec = Item::findOrFail($id);
        $rec->fill($r->only([
            'nombre','descripcion','categoria_id','unidad_medida_id',
            'unidad_compra_id','unidad_salida_id','activo'
        ]))->save();

        return response()->json([
            'ok' => true,
            'data' => $rec,
            'message' => 'Item actualizado exitosamente',
            'timestamp' => now()->toIso8601String()
        ]);
    }

    // DELETE /api/inventory/items/{id}
    public function destroy($id)
    {
        $item = Item::findOrFail($id);

        // Soft delete - just mark as inactive instead of actually deleting
        $item->activo = false;
        $item->save();

        return response()->json([
            'ok' => true,
            'data' => ['id' => $id],
            'message' => 'Item desactivado exitosamente',
            'timestamp' => now()->toIso8601String()
        ]);
    }
}
