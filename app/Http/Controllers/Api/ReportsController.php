<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;
use Carbon\Carbon;
use Illuminate\Database\Connection;

class ReportsController extends Controller
{
    private function materializedCoversRange(string $table, string $dateColumn, string $desde, string $hasta): bool
    {
        $stats = $this->pg()->table($table)
            ->selectRaw("MIN({$dateColumn}) AS min_fecha, MAX({$dateColumn}) AS max_fecha")
            ->first();

        if (!$stats || !$stats->min_fecha || !$stats->max_fecha) {
            return false;
        }

        $min = Carbon::parse($stats->min_fecha)->toDateString();
        $max = Carbon::parse($stats->max_fecha)->toDateString();

        return $min <= $desde && $max >= $hasta;
    }

    private function pg(): Connection
    {
        return DB::connection('pgsql');
    }

    private function range(Request $request): array
    {
        $tz = config('app.timezone');
        $rawDesde = $request->query('desde');
        $rawHasta = $request->query('hasta');

        try {
            $desde = $rawDesde ? Carbon::parse($rawDesde, $tz) : now($tz);
        } catch (\Throwable $e) {
            $desde = now($tz);
        }

        try {
            $hasta = $rawHasta ? Carbon::parse($rawHasta, $tz) : clone $desde;
        } catch (\Throwable $e) {
            $hasta = clone $desde;
        }

        if ($desde->gt($hasta)) {
            [$desde, $hasta] = [$hasta, $desde];
        }

        return [$desde->toDateString(), $hasta->toDateString()];
    }

    public function kpisSucursalDia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_resumen_sucursal')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('sucursal_id')
            ->get();
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function kpisTerminalDia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_resumen_terminal')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('terminal_id')
            ->get();
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function ventasFamilia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_ventas_categorias')
            ->selectRaw('fecha, sucursal_id, categoria AS familia, unidades, venta_total')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('familia')
            ->get();
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasPorHora(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_ventas_hora')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('hora')
            ->get();
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasTopProductos(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $limit = (int) $request->query('limit', 5);
        $limit = max(1, min($limit, 100));

        $start = Carbon::parse($desde, config('app.timezone'))->startOfDay();
        $end = Carbon::parse($hasta, config('app.timezone'))->endOfDay();

        $rows = $this->pg()->table('public.ticket_item as ti')
            ->selectRaw("
                ti.item_id AS plu,
                COALESCE(MAX(NULLIF(ti.item_name, '')), ti.item_id::text) AS descripcion,
                SUM(
                    COALESCE(
                        NULLIF(ti.item_quantity, 0),
                        NULLIF(ti.item_count, 0),
                        0
                    )::numeric
                ) AS unidades,
                SUM(COALESCE(ti.total_price, 0)) AS venta_total
            ")
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereNotNull('ti.item_id')
            ->whereBetween('t.closing_date', [$start, $end])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('ti.item_id')
            ->orderByDesc('venta_total')
            ->limit($limit)
            ->get();

        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ventasDiarias(Request $request)
    {
        [$desde, $hasta] = $this->range($request);

        $rows = $this->pg()->table('selemti.vw_dashboard_resumen_sucursal')
            ->select('fecha', DB::raw('SUM(venta_total) AS venta_total'), DB::raw('SUM(tickets) AS tickets'))
            ->whereBetween('fecha', [$desde, $hasta])
            ->groupBy('fecha')
            ->orderBy('fecha')
            ->get();

        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function stockValorizado()
    {
        $rows = $this->pg()->select("SELECT * FROM selemti.vw_stock_valorizado ORDER BY valor DESC");
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function consumoVsMovimientos(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->select("SELECT * FROM selemti.vw_consumo_vs_movimientos WHERE fecha BETWEEN ? AND ? ORDER BY fecha DESC, sucursal_id", [$desde, $hasta]);
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function anomalos(Request $request)
    {
        $limit = (int) ($request->query('limit', 200));
        $rows = $this->pg()->select("SELECT * FROM selemti.vw_movimientos_anomalos ORDER BY ts DESC LIMIT $limit");
        return response()->json(['ok' => true, 'data' => $rows]);
    }

    public function ticketPromedio(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $totals = $this->pg()->table('selemti.vw_dashboard_ticket_base')
            ->selectRaw('COUNT(DISTINCT ticket_id) AS tickets, SUM(total) AS venta_total')
            ->whereBetween('fecha', [$desde, $hasta])
            ->where('paid', true)
            ->where('voided', false)
            ->first();

        $tickets = (int) ($totals->tickets ?? 0);
        $venta = (float) ($totals->venta_total ?? 0);
        $avg = $tickets > 0 ? ($venta / $tickets) : 0;

        return response()->json([
            'ok' => true,
            'desde' => $desde,
            'hasta' => $hasta,
            'tickets' => $tickets,
            'venta_total' => $venta,
            'ticket_promedio' => $avg
        ]);
    }

    public function ventasItemsResumen(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $tot = $this->pg()->table('selemti.vw_dashboard_ventas_productos')
            ->selectRaw('SUM(unidades) AS unidades, SUM(venta_total) AS venta_total')
            ->whereBetween('fecha', [$desde, $hasta])
            ->first();

        $units = (int) round((float) ($tot->unidades ?? 0));
        $total = (float) ($tot->venta_total ?? 0);

        return response()->json([
            'ok' => true,
            'desde' => $desde,
            'hasta' => $hasta,
            'unidades' => $units,
            'venta_total' => $total
        ]);
    }

    public function formasPago(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $query = $this->pg()->table('selemti.vw_dashboard_formas_pago')
            ->select('codigo_fp', DB::raw('SUM(monto) AS monto'))
            ->whereBetween('fecha', [$desde, $hasta]);

        if ($request->filled('sucursal_id')) {
            $query->where('sucursal_id', $request->query('sucursal_id'));
        }

        $rows = $query
            ->groupBy('codigo_fp')
            ->orderByDesc(DB::raw('SUM(monto)'))
            ->get();

        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'data'=>$rows]);
    }

    public function ventasCategorias(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_ventas_categorias')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('categoria')
            ->get();
        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'data'=>$rows]);
    }

    public function ventasPorSucursal(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = $this->pg()->table('selemti.vw_dashboard_resumen_sucursal')
            ->whereBetween('fecha', [$desde, $hasta])
            ->select('fecha', 'sucursal_id', 'tickets', 'venta_total', 'sub_total')
            ->orderBy('fecha')
            ->orderBy('sucursal_id')
            ->get();
        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'data'=>$rows]);
    }

    public function ordenesRecientes(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $limit = (int) $request->query('limit', 10);
        $limit = max(1, min($limit, 50));

        $rows = $this->pg()->table('selemti.vw_dashboard_ordenes as o')
            ->leftJoin('public.terminal as term', 'term.id', '=', 'o.terminal_id')
            ->whereBetween('o.fecha', [$desde, $hasta])
            ->orderByDesc('o.closing_date')
            ->limit($limit)
            ->get([
                DB::raw("o.ticket_ref AS ticket"),
                DB::raw("o.closing_date AS closing_date"),
                DB::raw("COALESCE(term.location, o.sucursal_id) AS location"),
                DB::raw("COALESCE(term.name, '') AS terminal_name"),
                DB::raw("COALESCE(term.id, o.terminal_id) AS terminal_id"),
                DB::raw("o.total AS total")
            ])
            ->map(function ($row) {
                $fecha = Carbon::parse($row->closing_date, config('app.timezone'));
                return [
                    'ticket' => $row->ticket,
                    'hora' => $fecha->format('H:i'),
                    'fecha' => $fecha->toDateString(),
                    'sucursal' => $row->location ?: 'Sin sucursal',
                    'terminal' => $row->terminal_name ?: ($row->terminal_id ? 'Terminal '.$row->terminal_id : '—'),
                    'total' => (float) $row->total,
                ];
            });

        return response()->json([
            'ok' => true,
            'desde' => $desde,
            'hasta' => $hasta,
            'data' => $rows
        ]);
    }
}
