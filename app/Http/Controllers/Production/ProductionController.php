<?php

namespace App\Http\Controllers\Production;

use App\Http\Controllers\Controller;
use App\Services\Audit\AuditLogService;
use App\Services\Production\ProductionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductionController extends Controller
{
    public function __construct(
        protected ProductionService $productionService,
        private AuditLogService $auditLogService
    ) {
        $this->middleware(['auth:sanctum', 'permission:can_edit_production_order']);
    }

    public function plan(Request $request): JsonResponse
    {
        try {
            $userId = (int) auth()->id();
            $data = $this->productionService->planBatch(
                (int) $request->input('recipe_id'),
                (float) $request->input('qty_target', 0),
                $userId
            );

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Batch de producción planificado.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'plan_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function consume(int $batch_id, Request $request): JsonResponse
    {
        try {
            $userId = (int) auth()->id();
            $consumed = $request->input('lines', []);
            $data = $this->productionService->consumeIngredients($batch_id, is_array($consumed) ? $consumed : [], $userId);

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Insumos registrados para el batch.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'consume_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function complete(int $batch_id, Request $request): JsonResponse
    {
        try {
            $userId = (int) auth()->id();
            $produced = $request->input('lines', []);
            $data = $this->productionService->completeBatch($batch_id, is_array($produced) ? $produced : [], $userId);

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Batch completado, listo para posteo.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'complete_error', 'message' => $e->getMessage()], 422);
        }
    }

    public function post(int $batch_id, Request $request): JsonResponse
    {
        if (empty(trim($request->input('motivo', '')))) {
            return response()->json(['ok' => false, 'error' => 'MOTIVO_REQUIRED', 'message' => 'Motivo es obligatorio para postear batch.'], 422);
        }

        try {
            $userId = (int) auth()->id();
            $data = $this->productionService->postBatchToInventory($batch_id, $userId);

            $this->auditLogService->logAction(
                $userId, 'PRODUCTION_POST_BATCH', 'batch', $batch_id,
                (string) $request->input('motivo', ''), $request->input('evidencia_url'), $request->all()
            );

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Batch posteado a inventario.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'post_error', 'message' => $e->getMessage()], 422);
        }
    }
}
