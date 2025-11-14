<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use App\Services\Caja\AlertasService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller for managing alerts in the Caja system
 */
class AlertasController extends Controller
{
    protected $alertasService;

    public function __construct(AlertasService $alertasService)
    {
        $this->alertasService = $alertasService;
    }

    /**
     * Get all alerts for the authenticated user
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $userId = auth()->user()->id ?? 1;
            $includeRead = $request->query('include_read', false);

            if ($includeRead) {
                // Get all alerts (including read)
                $alertas = \DB::connection('pgsql')
                    ->table('selemti.alertas_cortes as a')
                    ->leftJoin('selemti.sesion_cajon as s', 'a.sesion_id', '=', 's.id')
                    ->leftJoin('selemti.postcorte as p', 'a.postcorte_id', '=', 'p.id')
                    ->select([
                        'a.id',
                        'a.tipo',
                        'a.sesion_id',
                        'a.postcorte_id',
                        's.terminal_id',
                        's.cajero_usuario_id',
                        'a.creada_en',
                        'a.leida',
                        'a.leida_en',
                        'p.declarado_efectivo',
                        'p.diferencia_efectivo',
                    ])
                    ->where('a.destinatario_id', $userId)
                    ->orderBy('a.creada_en', 'desc')
                    ->limit(50)
                    ->get()
                    ->toArray();
            } else {
                // Get only unread alerts
                $alertas = $this->alertasService->obtenerAlertasPendientes($userId);
            }

            return response()->json([
                'ok' => true,
                'data' => $alertas,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error al obtener alertas: '.$e->getMessage());

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al obtener alertas',
            ], 500);
        }
    }

    /**
     * Get count of unread alerts for badge display
     */
    public function count(Request $request): JsonResponse
    {
        try {
            $userId = auth()->user()->id ?? 1;
            $count = $this->alertasService->contarAlertasPendientes($userId);

            return response()->json([
                'ok' => true,
                'count' => $count,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error al contar alertas: '.$e->getMessage());

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al contar alertas',
            ], 500);
        }
    }

    /**
     * Mark an alert as read
     */
    public function marcarLeida(Request $request, $id): JsonResponse
    {
        try {
            $success = $this->alertasService->marcarLeida($id);

            if (! $success) {
                return response()->json([
                    'ok' => false,
                    'error' => 'alert_not_found',
                ], 404);
            }

            return response()->json([
                'ok' => true,
                'message' => 'Alerta marcada como leída',
            ]);

        } catch (\Exception $e) {
            \Log::error("Error al marcar alerta como leída (id: $id): ".$e->getMessage());

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al marcar alerta como leída',
            ], 500);
        }
    }

    /**
     * Mark all alerts as read for the authenticated user
     */
    public function marcarTodasLeidas(Request $request): JsonResponse
    {
        try {
            $userId = auth()->user()->id ?? 1;

            \DB::connection('pgsql')
                ->table('selemti.alertas_cortes')
                ->where('destinatario_id', $userId)
                ->where('leida', false)
                ->update([
                    'leida' => true,
                    'leida_en' => now(),
                ]);

            return response()->json([
                'ok' => true,
                'message' => 'Todas las alertas marcadas como leídas',
            ]);

        } catch (\Exception $e) {
            \Log::error('Error al marcar todas las alertas como leídas: '.$e->getMessage());

            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'detail' => config('app.debug') ? $e->getMessage() : 'Error al marcar alertas como leídas',
            ], 500);
        }
    }
}
