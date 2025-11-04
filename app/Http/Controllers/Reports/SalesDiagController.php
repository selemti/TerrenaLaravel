<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesDiagnosticsExport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SalesDiagController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $severity);
        $summary = $this->summarize($dataset, $severity);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'severity' => $severity,
            'summary' => $summary,
            'data' => $dataset->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $severity] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $filtered = $this->applyFilters($dataset, $severity);
        $summary = $this->summarize($filtered, $severity, $dataset);

        return view('reports.sales.diagnostics', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'severity' => $severity,
            'rows' => $filtered,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $severity);
        $summary = $this->summarize($dataset, $severity);

        $export = new SalesDiagnosticsExport($start, $end, $dataset, $summary, $severity);
        $filename = sprintf(
            'reporte_diagnosticos_%s_%s.xlsx',
            $start->format('Ymd'),
            $end->format('Ymd')
        );

        return Excel::download($export, $filename);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $severity] = $this->resolveFilters($request);

        $dataset = $this->applyFilters($this->fetchData($start, $end), $severity);
        $summary = $this->summarize($dataset, $severity);

        $filename = sprintf(
            'reporte_diagnosticos_%s_%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd')
        );

        return $this->renderPdf('reports.exports.sales.diagnostics', [
            'startDate' => $start,
            'endDate' => $end,
            'severity' => $severity,
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);
        $severity = $this->parseEnum($request, 'severity');

        return [$start, $end, $severity];
    }

    protected function fetchData(Carbon $start, Carbon $end): Collection
    {
        $rows = DB::connection('pgsql')->select(
            <<<SQL
            SELECT gs.day::date AS report_date, f.*
            FROM generate_series(?::date, ?::date, interval '1 day') AS gs(day)
            CROSS JOIN LATERAL public.f_daily_diagnostics_summary_on(gs.day::date) AS f
            SQL,
            [$start->format('Y-m-d'), $end->format('Y-m-d')]
        );

        return collect($rows);
    }

    protected function applyFilters(Collection $rows, ?string $severity): Collection
    {
        if ($severity) {
            $rows = $rows->filter(function (object $row) use ($severity) {
                return strtoupper((string) ($row->severity ?? '')) === $severity;
            });
        }

        return $rows->values();
    }

    protected function summarize(Collection $rows, ?string $severity, ?Collection $original = null): array
    {
        $sumRows = fn (Collection $collection) => $collection->sum(fn (object $row) => (int) ($row->rows ?? 0));

        $totalAll = $original ? $sumRows($original) : $sumRows($rows);
        $totalFiltered = $sumRows($rows);

        $critical = $rows->sum(fn (object $row) => strtoupper((string) ($row->severity ?? '')) === 'CRITICAL' ? (int) ($row->rows ?? 0) : 0);
        $warning = $rows->sum(fn (object $row) => strtoupper((string) ($row->severity ?? '')) === 'WARN' ? (int) ($row->rows ?? 0) : 0);
        $info = $rows->sum(fn (object $row) => strtoupper((string) ($row->severity ?? '')) === 'INFO' ? (int) ($row->rows ?? 0) : 0);

        $views = $rows
            ->map(function (object $row) {
                $source = $row->source_view ?? 'unknown';

                return [
                    'view' => $this->translateViewName($source),
                    'raw_view' => $source,
                    'severity' => strtoupper((string) ($row->severity ?? 'INFO')),
                    'count' => (int) ($row->rows ?? 0),
                    'report_date' => $row->report_date ?? null,
                ];
            })
            ->sortByDesc('count')
            ->toArray();

        return [
            'total_checks' => $totalAll,
            'filtered_count' => $totalFiltered,
            'entry_count' => $rows->count(),
            'critical_count' => $critical,
            'warning_count' => $warning,
            'info_count' => $info,
            'total_rows_affected' => $totalFiltered,
            'severity_filter' => $severity,
            'views' => $views,
            'days' => $rows->pluck('report_date')->filter()->unique()->sort()->values()->all(),
        ];
    }

    protected function translateViewName(string $view): string
    {
        return match ($view) {
            'vw_diag_neto_vs_cobros' => 'Neto vs cobros',
            'vw_diag_discount_header_vs_lines' => 'Descuentos encabezado vs líneas',
            'vw_diag_paid_but_no_payments' => 'Tickets pagados sin pagos',
            'vw_diag_unnormalized_payments' => 'Pagos sin normalizar',
            'vw_diag_service_charge_vs_paid' => 'Servicio vs pagos',
            'vw_diag_drawer_vs_cash_transactions' => 'Cajón vs efectivo',
            'vw_diag_orphans_tickets' => 'Tickets huérfanos',
            'vw_diag_orphans_tx' => 'Transacciones huérfanas',
            'vw_diag_high_discounts' => 'Descuentos altos',
            default => $view,
        };
    }
}
