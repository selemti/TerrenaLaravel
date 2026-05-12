<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Services\Purchasing\ReturnService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReturnController extends Controller
{
    public function __construct(protected ReturnService $returnService)
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);
    }

    public function createFromPO(int $purchase_order_id, Request $request): JsonResponse
    {
        try {
            $data = $this->returnService->createDraftReturn($purchase_order_id, (int) auth()->id());

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Devolución al proveedor creada en borrador.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'create_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function approve(int $return_id, Request $request): JsonResponse
    {
        try {
            $data = $this->returnService->approveReturn($return_id, (int) auth()->id());

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Devolución aprobada.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'approve_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function ship(int $return_id, Request $request): JsonResponse
    {
        try {
            $tracking = $request->input('tracking', []);
            $data = $this->returnService->markShipped($return_id, is_array($tracking) ? $tracking : [], (int) auth()->id());

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Devolución marcada en tránsito.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'ship_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function confirm(int $return_id, Request $request): JsonResponse
    {
        try {
            $data = $this->returnService->confirmVendorReceived($return_id, (int) auth()->id());

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Proveedor confirmó recepción.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'confirm_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function post(int $return_id, Request $request): JsonResponse
    {
        try {
            $data = $this->returnService->postInventoryAdjustment($return_id, (int) auth()->id());

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Devolución posteada a inventario.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'post_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function creditNote(int $return_id, Request $request): JsonResponse
    {
        try {
            $data = $this->returnService->attachCreditNote(
                $return_id,
                $request->only(['folio', 'monto', 'fecha', 'observaciones']),
                (int) auth()->id()
            );

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Nota de crédito registrada.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'credit_note_error', 'message' => $e->getMessage()], 422);
        }
    }
}
