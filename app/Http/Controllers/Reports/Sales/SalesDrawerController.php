<?php

namespace App\Http\Controllers\Reports\Sales;

use App\Http\Controllers\Reports\BaseReportController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SalesDrawerController extends BaseReportController
{
    /**
     * API: Obtener reporte de Cajón vs Efectivo en JSON
     */
    public function index(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on(?)', [$date->format('Y-m-d')]);

        return response()->json([
            'success' => true,
            'date' => $date->format('Y-m-d'),
            'data' => $data,
            'summary' => [
                'total_discrepancies' => count(array_filter($data, fn($r) => $r->diferencia != 0)),
                'total_terminals' => count($data),
                'critical_count' => count(array_filter($data, fn($r) => $r->severidad === 'CRITICAL')),
                'warning_count' => count(array_filter($data, fn($r) => $r->severidad === 'WARN')),
            ]
        ], 200, [], JSON_PRETTY_PRINT);
    }

    /**
     * WEB: Mostrar vista del reporte Cajón vs Efectivo
     */
    public function show(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on(?)', [$date->format('Y-m-d')]);

        // Calcular resumen
        $summary = [
            'total_terminals' => count($data),
            'total_expected' => array_sum(array_map(fn($r) => floatval($r->efectivo_esperado ?? 0), $data)),
            'total_registered' => array_sum(array_map(fn($r) => floatval($r->efectivo_registrado ?? 0), $data)),
            'total_difference' => array_sum(array_map(fn($r) => floatval($r->diferencia ?? 0), $data)),
            'discrepancies_count' => count(array_filter($data, fn($r) => abs(floatval($r->diferencia ?? 0)) > 0.01)),
            'critical_count' => count(array_filter($data, fn($r) => $r->severidad === 'CRITICAL')),
            'warning_count' => count(array_filter($data, fn($r) => $r->severidad === 'WARN')),
            'ok_count' => count(array_filter($data, fn($r) => $r->severidad === 'INFO')),
        ];

        return view('reports.sales.drawer', [
            'date' => $date,
            'data' => $data,
            'summary' => $summary,
            'active' => 'reportes'
        ]);
    }
}
