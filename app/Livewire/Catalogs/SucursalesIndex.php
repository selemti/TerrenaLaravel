<?php

namespace App\Livewire\Catalogs;

use Illuminate\Support\Facades\DB;
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
            'clave'     => ['required','max:16', Rule::unique('cat_sucursales','clave')->ignore($this->editId)],
            'nombre'    => ['required','max:120'],
            'ubicacion' => ['nullable','max:160'],
            'activo'    => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId','clave','nombre','ubicacion','activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        $r = DB::table('cat_sucursales')->where('id',$id)->first();
        if (!$r) return;
        $this->editId   = $r->id;
        $this->clave    = $r->clave;
        $this->nombre   = $r->nombre;
        $this->ubicacion= $r->ubicacion ?? '';
        $this->activo   = (bool)$r->activo;
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'clave'      => $this->clave,
            'nombre'     => $this->nombre,
            'ubicacion'  => $this->ubicacion,
            'activo'     => $this->activo,
            'updated_at' => now(),
        ];

        if ($this->editId) {
            DB::table('cat_sucursales')->where('id',$this->editId)->update($payload);
        } else {
            $payload['created_at'] = now();
            DB::table('cat_sucursales')->insert($payload);
        }

        $this->create();
        session()->flash('ok','Sucursal guardada');
    }

    public function delete(int $id)
    {
        DB::table('cat_sucursales')->where('id',$id)->delete();
        session()->flash('ok','Sucursal eliminada');
    }

    public function render()
    {
        $rows = DB::table('cat_sucursales')
            ->when($this->search, fn($q) =>
                $q->where('clave','ilike',"%{$this->search}%")
                  ->orWhere('nombre','ilike',"%{$this->search}%")
                  ->orWhere('ubicacion','ilike',"%{$this->search}%")
            )
            ->orderBy('clave')
            ->paginate(10);

        return view('livewire.catalogs.sucursales-index', compact('rows'));
    }
}
