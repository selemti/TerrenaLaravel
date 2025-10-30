<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware de control de permisos por acción crítica.
 *
 * Uso esperado en rutas:
 *   ->middleware('perm:inventory.receptions.post')
 *
 * Política actual (Sprint 1.9):
 * - No hacemos aún verificación real en BD.
 * - Solo validamos que:
 *   a) haya un usuario autenticado (o pasado explícitamente en la request),
 *   b) el permiso requerido venga en el middleware param.
 *
 * Próxima fase:
 * - Amarrar con tabla de permisos/roles interna (selemti.users + permisos tipo purchasing.*, inventory.*).
 * - Integrar esto con Gate/Policies si decidimos formalizarlo vía Laravel.
 */
class CheckPermission
{
    /**
     * Maneja la autorización basada en permisos declarativos.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  $requiredPermission  Ej: "inventory.receptions.post"
     */
    public function handle(Request $request, Closure $next, string $requiredPermission): Response
    {
        // 🔐 Paso 1: identificar usuario
        // Nota: en producción esto debe venir de auth real (JWT / session).
        // Para ambiente actual (desarrollo), aceptamos:
        //   - $request->user()
        //   - o, si no existe user(), un user_id manual pasado en body/query.
        $user = $request->user();
        $userIdFromRequest = $request->input('user_id');

        if (!$user && !$userIdFromRequest) {
            return response()->json([
                'ok' => false,
                'error' => 'UNAUTHENTICATED',
                'message' => 'Usuario no autenticado.',
            ], 401);
        }

        // 🔐 Paso 2: validación de permiso (stub)
        // Aquí debería ir la verificación real:
        //   doesUserHave($user->id, $requiredPermission)
        //
        // Por ahora Sprint 1.9 = modo permisivo:
        // - Permitimos TODO si hay usuario (o user_id).
        // - PERO respondemos el permiso requerido en la respuesta
        //   para que quede trazado en logs/front.
        //
        // Si quisieras endurecer esto rápido:
        //   - mete una lista de permisos bloqueados aquí y responde 403.
        //   - ej: if (in_array($requiredPermission, ['inventory.receptions.post'])) { ... }
        //
        // Nota: dejamos esto abierto para la siguiente fase.

        // 👌 Paso 3: continuar
        // Inyectamos en la request el permiso requerido, para logging aguas abajo
        // (no es obligatorio, pero es útil si el Controller quiere auditar).
        $request->attributes->set('requiredPermission', $requiredPermission);
        $request->attributes->set('effectiveUserId', $user?->id ?? $userIdFromRequest);

        return $next($request);
    }
}
