<?php

namespace App\Services\Caja;

use Illuminate\Support\Facades\DB;

/**
 * Service for managing alerts in the Caja system
 *
 * Handles creation and retrieval of alerts for postcorte approval workflow
 */
class AlertasService
{
    /**
     * Create alert when postcorte requires approval
     */
    public function crearAlertaAprobacion(int $postcorteId, int $sesionId): void
    {
        // Get all users with permission to approve irregular cortes
        $userIds = $this->getUsersWithPermission('aprobar-cortes-irregulares');

        // Create alert for each authorized user
        foreach ($userIds as $userId) {
            DB::connection('pgsql')->table('selemti.alertas_cortes')->insert([
                'postcorte_id' => $postcorteId,
                'sesion_id' => $sesionId,
                'tipo' => 'REQUIERE_APROBACION',
                'destinatario_id' => $userId,
                'leida' => false,
                'creada_en' => now(),
            ]);
        }
    }

    /**
     * Create alert when postcorte is approved
     */
    public function crearAlertaAprobado(int $postcorteId, int $sesionId, int $cajeroUsuarioId): void
    {
        DB::connection('pgsql')->table('selemti.alertas_cortes')->insert([
            'postcorte_id' => $postcorteId,
            'sesion_id' => $sesionId,
            'tipo' => 'APROBADO',
            'destinatario_id' => $cajeroUsuarioId,
            'leida' => false,
            'creada_en' => now(),
        ]);
    }

    /**
     * Create alert when postcorte is rejected
     */
    public function crearAlertaRechazado(int $postcorteId, int $sesionId, int $cajeroUsuarioId): void
    {
        DB::connection('pgsql')->table('selemti.alertas_cortes')->insert([
            'postcorte_id' => $postcorteId,
            'sesion_id' => $sesionId,
            'tipo' => 'RECHAZADO',
            'destinatario_id' => $cajeroUsuarioId,
            'leida' => false,
            'creada_en' => now(),
        ]);
    }

    /**
     * Get pending alerts for a specific user
     */
    public function obtenerAlertasPendientes(int $userId): array
    {
        $alertas = DB::connection('pgsql')
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
                'p.declarado_efectivo',
                'p.diferencia_efectivo',
            ])
            ->where('a.destinatario_id', $userId)
            ->where('a.leida', false)
            ->orderBy('a.creada_en', 'desc')
            ->get()
            ->toArray();

        return $alertas;
    }

    /**
     * Get count of pending alerts for a user
     */
    public function contarAlertasPendientes(int $userId): int
    {
        return DB::connection('pgsql')
            ->table('selemti.alertas_cortes')
            ->where('destinatario_id', $userId)
            ->where('leida', false)
            ->count();
    }

    /**
     * Mark an alert as read
     */
    public function marcarLeida(int $alertaId): bool
    {
        $updated = DB::connection('pgsql')
            ->table('selemti.alertas_cortes')
            ->where('id', $alertaId)
            ->update([
                'leida' => true,
                'leida_en' => now(),
            ]);

        return $updated > 0;
    }

    /**
     * Mark all alerts for a postcorte as read
     */
    public function marcarLeidasPorPostcorte(int $postcorteId, int $userId): void
    {
        DB::connection('pgsql')
            ->table('selemti.alertas_cortes')
            ->where('postcorte_id', $postcorteId)
            ->where('destinatario_id', $userId)
            ->where('leida', false)
            ->update([
                'leida' => true,
                'leida_en' => now(),
            ]);
    }

    /**
     * Get all users with a specific permission
     */
    private function getUsersWithPermission(string $permissionName): array
    {
        // Get permission ID
        $permission = DB::connection('pgsql')
            ->table('selemti.permissions')
            ->where('name', $permissionName)
            ->first();

        if (! $permission) {
            return [];
        }

        // Get roles that have this permission
        $roleIds = DB::connection('pgsql')
            ->table('selemti.role_has_permissions')
            ->where('permission_id', $permission->id)
            ->pluck('role_id')
            ->toArray();

        if (empty($roleIds)) {
            return [];
        }

        // Get users that have these roles
        $userIds = DB::connection('pgsql')
            ->table('selemti.model_has_roles')
            ->whereIn('role_id', $roleIds)
            ->where('model_type', 'App\\Models\\User')
            ->pluck('model_id')
            ->unique()
            ->toArray();

        return $userIds;
    }
}
