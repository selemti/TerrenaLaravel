<?php

namespace App\Livewire\Purchasing\Requests;

use App\Models\Inventory\Item;
use App\Models\Catalogs\Sucursal;
use App\Models\Catalogs\Proveedor;
use App\Services\Purchasing\PurchasingService;
use Livewire\Component;
use Livewire\WithPagination;

class Create extends Component
{
    use WithPagination;

    protected $paginationTheme = 'bootstrap';

    // Datos de la solicitud
    public ?string $sucursal_id = null;
    public ?int $requested_by = null;
    public string $requested_at = '';
    public string $notas = '';

    // Líneas de la solicitud
    public array $lineas = [];

    // Búsqueda de items
    public string $searchItem = '';
    public bool $showItemModal = false;

    protected $rules = [
        'sucursal_id' => 'nullable|string',
        'requested_by' => 'nullable|integer',
        'requested_at' => 'required|date',
        'notas' => 'nullable|string',
        'lineas' => 'required|array|min:1',
        'lineas.*.item_id' => 'required|integer',
        'lineas.*.qty' => 'required|numeric|min:0.001',
        'lineas.*.uom' => 'required|string',
        'lineas.*.fecha_requerida' => 'nullable|date',
        'lineas.*.preferred_vendor_id' => 'nullable|integer',
    ];

    public function mount()
    {
        $this->requested_at = now()->format('Y-m-d');
        $this->requested_by = auth()->id();
    }

    public function agregarItem($itemId)
    {
        $item = Item::find($itemId);

        if (!$item) return;

        // Verificar si ya existe
        $existe = collect($this->lineas)->first(fn($l) => $l['item_id'] == $itemId);
        if ($existe) {
            $this->dispatch('notify', [
                'type' => 'warning',
                'message' => 'El item ya está en la lista'
            ]);
            return;
        }

        $this->lineas[] = [
            'item_id' => $item->id,
            'item_codigo' => $item->codigo,
            'item_nombre' => $item->nombre,
            'qty' => 1,
            'uom' => $item->uom_compra ?? 'UND',
            'fecha_requerida' => now()->addDays(7)->format('Y-m-d'),
            'preferred_vendor_id' => null,
            'last_price' => $item->costo_promedio ?? 0,
        ];

        $this->searchItem = '';
        $this->showItemModal = false;
        $this->resetPage('itemsPage');
    }

    public function removerLinea($index)
    {
        unset($this->lineas[$index]);
        $this->lineas = array_values($this->lineas);
    }

    public function crearSolicitud()
    {
        $this->validate();

        try {
            $service = new PurchasingService();

            $payload = [
                'sucursal_id' => $this->sucursal_id,
                'created_by' => auth()->id(),
                'requested_by' => $this->requested_by ?? auth()->id(),
                'requested_at' => $this->requested_at,
                'estado' => 'BORRADOR',
                'notas' => $this->notas,
                'lineas' => collect($this->lineas)->map(function ($linea) {
                    return [
                        'item_id' => $linea['item_id'],
                        'qty' => $linea['qty'],
                        'uom' => $linea['uom'],
                        'fecha_requerida' => $linea['fecha_requerida'] ?? null,
                        'preferred_vendor_id' => $linea['preferred_vendor_id'] ?? null,
                        'last_price' => $linea['last_price'] ?? 0,
                    ];
                })->toArray(),
            ];

            $result = $service->createRequest($payload);

            session()->flash('success', 'Solicitud creada exitosamente: ' . $result['folio']);

            return redirect()->route('purchasing.requests.detail', $result['id']);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error al crear solicitud: ' . $e->getMessage()
            ]);
        }
    }

    public function render()
    {
        $items = [];
        if ($this->searchItem) {
            $items = Item::where('activo', true)
                ->where(function ($q) {
                    $q->where('codigo', 'ilike', '%' . $this->searchItem . '%')
                      ->orWhere('nombre', 'ilike', '%' . $this->searchItem . '%');
                })
                ->orderBy('nombre')
                ->paginate(10, ['*'], 'itemsPage');
        }

        $sucursales = Sucursal::orderBy('nombre')->get();
        $proveedores = Proveedor::orderBy('nombre')->get();

        return view('livewire.purchasing.requests.create', [
            'items' => $items,
            'sucursales' => $sucursales,
            'proveedores' => $proveedores,
        ]);
    }
}
