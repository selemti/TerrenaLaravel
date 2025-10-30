<?php

namespace App\Http\Controllers\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Inventory\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador REST para transferencias internas de inventario.
 */
class TransferController extends Controller
{
    public function __construct(
        protected TransferService $transferService,
        private AuditLogService $auditLogService
    )
    {
        $this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);
    }

    /**
     * Obtiene el detalle de una transferencia (mock por ahora).
     *
     * @route GET /api/inventory/transfers/{transfer_id}
     * @param int $transfer_id
     * @return JsonResponse
     * @todo Autorización inventory.transfers.view
     * @todo Cargar datos reales desde TransferService
     */
    public function show(int $transfer_id): JsonResponse
    {
        // TODO: autorización inventory.transfers.view
        // TODO: Cargar datos reales desde TransferService
        return response()->json([
            'ok' => true,
            'data' => [
                'transfer_id' => $transfer_id,
                'estado' => 'EN_CAMINO',
                'origen_nombre' => 'Bodega Central',
                'destino_nombre' => 'Sucursal Reforma',
                'lineas' => [
                    [
                        'item_id' => 45,
                        'item_nombre' => 'Papas saco 20kg',
                        'qty_enviada' => '5.000000',
                        'qty_recibida' => '0.000000',
                        'uom' => 'KG',
                    ],
                ],
            ],
        ]);
    }

    /**
     * Crea una transferencia solicitada entre almacenes.
     *
     * @route POST /api/inventory/transfers/create
     * @param Request $request
     * @return JsonResponse
     * @todo Validar payload vía FormRequest y manejar errores de input.
     */
    public function create(Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.transfers.create
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $from = (int) $request->input('from_almacen_id');
        $to = (int) $request->input('to_almacen_id');
        $lines = $request->input('lines', []);
        $lines = is_array($lines) ? $lines : [];

        $data = $this->transferService->createTransfer($from, $to, $lines, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Transferencia solicitada.',
        ]);
    }

    /**
     * Aprueba una transferencia pendiente.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/approve
     * @param int $transfer_id
     * @param Request $request
     * @return JsonResponse
     * @todo Añadir logging de aprobación y comentarios operativos.
     */
    public function approve(int $transfer_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.transfers.approve
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
                'message' => 'Motivo es obligatorio para aprobar transferencia.',
            ], 422);
        }

        $data = $this->transferService->approveTransfer($transfer_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'TRANSFER_APPROVE',
            'transfer',
            $transfer_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Transferencia aprobada.',
        ]);
    }

    /**
     * Marca la transferencia como enviada desde el almacén origen.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/ship
     * @param int $transfer_id
     * @param Request $request
     * @return JsonResponse
     * @todo Registrar información de logística (operador, unidad, placas).
     */
    public function ship(int $transfer_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.transfers.ship
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
                'message' => 'Motivo es obligatorio para marcar transferencia como enviada.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->transferService->markInTransit($transfer_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'TRANSFER_SHIP',
            'transfer',
            $transfer_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Transferencia en tránsito.',
        ]);
    }

    /**
     * Confirma las cantidades recibidas en destino.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/receive
     * @param int $transfer_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar que `lines` incluya lote y diferencias máximas permitidas.
     */
    public function receive(int $transfer_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.transfers.receive
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
                'message' => 'Motivo es obligatorio para confirmar recepción de transferencia.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $receivedLines = $request->input('lines', []);
        $receivedLines = is_array($receivedLines) ? $receivedLines : [];

        $data = $this->transferService->receiveTransfer($transfer_id, $receivedLines, $userId);

        $this->auditLogService->logAction(
            $userId,
            'TRANSFER_RECEIVE',
            'transfer',
            $transfer_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Transferencia recibida en destino.',
        ]);
    }

    /**
     * Postea la transferencia en Kardex generando TRANSFER_OUT/IN.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/post
     * @param int $transfer_id
     * @param Request $request
     * @return JsonResponse
     * @todo Manejar errores cuando ya existan movimientos asociados.
     */
    public function post(int $transfer_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso inventory.transfers.post
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
                'message' => 'Motivo es obligatorio para postear transferencia.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->transferService->postTransferToInventory($transfer_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'TRANSFER_POST',
            'transfer',
            $transfer_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Transferencia posteada a inventario (transfer out/in).',
        ]);
    }
}
