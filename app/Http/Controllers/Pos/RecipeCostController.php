<?php

namespace App\Http\Controllers\Pos;

use App\Http\Controllers\Controller;
use App\Services\Pos\PosConsumptionService;
use App\Services\Pos\Repositories\CostosRepository;
use App\Services\Pos\Repositories\RecetaRepository;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class RecipeCostController extends Controller
{
    public function __construct(
        protected PosConsumptionService $service,
        protected CostosRepository $costosRepo,
        protected RecetaRepository $recetaRepo
    ) {
    }

    /**
     * GET /api/recipes/{recipeId}/cost
     *
     * Obtiene el costo estándar actual de una receta
     * Requiere permiso: can_view_recipe_dashboard
     *
     * @param int $recipeId
     * @return JsonResponse
     */
    public function showCost(int $recipeId): JsonResponse
    {
        try {
            // 1. Verificar que la receta existe
            $recipeInfo = $this->recetaRepo->getRecipeInfo($recipeId);
            if (!$recipeInfo) {
                return response()->json([
                    'ok' => false,
                    'error' => 'RECIPE_NOT_FOUND',
                    'message' => 'Receta no encontrada',
                    'timestamp' => now()->toIso8601String(),
                ], 404);
            }

            // 2. Forzar snapshot de costo (recalcular)
            $this->service->recalcularCostoReceta($recipeId);

            // 3. Obtener costo actual
            $costo = $this->costosRepo->getRecipeCostNow($recipeId);

            // 4. Obtener detalles de items de la receta
            $recipeItems = $this->recetaRepo->getRecipeItemsByRecipeVersion($recipeId);

            // 5. Calcular costo detallado por item
            $costosDetallados = [];
            $costoTotalCalculado = 0.0;

            foreach ($recipeItems as $item) {
                $itemId = $item['item_id'];
                $qty = (float) ($item['qty'] ?? 0);
                $uom = $item['uom'] ?? 'UNI';

                $costoUnitario = $this->costosRepo->getItemUnitCostNow($itemId, $uom);
                $costoTotal = $costoUnitario * $qty;
                $costoTotalCalculado += $costoTotal;

                $costosDetallados[] = [
                    'item_id' => $itemId,
                    'item_descripcion' => $item['item_descripcion'] ?? 'Unknown',
                    'item_clave' => $item['item_clave'] ?? '',
                    'qty' => $qty,
                    'uom' => $uom,
                    'costo_unitario' => round($costoUnitario, 2),
                    'costo_total' => round($costoTotal, 2),
                    'es_producible' => $item['es_producible'] ?? false,
                ];
            }

            return response()->json([
                'ok' => true,
                'data' => [
                    'recipe_id' => $recipeId,
                    'recipe_name' => $recipeInfo['name'] ?? 'Unknown',
                    'costo_estandar' => round($costo, 2),
                    'costo_calculado' => round($costoTotalCalculado, 2),
                    'num_items' => count($recipeItems),
                    'items' => $costosDetallados,
                    'timestamp' => now()->toIso8601String(),
                ],
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error en showCost endpoint', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'COST_CALCULATION_ERROR',
                'message' => 'Error al calcular costo de receta: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    /**
     * POST /api/recipes/{recipeId}/recalculate
     *
     * Fuerza el recálculo del costo de una receta
     * Requiere permiso: can_view_recipe_dashboard
     *
     * @param int $recipeId
     * @return JsonResponse
     */
    public function recalculate(int $recipeId): JsonResponse
    {
        try {
            // Verificar que la receta existe
            $recipeInfo = $this->recetaRepo->getRecipeInfo($recipeId);
            if (!$recipeInfo) {
                return response()->json([
                    'ok' => false,
                    'error' => 'RECIPE_NOT_FOUND',
                    'message' => 'Receta no encontrada',
                    'timestamp' => now()->toIso8601String(),
                ], 404);
            }

            // Recalcular
            $this->service->recalcularCostoReceta($recipeId);

            // Obtener nuevo costo
            $costo = $this->costosRepo->getRecipeCostNow($recipeId);

            return response()->json([
                'ok' => true,
                'data' => [
                    'recipe_id' => $recipeId,
                    'recipe_name' => $recipeInfo['name'] ?? 'Unknown',
                    'costo_estandar' => round($costo, 2),
                    'recalculado_at' => now()->toIso8601String(),
                ],
                'message' => 'Costo recalculado exitosamente',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error en recalculate endpoint', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'RECALCULATE_ERROR',
                'message' => 'Error al recalcular costo: ' . $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }
}
