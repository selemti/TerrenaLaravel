<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\Rec\Receta;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class RecipeCostController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:sanctum', 'permission:can_view_recipe_dashboard']);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $at = $request->query('at');

        try {
            $moment = $at ? Carbon::parse($at) : now();
        } catch (Throwable $exception) {
            return response()->json([
                'message' => 'El parámetro at debe ser una fecha válida.',
            ], 422);
        }

        $data = $this->calculateCostAtDate($id, $moment);

        return response()->json([
            'data' => $data,
            'requested_at' => $moment->toIso8601String(),
        ]);
    }

    public function calculateCostAtDate(string $recipeId, ?Carbon $moment = null): array
    {
        $moment = $moment ?? now();

        try {
            $result = DB::connection('pgsql')->selectOne(
                'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
                [$recipeId, $moment->toDateTimeString()]
            );

            if ($result) {
                $resultArray = (array) $result;

                return [
                    'recipe_id' => $recipeId,
                    'cost_total' => (float) ($resultArray['batch_cost'] ?? 0),
                    'cost_per_portion' => (float) ($resultArray['portion_cost'] ?? 0),
                    'portions' => (float) ($resultArray['yield_portions'] ?? 0),
                    'cost_breakdown' => [],
                    'from_snapshot' => false,
                ];
            }
        } catch (Throwable $exception) {
            Log::warning('Fallo cálculo de costo vía función Postgres, usando fallback', [
                'recipe_id' => $recipeId,
                'error' => $exception->getMessage(),
            ]);
        }

        $recipe = Receta::with('detalles')->findOrFail($recipeId);

        $baseIngredients = [];
        $this->implodeRecipeBomRecursive($recipeId, 1.0, $baseIngredients);

        $totalCost = 0.0;
        $breakdown = [];

        foreach ($baseIngredients as $ingredient) {
            $qty = (float) ($ingredient['qty'] ?? 0);
            $unitCost = (float) ($ingredient['unit_cost'] ?? 0);
            $lineCost = $qty * $unitCost;
            $totalCost += $lineCost;

            $breakdown[] = array_merge($ingredient, [
                'total_cost' => $lineCost,
            ]);
        }

        $portions = max((float) ($recipe->porciones_standard ?? 1), 1);
        $costPerPortion = $portions > 0 ? $totalCost / $portions : 0.0;

        return [
            'recipe_id' => $recipeId,
            'recipe_name' => $recipe->nombre_plato ?? null,
            'cost_total' => $totalCost,
            'cost_per_portion' => $costPerPortion,
            'portions' => $portions,
            'cost_breakdown' => $breakdown,
        ];
    }

    public function implodeRecipeBom(string $id): JsonResponse
    {
        try {
            $recipe = Receta::findOrFail($id);

            $baseIngredients = [];
            $this->implodeRecipeBomRecursive($id, 1.0, $baseIngredients);

            return response()->json([
                'ok' => true,
                'data' => [
                    'recipe_id' => $recipe->id,
                    'recipe_name' => $recipe->nombre_plato,
                    'base_ingredients' => array_values($baseIngredients),
                    'total_ingredients' => count($baseIngredients),
                ],
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (Throwable $exception) {
            Log::error('Error implosionando BOM de receta', [
                'recipe_id' => $id,
                'error' => $exception->getMessage(),
            ]);

            return response()->json([
                'ok' => false,
                'error' => 'BOM_IMPLOSION_ERROR',
                'message' => 'Error al implosionar BOM de receta',
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }

    private function implodeRecipeBomRecursive(
        string $recipeId,
        float $factor,
        array &$baseIngredients,
        int $depth = 0
    ): void {
        if ($depth > 10) {
            Log::warning('Se alcanzó la profundidad máxima de implosión de BOM', [
                'recipe_id' => $recipeId,
                'depth' => $depth,
            ]);

            return;
        }

        $recipe = Receta::with(['detalles.item', 'detalles.subreceta'])->findOrFail($recipeId);

        foreach ($recipe->detalles as $detalle) {
            $adjustedQty = (float) $detalle->cantidad * $factor;

            if ($detalle->item_id && $detalle->item) {
                $item = $detalle->item;
                $key = $item->id;
                $unitCost = (float) ($item->costo_promedio ?? 0);
                $categoryModel = method_exists($item, 'category') ? $item->category : null;
                $category = $categoryModel->nombre
                    ?? $categoryModel->name
                    ?? ($item->categoria ?? 'Sin categoría');

                if (isset($baseIngredients[$key])) {
                    $baseIngredients[$key]['qty'] += $adjustedQty;
                } else {
                    $baseIngredients[$key] = [
                        'item_id' => $item->id,
                        'item_code' => $item->codigo ?? null,
                        'item_name' => $item->nombre ?? null,
                        'qty' => $adjustedQty,
                        'uom' => $detalle->unidad_id ?? null,
                        'unit_cost' => $unitCost,
                        'category' => $category,
                    ];
                }
            } elseif ($detalle->receta_id_ingrediente) {
                $this->implodeRecipeBomRecursive(
                    $detalle->receta_id_ingrediente,
                    $factor * (float) $detalle->cantidad,
                    $baseIngredients,
                    $depth + 1
                );
            }
        }
    }
}
