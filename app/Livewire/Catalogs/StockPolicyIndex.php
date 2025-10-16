<?php

namespace App\Livewire\Catalogs;

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class StockPolicyIndex extends Component
{
    use WithPagination;

    public string $search = '';
    public ?int $editId = null;
    public ?int $item_id = null;
    public ?int $sucursal_id = null;
    public float $min_qty = 0;
    public float $max_qty = 0;
    public float $reorder_qty = 0;
    public bool $activo = true;

    protected function rules(): array
    {
        return [
            'item_id'     => ['required','integer'],
            'sucursal_id' => ['required','integer'],
            'min_qty'     => ['required','numeric','gte:0'],
            'max_qty'     => ['required','numeric','gte:min_qty'],
            'reorder_qty' => ['required','numeric','gte:0'],
            'activo'      => ['boolean'],
        ];
    }

    public function create()
    {
        $this->reset(['editId','item_id','sucursal_id','min_qty','max_qty','reorder_qty','activo']);
        $this->activo = true;
    }

    public function edit(int $id)
    {
        $r = DB::table('inv_stock_policy')->where('id',$id)->first();
        if (!$r) return;
        $this->editId      = $r->id;
        $this->item_id     = $r->item_id;
        $this->sucursal_id = $r->sucursal_id;
        $this->min_qty     = (float)$r->min_qty;
        $this->max_qty     = (float)$r->max_qty;
        $this->reorder_qty = (float)$r->reorder_qty;
        $this->activo      = (bool)$r->activo;
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'item_id'     => $this->item_id,
            'sucursal_id' => $this->sucursal_id,
            'min_qty'     => $this->min_qty,
            'max_qty'     => $this->max_qty,
            'reorder_qty' => $this->reorder_qty,
            'activo'      => $this->activo,
            'updated_at'  => now(),
        ];

        if ($this->editId) {
            DB::table('inv_stock_policy')->where('id',$this->editId)->update($payload);
        } else {
            $payload['created_at'] = now();
            DB::table('inv_stock_policy')->insert($payload);
        }

        $this->create();
        session()->flash('ok','Política guardada');
    }

    public function delete(int $id)
    {
        DB::table('inv_stock_policy')->where('id',$id)->delete();
        session()->flash('ok','Política eliminada');
    }

    public function render()
    {
        // Nota: asumo tablas items y cat_sucursales para joins
        $rows = DB::table('inv_stock_policy as p')
            ->leftJoin('items as it','it.id','=','p.item_id')
            ->leftJoin('cat_sucursales as s','s.id','=','p.sucursal_id')
            ->select('p.*','it.name as item','s.nombre as sucursal')
            ->when($this->search, fn($q) =>
                $q->where('it.name','ilike',"%{$this->search}%")
                  ->orWhere('s.nombre','ilike',"%{$this->search}%")
            )
            ->orderBy('s.nombre')
            ->paginate(10);

        $items      = DB::table('items')->select('id','name')->orderBy('name')->get();
        $sucursales = DB::table('cat_sucursales')->select('id','nombre')->orderBy('nombre')->get();

        return view('livewire.catalogs.stock-policy-index', compact('rows','items','sucursales'));
    }
}
