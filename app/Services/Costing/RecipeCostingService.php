<?php

namespace App\Services\Costing;

use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class RecipeCostingService
{
    public function __construct(
        private readonly string $connection = 'pgsql'
    ) {
    }

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
}
