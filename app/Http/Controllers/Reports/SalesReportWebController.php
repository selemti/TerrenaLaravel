<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use App\Traits\Reports\ConfiguresReportConnection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Carbon\Carbon;

/**
 * Controlador web para visualización de reportes de ventas
 */
class SalesReportWebController extends Controller
{
    use ConfiguresReportConnection;

    public function __construct()
    {
        $this->middleware('auth');
        $this->configureReportConnection();
    }

    /**
     * Reporte de Mix de Ventas (Formas de Pago)
     */
    public function salesMix(Request $request): View
    {
        $date = $request->input('date') 
            ? Carbon::parse($request->input('date'))->timezone('America/Mexico_City')
            : now()->timezone('America/Mexico_City');

        $data = DB::connection('pgsql')->select(
            'SELECT * FROM public.f_sales_mix_payment_on(?)',
            [$date->format('Y-m-d')]
        );

        // Calcular totales
        $totals = [
            'total_general' => 0,
            'by_payment' => [],
            'by_branch' => []
        ];

        foreach ($data as $row) {
            $amount = (float) $row->total;
            $totals['total_general'] += $amount;

            if (!isset($totals['by_payment'][$row->normalized_payment])) {
                $totals['by_payment'][$row->normalized_payment] = 0;
            }
            $totals['by_payment'][$row->normalized_payment] += $amount;

            if (!isset($totals['by_branch'][$row->branch_key])) {
                $totals['by_branch'][$row->branch_key] = 0;
            }
            $totals['by_branch'][$row->branch_key] += $amount;
        }

        return view('reports.sales.mix', [
            'date' => $date,
            'data' => $data,
            'totals' => $totals,
            'active' => 'reportes'
        ]);
    }
}
