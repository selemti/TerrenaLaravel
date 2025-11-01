<?php

namespace App\Services\Recipes;

use App\Http\Controllers\Api\Inventory\RecipeCostController;
use App\Models\Rec\RecipeCostSnapshot;
use App\Models\Rec\Receta;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class RecipeCostSnapshotService
{
    public const COST_CHANGE_THRESHOLD = 0.02;

    public function __construct(private readonly RecipeCostController $recipeCostController)
    {
    }

    public function createSnapshot(
        string $recipeId,
        string $reason = RecipeCostSnapshot::REASON_MANUAL,
        ?int $userId = null,
        ?Carbon $date = null
    ): RecipeCostSnapshot {
        $date = $date ?? now();

        DB::beginTransaction();

        try {
            $costData = $this->recipeCostController->calculateCostAtDate($recipeId, $date);

            if (! $costData || ! array_key_exists('cost_total', $costData)) {
                throw new \RuntimeException("No se pudo calcular el costo para la receta {$recipeId}");
            }

            $snapshot = RecipeCostSnapshot::create([
                'recipe_id' => $recipeId,
                'snapshot_date' => $date,
                'cost_total' => $costData['cost_total'],
                'cost_per_portion' => $costData['cost_per_portion'] ?? 0,
                'portions' => $costData['portions'] ?? 1,
                'cost_breakdown' => $costData['cost_breakdown'] ?? [],
                'reason' => $reason,
                'created_by_user_id' => $userId,
            ]);

            Log::info('Snapshot de costo creado', [
                'recipe_id' => $recipeId,
                'snapshot_id' => $snapshot->id,
                'cost_total' => (float) $snapshot->cost_total,
                'reason' => $reason,
            ]);

            DB::commit();

            return $snapshot;
        } catch (Throwable $exception) {
            DB::rollBack();

            Log::error('Error creando snapshot de costo', [
                'recipe_id' => $recipeId,
                'error' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }

    public function checkAndCreateIfThresholdExceeded(string $recipeId, float $newCostTotal): bool
    {
        $lastSnapshot = RecipeCostSnapshot::getLatestForRecipe($recipeId);

        if (! $lastSnapshot) {
            $this->createSnapshot($recipeId, RecipeCostSnapshot::REASON_MANUAL);

            return true;
        }

        $oldCost = (float) $lastSnapshot->cost_total;

        if ($oldCost <= 0) {
            return false;
        }

        $percentChange = abs(($newCostTotal - $oldCost) / $oldCost);

        if ($percentChange > self::COST_CHANGE_THRESHOLD) {
            $this->createSnapshot($recipeId, RecipeCostSnapshot::REASON_AUTO_THRESHOLD);

            Log::warning(sprintf('Costo de receta cambió >%.2f%%', self::COST_CHANGE_THRESHOLD * 100), [
                'recipe_id' => $recipeId,
                'old_cost' => $oldCost,
                'new_cost' => $newCostTotal,
                'change_percent' => round($percentChange * 100, 2),
            ]);

            return true;
        }

        return false;
    }

    public function getCostAtDate(string $recipeId, Carbon $date): array
    {
        $snapshot = RecipeCostSnapshot::getForRecipeAtDate($recipeId, $date);

        if ($snapshot) {
            return [
                'recipe_id' => $snapshot->recipe_id,
                'cost_total' => (float) $snapshot->cost_total,
                'cost_per_portion' => (float) $snapshot->cost_per_portion,
                'portions' => (float) $snapshot->portions,
                'cost_breakdown' => $snapshot->cost_breakdown,
                'from_snapshot' => true,
                'snapshot_date' => $snapshot->snapshot_date,
            ];
        }

        Log::warning('No hay snapshot previo, recalculando costo', [
            'recipe_id' => $recipeId,
            'date' => $date->toIso8601String(),
        ]);

        $costData = $this->recipeCostController->calculateCostAtDate($recipeId, $date);
        $costData['from_snapshot'] = false;

        return $costData;
    }

    public function createSnapshotsForAllRecipes(
        string $reason = RecipeCostSnapshot::REASON_SCHEDULED,
        ?Carbon $date = null
    ): int {
        $date = $date ?? now();

        $count = 0;

        Receta::where('activo', true)
            ->orderBy('id')
            ->chunk(100, function ($recipes) use (&$count, $reason, $date) {
                foreach ($recipes as $recipe) {
                    try {
                        $this->createSnapshot($recipe->id, $reason, null, $date);
                        $count++;
                    } catch (Throwable $exception) {
                        Log::error('Error creando snapshot de receta', [
                            'recipe_id' => $recipe->id,
                            'error' => $exception->getMessage(),
                        ]);
                    }
                }
            });

        Log::info('Snapshots masivos completados', [
            'total' => $count,
            'reason' => $reason,
            'date' => $date->toIso8601String(),
        ]);

        return $count;
    }
}
