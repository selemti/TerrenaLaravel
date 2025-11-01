<?php

namespace App\Http\Controllers\Api\Inventory;

use App\Http\Controllers\Controller;
use App\Models\Rec\Receta;
use App\Models\Rec\RecetaVersion;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecipeCostController extends Controller
{
    public function __construct()
    {
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
     * @param Request $request
     * @param string $id Recipe ID
     * @return JsonResponse
     */
    public function implodeBom(Request $request, string $id): JsonResponse
    {
        try {
            $receta = Receta::findOrFail($id);
            
            // Obtener versión publicada o la última versión
            $version = $receta->publishedVersion ?? $receta->latestVersion;
            
            if (!$version) {
                return response()->json([
                    'ok' => false,
                    'message' => 'La receta no tiene versiones disponibles.',
                    'recipe_id' => $id,
                ], 404);
            }

            // Cargar detalles con relaciones
            $version->load(['detalles.item']);
            
            $baseIngredients = $this->implodeRecursive(
                $version->detalles, 
                $multiplier = 1.0,
                $depth = 0,
                $visited = []
            );

            return response()->json([
                'ok' => true,
                'recipe_id' => $id,
                'recipe_name' => $receta->nombre_plato,
                'version_id' => $version->id,
                'version_number' => $version->version,
                'base_ingredients' => array_values($baseIngredients),
                'total_ingredients' => count($baseIngredients),
                'aggregated' => true,
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
                'message' => 'Error al procesar BOM: ' . $e->getMessage(),
                'recipe_id' => $id,
            ], 500);
        }
    }

    /**
     * Método recursivo para implotar BOM
     * 
     * @param \Illuminate\Database\Eloquent\Collection $detalles
     * @param float $multiplier Multiplicador de cantidad (para sub-recetas)
     * @param int $depth Profundidad de recursión (protección contra loops)
     * @param array $visited Items ya visitados (protección contra loops)
     * @return array Ingredientes base agregados por item_id
     */
    private function implodeRecursive($detalles, float $multiplier = 1.0, int $depth = 0, array $visited = []): array
    {
        // Protección contra recursión infinita
        if ($depth > 10) {
            throw new \RuntimeException('Profundidad máxima de recursión excedida (loop detectado en receta). Max: 10 niveles.');
        }

        $ingredients = [];

        foreach ($detalles as $detalle) {
            $itemId = $detalle->item_id;
            
            // Protección contra loops infinitos
            if (in_array($itemId, $visited)) {
                continue; // Skip si ya visitamos este item en esta rama
            }

            // Verificar si el item es una receta (código inicia con 'REC-')
            if (str_starts_with($itemId, 'REC-')) {
                // Es una sub-receta, necesitamos implodirla
                try {
                    $subReceta = Receta::find($itemId);
                    
                    if ($subReceta) {
                        $subVersion = $subReceta->publishedVersion ?? $subReceta->latestVersion;
                        
                        if ($subVersion) {
                            $subVersion->load(['detalles.item']);
                            
                            // Calcular multiplicador: cantidad de sub-receta * multiplicador acumulado
                            $subMultiplier = $detalle->cantidad * $multiplier;
                            
                            // Recursión: agregar itemId actual a visited
                            $newVisited = array_merge($visited, [$itemId]);
                            
                            $subIngredients = $this->implodeRecursive(
                                $subVersion->detalles,
                                $subMultiplier,
                                $depth + 1,
                                $newVisited
                            );
                            
                            // Agregar ingredientes de sub-receta a nuestro array
                            foreach ($subIngredients as $key => $subIng) {
                                if (!isset($ingredients[$key])) {
                                    $ingredients[$key] = $subIng;
                                } else {
                                    // Agregar cantidades
                                    $ingredients[$key]['total_qty'] += $subIng['total_qty'];
                                }
                            }
                        }
                    }
                } catch (\Exception $e) {
                    // Si falla cargar sub-receta, tratarlo como ingrediente base
                    $key = $itemId;
                    
                    if (!isset($ingredients[$key])) {
                        $ingredients[$key] = [
                            'item_id' => $itemId,
                            'item_name' => $detalle->item->nombre ?? $itemId,
                            'total_qty' => 0,
                            'uom' => $detalle->unidad_medida,
                            'is_base' => true,
                        ];
                    }
                    
                    $qtyAdjusted = $detalle->cantidad * $multiplier;
                    $ingredients[$key]['total_qty'] += $qtyAdjusted;
                }
            } else {
                // Es un ingrediente base (item de inventario)
                $key = $itemId;
                
                if (!isset($ingredients[$key])) {
                    $ingredients[$key] = [
                        'item_id' => $itemId,
                        'item_name' => $detalle->item->nombre ?? 'Item desconocido',
                        'total_qty' => 0,
                        'uom' => $detalle->unidad_medida,
                        'is_base' => true,
                    ];
                }
                
                // Aplicar multiplicador y agregar
                $qtyAdjusted = $detalle->cantidad * $multiplier;
                $ingredients[$key]['total_qty'] += $qtyAdjusted;
            }
        }

        return $ingredients;
    }
}
