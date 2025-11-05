<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesSummaryController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $totals = [
            'tickets' => (int) $rows->sum(fn ($r) => (int)($r->tickets ?? 0)),
            'bruto' => $this->round((float) $rows->sum(fn ($r) => (float)($r->bruto ?? 0))),
            'descuento' => $this->round((float) $rows->sum(fn ($r) => (float)($r->descuento ?? 0))),
            'neto' => $this->round((float) $rows->sum(fn ($r) => (float)($r->neto ?? 0))),
        ];

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $branch,
            'terminal' => $terminal,
            'totals' => $totals,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        return view('reports.sales.summary', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'rows' => $rows,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $filename = sprintf(
            'reporte_resumen_ventas_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return $this->renderPdf('reports.exports.sales.summary', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'rows' => $rows,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        $start = $request->input('start') ?? $request->input('start_date');
        $end = $request->input('end') ?? $request->input('end_date');
        $start = $start ? Carbon::parse($start, 'America/Mexico_City') : now('America/Mexico_City')->startOfDay();
        $end = $end ? Carbon::parse($end, 'America/Mexico_City') : $start->copy();
        if ($end->lt($start)) [$start, $end] = [$end, $start];
        $start = $start->startOfDay();
        $end = $end->startOfDay();

        $branch = trim((string) $request->input('branch', ''));
        $branch = $branch !== '' ? strtoupper($branch) : null;
        $terminal = trim((string) $request->input('terminal', ''));
        $terminal = $terminal !== '' ? $terminal : null;

        return [$start, $end, $branch, $terminal];
    }

    protected function fetch(Carbon $start, Carbon $end, ?string $branch, ?string $terminal): Collection
    {
        if (!$terminal) {
            $sql = "SELECT * FROM public.vw_report_sales_summary WHERE folio_date BETWEEN ? AND ?";
            $bindings = [$start->toDateString(), $end->toDateString()];
            if ($branch) {
                if (str_contains($branch, ',')) {
                    $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
                } else {
                    $sql .= " AND UPPER(branch_key) = ?";
                }
                $bindings[] = $branch;
            }
            return collect(DB::connection('pgsql')->select($sql, $bindings));
        }

        $sql = <<<SQL
            SELECT
              b.folio_date,
              b.branch_key,
              COUNT(DISTINCT b.ticket_id) AS tickets,
              ROUND(SUM(b.total_price),2) AS bruto,
              ROUND(SUM(b.total_discount),2) AS descuento,
              ROUND(SUM(b.total_price - b.total_discount),2) AS neto,
              ROUND(SUM(b.tip_amount),2) AS propina,
              ROUND(SUM(b.service_charges),2) AS cargo_servicio
            FROM public.vw_ticket_base b
            WHERE b.folio_date BETWEEN ? AND ?
              AND CAST(b.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))
        SQL;
        $bindings = [$start->toDateString(), $end->toDateString(), $terminal];
        if ($branch) {
            if (str_contains($branch, ',')) {
                $sql .= " AND UPPER(b.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            } else {
                $sql .= " AND UPPER(b.branch_key) = ?";
            }
            $bindings[] = $branch;
        }
        $sql .= " GROUP BY 1,2";
        return collect(DB::connection('pgsql')->select($sql, $bindings));
    }
}
