<?php

namespace App\Http\Controllers\Reports;

use App\Services\Reports\ProductsReportService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\View;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Symfony\Component\HttpFoundation\StreamedCsvResponse;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\DB;

class ProductsReportController extends BaseReportController
{
    protected ProductsReportService $service;

    public function __construct(ProductsReportService $service)
    {
        $this->service = $service;
        parent::__construct();
    }

    /**
     * Muestra el dashboard del reporte de productos
     */
    public function index(Request $request): \Illuminate\View\View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        // Meses por defecto: últimos 3 meses para productos individuales
        $defaultStart = Carbon::now()->subMonths(3)->startOfMonth();
        $defaultEnd = Carbon::now()->endOfMonth();

        // Usar fechas del request o por defecto
        $start = $start ?? $defaultStart;
        $end = $end ?? $defaultEnd;

        // Obtener datos principales - por defecto mostrar productos individuales
        $groupBy = request('group_by', 'product');
        $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, $groupBy);
        $summary = $this->service->getSummary($data);

        // Obtener comparación mes a mes
        $monthlyComparison = $this->service->getMonthComparison($start, $end);

        // Obtener datos para gráficos
        $chartData = $this->prepareChartData($data);

        // Estadísticas rápidas del día actual
        $todayData = $this->getTodayStats();

        // Obtener totales detallados usando metodología JasperReports
        $jasperTotals = $this->service->getJasperReportsTotals($start, $end, $branches, $terminals);

        return view('reports.products.index', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'data' => $data,
            'summary' => $summary,
            'monthlyComparison' => $monthlyComparison,
            'chartData' => $chartData,
            'todayStats' => $todayData,
            'groupBy' => $groupBy,
            'jasperTotals' => $jasperTotals,
        ]);
    }

    /**
     * API endpoint para obtener datos dinámicos
     */
    public function apiProducts(Request $request): \Illuminate\Http\JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $groupBy = $request->input('group_by', 'month');

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, $groupBy);
            $summary = $this->service->getSummary($data);

            return response()->json([
                'ok' => true,
                'data' => $data,
                'summary' => $summary,
                'timestamp' => now()->toIso8601String()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al obtener datos de productos',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
    }

    /**
     * API endpoint para productos agrupados por categoría
     */
    public function apiCategories(Request $request): \Illuminate\Http\JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, 'category');
            $summary = $this->service->getSummary($data);

            return response()->json([
                'ok' => true,
                'data' => $data,
                'summary' => $summary,
                'timestamp' => now()->toIso8601String()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al obtener datos por categoría',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
    }

    /**
     * API endpoint para productos detallados
     */
    public function apiDetailed(Request $request): \Illuminate\Http\JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, 'product');
            $summary = $this->service->getSummary($data);

            return response()->json([
                'ok' => true,
                'data' => $data,
                'summary' => $summary,
                'timestamp' => now()->toIso8601String()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al obtener productos detallados',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
    }

    /**
     * API endpoint para datos diarios
     */
    public function apiDaily(Request $request): \Illuminate\Http\JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);

        try {
            $data = $this->service->fetchDailyProducts($start, $end, $branches, $terminals);

            return response()->json([
                'ok' => true,
                'data' => $data,
                'count' => $data->count(),
                'timestamp' => now()->toIso8601String()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al obtener datos diarios',
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String()
            ], 500);
        }
    }

    /**
     * Exportar a PDF
     */
    public function exportPdf(Request $request)
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $groupBy = $request->input('group_by', 'month');

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, $groupBy);
            $summary = $this->service->getSummary($data);

            $filename = 'productos_vendidos_' . $start->format('Y-m-d') . '_a_' . $end->format('Y-m-d') . '.pdf';

            return $this->renderPdf('reports.products.pdf', [
                'title' => 'Reporte de Productos Vendidos',
                'start' => $start->format('d/m/Y'),
                'end' => $end->format('d/m/Y'),
                'data' => $data,
                'summary' => $summary,
                'groupBy' => $groupBy,
                'branches' => $branches,
                'terminals' => $terminals,
            ], $filename);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al generar PDF',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Exportar a Excel
     */
    public function exportExcel(Request $request)
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $groupBy = $request->input('group_by', 'month');

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, $groupBy);
            $summary = $this->service->getSummary($data);

            return Excel::download(new ProductsExport($data, $summary, $groupBy), 'productos_vendidos_' . $start->format('Y-m-d') . '_a_' . $end->format('Y-m-d') . '.xlsx');
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al generar Excel',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Exportar a CSV
     */
    public function exportCsv(Request $request)
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $groupBy = $request->input('group_by', 'month');

        try {
            $data = $this->service->fetchProductsByMonth($start, $end, $branches, $terminals, $groupBy);

            $headers = [
                'Content-Type' => 'text/csv',
                'Content-Disposition' => 'attachment; filename="productos_vendidos_' . $start->format('Y-m-d') . '.csv"',
            ];

            $callback = function() use ($data) {
                $file = fopen('php://output', 'w');
                // Cabecera CSV
                fputcsv($file, ['Mes', 'Año', 'Unidades', 'Ingreso Total', 'Tickets', 'Productos Únicos']);

                foreach ($data as $row) {
                    fputcsv($file, [
                        $row->mes_formateado,
                        $row->anio,
                        $row->unidades_vendidas,
                        $row->ingreso_total_formateado,
                        $row->tickets_totales,
                        $row->productos_unicos ?? 0
                    ]);
                }
                fclose($file);
            };

            return new StreamedResponse('php://output', 200, $headers, $callback);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'error' => 'Error al generar CSV',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Prepara datos para gráficos
     */
    protected function prepareChartData($data): array
    {
        return [
            'labels' => $data->pluck('mes_formateado'),
            'unidades' => $data->pluck('unidades_vendidas'),
            'ingresos' => $data->pluck('ingreso_total'),
            'tickets' => $data->pluck('tickets_totales'),
        ];
    }

    /**
     * Obtiene estadísticas rápidas del día actual
     */
    protected function getTodayStats(): array
    {
        try {
            $today = now()->startOfDay();
            $tomorrow = now()->endOfDay();

            $query = DB::connection('pgsql')
                ->table('public.ticket AS t')
                ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
                ->whereBetween('t.folio_date', [$today, $tomorrow])
                ->where('t.paid', '=', true)
                ->where('t.voided', '=', false)
                ->selectRaw('
                    SUM(ti.item_count) as unidades,
                    SUM(ti.total_price) as ingresos,
                    COUNT(DISTINCT t.id) as tickets,
                    COUNT(DISTINCT ti.item_name) as productos_unicos
                ')
                ->first();

            return [
                'unidades' => (int) ($query->unidades ?? 0),
                'ingresos' => (float) ($query->ingresos ?? 0),
                'tickets' => (int) ($query->tickets ?? 0),
                'productos_unicos' => (int) ($query->productos_unicos ?? 0),
                'ingresos_formateado' => '$' . number_format($query->ingresos ?? 0, 2),
            ];
        } catch (\Exception $e) {
            return [
                'unidades' => 0,
                'ingresos' => 0,
                'tickets' => 0,
                'productos_unicos' => 0,
                'ingresos_formateado' => '$0.00',
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Resuelve filtros desde request
     */
    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);

        $branchParam = $request->input('branch', []);
        $branches = is_array($branchParam)
            ? $branchParam
            : explode(',', (string) $branchParam);

        $branches = $this->normalizeFilterList($branches, true);

        $terminalParam = $request->input('terminal', []);
        $terminals = is_array($terminalParam)
            ? $terminalParam
            : explode(',', (string) $terminalParam);

        $terminals = $this->normalizeFilterList($terminals, false);

        return [$start, $end, $branches, $terminals];
    }
}

// Export class para Excel
class ProductsExport implements \Maatwebsite\Excel\Concerns\FromCollection, \Maatwebsite\Excel\Concerns\WithHeadings
{
    protected $data;
    protected array $summary;
    protected string $groupBy;

    public function __construct($data, array $summary, string $groupBy = 'month')
    {
        $this->data = $data;
        $this->summary = $summary;
        $this->groupBy = $groupBy;
    }

    public function collection()
    {
        return $this->data;
    }

    public function headings(): array
    {
        if ($this->groupBy === 'month') {
            return ['Mes', 'Año', 'Unidades Vendidas', 'Ingreso Total', 'Tickets', 'Productos Únicos'];
        } elseif ($this->groupBy === 'category') {
            return ['Categoría', 'Unidades Vendidas', 'Ingreso Total', 'Tickets', 'Productos Únicos'];
        } else {
            return ['Categoría', 'Grupo', 'Producto', 'Unidades Vendidas', 'Ingreso Total', 'Tickets', 'Precio Promedio', 'Precio Mínimo', 'Precio Máximo'];
        }
    }

    public function map($row): array
    {
        if ($this->groupBy === 'month') {
            return [
                $row->mes_formateado,
                $row->anio,
                $row->unidades_vendidas,
                $row->ingreso_total,
                $row->tickets_totales,
                $row->productos_unicos ?? 0,
            ];
        } elseif ($this->groupBy === 'category') {
            return [
                $row->categoria,
                $row->unidades_vendidas,
                $row->ingreso_total,
                $row->tickets_totales,
                $row->productos_unicos,
            ];
        } else {
            return [
                $row->categoria ?? '',
                $row->grupo_menu ?? '',
                $row->producto ?? '',
                $row->unidades_vendidas,
                $row->ingreso_total,
                $row->tickets_totales,
                $row->precio_promedio_formateado ?? '$0.00',
                $row->precio_minimo_formateado ?? '$0.00',
                $row->precio_maximo_formateado ?? '$0.00',
            ];
        }
    }
}