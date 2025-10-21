<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Almacen;
use App\Models\Catalogs\Sucursal;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\On;

class AlmacenesIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';
    public ?int $editId = null;
    public string $clave = '';
    public string $nombre = '';
    public ?int $sucursal_id = null;
    public bool $activo = true;

    protected function rules(): array
    {
        return [
            'clave'       => [
                'required',
                'string',
                'max:16',
                Rule::unique('cat_almacenes', 'clave')->ignore($this->editId),
            ],
            'nombre'      => ['required', 'string', 'max:80'],
            'sucursal_id' => ['nullable', 'integer', 'exists:cat_sucursales,id'],
            'activo'      => ['boolean'],
        ];
    }

    private function resetForm(): void
    {
        $this->reset(['editId', 'clave', 'nombre', 'sucursal_id']);
        $this->activo = true;
    }

    public function create()
    {
        $this->resetForm();
        $this->dispatch('toggle-almacen-modal', open: true);
    }

    public function edit(int $id)
    {
        $almacen = Almacen::findOrFail($id);

        $this->editId      = $almacen->id;
        $this->clave       = $almacen->clave;
        $this->nombre      = $almacen->nombre;
        $this->sucursal_id = $almacen->sucursal_id;
        $this->activo      = (bool) $almacen->activo;
        $this->dispatch('toggle-almacen-modal', open: true);
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'clave'       => strtoupper(trim($this->clave)),
            'nombre'      => trim($this->nombre),
            'sucursal_id' => $this->sucursal_id ?: null,
            'activo'      => (bool) $this->activo,
        ];

        if ($this->editId) {
            Almacen::findOrFail($this->editId)->update($payload);
        } else {
            Almacen::create($payload);
        }

        $this->resetForm();
        session()->flash('ok', 'Almacén guardado');
        $this->dispatch('toggle-almacen-modal', open: false);
    }

    public function delete(int $id)
    {
        Almacen::whereKey($id)->delete();
        session()->flash('ok', 'Almacén eliminado');
        $this->resetForm();
        $this->dispatch('toggle-almacen-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-almacen-modal', open: false);
    }

    public function render()
    {
        $rows = Almacen::with('sucursal:id,nombre')
            ->when($this->search !== '', function ($query) {
                $needle = '%' . $this->search . '%';
                $query->where(function ($sub) use ($needle) {
                    $sub->where('clave', 'ilike', $needle)
                        ->orWhere('nombre', 'ilike', $needle)
                        ->orWhereHas('sucursal', fn ($s) => $s->where('nombre', 'ilike', $needle));
                });
            })
            ->orderBy('clave')
            ->paginate(10);

        $sucursales = Sucursal::orderBy('nombre')->get(['id', 'nombre']);

        return view('livewire.catalogs.almacenes-index', compact('rows', 'sucursales'))
            ->layout('layouts.terrena', [
                'active'    => 'config',
                'title'     => 'Catálogo · Almacenes',
                'pageTitle' => 'Almacenes',
            ]);
    }

    #[On('almacen-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }
}
