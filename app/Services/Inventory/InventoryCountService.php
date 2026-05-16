<?php

namespace App\Services\Inventory;

use App\Exceptions\Inventory\InventoryValidationException;
use App\Exceptions\Inventory\ItemNotFoundException;
use App\Models\Inv\Item;
use App\Models\Inventory\InventoryCount;
use App\ValueObjects\SequentialFolio;
use Carbon\CarbonInterface;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class InventoryCountService
{
    protected string $connection;

    protected string $schema;

    public function __construct()
    {
        $this->connection = config('database.default_inventory', 'pgsql');
        $this->schema = config('database.inventory_schema', 'selemti');
    }

    public function createCount(array $data, ?int $userId = null): InventoryCount
    {
        return DB::connection($this->connection)->transaction(function () use ($data, $userId) {
            $now = now();
            $branchId = $data['sucursal_id'] ?? $data['branch_id'] ?? null;
            $warehouseId = $data['almacen_id'] ?? $data['warehouse_id'] ?? null;

            $countId = (int) $this->table('inventory_counts')->insertGetId([
                'folio' => $this->nextFolio($branchId ? (string) $branchId : null),
                'sucursal_id' => $branchId,
                'almacen_id' => $warehouseId,
                'programado_para' => $data['programado_para'] ?? $data['scheduled_for'] ?? null,
                'estado' => InventoryCount::STATUS_DRAFT,
                'creado_por' => $userId ?? $data['user_id'] ?? auth()->id(),
                'notas' => $data['observaciones'] ?? $data['notes'] ?? null,
                'total_items' => 0,
                'total_variacion' => 0,
                'meta' => isset($data['meta']) ? json_encode($data['meta']) : null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            return InventoryCount::query()->with('lines')->findOrFail($countId);
        });
    }

    public function addItemsToCount(int $countId, array $items): array
    {
        return DB::connection($this->connection)->transaction(function () use ($countId, $items) {
            $count = $this->table('inventory_counts')->lockForUpdate()->find($countId);

            if (! $count) {
                throw new ItemNotFoundException('Conteo de inventario no encontrado');
            }

            if ($count->estado !== InventoryCount::STATUS_DRAFT) {
                throw new \RuntimeException("Count must be in BORRADOR status to add items. Current: {$count->estado}");
            }

            $now = now();
            $added = 0;
            $itemIds = collect($items)->pluck('item_id')->filter()->unique();
            $itemsMap = Item::with('uom')->findMany($itemIds)->keyBy('id');

            foreach ($items as $item) {
                $itemId = (string) Arr::get($item, 'item_id');
                $existing = $this->table('inventory_count_lines')
                    ->where('inventory_count_id', $countId)
                    ->where('item_id', $itemId)
                    ->exists();

                if ($existing) {
                    continue;
                }

                $expectedQty = Arr::has($item, 'expected_qty')
                    ? (float) $item['expected_qty']
                    : $this->currentStock($itemId, $count->sucursal_id, $count->almacen_id);

                $line = $this->normalizeLine([
                    'item_id' => $itemId,
                    'expected_qty' => $expectedQty,
                    'counted_qty' => 0,
                    'uom' => $itemsMap->get($itemId)?->uom?->clave ?? Arr::get($item, 'uom', 'PZ'),
                    'source' => 'create_count',
                ], $itemsMap);
                $line['inventory_count_id'] = $countId;
                $line['created_at'] = $now;
                $line['updated_at'] = $now;

                $this->table('inventory_count_lines')->insert($line);
                $added++;
            }

            $this->table('inventory_counts')
                ->where('id', $countId)
                ->update([
                    'total_items' => DB::raw('COALESCE(total_items, 0) + '.$added),
                    'updated_at' => $now,
                ]);

            return ['items_added' => $added];
        });
    }

    public function startCount(int $countId, int $userId): array
    {
        return DB::connection($this->connection)->transaction(function () use ($countId) {
            $count = $this->table('inventory_counts')->lockForUpdate()->find($countId);

            if (! $count) {
                throw new ItemNotFoundException('Conteo de inventario no encontrado');
            }

            if ($count->estado !== InventoryCount::STATUS_DRAFT) {
                throw new \RuntimeException("Count must be in BORRADOR status to be started. Current: {$count->estado}");
            }

            $this->table('inventory_counts')->where('id', $countId)->update([
                'estado' => InventoryCount::STATUS_ABIERTO,
                'iniciado_en' => now(),
                'updated_at' => now(),
            ]);

            return ['count_id' => $countId, 'status' => InventoryCount::STATUS_ABIERTO];
        });
    }

    public function captureLine(int $lineId, float $countedQty, int $userId): array
    {
        return DB::connection($this->connection)->transaction(function () use ($lineId, $countedQty, $userId) {
            $line = $this->table('inventory_count_lines')->where('id', $lineId)->lockForUpdate()->first();

            if (! $line) {
                throw new ItemNotFoundException('Línea de conteo no encontrada');
            }

            $count = $this->table('inventory_counts')->lockForUpdate()->find($line->inventory_count_id);

            if ($count->estado !== InventoryCount::STATUS_ABIERTO) {
                throw new \RuntimeException("Count must be in EN_PROCESO status to capture lines. Current: {$count->estado}");
            }

            $meta = json_decode($line->meta ?? '{}', true) ?: [];
            $meta['capturado_por'] = $userId;
            $meta['capturado_en'] = now()->toIso8601String();
            $variance = $countedQty - (float) $line->qty_teorica;

            $this->table('inventory_count_lines')->where('id', $lineId)->update([
                'qty_contada' => $countedQty,
                'qty_variacion' => $variance,
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);

            return ['line_id' => $lineId, 'capturado' => $countedQty, 'variance' => $variance];
        });
    }

    public function closeCount(int $countId, int $userId): array
    {
        return DB::connection($this->connection)->transaction(function () use ($countId, $userId) {
            $count = $this->table('inventory_counts')->lockForUpdate()->find($countId);

            if (! $count) {
                throw new ItemNotFoundException('Conteo de inventario no encontrado');
            }

            if ($count->estado !== InventoryCount::STATUS_ABIERTO) {
                throw new \RuntimeException("Count must be in EN_PROCESO status to be closed. Current: {$count->estado}");
            }

            $uncaptured = $this->table('inventory_count_lines')
                ->where('inventory_count_id', $countId)
                ->where(function ($query) {
                    $query->whereNull('meta')
                        ->orWhere('meta', 'not like', '%capturado_en%');
                })
                ->exists();

            if ($uncaptured) {
                throw new \RuntimeException('Cannot close count with uncaptured lines');
            }

            $varianceTotal = (float) $this->table('inventory_count_lines')
                ->where('inventory_count_id', $countId)
                ->sum('qty_variacion');

            $this->table('inventory_counts')->where('id', $countId)->update([
                'estado' => InventoryCount::STATUS_CERRADO,
                'cerrado_en' => now(),
                'cerrado_por' => $userId,
                'total_variacion' => $varianceTotal,
                'updated_at' => now(),
            ]);

            return ['count_id' => $countId, 'status' => InventoryCount::STATUS_CERRADO];
        });
    }

    public function open(array $header, array $lines): int
    {
        return DB::connection($this->connection)->transaction(function () use ($header, $lines) {
            $now = now();
            $folio = $this->nextFolio($header['branch_id'] ?? null);

            $countId = (int) $this->table('inventory_counts')->insertGetId([
                'folio' => $folio,
                'sucursal_id' => $header['branch_id'] ?? null,
                'almacen_id' => $header['warehouse_id'] ?? null,
                'programado_para' => $header['scheduled_for'] ?? null,
                'iniciado_en' => $now,
                'estado' => 'EN_PROCESO',
                'creado_por' => $header['user_id'] ?? null,
                'total_items' => 0,
                'total_variacion' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $totals = ['items' => 0.0, 'variance' => 0.0];

            $itemIds = collect($lines)->pluck('item_id')->filter()->unique();
            $itemsMap = Item::with('uom')->findMany($itemIds)->keyBy('id');

            foreach ($lines as $line) {
                $payload = $this->normalizeLine($line, $itemsMap);
                $payload['inventory_count_id'] = $countId;
                $payload['created_at'] = $now;
                $payload['updated_at'] = $now;

                $this->table('inventory_count_lines')->insert($payload);

                $totals['items'] += $payload['qty_teorica'];
            }

            $this->table('inventory_counts')
                ->where('id', $countId)
                ->update([
                    'total_items' => $totals['items'],
                    'updated_at' => $now,
                ]);

            return $countId;
        });
    }

    public function finalize(int $countId, array $lines, int $userId, ?string $notes = null): void
    {
        DB::connection($this->connection)->transaction(function () use ($countId, $lines, $userId, $notes) {
            $now = now();
            $varianceTotal = 0.0;

            $count = $this->table('inventory_counts')->lockForUpdate()->find($countId);

            if (! $count) {
                throw new ItemNotFoundException('Conteo de inventario no encontrado');
            }

            $itemIds = collect($lines)->pluck('item_id')->filter()->unique();
            $itemsMap = Item::with('uom')->findMany($itemIds)->keyBy('id');

            foreach ($lines as $line) {
                $payload = $this->normalizeLine($line, $itemsMap);
                $payload['updated_at'] = $now;

                $existing = $this->table('inventory_count_lines')
                    ->where('inventory_count_id', $countId)
                    ->where('item_id', $payload['item_id'])
                    ->when($payload['inventory_batch_id'], function ($query, $batchId) {
                        $query->where('inventory_batch_id', $batchId);
                    })
                    ->first();

                if ($existing) {
                    $payload['qty_teorica'] = $existing->qty_teorica;
                    $this->table('inventory_count_lines')
                        ->where('id', $existing->id)
                        ->update([
                            'qty_contada' => $payload['qty_contada'],
                            'qty_variacion' => $payload['qty_contada'] - $payload['qty_teorica'],
                            'motivo' => $payload['motivo'],
                            'meta' => $payload['meta'],
                            'updated_at' => $now,
                        ]);

                    $variance = ($payload['qty_contada'] - $payload['qty_teorica']);
                    $varianceTotal += $variance;

                    $this->createAdjustmentMovement(
                        $countId,
                        (string) $existing->item_id,
                        $payload['inventory_batch_id'] ? (int) $payload['inventory_batch_id'] : null,
                        $variance,
                        $payload['uom'],
                        $userId,
                        $now,
                        $count->sucursal_id,
                        $count->almacen_id,
                        $itemsMap
                    );
                } else {
                    $payload['inventory_count_id'] = $countId;
                    $payload['qty_variacion'] = $payload['qty_contada'] - $payload['qty_teorica'];
                    $this->table('inventory_count_lines')->insert(array_merge($payload, [
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]));

                    $varianceTotal += $payload['qty_variacion'];
                    $this->createAdjustmentMovement(
                        $countId,
                        (string) $payload['item_id'],
                        $payload['inventory_batch_id'] ? (int) $payload['inventory_batch_id'] : null,
                        $payload['qty_variacion'],
                        $payload['uom'],
                        $userId,
                        $now,
                        $count->sucursal_id,
                        $count->almacen_id,
                        $itemsMap
                    );
                }
            }

            $this->table('inventory_counts')
                ->where('id', $countId)
                ->update([
                    'estado' => 'AJUSTADO',
                    'cerrado_en' => $now,
                    'cerrado_por' => $userId,
                    'notas' => $notes,
                    'total_variacion' => DB::raw('COALESCE(total_variacion,0) + '.(float) $varianceTotal),
                    'updated_at' => $now,
                ]);
        });
    }

    protected function normalizeLine(array $line, ?\Illuminate\Support\Collection $itemsMap = null): array
    {
        $expected = (float) ($line['expected_qty'] ?? $line['qty_teorica'] ?? 0);
        $counted = (float) ($line['counted_qty'] ?? $line['qty_contada'] ?? 0);

        if (! Arr::has($line, 'item_id')) {
            throw new InventoryValidationException('inventory count line requires item_id');
        }

        $batchId = Arr::get($line, 'inventory_batch_id');
        $batchId = ($batchId === null || $batchId === '') ? null : (int) $batchId;

        $itemId = Arr::get($line, 'item_id');
        $itemModel = $itemsMap?->get($itemId) ?? Item::with('uom')->find($itemId);
        $uomBase = $itemModel?->uom?->clave ?? Arr::get($line, 'uom', 'PZ');

        return [
            'item_id' => (string) Arr::get($line, 'item_id'),
            'inventory_batch_id' => $batchId,
            'qty_teorica' => $expected,
            'qty_contada' => $counted,
            'qty_variacion' => $counted - $expected,
            'uom' => $uomBase,
            'motivo' => Arr::get($line, 'reason'),
            'meta' => $this->buildMeta($line),
        ];
    }

    protected function buildMeta(array $line): ?string
    {
        $meta = Arr::only($line, ['notes', 'source']);
        $meta = array_filter($meta, static fn ($value) => $value !== null && $value !== '');

        return empty($meta) ? null : json_encode($meta);
    }

    protected function nextFolio(?string $branchId = null): string
    {
        return SequentialFolio::generateForBranch(
            prefix: 'CNT',
            table: "{$this->schema}.inventory_counts",
            branchId: $branchId,
            branchColumn: 'sucursal_id',
            connection: $this->connection,
        )->toString();
    }

    protected function createAdjustmentMovement(
        int $countId,
        string $itemId,
        ?int $batchId,
        float $variance,
        string $uom,
        int $userId,
        CarbonInterface $timestamp,
        ?string $branchId = null,
        ?string $warehouseId = null,
        ?\Illuminate\Support\Collection $itemsMap = null
    ): void {
        if (abs($variance) < 0.000001) {
            return;
        }

        $itemModel = $itemsMap?->get($itemId) ?? Item::find($itemId);

        $this->table('mov_inv')->insert([
            'item_id' => $itemId,
            'lote_id' => $batchId,
            'tipo' => 'AJUSTE',
            'cantidad' => $variance,
            'qty_original' => $variance,
            'uom_original_id' => $itemModel?->unidad_medida_id,
            'costo_unit' => 0,
            'sucursal_id' => $branchId,
            'ref_tipo' => 'inventory_count',
            'ref_id' => $countId,
            'usuario_id' => $userId ?: null,
            'ts' => $timestamp,
            'created_at' => $timestamp,
        ]);
    }

    protected function table(string $name)
    {
        return DB::connection($this->connection)->table("{$this->schema}.{$name}");
    }

    protected function currentStock(string $itemId, ?string $branchId, ?string $warehouseId): float
    {
        return (float) $this->table('mov_inv')
            ->where('item_id', $itemId)
            ->when($branchId, fn ($query) => $query->where('sucursal_id', $branchId))
            ->when($warehouseId, fn ($query) => $query->where('almacen_id', $warehouseId))
            ->sum('cantidad');
    }
}
