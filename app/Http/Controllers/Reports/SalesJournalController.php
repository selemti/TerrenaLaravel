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
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branch, $terminal);

        return response()->json([
            'success' => true,
            'range' => ['start' => $start->toDateString(), 'end' => $end->toDateString()],
            'branch' => $branch,
            'terminal' => $terminal,
            'lines' => $lines->values(),
            'payments' => $payments->values(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branch, $terminal);

        return view('reports.sales.journal', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'lines' => $lines,
            'payments' => $payments,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branch, $terminal] = $this->resolveFilters($request);
        [$lines, $payments] = $this->fetch($start, $end, $branch, $terminal);

        $filename = sprintf(
            'reporte_journal_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            $branch ? '_' . str_replace(' ', '_', strtolower($branch)) : ''
        );

        return $this->renderPdf('reports.exports.sales.journal', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branch,
            'terminal' => $terminal,
            'lines' => $lines,
            'payments' => $payments,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
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

    protected function fetch(Carbon $start, Carbon $end, ?string $branch, ?string $terminal): array
    {
        $lSql = "SELECT * FROM public.vw_report_journal_lines WHERE folio_date BETWEEN ? AND ?";
        $pSql = "SELECT * FROM public.vw_report_journal_payments WHERE folio_date BETWEEN ? AND ?";
        $bindingsL = [$start->toDateString(), $end->toDateString()];
        $bindingsP = [$start->toDateString(), $end->toDateString()];

        if ($branch) {
            if (str_contains($branch, ',')) {
                $lSql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))"; $bindingsL[] = $branch;
                $pSql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))"; $bindingsP[] = $branch;
            } else {
                $lSql .= " AND UPPER(branch_key) = ?"; $bindingsL[] = $branch;
                $pSql .= " AND UPPER(branch_key) = ?"; $bindingsP[] = $branch;
            }
        }

        if ($terminal) {
            $lSql .= " AND EXISTS (SELECT 1 FROM public.ticket t WHERE t.id = vw_report_journal_lines.ticket_id AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ','))))";
            $bindingsL[] = $terminal;
            $pSql .= " AND EXISTS (SELECT 1 FROM public.ticket t WHERE t.id = vw_report_journal_payments.ticket_id AND CAST(t.terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ','))))";
            $bindingsP[] = $terminal;
        }

        $lines = collect(DB::connection('pgsql')->select($lSql, $bindingsL));
        $payments = collect(DB::connection('pgsql')->select($pSql, $bindingsP));
        return [$lines, $payments];
    }
}
