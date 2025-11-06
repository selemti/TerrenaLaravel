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
    /**
     * Paleta utilizada cuando no hay color definido en config/reports.php.
     */
    protected array $fallbackPalette = [
        '#2563eb',
        '#16a34a',
        '#f97316',
        '#0ea5e9',
        '#f43f5e',
        '#8b5cf6',
        '#f59e0b',
        '#22c55e',
        '#7c3aed',
        '#ef4444',
        '#0f172a',
    ];
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $filtered = $this->applyBranchFilter($dataset, $branch);
        $summary = $this->summarize($filtered);
        $adjustments = $this->fetchSalesAdjustments($start, $end, $branch);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->format('Y-m-d'),
                'end' => $end->format('Y-m-d'),
            ],
            'branch' => $branch,
            'summary' => $summary,
            'adjustments' => $adjustments,
            'data' => $filtered->values(),
            'generated_at' => now('America/Mexico_City')->toIso8601String(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch] = $this->resolveFilters($request);

        $dataset = $this->fetchData($start, $end);
        $branches = $this->extractBranches($dataset);
        $selectedBranches = $this->explodeBranchList($branch);
        $branchColors = $this->prepareBranchColors($branches->pluck('key')->filter()->values()->all());
        $branchOptions = $this->buildBranchOptions($branches, $selectedBranches, $branchColors);
        $branchLegend = $this->buildBranchLegend($branches, $branchColors);

        $filtered = $this->applyBranchFilter($dataset, $branch);
        $summary = $this->summarize($filtered);
        $pivot = $this->buildPivot($filtered);

        $pivotTotals = $this->sumPivot($pivot);
        $branchPivot = $this->buildBranchPivot($filtered);
        $branchTotals = $this->sumPivot($branchPivot);
        $adjustments = $this->fetchSalesAdjustments($start, $end, $branch);

        return view('reports.sales.mix', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'branches' => $branches,
            'branchOptions' => $branchOptions,
            'branchLegend' => $branchLegend,
            'branchColors' => $branchColors,
            'selectedBranches' => $selectedBranches,
            'rows' => $filtered,
            'pivotRows' => $pivot,
            'pivotTotals' => $pivotTotals,
            'branchPivot' => $branchPivot,
            'branchTotals' => $branchTotals,
            'summary' => $summary,
            'adjustments' => $adjustments,
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

        $datasetRaw = $this->fetchData($start, $end);
        $branches = $this->extractBranches($datasetRaw);
        $branchColors = $this->prepareBranchColors($branches->pluck('key')->filter()->values()->all());
        $branchLegend = $this->buildBranchLegend($branches, $branchColors);
        $selectedBranches = $this->explodeBranchList($branch);

        $dataset = $this->applyBranchFilter($datasetRaw, $branch);
        $summary = $this->summarize($dataset);
        $pivot = $this->buildPivot($dataset);
        $pivotTotals = $this->sumPivot($pivot);
        $branchPivot = $this->buildBranchPivot($dataset);
        $branchTotals = $this->sumPivot($branchPivot);
        $adjustments = $this->fetchSalesAdjustments($start, $end, $branch);

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
            'pivotRows' => $pivot,
            'pivotTotals' => $pivotTotals,
            'branchPivot' => $branchPivot,
            'branchTotals' => $branchTotals,
            'adjustments' => $adjustments,
            'generatedAt' => now('America/Mexico_City'),
            'branchColors' => $branchColors,
            'branchLegend' => $branchLegend,
            'selectedBranches' => $selectedBranches,
        ], $filename, paper: 'letter', orientation: 'portrait');
    }

    protected function resolveFilters(Request $request): array
    {
        [$start, $end] = $this->parseDateRange($request);
        $branchParam = $request->input('branch');
        if (is_array($branchParam)) {
            $branch = strtoupper(implode(',', array_filter(array_map('strval', $branchParam))));
        } else {
            $branch = $this->parseBranch($request);
        }
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
        $normalized = array_map('trim', explode(',', strtoupper($branch)));
        return $rows
            ->filter(function (object $row) use ($normalized) {
                $value = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->branch_name ?? ''));
                return in_array($value, $normalized, true);
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

    protected function fetchSalesAdjustments(Carbon $start, Carbon $end, ?string $branch): array
    {
        $sql = <<<SQL
            SELECT
                COALESCE(SUM(bruto), 0) AS bruto,
                COALESCE(SUM(descuento), 0) AS descuento,
                COALESCE(SUM(neto), 0) AS neto,
                COALESCE(SUM(propina), 0) AS propina,
                COALESCE(SUM(cargo_servicio), 0) AS cargo_servicio
            FROM public.vw_report_sales_summary
            WHERE folio_date BETWEEN ? AND ?
        SQL;

        $bindings = [$start->format('Y-m-d'), $end->format('Y-m-d')];

        if ($branch) {
            if (str_contains($branch, ',')) {
                $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            } else {
                $sql .= " AND UPPER(branch_key) = ?";
            }
            $bindings[] = $branch;
        }

        $row = DB::connection('pgsql')->selectOne($sql, $bindings);

        if (!$row) {
            return [
                'gross' => 0.0,
                'discount' => 0.0,
                'net' => 0.0,
                'tips' => 0.0,
                'service' => 0.0,
                'total_with_charges' => 0.0,
            ];
        }

        $gross = $this->round((float) ($row->bruto ?? 0));
        $discount = $this->round((float) ($row->descuento ?? 0));
        $net = $this->round((float) ($row->neto ?? 0));
        $tips = $this->round((float) ($row->propina ?? 0));
        $service = $this->round((float) ($row->cargo_servicio ?? 0));
        $totalWithCharges = $this->round($net + $tips + $service);

        return [
            'gross' => $gross,
            'discount' => $discount,
            'net' => $net,
            'tips' => $tips,
            'service' => $service,
            'total_with_charges' => $totalWithCharges,
        ];
    }

    protected function explodeBranchList(?string $branch): array
    {
        if (!$branch) {
            return [];
        }

        return collect(explode(',', $branch))
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();
    }

    protected function prepareBranchColors(array $branchKeys): array
    {
        $configured = collect(config('reports.branch_colors', []))
            ->mapWithKeys(fn ($color, $key) => [strtoupper((string) $key) => $color])
            ->toArray();

        $palette = config('reports.branch_palette', $this->fallbackPalette);
        if (empty($palette)) {
            $palette = $this->fallbackPalette;
        }

        $colors = $configured;
        $index = 0;

        foreach ($branchKeys as $key) {
            $upper = strtoupper((string) $key);
            if ($upper === '') {
                continue;
            }

            if (!isset($colors[$upper])) {
                $colors[$upper] = $palette[$index % count($palette)];
                $index++;
            }
        }

        return $colors;
    }

    protected function buildBranchOptions(Collection $branches, array $selected, array $branchColors): Collection
    {
        $selectedSet = collect($selected)
            ->map(fn ($value) => strtoupper((string) $value))
            ->filter()
            ->values()
            ->all();

        return $branches
            ->map(function (array $branch) use ($selectedSet, $branchColors) {
                $key = strtoupper((string) ($branch['key'] ?? ''));
                $label = (string) ($branch['label'] ?? $key);
                if ($key === '') {
                    return null;
                }

                $color = $branchColors[$key] ?? $this->fallbackPalette[0];

                return [
                    'key' => $key,
                    'value' => $key,
                    'label' => $label,
                    'indicator_color' => $color,
                    'color' => $color,
                    'selected' => in_array($key, $selectedSet, true),
                    'badge' => null,
                    'highlight' => false,
                ];
            })
            ->filter()
            ->sortBy(fn (array $opt) => $opt['label'])
            ->values();
    }

    protected function buildBranchLegend(Collection $branches, array $branchColors): Collection
    {
        return $branches
            ->map(function (array $branch) use ($branchColors) {
                $key = strtoupper((string) ($branch['key'] ?? ''));
                if ($key === '') {
                    return null;
                }

                return [
                    'key' => $key,
                    'label' => (string) ($branch['label'] ?? $key),
                    'color' => $branchColors[$key] ?? $this->fallbackPalette[0],
                ];
            })
            ->filter()
            ->sortBy(fn (array $item) => $item['label'])
            ->values();
    }

    protected function buildPivot(Collection $rows): array
    {
        $grouped = $rows->groupBy(function (object $row) {
            $date = (string) ($row->report_date ?? '');
            $branch = strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->branch_name ?? ''));
            return $date.'|'.$branch;
        });

        $result = [];
        foreach ($grouped as $key => $items) {
            [$date, $branch] = explode('|', $key, 2);

            $cash = 0.0; $credit = 0.0; $debit = 0.0; $other = 0.0; $net = 0.0;
            foreach ($items as $row) {
                $amount = (float) ($row->total ?? 0);
                $method = strtoupper((string) ($row->normalized_payment ?? $row->payment_method ?? $row->payment ?? $row->pay_norm ?? ''));
                switch ($method) {
                    case 'CASH': $cash += $amount; break;
                    case 'CREDIT_CARD': $credit += $amount; break;
                    case 'DEBIT_CARD': $debit += $amount; break;
                    default: $other += $amount; break;
                }
                $net += $amount;
            }

            $result[] = [
                'report_date' => $date,
                'branch_key' => $branch,
                'cash' => $this->round($cash),
                'credit' => $this->round($credit),
                'debit' => $this->round($debit),
                'other' => $this->round($other),
                'net' => $this->round($net),
            ];
        }

        usort($result, function ($a, $b) {
            return strcmp(($a['report_date'] ?? ''), ($b['report_date'] ?? '')) ?: strcmp(($a['branch_key'] ?? ''), ($b['branch_key'] ?? ''));
        });

        return $result;
    }

    protected function sumPivot(array $pivot): array
    {
        $totals = ['cash' => 0.0, 'credit' => 0.0, 'debit' => 0.0, 'other' => 0.0, 'net' => 0.0];
        foreach ($pivot as $r) {
            $totals['cash'] += (float)($r['cash'] ?? 0);
            $totals['credit'] += (float)($r['credit'] ?? 0);
            $totals['debit'] += (float)($r['debit'] ?? 0);
            $totals['other'] += (float)($r['other'] ?? 0);
            $totals['net'] += (float)($r['net'] ?? 0);
        }
        foreach ($totals as $k => $v) { $totals[$k] = $this->round($v); }
        return $totals;
    }

    protected function buildBranchPivot(Collection $rows): array
    {
        $grouped = $rows->groupBy(function (object $row) {
            return strtoupper((string) ($row->branch_key ?? $row->branch ?? $row->branch_name ?? ''));
        });

        $result = [];
        foreach ($grouped as $branch => $items) {
            $cash = 0.0; $credit = 0.0; $debit = 0.0; $other = 0.0; $net = 0.0;
            foreach ($items as $row) {
                $amount = (float) ($row->total ?? 0);
                $method = strtoupper((string) ($row->normalized_payment ?? $row->payment_method ?? $row->payment ?? $row->pay_norm ?? ''));
                switch ($method) {
                    case 'CASH': $cash += $amount; break;
                    case 'CREDIT_CARD': $credit += $amount; break;
                    case 'DEBIT_CARD': $debit += $amount; break;
                    default: $other += $amount; break;
                }
                $net += $amount;
            }
            $result[] = [
                'branch_key' => $branch,
                'cash' => $this->round($cash),
                'credit' => $this->round($credit),
                'debit' => $this->round($debit),
                'other' => $this->round($other),
                'net' => $this->round($net),
            ];
        }
        usort($result, fn($a,$b) => strcmp($a['branch_key'] ?? '', $b['branch_key'] ?? ''));
        return $result;
    }
}
