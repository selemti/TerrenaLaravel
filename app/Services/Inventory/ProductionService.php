<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class ProductionService
{
    public function createOrder(array $header, array $inputs, array $outputs, array $wastes = []): int
    {
        if (empty($inputs)) {
            throw new InvalidArgumentException('Debe registrar al menos un insumo a consumir.');
        }

        if (empty($outputs)) {
            throw new InvalidArgumentException('Debe registrar al menos un producto terminado.');
        }

        return DB::transaction(function () use ($header, $inputs, $outputs, $wastes) {
            $now = now();
            $folio = $this->buildSequentialNumber();

            $orderData = [
                'folio'          => $folio,
                'recipe_id'      => $header['recipe_id'] ?? null,
                'item_id'        => $header['item_id'] ?? null,
                'qty_programada' => (float) ($header['scheduled_qty'] ?? 0),
                'qty_producida'  => 0,
                'qty_merma'      => 0,
                'uom_base'       => $header['uom'] ?? null,
                'sucursal_id'    => $header['branch_id'] ?? null,
                'almacen_id'     => $header['warehouse_id'] ?? null,
                'programado_para'=> $header['scheduled_at'] ?? null,
                'iniciado_en'    => $now,
                'estado'         => 'EN_PROCESO',
                'creado_por'     => $header['user_id'] ?? null,
                'notas'          => $header['notes'] ?? null,
                'meta'           => isset($header['meta']) ? json_encode($header['meta']) : null,
                'created_at'     => $now,
                'updated_at'     => $now,
            ];

            $orderId = (int) DB::table('production_orders')->insertGetId($orderData);

            $totals = [
                'produced' => 0.0,
                'waste'    => 0.0,
            ];

            foreach ($inputs as $input) {
                $normalized = $this->normalizeInput($input);
                $normalized['production_order_id'] = $orderId;
                $normalized['created_at'] = $now;
                $normalized['updated_at'] = $now;

                DB::table('production_order_inputs')->insert($normalized);

                $movement = [
                    'item_id'            => $normalized['item_id'],
                    'inventory_batch_id' => $normalized['inventory_batch_id'],
                    'tipo'               => 'PROD_OUT',
                    'qty'                => $normalized['qty'],
                    'uom'                => $normalized['uom'],
                    'sucursal_id'        => $header['branch_id'] ?? null,
                    'almacen_id'         => $header['warehouse_id'] ?? null,
                    'ref_tipo'           => 'production_order',
                    'ref_id'             => $orderId,
                    'user_id'            => $header['user_id'] ?? null,
                    'ts'                 => $now,
                    'meta'               => $normalized['meta'],
                    'created_at'         => $now,
                    'updated_at'         => $now,
                ];

                DB::table('mov_inv')->insert($movement);
            }

            foreach ($outputs as $output) {
                $normalized = $this->normalizeOutput($output, $header, $now);
                $normalized['production_order_id'] = $orderId;
                $normalized['created_at'] = $now;
                $normalized['updated_at'] = $now;

                DB::table('production_order_outputs')->insert($normalized);

                $totals['produced'] += $normalized['qty'];

                DB::table('mov_inv')->insert([
                    'item_id'            => $normalized['item_id'],
                    'inventory_batch_id' => $normalized['inventory_batch_id'],
                    'tipo'               => 'PROD_IN',
                    'qty'                => $normalized['qty'],
                    'uom'                => $normalized['uom'],
                    'sucursal_id'        => $header['branch_id'] ?? null,
                    'almacen_id'         => $header['warehouse_id'] ?? null,
                    'ref_tipo'           => 'production_order',
                    'ref_id'             => $orderId,
                    'user_id'            => $header['user_id'] ?? null,
                    'ts'                 => $now,
                    'meta'               => $normalized['meta'],
                    'created_at'         => $now,
                    'updated_at'         => $now,
                ]);
            }

            foreach ($wastes as $waste) {
                $normalized = $this->normalizeWaste($waste, $header, $now);
                $normalized['production_order_id'] = $orderId;
                $normalized['created_at'] = $now;
                $normalized['updated_at'] = $now;

                DB::table('inventory_wastes')->insert($normalized);

                $totals['waste'] += $normalized['qty'];

                DB::table('mov_inv')->insert([
                    'item_id'            => $normalized['item_id'],
                    'inventory_batch_id' => $normalized['inventory_batch_id'],
                    'tipo'               => 'MERMA',
                    'qty'                => $normalized['qty'],
                    'uom'                => $normalized['uom'],
                    'sucursal_id'        => $header['branch_id'] ?? null,
                    'almacen_id'         => $header['warehouse_id'] ?? null,
                    'ref_tipo'           => 'production_order',
                    'ref_id'             => $orderId,
                    'user_id'            => $header['user_id'] ?? null,
                    'ts'                 => $now,
                    'meta'               => $normalized['meta'],
                    'created_at'         => $now,
                    'updated_at'         => $now,
                ]);
            }

            DB::table('production_orders')
                ->where('id', $orderId)
                ->update([
                    'qty_producida' => $totals['produced'],
                    'qty_merma'     => $totals['waste'],
                    'estado'        => 'COMPLETADO',
                    'cerrado_en'    => $now,
                    'updated_at'    => $now,
                ]);

            return $orderId;
        });
    }

    protected function buildSequentialNumber(): string
    {
        $today = now()->format('Ymd');

        $count = DB::table('production_orders')
            ->whereDate('created_at', now()->toDateString())
            ->count();

        return sprintf('PR-%s-%04d', $today, $count + 1);
    }

    private function normalizeInput(array $input): array
    {
        if (empty($input['item_id'])) {
            throw new InvalidArgumentException('El insumo requiere item_id.');
        }

        if (empty($input['uom'])) {
            throw new InvalidArgumentException('El insumo requiere unidad de medida.');
        }

        $qty = (float) ($input['qty'] ?? 0);

        if ($qty <= 0) {
            throw new InvalidArgumentException('La cantidad del insumo debe ser mayor a cero.');
        }

        return [
            'item_id'            => (int) $input['item_id'],
            'inventory_batch_id' => isset($input['inventory_batch_id']) ? (int) $input['inventory_batch_id'] : null,
            'qty'                => $qty,
            'uom'                => $input['uom'],
            'meta'               => isset($input['meta']) ? json_encode($input['meta']) : null,
        ];
    }

    private function normalizeOutput(array $output, array $header, $now): array
    {
        if (empty($output['item_id'])) {
            throw new InvalidArgumentException('El producto terminado requiere item_id.');
        }

        if (empty($output['uom'])) {
            throw new InvalidArgumentException('El producto terminado requiere unidad de medida.');
        }

        $qty = (float) ($output['qty'] ?? 0);

        if ($qty <= 0) {
            throw new InvalidArgumentException('La cantidad producida debe ser mayor a cero.');
        }

        $batchId = $output['inventory_batch_id'] ?? null;

        if (! $batchId) {
            $batchId = (int) DB::table('inventory_batch')->insertGetId([
                'item_id'           => $output['item_id'],
                'lote_proveedor'    => $output['lot'] ?? (string) Str::uuid(),
                'cantidad_original' => $qty,
                'cantidad_actual'   => $qty,
                'uom_base'          => $output['uom'],
                'caducidad'         => $output['exp_date'] ?? null,
                'estado'            => 'ACTIVO',
                'sucursal_id'       => $header['branch_id'] ?? null,
                'almacen_id'        => $header['warehouse_id'] ?? null,
                'meta'              => isset($output['meta']) ? json_encode($output['meta']) : null,
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }

        return [
            'item_id'            => (int) $output['item_id'],
            'inventory_batch_id' => $batchId ? (int) $batchId : null,
            'lote_producido'     => $output['lot'] ?? null,
            'fecha_caducidad'    => $output['exp_date'] ?? null,
            'qty'                => $qty,
            'uom'                => $output['uom'],
            'meta'               => isset($output['meta']) ? json_encode($output['meta']) : null,
        ];
    }

    private function normalizeWaste(array $waste, array $header, $now): array
    {
        if (empty($waste['item_id'])) {
            throw new InvalidArgumentException('La merma requiere item_id.');
        }

        if (empty($waste['uom'])) {
            throw new InvalidArgumentException('La merma requiere unidad de medida.');
        }

        $qty = (float) ($waste['qty'] ?? 0);

        if ($qty <= 0) {
            throw new InvalidArgumentException('La merma debe ser mayor a cero.');
        }

        $batchId = $waste['inventory_batch_id'] ?? null;

        if (! $batchId && ! empty($waste['lot'])) {
            $batchId = (int) DB::table('inventory_batch')->insertGetId([
                'item_id'           => $waste['item_id'],
                'lote_proveedor'    => $waste['lot'],
                'cantidad_original' => $qty,
                'cantidad_actual'   => 0,
                'uom_base'          => $waste['uom'],
                'caducidad'         => $waste['exp_date'] ?? null,
                'estado'            => 'CERRADO',
                'sucursal_id'       => $header['branch_id'] ?? null,
                'almacen_id'        => $header['warehouse_id'] ?? null,
                'meta'              => isset($waste['meta']) ? json_encode($waste['meta']) : null,
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }

        return [
            'item_id'            => (int) $waste['item_id'],
            'inventory_batch_id' => $batchId ? (int) $batchId : null,
            'qty'                => $qty,
            'uom'                => $waste['uom'],
            'motivo'             => $waste['reason'] ?? null,
            'sucursal_id'        => $header['branch_id'] ?? null,
            'almacen_id'         => $header['warehouse_id'] ?? null,
            'user_id'            => $header['user_id'] ?? null,
            'ref_tipo'           => $waste['ref_tipo'] ?? null,
            'ref_id'             => $waste['ref_id'] ?? null,
            'registrado_en'      => $now,
            'meta'               => isset($waste['meta']) ? json_encode($waste['meta']) : null,
            'notas'              => $waste['notes'] ?? null,
        ];
    }
}
