<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Inventory\TransferHeader;
use App\Services\Inventory\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

/**
 * API REST Controller para transferencias internas entre almacenes.
 */
class TransferApiController extends Controller
{
    public function __construct(
        protected TransferService $transferService
    ) {
        $this->middleware(['auth:sanctum']);
    }

    /**
     * Lista transferencias con filtros opcionales.
     *
     * @route GET /api/inventory/transfers
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'creadaPor',
                'lineas.item'
            ]);

            // Filtros opcionales
            if ($request->has('estado')) {
                $query->where('estado', $request->estado);
            }

            if ($request->has('origen_almacen_id')) {
                $query->where('origen_almacen_id', $request->origen_almacen_id);
            }

            if ($request->has('destino_almacen_id')) {
                $query->where('destino_almacen_id', $request->destino_almacen_id);
            }

            if ($request->has('fecha_desde')) {
                $query->where('fecha_solicitada', '>=', $request->fecha_desde);
            }

            if ($request->has('fecha_hasta')) {
                $query->where('fecha_solicitada', '<=', $request->fecha_hasta);
            }

            // Scope especiales
            if ($request->has('pendientes') && $request->pendientes === 'true') {
                $query->pendientes();
            }

            if ($request->has('completadas') && $request->completadas === 'true') {
                $query->completadas();
            }

            $perPage = $request->get('per_page', 15);
            $transfers = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'ok' => true,
                'data' => $transfers,
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al obtener transferencias',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Crea una nueva transferencia en estado SOLICITADA.
     *
     * @route POST /api/inventory/transfers
     * @param Request $request
     * @return JsonResponse
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'origen_almacen_id' => 'required|integer|exists:selemti.almacenes,id',
                'destino_almacen_id' => 'required|integer|exists:selemti.almacenes,id|different:origen_almacen_id',
                'lines' => 'required|array|min:1',
                'lines.*.item_id' => 'required|integer|exists:selemti.items,id',
                'lines.*.cantidad' => 'required|numeric|min:0.0001',
                'lines.*.unidad_medida' => 'required|string|max:10',
                'lines.*.observaciones' => 'nullable|string|max:500',
                'observaciones' => 'nullable|string|max:1000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }

            $result = $this->transferService->createTransfer(
                $request->origen_almacen_id,
                $request->destino_almacen_id,
                $request->lines,
                $request->user()->id
            );

            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'lineas.item'
            ])->find($result['transfer_id']);

            return response()->json([
                'ok' => true,
                'message' => 'Transferencia creada exitosamente',
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ], 201);

        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al crear transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Obtiene el detalle de una transferencia específica.
     *
     * @route GET /api/inventory/transfers/{id}
     * @param int $id
     * @return JsonResponse
     */
    public function show(int $id): JsonResponse
    {
        try {
            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'creadaPor',
                'aprobadaPor',
                'despachadaPor',
                'recibidaPor',
                'posteadaPor',
                'lineas.item'
            ])->findOrFail($id);

            return response()->json([
                'ok' => true,
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'ok' => false,
                'message' => "Transferencia #{$id} no encontrada",
                'timestamp' => now()->toIso8601String(),
            ], 404);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al obtener transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Aprueba una transferencia (valida stock disponible).
     *
     * @route POST /api/inventory/transfers/{id}/approve
     * @param int $id
     * @param Request $request
     * @return JsonResponse
     */
    public function approve(int $id, Request $request): JsonResponse
    {
        try {
            $result = $this->transferService->approveTransfer(
                $id,
                $request->user()->id
            );

            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'aprobadaPor',
                'lineas.item'
            ])->find($id);

            return response()->json([
                'ok' => true,
                'message' => 'Transferencia aprobada exitosamente',
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al aprobar transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Marca la transferencia como EN_TRANSITO (despacho).
     *
     * @route POST /api/inventory/transfers/{id}/ship
     * @param int $id
     * @param Request $request
     * @return JsonResponse
     */
    public function ship(int $id, Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'numero_guia' => 'nullable|string|max:100',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }

            $result = $this->transferService->markInTransit(
                $id,
                $request->user()->id,
                $request->numero_guia
            );

            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'despachadaPor',
                'lineas.item'
            ])->find($id);

            return response()->json([
                'ok' => true,
                'message' => 'Transferencia despachada exitosamente',
                'data' => $transfer,
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al despachar transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Registra la recepción de la transferencia.
     *
     * @route POST /api/inventory/transfers/{id}/receive
     * @param int $id
     * @param Request $request
     * @return JsonResponse
     */
    public function receive(int $id, Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'lines' => 'required|array|min:1',
                'lines.*.line_id' => 'required|integer',
                'lines.*.cantidad_recibida' => 'required|numeric|min:0',
                'lines.*.observaciones' => 'nullable|string|max:500',
                'observaciones_generales' => 'nullable|string|max:1000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }

            $result = $this->transferService->receiveTransfer(
                $id,
                $request->lines,
                $request->user()->id
            );

            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'recibidaPor',
                'lineas.item'
            ])->find($id);

            return response()->json([
                'ok' => true,
                'message' => 'Transferencia recibida exitosamente',
                'data' => $transfer,
                'varianzas' => $result['varianzas'] ?? [],
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al recibir transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * Postea la transferencia al inventario (crea mov_inv).
     *
     * @route POST /api/inventory/transfers/{id}/post
     * @param int $id
     * @param Request $request
     * @return JsonResponse
     */
    public function post(int $id, Request $request): JsonResponse
    {
        try {
            $result = $this->transferService->postTransferToInventory(
                $id,
                $request->user()->id
            );

            $transfer = TransferHeader::with([
                'origenAlmacen',
                'destinoAlmacen',
                'posteadaPor',
                'lineas.item'
            ])->find($id);

            return response()->json([
                'ok' => true,
                'message' => 'Transferencia posteada exitosamente',
                'data' => $transfer,
                'movimientos_generados' => $result['movimientos_generados'],
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al postear transferencia',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }
}
