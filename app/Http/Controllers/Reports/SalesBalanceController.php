<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesBalanceController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $total = $rows->sum(fn ($r) => (float) ($r->monto ?? 0));
        $payments = $rows
            ->groupBy(fn ($r) => (string) ($r->payment ?? ''))
            ->map(fn (Collection $g) => $this->round((float) $g->sum(fn ($r) => (float) ($r->monto ?? 0))))
            ->toArray();

        $observedBranches = $rows
            ->map(fn ($row) => $row->branch_key ?? $row->branch ?? null)
            ->filter()
            ->all();

        [$branchColors] = $this->buildBranchContext($observedBranches, $branches);

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'filters' => [
                'branches' => $branches,
                'terminals' => $terminals,
            ],
            'branch_colors' => $branchColors,
            'total' => $this->round($total),
            'by_payment' => $payments,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);
        $pivot = $this->buildPivot($rows);

        $observedBranches = $rows
            ->map(fn ($row) => $row->branch_key ?? $row->branch ?? null)
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);
        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $terminals, $branches);

        return view('reports.sales.balance', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $rows,
            'pivotRows' => $pivot,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);
        $pivot = $this->buildPivot($rows);

        $filename = sprintf(
            'reporte_balance_formas_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            !empty($branches)
                ? '_' . str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return $this->renderPdf('reports.exports.sales.balance', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'rows' => $rows,
            'pivotRows' => $pivot,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        $startInput = $request->input('start') ?? $request->input('start_date');
        $endInput = $request->input('end') ?? $request->input('end_date');

        $start = $startInput
            ? Carbon::parse($startInput, 'America/Mexico_City')
            : now('America/Mexico_City')->startOfDay();
        $end = $endInput
            ? Carbon::parse($endInput, 'America/Mexico_City')
            : $start->copy();

        if ($end->lt($start)) {
            [$start, $end] = [$end, $start];
        }

        $start = $start->startOfDay();
        $end = $end->startOfDay();

        $branches = $this->normalizeFilterList($request->input('branch'), uppercase: true);
        $terminals = $this->normalizeFilterList($request->input('terminal'), uppercase: false);

        return [$start, $end, $branches, $terminals];
    }

    protected function fetch(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        $branchList = $this->stringifyFilter($branches);
        $terminalList = $this->stringifyFilter($terminals);

        if (!$terminalList) {
            $sql = "SELECT * FROM public.vw_report_balance_detail WHERE folio_date BETWEEN ? AND ?";
            $bindings = [$start->toDateString(), $end->toDateString()];
            if ($branchList) {
                $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
                $bindings[] = $branchList;
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
        $bindings = [$start->toDateString(), $end->toDateString(), $terminalList];
        if ($branchList) {
            $sql .= " AND UPPER(b.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = $branchList;
        }
        $sql .= " GROUP BY 1,2,3 ORDER BY 1,2,4 DESC";
        return collect(DB::connection('pgsql')->select($sql, $bindings));
    }

    protected function buildPivot(Collection $rows): array
    {
        $grouped = $rows->groupBy(function ($r) {
            $date = (string)($r->folio_date ?? '');
            $branch = strtoupper((string)($r->branch_key ?? ''));
            return $date.'|'.$branch;
        });

        $result = [];
        foreach ($grouped as $key => $items) {
            [$date, $branch] = explode('|', $key, 2);
            $cash=0.0; $credit=0.0; $debit=0.0; $other=0.0; $net=0.0;
            foreach ($items as $r) {
                $amount = (float)($r->monto ?? 0);
                $method = strtoupper((string)($r->payment ?? ''));
                switch ($method) {
                    case 'CASH': $cash += $amount; break;
                    case 'CREDIT_CARD': $credit += $amount; break;
                    case 'DEBIT_CARD': $debit += $amount; break;
                    default: $other += $amount; break;
                }
                $net += $amount;
            }
            $result[] = [
                'folio_date' => $date,
                'branch_key' => $branch,
                'cash' => $this->round($cash),
                'credit' => $this->round($credit),
                'debit' => $this->round($debit),
                'other' => $this->round($other),
                'net' => $this->round($net),
            ];
        }
        usort($result, fn($a,$b) => strcmp($a['folio_date'] ?? '', $b['folio_date'] ?? '') ?: strcmp($a['branch_key'] ?? '', $b['branch_key'] ?? ''));
        return $result;
    }
}
