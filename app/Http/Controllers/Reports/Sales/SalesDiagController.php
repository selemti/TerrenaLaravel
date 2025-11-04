<?php

namespace App\Http\Controllers\Reports\Sales;

use App\Http\Controllers\Reports\BaseReportController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SalesDiagController extends BaseReportController
{
    /**
     * API: Obtener diagnósticos diarios en JSON
     */
    public function index(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $severityFilter = $request->input('severity'); // INFO, WARN, CRITICAL

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_daily_diagnostics_summary_on(?)', [$date->format('Y-m-d')]);

        // Filtrar por severidad si se especifica
        if ($severityFilter) {
            $data = array_filter($data, fn($r) => strtoupper($r->severidad) === strtoupper($severityFilter));
        }

        return response()->json([
            'success' => true,
            'date' => $date->format('Y-m-d'),
            'severity_filter' => $severityFilter,
            'data' => array_values($data),
            'summary' => [
                'total_checks' => count($data),
                'critical_count' => count(array_filter($data, fn($r) => $r->severidad === 'CRITICAL')),
                'warning_count' => count(array_filter($data, fn($r) => $r->severidad === 'WARN')),
                'info_count' => count(array_filter($data, fn($r) => $r->severidad === 'INFO')),
            ]
        ], 200, [], JSON_PRETTY_PRINT);
    }

    /**
     * WEB: Mostrar vista de diagnósticos diarios
     */
    public function show(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $severityFilter = $request->input('severity');

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_daily_diagnostics_summary_on(?)', [$date->format('Y-m-d')]);

        // Filtrar por severidad si se especifica
        $filteredData = $data;
        if ($severityFilter) {
            $filteredData = array_filter($data, fn($r) => strtoupper($r->severidad) === strtoupper($severityFilter));
        }

        // Calcular resumen
        $summary = [
            'total_checks' => count($data),
            'filtered_count' => count($filteredData),
            'critical_count' => count(array_filter($data, fn($r) => $r->severidad === 'CRITICAL')),
            'warning_count' => count(array_filter($data, fn($r) => $r->severidad === 'WARN')),
            'info_count' => count(array_filter($data, fn($r) => $r->severidad === 'INFO')),
            'total_rows_affected' => array_sum(array_map(fn($r) => intval($r->conteo ?? 0), $data)),
        ];

        return view('reports.sales.diagnostics', [
            'date' => $date,
            'data' => array_values($filteredData),
            'allData' => $data,
            'summary' => $summary,
            'severityFilter' => $severityFilter,
            'active' => 'reportes'
        ]);
    }
}
