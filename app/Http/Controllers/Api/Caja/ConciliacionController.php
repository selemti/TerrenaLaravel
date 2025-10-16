<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

// ============ CONCILIACIÓN ============

class ConciliacionController extends Controller
{
    public function getBySesion(Request $request, int $sesionId): JsonResponse
    {
        try {
            $conciliacion = DB::selectOne("
                SELECT * 
                FROM selemti.vw_conciliacion_sesion 
                WHERE sesion_id = ?
            ", [$sesionId]);

            if (!$conciliacion) {
                return response()->json([
                    'ok' => false,
                    'error' => 'not_found'
                ], 404);
            }

            return response()->json([
                'ok' => true,
                'data' => (array) $conciliacion
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en conciliacion por sesion {$sesionId}: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'view_missing',
                'message' => config('app.debug') ? $e->getMessage() : 'Error al obtener conciliación'
            ], 500);
        }
    }
}


