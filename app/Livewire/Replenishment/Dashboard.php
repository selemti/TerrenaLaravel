<?php

namespace App\Livewire\Replenishment;

use App\Models\ReplenishmentSuggestion;
use App\Models\Catalogs\Sucursal;
use App\Services\Replenishment\ReplenishmentService;
use Illuminate\Database\Eloquent\Builder;
use Livewire\Component;
use Livewire\WithPagination;

class Dashboard extends Component
{
    use WithPagination;

    protected $paginationTheme = 'bootstrap';

    public array $suggestions = [];

    public array $stats = [];

    public bool $loading = false;

    public ?string $flashMessage = null;

    public ?string $errorMessage = null;

    // Filtros
    public string $search = '';

    public string $estadoFilter = 'PENDIENTE';

    public string $prioridadFilter = 'all';

    public string $sucursalFilter = 'all';

    public string $origenFilter = 'all';

    public string $fechaDesde = '';

    public string $fechaHasta = '';

    // Modales
    public bool $showModalAprobar = false;

    public bool $showModalRechazar = false;

    public bool $showModalConvertir = false;

    public ?int $selectedSuggestionId = null;

    public ?array $selectedSuggestion = null;

    public ?float $qtyAprobada = null;

    public string $motivoRechazo = '';

    public string $tipoConversion = 'purchase_request';

    protected $queryString = [
        'search' => ['except' => ''],
        'estadoFilter' => ['except' => 'PENDIENTE'],
        'prioridadFilter' => ['except' => 'all'],
        'sucursalFilter' => ['except' => 'all'],
        'origenFilter' => ['except' => 'all'],
    ];

    public function mount(): void
    {
        $this->loadSuggestions();
        $this->loadStats();
    }

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingEstadoFilter()
    {
        $this->resetPage();
    }

    public function updatingPrioridadFilter()
    {
        $this->resetPage();
    }

    public function updatingSucursalFilter()
    {
        $this->resetPage();
    }

    public function limpiarFiltros()
    {
        $this->reset([
            'search',
            'estadoFilter',
            'prioridadFilter',
            'sucursalFilter',
            'origenFilter',
            'fechaDesde',
            'fechaHasta',
        ]);
        $this->resetPage();
        $this->loadSuggestions();
        $this->loadStats();
    }

    /**
     * Ejecuta cálculo manual (sincronizado) usando el endpoint API.
     */
    public function runCalculation(): void
    {
        $this->loading = true;
        $this->flashMessage = null;
        $this->errorMessage = null;

        try {
            $resultado = app(ReplenishmentService::class)->generateDailySuggestions([
                'async' => false,
                'dias_analisis' => 7,
                'auto_aprobar' => false,
            ]);

            $total = (int) ($resultado['total'] ?? 0);
            $urgentes = (int) ($resultado['urgentes'] ?? 0);

            if ($total > 0) {
                $this->flashMessage = "Cálculo completado: {$total} sugerencias ({$urgentes} urgentes).";
            } else {
                $this->flashMessage = 'Cálculo completado sin nuevas sugerencias.';
            }

            $this->loadSuggestions();
            $this->loadStats();
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        } finally {
            $this->loading = false;
        }
    }

    /**
     * Carga sugerencias desde el endpoint API con filtros.
     */
    public function loadSuggestions(): void
    {
        $this->loading = true;
        $this->errorMessage = null;

        try {
            $this->suggestions = $this->buildSuggestionsQuery()
                ->limit(15)
                ->get()
                ->map(fn (ReplenishmentSuggestion $suggestion) => $suggestion->toArray())
                ->values()
                ->all();
        } catch (\Throwable $e) {
            $this->suggestions = [];
            $this->errorMessage = $e->getMessage();
        } finally {
            $this->loading = false;
        }
    }

    /**
     * Carga estadísticas desde la API.
     */
    public function loadStats(): void
    {
        try {
            $this->stats = [
                'total' => ReplenishmentSuggestion::count(),
                'pendiente' => ReplenishmentSuggestion::pendiente()->count(),
                'aprobada' => ReplenishmentSuggestion::aprobada()->count(),
                'rechazada' => ReplenishmentSuggestion::rechazada()->count(),
                'convertida' => ReplenishmentSuggestion::convertida()->count(),
                'urgentes' => ReplenishmentSuggestion::urgentes()->count(),
            ];
        } catch (\Throwable $e) {
            $this->stats = [
                'total' => 0,
                'pendiente' => 0,
                'aprobada' => 0,
                'rechazada' => 0,
                'convertida' => 0,
                'urgentes' => 0,
            ];
        }
    }

    /**
     * Abrir modal para aprobar sugerencia.
     */
    public function abrirModalAprobar(int $id): void
    {
        $this->selectedSuggestionId = $id;
        $this->selectedSuggestion = collect($this->suggestions)->firstWhere('id', $id);
        $this->qtyAprobada = $this->selectedSuggestion['qty_sugerida'] ?? null;
        $this->showModalAprobar = true;
    }

    /**
     * Aprobar sugerencia.
     */
    public function aprobarSugerencia(): void
    {
        $this->errorMessage = null;

        try {
            if (! $this->selectedSuggestionId) {
                $this->errorMessage = 'No se seleccionó una sugerencia.';

                return;
            }

            $suggestion = ReplenishmentSuggestion::findOrFail($this->selectedSuggestionId);
            $suggestion->marcarAprobada((int) auth()->id(), $this->qtyAprobada);

            $this->flashMessage = 'Sugerencia aprobada exitosamente.';
            $this->showModalAprobar = false;
            $this->loadSuggestions();
            $this->loadStats();
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    /**
     * Abrir modal para rechazar sugerencia.
     */
    public function abrirModalRechazar(int $id): void
    {
        $this->selectedSuggestionId = $id;
        $this->selectedSuggestion = collect($this->suggestions)->firstWhere('id', $id);
        $this->motivoRechazo = '';
        $this->showModalRechazar = true;
    }

    /**
     * Rechazar sugerencia.
     */
    public function rechazarSugerencia(): void
    {
        $this->errorMessage = null;

        if (empty($this->motivoRechazo)) {
            $this->errorMessage = 'El motivo de rechazo es requerido.';

            return;
        }

        try {
            if (! $this->selectedSuggestionId) {
                $this->errorMessage = 'No se seleccionó una sugerencia.';

                return;
            }

            $suggestion = ReplenishmentSuggestion::findOrFail($this->selectedSuggestionId);
            $suggestion->marcarRechazada((int) auth()->id(), $this->motivoRechazo);

            $this->flashMessage = 'Sugerencia rechazada.';
            $this->showModalRechazar = false;
            $this->loadSuggestions();
            $this->loadStats();
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    /**
     * Abrir modal para convertir sugerencia.
     */
    public function abrirModalConvertir(int $id): void
    {
        $this->selectedSuggestionId = $id;
        $this->selectedSuggestion = collect($this->suggestions)->firstWhere('id', $id);
        $this->tipoConversion = 'purchase_request';
        $this->showModalConvertir = true;
    }

    /**
     * Convertir sugerencia a Purchase Request o Production Order.
     */
    public function convertirSugerencia(): void
    {
        $this->errorMessage = null;

        try {
            if (! $this->selectedSuggestionId) {
                $this->errorMessage = 'No se seleccionó una sugerencia.';

                return;
            }

            $suggestion = ReplenishmentSuggestion::findOrFail($this->selectedSuggestionId);

            if ($this->tipoConversion === 'purchase_request') {
                app(ReplenishmentService::class)->convertToPurchaseRequest($suggestion->id, [
                    'qty' => $this->qtyAprobada,
                    'user_id' => auth()->id(),
                ]);
                $tipo = 'Solicitud de Compra';
            } else {
                app(ReplenishmentService::class)->convertToProductionOrder($suggestion->id, [
                    'qty' => $this->qtyAprobada,
                    'user_id' => auth()->id(),
                ]);
                $tipo = 'Orden de Producción';
            }

            $this->flashMessage = "Sugerencia convertida a {$tipo} exitosamente.";
            $this->showModalConvertir = false;
            $this->loadSuggestions();
            $this->loadStats();
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
    }

    protected function buildSuggestionsQuery(): Builder
    {
        $query = ReplenishmentSuggestion::with(['item', 'sucursal', 'almacen', 'revisadoPor']);

        if ($this->estadoFilter !== 'all') {
            $query->where('estado', $this->estadoFilter);
        }

        if ($this->prioridadFilter !== 'all') {
            $query->where('prioridad', $this->prioridadFilter);
        }

        if ($this->sucursalFilter !== 'all') {
            $query->where('sucursal_id', $this->sucursalFilter);
        }

        if ($this->origenFilter !== 'all') {
            $query->where('origen', $this->origenFilter);
        }

        if ($this->fechaDesde) {
            $query->whereDate('sugerido_en', '>=', $this->fechaDesde);
        }

        if ($this->fechaHasta) {
            $query->whereDate('sugerido_en', '<=', $this->fechaHasta);
        }

        if ($this->search !== '') {
            $needle = '%'.mb_strtolower($this->search).'%';
            $query->where(function (Builder $inner) use ($needle) {
                $inner->whereRaw('LOWER(COALESCE(folio, \'\')) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(COALESCE(item_id, \'\')) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(COALESCE(motivo, \'\')) LIKE ?', [$needle]);
            });
        }

        return $query->orderBy('prioridad')->orderByDesc('sugerido_en');
    }

    public function render()
    {
        $sucursales = Sucursal::orderBy('nombre')->get();

        return view('livewire.replenishment.dashboard', [
            'sucursales' => $sucursales,
        ])->layout('layouts.terrena', [
            'active' => 'compras',
            'title' => 'Replenishment',
            'pageTitle' => 'Replenishment',
        ]);
    }
}
