<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class SesionesController extends Controller
{
    public function getActiva(Request $request): JsonResponse
    {
        $terminalId = $request->query('terminal_id');
        $usuarioId = $request->query('usuario_id');
        if (!$terminalId || !$usuarioId) {
            return response()->json(['ok' => false, 'error' => 'missing_params'], 400);
        }

        try {
            $sql = "
                SELECT *
                FROM selemti.sesion_cajon
                WHERE terminal_id = ? AND cajero_usuario_id = ?
                  AND estatus IN ('ACTIVA', 'LISTO_PARA_CORTE')
                ORDER BY apertura_ts DESC
                LIMIT 1
            ";
            $sesion = DB::selectOne($sql, [$terminalId, $usuarioId]);

            if (!$sesion) {
                return response()->json(['ok' => false, 'error' => 'sesion_not_found'], 404);
            }

            return response()->json([
                'ok' => true,
                'sesion' => [
                    'id' => (int) $sesion->id,
                    'terminal_id' => (int) $sesion->terminal_id,
                    'cajero_usuario_id' => (int) $sesion->cajero_usuario_id,
                    'apertura_ts' => $sesion->apertura_ts,
                    'cierre_ts' => $sesion->cierre_ts,
                    'estatus' => $sesion->estatus,
                    'opening_float' => (float) $sesion->opening_float,
                    'closing_float' => (float) $sesion->closing_float,
                ],
            ]);
        } catch (\Exception $e) {
            \Log::error("Error en getActiva (terminal_id: $terminalId, usuario_id: $usuarioId): " . $e->getMessage());
            return response()->json(['ok' => false, 'error' => 'server_error', 'detail' => $e->getMessage()], 500);
        }
    }
}