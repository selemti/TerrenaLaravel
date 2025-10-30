<?php

namespace App\Livewire\InventoryCount;

use App\Models\Item;
use App\Services\Inventory\InventoryCountService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class Create extends Component
{
    public array $form = [
        'sucursal_id' => '',
        'almacen_id' => '',
        'programado_para' => '',
        'notas' => '',
    ];

    // Items seleccionados para el conteo
    public array $selectedItems = [];
    public string $itemSearch = '';

    public function mount()
    {
        // Inicializar con fecha actual
        $this->form['programado_para'] = now()->format('Y-m-d\TH:i');
    }

    public function render()
    {
        // Obtener items disponibles para el conteo
        $itemsQuery = Item::query()
            ->where('activo', true)
            ->orderBy('nombre');

        if ($this->itemSearch) {
            $itemsQuery->where(function($q) {
                $q->where('codigo', 'ILIKE', '%' . $this->itemSearch . '%')
                  ->orWhere('nombre', 'ILIKE', '%' . $this->itemSearch . '%');
            });
        }

        $items = $itemsQuery->limit(50)->get();

        // Obtener sucursales y almacenes
        $sucursales = DB::connection('pgsql')
            ->table('selemti.cat_sucursales')
            ->select('id', 'nombre')
            ->where('activo', true)
            ->orderBy('nombre')
            ->get();

        $almacenes = DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->select('id', 'nombre')
            ->where('activo', true)
            ->orderBy('nombre')
            ->get();

        return view('livewire.inventory-count.create', [
            'items' => $items,
            'sucursales' => $sucursales,
            'almacenes' => $almacenes,
        ]);
    }

    public function toggleItem($itemId)
    {
        if (isset($this->selectedItems[$itemId])) {
            unset($this->selectedItems[$itemId]);
        } else {
            $item = Item::find($itemId);
            if ($item) {
                // Obtener stock actual como qty_teorica
                $stockActual = DB::connection('pgsql')
                    ->table('mov_inv')
                    ->where('item_id', $itemId)
                    ->when($this->form['almacen_id'], function($q, $almacen) {
                        $q->where('almacen_id', $almacen);
                    })
                    ->sum('qty');

                $this->selectedItems[$itemId] = [
                    'item_id' => $itemId,
                    'nombre' => $item->nombre,
                    'codigo' => $item->codigo,
                    'uom' => $item->uom_base,
                    'qty_teorica' => $stockActual,
                ];
            }
        }
    }

    public function seleccionarTodos()
    {
        $items = Item::where('activo', true)->limit(100)->get();

        foreach ($items as $item) {
            if (!isset($this->selectedItems[$item->id])) {
                $this->toggleItem($item->id);
            }
        }

        $this->dispatch('toast',
            type: 'success',
            body: count($items) . ' items agregados al conteo'
        );
    }

    public function limpiarSeleccion()
    {
        $this->selectedItems = [];

        $this->dispatch('toast',
            type: 'info',
            body: 'Selección limpiada'
        );
    }

    public function crearConteo()
    {
        // Validación
        $this->validate([
            'form.sucursal_id' => 'nullable|string',
            'form.almacen_id' => 'nullable|string',
            'form.programado_para' => 'nullable|date',
        ], [
            'form.programado_para.date' => 'La fecha programada no es válida',
        ]);

        if (empty($this->selectedItems)) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Debe seleccionar al menos un item para contar'
            );
            return;
        }

        try {
            $service = new InventoryCountService();

            $header = [
                'branch_id' => $this->form['sucursal_id'] ?: null,
                'warehouse_id' => $this->form['almacen_id'] ?: null,
                'scheduled_for' => $this->form['programado_para'] ?: now(),
                'user_id' => Auth::id(),
            ];

            $lines = array_values($this->selectedItems);

            $countId = $service->open($header, $lines);

            $this->dispatch('toast',
                type: 'success',
                body: 'Conteo creado exitosamente'
            );

            return redirect()->route('inv.counts.capture', ['id' => $countId]);

        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error al crear conteo: ' . $e->getMessage()
            );
        }
    }
}
