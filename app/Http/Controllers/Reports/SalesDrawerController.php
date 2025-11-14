<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesDrawerExport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SalesDrawerController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $branches, $severity);
        $summary = $this->summarize($dataset);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'branch' => $this->stringifyFilter($branches),
            'severity' => $severity,
            'filters' => [
                'branches' => $branches,
            ],
            'summary' => $summary,
            'data' => $dataset->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $severity] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $branchCandidates = $this->extractBranches($dataset);
        $filtered = $this->applyFilters($dataset, $branches, $severity);
        $summary = $this->summarize($filtered);

        $observedBranches = $branchCandidates
            ->pluck('key')
            ->merge($filtered->map(fn ($row) => $row->branch_key ?? $row->branch ?? $row->sucursal ?? null))
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);

        return view('reports.sales.drawer', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'severity' => $severity,
            'branchOptions' => $branchOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $filtered,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $branches, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $branches, $severity);
        $summary = $this->summarize($dataset);

        $export = new SalesDrawerExport($start, $end, $dataset, $summary, $this->stringifyFilter($branches), $severity);
        $filename = sprintf(
            'reporte_cajon_vs_efectivo_%s_%s%s.xlsx',
            $start->format('Ymd'),
            $end->format('Ymd'),
            ! empty($branches)
                ? '_'.str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return Excel::download($export, $filename);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $branches, $severity);
        $summary = $this->summarize($dataset);

        $filename = sprintf(
            'reporte_cajon_vs_efectivo_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            ! empty($branches)
                ? '_'.str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return $this->renderPdf('reports.exports.sales.drawer', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($branches),
            'severity' => $severity,
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);
        $branches = $this->normalizeFilterList($request->input('branch'), uppercase: true);
        $severity = $this->parseEnum($request, 'severity');

        return [$start, $end, $branches, $severity];
    }

    protected function fetchData(Carbon $start, Carbon $end): Collection
    {
        $rows = DB::connection('pgsql')->select(
            <<<'SQL'
            SELECT gs.day::date AS report_date, f.*
            FROM generate_series(?::date, ?::date, interval '1 day') AS gs(day)
            CROSS JOIN LATERAL public.f_diag_drawer_vs_cash_transactions_on(gs.day::date) AS f
            SQL,
            [$start->format('Y-m-d'), $end->format('Y-m-d')]
        );

        return collect($rows);
    }

    protected function applyFilters(Collection $rows, array $branches, ?string $severity): Collection
    {
        if (! empty($branches)) {
            $normalized = collect($branches)
                ->map(fn ($value) => strtoupper(trim((string) $value)))
                ->filter()
                ->unique()
                ->values()
                ->all();

            $rows = $rows->filter(function (object $row) use ($normalized) {
                $value = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->sucursal ?? ''));

                return in_array($value, $normalized, true);
            });
        }

        if ($severity) {
            $rows = $rows->filter(function (object $row) use ($severity) {
                return strtoupper((string) ($row->severidad ?? '')) === $severity;
            });
        }

        return $rows->values();
    }

    protected function summarize(Collection $rows): array
    {
        $totalExpected = $rows->sum(fn (object $row) => (float) ($row->efectivo_esperado ?? 0));
        $totalRegistered = $rows->sum(fn (object $row) => (float) ($row->efectivo_registrado ?? 0));
        $totalDifference = $rows->sum(fn (object $row) => (float) ($row->diferencia ?? 0));

        $severityCounts = [
            'CRITICAL' => 0,
            'WARN' => 0,
            'INFO' => 0,
        ];

        foreach ($rows as $row) {
            $severity = strtoupper((string) ($row->severidad ?? 'INFO'));
            if (array_key_exists($severity, $severityCounts)) {
                $severityCounts[$severity]++;
            }
        }

        $branches = $rows
            ->groupBy(fn (object $row) => strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->sucursal ?? 'SIN_SUCURSAL')))
            ->map(function (Collection $items, string $key) {
                $first = $items->first();
                $label = $first?->branch_name
                    ?? $first?->branch
                    ?? $first?->sucursal
                    ?? $key;

                $label = $label !== null ? (string) $label : $key;

                $expected = $items->sum(fn (object $row) => (float) ($row->efectivo_esperado ?? 0));
                $registered = $items->sum(fn (object $row) => (float) ($row->efectivo_registrado ?? 0));
                $difference = $items->sum(fn (object $row) => (float) ($row->diferencia ?? 0));

                return [
                    'key' => $key,
                    'label' => $label,
                    'expected' => $this->round($expected),
                    'registered' => $this->round($registered),
                    'difference' => $this->round($difference),
                ];
            })
            ->values()
            ->toArray();

        $discrepancies = $rows->filter(function (object $row) {
            return abs((float) ($row->diferencia ?? 0)) > 0.0099;
        })->count();

        return [
            'total_terminals' => $rows->count(),
            'discrepancies_count' => $discrepancies,
            'total_expected' => $this->round($totalExpected),
            'total_registered' => $this->round($totalRegistered),
            'total_difference' => $this->round($totalDifference),
            'critical_count' => $severityCounts['CRITICAL'],
            'warning_count' => $severityCounts['WARN'],
            'info_count' => $severityCounts['INFO'],
            'branches' => $branches,
            'days' => $rows->pluck('report_date')->filter()->unique()->sort()->values()->all(),
        ];
    }

    protected function extractBranches(Collection $rows): Collection
    {
        return $rows
            ->map(function (object $row) {
                $key = $row->branch_key ?? $row->branch ?? $row->sucursal ?? null;
                $label = $row->branch_name ?? $row->branch ?? $row->sucursal ?? $row->branch_key ?? null;

                if ($key === null || $label === null) {
                    return null;
                }

                return [
                    'key' => strtoupper((string) $key),
                    'label' => (string) $label,
                ];
            })
            ->filter()
            ->unique('key')
            ->sortBy('label')
            ->values();
    }
}
