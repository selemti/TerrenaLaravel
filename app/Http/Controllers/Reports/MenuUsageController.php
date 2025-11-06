<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class MenuUsageController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $summary = [
            'unique_items' => $rows->pluck('item_name')->filter()->unique()->count(),
            'total_qty' => (float) $rows->sum(fn ($r) => (float) ($r->qty ?? 0)),
            'total_neto' => $this->round((float) $rows->sum(fn ($r) => (float) ($r->neto ?? 0))),
        ];

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
            'summary' => $summary,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $observedBranches = $rows
            ->map(fn ($row) => $row->branch_key ?? $row->branch ?? null)
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);
        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $terminals, $branches);

        return view('reports.menu.usage', [
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
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $filename = sprintf(
            'reporte_uso_menu_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            !empty($branches)
                ? '_' . str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return $this->renderPdf('reports.exports.menu.usage', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'rows' => $rows,
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

        $branchParam = $request->input('branch');
        $terminalParam = $request->input('terminal');

        $branches = $this->normalizeFilterList($branchParam, uppercase: true);
        $terminals = $this->normalizeFilterList($terminalParam, uppercase: false);

        return [$start, $end, $branches, $terminals];
    }

    protected function fetch(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        $branchList = $this->stringifyFilter($branches);
        $terminalList = $this->stringifyFilter($terminals);

        if (!$terminalList) {
            $sql = "SELECT * FROM public.vw_report_menu_usage WHERE folio_date BETWEEN ? AND ?";
            $bindings = [$start->toDateString(), $end->toDateString()];
            if ($branchList) {
                $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
                $bindings[] = $branchList;
            }
            return collect(DB::connection('pgsql')->select($sql, $bindings));
        }

        $sql = <<<SQL
            SELECT b.folio_date, b.branch_key, ti.item_name::text AS item_name,
                   SUM(COALESCE(ti.item_quantity,0))::numeric(12,2) AS qty,
                   ROUND(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount_amount,0)),2) AS neto
            FROM public.vw_ticket_base b
            JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id
            WHERE b.folio_date BETWEEN ? AND ?
              AND CAST(b.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))
        SQL;
        $bindings = [$start->toDateString(), $end->toDateString(), $terminalList];
        if ($branchList) {
            $sql .= " AND UPPER(b.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = $branchList;
        }
        $sql .= " GROUP BY 1,2,3";
        return collect(DB::connection('pgsql')->select($sql, $bindings));
    }
}
