<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

// ============ HEALTH CHECK ============

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        try {
            DB::select('SELECT 1');
            
            return response()->json([
                'ok' => true,
                'db' => 'ok',
                'port' => config('database.connections.pgsql.port', 5432)
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en health check: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'db',
                'message' => config('app.debug') ? $e->getMessage() : 'Error de conexión'
            ], 500);
        }
    }

    /**
     * Alias para compatibilidad legacy
     */
    public function ping(): JsonResponse
    {
        return $this->check();
    }
}