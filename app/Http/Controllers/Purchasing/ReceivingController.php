<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador de recepciones de compra.
 *
 * Pendiente: implementar contra ReceptionService una vez definida la
 * integración purchasing PO → recepción de inventario.
 */
class ReceivingController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);
    }

    public function createFromPO(int $purchase_order_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    public function setLines(int $recepcion_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    public function validateReception(int $recepcion_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    public function approve(int $recepcion_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    public function show(int $recepcion_id): JsonResponse
    {
        return $this->notImplemented();
    }

    public function postReception(int $recepcion_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    public function finalizeCosting(int $recepcion_id, Request $request): JsonResponse
    {
        return $this->notImplemented();
    }

    private function notImplemented(): JsonResponse
    {
        return response()->json([
            'ok' => false,
            'error' => 'not_implemented',
            'message' => 'Receiving workflow pending ReceptionService integration.',
        ], 501);
    }
}
