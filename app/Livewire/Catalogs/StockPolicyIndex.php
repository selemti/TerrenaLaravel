<?php

namespace App\Livewire\Catalogs;

use App\Models\Catalogs\StockPolicy;
use App\Models\Catalogs\Sucursal;
use App\Models\Inv\Item;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\On;

class StockPolicyIndex extends Component
{
    use WithPagination;

    protected string $paginationTheme = 'bootstrap';

    public string $search = '';
    public ?int $editId = null;
    public ?string $item_id = null;
    public ?int $sucursal_id = null;
    public float $min_qty = 0;
    public float $max_qty = 0;
    public float $reorder_qty = 0;
    public bool $activo = true;

    protected function rules(): array
    {
        $uniqueRule = Rule::unique('inv_stock_policy', 'item_id')
            ->where(fn ($query) => $query->where('sucursal_id', $this->sucursal_id));

        if ($this->editId) {
            $uniqueRule = $uniqueRule->ignore($this->editId);
        }

        return [
            'item_id'     => [
                'required',
                'string',
                'exists:items,id',
                $uniqueRule,
            ],
            'sucursal_id' => ['required','integer','exists:cat_sucursales,id'],
            'min_qty'     => ['required','numeric','gte:0'],
            'max_qty'     => ['required','numeric','gte:min_qty'],
            'reorder_qty' => ['required','numeric','gte:0'],
            'activo'      => ['boolean'],
        ];
    }

    private function resetForm(): void
    {
        $this->reset(['editId','item_id','sucursal_id','min_qty','max_qty','reorder_qty']);
        $this->min_qty = 0;
        $this->max_qty = 0;
        $this->reorder_qty = 0;
        $this->activo = true;
    }

    public function create()
    {
        $this->resetForm();
        $this->dispatch('toggle-stock-modal', open: true);
    }

    public function edit(int $id)
    {
        $policy = StockPolicy::findOrFail($id);

        $this->editId      = $policy->id;
        $this->item_id     = (string) $policy->item_id;
        $this->sucursal_id = $policy->sucursal_id;
        $this->min_qty     = (float) $policy->min_qty;
        $this->max_qty     = (float) $policy->max_qty;
        $this->reorder_qty = (float) $policy->reorder_qty;
        $this->activo      = (bool) $policy->activo;
        $this->dispatch('toggle-stock-modal', open: true);
    }

    public function save()
    {
        $this->validate();

        $payload = [
            'item_id'     => trim((string) $this->item_id),
            'sucursal_id' => (int) $this->sucursal_id,
            'min_qty'     => $this->min_qty,
            'max_qty'     => $this->max_qty,
            'reorder_qty' => $this->reorder_qty,
            'activo'      => (bool) $this->activo,
        ];

        if ($this->editId) {
            StockPolicy::findOrFail($this->editId)->update($payload);
        } else {
            StockPolicy::create($payload);
        }

        $this->resetForm();
        session()->flash('ok','Política guardada');
        $this->dispatch('toggle-stock-modal', open: false);
    }

    public function delete(int $id)
    {
        StockPolicy::whereKey($id)->delete();
        session()->flash('ok','Política eliminada');
        $this->resetForm();
        $this->dispatch('toggle-stock-modal', open: false);
    }

    public function closeModal(): void
    {
        $this->resetForm();
        $this->dispatch('toggle-stock-modal', open: false);
    }

    public function render()
    {
        $itemLabel = Schema::hasColumn('items', 'name') ? 'name' : 'nombre';

        $rows = StockPolicy::with([
                'item:id,' . $itemLabel,
                'sucursal:id,nombre',
            ])
            ->when($this->search !== '', function ($query) use ($itemLabel) {
                $needle = '%' . $this->search . '%';
                $query->where(function ($sub) use ($needle, $itemLabel) {
                    $sub->whereHas('item', fn ($q) => $q->where($itemLabel, 'ilike', $needle))
                        ->orWhereHas('sucursal', fn ($q) => $q->where('nombre', 'ilike', $needle));
                });
            })
            ->orderBy('sucursal_id')
            ->orderBy('item_id')
            ->paginate(10);

        $rows->getCollection()->transform(function ($row) use ($itemLabel) {
            $row->item_name = optional($row->item)->{$itemLabel} ?? optional($row->item)->nombre ?? optional($row->item)->name ?? '—';
            $row->sucursal_name = optional($row->sucursal)->nombre ?? '—';
            return $row;
        });

        $items = Item::select('id', $itemLabel)
            ->orderBy($itemLabel)
            ->get()
            ->map(function ($item) use ($itemLabel) {
                return (object) [
                    'id'   => (string) $item->id,
                    'name' => $item->{$itemLabel},
                ];
            });

        $sucursales = Sucursal::select('id', 'nombre')
            ->orderBy('nombre')
            ->get()
            ->map(fn ($sucursal) => (object) ['id' => $sucursal->id, 'name' => $sucursal->nombre]);

        return view('livewire.catalogs.stock-policy-index', [
            'rows'       => $rows,
            'items'      => $items,
            'sucursales' => $sucursales,
        ])->layout('layouts.terrena', [
            'active'    => 'config',
            'title'     => 'Catálogo · Políticas de Stock',
            'pageTitle' => 'Políticas de Stock',
        ]);
    }

    #[On('stock-modal-closed')]
    public function handleModalClosed(): void
    {
        $this->resetForm();
    }
}
