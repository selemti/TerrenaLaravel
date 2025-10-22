<?php

namespace App\Livewire\Inventory;

use App\Actions\Inventory\StoreVendorPrice;
use App\Support\Inventory\VendorPriceValidation;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Livewire\Component;

class ItemPriceCreate extends Component
{
    use AuthorizesRequests;

    public bool $open = false;
    public ?string $itemId = null;
    public ?string $vendorId = null;
    public ?string $price = null;
    public ?string $packQty = null;
    public ?string $packUom = null;
    public ?string $effectiveFrom = null;
    public ?string $notes = null;
    public ?string $source = null;

    public string $itemSearch = '';
    public string $vendorSearch = '';

    public array $itemOptions = [];
    public array $vendorOptions = [];

    protected $listeners = [
        'openPriceCreate' => 'open',
        'setPriceItem' => 'setItem',
    ];

    public function mount(): void
    {
        abort_unless(Auth::check(), 403);
        $this->authorize('inventory.prices.manage');
        $this->resetForm();
        $this->hydrateItemOptions();
    }

    public function open(?string $itemId = null): void
    {
        $this->authorize('inventory.prices.manage');
        $this->resetErrorBag();
        $this->resetValidation();
        $this->open = true;

        if ($itemId) {
            $this->setItem($itemId);
        } else {
            $this->hydrateItemOptions();
            $this->hydrateVendorOptions();
        }
    }

    public function close(): void
    {
        $this->open = false;
    }

    public function setItem(?string $itemId): void
    {
        if ($itemId === null) {
            $this->itemId = null;
            return;
        }

        $this->itemId = (string) $itemId;
        $this->hydrateItemOptions();
        $this->hydrateVendorOptions();
    }

    public function updatedItemSearch(): void
    {
        $this->hydrateItemOptions();
    }

    public function updatedVendorSearch(): void
    {
        $this->hydrateVendorOptions();
    }

    public function updatedItemId($value): void
    {
        $this->itemId = $value !== null ? (string) $value : null;
        $this->hydrateVendorOptions();
    }

    public function save(StoreVendorPrice $action)
    {
        $this->authorize('inventory.prices.manage');

        $input = VendorPriceValidation::sanitize([
            'item_id' => $this->itemId,
            'vendor_id' => $this->vendorId,
            'price' => $this->price,
            'pack_qty' => $this->packQty,
            'pack_uom' => $this->packUom,
            'effective_from' => $this->effectiveFrom,
            'notes' => $this->notes,
            'source' => $this->source,
        ]);

        $validator = Validator::make($input, VendorPriceValidation::rules(), [], [
            'item_id' => 'ítem',
            'vendor_id' => 'proveedor',
            'price' => 'precio',
            'pack_qty' => 'cantidad del pack',
            'pack_uom' => 'unidad del pack',
            'effective_from' => 'vigente desde',
        ]);

        $validator->after(function ($validator) use ($input) {
            VendorPriceValidation::afterValidation($validator, $input);
        });

        $validated = $validator->validate();

        $this->itemId = $validated['item_id'];
        $this->vendorId = $validated['vendor_id'];
        $this->packUom = $validated['pack_uom'];
        $this->packQty = (string) $validated['pack_qty'];
        $this->price = (string) $validated['price'];

        $latest = $action->execute($validated);

        $this->dispatch('toast', type: 'success', body: 'Precio registrado correctamente.');
        $this->dispatch('refreshItems')->to(ItemsManage::class);

        $this->resetForm();
        $this->open = false;

        return $latest;
    }

    public function render()
    {
        return view('livewire.inventory.item-price-create', [
            'itemOptions' => $this->itemOptions,
            'vendorOptions' => $this->vendorOptions,
        ]);
    }

    private function resetForm(): void
    {
        $this->itemId = null;
        $this->vendorId = null;
        $this->price = null;
        $this->packQty = null;
        $this->packUom = null;
        $this->notes = null;
        $this->source = null;
        $this->effectiveFrom = Carbon::now()->format('Y-m-d\TH:i');
        $this->itemSearch = '';
        $this->vendorSearch = '';
    }

    private function hydrateItemOptions(): void
    {
        $term = trim($this->itemSearch);

        $query = DB::connection('pgsql')
            ->table('selemti.items as i')
            ->leftJoin('selemti.item_vendor as pv', function ($join) {
                $join->on('pv.item_id', '=', 'i.id')
                    ->where('pv.preferente', true);
            })
            ->select([
                'i.id',
                'i.item_code',
                'i.nombre',
                DB::raw('pv.vendor_id::text as preferred_vendor'),
            ])
            ->limit(20)
            ->orderBy('i.nombre');

        if ($term !== '') {
            $needle = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $term) . '%';
            $query->where(function ($sub) use ($needle) {
                $sub->where('i.id', 'ilike', $needle)
                    ->orWhere('i.item_code', 'ilike', $needle)
                    ->orWhere('i.nombre', 'ilike', $needle);
            });
        }

        $this->itemOptions = $query->get()->map(function ($row) {
            return [
                'id' => (string) $row->id,
                'item_code' => $row->item_code,
                'name' => $row->nombre,
                'preferred_vendor' => $row->preferred_vendor,
            ];
        })->all();
    }

    private function hydrateVendorOptions(): void
    {
        if ($this->itemId === null || $this->itemId === '') {
            $this->vendorOptions = [];
            return;
        }

        $term = trim($this->vendorSearch);

        $query = DB::connection('pgsql')
            ->table('selemti.item_vendor as iv')
            ->whereRaw('iv.item_id::text = ?', [$this->itemId])
            ->leftJoin(DB::raw('selemti.cat_proveedores as cp'), function ($join) {
                $join->on(DB::raw('cp.id::text'), '=', DB::raw('iv.vendor_id::text'));
            })
            ->select([
                DB::raw('iv.vendor_id::text as id'),
                DB::raw("coalesce(cp.nombre, concat('Proveedor ', iv.vendor_id::text)) as name"),
                'iv.preferente',
                'iv.presentacion',
            ])
            ->orderBy('name')
            ->limit(20);

        if ($term !== '') {
            $needle = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $term) . '%';
            $query->where(function ($sub) use ($needle) {
                $sub->whereRaw('iv.vendor_id::text ilike ?', [$needle])
                    ->orWhereRaw('cp.nombre ilike ?', [$needle]);
            });
        }

        $this->vendorOptions = $query->get()->map(function ($row) {
            return [
                'id' => $row->id,
                'name' => $row->name,
                'preferente' => (bool) $row->preferente,
                'presentacion' => $row->presentacion,
            ];
        })->all();
    }
}
