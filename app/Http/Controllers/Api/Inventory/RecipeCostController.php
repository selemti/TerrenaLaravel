<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
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

        $recipe = Receta::findOrFail($recipeId);

        try {
            $result = DB::connection('pgsql')->selectOne(
                'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
                [$recipeId, $moment->toDateTimeString()]
            );

            if ($result) {
                $resultArray = (array) $result;

                return [
                    'recipe_id' => $recipeId,
                    'recipe_name' => $recipe->nombre_plato ?? null,
                    'cost_total' => (float) ($resultArray['batch_cost'] ?? 0),
                    'cost_per_portion' => (float) ($resultArray['portion_cost'] ?? 0),
                    'portions' => (float) ($resultArray['yield_portions'] ?? ($recipe->porciones_standard ?? 0)),
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

        $version = $this->resolveLatestVersion($recipeId);

        if (! $version) {
            return [
                'recipe_id' => $recipeId,
                'recipe_name' => $recipe->nombre_plato ?? null,
                'cost_total' => 0.0,
                'cost_per_portion' => 0.0,
                'portions' => (float) ($recipe->porciones_standard ?? 1),
                'cost_breakdown' => [],
            ];
        }

        $baseIngredients = [];
        $this->processVersionDetails($version, 1.0, $baseIngredients);

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

            $version = $this->resolveLatestVersion($id);

            if (! $version) {
                return response()->json([
                    'ok' => true,
                    'data' => [
                        'recipe_id' => $recipe->id,
                        'recipe_name' => $recipe->nombre_plato,
                        'base_ingredients' => [],
                        'total_ingredients' => 0,
                    ],
                    'timestamp' => now()->toIso8601String(),
                ]);
            }

            $baseIngredients = [];
            $this->processVersionDetails($version, 1.0, $baseIngredients);

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

    private function resolveLatestVersion(string $recipeId): ?RecetaVersion
    {
        return RecetaVersion::query()
            ->where('receta_id', $recipeId)
            ->orderByDesc('fecha_efectiva')
            ->orderByDesc('version')
            ->orderByDesc('id')
            ->with(['detalles' => function ($query) {
                $query
                    ->orderBy('orden')
                    ->orderBy('id')
                    ->with('item');
            }])
            ->first();
    }

    private function processVersionDetails(RecetaVersion $version, float $factor, array &$baseIngredients, int $depth = 0): void
    {
        if ($depth > 10) {
            Log::warning('Se alcanzó la profundidad máxima de implosión de BOM', [
                'recipe_id' => $version->receta_id,
                'depth' => $depth,
            ]);

            return;
        }

        foreach ($version->detalles as $detalle) {
            if (! $detalle->item) {
                continue;
            }

            $item = $detalle->item;
            $key = $item->id;
            $adjustedQty = (float) $detalle->cantidad * $factor;
            $unitCost = (float) ($item->costo_promedio ?? 0);
            $category = optional($item->category)->nombre
                ?? optional($item->legacyCategory)->nombre
                ?? 'Sin categoría';
            $itemCode = $item->item_code ?? $item->codigo ?? $item->id;
            $uom = $detalle->unidad_medida ?? $item->unidad_medida ?? null;

            if (isset($baseIngredients[$key])) {
                $baseIngredients[$key]['qty'] += $adjustedQty;
            } else {
                $baseIngredients[$key] = [
                    'item_id' => $item->id,
                    'item_code' => $itemCode,
                    'item_name' => $item->nombre ?? null,
                    'qty' => $adjustedQty,
                    'uom' => $uom,
                    'unit_cost' => $unitCost,
                    'category' => $category,
                ];
            }
        }
    }
}
