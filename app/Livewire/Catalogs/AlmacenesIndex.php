<?php

namespace App\Livewire\Catalogs;

use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

class AlmacenesIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public ?int $editId = null;
    public string $clave = '';
    public string $nombre = '';
    public ?int $sucursal_id = null;
    public bool $activo = true;

    protected function rules(): array
    {
        return [
            'clave'       => ['required','max:16', Rule::unique('cat_almacenes','clave')->ignore($this->editId)],
            'nombre'      => ['required','max:80'],
            'sucursal_id' => ['nullable','integer'],
            'activo'      => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId','clave','nombre','sucursal_id','activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        $r = DB::table('cat_almacenes')->where('id',$id)->first();
        if (!$r) return;
        $this->editId     = $r->id;
        $this->clave      = $r->clave;
        $this->nombre     = $r->nombre;
        $this->sucursal_id= $r->sucursal_id;
        $this->activo     = (bool)$r->activo;
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'clave'       => $this->clave,
            'nombre'      => $this->nombre,
            'sucursal_id' => $this->sucursal_id,
            'activo'      => $this->activo,
            'updated_at'  => now(),
        ];

        if ($this->editId) {
            DB::table('cat_almacenes')->where('id',$this->editId)->update($payload);
        } else {
            $payload['created_at'] = now();
            DB::table('cat_almacenes')->insert($payload);
        }

        $this->create();
        session()->flash('ok','Almacén guardado');
    }

    public function delete(int $id)
    {
        DB::table('cat_almacenes')->where('id',$id)->delete();
        session()->flash('ok','Almacén eliminado');
    }

    public function render()
    {
        $rows = DB::table('cat_almacenes as a')
            ->leftJoin('cat_sucursales as s','s.id','=','a.sucursal_id')
            ->select('a.*','s.nombre as sucursal')
            ->when($this->search, fn($q) =>
                $q->where('a.clave','ilike',"%{$this->search}%")
                  ->orWhere('a.nombre','ilike',"%{$this->search}%")
                  ->orWhere('s.nombre','ilike',"%{$this->search}%")
            )
            ->orderBy('a.clave')
            ->paginate(10);

        $sucursales = DB::table('cat_sucursales')->orderBy('nombre')->get();

        return view('livewire.catalogs.almacenes-index', compact('rows','sucursales'));
    }
}
