<?php

namespace App\Http\Controllers\Api\Caja;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

// ============ FORMAS DE PAGO ============

class FormasPagoController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $formas = DB::table('selemti.formas_pago')
                ->where('activo', true)
                ->orderBy('prioridad')
                ->orderBy('id')
                ->get([
                    'id', 'codigo', 'payment_type', 'transaction_type', 'payment_sub_type',
                    'custom_name', 'custom_ref', 'activo', 'prioridad', 'created_at'
                ]);

            return response()->json([
                'ok' => true,
                'items' => $formas->toArray()
            ]);

        } catch (\Exception $e) {
            \Log::error("Error en formas de pago: " . $e->getMessage());
            return response()->json([
                'ok' => false,
                'error' => 'server_error',
                'message' => config('app.debug') ? $e->getMessage() : 'Error al obtener formas de pago'
            ], 500);
        }
    }

    /**
     * Alias para compatibilidad legacy
     */
    public function listar(): JsonResponse
    {
        return $this->index();
    }
}
