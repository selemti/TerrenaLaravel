<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Services\Inventory\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;
use RuntimeException;

/**
 * API REST para gestión de transferencias entre almacenes
 *
 * Flujo completo: SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA
 *
 * @version 1.0 - Sprint 1 (INV-003)
 */
class TransferController extends Controller
{
    protected TransferService $transferService;

    public function __construct(TransferService $transferService)
    {
        $this->transferService = $transferService;
    }

    /**
     * Listar transferencias con filtros
     *
     * GET /api/inventory/transfers
     *
     * Query params:
     * - estado: string (SOLICITADA, APROBADA, EN_TRANSITO, RECIBIDA, POSTEADA, CANCELADA)
     * - origen_almacen_id: int
     * - destino_almacen_id: int
     * - fecha_desde: date (Y-m-d)
     * - fecha_hasta: date (Y-m-d)
     */
    public function index(Request $request): JsonResponse
    {
        // TODO: Implementar filtros y paginación
        // Por ahora retorna estructura básica
        return response()->json([
            'success' => true,
            'message' => 'Endpoint de listado en construcción',
            'data' => [],
            'meta' => [
                'total' => 0,
                'per_page' => 15,
                'current_page' => 1,
            ],
        ]);
    }

    /**
     * Crear nueva transferencia en estado SOLICITADA
     *
     * POST /api/inventory/transfers
     *
     * Body:
     * {
     *   "origen_almacen_id": 1,
     *   "destino_almacen_id": 2,
     *   "lineas": [
     *     {
     *       "item_id": "ITEM-001",
     *       "cantidad": 10,
     *       "unidad_medida": "UND",
     *       "observaciones": "..."
     *     }
     *   ],
     *   "observaciones": "Transferencia urgente"
     * }
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'origen_almacen_id' => 'required|integer|min:1',
                'destino_almacen_id' => 'required|integer|min:1|different:origen_almacen_id',
                'lineas' => 'required|array|min:1',
                'lineas.*.item_id' => 'required|string',
                'lineas.*.cantidad' => 'required|numeric|min:0.001',
                'lineas.*.unidad_medida' => 'required|string',
                'lineas.*.observaciones' => 'nullable|string',
                'observaciones' => 'nullable|string',
            ]);

            $userId = auth()->id() ?? 1; // TODO: Usar auth real

            $result = $this->transferService->createTransfer(
                $validated['origen_almacen_id'],
                $validated['destino_almacen_id'],
                $validated['lineas'],
                $userId
            );

            return response()->json([
                'success' => true,
                'message' => 'Transferencia creada exitosamente',
                'data' => $result,
            ], 201);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $e->errors(),
            ], 422);

        } catch (InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al crear transferencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Aprobar transferencia (SOLICITADA → APROBADA)
     *
     * POST /api/inventory/transfers/{id}/approve
     */
    public function approve(int $id, Request $request): JsonResponse
    {
        try {
            $userId = auth()->id() ?? 1; // TODO: Usar auth real

            $result = $this->transferService->approveTransfer($id, $userId);

            return response()->json([
                'success' => true,
                'message' => 'Transferencia aprobada exitosamente',
                'data' => $result,
            ]);

        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al aprobar transferencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Despachar transferencia (APROBADA → EN_TRANSITO)
     *
     * POST /api/inventory/transfers/{id}/dispatch
     *
     * Body:
     * {
     *   "numero_guia": "GUIA-12345"
     * }
     */
    public function dispatch(int $id, Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'numero_guia' => 'nullable|string|max:64',
            ]);

            $userId = auth()->id() ?? 1; // TODO: Usar auth real

            $result = $this->transferService->markInTransit(
                $id,
                $userId,
                $validated['numero_guia'] ?? null
            );

            return response()->json([
                'success' => true,
                'message' => 'Transferencia despachada exitosamente',
                'data' => $result,
            ]);

        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al despachar transferencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Recibir transferencia (EN_TRANSITO → RECIBIDA)
     *
     * POST /api/inventory/transfers/{id}/receive
     *
     * Body:
     * {
     *   "lineas": [
     *     {
     *       "line_id": 1,
     *       "cantidad_recibida": 9.5,
     *       "observaciones": "Faltó 0.5"
     *     }
     *   ],
     *   "observaciones_generales": "Todo OK"
     * }
     */
    public function receive(int $id, Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'lineas' => 'required|array|min:1',
                'lineas.*.line_id' => 'required|integer',
                'lineas.*.cantidad_recibida' => 'required|numeric|min:0',
                'lineas.*.observaciones' => 'nullable|string',
                'observaciones_generales' => 'nullable|string',
            ]);

            $userId = auth()->id() ?? 1; // TODO: Usar auth real

            $result = $this->transferService->receiveTransfer(
                $id,
                $validated['lineas'],
                $userId
            );

            return response()->json([
                'success' => true,
                'message' => 'Transferencia recibida exitosamente',
                'data' => $result,
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $e->errors(),
            ], 422);

        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al recibir transferencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Postear transferencia a inventario (RECIBIDA → POSTEADA)
     *
     * POST /api/inventory/transfers/{id}/post
     *
     * Genera:
     * - Movimiento de salida en almacén origen (TRASPASO_OUT)
     * - Movimiento de entrada en almacén destino (TRASPASO_IN)
     * - Actualiza estado a POSTEADA (irreversible)
     */
    public function post(int $id, Request $request): JsonResponse
    {
        try {
            $userId = auth()->id() ?? 1; // TODO: Usar auth real

            $result = $this->transferService->postTransferToInventory($id, $userId);

            return response()->json([
                'success' => true,
                'message' => 'Transferencia posteada a inventario exitosamente',
                'data' => $result,
            ]);

        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al postear transferencia',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
