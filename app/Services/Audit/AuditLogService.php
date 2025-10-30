<?php

namespace App\Services\Audit;

use Illuminate\Support\Facades\DB;

class AuditLogService
{
    public function logAction(
        int $userId,
        string $accion,
        string $entidad,
        int $entidadId,
        string $motivo = '',
        ?string $evidenciaUrl = null,
        array $payload = []
    ): void {
        if ($userId <= 0) {
            throw new \InvalidArgumentException('userId inválido en logAction()');
        }

        if (empty(trim($accion)) || empty(trim($entidad))) {
            throw new \InvalidArgumentException('acción o entidad vacía');
        }

        DB::connection('pgsql')
            ->table('selemti.audit_log')
            ->insert([
                'timestamp'     => now(),
                'user_id'       => $userId,
                'accion'        => $accion,
                'entidad'       => $entidad,
                'entidad_id'    => $entidadId,
                'motivo'        => $motivo,
                'evidencia_url' => $evidenciaUrl,
                'payload_json'  => json_encode($payload),
            ]);
    }
}
