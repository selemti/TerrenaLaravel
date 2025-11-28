<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesModsExport;
use App\Services\Reports\ItemModsReportService;
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
    public function __construct(
        protected ItemModsReportService $service
    ) {
        parent::__construct();
    }

    public function index(Request $request): JsonResponse
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        // Usar nuevo servicio si se especifica una vista, caso contrario usar legacy
        if (isset($filters['view']) && $filters['view'] !== 'legacy') {
            $dataset = $this->service->fetch($start, $end, $filters);
            $summary = $this->service->summarize($dataset, $filters['view']);
        } else {
            // Mantener comportamiento legacy
            $branches = $filters['branch_ids'] ?? [];
            $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branches);
            $summary = $this->summarize($dataset);
        }

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'branch' => $this->stringifyFilter($filters['branch_ids'] ?? []),
            'filters' => $filters,
            'summary' => $summary,
            'data' => $dataset->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        $view = $filters['view'] ?? 'legacy';
        $groupByDay = $filters['group_by_day'] ?? false;
        $branches = $filters['branch_ids'] ?? [];
        $terminals = $filters['terminal_ids'] ?? [];

        // Usar nuevo servicio si se especifica una vista, caso contrario usar legacy
        if ($view !== 'legacy') {
            $dataset = $this->service->fetch($start, $end, $filters);
            $summary = $this->service->summarize($dataset, $view);
            $branchCandidates = $this->extractBranchesFromNewData($dataset);
        } else {
            // Mantener comportamiento legacy (función actual)
            $dataset = $this->fetchData($start, $end);
            $branchCandidates = $this->extractBranches($dataset);
            $filtered = $this->applyBranchFilter($dataset, $branches);
            $summary = $this->summarize($filtered);
            $dataset = $filtered;
        }

        $observedBranches = $branchCandidates
            ->pluck('key')
            ->merge($dataset->map(fn ($row) => $row->branch_key ?? $row->branch ?? $row->sucursal ?? null))
            ->filter()
            ->all();

        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $branches);

        // Obtener terminales disponibles para el selector
        $terminalOptions = $this->getTerminalOptions();

        return view('reports.sales.mods', [
            'active' => 'reportes',
            'view' => $view,
            'groupByDay' => $groupByDay,
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $filters] = $this->resolveFilters($request);

        $view = $filters['view'] ?? 'legacy';
        $branches = $filters['branch_ids'] ?? [];

        if ($view !== 'legacy') {
            $dataset = $this->service->fetch($start, $end, $filters);
            $summary = $this->service->summarize($dataset, $view);
        } else {
            $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branches);
            $summary = $this->summarize($dataset);
        }

        $export = new SalesModsExport($start, $end, $dataset, $summary, $view, $this->stringifyFilter($branches));
        $filename = sprintf(
            'reporte_items_mods_%s_%s%s.xlsx',
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
        [$start, $end, $filters] = $this->resolveFilters($request);

        $view = $filters['view'] ?? 'legacy';
        $branches = $filters['branch_ids'] ?? [];

        if ($view !== 'legacy') {
            $dataset = $this->service->fetch($start, $end, $filters);
            $summary = $this->service->summarize($dataset, $view);
        } else {
            $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branches);
            $summary = $this->summarize($dataset);
        }

        $filename = sprintf(
            'reporte_items_mods_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            ! empty($branches)
                ? '_'.str_replace(' ', '_', strtolower($this->stringifyFilter($branches)))
                : ''
        );

        return $this->renderPdf('reports.exports.sales.mods', [
            'startDate' => $start,
            'endDate' => $end,
            'view' => $view,
            'branch' => $this->stringifyFilter($branches),
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);

        $filters = [
            'view' => $request->input('view', 'legacy'),
            'group_by_day' => (bool) $request->input('group_by_day', false),
            'branch_ids' => $this->normalizeFilterList($request->input('branch'), uppercase: true),
            'terminal_ids' => $this->normalizeFilterList($request->input('terminal')),
        ];

        return [$start, $end, $filters];
    }

    protected function fetchData(Carbon $start, Carbon $end): Collection
    {
        $rows = DB::connection('pgsql')->select(
            <<<'SQL'
            SELECT gs.day::date AS report_date, f.*
            FROM generate_series(?::date, ?::date, interval '1 day') AS gs(day)
            CROSS JOIN LATERAL public.f_item_mods_on(gs.day::date) AS f
            SQL,
            [$start->format('Y-m-d'), $end->format('Y-m-d')]
        );

        return collect($rows);
    }

    protected function applyBranchFilter(Collection $rows, array $branches): Collection
    {
        if (empty($branches)) {
            return $rows->values();
        }

        $normalized = collect($branches)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->unique()
            ->values()
            ->all();

        return $rows
            ->filter(function (object $row) use ($normalized) {
                $value = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->sucursal ?? ''));

                return in_array($value, $normalized, true);
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

    /**
     * Extrae sucursales de los datos del nuevo servicio
     */
    protected function extractBranchesFromNewData(Collection $rows): Collection
    {
        return $rows
            ->map(function (object $row) {
                $key = $row->sucursal ?? $row->branch_key ?? $row->branch ?? null;
                $label = $key;

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

    /**
     * Obtiene opciones de terminales para el selector
     */
    protected function getTerminalOptions(): array
    {
        try {
            $terminals = DB::connection('pgsql')
                ->table('public.terminal')
                ->select('id', 'name')
                ->where('enabled', true)
                ->orderBy('id')
                ->get();

            return $terminals->map(fn($t) => [
                'key' => (string) $t->id,
                'label' => $t->name ?? "Terminal {$t->id}",
            ])->toArray();
        } catch (\Exception $e) {
            return [];
        }
    }
}
