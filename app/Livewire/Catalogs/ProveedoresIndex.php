<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\Proveedor;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

class ProveedoresIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public ?int $editId = null;
    public string $rfc = '';
    public string $nombre = '';
    public string $telefono = '';
    public string $email = '';
    public bool $activo = true;
    public bool $tableReady = false;
    public string $tableNotice = '';

    public function mount(): void
    {
        $this->tableReady = Schema::hasTable('cat_proveedores');

        if (! $this->tableReady) {
            $this->tableNotice = 'La tabla cat_proveedores no existe en la base de datos. Ejecuta las migraciones para habilitar este catálogo.';
        }
    }

    protected function rules(): array
    {
        $rfcRules = ['required','string','max:20'];

        if ($this->tableReady) {
            $rfcRules[] = Rule::unique('cat_proveedores', 'rfc')->ignore($this->editId);
        }

        return [
            'rfc'      => $rfcRules,
            'nombre'   => ['required','string','max:120'],
            'telefono' => ['nullable','string','max:30'],
            'email'    => ['nullable','email','max:120'],
            'activo'   => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId', 'rfc', 'nombre', 'telefono', 'email', 'activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn', 'Catálogo no disponible. Ejecuta las migraciones correspondientes.');
            return;
        }

        $proveedor = Proveedor::findOrFail($id);

        $this->editId   = $proveedor->id;
        $this->rfc      = $proveedor->rfc;
        $this->nombre   = $proveedor->nombre;
        $this->telefono = $proveedor->telefono ?? '';
        $this->email    = $proveedor->email ?? '';
        $this->activo   = (bool) $proveedor->activo;
    }

    public function save()
    {
        if (! $this->tableReady) {
            session()->flash('warn', 'No es posible guardar porque la tabla cat_proveedores no está disponible.');
            return;
        }

        $this->validate();

        $payload = [
            'rfc'      => strtoupper(trim($this->rfc)),
            'nombre'   => trim($this->nombre),
            'telefono' => $this->telefono ? trim($this->telefono) : null,
            'email'    => $this->email ? trim($this->email) : null,
            'activo'   => (bool) $this->activo,
        ];

        if ($this->editId) {
            Proveedor::findOrFail($this->editId)->update($payload);
        } else {
            Proveedor::create($payload);
        }

        $this->create();
        session()->flash('ok', 'Proveedor guardado');
    }

    public function delete(int $id)
    {
        if (! $this->tableReady) {
            session()->flash('warn', 'No es posible eliminar registros porque la tabla cat_proveedores no está disponible.');
            return;
        }

        Proveedor::whereKey($id)->delete();
        session()->flash('ok', 'Proveedor eliminado');
    }

    public function render()
    {
        if ($this->tableReady) {
            $rows = Proveedor::query()
                ->when($this->search !== '', function ($query) {
                    $needle = '%' . $this->search . '%';
                    $query->where(function ($sub) use ($needle) {
                        $sub->where('rfc', 'ilike', $needle)
                            ->orWhere('nombre', 'ilike', $needle)
                            ->orWhere('email', 'ilike', $needle);
                    });
                })
                ->orderBy('nombre')
                ->paginate(10);
        } else {
            $rows = new LengthAwarePaginator([], 0, 10, $this->getPage(), [
                'path'  => request()->url(),
                'query' => request()->query(),
            ]);
        }

        return view('livewire.catalogs.proveedores-index', [
            'rows'        => $rows,
            'tableReady'  => $this->tableReady,
            'tableNotice' => $this->tableNotice,
        ])
            ->layout('layouts.terrena', [
                'active'    => 'config',
                'title'     => 'Catálogo · Proveedores',
                'pageTitle' => 'Proveedores',
            ]);
    }
}
