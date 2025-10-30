<?php

namespace App\Http\Controllers\Audit;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditQueryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Controlador HTTP para lectura del log de auditoría
 * 
 * Este controlador proporciona un endpoint API protegido para consultar
 * registros de auditoría con filtros y permisos adecuados.
 */
class AuditLogController extends Controller
{
    public function __construct(private AuditQueryService $auditQueryService)
    {
        // Vista web protegida por sesión y permiso correspondiente.
        $this->middleware(['auth', 'permission:alerts.view'])->only('index');
        // Endpoint API protegido por Sanctum + permiso alerts.view.
        $this->middleware(['auth:sanctum', 'permission:alerts.view'])->only('list');
    }

    /**
     * Mostrar la vista principal de auditoría operacional
     * 
     * @route GET /audit/logs
     * @middleware auth, permission:alerts.view
     * @return \Illuminate\Contracts\View\View
     */
    public function index()
    {
        // Obtener los últimos 100 registros de auditoría
        $logs = DB::connection('pgsql')
            ->table('selemti.audit_log')
            ->orderByDesc('timestamp')
            ->limit(100)
            ->get()
            ->map(function ($log) {
                // Decodificar el payload JSON si existe
                $payloadJsonDecoded = null;
                if (! empty($log->payload_json)) {
                    $payloadJsonDecoded = json_decode($log->payload_json, true);
                }

                return (object) [
                    'id' => $log->id,
                    'timestamp' => $log->timestamp ? new \DateTime($log->timestamp) : null,
                    'user_id' => $log->user_id,
                    'user' => $this->getUserDetails($log->user_id),
                    'accion' => $log->accion,
                    'entidad' => $log->entidad,
                    'entidad_id' => $log->entidad_id,
                    'motivo' => $log->motivo,
                    'evidencia_url' => $log->evidencia_url,
                    'payload_json' => $log->payload_json,
                    'payload_json_decoded' => $payloadJsonDecoded,
                ];
            });

        return view('audit.logs', ['logs' => $logs]);
    }

    /**
     * Buscar y retornar logs de auditoría
     * 
     * @route GET /api/audit/logs
     * @middleware auth:sanctum, permission:alerts.view
     * @param Request $request
     * @return JsonResponse
     */
    public function list(Request $request): JsonResponse
    {
        // Validaciones mínimas
        $filters = [];
        
        // user_id debe ser numérico si se proporciona
        if ($request->has('user_id') && $request->user_id !== '') {
            if (! is_numeric($request->user_id)) {
                return response()->json([
                    'ok' => false,
                    'error' => 'INVALID_USER_ID',
                    'message' => 'user_id debe ser un número entero',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }
            $filters['user_id'] = (int) $request->user_id;
        }

        // entidad_id debe ser numérico si se proporciona
        if ($request->has('entidad_id') && $request->entidad_id !== '') {
            if (! is_numeric($request->entidad_id)) {
                return response()->json([
                    'ok' => false,
                    'error' => 'INVALID_ENTITY_ID',
                    'message' => 'entidad_id debe ser un número entero',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }
            $filters['entidad_id'] = (int) $request->entidad_id;
        }

        // date_from debe tener formato YYYY-MM-DD si se proporciona
        if ($request->has('date_from') && $request->date_from !== '') {
            if (! $this->validateDateFormat($request->date_from)) {
                return response()->json([
                    'ok' => false,
                    'error' => 'INVALID_DATE_FROM',
                    'message' => 'date_from debe tener formato YYYY-MM-DD',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }
            $filters['date_from'] = $request->date_from;
        }

        // date_to debe tener formato YYYY-MM-DD si se proporciona
        if ($request->has('date_to') && $request->date_to !== '') {
            if (! $this->validateDateFormat($request->date_to)) {
                return response()->json([
                    'ok' => false,
                    'error' => 'INVALID_DATE_TO',
                    'message' => 'date_to debe tener formato YYYY-MM-DD',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }
            $filters['date_to'] = $request->date_to;
        }

        // accion, entidad (sin validación estricta, se usan como strings)
        if ($request->has('accion') && $request->accion !== '') {
            $filters['accion'] = $request->accion;
        }

        if ($request->has('entidad') && $request->entidad !== '') {
            $filters['entidad'] = $request->entidad;
        }

        // Llamar al servicio de consulta
        $results = $this->auditQueryService->search($filters);

        return response()->json([
            'ok' => true,
            'data' => $results,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Validar formato de fecha YYYY-MM-DD
     */
    private function validateDateFormat(string $date): bool
    {
        $date = trim($date);
        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) === 1;
    }

    /**
     * Obtener detalles del usuario por ID
     */
    private function getUserDetails(?int $userId)
    {
        if (! $userId) {
            return null;
        }

        try {
            return DB::connection('pgsql')
                ->table('selemti.users')
                ->select('id', 'username', 'nombre_completo')
                ->where('id', $userId)
                ->first();
        } catch (\Exception $e) {
            return null;
        }
    }
}
