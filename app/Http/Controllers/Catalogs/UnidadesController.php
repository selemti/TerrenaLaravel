<?php

namespace App\Http\Controllers\Catalogs;

use App\Http\Controllers\Controller;
use App\Http\Requests\Catalogs\StoreUnidadRequest;
use App\Http\Requests\Catalogs\UpdateUnidadRequest;
use App\Models\Catalogs\Unidad;
use Illuminate\Http\Request;

class UnidadesController extends Controller
{
    public function index(Request $request)
    {
        $q = trim($request->query('q', ''));
        $query = Unidad::query();
        if ($q !== '') {
            $query->where(function($w) use ($q){
                $w->where('codigo','ILIKE',"%{$q}%")
                  ->orWhere('nombre','ILIKE',"%{$q}%");
            });
        }
        $rows = $query->orderBy('codigo')->paginate(15)->withQueryString();
        return view('catalogs.unidades.index', compact('rows','q'));
    }

    public function create()
    {
        $unidad = new Unidad();
        return view('catalogs.unidades.create', compact('unidad'));
    }

    public function store(StoreUnidadRequest $request)
    {
        $data = $request->validated();
        $data['es_base'] = (bool)($data['es_base'] ?? false);
        Unidad::create($data);
        return redirect()->route('catalogos.unidades.index')->with('ok','Unidad creada');
    }

    public function show(Unidad $unidad)
    {
        return view('catalogs.unidades.show', compact('unidad'));
    }

    public function edit(Unidad $unidad)
    {
        return view('catalogs.unidades.edit', compact('unidad'));
    }

    public function update(UpdateUnidadRequest $request, Unidad $unidad)
    {
        $data = $request->validated();
        $data['es_base'] = (bool)($data['es_base'] ?? false);
        $unidad->update($data);
        return redirect()->route('catalogos.unidades.index')->with('ok','Unidad actualizada');
    }

    public function destroy(Unidad $unidad)
    {
        $unidad->delete();
        return redirect()->route('catalogos.unidades.index')->with('ok','Unidad eliminada');
    }
}
