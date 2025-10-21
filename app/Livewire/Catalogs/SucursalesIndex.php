<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Sucursal;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

class SucursalesIndex extends Component
{
    use WithPagination;

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
                Rule::unique('cat_sucursales', 'clave')->ignore($this->editId),
            ],
            'nombre'    => ['required','string','max:120'],
            'ubicacion' => ['nullable','string','max:160'],
            'activo'    => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId', 'clave', 'nombre', 'ubicacion', 'activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        $sucursal = Sucursal::findOrFail($id);

        $this->editId    = $sucursal->id;
        $this->clave     = $sucursal->clave;
        $this->nombre    = $sucursal->nombre;
        $this->ubicacion = $sucursal->ubicacion ?? '';
        $this->activo    = (bool) $sucursal->activo;
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

        $this->create();
        session()->flash('ok', 'Sucursal guardada');
    }

    public function delete(int $id)
    {
        Sucursal::whereKey($id)->delete();
        session()->flash('ok', 'Sucursal eliminada');
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
}
