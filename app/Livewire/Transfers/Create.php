<?php

namespace App\Livewire\Transfers;

use App\Services\Inventory\TransferService;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

/**
 * Componente para crear transferencias entre almacenes
 *
 * Contrato API esperado:
 * POST /api/transferencias
 * Request: {
 *   almacen_origen_id: int,
 *   almacen_destino_id: int,
 *   fecha_solicitada: date,
 *   observaciones: string|null,
 *   lineas: [{ item_id: string, cantidad: decimal, uom_id: int }]
 * }
 * Response: {
 *   ok: bool,
 *   data: { id: int, numero: string, estado: string },
 *   message: string
 * }
 */
class Create extends Component
{
    public array $form = [
        'almacen_origen_id' => null,
        'almacen_destino_id' => null,
        'fecha_solicitada' => '',
        'observaciones' => '',
    ];

    public array $lineas = [];

    public array $almacenes = [];

    public array $items = [];

    public bool $loading = false;

    public function mount(): void
    {
        $this->form['fecha_solicitada'] = now()->addDay()->format('Y-m-d');
        $this->loadAlmacenes();
        $this->loadItems();
        $this->addLinea();
    }

    public function addLinea(): void
    {
        $this->lineas[] = [
            'item_id' => '',
            'cantidad' => '',
            'uom_id' => null,
        ];
    }

    public function removeLinea(int $index): void
    {
        if (count($this->lineas) > 1) {
            unset($this->lineas[$index]);
            $this->lineas = array_values($this->lineas);
        }
    }

    public function save(TransferService $service)
    {
        $this->validate($this->rules(), $this->messages());

        // Validar que haya al menos una línea válida
        if (empty($this->lineas)) {
            $this->dispatch('toast',
                type: 'warning',
                body: 'Debes agregar al menos un ítem'
            );

            return;
        }

        $this->loading = true;

        try {
            // Formatear líneas para el servicio (solo item_id y cantidad)
            $lines = collect($this->lineas)->map(function ($line) {
                return [
                    'item_id' => $line['item_id'],
                    'cantidad' => (float) $line['cantidad'],
                ];
            })->toArray();

            $result = $service->createTransfer(
                fromAlmacenId: (int) $this->form['almacen_origen_id'],
                toAlmacenId: (int) $this->form['almacen_destino_id'],
                lines: $lines,
                userId: auth()->id() ?? 1
            );

            $transferId = $result['transfer_id'];

            $this->dispatch('toast',
                type: 'success',
                body: "Transferencia #{$transferId} creada en estado SOLICITADA"
            );

            // Redirigir a vista de detalle
            return redirect()->route('transfers.detail', ['id' => $transferId]);
        } catch (\Exception $e) {
            $this->dispatch('toast',
                type: 'error',
                body: 'Error: '.$e->getMessage()
            );
        } finally {
            $this->loading = false;
        }
    }

    public function render()
    {
        return view('livewire.transfers.create')
            ->layout('layouts.terrena', [
                'active' => 'inventario',
                'title' => 'Nueva Transferencia · Inventario',
                'pageTitle' => 'Crear Transferencia',
            ]);
    }

    protected function rules(): array
    {
        return [
            'form.almacen_origen_id' => 'required|integer|different:form.almacen_destino_id',
            'form.almacen_destino_id' => 'required|integer',
            'form.fecha_solicitada' => 'required|date|after_or_equal:today',
            'form.observaciones' => 'nullable|string|max:500',
            'lineas.*.item_id' => 'required|string',
            'lineas.*.cantidad' => 'required|numeric|min:0.01',
            'lineas.*.uom_id' => 'required|integer',
        ];
    }

    protected function messages(): array
    {
        return [
            'form.almacen_origen_id.required' => 'Selecciona el almacén de origen',
            'form.almacen_origen_id.different' => 'El almacén de origen debe ser diferente al destino',
            'form.almacen_destino_id.required' => 'Selecciona el almacén de destino',
            'form.fecha_solicitada.required' => 'La fecha es obligatoria',
            'form.fecha_solicitada.after_or_equal' => 'La fecha no puede ser anterior a hoy',
            'lineas.*.item_id.required' => 'Selecciona un ítem',
            'lineas.*.cantidad.required' => 'La cantidad es obligatoria',
            'lineas.*.cantidad.min' => 'La cantidad debe ser mayor a cero',
            'lineas.*.uom_id.required' => 'Selecciona una unidad de medida',
        ];
    }

    protected function loadAlmacenes(): void
    {
        try {
            $this->almacenes = DB::connection('pgsql')
                ->table('selemti.cat_almacenes')
                ->where('activo', true)
                ->orderBy('nombre')
                ->get(['id', 'nombre', 'clave'])
                ->map(fn ($row) => [
                    'id' => (int) $row->id,
                    'nombre' => trim(($row->clave ? "{$row->clave} - " : '').$row->nombre),
                ])
                ->toArray();
        } catch (\Exception $e) {
            $this->almacenes = [];
        }
    }

    protected function loadItems(): void
    {
        try {
            $this->items = DB::connection('pgsql')
                ->table('selemti.items as i')
                ->leftJoin('selemti.unidades_medida as u', 'u.id', '=', 'i.unidad_medida_id')
                ->where('i.activo', true)
                ->orderBy('i.nombre')
                ->limit(200)
                ->get(['i.id', 'i.nombre', 'u.codigo as uom_codigo', 'u.id as uom_id'])
                ->map(fn ($row) => [
                    'id' => $row->id,
                    'nombre' => $row->nombre,
                    'uom_codigo' => $row->uom_codigo,
                    'uom_id' => (int) $row->uom_id,
                ])
                ->toArray();
        } catch (\Exception $e) {
            $this->items = [];
        }
    }
}
