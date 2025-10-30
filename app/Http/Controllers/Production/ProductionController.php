<?php

namespace App\Http\Controllers\Production;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Production\ProductionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador REST para batches de producción interna.
 */
class ProductionController extends Controller
{
    public function __construct(
        protected ProductionService $productionService,
        private AuditLogService $auditLogService
    )
    {
        $this->middleware(['auth:sanctum', 'permission:can_edit_production_order']);
    }

    /**
     * Planifica un batch de producción para una receta.
     *
     * @route POST /api/production/batch/plan
     * @param Request $request
     * @return JsonResponse
     * @todo Validar recipe y qty target con un FormRequest dedicado.
     */
    public function plan(Request $request): JsonResponse
    {
        // TODO auth: requiere permiso production.batch.plan
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $recipeId = (int) $request->input('recipe_id');
        $qtyTarget = (float) $request->input('qty_target', 0);

        $data = $this->productionService->planBatch($recipeId, $qtyTarget, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Batch de producción planificado.',
        ]);
    }

    /**
     * Registra el consumo de insumos para un batch.
     *
     * @route POST /api/production/batch/{batch_id}/consume
     * @param int $batch_id
     * @param Request $request
     * @return JsonResponse
     * @todo Validar líneas contra inventario disponible y recipe BOM.
     */
    public function consume(int $batch_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso production.batch.consume
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $consumed = $request->input('lines', []);
        $consumed = is_array($consumed) ? $consumed : [];

        $data = $this->productionService->consumeIngredients($batch_id, $consumed, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Insumos registrados para el batch.',
        ]);
    }

    /**
     * Marca el batch como completado con las cantidades producidas.
     *
     * @route POST /api/production/batch/{batch_id}/complete
     * @param int $batch_id
     * @param Request $request
     * @return JsonResponse
     * @todo Registrar métricas de rendimiento y lotes generados.
     */
    public function complete(int $batch_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso production.batch.complete
        $user = $request->user();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'message' => 'Usuario no autenticado',
            ], 401);
        }
        $userId = (int) $user->id;
        $produced = $request->input('lines', []);
        $produced = is_array($produced) ? $produced : [];

        $data = $this->productionService->completeBatch($batch_id, $produced, $userId);

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Batch completado, listo para posteo.',
        ]);
    }

    /**
     * Postea el batch generando mov_inv de insumos y producto final.
     *
     * @route POST /api/production/batch/{batch_id}/post
     * @param int $batch_id
     * @param Request $request
     * @return JsonResponse
     * @todo Manejar errores de doble posteo y bloquear cuando ya exista Kardex.
     */
    public function post(int $batch_id, Request $request): JsonResponse
    {
        // TODO auth: requiere permiso production.batch.post
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
                'message' => 'Motivo es obligatorio para postear batch de producción.',
            ], 422);
        }

        // TODO: evidencia_url será obligatoria en producción. Si viene vacía aquí, estamos permitiendo temporalmente por QA.

        $data = $this->productionService->postBatchToInventory($batch_id, $userId);

        $this->auditLogService->logAction(
            $userId,
            'PRODUCTION_POST_BATCH',
            'batch',
            $batch_id,
            (string) $request->input('motivo', ''),
            $request->input('evidencia_url'),
            $request->all()
        );

        return response()->json([
            'ok' => true,
            'data' => $data,
            'message' => 'Batch posteado a inventario (consumo y producto terminado).',
        ]);
    }
}
