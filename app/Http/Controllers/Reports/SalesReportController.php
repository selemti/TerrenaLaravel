<?php

namespace App\Http\Controllers\Reports;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class SalesReportController extends Controller
{
    public function index(Request $request)
    {
        $fechaDesde = $request->query('fecha_desde');
        $fechaHasta = $request->query('fecha_hasta');

        // Datos para pasar a la vista
        $data = [
            'fecha_desde' => $fechaDesde,
            'fecha_hasta' => $fechaHasta,
        ];

        return view('reports.sales', $data);
    }
}