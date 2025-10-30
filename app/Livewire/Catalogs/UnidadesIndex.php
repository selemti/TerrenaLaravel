<?php

namespace App\Livewire\Catalogs;

use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\On;
use App\Models\Catalogs\Unidad;
use Illuminate\Validation\Rule;

class UnidadesIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    // Filtros / querystring
    public string $q = '';
    public int $perPage = 25;

    protected $queryString = [
        'q' => ['except' => ''],
    ];

    // Form modal/simple
    public ?int $editingId = null;
    public array $form = [
        'clave' => '',
        'nombre' => '',
        'activo' => true,
    ];

    public function updatingQ() { $this->resetPage(); }
    public function updatedPerPage() { $this->resetPage(); }

    protected function rules()
    {
        $uniqueClave = Rule::unique('selemti.cat_unidades', 'clave');
        if ($this->editingId) {
            $uniqueClave = $uniqueClave->ignore($this->editingId, 'id');
        }

        return [
            'form.clave' => ['required', 'string', 'max:16', 'regex:/^[A-Z0-9]{1,16}$/', $uniqueClave],
            'form.nombre' => ['required', 'string', 'max:64'],
            'form.activo' => ['boolean'],
        ];
    }

    private function defaults(): array
    {
        return [
            'clave' => '',
            'nombre' => '',
            'activo' => true,
        ];
    }

    private function resetForm(): void
    {
        $this->editingId = null;
        $this->form = $this->defaults();
    }

    public function createNew()
    {
        $this->resetForm();
        $this->dispatch('toggle-unidad-modal', open: true);
    }

    public function edit(int $id)
    {
        $this->editingId = $id;
        $u = Unidad::findOrFail($id);
        $this->form = [
            'clave' => $u->clave,
            'nombre' => $u->nombre,
            'activo' => $u->activo,
        ];
        $this->dispatch('toggle-unidad-modal', open: true);
    }

    public function save()
    {
        $this->form['clave'] = strtoupper(trim($this->form['clave'] ?? ''));
        $this->validate();

        if ($this->editingId) {
            $u = Unidad::findOrFail($this->editingId);
            $u->update($this->form);
        } else {
            Unidad::create($this->form);
        }

        $this->resetForm();
        session()->flash('ok', 'Unidad guardada correctamente');
        $this->resetPage();
        $this->dispatch('toggle-unidad-modal', open: false);
    }

    public function delete(int $id)
    {
        Unidad::whereKey($id)->delete();
        session()->flash('ok', 'Unidad eliminada');
        $this->resetPage();
        $this->dispatch('toggle-unidad-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-unidad-modal', open: false);
    }

    public function render()
    {
        $q = Unidad::query();

        if ($this->q !== '') {
            $needle = mb_strtoupper($this->q);
            $q->where(function ($qq) use ($needle) {
                $qq->whereRaw('UPPER(clave) LIKE ?', ["%{$needle}%"])
                   ->orWhereRaw('UPPER(nombre) LIKE ?', ["%{$needle}%"]);
            });
        }

        $q->orderBy('clave');

        return view('livewire.catalogs.unidades-index', [
            'rows' => $q->paginate($this->perPage),
        ])->layout('layouts.terrena', [
            'active'    => 'config',
            'title'     => 'Catálogo · Unidades de Medida',
            'pageTitle' => 'Unidades de Medida',
        ]);
    }

    #[On('unidad-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }
}
