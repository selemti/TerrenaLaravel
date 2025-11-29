<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesExceptionsExport;
use App\Services\Reports\SalesExceptionsReportService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SalesExceptionsController extends BaseReportController
{
    public function __construct(protected SalesExceptionsReportService $service)
    {
        parent::__construct();
    }

    public function index(Request $request): JsonResponse
    {
        [$start, $end, $filters] = $this->resolveFilters($request);
        $report = $this->buildReport($start, $end, $filters);

        $observedBranches = $report['records']->pluck('branch_key')->filter()->all();
        [$branchColors] = $this->buildBranchContext($observedBranches, $filters['branch_ids']);

        $categories = $report['categories']
            ->map(function (array $category) {
                $rows = $category['rows'] instanceof Collection
                    ? $category['rows']->values()->all()
                    : ($category['rows'] ?? []);

                return array_merge($category, ['rows' => $rows]);
            })
            ->values();

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'branch' => $this->stringifyFilter($filters['branch_ids']),
            'terminal' => $this->stringifyFilter($filters['terminal_ids']),
            'filters' => $filters,
            'branch_colors' => $branchColors,
            'summary' => $report['summary'],
            'categories' => $categories,
            'records' => $report['records']->values(),
            'discounts_summary' => $report['discount_summary']->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $filters] = $this->resolveFilters($request);
        $report = $this->buildReport($start, $end, $filters);

        $observedBranches = $report['records']->pluck('branch_key')->filter()->all();
        [$branchColors, $branchOptions, $branchLabels] = $this->buildBranchContext($observedBranches, $filters['branch_ids']);
        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $filters['terminal_ids'], $filters['branch_ids']);

        return view('reports.sales.exceptions', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $filters['branch_ids'],
            'terminalFilter' => $filters['terminal_ids'],
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'records' => $report['records'],
            'categories' => $report['categories'],
            'summary' => $report['summary'],
            'discountSummary' => $report['discount_summary'],
            'categoryCatalog' => $this->service->getCategoryCatalog(),
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $filters] = $this->resolveFilters($request);
        $report = $this->buildReport($start, $end, $filters);

        $export = new SalesExceptionsExport(
            $start,
            $end,
            $report['records'],
            $report['categories'],
            $report['summary'],
            $filters['branch_ids'],
            $filters['terminal_ids'],
            $report['discount_summary']
        );

        $filename = sprintf(
            'reporte_excepciones_%s_%s%s.xlsx',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $this->buildFilenameSuffix($filters)
        );

        return Excel::download($export, $filename);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $filters] = $this->resolveFilters($request);
        $report = $this->buildReport($start, $end, $filters);

        $filename = sprintf(
            'reporte_excepciones_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $this->buildFilenameSuffix($filters)
        );

        return $this->renderPdf('reports.exports.sales.exceptions', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $this->stringifyFilter($filters['branch_ids']),
            'terminal' => $this->stringifyFilter($filters['terminal_ids']),
            'categories' => $report['categories'],
            'summary' => $report['summary'],
            'discountSummary' => $report['discount_summary'],
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

        $filters = [
            'branch_ids' => $this->normalizeFilterList($request->input('branch'), uppercase: true),
            'terminal_ids' => $this->normalizeFilterList($request->input('terminal'), uppercase: false),
        ];

        return [$start->startOfDay(), $end->startOfDay(), $filters];
    }

    protected function buildReport(Carbon $start, Carbon $end, array $filters): array
    {
        $tickets = $this->service->fetch($start, $end, $filters);
        $report = $this->service->summarize($tickets, 'default');

        return [
            'records' => collect($report['records'] ?? []),
            'categories' => collect($report['categories'] ?? []),
            'summary' => $report['summary'] ?? [],
            'discount_summary' => $this->asCollection($report['discounts']['summary'] ?? []),
        ];
    }

    protected function buildFilenameSuffix(array $filters): string
    {
        $parts = [];

        $branchList = $this->stringifyFilter($filters['branch_ids'] ?? []);
        $terminalList = $this->stringifyFilter($filters['terminal_ids'] ?? []);

        if (! empty($branchList)) {
            $parts[] = str_replace(' ', '_', strtolower($branchList));
        }

        if (! empty($terminalList)) {
            $parts[] = str_replace(' ', '_', strtolower($terminalList));
        }

        return empty($parts) ? '' : '_'.implode('_', $parts);
    }

    protected function asCollection(mixed $value): Collection
    {
        if ($value instanceof Collection) {
            return $value;
        }

        return collect($value);
    }
}
