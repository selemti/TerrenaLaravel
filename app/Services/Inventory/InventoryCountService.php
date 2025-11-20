<?php

namespace App\Services\Inventory;

use Carbon\CarbonInterface;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;
use RuntimeException;

class InventoryCountService
{
    protected string $connection = 'pgsql';

    protected string $schema = 'selemti';

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

            foreach ($lines as $line) {
                $payload = $this->normalizeLine($line);
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
                throw new RuntimeException('Conteo de inventario no encontrado');
            }

            foreach ($lines as $line) {
                $payload = $this->normalizeLine($line);
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
                        $count->almacen_id
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
                        $count->almacen_id
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

    protected function normalizeLine(array $line): array
    {
        $expected = (float) ($line['expected_qty'] ?? $line['qty_teorica'] ?? 0);
        $counted = (float) ($line['counted_qty'] ?? $line['qty_contada'] ?? 0);

        if (! Arr::has($line, 'item_id')) {
            throw new InvalidArgumentException('inventory count line requires item_id');
        }

        $batchId = Arr::get($line, 'inventory_batch_id');
        $batchId = ($batchId === null || $batchId === '') ? null : (int) $batchId;

        return [
            'item_id' => (string) Arr::get($line, 'item_id'),
            'inventory_batch_id' => $batchId,
            'qty_teorica' => $expected,
            'qty_contada' => $counted,
            'qty_variacion' => $counted - $expected,
            'uom' => Arr::get($line, 'uom', 'UND'),
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
        $today = now()->format('Ymd');

        $count = $this->table('inventory_counts')
            ->when($branchId, fn ($query, $branch) => $query->where('sucursal_id', $branch))
            ->whereDate('created_at', now()->toDateString())
            ->count();

        $prefix = $branchId ? Str::upper(Str::slug($branchId, '')) : 'CNT';

        return sprintf('%s-%s-%04d', $prefix, $today, $count + 1);
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
        ?string $warehouseId = null
    ): void {
        if (abs($variance) < 0.000001) {
            return;
        }

        $this->table('mov_inv')->insert([
            'item_id' => $itemId,
            'inventory_batch_id' => $batchId,
            'tipo' => 'AJUSTE',
            'qty' => $variance,
            'uom' => $uom,
            'sucursal_id' => $branchId,
            'almacen_id' => $warehouseId,
            'ref_tipo' => 'inventory_count',
            'ref_id' => $countId,
            'user_id' => $userId ?: null,
            'ts' => $timestamp,
            'meta' => json_encode(['origen' => 'conteo']),
            'notas' => 'Ajuste por conteo',
            'created_at' => $timestamp,
            'updated_at' => $timestamp,
        ]);
    }

    protected function table(string $name)
    {
        return DB::connection($this->connection)->table("{$this->schema}.{$name}");
    }
}
