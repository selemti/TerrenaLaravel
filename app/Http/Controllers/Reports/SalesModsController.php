<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesModsExport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SalesModsController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branch);
        $summary = $this->summarize($dataset);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'branch' => $branch,
            'summary' => $summary,
            'data' => $dataset->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $branches = $this->extractBranches($dataset);
        $filtered = $this->applyBranchFilter($dataset, $branch);
        $summary = $this->summarize($filtered);

        return view('reports.sales.mods', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'branches' => $branches,
            'rows' => $filtered,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branch);
        $summary = $this->summarize($dataset);

        $export = new SalesModsExport($start, $end, $dataset, $summary, $branch);
        $filename = sprintf(
            'reporte_items_mods_%s_%s%s.xlsx',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return Excel::download($export, $filename);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branch);
        $summary = $this->summarize($dataset);

        $filename = sprintf(
            'reporte_items_mods_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return $this->renderPdf('reports.exports.sales.mods', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);
        $branch = $this->parseBranch($request);

        return [$start, $end, $branch];
    }

    protected function fetchData(Carbon $start, Carbon $end): Collection
    {
        $rows = DB::connection('pgsql')->select(
            <<<SQL
            SELECT gs.day::date AS report_date, f.*
            FROM generate_series(?::date, ?::date, interval '1 day') AS gs(day)
            CROSS JOIN LATERAL public.f_item_mods_on(gs.day::date) AS f
            SQL,
            [$start->format('Y-m-d'), $end->format('Y-m-d')]
        );

        return collect($rows);
    }

    protected function applyBranchFilter(Collection $rows, ?string $branch): Collection
    {
        if (!$branch) {
            return $rows->values();
        }

        $normalized = strtoupper($branch);

        return $rows
            ->filter(function (object $row) use ($normalized) {
                $value = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->sucursal ?? ''));
                return $value === $normalized;
            })
            ->values();
    }

    protected function summarize(Collection $rows): array
    {
        $uniqueItems = $rows->pluck('item_name')->filter()->unique()->count();
        $uniqueModifiers = $rows->pluck('modifier_name')->filter()->unique()->count();
        $totalCombinations = $rows->count();

        $totalAmount = $rows->sum(fn (object $row) => (float) ($row->mods_total_amount ?? 0));
        $totalSelections = $rows->sum(fn (object $row) => (int) ($row->mods_count ?? 0));

        $avgAmountPerSelection = $totalSelections > 0
            ? $this->round($totalAmount / $totalSelections)
            : 0.0;

        $topModifiers = $rows
            ->groupBy(fn (object $row) => $row->modifier_name ?? 'Sin nombre')
            ->map(function (Collection $items, string $name) {
                return [
                    'modifier' => $name,
                    'times_selected' => $items->sum(fn (object $row) => (int) ($row->mods_count ?? 0)),
                    'amount' => $this->round($items->sum(fn (object $row) => (float) ($row->mods_total_amount ?? 0))),
                ];
            })
            ->filter(fn (array $row) => $row['times_selected'] > 0 || $row['amount'] > 0)
            ->sortByDesc('amount')
            ->take(5)
            ->values()
            ->toArray();

        return [
            'total_items' => $uniqueItems,
            'total_modifiers' => $uniqueModifiers,
            'total_combinations' => $totalCombinations,
            'total_amount' => $this->round($totalAmount),
            'total_selections' => $totalSelections,
            'avg_amount_per_selection' => $avgAmountPerSelection,
            'top_modifiers' => $topModifiers,
            'days' => $rows->pluck('report_date')->filter()->unique()->sort()->values()->all(),
        ];
    }

    protected function extractBranches(Collection $rows): Collection
    {
        return $rows
            ->map(function (object $row) {
                $key = $row->branch_key ?? $row->branch ?? $row->sucursal ?? null;
                $label = $row->branch_name ?? $row->branch ?? $row->sucursal ?? $row->branch_key ?? null;

                if ($key === null) {
                    return null;
                }

                return [
                    'key' => strtoupper((string) $key),
                    'label' => $label !== null ? (string) $label : strtoupper((string) $key),
                ];
            })
            ->filter()
            ->unique('key')
            ->sortBy('label')
            ->values();
    }
}
