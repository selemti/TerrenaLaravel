<?php

namespace App\Services\Inventory;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class InventoryValuationService
{
    public function getValuation(array $filters): array
    {
        $perPage = min(max((int) ($filters['per_page'] ?? 50), 1), 200);
        $page = max((int) ($filters['page'] ?? 1), 1);
        $onlyWithStock = $this->booleanFilter($filters['only_with_stock'] ?? true);
        $almacenId = $filters['almacen_id'] ?? null;

        $rowsQuery = $this->valuationRowsQuery(array_merge($filters, [
            'almacen_id' => $almacenId,
            'only_with_stock' => $onlyWithStock,
        ]));

        $summary = DB::connection('pgsql')
            ->query()
            ->fromSub(clone $rowsQuery, 'valuation')
            ->selectRaw('COUNT(*) as total_items')
            ->selectRaw('COALESCE(SUM(current_stock), 0) as total_qty')
            ->selectRaw('COALESCE(SUM(COALESCE(valor_total, 0)), 0) as total_value')
            ->first();

        $total = (int) ($summary->total_items ?? 0);
        $items = DB::connection('pgsql')
            ->query()
            ->fromSub($rowsQuery, 'valuation')
            ->orderByRaw('CASE WHEN valor_total IS NULL THEN 1 ELSE 0 END ASC')
            ->orderByDesc('valor_total')
            ->orderBy('item_nombre')
            ->offset(($page - 1) * $perPage)
            ->limit($perPage)
            ->get()
            ->map(fn (object $row) => $this->formatRow($row))
            ->all();

        return [
            'items' => $items,
            'summary' => [
                'total_items' => $total,
                'total_value' => $this->roundMoney((float) ($summary->total_value ?? 0)),
                'total_qty' => $this->roundQuantity((float) ($summary->total_qty ?? 0)),
                'currency' => 'MXN',
            ],
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) max(1, ceil($total / $perPage)),
            ],
            'filters_applied' => [
                'almacen_id' => $almacenId,
                'only_with_stock' => $onlyWithStock,
            ],
        ];
    }

    private function valuationRowsQuery(array $filters): Builder
    {
        $almacenId = $filters['almacen_id'] ?? null;
        $onlyWithStock = (bool) ($filters['only_with_stock'] ?? true);
        $hasItemAlmacenId = $this->itemsHasColumn('almacen_id');
        $hasItemSucursalId = $this->itemsHasColumn('sucursal_id');
        $categoryColumn = $this->categoryColumn();

        $stockSubquery = DB::connection('pgsql')
            ->table('selemti.mov_inv as m')
            ->select([
                'm.item_id',
                DB::raw('SUM(COALESCE(m.cantidad, m.qty, 0)) as current_stock'),
            ])
            ->when($almacenId, fn (Builder $query, string $id) => $query->where('m.almacen_id', $id))
            ->groupBy('m.item_id');

        $currentStock = 'COALESCE(stock.current_stock, 0)';
        $valorTotal = "CASE WHEN i.costo_promedio IS NULL OR i.costo_promedio = 0 THEN NULL ELSE {$currentStock} * i.costo_promedio END";

        $query = DB::connection('pgsql')
            ->table('selemti.items as i')
            ->leftJoinSub($stockSubquery, 'stock', 'stock.item_id', '=', 'i.id')
            ->leftJoin('selemti.cat_unidades as u', 'u.id', '=', 'i.unidad_medida_id')
            ->where('i.activo', true)
            ->when($onlyWithStock, fn (Builder $query) => $query->whereRaw($currentStock.' > 0'))
            ->when(($filters['sucursal_id'] ?? null) && $hasItemSucursalId, function (Builder $query) use ($filters) {
                $query->where('i.sucursal_id', $filters['sucursal_id']);
            })
            ->when(($filters['categoria'] ?? null) && $categoryColumn !== null, function (Builder $query) use ($filters, $categoryColumn) {
                $query->where("i.{$categoryColumn}", $filters['categoria']);
            });

        if ($almacenId !== null) {
            $query->leftJoin('selemti.cat_almacenes as a', function ($join) use ($almacenId) {
                $join->whereRaw('CAST(a.id AS TEXT) = CAST(? AS TEXT)', [$almacenId]);
            });
        } elseif ($hasItemAlmacenId) {
            $query->leftJoin('selemti.cat_almacenes as a', DB::raw('CAST(a.id AS TEXT)'), '=', 'i.almacen_id');
        }

        $query->select([
            'i.id as item_id',
            'i.item_code',
            'i.nombre as item_nombre',
            DB::raw('COALESCE(u.clave, i.unidad_medida) as uom_base'),
            DB::raw($currentStock.' as current_stock'),
            'i.costo_promedio',
            DB::raw($valorTotal.' as valor_total'),
        ]);

        if ($almacenId !== null) {
            $query->selectRaw('CAST(? AS TEXT) as almacen_id', [$almacenId])
                ->addSelect([
                    'a.clave as almacen_clave',
                    'a.nombre as almacen_nombre',
                ]);
        } elseif ($hasItemAlmacenId) {
            $query->addSelect([
                'i.almacen_id',
                'a.clave as almacen_clave',
                'a.nombre as almacen_nombre',
            ]);
        } else {
            $query->selectRaw('NULL as almacen_id')
                ->selectRaw('NULL as almacen_clave')
                ->selectRaw('NULL as almacen_nombre');
        }

        return $query;
    }

    private function formatRow(object $row): array
    {
        return [
            'item_id' => (string) $row->item_id,
            'item_code' => $row->item_code,
            'item_nombre' => $row->item_nombre,
            'uom_base' => $row->uom_base,
            'current_stock' => $this->roundQuantity((float) $row->current_stock),
            'costo_promedio' => $row->costo_promedio === null ? null : round((float) $row->costo_promedio, 4),
            'valor_total' => $row->valor_total === null ? null : $this->roundMoney((float) $row->valor_total),
            'almacen' => $row->almacen_id === null ? null : [
                'id' => (string) $row->almacen_id,
                'clave' => $row->almacen_clave,
                'nombre' => $row->almacen_nombre,
            ],
        ];
    }

    private function booleanFilter(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) ?? true;
    }

    private function itemsHasColumn(string $column): bool
    {
        return Schema::connection('pgsql')->hasColumn('selemti.items', $column);
    }

    private function categoryColumn(): ?string
    {
        foreach (['categoria', 'categoria_id', 'category_id'] as $column) {
            if ($this->itemsHasColumn($column)) {
                return $column;
            }
        }

        return null;
    }

    private function roundQuantity(float $value): float
    {
        return round($value, 6);
    }

    private function roundMoney(float $value): float
    {
        return round($value, 4);
    }
}
