<?php

namespace App\Livewire\Reports;

use App\Models\Reports\ReportFavorite;
use App\Services\Reports\ReportExportService;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Livewire\Component;

/**
 * Dashboard interactivo con KPIs y gráficas.
 *
 * El componente consulta los datos agregados directamente en PostgreSQL
 * utilizando la conexión `pgsql`. Cuando alguna vista o tabla auxiliar no está
 * disponible (por ejemplo en entornos de desarrollo sin todas las migraciones)
 * el componente captura la excepción y deja los valores en cero para evitar
 * fallos en la interfaz.
 */
class Dashboard extends Component
{
    public string $dateRange = 'last_30_days';

    public Carbon $fechaDesde;

    public Carbon $fechaHasta;

    public string $fechaDesdePersonalizada = '';

    public string $fechaHastaPersonalizada = '';

    /** @var array<string, float> */
    public array $kpis = [];

    /** @var array<string, array<int, mixed>> */
    public array $charts = [];

    /** @var array<int, array{id:int,key:string,label:string,meta:array}> */
    public array $favorites = [];

    /** @var array<string, mixed> */
    public array $summary = [];

    public array $dashboardLayout = [
        'summary' => true,
        'kpis' => true,
        'ventas_por_dia' => true,
        'top_productos' => true,
        'mermas_por_categoria' => true,
        'stock_por_almacen' => true,
    ];

    public bool $autoRefreshEnabled = false;

    public int $refreshInterval = 300; // 5 minutos por defecto

    public function mount(): void
    {
        $this->setDateRange();
        $this->loadFavorites();
        $this->loadSummary();
        $this->loadData();
    }

    public function updatedDateRange(): void
    {
        $this->setDateRange();
        $this->loadSummary();
        $this->loadData();
    }

    public function loadData(): void
    {
        $this->kpis = $this->loadKpis();
        $this->charts = $this->loadCharts();

        $this->dispatch('dashboard-data-updated', data: [
            'kpis' => $this->kpis,
            'charts' => $this->charts,
        ]);
    }

    public function export(string $type)
    {
        $type = strtolower($type);
        abort_unless(in_array($type, ['csv', 'pdf'], true), 404);

        $service = app(ReportExportService::class);

        return $service->export(
            type: $type,
            range: $this->dateRange,
            from: $this->fechaDesde,
            to: $this->fechaHasta,
            kpis: $this->kpis,
            charts: $this->charts,
        );
    }

    public function toggleFavorite(string $key): void
    {
        $user = Auth::user();
        if (! $user) {
            return;
        }

        $favorite = ReportFavorite::query()
            ->where('user_id', $user->id)
            ->where('report_key', $key)
            ->first();

        if ($favorite) {
            $favorite->delete();
            $this->dispatch('toast', type: 'info', body: 'Reporte eliminado de favoritos');
        } else {
            ReportFavorite::create([
                'user_id' => $user->id,
                'report_key' => $key,
                'meta' => [
                    'range' => $this->dateRange,
                    'title' => Str::headline(str_replace('_', ' ', $key)),
                ],
            ]);

            $this->dispatch('toast', type: 'success', body: 'Reporte agregado a favoritos');
        }

        $this->loadFavorites();
    }

    public function goToFavoriteReport(string $key)
    {
        if ($key === 'ventas_totales') {
            return $this->goToSalesReport();
        }

        // Para otros tipos de reportes, simplemente actualizamos el rango de fechas
        $this->dateRange = 'custom';
        $this->fechaDesdePersonalizada = $this->fechaDesde->format('Y-m-d');
        $this->fechaHastaPersonalizada = $this->fechaHasta->format('Y-m-d');

        // Desplazar hacia el KPI correspondiente
        $this->dispatch('scroll-to-kpi', $key);
    }

    public function onChartClick(string $chartKey, array $data)
    {
        // Este método manejará los clics en los gráficos
        // Por ejemplo, al hacer clic en una barra del gráfico de productos,
        // podríamos navegar a un reporte detallado del producto
        $this->dispatch('toast', type: 'info', body: "Clic en ${chartKey}: ".json_encode($data));
    }

    public function render()
    {
        return view('livewire.reports.dashboard')
            ->layout('layouts.terrena', [
                'active' => 'reportes',
                'title' => 'Dashboard de reportes',
                'pageTitle' => 'Dashboard',
            ]);
    }

    public function goToSalesReport()
    {
        $params = [
            'fecha_desde' => $this->fechaDesde->format('Y-m-d'),
            'fecha_hasta' => $this->fechaHasta->format('Y-m-d'),
        ];

        return redirect()->route('reports.sales', $params);
    }

    protected function setDateRange(): void
    {
        $now = now();

        if ($this->dateRange === 'custom' && $this->fechaDesdePersonalizada && $this->fechaHastaPersonalizada) {
            $this->fechaDesde = Carbon::parse($this->fechaDesdePersonalizada)->startOfDay();
            $this->fechaHasta = Carbon::parse($this->fechaHastaPersonalizada)->endOfDay();
        } else {
            $ranges = [
                'today' => [
                    $now->copy()->startOfDay(),
                    $now->copy()->endOfDay(),
                ],
                'yesterday' => [
                    $now->copy()->subDay()->startOfDay(),
                    $now->copy()->subDay()->endOfDay(),
                ],
                'last_7_days' => [
                    $now->copy()->subDays(6)->startOfDay(),
                    $now->copy()->endOfDay(),
                ],
                'last_30_days' => [
                    $now->copy()->subDays(29)->startOfDay(),
                    $now->copy()->endOfDay(),
                ],
                'this_month' => [
                    $now->copy()->startOfMonth(),
                    $now->copy()->endOfMonth(),
                ],
                'last_month' => [
                    $now->copy()->subMonth()->startOfMonth(),
                    $now->copy()->subMonth()->endOfMonth(),
                ],
            ];

            [$this->fechaDesde, $this->fechaHasta] = $ranges[$this->dateRange] ?? $ranges['last_30_days'];
        }
    }

    /**
     * @return array<string, float>
     */
    protected function loadKpis(): array
    {
        $from = $this->fechaDesde->toDateTimeString();
        $to = $this->fechaHasta->toDateTimeString();

        $connection = DB::connection('pgsql');

        $ventas = $this->safeAggregate(fn () => (float) $connection->table('ticket')
            ->whereBetween('create_date', [$from, $to])
            ->where('voided', false)
            ->sum('total_price')
        );

        $produccion = $this->safeAggregate(fn () => (float) $connection->table('production_orders')
            ->whereBetween('cerrado_en', [$from, $to])
            ->where('estado', 'COMPLETADO')
            ->sum('qty_producida')
        );

        $compras = $this->safeAggregate(fn () => (float) $connection->table('recepcion_cab')
            ->whereBetween('fecha_recepcion', [$from, $to])
            ->sum('total')
        );

        $inventario = $this->safeAggregate(fn () => (float) $connection->table('vw_stock_valorizado')->sum('valor_total')
        );

        $merma = $this->safeAggregate(fn () => (float) $connection->table('production_orders')
            ->whereBetween('cerrado_en', [$from, $to])
            ->where('estado', 'COMPLETADO')
            ->avg('qty_merma')
        );

        $costoPromedio = $this->safeAggregate(fn () => (float) $connection->table('recipe_cost_snapshots')
            ->whereBetween('snapshot_date', [$from, $to])
            ->avg('cost_per_portion')
        );

        $rotacion = $this->calculateInventoryTurnover($from, $to);
        $eficiencia = $this->calculateProductionEfficiency($from, $to);

        // Métricas adicionales
        $tickets = $this->safeAggregate(fn () => (int) $connection->table('ticket')
            ->whereBetween('create_date', [$from, $to])
            ->where('voided', false)
            ->count()
        );

        $productosDistintosVendidos = $this->safeAggregate(fn () => (int) $connection->table('ticket_item')
            ->join('ticket', 'ticket_item.ticket_id', '=', 'ticket.id')
            ->whereBetween('ticket.create_date', [$from, $to])
            ->where('ticket.voided', false)
            ->distinct('ticket_item.item_name')
            ->count('ticket_item.item_name')
        );

        return [
            'ventas_totales' => $ventas,
            'produccion_total' => $produccion,
            'compras_totales' => $compras,
            'inventario_actual' => $inventario,
            'merma_promedio' => $merma,
            'costo_receta_promedio' => $costoPromedio,
            'rotacion_inventario' => $rotacion,
            'eficiencia_produccion' => $eficiencia,
            'tickets_totales' => $tickets,
            'productos_distintos_vendidos' => $productosDistintosVendidos,
        ];
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    protected function loadCharts(): array
    {
        $from = $this->fechaDesde->toDateTimeString();
        $to = $this->fechaHasta->toDateTimeString();
        $connection = DB::connection('pgsql');

        $ventasPorDia = $this->safeCollection(fn () => $connection->table('ticket')
            ->selectRaw('DATE(create_date) AS fecha, SUM(total_price) AS total')
            ->whereBetween('create_date', [$from, $to])
            ->where('voided', false)
            ->groupBy('fecha')
            ->orderBy('fecha')
            ->get()
            ->map(fn ($row) => [
                'fecha' => Carbon::parse($row->fecha)->format('d/m'),
                'total' => (float) $row->total,
            ])
            ->all()
        );

        $topProductos = $this->safeCollection(fn () => $connection->table('ticket_item')
            ->selectRaw('item_name, SUM(qty) AS total_qty')
            ->whereBetween('created_at', [$from, $to])
            ->groupBy('item_name')
            ->orderByDesc('total_qty')
            ->limit(10)
            ->get()
            ->map(fn ($row) => [
                'producto' => $row->item_name,
                'cantidad' => (float) $row->total_qty,
            ])
            ->all()
        );

        $mermas = $this->safeCollection(fn () => $connection->table('inventory_wastes')
            ->selectRaw('COALESCE(motivo, \"Sin motivo\") AS motivo, SUM(qty) AS total')
            ->whereBetween('registrado_en', [$from, $to])
            ->groupBy('motivo')
            ->orderByDesc('total')
            ->limit(6)
            ->get()
            ->map(fn ($row) => [
                'motivo' => $row->motivo,
                'total' => (float) $row->total,
            ])
            ->all()
        );

        $stockPorAlmacen = $this->safeCollection(fn () => $connection->table('vw_stock_valorizado')
            ->selectRaw('almacen_nombre, SUM(valor_total) AS total')
            ->groupBy('almacen_nombre')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => [
                'almacen' => $row->almacen_nombre ?? 'Sin nombre',
                'valor' => (float) $row->total,
            ])
            ->all()
        );

        $costosRecetas = $this->safeCollection(fn () => $connection->table('recipe_cost_snapshots')
            ->selectRaw('recipe_id, snapshot_date, cost_per_portion')
            ->whereBetween('snapshot_date', [$from, $to])
            ->orderByDesc('snapshot_date')
            ->limit(30)
            ->get()
            ->groupBy('recipe_id')
            ->map(function (Collection $items, $recipeId) {
                return [
                    'recipe_id' => (string) $recipeId,
                    'data' => $items->sortBy('snapshot_date')->map(fn ($row) => [
                        'fecha' => Carbon::parse($row->snapshot_date)->format('d/m'),
                        'costo' => (float) $row->cost_per_portion,
                    ])->values()->all(),
                ];
            })
            ->take(5)
            ->values()
            ->all()
        );

        return [
            'ventas_por_dia' => [
                'data' => $ventasPorDia,
                'empty' => empty($ventasPorDia),
                'message' => empty($ventasPorDia) ? 'No hay datos de ventas en el rango de fechas seleccionado' : null,
            ],
            'top_productos' => [
                'data' => $topProductos,
                'empty' => empty($topProductos),
                'message' => empty($topProductos) ? 'No hay productos vendidos en el rango de fechas seleccionado' : null,
            ],
            'mermas_por_categoria' => [
                'data' => $mermas,
                'empty' => empty($mermas),
                'message' => empty($mermas) ? 'No se han registrado mermas en el rango de fechas seleccionado' : null,
            ],
            'stock_por_almacen' => [
                'data' => $stockPorAlmacen,
                'empty' => empty($stockPorAlmacen),
                'message' => empty($stockPorAlmacen) ? 'No hay datos de inventario disponibles' : null,
            ],
            'costos_recetas' => [
                'data' => $costosRecetas,
                'empty' => empty($costosRecetas),
                'message' => empty($costosRecetas) ? 'No hay datos históricos de costos de recetas' : null,
            ],
        ];
    }

    protected function calculateInventoryTurnover(string $from, string $to): float
    {
        return $this->safeAggregate(function () use ($from, $to) {
            $connection = DB::connection('pgsql');

            $ventas = $connection->table('ticket_item')
                ->whereBetween('created_at', [$from, $to])
                ->sum(DB::raw('qty * price')); // costo aproximado

            $inventarioInicial = $connection->table('vw_stock_valorizado')
                ->sum('valor_total');

            if ($inventarioInicial <= 0) {
                return 0.0;
            }

            return (float) ($ventas / max($inventarioInicial, 1));
        });
    }

    protected function calculateProductionEfficiency(string $from, string $to): float
    {
        return $this->safeAggregate(function () use ($from, $to) {
            $connection = DB::connection('pgsql');

            $planned = $connection->table('production_orders')
                ->whereBetween('programado_para', [$from, $to])
                ->sum('qty_programada');

            $produced = $connection->table('production_orders')
                ->whereBetween('cerrado_en', [$from, $to])
                ->sum('qty_producida');

            if ($planned <= 0) {
                return 0.0;
            }

            return (float) (($produced / max($planned, 1)) * 100);
        });
    }

    /**
     * Ejecuta un agregado capturando errores de conexión o esquema.
     */
    protected function safeAggregate(callable $callback): float
    {
        try {
            return (float) ($callback() ?? 0.0);
        } catch (\Throwable $e) {
            report($e);

            return 0.0;
        }
    }

    /**
     * @param  callable():array<int, mixed>  $callback
     * @return array<int, mixed>
     */
    protected function safeCollection(callable $callback): array
    {
        try {
            $result = $callback();

            return is_array($result) ? $result : [];
        } catch (\Throwable $e) {
            report($e);

            return [];
        }
    }

    protected function loadFavorites(): void
    {
        $user = Auth::user();
        if (! $user) {
            $this->favorites = [];

            return;
        }

        $this->favorites = ReportFavorite::query()
            ->where('user_id', $user->id)
            ->orderByDesc('id')
            ->get()
            ->map(fn (ReportFavorite $favorite) => [
                'id' => $favorite->id,
                'key' => $favorite->report_key,
                'label' => Str::headline(str_replace('_', ' ', $favorite->report_key)),
                'meta' => $favorite->meta ?? [],
            ])
            ->all();
    }

    protected function loadSummary(): void
    {
        $from = $this->fechaDesde->toDateTimeString();
        $to = $this->fechaHasta->toDateTimeString();
        $connection = DB::connection('pgsql');

        try {
            $ventas = $connection->table('ticket')
                ->whereBetween('create_date', [$from, $to])
                ->where('voided', false)
                ->sum('total_price');

            $ventasCount = $connection->table('ticket')
                ->whereBetween('create_date', [$from, $to])
                ->where('voided', false)
                ->count();

            $productosVendidos = $connection->table('ticket_item')
                ->whereBetween('created_at', [$from, $to])
                ->sum('qty');

            $productosCount = $connection->table('ticket_item')
                ->whereBetween('created_at', [$from, $to])
                ->distinct('item_name')
                ->count('item_name');

            $this->summary = [
                'ventas_totales' => $ventas,
                'transacciones' => $ventasCount,
                'productos_vendidos' => $productosVendidos,
                'productos_distintos' => $productosCount,
                'ticket_promedio' => $ventasCount > 0 ? $ventas / $ventasCount : 0,
            ];
        } catch (\Throwable $e) {
            report($e);
            $this->summary = [
                'ventas_totales' => 0,
                'transacciones' => 0,
                'productos_vendidos' => 0,
                'productos_distintos' => 0,
                'ticket_promedio' => 0,
            ];
        }
    }

    public function updateLayout(string $component, bool $visible): void
    {
        $this->dashboardLayout[$component] = $visible;
    }

    public function resetLayout(): void
    {
        $this->dashboardLayout = [
            'summary' => true,
            'kpis' => true,
            'ventas_por_dia' => true,
            'top_productos' => true,
            'mermas_por_categoria' => true,
            'stock_por_almacen' => true,
        ];
    }

    public function toggleAutoRefresh(): void
    {
        $this->autoRefreshEnabled = ! $this->autoRefreshEnabled;

        if ($this->autoRefreshEnabled) {
            $this->dispatch('start-auto-refresh', interval: $this->refreshInterval * 1000);
        } else {
            $this->dispatch('stop-auto-refresh');
        }
    }

    public function updatedRefreshInterval(): void
    {
        if ($this->autoRefreshEnabled) {
            $this->dispatch('start-auto-refresh', interval: $this->refreshInterval * 1000);
        }
    }

    #[\Livewire\Attributes\On('auto-refresh')]
    public function handleAutoRefresh(): void
    {
        if ($this->autoRefreshEnabled) {
            $this->loadSummary();
            $this->loadData();
        }
    }
}
