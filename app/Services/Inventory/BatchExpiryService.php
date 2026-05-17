<?php

namespace App\Services\Inventory;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class BatchExpiryService
{
    public function getExpiringBatches(array $filters): array
    {
        $days = min(max((int) ($filters['days'] ?? 7), 1), 365);
        $perPage = min(max((int) ($filters['per_page'] ?? 50), 1), 200);
        $page = max((int) ($filters['page'] ?? 1), 1);
        $includeExpired = $this->booleanFilter($filters['include_expired'] ?? false);
        $onlyWithQty = array_key_exists('only_with_qty', $filters)
            ? $this->booleanFilter($filters['only_with_qty'])
            : true;

        $rowsQuery = $this->baseQuery($filters, $days, $includeExpired)
            ->when($onlyWithQty, fn (Builder $query) => $query->where('b.cantidad_actual', '>', 0));

        $total = (clone $rowsQuery)->count();
        $batches = (clone $rowsQuery)
            ->orderBy($this->expiryColumnQualified())
            ->orderByDesc('b.cantidad_actual')
            ->offset(($page - 1) * $perPage)
            ->limit($perPage)
            ->get()
            ->map(fn (object $row) => $this->formatBatch($row))
            ->all();

        $summary = $this->summary($filters, $days, $includeExpired);

        return [
            'batches' => $batches,
            'summary' => [
                'expiring_soon' => (int) ($summary->expiring_soon ?? 0),
                'already_expired' => (int) ($summary->already_expired ?? 0),
                'total_exposure' => round((float) ($summary->total_exposure ?? 0), 4),
            ],
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) max(1, ceil($total / $perPage)),
            ],
            'query_date' => $this->queryDate(),
        ];
    }

    private function summary(array $filters, int $days, bool $includeExpired): object
    {
        $summaryRows = $this->baseQuery($filters, $days, $includeExpired)
            ->where('b.cantidad_actual', '>', 0);

        return DB::connection('pgsql')
            ->query()
            ->fromSub($summaryRows, 'expiring')
            ->selectRaw('COUNT(CASE WHEN dias_restantes >= 0 THEN 1 END) as expiring_soon')
            ->selectRaw('COUNT(CASE WHEN dias_restantes < 0 THEN 1 END) as already_expired')
            ->selectRaw('COALESCE(SUM(valor_en_riesgo), 0) as total_exposure')
            ->first();
    }

    private function baseQuery(array $filters, int $days, bool $includeExpired): Builder
    {
        $expiryColumn = $this->expiryColumnQualified();

        return DB::connection('pgsql')
            ->table('selemti.inventory_batch as b')
            ->join('selemti.items as i', 'i.id', '=', DB::raw('b.item_id::text'))
            ->leftJoin('selemti.cat_almacenes as a', DB::raw('a.id::text'), '=', 'b.almacen_id')
            ->whereNotNull($expiryColumn)
            ->whereRaw("{$expiryColumn} <= CURRENT_DATE + (? * INTERVAL '1 day')", [$days])
            ->when(! $includeExpired, fn (Builder $query) => $query->whereRaw("{$expiryColumn} >= CURRENT_DATE"))
            ->when($filters['almacen_id'] ?? null, fn (Builder $query, string $almacenId) => $query->where('b.almacen_id', $almacenId))
            ->select([
                'b.id',
                'b.lote_proveedor',
                'b.item_id',
                'i.item_code',
                'i.nombre as item_nombre',
                DB::raw('COALESCE(b.uom_base, i.unidad_medida) as uom_base'),
                'b.cantidad_actual',
                DB::raw($this->costColumnExpression().' as unit_cost'),
                DB::raw("({$expiryColumn})::date as fecha_caducidad"),
                DB::raw("({$expiryColumn} - CURRENT_DATE) as dias_restantes"),
                'b.almacen_id',
                'a.clave as almacen_clave',
                'a.nombre as almacen_nombre',
                DB::raw('(b.cantidad_actual * '.$this->costColumnExpression().') as valor_en_riesgo'),
            ]);
    }

    private function formatBatch(object $row): array
    {
        $qty = $this->roundQuantity((float) $row->cantidad_actual);
        $unitCost = $row->unit_cost === null ? null : round((float) $row->unit_cost, 4);
        $valueAtRisk = $unitCost === null ? null : round($qty * $unitCost, 4);
        $daysRemaining = (int) $row->dias_restantes;

        return [
            'batch_id' => (int) $row->id,
            'lote' => $row->lote_proveedor,
            'item_id' => (string) $row->item_id,
            'item_code' => $row->item_code,
            'item_nombre' => $row->item_nombre,
            'uom_base' => $row->uom_base,
            'qty_actual' => $qty,
            'costo_unit' => $unitCost,
            'valor_en_riesgo' => $valueAtRisk,
            'fecha_caducidad' => (string) $row->fecha_caducidad,
            'dias_restantes' => $daysRemaining,
            'estado' => $this->estado($daysRemaining),
            'almacen' => $row->almacen_id === null ? null : [
                'id' => (string) $row->almacen_id,
                'clave' => $row->almacen_clave,
                'nombre' => $row->almacen_nombre,
            ],
        ];
    }

    private function estado(int $daysRemaining): string
    {
        if ($daysRemaining < 0) {
            return 'VENCIDO';
        }

        if ($daysRemaining <= 2) {
            return 'CRITICO';
        }

        if ($daysRemaining <= 7) {
            return 'PROXIMO';
        }

        return 'OK';
    }

    private function queryDate(): string
    {
        return (string) DB::connection('pgsql')->selectOne('SELECT CURRENT_DATE::date as today')->today;
    }

    private function expiryColumnQualified(): string
    {
        return 'b.'.$this->expiryColumn();
    }

    private function expiryColumn(): string
    {
        return Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'fecha_caducidad')
            ? 'fecha_caducidad'
            : 'caducidad';
    }

    private function costColumnExpression(): string
    {
        if (Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'unit_cost')) {
            return 'b.unit_cost';
        }

        if (Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'costo_unit')) {
            return 'b.costo_unit';
        }

        return 'NULL::numeric';
    }

    private function roundQuantity(float $value): float
    {
        return round($value, 6);
    }

    private function booleanFilter(mixed $value): bool
    {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN);
    }
}
