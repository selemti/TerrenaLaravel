<?php

namespace App\Services\Purchasing;

use App\Adapters\FloreantPos\FloreantPosAdapter;
use App\Services\Inventory\ModifierValidationService;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DemandCalculationService
{
    public function __construct(
        private readonly ModifierValidationService $modifierValidation,
        private readonly FloreantPosAdapter $posAdapter,
    ) {}

    /**
     * Calcula demanda de un modificador usando la relación correcta item_id -> menu_modifier.
     */
    public function calculateModifierDemand(int $modifierId, Carbon $startDate, Carbon $endDate): array
    {
        if ($modifierId <= 0) {
            return [
                'modifier' => null,
                'demand' => collect(),
                'trend' => ['total_units' => 0, 'days' => 0, 'avg_per_day' => 0.0],
                'recommendation' => ['recommended_qty' => 0, 'basis' => 'Sin modificador'],
            ];
        }

        $modifier = $this->modifierValidation->getModifierWithCorrectGroup($modifierId);

        $demand = $this->posAdapter->getModifierDemandByDateRange(
            $modifierId,
            $startDate->toDateTimeString(),
            $endDate->toDateTimeString()
        );

        return [
            'modifier' => $modifier,
            'demand' => $demand,
            'trend' => $this->calculateDemandTrend($demand),
            'recommendation' => $this->generatePurchaseRecommendation($modifier, $demand),
        ];
    }

    /**
     * Resume tendencia simple de unidades por día.
     */
    protected function calculateDemandTrend(Collection $demand): array
    {
        $days = $demand->count();
        $totalUnits = $demand->sum(fn ($row) => (float) ($row->total_units ?? 0));
        $avgPerDay = $days > 0 ? $totalUnits / $days : 0.0;

        return [
            'total_units' => $totalUnits,
            'days' => $days,
            'avg_per_day' => round($avgPerDay, 4),
        ];
    }

    /**
     * Genera recomendación básica de compra basada en promedio diario.
     */
    protected function generatePurchaseRecommendation($modifier, Collection $demand): array
    {
        if ($demand->isEmpty()) {
            return [
                'recommended_qty' => 0,
                'basis' => 'Sin historial en el rango seleccionado',
            ];
        }

        $avgPerDay = $demand->avg(fn ($row) => (float) ($row->total_units ?? 0));
        $peak = $demand->max(fn ($row) => (float) ($row->total_units ?? 0));

        return [
            'recommended_qty' => round($avgPerDay * 3, 2),
            'basis' => 'Promedio diario de los últimos '.$demand->count().' días',
            'peak_day_units' => $peak,
            'modifier_group' => $modifier->group_name ?? null,
        ];
    }
}
