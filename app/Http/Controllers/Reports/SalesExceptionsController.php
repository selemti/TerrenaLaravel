<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesExceptionsController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $summary = [
            'total' => $rows->count(),
            'by_code' => $rows->groupBy(fn ($r) => (string)($r->error_code ?? ''))
                ->map->count()
                ->toArray(),
        ];

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $branch,
            'terminal' => $terminal,
            'summary' => $summary,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        return view('reports.sales.exceptions', [
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
            'reporte_excepciones_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return $this->renderPdf('reports.exports.sales.exceptions', [
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
        $sql = "SELECT e.* FROM public.vw_report_sales_exceptions e WHERE e.folio_date BETWEEN ? AND ?";
        $bindings = [$start->toDateString(), $end->toDateString()];

        if ($branch) {
            if (str_contains($branch, ',')) {
                $sql .= " AND UPPER(e.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            } else {
                $sql .= " AND UPPER(e.branch_key) = ?";
            }
            $bindings[] = $branch;
        }

        if ($terminal) {
            $sql .= " AND EXISTS (SELECT 1 FROM public.ticket t WHERE t.id = e.ticket_id AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ','))))";
            $bindings[] = $terminal;
        }

        try {
            $rows = DB::connection('pgsql')->select($sql, $bindings);
            return collect($rows);
        } catch (\Illuminate\Database\QueryException $qe) {
            $msg = $qe->getMessage();
            if (stripos($msg, 'vw_report_sales_exceptions') === false) {
                throw $qe;
            }

            // Fallback: construir excepciones sin la vista, usando vw_ticket_base + transactions
            $baseSql = [];
            $baseBindings = [];

            $baseSql[] = "WITH base AS (";
            $baseSql[] = "  SELECT b.folio_date, b.branch_key, b.ticket_id, (b.total_price - b.total_discount)::numeric(12,2) AS neto";
            $baseSql[] = "  FROM public.vw_ticket_base b";
            $baseSql[] = "  WHERE b.folio_date BETWEEN ? AND ?";
            $baseBindings[] = $start->toDateString();
            $baseBindings[] = $end->toDateString();

            if ($branch) {
                if (str_contains($branch, ',')) {
                    $baseSql[] = "    AND UPPER(b.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
                } else {
                    $baseSql[] = "    AND UPPER(b.branch_key) = ?";
                }
                $baseBindings[] = $branch;
            }

            if ($terminal) {
                $baseSql[] = "    AND CAST(b.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))";
                $baseBindings[] = $terminal;
            }

            $baseSql[] = ")";

            $baseSql[] = ", paid AS (";
            $baseSql[] = "  SELECT t.id AS ticket_id, ROUND(SUM(CASE";
            $baseSql[] = "    WHEN COALESCE(tx.voided, FALSE)=FALSE AND UPPER(tx.transaction_type)='CREDIT' AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')";
            $baseSql[] = "    THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS paid_amount";
            $baseSql[] = "  FROM public.ticket t";
            $baseSql[] = "  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id";
            $baseSql[] = "  GROUP BY t.id";
            $baseSql[] = ")";

            $baseSql[] = ", tot_disc AS (";
            $baseSql[] = "  SELECT b.ticket_id, (b.total_discount)::numeric(12,2) AS total_discount";
            $baseSql[] = "  FROM public.vw_ticket_base b";
            $baseSql[] = ")";

            $unions = [];
            // 1) Neto vs cobros
            $unions[] = "SELECT b.folio_date, b.branch_key, 'PAYMENT_VS_NET_MISMATCH'::text AS error_code, 'WARN'::text AS severity, b.ticket_id, ROUND((b.neto - COALESCE(p.paid_amount,0))::numeric,2) AS diff FROM base b LEFT JOIN paid p ON p.ticket_id = b.ticket_id WHERE ABS((b.neto - COALESCE(p.paid_amount,0))) > 0.01";
            // 2) Descuentos altos
            $unions[] = "SELECT b.folio_date, b.branch_key, 'DISCOUNT_OVER_THRESHOLD'::text AS error_code, 'INFO'::text AS severity, b.ticket_id, td.total_discount AS diff FROM base b JOIN tot_disc td ON td.ticket_id = b.ticket_id WHERE td.total_discount > 100 OR ((b.neto + td.total_discount) > 0 AND td.total_discount / NULLIF((b.neto + td.total_discount),0) > 0.20)";
            // 3) Pagado sin TX
            $unions[] = "SELECT b.folio_date, b.branch_key, 'PAID_WITHOUT_TX'::text AS error_code, 'WARN'::text AS severity, b.ticket_id, b.neto AS diff FROM base b LEFT JOIN paid p ON p.ticket_id = b.ticket_id WHERE COALESCE(p.paid_amount,0) = 0 AND b.neto > 0";

            $finalSql = implode("\n", $baseSql) . "\n" . implode("\nUNION ALL\n", $unions);
            $rows = DB::connection('pgsql')->select($finalSql, $baseBindings);
            return collect($rows);
        }
    }
}
