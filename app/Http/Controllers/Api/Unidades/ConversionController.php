<?php

namespace App\Http\Controllers\Api\Unidades;

use App\Http\Controllers\Controller;
use App\Models\Inv\ConversionUnidad;
use Illuminate\Http\Request;

class ConversionController extends Controller
{
    // GET /api/unidades/conversiones?origen=1&destino=2&activo=1
    public function index(Request $r)
    {
        $q = ConversionUnidad::with(['origen','destino']);
        if ($r->filled('origen'))  $q->where('unidad_origen_id',  $r->integer('origen'));
        if ($r->filled('destino')) $q->where('unidad_destino_id', $r->integer('destino'));
        if ($r->filled('activo'))  $q->where('activo', filter_var($r->get('activo'), FILTER_VALIDATE_BOOL));

        return response()->json($q->orderBy('id','desc')->paginate($r->integer('per_page',25)));
    }

    // POST /api/unidades/conversiones
    public function store(Request $r)
    {
        $data = $r->validate([
            'unidad_origen_id'  => 'required|integer|different:unidad_destino_id',
            'unidad_destino_id' => 'required|integer',
            'factor_conversion' => 'required|numeric|min:0.000001',
            'precision_estimada'=> 'nullable|numeric|min:0|max:1',
            'activo'            => 'nullable|boolean',
        ]);

        $rec = ConversionUnidad::create($data + ['activo' => $data['activo'] ?? true]);
        return response()->json($rec, 201);
    }

    // PUT /api/unidades/conversiones/{id}
    public function update(Request $r, int $id)
    {
        $rec = ConversionUnidad::findOrFail($id);
        $rec->fill($r->only([
            'factor_conversion','precision_estimada','activo'
        ]))->save();
        return response()->json($rec);
    }

    // DELETE /api/unidades/conversiones/{id}
    public function destroy(int $id)
    {
        ConversionUnidad::whereKey($id)->delete();
        return response()->json(['ok'=>true]);
    }
}
