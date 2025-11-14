<?php

namespace App\Services\Costing;

use App\Models\Rec\RecipeCostSnapshot;
use Carbon\CarbonInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class RecipeCostingService
{
    public function __construct(
        private readonly string $connection = 'pgsql'
    ) {}

    public function calculate(int $recipeId, ?CarbonInterface $at = null): array
    {
        $at = $at?->toDateTimeString() ?? now()->toDateTimeString();

        $mpCost = $this->resolveMaterialCost($recipeId, $at);
        $labor = $this->resolveLaborCost($recipeId, $at, $mpCost);
        $overhead = $this->resolveOverheadCost($recipeId, $at, $mpCost, $labor);

        $yield = $mpCost['yield_portions'] ?? 0;
        $totalBatch = $mpCost['batch_cost'] + $labor['batch_cost'] + $overhead['batch_cost'];
        $portionCost = $yield > 0 ? $totalBatch / $yield : 0;

        return [
            'recipe_id' => $recipeId,
            'at' => $at,
            'yield_portions' => $yield,
            'material' => $mpCost,
            'labor' => $labor,
            'overhead' => $overhead,
            'total_batch_cost' => $totalBatch,
            'portion_cost' => $portionCost,
        ];
    }

    public function snapshot(int $recipeId, ?CarbonInterface $at = null): array
    {
        $data = $this->calculate($recipeId, $at);

        if (! Schema::connection($this->connection)->hasTable('recipe_extended_cost_history')) {
            return $data;
        }

        DB::connection($this->connection)->table('recipe_extended_cost_history')->insert([
            'recipe_id' => $recipeId,
            'snapshot_at' => $data['at'],
            'mp_batch_cost' => $data['material']['batch_cost'],
            'labor_batch_cost' => $data['labor']['batch_cost'],
            'overhead_batch_cost' => $data['overhead']['batch_cost'],
            'total_batch_cost' => $data['total_batch_cost'],
            'portion_cost' => $data['portion_cost'],
            'yield_portions' => $data['yield_portions'],
            'breakdown' => json_encode([
                'material' => $data['material'],
                'labor' => $data['labor'],
                'overhead' => $data['overhead'],
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $data;
    }

    protected function resolveMaterialCost(int $recipeId, string $at): array
    {
        try {
            $row = DB::connection($this->connection)->selectOne(
                'select * from selemti.fn_recipe_cost_at(?, ?)',
                [$recipeId, $at]
            );
        } catch (\Throwable $e) {
            Log::warning('Error fetching recipe MP cost', ['recipe_id' => $recipeId, 'error' => $e->getMessage()]);
            $row = null;
        }

        if (! $row) {
            return [
                'batch_cost' => 0.0,
                'portion_cost' => 0.0,
                'yield_portions' => 0.0,
                'details' => [],
            ];
        }

        $data = (array) $row;

        return [
            'batch_cost' => (float) ($data['batch_cost'] ?? $data['batch_total'] ?? 0),
            'portion_cost' => (float) ($data['portion_cost'] ?? $data['portion_total'] ?? 0),
            'yield_portions' => (float) ($data['yield_portions'] ?? $data['yield'] ?? 0),
            'details' => $data,
        ];
    }

    protected function resolveLaborCost(int $recipeId, string $at, array $mpCost): array
    {
        if (! Schema::connection($this->connection)->hasTable('recipe_labor_steps')) {
            return ['batch_cost' => 0.0, 'steps' => [], 'total_minutes' => 0.0];
        }

        $steps = DB::connection($this->connection)
            ->table('recipe_labor_steps as rls')
            ->select([
                'rls.id',
                'rls.nombre',
                'rls.duracion_minutos',
                'rls.costo_manual',
                'rls.orden',
                'lr.rate_per_hour',
            ])
            ->leftJoin('labor_roles as lr', 'lr.id', '=', 'rls.labor_role_id')
            ->where('rls.recipe_id', $recipeId)
            ->orderBy('rls.orden')
            ->get();

        $total = 0.0;
        $totalMinutes = 0.0;
        $normalized = [];

        foreach ($steps as $step) {
            $duration = (float) $step->duracion_minutos;
            $rate = (float) ($step->rate_per_hour ?? 0);
            $manual = $step->costo_manual !== null ? (float) $step->costo_manual : null;
            $cost = $manual ?? ($rate * ($duration / 60));
            $total += $cost;
            $totalMinutes += $duration;

            $normalized[] = [
                'id' => $step->id,
                'nombre' => $step->nombre,
                'duracion_minutos' => $duration,
                'rate_per_hour' => $rate,
                'costo_calculado' => $cost,
                'costo_manual' => $manual,
            ];
        }

        return [
            'batch_cost' => round($total, 6),
            'steps' => $normalized,
            'total_minutes' => $totalMinutes,
        ];
    }

    protected function resolveOverheadCost(int $recipeId, string $at, array $mpCost, array $laborCost): array
    {
        if (! Schema::connection($this->connection)->hasTable('recipe_overhead_allocations')) {
            return ['batch_cost' => 0.0, 'items' => []];
        }

        $rows = DB::connection($this->connection)
            ->table('recipe_overhead_allocations as roa')
            ->join('overhead_definitions as od', 'od.id', '=', 'roa.overhead_id')
            ->select([
                'od.id',
                'od.clave',
                'od.nombre',
                'od.tipo',
                'od.tasa',
                'roa.valor',
            ])
            ->where('roa.recipe_id', $recipeId)
            ->where('od.activo', true)
            ->get();

        $items = [];
        $total = 0.0;
        $mpBatch = $mpCost['batch_cost'] ?? 0.0;
        $laborBatch = $laborCost['batch_cost'] ?? 0.0;
        $laborMinutes = $laborCost['total_minutes'] ?? 0.0;

        foreach ($rows as $row) {
            $amount = $row->valor !== null ? (float) $row->valor : 0.0;

            if ($row->tipo === 'per_hour') {
                $hours = $laborMinutes > 0 ? $laborMinutes / 60 : 0;
                $amount = (float) $row->tasa * $hours;
            } elseif ($row->tipo === 'pct_mp') {
                $amount = $mpBatch * ((float) $row->tasa);
            } elseif ($row->tipo === 'fixed_per_batch' && $row->valor === null) {
                $amount = (float) $row->tasa;
            }

            $total += $amount;
            $items[] = [
                'id' => $row->id,
                'clave' => $row->clave,
                'tipo' => $row->tipo,
                'tasa' => (float) $row->tasa,
                'valor' => $row->valor !== null ? (float) $row->valor : null,
                'monto' => round($amount, 6),
            ];
        }

        return [
            'batch_cost' => round($total, 6),
            'items' => $items,
        ];
    }

    /**
     * Create a cost snapshot for a recipe
     * Uses sp_snapshot_recipe_cost stored procedure
     */
    public function createSnapshot(int $recipeId, ?CarbonInterface $at = null, ?string $notes = null): RecipeCostSnapshot
    {
        $at = $at ?? now();

        // Call stored procedure to create snapshot
        DB::connection($this->connection)->statement(
            'SELECT selemti.sp_snapshot_recipe_cost(?, ?)',
            [$recipeId, $at->toDateTimeString()]
        );

        // Retrieve the created snapshot
        $snapshot = RecipeCostSnapshot::forRecipe($recipeId)
            ->where('snapshot_at', $at->toDateTimeString())
            ->latest()
            ->firstOrFail();

        // Update notes if provided
        if ($notes) {
            $snapshot->notes = $notes;
            $snapshot->save();
        }

        return $snapshot;
    }

    /**
     * Get cost history for a recipe
     */
    public function getHistory(
        int $recipeId,
        ?CarbonInterface $from = null,
        ?CarbonInterface $to = null,
        int $limit = 100
    ): Collection {
        $query = RecipeCostSnapshot::forRecipe($recipeId)->latest();

        if ($from && $to) {
            $query->betweenDates($from->toDateTimeString(), $to->toDateTimeString());
        } elseif ($from) {
            $query->where('snapshot_at', '>=', $from->toDateTimeString());
        } elseif ($to) {
            $query->where('snapshot_at', '<=', $to->toDateTimeString());
        }

        return $query->limit($limit)->get();
    }

    /**
     * Get latest snapshot for a recipe
     */
    public function getLatestSnapshot(int $recipeId): ?RecipeCostSnapshot
    {
        return RecipeCostSnapshot::forRecipe($recipeId)
            ->latest()
            ->first();
    }

    /**
     * Compare two snapshots and calculate variance
     */
    public function compareSnapshots(RecipeCostSnapshot $current, RecipeCostSnapshot $previous): array
    {
        $portionDiff = $current->portion_cost - $previous->portion_cost;
        $portionPct = $previous->portion_cost > 0
            ? ($portionDiff / $previous->portion_cost) * 100
            : 0;

        $batchDiff = $current->batch_cost - $previous->batch_cost;
        $batchPct = $previous->batch_cost > 0
            ? ($batchDiff / $previous->batch_cost) * 100
            : 0;

        return [
            'current' => [
                'id' => $current->id,
                'snapshot_at' => $current->snapshot_at,
                'portion_cost' => $current->portion_cost,
                'batch_cost' => $current->batch_cost,
            ],
            'previous' => [
                'id' => $previous->id,
                'snapshot_at' => $previous->snapshot_at,
                'portion_cost' => $previous->portion_cost,
                'batch_cost' => $previous->batch_cost,
            ],
            'variance' => [
                'portion_diff' => round($portionDiff, 4),
                'portion_pct' => round($portionPct, 2),
                'batch_diff' => round($batchDiff, 4),
                'batch_pct' => round($batchPct, 2),
                'days_between' => $previous->snapshot_at->diffInDays($current->snapshot_at),
            ],
        ];
    }

    /**
     * Check if cost variance exceeds threshold (for auto-snapshot triggers)
     */
    public function shouldCreateAutoSnapshot(int $recipeId, float $thresholdPct = 2.0): bool
    {
        $latest = $this->getLatestSnapshot($recipeId);

        if (! $latest) {
            return true; // No snapshot exists, create first one
        }

        // Calculate current cost
        $current = $this->calculate($recipeId);
        $currentPortionCost = $current['portion_cost'];
        $latestPortionCost = $latest->portion_cost;

        if ($latestPortionCost == 0) {
            return false;
        }

        $variance = abs(($currentPortionCost - $latestPortionCost) / $latestPortionCost) * 100;

        return $variance >= $thresholdPct;
    }
}
