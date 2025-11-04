<?php

namespace App\Http\Controllers\Reports;

use App\Exports\Reports\SalesMixExport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SalesMixController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $filtered = $this->applyBranchFilter($dataset, $branch);
        $summary = $this->summarize($filtered);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'branch' => $branch,
            'summary' => $summary,
            'data' => $filtered->values(),
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

        return view('reports.sales.mix', [
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

    public function today(): JsonResponse
    {
        $dataset = collect(DB::connection('pgsql')->select('SELECT * FROM public.vw_sales_mix_payment_today'));
        $summary = $this->summarize($dataset);

        return response()->json([
            'success' => true,
            'date' => now('America/Mexico_City')->format('Y-m-d'),
            'branch' => null,
            'summary' => $summary,
            'data' => $dataset->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function exportExcel(Request $request): BinaryFileResponse
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->applyBranchFilter($this->fetchData($start, $end), $branch);
        $summary = $this->summarize($dataset);

        $export = new SalesMixExport($start, $end, $dataset, $summary, $branch);
        $filename = sprintf(
            'reporte_mix_ventas_%s_%s%s.xlsx',
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
            'reporte_mix_ventas_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return $this->renderPdf('reports.exports.sales.mix', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'rows' => $dataset,
            'summary' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename, paper: 'letter', orientation: 'portrait');
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
            CROSS JOIN LATERAL public.f_sales_mix_payment_on(gs.day::date) AS f
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
                $value = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->branch_name ?? ''));
                return $value === $normalized;
            })
            ->values();
    }

    protected function summarize(Collection $rows): array
    {
        $total = $rows->sum(fn (object $row) => (float) ($row->total ?? 0));

        $payments = $rows
            ->groupBy(fn (object $row) => strtoupper((string) ($row->normalized_payment ?? 'SIN_DEFINIR')))
            ->map(function (Collection $items, string $key) use ($total) {
                $amount = $items->sum(fn (object $row) => (float) ($row->total ?? 0));

                return [
                    'key' => $key,
                    'label' => $this->paymentLabel($key),
                    'amount' => $this->round($amount),
                    'percentage' => $total > 0 ? $this->round(($amount / $total) * 100) : 0.0,
                ];
            })
            ->sortByDesc('amount')
            ->values()
            ->toArray();

        $branches = $rows
            ->groupBy(fn (object $row) => strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->branch_name ?? 'SIN_SUCURSAL')))
            ->map(function (Collection $items, string $key) use ($total) {
                $amount = $items->sum(fn (object $row) => (float) ($row->total ?? 0));
                $first = $items->first();
                $label = $first?->branch_name
                    ?? $first?->branch
                    ?? $first?->branch_key
                    ?? $key;

                return [
                    'key' => $key,
                    'label' => $label,
                    'amount' => $this->round($amount),
                    'percentage' => $total > 0 ? $this->round(($amount / $total) * 100) : 0.0,
                ];
            })
            ->sortByDesc('amount')
            ->values()
            ->toArray();

        return [
            'total_general' => $this->round($total),
            'payments' => $payments,
            'branches' => $branches,
            'metrics' => [
                'total_methods' => count($payments),
                'total_branches' => count($branches),
            ],
            'days' => $rows->pluck('report_date')->filter()->unique()->sort()->values()->all(),
        ];
    }

    protected function extractBranches(Collection $rows): Collection
    {
        return $rows
            ->map(function (object $row) {
                $key = $row->branch_key ?? $row->branch ?? $row->branch_name ?? null;
                $label = $row->branch_name ?? $row->branch ?? $row->branch_key ?? null;

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

    protected function paymentLabel(string $key): string
    {
        return match ($key) {
            'CASH' => 'Efectivo',
            'DEBIT_CARD' => 'Tarjeta débito',
            'CREDIT_CARD' => 'Tarjeta crédito',
            'TRANSFER' => 'Transferencia',
            'VOUCHER' => 'Vales',
            'DIGITAL' => 'Digital',
            default => ucfirst(strtolower(str_replace('_', ' ', $key))),
        };
    }
}
