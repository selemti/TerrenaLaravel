<?php

namespace App\Services\Menu;

use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class MenuEngineeringService
{
    /**
     * @param  array<string, mixed>  $filters
     * @return Collection<int, array<string, mixed>>
     */
    public function buildSnapshot(array $filters): Collection
    {
        $periodStart = CarbonImmutable::parse($filters['period_start'] ?? 'first day of this month');
        $periodEnd = CarbonImmutable::parse($filters['period_end'] ?? 'last day of this month');

        $sales = $this->querySales($periodStart, $periodEnd, $filters);
        $costs = $this->queryCosts($periodStart, $periodEnd, $sales->keys()->all());

        $popularityTotal = $sales->sum('units');
        $avgSales = $sales->avg('units') ?: 0;
        $avgContribution = $sales->avg('contribution') ?: 0;

        return $sales->map(function (array $row) use ($costs, $popularityTotal, $avgSales, $avgContribution) {
            $costRow = $costs->get($row['menu_item_id'], ['food_cost' => 0, 'avg_cost' => 0]);
            $marginPct = $row['net_sales'] > 0 ? (($row['contribution'] / $row['net_sales']) * 100) : 0;
            $popularityIndex = $popularityTotal > 0 ? ($row['units'] / $popularityTotal) * 100 : 0;

            return [
                'menu_item_id' => $row['menu_item_id'],
                'plu' => $row['plu'],
                'name' => $row['name'],
                'category' => $row['category'],
                'units_sold' => $row['units'],
                'net_sales' => $row['net_sales'],
                'avg_price' => $row['avg_price'],
                'food_cost' => $costRow['food_cost'],
                'avg_cost' => $costRow['avg_cost'],
                'contribution' => $row['contribution'],
                'margin_pct' => round($marginPct, 2),
                'popularity_index' => round($popularityIndex, 2),
                'classification' => $this->classify($row['units'], $row['contribution'], $avgSales, $avgContribution),
            ];
        })->values();
    }

    protected function querySales(CarbonImmutable $start, CarbonImmutable $end, array $filters): Collection
    {
        $query = DB::connection('pgsql')
            ->table('public.ticket_item as ti')
            ->selectRaw('mi.id as menu_item_id, mi.plu, mi.name, mi.category, SUM(ti.item_quantity) as units, SUM(ti.item_subtotal) as net_sales, AVG(ti.item_price) as avg_price')
            ->join('selemti.menu_item_sync_map as map', 'map.pos_identifier', '=', 'ti.item_id')
            ->join('selemti.menu_items as mi', 'mi.id', '=', 'map.menu_item_id')
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereBetween('t.paid_time', [$start->startOfDay(), $end->endOfDay()])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('mi.id', 'mi.plu', 'mi.name', 'mi.category');

        if ($filters['category'] ?? null) {
            $query->where('mi.category', $filters['category']);
        }

        if ($filters['sucursal_id'] ?? null) {
            $query->where('t.terminal_id', $filters['sucursal_id']);
        }

        return collect($query->get())->map(function ($row) {
            $netSales = (float) $row->net_sales;
            $units = (float) $row->units;
            $avgPrice = (float) $row->avg_price;
            $contribution = $netSales; // se ajustará luego con costos

            return [
                'menu_item_id' => (int) $row->menu_item_id,
                'plu' => $row->plu,
                'name' => $row->name,
                'category' => $row->category,
                'units' => $units,
                'net_sales' => $netSales,
                'avg_price' => $avgPrice,
                'contribution' => $contribution,
            ];
        })->keyBy('menu_item_id');
    }

    protected function queryCosts(CarbonImmutable $start, CarbonImmutable $end, array $menuItemIds): Collection
    {
        if ($menuItemIds === []) {
            return collect();
        }

        $rows = DB::connection('pgsql')
            ->table('selemti.menu_items as mi')
            ->selectRaw('mi.id, AVG(costs.cost_per_portion) as avg_cost, SUM(costs.cost_per_portion * metrics.units) as total_cost')
            ->leftJoin('selemti.menu_engineering_snapshots as snap', function ($join) use ($start, $end) {
                $join->on('snap.menu_item_id', '=', 'mi.id')
                    ->whereBetween('snap.period_start', [$start->startOfDay(), $end->endOfDay()]);
            })
            ->leftJoinSub($this->recipeCostSubquery($start, $end), 'costs', 'costs.menu_item_id', '=', 'mi.id')
            ->leftJoinSub($this->salesMetricsSubquery($start, $end), 'metrics', 'metrics.menu_item_id', '=', 'mi.id')
            ->whereIn('mi.id', $menuItemIds)
            ->groupBy('mi.id')
            ->get();

        return collect($rows)->mapWithKeys(function ($row) {
            $units = (float) ($row->units ?? 0);
            $totalCost = (float) ($row->total_cost ?? 0);
            $foodCost = $units > 0 ? $totalCost : (float) ($row->avg_cost ?? 0);

            return [
                (int) $row->id => [
                    'avg_cost' => round((float) ($row->avg_cost ?? 0), 2),
                    'food_cost' => round($foodCost, 2),
                ],
            ];
        });
    }

    protected function recipeCostSubquery(CarbonImmutable $start, CarbonImmutable $end)
    {
        return DB::connection('pgsql')
            ->table('selemti.menu_items as mi')
            ->selectRaw('mi.id as menu_item_id, AVG(rc.cost_per_portion) as cost_per_portion')
            ->join('selemti.recipes as r', 'r.id', '=', 'mi.recipe_id')
            ->join('selemti.recipe_cost_history as rc', function ($join) use ($start, $end) {
                $join->on('rc.recipe_id', '=', 'r.id')
                    ->whereBetween('rc.snapshot_at', [$start->startOfDay(), $end->endOfDay()]);
            })
            ->groupBy('mi.id');
    }

    protected function salesMetricsSubquery(CarbonImmutable $start, CarbonImmutable $end)
    {
        return DB::connection('pgsql')
            ->table('public.ticket_item as ti')
            ->selectRaw('mi.id as menu_item_id, SUM(ti.item_quantity) as units')
            ->join('selemti.menu_item_sync_map as map', 'map.pos_identifier', '=', 'ti.item_id')
            ->join('selemti.menu_items as mi', 'mi.id', '=', 'map.menu_item_id')
            ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
            ->whereBetween('t.paid_time', [$start->startOfDay(), $end->endOfDay()])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->groupBy('mi.id');
    }

    protected function classify(float $units, float $contribution, float $avgUnits, float $avgContribution): string
    {
        $popular = $avgUnits > 0 && $units >= $avgUnits;
        $profitable = $avgContribution > 0 && $contribution >= $avgContribution;

        return match (true) {
            $popular && $profitable => 'estrella',
            $popular && ! $profitable => 'vaca',
            ! $popular && $profitable => 'puzzle',
            default => 'perro',
        };
    }
}
