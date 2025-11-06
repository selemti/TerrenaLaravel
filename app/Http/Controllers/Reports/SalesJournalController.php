<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesJournalController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branches, $terminals);

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'filters' => [
                'branches' => $branches,
                'terminals' => $terminals,
            ],
            'lines' => $lines->values(),
            'payments' => $payments->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branches, $terminals);

        $observedBranches = $lines
            ->pluck('branch_key')
            ->merge($payments->pluck('branch_key'))
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);
        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $terminals, $branches);

        return view('reports.sales.journal', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'lines' => $lines,
            'payments' => $payments,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branches, $terminals);

        $filename = sprintf(
            'reporte_journal_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            !empty($branches)
                ? '_' . str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return $this->renderPdf('reports.exports.sales.journal', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($branches),
            'terminal' => $this->stringifyFilter($terminals),
            'lines' => $lines,
            'payments' => $payments,
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

    protected function fetch(Carbon $start, Carbon $end, array $branches, array $terminals): array
    {
        $lSql = "SELECT * FROM public.vw_report_journal_lines WHERE folio_date BETWEEN ? AND ?";
        $pSql = "SELECT * FROM public.vw_report_journal_payments WHERE folio_date BETWEEN ? AND ?";
        $bindingsL = [$start->toDateString(), $end->toDateString()];
        $bindingsP = [$start->toDateString(), $end->toDateString()];

        $branchList = $this->stringifyFilter($branches);
        $terminalList = $this->stringifyFilter($terminals);

        if ($branchList) {
            $lSql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindingsL[] = $branchList;
            $pSql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindingsP[] = $branchList;
        }

        if ($terminalList) {
            $lSql .= " AND EXISTS (SELECT 1 FROM public.ticket t WHERE t.id = vw_report_journal_lines.ticket_id AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ','))))";
            $bindingsL[] = $terminalList;
            $pSql .= " AND EXISTS (SELECT 1 FROM public.ticket t WHERE t.id = vw_report_journal_payments.ticket_id AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ','))))";
            $bindingsP[] = $terminalList;
        }

        $lines = collect(DB::connection('pgsql')->select($lSql, $bindingsL));
        $payments = collect(DB::connection('pgsql')->select($pSql, $bindingsP));
        return [$lines, $payments];
    }
}
