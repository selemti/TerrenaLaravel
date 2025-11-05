<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class SalesDetailController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $summary = [
            'total_lines' => $rows->count(),
            'total_qty' => (float) $rows->sum(fn ($r) => (float)($r->qty ?? 0)),
            'total_neto' => $this->round((float) $rows->sum(fn ($r) => (float)($r->line_neto ?? 0))),
        ];

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $branch,
            'terminal' => $terminal,
            'summary' => $summary,
            'data' => $rows->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        return view('reports.sales.detail', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'rows' => $rows,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    protected function resolveFilters(Request $request): array
    {
        $start = $request->input('start') ?? $request->input('start_date');
        $end = $request->input('end') ?? $request->input('end_date');
        $start = $start ? Carbon::parse($start, 'America/Mexico_City') : now('America/Mexico_City')->startOfDay();
        $end = $end ? Carbon::parse($end, 'America/Mexico_City') : $start->copy();
        if ($end->lt($start)) [$start, $end] = [$end, $start];
        $start = $start->startOfDay();
        $end = $end->startOfDay();

        $branch = trim((string) $request->input('branch', ''));
        $branch = $branch !== '' ? strtoupper($branch) : null;
        $terminal = trim((string) $request->input('terminal', ''));
        $terminal = $terminal !== '' ? $terminal : null;

        return [$start, $end, $branch, $terminal];
    }

    protected function fetch(Carbon $start, Carbon $end, ?string $branch, ?string $terminal): Collection
    {
        $sql = "SELECT * FROM public.vw_report_sales_detail WHERE folio_date BETWEEN ? AND ?";
        $bindings = [$start->toDateString(), $end->toDateString()];

        if ($branch) {
            if (str_contains($branch, ',')) {
                $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            } else {
                $sql .= " AND UPPER(branch_key) = ?";
            }
            $bindings[] = $branch;
        }

        if ($terminal) {
            $sql .= " AND CAST(terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = $terminal;
        }

        $rows = DB::connection('pgsql')->select($sql, $bindings);
        return collect($rows);
    }
}
