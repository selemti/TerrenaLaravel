<?php

namespace App\Http\Controllers\Audit;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LogController extends Controller
{
    /**
     * Mostrar la vista principal de auditoría
     */
    public function index()
    {
        $logs = DB::connection('pgsql')
            ->table('selemti.audit_log')
            ->orderByDesc('timestamp')
            ->limit(100)
            ->get()
            ->map(function ($log) {
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
                    'payload_json_decoded' => ! empty($log->payload_json) ? json_decode($log->payload_json, true) : null,
                ];
            });

        return view('audit.logs', ['logs' => $logs]);
    }

    /**
     * Listar registros de auditoría con filtros
     */
    public function list(Request $request): JsonResponse
    {
        $query = AuditLog::query()
            ->with('user:id,nombre_completo,username')
            ->orderByDesc('timestamp');

        // Aplicar filtros
        if ($request->filled('desde')) {
            $query->whereDate('timestamp', '>=', $request->desde);
        }

        if ($request->filled('hasta')) {
            $query->whereDate('timestamp', '<=', $request->hasta);
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->filled('module')) {
            $query->where('entidad', $request->module);
        }

        if ($request->filled('search')) {
            $search = strtolower(trim($request->search));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(accion) ILIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(entidad_id::text) ILIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(motivo) ILIKE ?', ["%{$search}%"])
                    ->orWhereHas('user', function ($subQuery) use ($search) {
                        $subQuery->whereRaw('LOWER(nombre_completo) ILIKE ?', ["%{$search}%"])
                            ->orWhereRaw('LOWER(username) ILIKE ?', ["%{$search}%"]);
                    });
            });
        }

        // Paginar resultados
        $logs = $query->paginate(50);

        // Formatear datos para la vista
        $formattedLogs = $logs->through(function ($log) {
            return [
                'id' => $log->id,
                'timestamp' => $log->timestamp->format('Y-m-d H:i:s'),
                'username' => $log->user?->username ?? '—',
                'user_full_name' => $log->user?->nombre_completo ?? '—',
                'module' => $log->module_name,
                'action' => $log->accion,
                'entity' => $log->entity_description,
                'entity_type' => $log->entidad,
                'entity_id' => $log->entidad_id,
                'reason' => $log->motivo,
                'evidence_url' => $log->evidencia_url,
                'has_payload' => ! empty($log->payload_json),
            ];
        });

        return response()->json($formattedLogs);
    }

    /**
     * Mostrar detalle de un registro específico
     */
    public function show(int $id): JsonResponse
    {
        $log = AuditLog::with('user')->findOrFail($id);

        return response()->json([
            'id' => $log->id,
            'timestamp' => $log->timestamp->format('Y-m-d H:i:s'),
            'user' => [
                'id' => $log->user?->id,
                'username' => $log->user?->username,
                'full_name' => $log->user?->nombre_completo,
            ],
            'module' => $log->module_name,
            'action' => $log->accion,
            'entity' => $log->entity_description,
            'entity_type' => $log->entidad,
            'entity_id' => $log->entidad_id,
            'reason' => $log->motivo,
            'evidence_url' => $log->evidencia_url,
            'payload' => $log->payload_json,
        ]);
    }

    /**
     * Listar usuarios para filtros
     */
    public function users(): JsonResponse
    {
        $users = \App\Models\User::query()
            ->select('id', 'username', 'nombre_completo')
            ->orderBy('nombre_completo')
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'username' => $user->username,
                    'full_name' => $user->nombre_completo,
                ];
            });

        return response()->json($users);
    }

    /**
     * Listar módulos disponibles
     */
    public function modules(): JsonResponse
    {
        $modules = \Illuminate\Support\Facades\DB::connection('pgsql')
            ->table('selemti.audit_log')
            ->select('entidad')
            ->distinct()
            ->whereNotNull('entidad')
            ->orderBy('entidad')
            ->pluck('entidad')
            ->toArray();

        // Agregar módulos conocidos incluso si no hay registros aún
        $knownModules = [
            'inventario',
            'transferencia',
            'pos',
            'caja_chica',
            'recetas',
            'produccion',
        ];

        $allModules = array_unique(array_merge($modules, $knownModules));
        sort($allModules);

        return response()->json($allModules);
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
        } catch (\Throwable $e) {
            return null;
        }
    }
}
