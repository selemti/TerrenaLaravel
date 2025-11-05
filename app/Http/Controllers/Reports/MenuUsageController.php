<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class MenuUsageController extends BaseReportController
{
    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branch, $terminal);

        $summary = [
            'unique_items' => $rows->pluck('item_name')->filter()->unique()->count(),
            'total_qty' => (float) $rows->sum(fn ($r) => (float)($r->qty ?? 0)),
            'total_neto' => $this->round((float) $rows->sum(fn ($r) => (float)($r->neto ?? 0))),
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

        return view('reports.menu.usage', [
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
        if (!$terminal) {
            $sql = "SELECT * FROM public.vw_report_menu_usage WHERE folio_date BETWEEN ? AND ?";
            $bindings = [$start->toDateString(), $end->toDateString()];
            if ($branch) {
                if (str_contains($branch, ',')) {
                    $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
                } else {
                    $sql .= " AND UPPER(branch_key) = ?";
                }
                $bindings[] = $branch;
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
        $bindings = [$start->toDateString(), $end->toDateString(), $terminal];
        if ($branch) {
            if (str_contains($branch, ',')) {
                $sql .= " AND UPPER(b.branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            } else {
                $sql .= " AND UPPER(b.branch_key) = ?";
            }
            $bindings[] = $branch;
        }
        $sql .= " GROUP BY 1,2,3";
        return collect(DB::connection('pgsql')->select($sql, $bindings));
    }
}
