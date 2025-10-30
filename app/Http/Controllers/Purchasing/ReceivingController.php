<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Inventory\ReceivingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador de recepciones de compra expuesto vía API REST.
 */
class ReceivingController extends Controller
{
    public function __construct(
        protected ReceivingService $receivingService,
        private AuditLogService $auditLogService
    )
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);
    }

    /**
     * Crea una recepción en borrador a partir de una orden de compra.
     *
     * @route POST /api/purchasing/receptions/create-from-po/{purchase_order_id}
     * @param int $purchase_order_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar request y mapear datos de PO a recepción antes de invocar el servicio.
     */
    public function createFromPO(int $purchase_order_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.create
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->receivingService->createDraftReception($purchase_order_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción creada a partir de la orden de compra.',
        ]);
    }

    /**
     * Captura o actualiza las líneas físicas recibidas.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/lines
     * @param int $recepcion_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar estructura de `lines` y aplicar form requests.
     */
    public function setLines(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.lines
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $lineItems = $request->input('lines', []);
        $lineItems = is_array($lineItems) ? $lineItems : [];

        $data = $this->receivingService->updateReceptionLines($recepcion_id, $lineItems, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Líneas de recepción guardadas.',
        ]);
    }

    /**
     * Valida una recepción aplicando tolerancias y banderas de aprobación.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/validate
     * @param int $recepcion_id
     * @param Request $request
     * @return JsonResponse
     * @todo Integrar policies y auditoría de usuarios que validan.
     */
    public function validateReception(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.validate
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $data = $this->receivingService->validateReception($recepcion_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción validada.',
        ]);
    }

    /**
     * Autoriza una recepción fuera de tolerancia para permitir el posteo.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/approve
     * @param int $recepcion_id
     * @param Request $request
     * @return JsonResponse
     * @todo Registrar auditoría de aprobaciones y adjuntar comentarios.
     */
    public function approve(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO: autorización inventory.receptions.override_tolerance
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;

        // Validar que el motivo sea obligatorio para operaciones críticas
        if (empty(trim($request->input('motivo', '')))) {
            return response()->json([
                'ok' => false,
                'error' => 'MOTIVO_REQUIRED',
                'message' => 'Motivo es obligatorio para autorizar recepción fuera de tolerancia.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->receivingService->approveReception($recepcion_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'RECEPTION_APPROVE',
            'recepcion',
            $recepcion_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción autorizada fuera de tolerancia.',
        ]);
    }

    /**
     * Muestra el detalle de una recepción para monitoreo operativo.
     *
     * @route GET /api/purchasing/receptions/{recepcion_id}
     * @param int $recepcion_id
     * @return JsonResponse
     * @todo Implementar policies inventory.receptions.view y formatear datos para UI.
     */
    public function show(int $recepcion_id): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.view
        $data = $this->receivingService->getReception($recepcion_id);

        return response()->json([
            'ok' => true,
            'data' => $data,
        ]);
    }

    /**
     * Postea una recepción validada al Kardex definitivo.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/post
     * @param int $recepcion_id
     * @param Request $request
     * @return JsonResponse
     * @todo Manejar errores de estado inválido y devolver códigos adecuados.
     */
    public function postReception(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.post
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;

        // Validar que el motivo sea obligatorio para operaciones críticas
        if (empty(trim($request->input('motivo', '')))) {
            return response()->json([
                'ok' => false,
                'error' => 'MOTIVO_REQUIRED',
                'message' => 'Motivo es obligatorio para postear recepción.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->receivingService->postToInventory($recepcion_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'RECEPTION_POST',
            'recepcion',
            $recepcion_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Recepción posteada al inventario.',
        ]);
    }

    /**
     * Aplica costeo final a una recepción previamente posteada.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/costing
     * @param int $recepcion_id
     * @param Request $request
     * @return JsonResponse
     * @todo Integrar validaciones de finanzas y bloquear acceso sin rol apropiado.
     */
    public function finalizeCosting(int $recepcion_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.receptions.cost_finalize
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;

        // Validar que el motivo sea obligatorio para operaciones críticas
        if (empty(trim($request->input('motivo', '')))) {
            return response()->json([
                'ok' => false,
                'error' => 'MOTIVO_REQUIRED',
                'message' => 'Motivo es obligatorio para aplicar costeo final.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->receivingService->finalizeCosting($recepcion_id, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Costeo final aplicado.',
        ]);
    }
}
