<?php

namespace App\Http\Controllers\Reports\Sales;

use App\Http\Controllers\Reports\BaseReportController;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * Controlador de Mix de Ventas (Formas de Pago)
 * Endpoint prioritario para cortes de caja
 */
class SalesMixController extends BaseReportController
{
    /**
     * Tags de cache
     */
    protected function getCacheTags(): array
    {
        return ['reports', 'sales', 'sales-mix'];
    }

    /**
     * GET /api/reports/sales/mix
     * 
     * Obtiene el mix de ventas por forma de pago para una fecha
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        $date = $this->parseDate($request);
        
        $cacheKey = "sales-mix:{$date->format('Y-m-d')}";
        
        $data = $this->getCached($cacheKey, function() use ($date) {
            return DB::connection('pgsql')->select(
                'SELECT * FROM public.f_sales_mix_payment_on(?)',
                [$date->format('Y-m-d')]
            );
        });

        // Calcular totales
        $totals = [
            'total_general' => 0,
            'by_payment' => [],
            'by_branch' => []
        ];

        foreach ($data as $row) {
            $amount = (float) $row->total;
            $totals['total_general'] += $amount;

            // Por forma de pago
            if (!isset($totals['by_payment'][$row->normalized_payment])) {
                $totals['by_payment'][$row->normalized_payment] = 0;
            }
            $totals['by_payment'][$row->normalized_payment] += $amount;

            // Por sucursal
            if (!isset($totals['by_branch'][$row->branch_key])) {
                $totals['by_branch'][$row->branch_key] = 0;
            }
            $totals['by_branch'][$row->branch_key] += $amount;
        }

        // Redondear totales
        $totals['total_general'] = $this->round($totals['total_general']);
        foreach ($totals['by_payment'] as $key => $value) {
            $totals['by_payment'][$key] = $this->round($value);
        }
        foreach ($totals['by_branch'] as $key => $value) {
            $totals['by_branch'][$key] = $this->round($value);
        }

        return response()->json([
            'success' => true,
            'date' => $date->format('Y-m-d'),
            'data' => $data,
            'summary' => $totals,
            'generated_at' => now()->toIso8601String()
        ]);
    }

    /**
     * GET /api/reports/sales/mix/today
     * 
     * Mix de ventas del día actual (vista materializada)
     * 
     * @return JsonResponse
     */
    public function today(): JsonResponse
    {
        $cacheKey = "sales-mix:today:" . now()->format('Y-m-d-H');
        
        $data = $this->getCached($cacheKey, function() {
            return DB::connection('pgsql')->select(
                'SELECT * FROM public.vw_sales_mix_payment_today'
            );
        }, 5); // Cache de 5 minutos para día actual

        // Calcular resumen
        $summary = [
            'total' => 0,
            'payments' => []
        ];

        foreach ($data as $row) {
            $amount = (float) $row->total;
            $summary['total'] += $amount;
            
            if (!isset($summary['payments'][$row->normalized_payment])) {
                $summary['payments'][$row->normalized_payment] = [
                    'amount' => 0,
                    'count' => 0
                ];
            }
            
            $summary['payments'][$row->normalized_payment]['amount'] += $amount;
            $summary['payments'][$row->normalized_payment]['count']++;
        }

        $summary['total'] = $this->round($summary['total']);
        foreach ($summary['payments'] as $key => $value) {
            $summary['payments'][$key]['amount'] = $this->round($value['amount']);
            $summary['payments'][$key]['percentage'] = $summary['total'] > 0 
                ? $this->round(($value['amount'] / $summary['total']) * 100) 
                : 0;
        }

        return response()->json([
            'success' => true,
            'date' => now()->format('Y-m-d'),
            'data' => $data,
            'summary' => $summary,
            'generated_at' => now()->toIso8601String()
        ]);
    }
}
