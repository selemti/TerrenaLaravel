<?php

namespace App\Http\Controllers\Api\Purchasing;

use App\Http\Controllers\Controller;
use App\Jobs\CalculateReplenishmentSuggestions;
use App\Models\ReplenishmentSuggestion;
use App\Services\Replenishment\ReplenishmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

/**
 * API REST para gestión de sugerencias de replenishment
 *
 * Endpoints:
 * - GET /api/purchasing/replenishment/suggestions - Listar sugerencias
 * - POST /api/purchasing/replenishment/calculate - Disparar cálculo manual
 * - POST /api/purchasing/replenishment/suggestions/{id}/approve - Aprobar sugerencia
 * - POST /api/purchasing/replenishment/suggestions/{id}/reject - Rechazar sugerencia
 * - POST /api/purchasing/replenishment/suggestions/{id}/convert - Convertir a PR/PO
 *
 * @see ReplenishmentService
 * @see CalculateReplenishmentSuggestions
 */
class ReplenishmentController extends Controller
{
    protected ReplenishmentService $service;

    public function __construct(ReplenishmentService $service)
    {
        $this->service = $service;
    }

    /**
     * Listar sugerencias de replenishment con filtros
     *
     * GET /api/purchasing/replenishment/suggestions
     *
     * Query params:
     * - sucursal_id: int (opcional)
     * - almacen_id: int (opcional)
     * - estado: string (PENDIENTE, APROBADA, RECHAZADA, CONVERTIDA)
     * - prioridad: string (URGENTE, ALTA, NORMAL, BAJA)
     * - tipo: string (COMPRA, PRODUCCION)
     * - desde: date (opcional, formato Y-m-d)
     * - hasta: date (opcional, formato Y-m-d)
     * - per_page: int (default 15)
     */
    public function index(Request $request): JsonResponse
    {
        $query = ReplenishmentSuggestion::with(['item', 'sucursal', 'almacen', 'revisadoPor']);

        // Filtros
        if ($request->has('sucursal_id')) {
            $query->where('sucursal_id', $request->sucursal_id);
        }

        if ($request->has('almacen_id')) {
            $query->where('almacen_id', $request->almacen_id);
        }

        if ($request->has('estado')) {
            $query->where('estado', $request->estado);
        }

        if ($request->has('prioridad')) {
            $query->where('prioridad', $request->prioridad);
        }

        if ($request->has('origen')) {
            $query->where('origen', $request->origen);
        }

        if ($request->has('desde')) {
            $query->whereDate('sugerido_en', '>=', $request->desde);
        }

        if ($request->has('hasta')) {
            $query->whereDate('sugerido_en', '<=', $request->hasta);
        }

        // Ordenamiento
        $orderBy = $request->get('order_by', 'sugerido_en');
        $orderDir = $request->get('order_dir', 'desc');
        $query->orderBy($orderBy, $orderDir);

        $perPage = (int) $request->get('per_page', 15);
        $suggestions = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $suggestions->items(),
            'pagination' => [
                'total' => $suggestions->total(),
                'per_page' => $suggestions->perPage(),
                'current_page' => $suggestions->currentPage(),
                'last_page' => $suggestions->lastPage(),
            ],
        ]);
    }

    /**
     * Disparar cálculo manual de sugerencias
     *
     * POST /api/purchasing/replenishment/calculate
     *
     * Body:
     * - sucursal_id: int (opcional)
     * - almacen_id: int (opcional)
     * - dias_analisis: int (default 7)
     * - auto_aprobar: bool (default false)
     * - async: bool (default true) - Si true, dispara job; si false, ejecuta sync
     */
    public function calculate(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'sucursal_id' => 'nullable|integer|exists:selemti.sucursales,id',
            'almacen_id' => 'nullable|integer|exists:selemti.almacenes,id',
            'dias_analisis' => 'nullable|integer|min:1|max:90',
            'auto_aprobar' => 'nullable|boolean',
            'async' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Errores de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        $options = [
            'sucursal_id' => $request->sucursal_id,
            'almacen_id' => $request->almacen_id,
            'dias_analisis' => $request->get('dias_analisis', 7),
            'auto_aprobar' => $request->get('auto_aprobar', false),
        ];

        $async = $request->get('async', true);

        if ($async) {
            // Disparar job asíncrono
            CalculateReplenishmentSuggestions::dispatch($options);

            return response()->json([
                'success' => true,
                'message' => 'Cálculo de sugerencias iniciado en background',
                'data' => [
                    'job_dispatched' => true,
                    'options' => $options,
                ],
            ], 202); // 202 Accepted
        } else {
            // Ejecutar síncronamente
            $resultado = $this->service->generateDailySuggestions($options);

            return response()->json([
                'success' => true,
                'message' => 'Sugerencias calculadas exitosamente',
                'data' => [
                    'total' => $resultado['total'],
                    'compras' => $resultado['compras'],
                    'producciones' => $resultado['producciones'],
                    'urgentes' => $resultado['urgentes'],
                    'normales' => $resultado['normales'],
                    'errors' => $resultado['errors'],
                ],
            ]);
        }
    }

    /**
     * Aprobar una sugerencia
     *
     * POST /api/purchasing/replenishment/suggestions/{id}/approve
     *
     * Body:
     * - qty_aprobada: float (opcional, default = qty_sugerida)
     * - notas: string (opcional)
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        $suggestion = ReplenishmentSuggestion::findOrFail($id);

        if ($suggestion->estado !== 'PENDIENTE') {
            return response()->json([
                'success' => false,
                'message' => 'Solo se pueden aprobar sugerencias en estado PENDIENTE',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'qty_aprobada' => 'nullable|numeric|min:0',
            'notas' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Actualizar sugerencia
        $suggestion->marcarAprobada(auth()->id(), $request->qty_aprobada);

        return response()->json([
            'success' => true,
            'message' => 'Sugerencia aprobada exitosamente',
            'data' => $suggestion->fresh(['item', 'revisadoPor']),
        ]);
    }

    /**
     * Rechazar una sugerencia
     *
     * POST /api/purchasing/replenishment/suggestions/{id}/reject
     *
     * Body:
     * - motivo: string (requerido)
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $suggestion = ReplenishmentSuggestion::findOrFail($id);

        if ($suggestion->estado !== 'PENDIENTE') {
            return response()->json([
                'success' => false,
                'message' => 'Solo se pueden rechazar sugerencias en estado PENDIENTE',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'motivo' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $suggestion->marcarRechazada(auth()->id(), $request->motivo);

        return response()->json([
            'success' => true,
            'message' => 'Sugerencia rechazada',
            'data' => $suggestion->fresh('revisadoPor'),
        ]);
    }

    /**
     * Convertir sugerencia a Purchase Request o Production Order
     *
     * POST /api/purchasing/replenishment/suggestions/{id}/convert
     *
     * Body:
     * - tipo: string (requerido) - 'purchase_request' o 'production_order'
     * - qty: float (opcional, usa qty_aprobada o qty_sugerida)
     * - notas: string (opcional)
     * - ... otros params específicos del tipo
     */
    public function convert(Request $request, int $id): JsonResponse
    {
        $suggestion = ReplenishmentSuggestion::findOrFail($id);

        if ($suggestion->estado !== 'APROBADA') {
            return response()->json([
                'success' => false,
                'message' => 'Solo se pueden convertir sugerencias APROBADAS',
            ], 400);
        }

        if ($suggestion->estado === 'CONVERTIDA') {
            return response()->json([
                'success' => false,
                'message' => 'Esta sugerencia ya fue convertida',
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'tipo' => ['required', Rule::in(['purchase_request', 'production_order'])],
            'qty' => 'nullable|numeric|min:0',
            'notas' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $tipo = $request->tipo;
            $overrides = [
                'qty' => $request->qty,
                'notas' => $request->notas,
                'user_id' => auth()->id(),
            ];

            if ($tipo === 'purchase_request') {
                $requestId = $this->service->convertToPurchaseRequest($id, $overrides);

                return response()->json([
                    'success' => true,
                    'message' => 'Sugerencia convertida a Purchase Request',
                    'data' => [
                        'purchase_request_id' => $requestId,
                        'suggestion' => $suggestion->fresh(),
                    ],
                ]);
            } else {
                $result = $this->service->convertToProductionOrder($id, $overrides);

                return response()->json([
                    'success' => true,
                    'message' => 'Sugerencia convertida a Production Order',
                    'data' => array_merge($result, [
                        'suggestion' => $suggestion->fresh(),
                    ]),
                ]);
            }

        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al convertir sugerencia: '.$e->getMessage(),
            ], 500);
        }
    }

    /**
     * Ver detalle de una sugerencia
     *
     * GET /api/purchasing/replenishment/suggestions/{id}
     */
    public function show(int $id): JsonResponse
    {
        $suggestion = ReplenishmentSuggestion::with([
            'item',
            'revisadoPor',
            'sucursal',
            'almacen',
            'purchaseRequest',
            'productionOrder',
        ])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $suggestion,
        ]);
    }
}
