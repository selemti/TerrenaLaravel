<?php

namespace App\Livewire\Catalogs;

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class UomConversionIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public ?int $editId = null;
    public ?int $origen_id = null;
    public ?int $destino_id = null;
    public float $factor = 1.0;

    protected function rules(): array
    {
        return [
            'origen_id'  => ['required','integer'],
            'destino_id' => ['required','integer','different:origen_id'],
            'factor'     => ['required','numeric','gt:0'],
        ];
    }

    public function create()
    {
        $this->reset(['editId','origen_id','destino_id','factor']);
        $this->factor = 1.0;
    }

    public function edit(int $id)
    {
        $r = DB::table('cat_uom_conversion')->where('id',$id)->first();
        if (!$r) return;
        $this->editId    = $r->id;
        $this->origen_id = $r->origen_id;
        $this->destino_id= $r->destino_id;
        $this->factor    = (float)$r->factor;
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'origen_id'  => $this->origen_id,
            'destino_id' => $this->destino_id,
            'factor'     => $this->factor,
            'updated_at' => now(),
        ];

        if ($this->editId) {
            DB::table('cat_uom_conversion')->where('id',$this->editId)->update($payload);
        } else {
            $payload['created_at'] = now();
            DB::table('cat_uom_conversion')->insert($payload);
        }

        $this->create();
        session()->flash('ok','Conversión guardada');
    }

    public function delete(int $id)
    {
        DB::table('cat_uom_conversion')->where('id',$id)->delete();
        session()->flash('ok','Conversión eliminada');
    }

    public function render()
    {
        $rows = DB::table('cat_uom_conversion as c')
            ->join('cat_unidades as u1','u1.id','=','c.origen_id')
            ->join('cat_unidades as u2','u2.id','=','c.destino_id')
            ->select('c.*','u1.clave as origen','u2.clave as destino')
            ->when($this->search, fn($q) =>
                $q->where('u1.clave','ilike',"%{$this->search}%")
                  ->orWhere('u2.clave','ilike',"%{$this->search}%")
            )
            ->orderBy('u1.clave')
            ->orderBy('u2.clave')
            ->paginate(10);

        $uoms = DB::table('cat_unidades')->orderBy('clave')->get();

        return view('livewire.catalogs.uom-conversion-index', compact('rows','uoms'));
    }
}
