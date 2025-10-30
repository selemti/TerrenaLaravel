<?php

namespace App\Http\Controllers\Pos;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Pos\PosConsumptionService;
use App\Services\Pos\Repositories\ConsumoPosRepository;
use App\Services\Pos\Repositories\TicketRepository;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PosConsumptionController extends Controller
{
    public function __construct(
        protected PosConsumptionService $service,
        protected TicketRepository $ticketRepo,
        protected ConsumoPosRepository $consumoRepo,
        private AuditLogService $auditLogService
    ) {
    }

    /**
     * GET /api/pos/tickets/{ticketId}/diagnostics
     *
     * Diagnostica el estado de un ticket
     *
     * @param int $ticketId
     * @return JsonResponse
     */
    public function diagnostics(int $ticketId): JsonResponse
    {
        try {
            $diagnostics = $this->service->diagnosticarTicket($ticketId);

            return response()->json([
                'ok' => true,
                'data' => $diagnostics->toArray(),
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error en diagnostics endpoint', [
                'ticket_id' => $ticketId,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'DIAGNOSTICS_ERROR',
                'message' => 'Error al diagnosticar ticket: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/pos/tickets/{ticketId}/reprocess
     *
     * Reprocesa un ticket histórico
     * Requiere permiso: can_reprocess_sales
     *
     * @param Request $request
     * @param int $ticketId
     * @return JsonResponse
     */
    public function reprocess(Request $request, int $ticketId): JsonResponse
    {
        try {
            $user = $request->user();
            if (! $user) {
                return response()->json([
                    'ok' => false,
                    'error' => 'UNAUTHORIZED',
                    'message' => 'Usuario no autenticado',
                    'timestamp' => now()->toIso8601String(),
                ], 401);
            }
            $userId = (int) $user->id;

            // TODO: evidencia_url será obligatoria cuando tengamos foto del ticket / factura.
            if (trim($request->input('motivo', '')) === '') {
                return response()->json([
                    'ok' => false,
                    'error' => 'MISSING_MOTIVO',
                    'message' => 'Motivo requerido para reprocesar ticket POS',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }

            // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

            $result = $this->service->reprocesarTicket($ticketId, $userId);

            $statusCode = $result->isSuccess() ? 200 : 400;

            $this->auditLogService->logAction(
                $userId,
                'POS_REPROCESS',
                'pos_ticket',
                $ticketId,
                (string) $request->input('motivo', ''),
                $request->input('evidencia_url'),
                $request->all()
            );

            return response()->json([
                'ok' => $result->isSuccess(),
                'data' => $result->toArray(),
                'timestamp' => now()->toIso8601String(),
            ], $statusCode);
        } catch (\Exception $e) {
            Log::error('Error en reprocess endpoint', [
                'ticket_id' => $ticketId,
                'user_id' => auth()->id(),
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'REPROCESS_ERROR',
                'message' => 'Error al reprocesar ticket: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/pos/tickets/{ticketId}/reverse
     *
     * Reversa el consumo de un ticket
     * Requiere permiso: can_reprocess_sales
     *
     * @param Request $request
     * @param int $ticketId
     * @return JsonResponse
     */
    public function reverse(Request $request, int $ticketId): JsonResponse
    {
        try {
            $user = $request->user();
            if (! $user) {
                return response()->json([
                    'ok' => false,
                    'error' => 'UNAUTHORIZED',
                    'message' => 'Usuario no autenticado',
                    'timestamp' => now()->toIso8601String(),
                ], 401);
            }
            $userId = (int) $user->id;

            $motivo = $request->input('motivo', 'Reversa manual');

            $result = $this->service->reversarTicket($ticketId, $userId, $motivo);

            $statusCode = $result->isSuccess() ? 200 : 400;

            $this->auditLogService->logAction(
                $userId,
                'POS_REVERSE',
                'pos_ticket',
                $ticketId,
                $motivo,
                $request->input('evidencia_url'),
                $request->all()
            );

            return response()->json([
                'ok' => $result->isSuccess(),
                'data' => $result->toArray(),
                'timestamp' => now()->toIso8601String(),
            ], $statusCode);
        } catch (\Exception $e) {
            Log::error('Error en reverse endpoint', [
                'ticket_id' => $ticketId,
                'user_id' => auth()->id(),
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'REVERSE_ERROR',
                'message' => 'Error al reversar ticket: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * GET /api/pos/dashboard/missing-recipes
     *
     * Lista tickets con problemas de mapeo de recetas
     * Para UI tipo semáforo
     * Requiere permiso: can_view_recipe_dashboard
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function missingRecipes(Request $request): JsonResponse
    {
        try {
            // Obtener parámetros de consulta
            $hours = $request->input('hours', 24); // últimas N horas
            $limit = $request->input('limit', 50); // máximo de resultados

            // Obtener tickets pagados de las últimas X horas
            $tickets = $this->ticketRepo->getTicketsPaidLastHours($hours, $limit);

            $problemTickets = [];

            foreach ($tickets as $ticket) {
                $ticketId = $ticket['id'];

                // Diagnosticar cada ticket
                $diagnostics = $this->service->diagnosticarTicket($ticketId);

                // Solo incluir tickets con problemas
                if ($diagnostics->hasIssues()) {
                    $problemTickets[] = [
                        'ticket_id' => $ticketId,
                        'folio_display' => $this->formatFolio($ticket),
                        'branch_key' => $ticket['branch_key'] ?? null,
                        'create_date' => $ticket['create_date'] ?? null,
                        'total_amount' => $ticket['total_amount'] ?? 0,
                        'estado_consumo' => $diagnostics->getEstadoConsumo(),
                        'items_total' => $diagnostics->getItemsTotal(),
                        'items_sin_receta' => $diagnostics->getItemsSinReceta(),
                        'puede_reprocesar' => $diagnostics->getPuedeReprocesar(),
                        'tiene_consumo_confirmado' => $diagnostics->getTieneConsumoConfirmado(),
                        'warnings' => $diagnostics->getWarnings(),
                    ];
                }
            }

            return response()->json([
                'ok' => true,
                'data' => [
                    'tickets' => $problemTickets,
                    'total' => count($problemTickets),
                    'hours' => $hours,
                    'limit' => $limit,
                ],
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error en missingRecipes endpoint', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'MISSING_RECIPES_ERROR',
                'message' => 'Error al obtener tickets problemáticos: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Formatea el folio para display
     *
     * @param array $ticket
     * @return string
     */
    protected function formatFolio(array $ticket): string
    {
        $dailyFolio = $ticket['daily_folio'] ?? '?';
        $createDate = $ticket['create_date'] ?? '';

        if ($createDate) {
            $date = date('Y-m-d', strtotime($createDate));
            return "{$dailyFolio} ({$date})";
        }

        return (string) $dailyFolio;
    }
}
