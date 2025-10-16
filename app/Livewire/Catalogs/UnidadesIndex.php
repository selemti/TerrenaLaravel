<?php

namespace App\Livewire\Catalogs;

use Livewire\Component;
use Livewire\WithPagination;
use App\Models\Catalogs\Unidad;
use Illuminate\Validation\Rule;

class UnidadesIndex extends Component
{
    use WithPagination;

    // Filtros / querystring
    public string $q = '';
    public string $tipo = '';
    public string $categoria = '';
    public int $perPage = 25;

    protected $queryString = [
        'q' => ['except' => ''],
        'tipo' => ['except' => ''],
        'categoria' => ['except' => ''],
    ];

    // Form modal/simple
    public ?int $editingId = null;
    public array $form = [
        'codigo' => '',
        'nombre' => '',
        'tipo' => 'PESO',
        'categoria' => 'METRICO',
        'es_base' => false,
        'factor_conversion_base' => 1.000000,
        'decimales' => 2,
    ];

    public function updatingQ() { $this->resetPage(); }
    public function updatedTipo() { $this->resetPage(); }
    public function updatedCategoria() { $this->resetPage(); }
    public function updatedPerPage() { $this->resetPage(); }

    protected function rules()
    {
        $uniqueCodigo = Rule::unique('selemti.unidades_medida', 'codigo');
        if ($this->editingId) {
            $uniqueCodigo = $uniqueCodigo->ignore($this->editingId, 'id');
        }

        return [
            'form.codigo' => ['required', 'string', 'max:10', 'regex:/^[A-Z0-9]{1,10}$/', $uniqueCodigo],
            'form.nombre' => ['required', 'string', 'max:50'],
            'form.tipo' => ['required', Rule::in(['PESO','VOLUMEN','UNIDAD','TIEMPO'])],
            'form.categoria' => ['nullable', Rule::in(['METRICO','IMPERIAL','CULINARIO'])],
            'form.es_base' => ['boolean'],
            'form.factor_conversion_base' => ['numeric', 'min:0.000001'],
            'form.decimales' => ['integer', 'between:0,6'],
        ];
    }

    public function createNew()
    {
        $this->reset('editingId');
        $this->form = [
            'codigo' => '',
            'nombre' => '',
            'tipo' => 'PESO',
            'categoria' => 'METRICO',
            'es_base' => false,
            'factor_conversion_base' => 1.000000,
            'decimales' => 2,
        ];
    }

    public function edit(int $id)
    {
        $this->editingId = $id;
        $u = Unidad::findOrFail($id);
        $this->form = [
            'codigo' => $u->codigo,
            'nombre' => $u->nombre,
            'tipo' => $u->tipo ?? 'PESO',
            'categoria' => $u->categoria,
            'es_base' => (bool) $u->es_base,
            'factor_conversion_base' => (float) $u->factor_conversion_base,
            'decimales' => (int) $u->decimales,
        ];
    }

    public function save()
    {
        $this->form['codigo'] = strtoupper(trim($this->form['codigo'] ?? ''));
        $this->validate();

        if ($this->editingId) {
            $u = Unidad::findOrFail($this->editingId);
            $u->update($this->form);
        } else {
            Unidad::create($this->form);
        }

        $this->createNew(); // reset
        session()->flash('ok', 'Unidad guardada correctamente');
        $this->resetPage();
    }

    public function delete(int $id)
    {
        Unidad::whereKey($id)->delete();
        session()->flash('ok', 'Unidad eliminada');
        $this->resetPage();
    }

    public function render()
    {
        $q = Unidad::query();

        if ($this->q !== '') {
            $needle = mb_strtoupper($this->q);
            $q->where(function ($qq) use ($needle) {
                $qq->whereRaw('UPPER(codigo) LIKE ?', ["%{$needle}%"])
                   ->orWhereRaw('UPPER(nombre) LIKE ?', ["%{$needle}%"]);
            });
        }

        if ($this->tipo !== '')   $q->where('tipo', $this->tipo);
        if ($this->categoria !== '') $q->where('categoria', $this->categoria);

        $q->orderBy('tipo')->orderBy('codigo');

        return view('livewire.catalogs.unidades-index', [
            'rows' => $q->paginate($this->perPage),
        ])->layout('layouts.app'); // Breeze layout
    }
}
