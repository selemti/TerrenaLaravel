<?php

namespace App\Services\Recetas;

use App\Services\Inventory\ModifierValidationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RecipeCostService
{
    public function __construct(
        private readonly ModifierValidationService $modifierValidation
    ) {}

    /**
     * Calcula el costo de una receta incluyendo modificadores usando la relación correcta.
     */
    public function calculateRecipeWithModifiers(int $recipeId, array $modifierIds = []): float
    {
        $baseCost = $this->getBaseRecipeCost($recipeId);
        $modifiersCost = 0.0;

        foreach ($modifierIds as $modifierId) {
            $modifier = $this->modifierValidation->getModifierWithCorrectGroup((int) $modifierId);

            if ($modifier) {
                $modifiersCost += $this->calculateModifierCost($modifier);
            }
        }

        return $baseCost + $modifiersCost;
    }

    /**
     * Calcula el costo de un modificador buscando su receta por grupo correcto.
     */
    protected function calculateModifierCost($modifier): float
    {
        try {
            $modifierRecipe = DB::connection('pgsql')
                ->table('selemti.recetas')
                ->where('grupo_modificador_id', $modifier->group_id)
                ->where('nombre_modificador', $modifier->name)
                ->first();
        } catch (\Throwable $e) {
            Log::warning('No se pudo resolver la receta del modificador', [
                'modifier_id' => $modifier->id ?? null,
                'error' => $e->getMessage(),
            ]);

            $modifierRecipe = null;
        }

        if ($modifierRecipe) {
            return $this->calculateRecipeIngredientsCost((int) $modifierRecipe->id);
        }

        return 0.0;
    }

    /**
     * Obtiene el costo base de la receta usando función nativa o fallback.
     */
    protected function getBaseRecipeCost(int $recipeId): float
    {
        try {
            $row = DB::connection('pgsql')->selectOne(
                'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
                [$recipeId, now()->toDateTimeString()]
            );
        } catch (\Throwable $e) {
            Log::warning('No se pudo calcular costo base de receta', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);

            $row = null;
        }

        if (! $row) {
            return 0.0;
        }

        $data = (array) $row;

        return (float) ($data['batch_cost'] ?? $data['batch_total'] ?? $data['portion_cost'] ?? 0);
    }

    /**
     * Calcula costo de ingredientes de una receta específica.
     */
    protected function calculateRecipeIngredientsCost(int $recipeId): float
    {
        try {
            $row = DB::connection('pgsql')->selectOne(
                'SELECT * FROM selemti.fn_recipe_cost_at(?, ?)',
                [$recipeId, now()->toDateTimeString()]
            );
        } catch (\Throwable $e) {
            Log::warning('No se pudo calcular costo de ingredientes del modificador', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);

            return 0.0;
        }

        if (! $row) {
            return 0.0;
        }

        $data = (array) $row;

        return (float) ($data['batch_cost'] ?? $data['batch_total'] ?? $data['portion_cost'] ?? 0);
    }
}
