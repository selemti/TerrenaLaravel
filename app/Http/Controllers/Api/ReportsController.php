<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;
use Carbon\Carbon;

class ReportsController extends Controller
{
    private function materializedCoversRange(string $table, string $dateColumn, string $desde, string $hasta): bool
    {
        $stats = DB::table($table)
            ->selectRaw("MIN({$dateColumn}) AS min_fecha, MAX({$dateColumn}) AS max_fecha")
            ->first();

        if (!$stats || !$stats->min_fecha || !$stats->max_fecha) {
            return false;
        }

        $min = Carbon::parse($stats->min_fecha)->toDateString();
        $max = Carbon::parse($stats->max_fecha)->toDateString();

        return $min <= $desde && $max >= $hasta;
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
        $rows = DB::table('selemti.vw_dashboard_resumen_sucursal')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('sucursal_id')
            ->get();
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function kpisTerminalDia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::table('selemti.vw_dashboard_resumen_terminal')
            ->whereBetween('fecha', [$desde, $hasta])
            ->orderBy('fecha')
            ->orderBy('terminal_id')
            ->get();
        return response()->json(['ok' => true, 'desde' => $desde, 'hasta' => $hasta, 'data' => $rows]);
    }

    public function ventasFamilia(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $rows = DB::table('selemti.vw_dashboard_ventas_categorias')
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
        $rows = DB::table('selemti.vw_dashboard_ventas_hora')
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

        $rows = DB::table('public.ticket_item as ti')
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

        $rows = DB::table('selemti.vw_dashboard_resumen_sucursal')
            ->select('fecha', DB::raw('SUM(venta_total) AS venta_total'), DB::raw('SUM(tickets) AS tickets'))
            ->whereBetween('fecha', [$desde, $hasta])
            ->groupBy('fecha')
            ->orderBy('fecha')
            ->get();

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
        $rows = DB::select("SELECT * FROM selemti.vw_consumo_vs_movimientos WHERE fecha BETWEEN ? AND ? ORDER BY fecha DESC, sucursal_id", [$desde, $hasta]);
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
        $start = Carbon::parse($desde, config('app.timezone'))->startOfDay();
        $end = Carbon::parse($hasta, config('app.timezone'))->endOfDay();

        $totals = DB::table('public.ticket as t')
            ->selectRaw("
                COUNT(DISTINCT t.id) AS tickets,
                SUM(COALESCE(t.total_price, 0)) AS venta_total
            ")
            ->whereBetween('t.closing_date', [$start, $end])
            ->where('t.paid', true)
            ->where('t.voided', false)
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
        $start = Carbon::parse($desde, config('app.timezone'))->startOfDay();
        $end = Carbon::parse($hasta, config('app.timezone'))->endOfDay();

        $tot = DB::table('public.ticket_item as ti')
            ->selectRaw("
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
            ->whereBetween('t.closing_date', [$start, $end])
            ->where('t.paid', true)
            ->where('t.voided', false)
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

        if ($this->materializedCoversRange('selemti.mv_dashboard_formas_pago', 'fecha', $desde, $hasta)) {
            $rows = DB::table('selemti.mv_dashboard_formas_pago')
                ->select('codigo_fp', DB::raw('SUM(monto) AS monto'))
                ->whereBetween('fecha', [$desde, $hasta])
                ->groupBy('codigo_fp')
                ->orderByDesc(DB::raw('SUM(monto)'))
                ->get();
        } else {
            $rows = collect(DB::select(<<<SQL
                SELECT
                    COALESCE(
                        fp.codigo,
                        selemti.fn_normalizar_forma_pago(
                            t.payment_type,
                            t.transaction_type,
                            t.payment_sub_type,
                            t.custom_payment_name
                        )
                    ) AS codigo_fp,
                    SUM(t.amount)::numeric(12,2) AS monto
                FROM public.transactions t
                INNER JOIN selemti.sesion_cajon s
                    ON t.transaction_time >= s.apertura_ts
                   AND t.transaction_time < COALESCE(s.cierre_ts, now())
                   AND t.terminal_id = s.terminal_id
                   AND t.user_id = s.cajero_usuario_id
                LEFT JOIN selemti.formas_pago fp
                    ON fp.payment_type = t.payment_type
                   AND COALESCE(fp.transaction_type, '') = COALESCE(t.transaction_type, '')
                   AND COALESCE(fp.payment_sub_type, '') = COALESCE(t.payment_sub_type, '')
                   AND COALESCE(fp.custom_name, '') = COALESCE(t.custom_payment_name, '')
                   AND COALESCE(fp.custom_ref, '') = COALESCE(t.custom_payment_ref, '')
                WHERE t.transaction_time::date BETWEEN ? AND ?
                GROUP BY codigo_fp
                ORDER BY SUM(t.amount) DESC
            SQL, [$desde, $hasta]));
        }

        return response()->json(['ok'=>true,'desde'=>$desde,'hasta'=>$hasta,'data'=>$rows]);
    }

    public function ordenesRecientes(Request $request)
    {
        [$desde, $hasta] = $this->range($request);
        $limit = (int) $request->query('limit', 10);
        $limit = max(1, min($limit, 50));

        $start = Carbon::parse($desde, config('app.timezone'))->startOfDay();
        $end = Carbon::parse($hasta, config('app.timezone'))->endOfDay();

        $rows = DB::table('public.ticket as t')
            ->leftJoin('public.terminal as term', 'term.id', '=', 't.terminal_id')
            ->selectRaw("
                COALESCE(
                    NULLIF(t.daily_folio::text, ''),
                    NULLIF(t.global_id::text, ''),
                    (row_to_json(t)->>'ticket_number'),
                    (row_to_json(t)->>'ticket'),
                    t.id::text
                ) AS ticket,
                t.closing_date,
                COALESCE(
                    term.location,
                    (row_to_json(t)->>'location'),
                    (row_to_json(t)->>'branch_key'),
                    ''
                ) AS location,
                COALESCE(term.name, '') AS terminal_name,
                COALESCE(term.id, t.terminal_id) AS terminal_id,
                COALESCE(t.total_price, 0) AS total
            ")
            ->whereBetween('t.closing_date', [$start, $end])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->orderByDesc('t.closing_date')
            ->limit($limit)
            ->get()
            ->map(function ($row) {
                $fecha = Carbon::parse($row->closing_date);
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
