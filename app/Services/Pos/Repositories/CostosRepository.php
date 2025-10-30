<?php

namespace App\Services\Pos\Repositories;

use Illuminate\Support\Facades\DB;

class CostosRepository
{
    /**
     * Obtiene el costo unitario de un item en una UOM específica
     *
     * @param int $itemId
     * @param string $targetUom
     * @return float
     */
    public function getItemUnitCostNow(int $itemId, string $targetUom): float
    {
        $result = DB::connection('pgsql')
            ->select("
                SELECT selemti.fn_item_unit_cost_at(?, NOW(), ?) as costo
            ", [$itemId, $targetUom]);

        return (float) ($result[0]->costo ?? 0.0);
    }

    /**
     * Obtiene el costo de una receta
     *
     * @param int $recipeId
     * @return float
     */
    public function getRecipeCostNow(int $recipeId): float
    {
        $result = DB::connection('pgsql')
            ->select("
                SELECT selemti.fn_recipe_cost_at(?, NOW()) as costo
            ", [$recipeId]);

        return (float) ($result[0]->costo ?? 0.0);
    }

    /**
     * Obtiene el costo de un item en su UOM base
     *
     * @param int $itemId
     * @return float
     */
    public function getItemBaseCost(int $itemId): float
    {
        $result = DB::connection('pgsql')
            ->table('selemti.items')
            ->where('id', $itemId)
            ->value('costo_promedio');

        return (float) ($result ?? 0.0);
    }

    /**
     * Obtiene el histórico de costos de un item
     *
     * @param int $itemId
     * @param string|null $fromDate
     * @param string|null $toDate
     * @return array
     */
    public function getItemCostHistory(int $itemId, ?string $fromDate = null, ?string $toDate = null): array
    {
        $query = DB::connection('pgsql')
            ->table('selemti.item_vendor_prices')
            ->where('item_id', $itemId);

        if ($fromDate) {
            $query->where('effective_date', '>=', $fromDate);
        }

        if ($toDate) {
            $query->where('effective_date', '<=', $toDate);
        }

        $results = $query
            ->orderBy('effective_date', 'desc')
            ->get();

        return $results->map(fn ($row) => (array) $row)->toArray();
    }

    /**
     * Calcula el costo total de un consumo
     *
     * @param array $consumoDetalles Array de detalles con item_id, qty, uom
     * @return float
     */
    public function calcularCostoTotalConsumo(array $consumoDetalles): float
    {
        $costoTotal = 0.0;

        foreach ($consumoDetalles as $detalle) {
            $itemId = $detalle['item_id'] ?? null;
            $qty = (float) ($detalle['qty'] ?? 0);
            $uom = $detalle['uom'] ?? 'UNI';

            if (!$itemId || $qty <= 0) {
                continue;
            }

            $costoUnitario = $this->getItemUnitCostNow($itemId, $uom);
            $costoTotal += $costoUnitario * $qty;
        }

        return $costoTotal;
    }
}
