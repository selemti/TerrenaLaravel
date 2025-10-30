<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Services\Purchasing\ReturnService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador REST para devoluciones a proveedores.
 */
class ReturnController extends Controller
{
    public function __construct(protected ReturnService $returnService)
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);
    }

    /**
     * Crea una devolución en borrador a partir de una PO.
     *
     * @route POST /api/purchasing/returns/create-from-po/{purchase_order_id}
     * @param int $purchase_order_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar la PO antes de crear la devolución.
     */
    public function createFromPO(int $purchase_order_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.create
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->returnService->createDraftReturn($purchase_order_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Devolución al proveedor creada en borrador.',
        ]);
    }

    /**
     * Aprueba una devolución y bloquea cambios de cabecera.
     *
     * @route POST /api/purchasing/returns/{return_id}/approve
     * @param int $return_id
     * @param Request $request
     * @return JsonResponse
     * @todo Registrar auditoría completa de la aprobación.
     */
    public function approve(int $return_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.approve
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->returnService->approveReturn($return_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Devolución aprobada.',
        ]);
    }

    /**
     * Marca la devolución como enviada y almacena tracking.
     *
     * @route POST /api/purchasing/returns/{return_id}/ship
     * @param int $return_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar estructura del array tracking y soportar adjuntos.
     */
    public function ship(int $return_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.ship
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $trackingInfo = $request->input('tracking', []);
        $trackingInfo = is_array($trackingInfo) ? $trackingInfo : [];

        $data = $this->returnService->markShipped($return_id, $trackingInfo, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Devolución marcada en tránsito.',
        ]);
    }

    /**
     * Confirma que el proveedor recibió el material devuelto.
     *
     * @route POST /api/purchasing/returns/{return_id}/confirm
     * @param int $return_id
     * @param Request $request
     * @return JsonResponse
     * @todo Adjuntar evidencia (PDF/Fotos) de la recepción del proveedor.
     */
    public function confirm(int $return_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.receive
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->returnService->confirmVendorReceived($return_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Proveedor confirmó recepción.',
        ]);
    }

    /**
     * Genera los movimientos negativos y avanza a nota de crédito.
     *
     * @route POST /api/purchasing/returns/{return_id}/post
     * @param int $return_id
     * @param Request $request
     * @return JsonResponse
     * @todo Manejar rollback transaccional si fallan los movimientos.
     */
    public function post(int $return_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.post
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->returnService->postInventoryAdjustment($return_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Devolución posteada a inventario (movimientos negativos).',
        ]);
    }

    /**
     * Registra la nota de crédito del proveedor y cierra la devolución.
     *
     * @route POST /api/purchasing/returns/{return_id}/credit-note
     * @param int $return_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar formato de folio y fechas antes de guardar.
     */
    public function creditNote(int $return_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso purchasing.returns.credit_note
        $userId = (int) ($request->user()->id ?? $request->input('user_id'));
        $notaCreditoData = $request->only(['folio', 'monto', 'fecha', 'observaciones']);

        $data = $this->returnService->attachCreditNote($return_id, $notaCreditoData, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Nota de crédito registrada.',
        ]);
    }
}
