<?php

namespace App\Services\Inventory;

use App\Models\Inv\Item;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class KardexService
{
    /** @var array<string,int>|null Cached sign map from cat_tipo_mov_inv */
    private ?array $signMap = null;

    public function getKardex(string $itemId, array $filters): array
    {
        $from = $this->dateFrom($filters['from'] ?? null);
        $to = $this->dateTo($filters['to'] ?? null);
        $almacenId = $filters['almacen_id'] ?? null;
        $tipo = $filters['tipo'] ?? null;
        $perPage = min(max((int) ($filters['per_page'] ?? 50), 1), 200);
        $page = max((int) ($filters['page'] ?? 1), 1);

        $item = Item::query()
            ->with('uom')
            ->whereKey($itemId)
            ->firstOrFail();

        $openingBalance = $this->baseMovementQuery($itemId, $almacenId)
            ->where('m.ts', '<', $from)
            ->get()
            ->sum(fn ($row) => $this->signedQuantity($row));

        $periodRows = $this->baseMovementQuery($itemId, $almacenId)
            ->whereBetween('m.ts', [$from, $to])
            ->when($tipo, fn ($query) => $query->where('m.tipo', $tipo))
            ->orderBy('m.ts')
            ->orderBy('m.id')
            ->get();

        $runningBalance = (float) $openingBalance;
        $movementsAsc = $periodRows->map(function ($row) use (&$runningBalance) {
            $signedQuantity = $this->signedQuantity($row);
            $runningBalance += $signedQuantity;

            return $this->formatMovement($row, $runningBalance);
        });

        $total = $movementsAsc->count();
        $pageRows = $movementsAsc
            ->reverse()
            ->values()
            ->forPage($page, $perPage)
            ->values()
            ->all();

        $totals = $this->calculateTotals($periodRows);
        $closingBalance = (float) $openingBalance + $totals['net'];

        return [
            'item' => [
                'id' => (string) $item->id,
                'code' => $item->item_code ?? $item->clave ?? $item->codigo ?? null,
                'nombre' => $item->nombre,
                'uom_base' => $item->uom?->clave ?? $item->unidad_medida,
            ],
            'opening_balance' => $this->roundQuantity($openingBalance),
            'movements' => $pageRows,
            'closing_balance' => $this->roundQuantity($closingBalance),
            'totals' => [
                'entradas' => $this->roundQuantity($totals['entradas']),
                'salidas' => $this->roundQuantity($totals['salidas']),
                'net' => $this->roundQuantity($totals['net']),
                'costo_total' => round($totals['costo_total'], 4),
            ],
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) max(1, ceil($total / $perPage)),
            ],
        ];
    }

    private function baseMovementQuery(string $itemId, ?string $almacenId)
    {
        return DB::connection('pgsql')
            ->table('selemti.mov_inv as m')
            ->leftJoin('selemti.cat_unidades as uo', 'uo.id', '=', 'm.uom_original_id')
            ->leftJoin('selemti.inventory_batch as b', function ($join) {
                $join->on('b.id', '=', DB::raw('COALESCE(m.inventory_batch_id, m.lote_id)'));
            })
            ->leftJoin('selemti.cat_almacenes as a', DB::raw('a.id::text'), '=', 'm.almacen_id')
            ->leftJoin('selemti.users as usr', 'usr.id', '=', DB::raw('COALESCE(m.usuario_id, m.user_id)'))
            ->where('m.item_id', $itemId)
            ->when($almacenId, fn ($query) => $query->where('m.almacen_id', $almacenId))
            ->select([
                'm.id',
                'm.ts',
                'm.tipo',
                'm.ref_tipo',
                'm.ref_id',
                'm.uom',
                'm.qty',
                'm.cantidad',
                'm.qty_original',
                'm.costo_unit',
                'm.almacen_id',
                'm.sucursal_dest',
                'm.notas',
                'm.meta',
                DB::raw('COALESCE(m.inventory_batch_id, m.lote_id) as batch_id'),
                DB::raw('COALESCE(m.usuario_id, m.user_id) as movement_user_id'),
                'uo.clave as uom_original_clave',
                'b.lote_proveedor',
                DB::raw($this->batchExpirySelect().' as batch_caducidad'),
                'a.clave as almacen_clave',
                'a.nombre as almacen_nombre',
                'usr.name as usuario_nombre',
            ]);
    }

    private function calculateTotals(Collection $rows): array
    {
        $totals = [
            'entradas' => 0.0,
            'salidas' => 0.0,
            'net' => 0.0,
            'costo_total' => 0.0,
        ];

        foreach ($rows as $row) {
            $signed = $this->signedQuantity($row);
            $qty = abs($this->rawQuantity($row));
            $cost = $row->costo_unit === null ? null : (float) $row->costo_unit;

            if ($signed >= 0) {
                $totals['entradas'] += $signed;
            } else {
                $totals['salidas'] += abs($signed);
            }

            $totals['net'] += $signed;

            if ($cost !== null) {
                $totals['costo_total'] += $qty * $cost;
            }
        }

        return $totals;
    }

    private function formatMovement(object $row, float $runningBalance): array
    {
        $qty = abs($this->rawQuantity($row));
        $cost = $row->costo_unit === null ? null : (float) $row->costo_unit;
        $batchId = $row->batch_id === null ? null : (int) $row->batch_id;

        return [
            'id' => (int) $row->id,
            'ts' => Carbon::parse($row->ts)->toIso8601String(),
            'tipo' => $row->tipo,
            'tipo_label' => $this->labelFor($row->tipo, $row->ref_tipo),
            'signo' => $this->signFor($row->tipo, $this->rawQuantity($row)),
            'qty_base' => $this->roundQuantity($qty),
            'uom_base' => $row->uom,
            'qty_original' => $row->qty_original === null ? null : $this->roundQuantity(abs((float) $row->qty_original)),
            'uom_original' => $row->uom_original_clave,
            'costo_unit' => $cost === null ? null : round($cost, 4),
            'costo_total' => $cost === null ? null : round($qty * $cost, 4),
            'saldo' => $this->roundQuantity($runningBalance),
            'ref_tipo' => $row->ref_tipo,
            'ref_id' => $row->ref_id === null ? null : (int) $row->ref_id,
            'lote' => $batchId === null ? null : [
                'id' => $batchId,
                'lote_proveedor' => $row->lote_proveedor,
                'fecha_caducidad' => $row->batch_caducidad,
            ],
            'almacen' => $row->almacen_id === null ? null : [
                'id' => (string) $row->almacen_id,
                'clave' => $row->almacen_clave,
                'nombre' => $row->almacen_nombre,
            ],
            'almacen_dest' => $this->destinationWarehouse($row),
            'usuario' => $row->usuario_nombre,
            'notas' => $row->notas,
        ];
    }

    private function destinationWarehouse(object $row): ?array
    {
        $meta = is_string($row->meta) ? json_decode($row->meta, true) : null;
        $destId = $meta['almacen_dest'] ?? $meta['almacen_destino_id'] ?? null;

        if (! $destId) {
            return null;
        }

        $warehouse = DB::connection('pgsql')
            ->table('selemti.cat_almacenes')
            ->where('id', $destId)
            ->first(['id', 'clave', 'nombre']);

        if (! $warehouse) {
            return null;
        }

        return [
            'id' => (string) $warehouse->id,
            'clave' => $warehouse->clave,
            'nombre' => $warehouse->nombre,
        ];
    }

    private function rawQuantity(object $row): float
    {
        return (float) ($row->cantidad ?? $row->qty ?? 0);
    }

    private function signedQuantity(object $row): float
    {
        return abs($this->rawQuantity($row)) * $this->signFor($row->tipo, $this->rawQuantity($row));
    }

    private function signFor(?string $tipo, float $quantity): int
    {
        $legacyTipo = strtoupper((string) $tipo);
        if ($legacyTipo === 'ENTRADA') {
            return 1;
        }

        if (in_array($legacyTipo, ['SALIDA', 'PRODUCCION'], true)) {
            return -1;
        }

        if ($legacyTipo === 'AJUSTE') {
            return $quantity >= 0 ? 1 : -1;
        }

        $map = $this->loadSignMap();

        if (isset($map[$tipo])) {
            $catalogSign = $map[$tipo];

            // Adjustment types: catalog sign is +1 but actual direction comes from quantity
            return $catalogSign === 0 ? ($quantity >= 0 ? 1 : -1) : $catalogSign;
        }

        // Fallback for types not yet in catalog: derive from quantity for AJUSTE* patterns
        if ($tipo !== null && str_starts_with(strtoupper($tipo), 'AJUSTE')) {
            return $quantity >= 0 ? 1 : -1;
        }

        // Unknown tipo: conservative — treat as negative (salida)
        return -1;
    }

    private function loadSignMap(): array
    {
        if ($this->signMap !== null) {
            return $this->signMap;
        }

        try {
            $hasSigno = Schema::connection('pgsql')->hasColumn('selemti.cat_tipo_mov_inv', 'signo');

            if ($hasSigno) {
                $rows = DB::connection('pgsql')
                    ->table('selemti.cat_tipo_mov_inv')
                    ->select('clave', 'signo')
                    ->get();

                $this->signMap = $rows->pluck('signo', 'clave')
                    ->map(fn ($s) => (int) $s)
                    ->all();
            } else {
                // Column not yet migrated — use legacy hardcoded map as fallback
                $this->signMap = [
                    'ENTRADA' => 1,
                    'RECEPCION_COMPRA' => 1,
                    'PRODUCCION_ENTRADA' => 1,
                    'TRASPASO_ENTRADA' => 1,
                    'AJUSTE_ENTRADA' => 1,
                    'APERTURA' => 1,
                    'SALIDA' => -1,
                    'PRODUCCION_SALIDA' => -1,
                    'VENTA_POS' => -1,
                    'TRASPASO_SALIDA' => -1,
                    'AJUSTE_SALIDA' => -1,
                    'MERMA' => -1,
                    'CONSUMO_OPERATIVO' => -1,
                ];
            }
        } catch (\Throwable) {
            $this->signMap = [];
        }

        return $this->signMap;
    }

    private function batchExpirySelect(): string
    {
        $column = Schema::connection('pgsql')->hasColumn('selemti.inventory_batch', 'fecha_caducidad')
            ? 'fecha_caducidad'
            : 'caducidad';

        return 'b.'.$column;
    }

    private function labelFor(?string $tipo, ?string $refTipo): string
    {
        $key = strtoupper((string) $tipo).'|'.strtoupper((string) $refTipo);

        return match ($key) {
            // Canonical tipos
            'RECEPCION_COMPRA|' => 'Recepción de compra',
            'PRODUCCION_ENTRADA|' => 'Entrada por producción',
            'PRODUCCION_SALIDA|' => 'Consumo en producción',
            'TRASPASO_ENTRADA|' => 'Traspaso entrada',
            'TRASPASO_SALIDA|' => 'Traspaso salida',
            'AJUSTE_ENTRADA|' => 'Ajuste positivo (conteo)',
            'AJUSTE_SALIDA|' => 'Ajuste negativo (conteo)',
            'VENTA_POS|' => 'Venta en punto de venta',
            'APERTURA|' => 'Carga inicial de inventario',
            'CONSUMO_OPERATIVO|' => 'Consumo operativo',
            'MERMA|' => 'Merma / pérdida',
            // Legacy tipos (ref_tipo-based)
            'ENTRADA|RECEPCION' => 'Recepción de compra',
            'ENTRADA|PRODUCCION' => 'Entrada por producción',
            'SALIDA|CONSUMO_POS' => 'Consumo POS',
            'SALIDA|PRODUCCION' => 'Consumo en producción',
            'TRASPASO_SALIDA|TRASPASO' => 'Traspaso salida',
            'TRASPASO_ENTRADA|TRASPASO' => 'Traspaso entrada',
            'AJUSTE|CONTEO_FISICO' => 'Ajuste por conteo',
            'AJUSTE|AJUSTE_MANUAL' => 'Ajuste manual',
            default => match (strtoupper((string) $tipo)) {
                'MERMA' => 'Merma / pérdida',
                'ENTRADA', 'RECEPCION_COMPRA' => 'Entrada de inventario',
                'SALIDA', 'PRODUCCION_SALIDA', 'VENTA_POS' => 'Salida de inventario',
                'TRASPASO_SALIDA' => 'Traspaso salida',
                'TRASPASO_ENTRADA' => 'Traspaso entrada',
                'AJUSTE', 'AJUSTE_ENTRADA', 'AJUSTE_SALIDA' => 'Ajuste de inventario',
                'PRODUCCION_ENTRADA' => 'Entrada por producción',
                'APERTURA' => 'Carga inicial',
                default => 'Movimiento de inventario',
            },
        };
    }

    private function dateFrom(?string $value): Carbon
    {
        return $value
            ? Carbon::createFromFormat('Y-m-d', $value)->startOfDay()
            : now()->subDays(30)->startOfDay();
    }

    private function dateTo(?string $value): Carbon
    {
        return $value
            ? Carbon::createFromFormat('Y-m-d', $value)->endOfDay()
            : now()->endOfDay();
    }

    private function roundQuantity(float $value): float
    {
        return round($value, 6);
    }
}
