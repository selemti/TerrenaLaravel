<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class InventoryMovementService
{
    public function __construct(
        private readonly ModifierValidationService $modifierValidation
    ) {}

    /**
     * Registra movimientos derivados de un modificador usando el grupo correcto.
     */
    public function recordModifierMovement(
        int $modifierId,
        float $quantity,
        string $type,
        array $data
    ): int {
        $modifier = $this->modifierValidation->getModifierWithCorrectGroup($modifierId);

        if ($modifier) {
            $recipeId = $this->getRecipeByModifierGroup((int) $modifier->group_id, (string) $modifier->name);

            if ($recipeId) {
                $movementId = $this->consumeRecipeIngredients($recipeId, $quantity, $data);

                if ($movementId) {
                    return $movementId;
                }
            }
        }

        return $this->recordBasicMovement($modifierId, $quantity, $type, $data);
    }

    /**
     * Busca la receta asociada a un modificador usando su grupo correcto.
     */
    protected function getRecipeByModifierGroup(int $groupId, string $modifierName): ?int
    {
        return DB::connection('pgsql')
            ->table('selemti.recetas')
            ->where('grupo_modificador_id', $groupId)
            ->where('nombre_modificador', $modifierName)
            ->value('id');
    }

    /**
     * Consume ingredientes de la receta asociada al modificador.
     */
    protected function consumeRecipeIngredients(int $recipeId, float $quantity, array $data): int
    {
        try {
            $ingredients = DB::connection('pgsql')
                ->table('selemti.receta_det')
                ->where('receta_id', $recipeId)
                ->get();
        } catch (\Throwable $e) {
            Log::warning('No se pudo cargar la receta para consumir modificador', [
                'recipe_id' => $recipeId,
                'error' => $e->getMessage(),
            ]);

            return 0;
        }

        if ($ingredients->isEmpty()) {
            return 0;
        }

        $movementId = 0;

        foreach ($ingredients as $ingredient) {
            $itemId = (int) ($ingredient->item_id ?? 0);
            $ingredientQty = (float) ($ingredient->cantidad ?? 0);

            if ($itemId <= 0 || $ingredientQty === 0.0) {
                continue;
            }

            $movementId = $this->recordBasicMovement(
                $itemId,
                $quantity * $ingredientQty,
                'MODIFIER_RECIPE',
                $data + [
                    'ref_tipo' => 'modifier_recipe',
                    'ref_id' => $recipeId,
                ]
            );
        }

        return $movementId;
    }

    /**
     * Inserta un movimiento básico en mov_inv con datos mínimos.
     */
    protected function recordBasicMovement(int $itemId, float $quantity, string $type, array $data): int
    {
        $payload = [
            'item_id' => $itemId,
            'qty' => $quantity,
            'tipo' => $type,
            'uom' => $data['uom'] ?? null,
            'sucursal_id' => $data['branch_id'] ?? null,
            'almacen_id' => $data['warehouse_id'] ?? null,
            'ref_tipo' => $data['ref_tipo'] ?? null,
            'ref_id' => $data['ref_id'] ?? null,
            'user_id' => $data['user_id'] ?? null,
            'ts' => $data['ts'] ?? now(),
            'meta' => isset($data['meta']) ? json_encode($data['meta']) : null,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        try {
            return (int) DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->insertGetId($payload);
        } catch (\Throwable $e) {
            Log::warning('Fallo al insertar movimiento básico de modificador', [
                'item_id' => $itemId,
                'type' => $type,
                'error' => $e->getMessage(),
            ]);

            try {
                $inserted = DB::connection('pgsql')
                    ->table('selemti.mov_inv')
                    ->insert($payload);

                return $inserted ? 1 : 0;
            } catch (\Throwable $inner) {
                Log::error('No se pudo registrar movimiento de modificador', [
                    'item_id' => $itemId,
                    'type' => $type,
                    'error' => $inner->getMessage(),
                ]);

                return 0;
            }
        }
    }
}
