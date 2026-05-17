<?php

namespace App\Livewire\Replenishment;

use App\Models\Catalogs\Sucursal;
use Illuminate\Support\Facades\Http;
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
            $response = Http::post('/api/purchasing/replenishment/calculate', [
                'async' => false,
                'dias_analisis' => 7,
                'auto_aprobar' => false,
            ]);

            if ($response->successful() && ($response->json('success') ?? false)) {
                $data = $response->json('data') ?? [];
                $total = $data['total'] ?? 0;
                $urgentes = $data['urgentes'] ?? 0;
                $this->flashMessage = "Cálculo completado: {$total} sugerencias ({$urgentes} urgentes).";
                $this->loadSuggestions();
            } else {
                $this->errorMessage = $response->json('message') ?? 'No se pudo calcular sugerencias.';
            }
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
            $params = [
                'per_page' => 15,
                'order_by' => 'prioridad',
                'order_dir' => 'asc',
            ];

            // Aplicar filtros
            if ($this->estadoFilter !== 'all') {
                $params['estado'] = $this->estadoFilter;
            }

            if ($this->prioridadFilter !== 'all') {
                $params['prioridad'] = $this->prioridadFilter;
            }

            if ($this->sucursalFilter !== 'all') {
                $params['sucursal_id'] = $this->sucursalFilter;
            }

            if ($this->origenFilter !== 'all') {
                $params['origen'] = $this->origenFilter;
            }

            if ($this->fechaDesde) {
                $params['desde'] = $this->fechaDesde;
            }

            if ($this->fechaHasta) {
                $params['hasta'] = $this->fechaHasta;
            }

            if ($this->search) {
                $params['search'] = $this->search;
            }

            $response = Http::get(url('/api/purchasing/replenishment/suggestions'), $params);

            if ($response->successful() && ($response->json('success') ?? false)) {
                $this->suggestions = $response->json('data') ?? [];
            } else {
                $this->suggestions = [];
                $this->errorMessage = $response->json('message') ?? 'No se pudieron cargar sugerencias.';
            }
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
            // Cargar conteos por estado
            $estados = ['PENDIENTE', 'APROBADA', 'RECHAZADA', 'CONVERTIDA'];
            $this->stats = ['total' => 0];

            foreach ($estados as $estado) {
                $response = Http::get(url('/api/purchasing/replenishment/suggestions'), [
                    'estado' => $estado,
                    'per_page' => 1,
                ]);

                if ($response->successful()) {
                    $total = $response->json('pagination.total') ?? 0;
                    $this->stats[strtolower($estado)] = $total;
                    $this->stats['total'] += $total;
                }
            }

            // Contar urgentes (todas las prioridades URGENTE)
            $response = Http::get(url('/api/purchasing/replenishment/suggestions'), [
                'prioridad' => 'URGENTE',
                'per_page' => 1,
            ]);

            if ($response->successful()) {
                $this->stats['urgentes'] = $response->json('pagination.total') ?? 0;
            }
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
            $response = Http::post("/api/purchasing/replenishment/suggestions/{$this->selectedSuggestionId}/approve", [
                'qty_aprobada' => $this->qtyAprobada,
            ]);

            if ($response->successful() && ($response->json('success') ?? false)) {
                $this->flashMessage = 'Sugerencia aprobada exitosamente.';
                $this->showModalAprobar = false;
                $this->loadSuggestions();
                $this->loadStats();
            } else {
                $this->errorMessage = $response->json('message') ?? 'Error al aprobar sugerencia.';
            }
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
            $response = Http::post("/api/purchasing/replenishment/suggestions/{$this->selectedSuggestionId}/reject", [
                'motivo' => $this->motivoRechazo,
            ]);

            if ($response->successful() && ($response->json('success') ?? false)) {
                $this->flashMessage = 'Sugerencia rechazada.';
                $this->showModalRechazar = false;
                $this->loadSuggestions();
                $this->loadStats();
            } else {
                $this->errorMessage = $response->json('message') ?? 'Error al rechazar sugerencia.';
            }
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
            $response = Http::post("/api/purchasing/replenishment/suggestions/{$this->selectedSuggestionId}/convert", [
                'tipo' => $this->tipoConversion,
            ]);

            if ($response->successful() && ($response->json('success') ?? false)) {
                $tipo = $this->tipoConversion === 'purchase_request' ? 'Solicitud de Compra' : 'Orden de Producción';
                $this->flashMessage = "Sugerencia convertida a {$tipo} exitosamente.";
                $this->showModalConvertir = false;
                $this->loadSuggestions();
                $this->loadStats();
            } else {
                $this->errorMessage = $response->json('message') ?? 'Error al convertir sugerencia.';
            }
        } catch (\Throwable $e) {
            $this->errorMessage = $e->getMessage();
        }
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
