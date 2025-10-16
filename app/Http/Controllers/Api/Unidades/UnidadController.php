<?php

namespace App\Http\Controllers\Api\Unidades;

use App\Http\Controllers\Controller;
use App\Models\Inv\Unidad;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UnidadController extends Controller
{
    // GET /api/unidades?q=gr&tipo=PESO&categoria=METRICO&base=1
    public function index(Request $r)
    {
        $q = Unidad::query();

        if ($term = $r->string('q')->toString()) {
            $q->where(function ($qq) use ($term) {
                $qq->where('codigo', 'ilike', "%{$term}%")
                   ->orWhere('nombre', 'ilike', "%{$term}%")
                   ->orWhere('tipo', 'ilike', "%{$term}%")
                   ->orWhere('categoria', 'ilike', "%{$term}%");
            });
        }

        if ($r->filled('tipo'))      $q->where('tipo', $r->get('tipo'));
        if ($r->filled('categoria')) $q->where('categoria', $r->get('categoria'));
        if ($r->filled('base'))      $q->where('es_base', filter_var($r->get('base'), FILTER_VALIDATE_BOOL));

        return response()->json(
            $q->orderBy('tipo')->orderBy('nombre')->paginate($r->integer('per_page', 25))
        );
    }

    public function show(int $id)
    {
        return response()->json(Unidad::findOrFail($id));
    }

    public function store(Request $r)
    {
        $data = $r->validate($this->rules());
        $data['decimales'] = $data['decimales'] ?? 2;
        $data['factor_conversion_base'] = $data['factor_conversion_base'] ?? 1.0;

        $u = Unidad::create($data);
        return response()->json($u, 201);
    }

    public function update(Request $r, int $id)
    {
        $u = Unidad::findOrFail($id);
        $data = $r->validate($this->rules($id));
        $u->fill($data)->save();
        return response()->json($u);
    }

    public function destroy(int $id)
    {
        $u = Unidad::findOrFail($id);
        try {
            $u->delete();
            return response()->json(['ok' => true]);
        } catch (\Illuminate\Database\QueryException $e) {
            if ($e->getCode() === '23503') {
                return response()->json(['ok'=>false,'error'=>'No se puede eliminar: unidad en uso.'], 409);
            }
            throw $e;
        }
    }

    private function rules(?int $id = null): array
    {
        $tipos = ['PESO','VOLUMEN','UNIDAD','TIEMPO'];
        $cats  = ['METRICO','IMPERIAL','CULINARIO'];

        return [
            'codigo'  => ['required','string','max:10','regex:/^[A-Z]{2,5}$/', Rule::unique('unidades_medida','codigo')->ignore($id)],
            'nombre'  => ['required','string','max:50'],
            'tipo'    => ['required', Rule::in($tipos)],
            'categoria' => ['nullable', Rule::in($cats)],
            'es_base' => ['nullable','boolean'],
            'factor_conversion_base' => ['nullable','numeric','min:0.000001'],
            'decimales' => ['nullable','integer','min:0','max:6'],
        ];
    }
}
