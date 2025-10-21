<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;

class ReportsController extends Controller
{
    private function range(Request $request): array
    {
        $desde = $request->query('desde');
        $hasta = $request->query('hasta');
        if (!$desde) { $desde = now()->toDateString(); }
        if (!$hasta) { $hasta = $desde; }
        return [$desde, $hasta];
    }

    public function kpisSucursalDia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_kpis_sucursal_dia WHERE fecha BETWEEN DATE ? AND DATE ? ORDER BY fecha, sucursal_id", [$desde, $hasta]);
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function kpisTerminalDia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_kpis_terminal_dia WHERE fecha BETWEEN DATE ? AND DATE ? ORDER BY fecha, terminal_id", [$desde, $hasta]);
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function ventasFamilia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_ventas_por_familia WHERE fecha BETWEEN DATE ? AND DATE ? ORDER BY fecha, familia", [$desde, $hasta]);
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasPorHora(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_ventas_por_hora WHERE hora::date BETWEEN DATE ? AND DATE ? ORDER BY hora", [$desde, $hasta]);
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasTopProductos(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $limit = (int) ($request->query('limit', 5));
        $rows = DB::select(<<<SQL
            SELECT plu, SUM(unidades) AS unidades, SUM(venta_total) AS venta_total
            FROM selemti.vw_ventas_por_item
            WHERE fecha BETWEEN DATE ? AND DATE ?
            GROUP BY plu
            ORDER BY SUM(venta_total) DESC
            LIMIT $limit
        SQL, [$desde, $hasta]);
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasDiarias(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select(<<<SQL
            SELECT fecha,
                   SUM(COALESCE(sistema_efectivo, 0) + COALESCE(sistema_no_efectivo, 0)) AS venta_total
            FROM selemti.vw_kpis_sucursal_dia
            WHERE fecha BETWEEN DATE ? AND DATE ?
            GROUP BY fecha
            ORDER BY fecha
        SQL, [$desde, $hasta]);

        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function stockValorizado()
    {
        $rows = DB::select("SELECT * FROM selemti.vw_stock_valorizado ORDER BY valor DESC");
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function consumoVsMovimientos(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_consumo_vs_movimientos WHERE fecha BETWEEN DATE ? AND DATE ? ORDER BY fecha DESC, sucursal_id", [$desde, $hasta]);
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function anomalos(Request $request)
    {
        $limit = (int) ($request->query('limit', 200));
        $rows = DB::select("SELECT * FROM selemti.vw_movimientos_anomalos ORDER BY ts DESC LIMIT $limit");
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ticketPromedio(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT * FROM selemti.vw_ticket_promedio_sucursal_dia WHERE fecha BETWEEN DATE ? AND DATE ?", [$desde, $hasta]);
        $tickets = 0; $venta = 0.0;
        foreach($rows as $r){ $tickets += (int)($r->tickets ?? 0); $venta += (float)($r->venta_total ?? 0); }
        $avg = $tickets > 0 ? ($venta / $tickets) : 0;
        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'tickets'=>$tickets,'venta_total'=>$venta,'ticket_promedio'=>$avg,'detalle'=>$rows]);
    }

    public function ventasItemsResumen(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT SUM(unidades) AS unidades, SUM(venta_total) AS venta_total FROM selemti.vw_ventas_por_item WHERE fecha BETWEEN DATE ? AND DATE ?", [$desde, $hasta]);
        $tot = $rows[0] ?? (object)['unidades'=>0,'venta_total'=>0];
        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'unidades'=>(int)($tot->unidades ?? 0),'venta_total'=>(float)($tot->venta_total ?? 0)]);
    }

    public function formasPago(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::select("SELECT codigo_fp, SUM(monto) AS monto FROM selemti.vw_sesion_ventas WHERE fecha BETWEEN DATE ? AND DATE ? GROUP BY codigo_fp ORDER BY SUM(monto) DESC", [$desde, $hasta]);
        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'data'=>$rows]);
    }
}
