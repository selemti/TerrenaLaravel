<?php

namespace App\Livewire\Replenishment;

use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\DB;
use App\Models\ReplenishmentSuggestion;
use App\Models\Sucursal;
use App\Services\Replenishment\ReplenishmentService;

class Dashboard extends Component
{
    use WithPagination;

    // Filtros
    public $tipoFilter = 'all';
    public $prioridadFilter = 'all';
    public $estadoFilter = 'PENDIENTE'; // Por defecto mostrar solo pendientes
    public $sucursalFilter = 'all';
    public $search = '';
    public $urgenciasOnly = false;

    // Selección múltiple
    public $selectedIds = [];
    public $selectAll = false;

    // Agrupación
    public $agruparPorProveedor = false;

    // Estado de generación
    public $generando = false;

    protected $queryString = [
        'tipoFilter' => ['except' => 'all'],
        'prioridadFilter' => ['except' => 'all'],
        'estadoFilter' => ['except' => 'PENDIENTE'],
        'sucursalFilter' => ['except' => 'all'],
        'urgenciasOnly' => ['except' => false],
    ];

    public function mount()
    {
        // Inicialización si es necesario
    }

    /**
     * Genera nuevas sugerencias manualmente
     */
    public function generarSugerencias()
    {
        $this->generando = true;

        try {
            $service = new ReplenishmentService();
            $resultado = $service->generateDailySuggestions([
                'sucursal_id' => $this->sucursalFilter !== 'all' ? $this->sucursalFilter : null,
            ]);

            $this->dispatch('notify', [
                'type' => 'success',
                'message' => "Se generaron {$resultado['total']} sugerencias ({$resultado['urgentes']} urgentes)"
            ]);

            $this->resetPage();

        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error al generar sugerencias: ' . $e->getMessage()
            ]);
        } finally {
            $this->generando = false;
        }
    }

    /**
     * Aprobar sugerencia individual
     */
    public function aprobar($id)
    {
        try {
            $suggestion = ReplenishmentSuggestion::findOrFail($id);
            $suggestion->marcarAprobada(auth()->id());

            $this->dispatch('notify', [
                'type' => 'success',
                'message' => "Sugerencia {$suggestion->folio} aprobada"
            ]);

        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    /**
     * Rechazar sugerencia
     */
    public function rechazar($id, $motivo = 'Rechazado por gerente')
    {
        try {
            $suggestion = ReplenishmentSuggestion::findOrFail($id);
            $suggestion->marcarRechazada(auth()->id(), $motivo);

            $this->dispatch('notify', [
                'type' => 'info',
                'message' => "Sugerencia {$suggestion->folio} rechazada"
            ]);

        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    /**
     * Convertir a solicitud de compra
     */
    public function convertirACompra($id)
    {
        try {
            $service = new ReplenishmentService();
            $requestId = $service->convertToPurchaseRequest($id);

            $this->dispatch('notify', [
                'type' => 'success',
                'message' => "Solicitud de compra creada (ID: {$requestId})"
            ]);

            return redirect()->route('purchasing.requests.detail', $requestId);

        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    /**
     * Convertir a orden de producción
     */
    public function convertirAProduccion($id)
    {
        try {
            $service = new ReplenishmentService();
            $resultado = $service->convertToProductionOrder($id);

            $this->dispatch('notify', [
                'type' => 'success',
                'message' => "Orden de producción creada (ID: {$resultado['production_order_id']})"
            ]);

        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    /**
     * Aprobar múltiples sugerencias
     */
    public function aprobarSeleccionadas()
    {
        if (empty($this->selectedIds)) {
            $this->dispatch('notify', [
                'type' => 'warning',
                'message' => 'No hay sugerencias seleccionadas'
            ]);
            return;
        }

        $count = 0;
        foreach ($this->selectedIds as $id) {
            try {
                $suggestion = ReplenishmentSuggestion::find($id);
                if ($suggestion && $suggestion->puede_aprobarse) {
                    $suggestion->marcarAprobada(auth()->id());
                    $count++;
                }
            } catch (\Exception $e) {
                // Continuar con las demás
            }
        }

        $this->selectedIds = [];
        $this->selectAll = false;

        $this->dispatch('notify', [
            'type' => 'success',
            'message' => "{$count} sugerencias aprobadas"
        ]);
    }

    /**
     * Convertir seleccionadas a compras
     */
    public function convertirSeleccionadasACompra()
    {
        if (empty($this->selectedIds)) {
            $this->dispatch('notify', [
                'type' => 'warning',
                'message' => 'No hay sugerencias seleccionadas'
            ]);
            return;
        }

        $service = new ReplenishmentService();
        $count = 0;

        foreach ($this->selectedIds as $id) {
            try {
                $suggestion = ReplenishmentSuggestion::find($id);
                if ($suggestion && $suggestion->tipo === ReplenishmentSuggestion::TIPO_COMPRA) {
                    $service->convertToPurchaseRequest($id);
                    $count++;
                }
            } catch (\Exception $e) {
                // Continuar con las demás
            }
        }

        $this->selectedIds = [];
        $this->selectAll = false;

        $this->dispatch('notify', [
            'type' => 'success',
            'message' => "{$count} solicitudes de compra creadas"
        ]);
    }

    /**
     * Limpiar filtros
     */
    public function limpiarFiltros()
    {
        $this->reset(['tipoFilter', 'prioridadFilter', 'estadoFilter', 'sucursalFilter', 'search', 'urgenciasOnly']);
        $this->estadoFilter = 'PENDIENTE';
        $this->resetPage();
    }

    /**
     * Toggle selección de todos
     */
    public function updatedSelectAll($value)
    {
        if ($value) {
            $this->selectedIds = $this->getSuggestions()->pluck('id')->toArray();
        } else {
            $this->selectedIds = [];
        }
    }

    /**
     * Obtener sugerencias con filtros aplicados
     */
    protected function getSuggestions()
    {
        $query = ReplenishmentSuggestion::with(['item', 'sucursal'])
            ->orderByRaw("
                CASE prioridad
                    WHEN 'URGENTE' THEN 1
                    WHEN 'ALTA' THEN 2
                    WHEN 'NORMAL' THEN 3
                    WHEN 'BAJA' THEN 4
                END
            ")
            ->orderBy('fecha_agotamiento_estimada', 'asc')
            ->orderBy('created_at', 'desc');

        // Filtro de búsqueda
        if ($this->search) {
            $query->where(function ($q) {
                $q->where('folio', 'ilike', '%' . $this->search . '%')
                  ->orWhere('item_id', 'ilike', '%' . $this->search . '%')
                  ->orWhereHas('item', function ($q2) {
                      $q2->where('nombre', 'ilike', '%' . $this->search . '%');
                  });
            });
        }

        // Filtro de tipo
        if ($this->tipoFilter !== 'all') {
            $query->where('tipo', $this->tipoFilter);
        }

        // Filtro de prioridad
        if ($this->prioridadFilter !== 'all') {
            $query->where('prioridad', $this->prioridadFilter);
        }

        // Filtro de estado
        if ($this->estadoFilter !== 'all') {
            $query->where('estado', $this->estadoFilter);
        }

        // Filtro de sucursal
        if ($this->sucursalFilter !== 'all') {
            $query->where('sucursal_id', $this->sucursalFilter);
        }

        // Solo urgencias
        if ($this->urgenciasOnly) {
            $query->urgentes();
        }

        return $query;
    }

    public function render()
    {
        try {
            // Estadísticas globales (sin filtros, para dar contexto general)
            $stats = [
                'total' => ReplenishmentSuggestion::count(),
                'pendientes' => ReplenishmentSuggestion::pendiente()->count(),
                'urgentes' => ReplenishmentSuggestion::urgentes()->count(),
                'compras' => ReplenishmentSuggestion::compra()->pendiente()->count(),
                'producciones' => ReplenishmentSuggestion::produccion()->pendiente()->count(),
                'convertidas_hoy' => ReplenishmentSuggestion::convertida()
                    ->whereDate('convertido_en', today())
                    ->count(),
            ];

            // Sugerencias con filtros aplicados (para la tabla)
            $suggestions = $this->getSuggestions()->paginate(20);

            // Sucursales para filtro
            $sucursales = Sucursal::where('activo', true)->orderBy('nombre')->get();

            return view('livewire.replenishment.dashboard', [
                'suggestions' => $suggestions,
                'stats' => $stats,
                'sucursales' => $sucursales,
            ]);
        } catch (\Exception $e) {
            \Log::error('Error en Dashboard render: ' . $e->getMessage());

            // Retornar vista con datos vacíos en caso de error
            return view('livewire.replenishment.dashboard', [
                'suggestions' => new \Illuminate\Pagination\LengthAwarePaginator([], 0, 20),
                'stats' => [
                    'total' => 0,
                    'pendientes' => 0,
                    'urgentes' => 0,
                    'compras' => 0,
                    'producciones' => 0,
                    'convertidas_hoy' => 0,
                ],
                'sucursales' => collect([]),
            ]);
        }
    }
}
