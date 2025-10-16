<?php

namespace App\Livewire\Recipes;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Inv\Unidad;
use Illuminate\Validation\Rule;

class UnidadesIndex extends Component
{
    use WithPagination;

    public string $q = '';
    public ?int $editId = null;

    // Campos del formulario
    public string $codigo = '';
    public string $nombre = '';
    public string $tipo = 'PESO';
    public ?string $categoria = 'METRICO';
    public bool $es_base = false;
    public string $factor_conversion_base = '1.000000';
    public int $decimales = 2;

    protected $paginationTheme = 'bootstrap';

    protected function rules()
    {
        return [
            'codigo' => [
                'required',
                'regex:/^[A-Z]{2,5}$/',
                Rule::unique('unidades_medida', 'codigo')->ignore($this->editId, 'id'),
            ],
            'nombre' => ['required','string','max:50'],
            'tipo' => ['required', Rule::in(['PESO','VOLUMEN','UNIDAD','TIEMPO'])],
            'categoria' => ['nullable', Rule::in(['METRICO','IMPERIAL','CULINARIO'])],
            'es_base' => ['boolean'],
            'factor_conversion_base' => ['required','regex:/^\d+(\.\d{1,6})?$/'],
            'decimales' => ['required','integer','between:0,6'],
        ];
    }

    public function updatingQ() { $this->resetPage(); }

    public function new()
    {
        $this->reset(['editId','codigo','nombre','tipo','categoria','es_base','factor_conversion_base','decimales']);
        $this->tipo = 'PESO';
        $this->categoria = 'METRICO';
        $this->es_base = false;
        $this->factor_conversion_base = '1.000000';
        $this->decimales = 2;
    }

    public function edit(int $id)
    {
        $u = Unidad::findOrFail($id);
        $this->editId = $u->id;
        $this->codigo = $u->codigo;
        $this->nombre = $u->nombre;
        $this->tipo = $u->tipo;
        $this->categoria = $u->categoria;
        $this->es_base = (bool)$u->es_base;
        $this->factor_conversion_base = (string)$u->factor_conversion_base;
        $this->decimales = (int)$u->decimales;
    }

    public function save()
    {
        $data = $this->validate();

        // si es base, fuerza factor 1.0
        if ($data['es_base']) $data['factor_conversion_base'] = '1.000000';

        Unidad::updateOrCreate(
            ['id' => $this->editId],
            $data
        );

        session()->flash('ok','Guardado');
        $this->new(); // limpia formulario
    }

    public function delete(int $id)
    {
        Unidad::findOrFail($id)->delete();
        session()->flash('ok','Eliminado');
        $this->resetPage();
    }

    public function render()
    {
        $rows = Unidad::query()
            ->when($this->q, fn($q) =>
                $q->where('codigo','ilike',"%{$this->q}%")
                  ->orWhere('nombre','ilike',"%{$this->q}%")
            )
            ->orderBy('nombre')
            ->paginate(10);

        return view('livewire.recipes.unidades-index', [
            'rows' => $rows,
        ])->layout('layouts.terrena', ['active' => 'recetas']);
    }
}
