<?php

namespace App\Http\Controllers\Reports;

use App\Models\Pos\Ticket;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Reporte de Cuentas Abiertas y Pagadas
 *
 * Muestra todas las cuentas (tickets) que están:
 * - Abiertas: sin pagar, sin anular, sin fecha de cierre
 * - Pagadas: pagadas exitosamente
 *
 * Útil para identificar problemas de cuentas arrastradas sin cerrar
 */
class OpenTicketsController extends BaseReportController
{
    /**
     * TTL del cache (minutos)
     */
    protected int $cacheTTL = 2;

    /**
     * Tags de cache (no se usan con driver file)
     */
    protected function getCacheTags(): array
    {
        return [];
    }

    /**
     * Muestra el reporte de cuentas abiertas/pagadas
     */
    public function show(Request $request)
    {
        [$startDate, $endDate] = $this->parseDateRange($request);
        $status = $request->input('status', 'open'); // open, paid, all
        $branch = $this->parseBranch($request);

        $cacheKey = sprintf(
            'reports:open-tickets:%s:%s:%s:%s',
            $startDate->format('Y-m-d'),
            $endDate->format('Y-m-d'),
            $status,
            $branch ?? 'all'
        );

        $data = $this->getCached($cacheKey, function () use ($startDate, $endDate, $status, $branch) {
            return $this->fetchTickets($startDate, $endDate, $status, $branch);
        });

        // Calcular totales
        $summary = [
            'total_open' => collect($data['open_tickets'])->count(),
            'total_paid' => collect($data['paid_tickets'])->count(),
            'amount_open' => collect($data['open_tickets'])->sum('total_price'),
            'amount_paid' => collect($data['paid_tickets'])->sum('total_price'),
            'oldest_open' => $this->getOldestOpenTicket($data['open_tickets']),
        ];

        return view('reports.tickets.open', [
            'title' => 'Reporte de Cuentas Abiertas/Pagadas',
            'active' => 'reports',
            'startDate' => $startDate,
            'endDate' => $endDate,
            'status' => $status,
            'branch' => $branch,
            'openTickets' => $data['open_tickets'],
            'paidTickets' => $data['paid_tickets'],
            'summary' => $summary,
            'branches' => $this->getBranches(),
        ]);
    }

    /**
     * Obtiene tickets según filtros
     */
    private function fetchTickets(Carbon $startDate, Carbon $endDate, string $status, ?string $branch): array
    {
        $baseQuery = "
            SELECT
                t.id,
                t.global_id,
                t.create_date,
                t.closing_date,
                t.paid,
                t.voided,
                t.sub_total,
                t.total_price,
                t.terminal_id,
                t.folio_date,
                t.branch_key,
                t.daily_folio,
                COALESCE(term.name, 'Terminal ' || t.terminal_id::text) as terminal_name,
                COALESCE(s.nombre, t.branch_key, 'Sin Sucursal') as branch_name,
                CASE
                    WHEN t.voided = true THEN 'voided'
                    WHEN t.paid = true THEN 'paid'
                    WHEN t.closing_date IS NULL THEN 'open'
                    ELSE 'closed'
                END as status,
                EXTRACT(EPOCH FROM (NOW() - t.create_date))/3600 as hours_open
            FROM public.ticket t
            LEFT JOIN public.terminal term ON t.terminal_id = term.id
            LEFT JOIN selemti.cat_sucursales s ON s.clave = UPPER(COALESCE(t.branch_key, term.location))
            WHERE t.create_date >= ? AND t.create_date <= ?
        ";

        $bindings = [
            $startDate->format('Y-m-d 00:00:00'),
            $endDate->format('Y-m-d 23:59:59'),
        ];

        // Filtrar por sucursal si se especifica
        if ($branch) {
            $baseQuery .= ' AND UPPER(COALESCE(t.branch_key, term.location)) = ?';
            $bindings[] = strtoupper($branch);
        }

        $baseQuery .= ' ORDER BY t.create_date DESC';

        $tickets = $this->executeWithTimeout($baseQuery, $bindings);

        // Separar por estado
        $openTickets = [];
        $paidTickets = [];

        foreach ($tickets as $ticket) {
            if ($ticket->voided) {
                continue; // Ignorar tickets anulados
            }

            if ($ticket->status === 'open') {
                $openTickets[] = $ticket;
            } elseif ($ticket->status === 'paid') {
                $paidTickets[] = $ticket;
            }
        }

        return [
            'open_tickets' => $openTickets,
            'paid_tickets' => $paidTickets,
        ];
    }

    /**
     * Obtiene el ticket abierto más antiguo
     */
    private function getOldestOpenTicket(array $openTickets): ?object
    {
        if (empty($openTickets)) {
            return null;
        }

        return collect($openTickets)->sortBy('create_date')->first();
    }

    /**
     * Obtiene lista de sucursales
     */
    private function getBranches(): array
    {
        try {
            $branches = DB::connection('pgsql')->select('
                SELECT
                    UPPER(clave) as key,
                    nombre as label
                FROM selemti.cat_sucursales
                ORDER BY nombre
            ');

            return array_map(fn ($b) => (array) $b, $branches);
        } catch (\Throwable $e) {
            return [];
        }
    }

    /**
     * Exporta reporte a PDF
     */
    public function exportPdf(Request $request)
    {
        [$startDate, $endDate] = $this->parseDateRange($request);
        $status = $request->input('status', 'open');
        $branch = $this->parseBranch($request);

        $data = $this->fetchTickets($startDate, $endDate, $status, $branch);

        $summary = [
            'total_open' => collect($data['open_tickets'])->count(),
            'total_paid' => collect($data['paid_tickets'])->count(),
            'amount_open' => collect($data['open_tickets'])->sum('total_price'),
            'amount_paid' => collect($data['paid_tickets'])->sum('total_price'),
            'oldest_open' => $this->getOldestOpenTicket($data['open_tickets']),
        ];

        $filename = sprintf(
            'cuentas-abiertas-%s-%s.pdf',
            $startDate->format('Y-m-d'),
            $endDate->format('Y-m-d')
        );

        return $this->renderPdf(
            'reports.exports.tickets.open',
            [
                'startDate' => $startDate,
                'endDate' => $endDate,
                'status' => $status,
                'branch' => $branch,
                'openTickets' => $data['open_tickets'],
                'paidTickets' => $data['paid_tickets'],
                'summary' => $summary,
                'generatedAt' => now(),
            ],
            $filename,
            'letter',
            'portrait'
        );
    }

    /**
     * API endpoint para datos del reporte
     */
    public function index(Request $request)
    {
        [$startDate, $endDate] = $this->parseDateRange($request);
        $status = $request->input('status', 'open');
        $branch = $this->parseBranch($request);

        $data = $this->fetchTickets($startDate, $endDate, $status, $branch);

        $summary = [
            'total_open' => collect($data['open_tickets'])->count(),
            'total_paid' => collect($data['paid_tickets'])->count(),
            'amount_open' => collect($data['open_tickets'])->sum('total_price'),
            'amount_paid' => collect($data['paid_tickets'])->sum('total_price'),
            'oldest_open' => $this->getOldestOpenTicket($data['open_tickets']),
        ];

        return response()->json([
            'ok' => true,
            'data' => [
                'open_tickets' => $data['open_tickets'],
                'paid_tickets' => $data['paid_tickets'],
                'summary' => $summary,
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
