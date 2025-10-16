<?php

namespace App\Livewire\Catalogs;

use Illuminate\Support\Facades\DB;
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

    protected function rules(): array
    {
        return [
            'rfc'      => ['required','max:20', Rule::unique('cat_proveedores','rfc')->ignore($this->editId)],
            'nombre'   => ['required','max:120'],
            'telefono' => ['nullable','max:30'],
            'email'    => ['nullable','email','max:120'],
            'activo'   => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId','rfc','nombre','telefono','email','activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        $r = DB::table('cat_proveedores')->where('id',$id)->first();
        if (!$r) return;
        $this->editId  = $r->id;
        $this->rfc     = $r->rfc;
        $this->nombre  = $r->nombre;
        $this->telefono= $r->telefono ?? '';
        $this->email   = $r->email ?? '';
        $this->activo  = (bool)$r->activo;
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'rfc'        => $this->rfc,
            'nombre'     => $this->nombre,
            'telefono'   => $this->telefono,
            'email'      => $this->email,
            'activo'     => $this->activo,
            'updated_at' => now(),
        ];

        if ($this->editId) {
            DB::table('cat_proveedores')->where('id',$this->editId)->update($payload);
        } else {
            $payload['created_at'] = now();
            DB::table('cat_proveedores')->insert($payload);
        }

        $this->create();
        session()->flash('ok','Proveedor guardado');
    }

    public function delete(int $id)
    {
        DB::table('cat_proveedores')->where('id',$id)->delete();
        session()->flash('ok','Proveedor eliminado');
    }

    public function render()
    {
        $rows = DB::table('cat_proveedores')
            ->when($this->search, fn($q) =>
                $q->where('rfc','ilike',"%{$this->search}%")
                  ->orWhere('nombre','ilike',"%{$this->search}%")
                  ->orWhere('email','ilike',"%{$this->search}%")
            )
            ->orderBy('nombre')
            ->paginate(10);

        return view('livewire.catalogs.proveedores-index', compact('rows'));
    }
}
