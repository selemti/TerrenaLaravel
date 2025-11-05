<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class SalesBalanceController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $total = $rows->sum(fn ($r) => (float)($r->monto ?? 0));
        $payments = $rows
            ->groupBy(fn ($r) => (string)($r->payment ?? ''))
            ->map(fn (Collection $g) => $this->round((float)$g->sum(fn ($r) => (float)($r->monto ?? 0))))
            ->toArray();

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $branch,
            'terminal' => $terminal,
            'total' => $this->round($total),
            'by_payment' => $payments,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        return view('reports.sales.balance', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'rows' => $rows,
            'generatedAt' => now('America/Mexico_City'),
        ]);
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
            $sql = "SELECT * FROM public.vw_report_balance_detail WHERE folio_date BETWEEN ? AND ?";
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
            WITH paid AS (
              SELECT
                t.id AS ticket_id,
                selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) AS pay_norm,
                ROUND(SUM(CASE
                  WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
                       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
                  THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric,2) AS paid_amount
              FROM public.ticket t
              LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
              GROUP BY 1,2
            )
            SELECT b.folio_date, b.branch_key, p.pay_norm AS payment, ROUND(SUM(COALESCE(p.paid_amount,0)),2) AS monto
            FROM public.vw_ticket_base b
            LEFT JOIN paid p ON p.ticket_id = b.ticket_id
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
        $sql .= " GROUP BY 1,2,3 ORDER BY 1,2,4 DESC";
        return collect(DB::connection('pgsql')->select($sql, $bindings));
    }
}
