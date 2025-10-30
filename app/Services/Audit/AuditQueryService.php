<?php

namespace App\Services\Audit;

use Illuminate\Support\Facades\DB;

/**
 * Servicio para consultas de auditoría (sólo lectura)
 * 
 * Este servicio permite buscar en la tabla de logs de auditoría 
 * de forma segura y filtrada, sin exponer datos sensibles.
 */
class AuditQueryService
{
    /**
     * Buscar registros en el log de auditoría
     * 
     * @param array $filters Filtros de búsqueda (todos opcionales)
     * @return array Array de registros de auditoría
     * 
     * Filtros soportados:
     * - user_id (int)
     * - accion (string exacta)
     * - entidad (string)
     * - entidad_id (int)
     * - date_from (YYYY-MM-DD)
     * - date_to (YYYY-MM-DD)
     * 
     * TODO: Incluir payload_json detrás de permiso auditoría avanzada
     */
    public function search(array $filters): array
    {
        $query = DB::connection('pgsql')->table('selemti.audit_log')
            ->select([
                'id',
                'timestamp',
                'user_id',
                'accion',
                'entidad',
                'entidad_id',
                'motivo',
                'evidencia_url',
                'payload_json',
            ]);

        // Aplicar filtros
        if (isset($filters['user_id']) && $filters['user_id'] !== '') {
            $query->where('user_id', (int)$filters['user_id']);
        }

        if (isset($filters['accion']) && $filters['accion'] !== '') {
            $query->where('accion', $filters['accion']);
        }

        if (isset($filters['entidad']) && $filters['entidad'] !== '') {
            $query->where('entidad', $filters['entidad']);
        }

        if (isset($filters['entidad_id']) && $filters['entidad_id'] !== '') {
            $query->where('entidad_id', (int)$filters['entidad_id']);
        }

        if (isset($filters['date_from']) && $filters['date_from'] !== '') {
            $query->whereDate('timestamp', '>=', $filters['date_from']);
        }

        if (isset($filters['date_to']) && $filters['date_to'] !== '') {
            $query->whereDate('timestamp', '<=', $filters['date_to']);
        }

        $results = $query->orderBy('timestamp', 'desc')->get();

        // Transformar resultados al formato esperado
        return $results->map(function ($row) {
            $payload = [];

            if (!empty($row->payload_json)) {
                $decoded = json_decode($row->payload_json, true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                    $payload = $decoded;
                }
            }

            return [
                'id'            => (int)$row->id,
                'timestamp'     => $row->timestamp,
                'user_id'       => (int)$row->user_id,
                'accion'        => $row->accion,
                'entidad'       => $row->entidad,
                'entidad_id'    => (int)$row->entidad_id,
                'motivo'        => $row->motivo,
                'evidencia_url' => $row->evidencia_url,
                'requires_investigation' => (bool)($payload['requires_investigation'] ?? false),
                'tolerancia_fuera' => (bool)($payload['tolerancia_fuera'] ?? false),
                'payload' => $payload,
            ];
        })->toArray();
    }
}
