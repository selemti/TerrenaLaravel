<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Sucursal;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\On;

class SucursalesIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';
    public ?int $editId = null;
    public string $clave = '';
    public string $nombre = '';
    public string $ubicacion = '';
    public bool $activo = true;

    protected function rules(): array
    {
        return [
            'clave'     => [
                'required',
                'string',
                'max:16',
                'regex:/^[A-Z0-9\-]+$/',
                Rule::unique('cat_sucursales', 'clave')->ignore($this->editId),
            ],
            'nombre'    => ['required','string','max:120'],
            'ubicacion' => ['nullable','string','max:160'],
            'activo'    => ['boolean'],
        ];
    }

    protected function messages(): array
    {
        return [
            'clave.required' => 'La clave es obligatoria',
            'clave.regex' => 'La clave solo debe contener letras, números o guiones',
            'clave.unique' => 'Ya existe una sucursal con esta clave',
            'nombre.required' => 'El nombre es obligatorio',
            'nombre.max' => 'El nombre no puede exceder 120 caracteres',
            'ubicacion.max' => 'La ubicación no puede exceder 160 caracteres',
        ];
    }

    public function updated($propertyName): void
    {
        if (in_array($propertyName, ['clave', 'nombre', 'ubicacion', 'activo'], true)) {
            $this->validateOnly($propertyName);
        }
    }

    private function resetForm(): void
    {
        $this->reset(['editId', 'clave', 'nombre', 'ubicacion']);
        $this->activo = true;
    }

    public function create()
    {
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: true);
    }

    public function edit(int $id)
    {
        $sucursal = Sucursal::findOrFail($id);

        $this->editId    = $sucursal->id;
        $this->clave     = $sucursal->clave;
        $this->nombre    = $sucursal->nombre;
        $this->ubicacion = $sucursal->ubicacion ?? '';
        $this->activo    = (bool) $sucursal->activo;
        $this->dispatch('toggle-sucursal-modal', open: true);
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'clave'      => strtoupper(trim($this->clave)),
            'nombre'     => trim($this->nombre),
            'ubicacion'  => $this->ubicacion ? trim($this->ubicacion) : null,
            'activo'     => (bool) $this->activo,
        ];

        if ($this->editId) {
            Sucursal::findOrFail($this->editId)->update($payload);
        } else {
            Sucursal::create($payload);
        }

        $this->resetForm();
        session()->flash('ok', 'Sucursal guardada');
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    public function delete(int $id)
    {
        Sucursal::whereKey($id)->delete();
        session()->flash('ok', 'Sucursal eliminada');
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-sucursal-modal', open: false);
    }

    public function render()
    {
        $rows = Sucursal::query()
            ->when($this->search !== '', function ($query) {
                $needle = '%' . $this->search . '%';
                $query->where(function ($sub) use ($needle) {
                    $sub->where('clave', 'ilike', $needle)
                        ->orWhere('nombre', 'ilike', $needle)
                        ->orWhere('ubicacion', 'ilike', $needle);
                });
            })
            ->orderBy('clave')
            ->paginate(10);

        return view('livewire.catalogs.sucursales-index', compact('rows'))
            ->layout('layouts.terrena', [
                'active'    => 'config',
                'title'     => 'Catálogo · Sucursales',
                'pageTitle' => 'Sucursales',
            ]);
    }

    #[On('sucursal-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }
}
