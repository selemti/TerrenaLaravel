<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Exceptions\Recetas\RecetaVersionException;
use App\Http\Controllers\Controller;
use App\Models\Rec\Receta;
use App\Services\Costing\RecipeCostingService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

        $result = DB::connection('pgsql')->selectOne(
            'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
            [$id, $moment->toDateTimeString()]
        );

        if (! $result) {
            return response()->json([
                'message' => 'No se encontró información de costo para la receta solicitada.',
            ], 404);
        }

        return response()->json([
            'data' => (array) $result,
            'requested_at' => $moment->toIso8601String(),
        ]);
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

            $snapshot = $this->costingService->createSnapshot(
                (int) $receta->id,
                $at,
                $notes
            );

            return response()->json([
                'ok' => true,
                'message' => 'Snapshot creado exitosamente',
                'data' => [
                    'id' => $snapshot->id,
                    'recipe_id' => $snapshot->recipe_id,
                    'snapshot_at' => $snapshot->snapshot_at,
                    'portion_cost' => $snapshot->portion_cost,
                    'batch_cost' => $snapshot->batch_cost,
                    'yield_portions' => $snapshot->yield_portions,
                    'notes' => $snapshot->notes,
                ],
            ], 201);
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

            $history = $this->costingService->getHistory(
                (int) $receta->id,
                $from,
                $to,
                $limit
            );

            return response()->json([
                'ok' => true,
                'data' => $history->map(fn ($snapshot) => [
                    'id' => $snapshot->id,
                    'snapshot_at' => $snapshot->snapshot_at,
                    'portion_cost' => $snapshot->portion_cost,
                    'batch_cost' => $snapshot->batch_cost,
                    'yield_portions' => $snapshot->yield_portions,
                    'cost_change_pct' => $snapshot->cost_change_percentage,
                    'notes' => $snapshot->notes,
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
            'current_id' => 'required|integer|exists:selemti.recipe_cost_history,id',
            'previous_id' => 'required|integer|exists:selemti.recipe_cost_history,id',
        ]);

        try {
            $receta = Receta::findOrFail($id);

            $current = \App\Models\Rec\RecipeCostSnapshot::findOrFail($request->input('current_id'));
            $previous = \App\Models\Rec\RecipeCostSnapshot::findOrFail($request->input('previous_id'));

            // Verify both snapshots belong to same recipe
            if ($current->recipe_id != $receta->id || $previous->recipe_id != $receta->id) {
                return response()->json([
                    'ok' => false,
                    'message' => 'Los snapshots no pertenecen a la receta especificada',
                ], 422);
            }

            $comparison = $this->costingService->compareSnapshots($current, $previous);

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
}
