<?php

namespace App\Services\Inventory;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class StockAlertService
{
    public function getAlerts(array $filters): array
    {
        $perPage = min(max((int) ($filters['per_page'] ?? 50), 1), 200);
        $page = max((int) ($filters['page'] ?? 1), 1);

        $rows = $this->alertRows($filters);
        $total = $rows->count();
        $alerts = $rows
            ->forPage($page, $perPage)
            ->values()
            ->map(fn (object $row) => $this->formatAlert($row))
            ->all();

        return [
            'alerts' => $alerts,
            'summary' => [
                'total_alerts' => $total,
                'critical' => $rows->where('severity', 'critical')->count(),
                'low' => $rows->where('severity', 'low')->count(),
                'total_shortage' => $this->roundQuantity($rows->sum('shortage_qty')),
            ],
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) max(1, ceil($total / $perPage)),
            ],
        ];
    }

    private function alertRows(array $filters): Collection
    {
        $stockSubquery = DB::connection('pgsql')
            ->table('selemti.mov_inv as m')
            ->select([
                'm.item_id',
                'm.almacen_id',
                DB::raw('SUM(COALESCE(m.cantidad, m.qty, 0)) as current_stock'),
            ])
            ->groupBy('m.item_id', 'm.almacen_id');

        $currentStock = 'COALESCE(SUM(stock.current_stock), 0)';
        $shortage = '(p.min_qty - '.$currentStock.')';

        return DB::connection('pgsql')
            ->table('selemti.stock_policy as p')
            ->join('selemti.items as i', 'i.id', '=', 'p.item_id')
            ->leftJoinSub($stockSubquery, 'stock', function ($join) {
                $join->on('stock.item_id', '=', 'p.item_id')
                    ->where(function ($query) {
                        $query->whereNull('p.almacen_id')
                            ->orWhereColumn('stock.almacen_id', 'p.almacen_id');
                    });
            })
            ->leftJoin('selemti.cat_unidades as u', 'u.id', '=', 'i.unidad_medida_id')
            ->leftJoin('selemti.cat_almacenes as a', DB::raw('CAST(a.id AS TEXT)'), '=', 'p.almacen_id')
            ->where('p.activo', true)
            ->when($filters['sucursal_id'] ?? null, fn ($query, $sucursalId) => $query->where('p.sucursal_id', $sucursalId))
            ->when($filters['almacen_id'] ?? null, fn ($query, $almacenId) => $query->where('p.almacen_id', $almacenId))
            ->select([
                'p.item_id',
                'i.item_code',
                'i.nombre as item_nombre',
                DB::raw('COALESCE(u.clave, i.unidad_medida) as uom_base'),
                'p.min_qty',
                'p.max_qty',
                'p.reorder_lote',
                'p.almacen_id',
                'a.clave as almacen_clave',
                'a.nombre as almacen_nombre',
                'i.costo_promedio',
                DB::raw($currentStock.' as current_stock'),
                DB::raw($shortage.' as shortage_qty'),
                DB::raw("CASE WHEN {$currentStock} <= 0 THEN 'critical' ELSE 'low' END as severity"),
            ])
            ->groupBy([
                'p.id',
                'p.item_id',
                'i.item_code',
                'i.nombre',
                'u.clave',
                'i.unidad_medida',
                'p.min_qty',
                'p.max_qty',
                'p.reorder_lote',
                'p.almacen_id',
                'a.clave',
                'a.nombre',
                'i.costo_promedio',
            ])
            ->havingRaw($currentStock.' < p.min_qty')
            ->when($filters['severity'] ?? null, function ($query, string $severity) use ($currentStock) {
                if ($severity === 'critical') {
                    $query->havingRaw($currentStock.' <= 0');
                } elseif ($severity === 'low') {
                    $query->havingRaw($currentStock.' > 0');
                }
            })
            ->orderByRaw("CASE WHEN {$currentStock} <= 0 THEN 1 ELSE 0 END DESC")
            ->orderByRaw($shortage.' DESC')
            ->get();
    }

    private function formatAlert(object $row): array
    {
        $currentStock = $this->roundQuantity((float) $row->current_stock);
        $minQty = $this->roundQuantity((float) $row->min_qty);
        $maxQty = $row->max_qty === null ? null : $this->roundQuantity((float) $row->max_qty);
        $reorderQty = $this->reorderQuantity($row, $currentStock);
        $cost = $row->costo_promedio === null ? null : round((float) $row->costo_promedio, 4);

        return [
            'item_id' => (string) $row->item_id,
            'item_code' => $row->item_code,
            'item_nombre' => $row->item_nombre,
            'uom_base' => $row->uom_base,
            'current_stock' => $currentStock,
            'min_qty' => $minQty,
            'max_qty' => $maxQty,
            'shortage_qty' => $this->roundQuantity((float) $row->shortage_qty),
            'reorder_qty' => $reorderQty,
            'severity' => $row->severity,
            'almacen' => $row->almacen_id === null ? null : [
                'id' => (string) $row->almacen_id,
                'clave' => $row->almacen_clave,
                'nombre' => $row->almacen_nombre,
            ],
            'costo_promedio' => $cost,
            'costo_reponer' => $reorderQty === null || $cost === null
                ? null
                : round($reorderQty * $cost, 4),
        ];
    }

    private function reorderQuantity(object $row, float $currentStock): ?float
    {
        if ($row->reorder_lote !== null) {
            return $this->roundQuantity((float) $row->reorder_lote);
        }

        if ($row->max_qty !== null) {
            return $this->roundQuantity((float) $row->max_qty - $currentStock);
        }

        return null;
    }

    private function roundQuantity(float $value): float
    {
        return round($value, 6);
    }
}
