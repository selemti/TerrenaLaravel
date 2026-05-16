<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Exceptions\Recetas\RecetaVersionException;
use App\Http\Controllers\Controller;
use App\Models\Rec\Receta;
use App\Models\Rec\RecipeCostSnapshot;
use App\Services\Costing\RecipeCostingService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class RecipeCostController extends Controller
{
    public function __construct(
        private readonly RecipeCostingService $costingService
    ) {
        $this->middleware(['auth:sanctum', 'permission:can_view_recipe_dashboard']);
    }

    public function show(Request $request, $id): JsonResponse
    {
        $at = $request->query('at');

        try {
            $moment = $at ? Carbon::parse($at) : now();
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'El parámetro at debe ser una fecha válida.',
            ], 422);
        }

        try {
            $cost = $this->calculateRecipeCost((string) $id, $moment);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException) {
            return response()->json([
                'message' => 'No se encontró información de costo para la receta solicitada.',
            ], 404);
        }

        return response()->json([
            'data' => [
                'recipe_id' => (string) $id,
                'cost_total' => $cost['cost_total'],
                'cost_per_portion' => $cost['cost_per_portion'],
                'batch_cost' => $cost['cost_total'],
                'portion_cost' => $cost['cost_per_portion'],
                'batch_size' => $cost['portions'],
                'yield_portions' => $cost['portions'],
                'cost_breakdown' => $cost['cost_breakdown'],
            ],
            'requested_at' => $moment->toIso8601String(),
        ]);
    }

    public function calculateCostAtDate($requestOrRecipeId, $recipeIdOrDate = null): JsonResponse|array
    {
        if ($requestOrRecipeId instanceof Request) {
            $request = $requestOrRecipeId;
            $recipeId = (string) $recipeIdOrDate;

            try {
                $date = Carbon::parse($request->input('date', now()->toDateString()));
                $cost = $this->calculateRecipeCost($recipeId, $date);

                return response()->json([
                    'ok' => true,
                    'data' => [
                        'receta_id' => $recipeId,
                        'date' => $date->toDateString(),
                        'cost' => $cost['cost_total'],
                        'currency' => 'MXN',
                        'cost_per_portion' => $cost['cost_per_portion'],
                        'portions' => $cost['portions'],
                        'cost_breakdown' => $cost['cost_breakdown'],
                    ],
                ]);
            } catch (\Illuminate\Database\Eloquent\ModelNotFoundException) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Receta no encontrada.',
                ], 404);
            } catch (\Throwable $e) {
                return response()->json([
                    'ok' => false,
                    'message' => 'No se pudo calcular el costo: '.$e->getMessage(),
                ], 500);
            }
        }

        $recipeId = (string) $requestOrRecipeId;
        $date = $recipeIdOrDate instanceof Carbon
            ? $recipeIdOrDate
            : Carbon::parse($recipeIdOrDate ?? now());

        return $this->calculateRecipeCost($recipeId, $date);
    }

    /**
     * Implotar BOM (Bill of Materials) de una receta
     * Retorna solo ingredientes base (items de inventario), resolviendo sub-recetas recursivamente
     *
     * @param  string  $id  Recipe ID
     */
    public function implodeBom(Request $request, string $id): JsonResponse
    {
        try {
            $receta = Receta::findOrFail($id);

            // Obtener versión publicada o la última versión
            $version = $receta->publishedVersion ?? $receta->latestVersion;

            if ($version) {
                $version->load(['detalles.item']);
                $detalles = $version->detalles;
            } else {
                // Fallback: use recipe's direct details (no versioning)
                $receta->load('detalles.item');
                $detalles = $receta->detalles;
            }

            $baseIngredients = $this->implodeRecursive(
                $detalles,
                $multiplier = 1.0,
                $depth = 0,
                $visited = []
            );

            return response()->json([
                'ok' => true,
                'data' => [
                    'recipe_id' => $id,
                    'recipe_name' => $receta->nombre_plato,
                    'version_id' => $version?->id,
                    'version_number' => $version?->version,
                    'base_ingredients' => array_values(array_map(fn ($ing) => array_merge($ing, ['qty' => $ing['total_qty']]), $baseIngredients)),
                    'total_ingredients' => count($baseIngredients),
                    'aggregated' => true,
                ],
                'timestamp' => now()->toIso8601String(),
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Receta no encontrada.',
                'recipe_id' => $id,
            ], 404);
        } catch (\RuntimeException $e) {
            return response()->json([
                'ok' => false,
                'message' => $e->getMessage(),
                'recipe_id' => $id,
            ], 400);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al procesar BOM: '.$e->getMessage(),
                'recipe_id' => $id,
            ], 500);
        }
    }

    /**
     * Método recursivo para implotar BOM
     *
     * @param  \Illuminate\Database\Eloquent\Collection  $detalles
     * @param  float  $multiplier  Multiplicador de cantidad (para sub-recetas)
     * @param  int  $depth  Profundidad de recursión (protección contra loops)
     * @param  array  $visited  Items ya visitados (protección contra loops)
     * @return array Ingredientes base agregados por item_id
     */
    private function implodeRecursive($detalles, float $multiplier = 1.0, int $depth = 0, array $visited = []): array
    {
        // Protección contra recursión infinita
        if ($depth > 10) {
            throw new RecetaVersionException('Profundidad máxima de recursión excedida (loop detectado en receta). Max: 10 niveles.');
        }

        $ingredients = [];

        foreach ($detalles as $detalle) {
            // Determine if this line is a sub-recipe reference
            $subRecipeId = $detalle->receta_id_ingrediente
                ?? (str_starts_with((string) $detalle->item_id, 'REC-') ? $detalle->item_id : null);

            if ($subRecipeId) {
                // Protección contra loops infinitos
                if (in_array($subRecipeId, $visited)) {
                    continue;
                }

                try {
                    $subReceta = Receta::find($subRecipeId);

                    if ($subReceta) {
                        $subVersion = $subReceta->publishedVersion ?? $subReceta->latestVersion;

                        if ($subVersion) {
                            $subVersion->load(['detalles.item']);
                            $subDetalles = $subVersion->detalles;
                        } else {
                            $subReceta->load('detalles.item');
                            $subDetalles = $subReceta->detalles;
                        }

                        $subMultiplier = $detalle->cantidad * $multiplier;
                        $newVisited = array_merge($visited, [$subRecipeId]);

                        $subIngredients = $this->implodeRecursive(
                            $subDetalles,
                            $subMultiplier,
                            $depth + 1,
                            $newVisited
                        );

                        foreach ($subIngredients as $key => $subIng) {
                            if (! isset($ingredients[$key])) {
                                $ingredients[$key] = $subIng;
                            } else {
                                $ingredients[$key]['total_qty'] += $subIng['total_qty'];
                            }
                        }
                    }
                } catch (\Exception $e) {
                    // ignore unresolvable sub-recipe
                }
            } else {
                // Ingrediente base (item de inventario)
                $itemId = $detalle->item_id;

                if (! $itemId || in_array($itemId, $visited)) {
                    continue;
                }

                if (! isset($ingredients[$itemId])) {
                    $ingredients[$itemId] = [
                        'item_id' => $itemId,
                        'item_name' => $detalle->item->nombre ?? 'Item desconocido',
                        'total_qty' => 0,
                        'uom' => $detalle->unidad_id ?? $detalle->unidad_medida ?? null,
                        'is_base' => true,
                    ];
                }

                $ingredients[$itemId]['total_qty'] += $detalle->cantidad * $multiplier;
            }
        }

        return $ingredients;
    }

    /**
     * Create a cost snapshot for a recipe
     * POST /api/recipes/{id}/cost/snapshot
     */
    public function createSnapshot(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'at' => 'nullable|date',
            'notes' => 'nullable|string|max:500',
        ]);

        try {
            $receta = Receta::findOrFail($id);

            $at = $request->input('at') ? Carbon::parse($request->input('at')) : now();
            $notes = $request->input('notes');
            $cost = $this->calculateRecipeCost($receta->id, $at);

            $snapshot = DB::connection('pgsql')->transaction(function () use ($receta, $at, $cost) {
                return RecipeCostSnapshot::create([
                    'recipe_id' => $receta->id,
                    'snapshot_date' => $at,
                    'cost_total' => $cost['cost_total'],
                    'cost_per_portion' => $cost['cost_per_portion'],
                    'portions' => $cost['portions'],
                    'cost_breakdown' => $cost['cost_breakdown'],
                    'reason' => RecipeCostSnapshot::REASON_MANUAL,
                    'created_by_user_id' => auth()->id(),
                ]);
            });

            return response()->json([
                'ok' => true,
                'message' => 'Snapshot creado exitosamente',
                'data' => [
                    'id' => $snapshot->id,
                    'recipe_id' => $snapshot->recipe_id,
                    'snapshot_at' => $snapshot->snapshot_date,
                    'portion_cost' => $snapshot->cost_per_portion,
                    'batch_cost' => $snapshot->cost_total,
                    'yield_portions' => $snapshot->portions,
                    'notes' => $notes,
                ],
            ], 201);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException) {
            return response()->json([
                'ok' => false,
                'message' => 'Receta no encontrada.',
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al crear snapshot: '.$e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get cost history for a recipe
     * GET /api/recipes/{id}/cost/history
     */
    public function getHistory(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'from' => 'nullable|date',
            'to' => 'nullable|date',
            'limit' => 'nullable|integer|min:1|max:500',
        ]);

        try {
            $receta = Receta::findOrFail($id);

            $from = $request->input('from') ? Carbon::parse($request->input('from')) : null;
            $to = $request->input('to') ? Carbon::parse($request->input('to')) : null;
            $limit = $request->input('limit', 100);

            $history = RecipeCostSnapshot::forRecipe($receta->id)
                ->when($from, fn ($query) => $query->where('snapshot_date', '>=', $from))
                ->when($to, fn ($query) => $query->where('snapshot_date', '<=', $to))
                ->orderByDesc('snapshot_date')
                ->orderByDesc('id')
                ->limit($limit)
                ->get();

            return response()->json([
                'ok' => true,
                'data' => $history->map(fn ($snapshot) => [
                    'id' => $snapshot->id,
                    'snapshot_at' => $snapshot->snapshot_date,
                    'portion_cost' => $snapshot->cost_per_portion,
                    'batch_cost' => $snapshot->cost_total,
                    'yield_portions' => $snapshot->portions,
                    'cost_change_pct' => $snapshot->cost_change_percentage,
                    'notes' => null,
                ]),
                'meta' => [
                    'count' => $history->count(),
                    'recipe_id' => $id,
                    'from' => $from?->toIso8601String(),
                    'to' => $to?->toIso8601String(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al obtener historial: '.$e->getMessage(),
            ], 500);
        }
    }

    /**
     * Compare two cost snapshots
     * GET /api/recipes/{id}/cost/compare
     */
    public function compareSnapshots(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'current_id' => ['required', 'integer', Rule::exists(RecipeCostSnapshot::class, 'id')],
            'previous_id' => ['required', 'integer', Rule::exists(RecipeCostSnapshot::class, 'id')],
        ]);

        try {
            $receta = Receta::findOrFail($id);

            $current = RecipeCostSnapshot::findOrFail($request->input('current_id'));
            $previous = RecipeCostSnapshot::findOrFail($request->input('previous_id'));

            // Verify both snapshots belong to same recipe
            if ($current->recipe_id != $receta->id || $previous->recipe_id != $receta->id) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Los snapshots no pertenecen a la receta especificada',
                ], 422);
            }

            $comparison = $this->compareSnapshotRows($current, $previous);

            return response()->json([
                'ok' => true,
                'data' => $comparison,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'ok' => false,
                'message' => 'Error al comparar snapshots: '.$e->getMessage(),
            ], 500);
        }
    }

    private function calculateRecipeCost(string $recipeId, Carbon $date): array
    {
        $receta = Receta::with('detalles.item')->findOrFail($recipeId);
        $portions = max((float) ($receta->porciones_standard ?? 1), 1.0);
        $breakdown = [];
        $total = 0.0;

        foreach ($receta->detalles as $detalle) {
            if (! $detalle->item_id) {
                continue;
            }

            $unitCost = (float) ($detalle->item?->costo_promedio ?? 0);
            $qty = (float) $detalle->cantidad;
            $lineCost = $qty * $unitCost;
            $total += $lineCost;

            $breakdown[] = [
                'item_id' => $detalle->item_id,
                'item_name' => $detalle->item?->nombre,
                'quantity' => $qty,
                'unit_cost' => $unitCost,
                'total_cost' => round($lineCost, 4),
                'uom' => $detalle->unidad_id,
            ];
        }

        return [
            'recipe_id' => $recipeId,
            'date' => $date->toDateString(),
            'cost_total' => round($total, 4),
            'cost_per_portion' => round($total / $portions, 4),
            'portions' => $portions,
            'cost_breakdown' => $breakdown,
            'currency' => 'MXN',
        ];
    }

    private function compareSnapshotRows(RecipeCostSnapshot $current, RecipeCostSnapshot $previous): array
    {
        $portionDiff = (float) $current->cost_per_portion - (float) $previous->cost_per_portion;
        $portionPct = (float) $previous->cost_per_portion > 0
            ? ($portionDiff / (float) $previous->cost_per_portion) * 100
            : 0;
        $batchDiff = (float) $current->cost_total - (float) $previous->cost_total;
        $batchPct = (float) $previous->cost_total > 0
            ? ($batchDiff / (float) $previous->cost_total) * 100
            : 0;

        return [
            'current' => [
                'id' => $current->id,
                'snapshot_at' => $current->snapshot_date,
                'portion_cost' => (float) $current->cost_per_portion,
                'batch_cost' => (float) $current->cost_total,
            ],
            'previous' => [
                'id' => $previous->id,
                'snapshot_at' => $previous->snapshot_date,
                'portion_cost' => (float) $previous->cost_per_portion,
                'batch_cost' => (float) $previous->cost_total,
            ],
            'variance' => [
                'portion_diff' => round($portionDiff, 4),
                'portion_pct' => round($portionPct, 2),
                'batch_diff' => round($batchDiff, 4),
                'batch_pct' => round($batchPct, 2),
                'days_between' => $previous->snapshot_date->diffInDays($current->snapshot_date),
            ],
        ];
    }
}
