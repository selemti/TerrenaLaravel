<?php

namespace App\Http\Controllers\Reports\Sales;

use App\Http\Controllers\Reports\BaseReportController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SalesModsController extends BaseReportController
{
    /**
     * API: Obtener reporte de ítems + modificadores en JSON
     */
    public function index(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_item_mods_on(?)', [$date->format('Y-m-d')]);

        return response()->json([
            'success' => true,
            'date' => $date->format('Y-m-d'),
            'data' => $data,
            'summary' => [
                'total_items' => count(array_unique(array_map(fn($r) => $r->item_name, $data))),
                'total_modifiers' => count(array_unique(array_map(fn($r) => $r->modifier_name, $data))),
                'total_combinations' => count($data),
                'total_amount' => array_sum(array_map(fn($r) => floatval($r->total_mods_amount ?? 0), $data)),
                'total_selections' => array_sum(array_map(fn($r) => intval($r->times_selected ?? 0), $data)),
            ]
        ], 200, [], JSON_PRETTY_PRINT);
    }

    /**
     * WEB: Mostrar vista del reporte de ítems + modificadores
     */
    public function show(Request $request)
    {
        $this->configureReportConnection();

        $date = $request->input('date')
            ? Carbon::parse($request->input('date'))
            : Carbon::now();

        $data = DB::connection('pgsql')
            ->select('SELECT * FROM public.f_item_mods_on(?)', [$date->format('Y-m-d')]);

        // Calcular resumen
        $uniqueItems = array_unique(array_map(fn($r) => $r->item_name, $data));
        $uniqueModifiers = array_unique(array_map(fn($r) => $r->modifier_name, $data));

        $summary = [
            'total_items' => count($uniqueItems),
            'total_modifiers' => count($uniqueModifiers),
            'total_combinations' => count($data),
            'total_amount' => round(array_sum(array_map(fn($r) => floatval($r->total_mods_amount ?? 0), $data)), 2),
            'total_selections' => array_sum(array_map(fn($r) => intval($r->times_selected ?? 0), $data)),
            'avg_amount_per_selection' => count($data) > 0 
                ? round(array_sum(array_map(fn($r) => floatval($r->total_mods_amount ?? 0), $data)) / 
                        array_sum(array_map(fn($r) => intval($r->times_selected ?? 1), $data)), 2)
                : 0,
        ];

        return view('reports.sales.mods', [
            'date' => $date,
            'data' => $data,
            'summary' => $summary,
            'active' => 'reportes'
        ]);
    }
}
