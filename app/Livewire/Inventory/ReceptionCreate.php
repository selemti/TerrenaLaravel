<?php
namespace App\Livewire\Inventory;

use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\Attributes\On;
use App\Services\Inventory\ReceptionService;
use Illuminate\Support\Facades\Storage;
use App\Models\Catalogs\Proveedor;
use App\Models\Catalogs\Sucursal;
use App\Models\Catalogs\Almacen;
use App\Models\Inv\Item as InvItem;
use Illuminate\Support\Collection;

class ReceptionCreate extends Component
{
    use WithFileUploads;

    public bool $asModal = false;

    public ?int $supplier_id = null;
    public ?string $branch_id = null;
    public ?string $warehouse_id = null;
    public array $lines = [];
    public array $purchaseUoms = ['PZ', 'CAJA', 'LT'];
    public array $baseUoms = ['GR', 'ML', 'PZ'];

    public function mount(bool $asModal = false): void
    {
        $this->asModal = $asModal;
        $this->resetForm();
    }

    #[On('reception-modal-toggled')]
    public function handleModalToggle(bool $open): void
    {
        $this->resetForm();
    }

    private function resetForm(): void
    {
        $this->supplier_id = null;
        $this->branch_id = null;
        $this->warehouse_id = null;
        $this->lines = [];
        $this->addLine();
    }

    public function addLine(): void
    {
        $this->lines[] = [
            'item_id'      => null,
            'qty_pack'     => 1,
            'uom_purchase' => $this->purchaseUoms[0] ?? 'PZ',
            'pack_size'    => 1,
            'uom_base'     => $this->baseUoms[0] ?? 'PZ',
            'lot'          => '',
            'exp_date'     => '',
            'temp'         => null,
            'evidence'     => null,
            'precio_unit'  => null,
        ];
    }

    public function removeLine(int $idx): void
    {
        unset($this->lines[$idx]);
        $this->lines = array_values($this->lines);

        if (count($this->lines) === 0) {
            $this->addLine();
        }
    }

    public function updatedBranchId($value): void
    {
        $this->branch_id = $value !== '' ? (string) $value : null;
        if ($this->warehouse_id) {
            $this->warehouse_id = null;
        }
    }

    public function updatedWarehouseId($value): void
    {
        $this->warehouse_id = $value !== '' ? (string) $value : null;
    }

    public function updatedSupplierId($value): void
    {
        $this->supplier_id = $value !== '' ? (int) $value : null;
    }

    protected function rules(): array
    {
        return [
            'supplier_id'             => 'required|integer|exists:cat_proveedores,id',
            'branch_id'               => 'nullable|string|exists:cat_sucursales,id',
            'warehouse_id'            => 'nullable|string|exists:cat_almacenes,id',
            'lines'                   => 'required|array|min:1',
            'lines.*.item_id'         => 'required|string|exists:items,id',
            'lines.*.qty_pack'        => 'required|numeric|min:0.0001',
            'lines.*.pack_size'       => 'nullable|numeric|min:0.0001',
            'lines.*.uom_purchase'    => 'required|string',
            'lines.*.uom_base'        => 'required|string|in:GR,ML,PZ',
            'lines.*.exp_date'        => 'nullable|date',
            'lines.*.temp'            => 'nullable|numeric',
            'lines.*.precio_unit'     => 'nullable|numeric|min:0',
        ];
    }

    public function save(ReceptionService $svc)
    {
        $this->validate();

        $lines = [];
        foreach ($this->lines as $line) {
            $normalized = $line;
            $normalized['item_id'] = $this->normalizeItemId($normalized['item_id'] ?? null);
            $normalized['qty_pack'] = isset($normalized['qty_pack']) ? (float) $normalized['qty_pack'] : 0;
            $normalized['pack_size'] = isset($normalized['pack_size']) && $normalized['pack_size'] !== null
                ? (float) $normalized['pack_size']
                : null;
            $normalized['temp'] = isset($normalized['temp']) && $normalized['temp'] !== null
                ? (float) $normalized['temp']
                : null;
            $normalized['precio_unit'] = isset($normalized['precio_unit']) && $normalized['precio_unit'] !== null
                ? (float) $normalized['precio_unit']
                : null;
            $normalized['lot'] = isset($normalized['lot']) ? trim($normalized['lot']) : '';
            $normalized['uom_purchase'] = isset($normalized['uom_purchase']) ? strtoupper($normalized['uom_purchase']) : null;
            $normalized['uom_base'] = isset($normalized['uom_base']) ? strtoupper($normalized['uom_base']) : null;

            if (!empty($normalized['evidence'])) {
                $path = $normalized['evidence']->store('evidencias', 'public');
                $normalized['doc_url'] = Storage::disk('public')->url($path);
            }

            unset($normalized['evidence']);
            $lines[] = $normalized;
        }

        $header = [
            'supplier_id'  => (int) $this->supplier_id,
            'branch_id'    => $this->branch_id ?: null,
            'warehouse_id' => $this->warehouse_id ?: null,
            'user_id'      => auth()->id() ?? 1,
        ];

        $id = $svc->createReception($header, $lines);
        $message = "Recepción #{$id} guardada.";

        if ($this->asModal) {
            $this->dispatch('reception-saved', receptionId: $id, message: $message);
            $this->resetForm();
            return;
        }

        session()->flash('ok', $message);
        return redirect()->route('inv.receptions');
    }

    protected function suppliers(): Collection
    {
        return Proveedor::query()
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre']);
    }

    protected function branches(): Collection
    {
        return Sucursal::query()
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'clave', 'nombre']);
    }

    protected function warehouses(): Collection
    {
        return Almacen::query()
            ->with('sucursal:id,clave')
            ->where('activo', true)
            ->when($this->branch_id, fn ($q) => $q->where('sucursal_id', $this->branch_id))
            ->orderBy('nombre')
            ->get(['id', 'clave', 'nombre', 'sucursal_id'])
            ->each(function ($warehouse) {
                $warehouse->sucursal_clave = optional($warehouse->sucursal)->clave;
            });
    }

    protected function items(): Collection
    {
        return InvItem::query()
            ->where('activo', true)
            ->orderBy('nombre')
            ->limit(200)
            ->get(['id', 'nombre', 'descripcion']);
    }

    private function normalizeItemId($value): int
    {
        if (is_numeric($value)) {
            return (int) $value;
        }

        return (int) preg_replace('/[^0-9]/', '', (string) $value);
    }

    public function render()
    {
        $view = view('inventory.receptions-create', [
            'suppliers'  => $this->suppliers(),
            'branches'   => $this->branches(),
            'warehouses' => $this->warehouses(),
            'items'      => $this->items(),
            'purchaseUoms' => $this->purchaseUoms,
            'baseUoms'     => $this->baseUoms,
            'asModal'      => $this->asModal,
        ]);

        if ($this->asModal) {
            return $view;
        }

        return $view->layout('layouts.terrena', [
            'active'    => 'inventario',
            'title'     => 'Nueva Recepción',
            'pageTitle' => 'Nueva recepción',
        ]);
    }
}
