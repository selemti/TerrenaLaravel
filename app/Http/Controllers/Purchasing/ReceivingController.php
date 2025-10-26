<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Services\Inventory\ReceivingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReceivingController extends Controller
{
    public function __construct(protected ReceivingService $receivingService)
    {
    }

    public function createFromPO(int $purchase_order_id, Request $request): JsonResponse
    {
        // TODO: autorización por permiso inventory.receptions.*
        $userId = (int) ($request->user()->id ?? $request->input('user_id'));
        $data = $this->receivingService->createDraftReception($purchase_order_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción creada a partir de la orden de compra.',
        ]);
    }

    public function setLines(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO: autorización por permiso inventory.receptions.*
        $userId = (int) ($request->user()->id ?? $request->input('user_id'));
        $lineItems = $request->input('lines', []);
        $lineItems = is_array($lineItems) ? $lineItems : [];

        $data = $this->receivingService->updateReceptionLines($recepcion_id, $lineItems, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Líneas de recepción guardadas.',
        ]);
    }

    public function validateReception(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO: autorización por permiso inventory.receptions.validate
        $userId = (int) ($request->user()->id ?? $request->input('user_id'));
        $data = $this->receivingService->validateReception($recepcion_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción validada.',
        ]);
    }

    public function postReception(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO: autorización por permiso inventory.receptions.post
        $userId = (int) ($request->user()->id ?? $request->input('user_id'));
        $data = $this->receivingService->postToInventory($recepcion_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción posteada al inventario.',
        ]);
    }
}
