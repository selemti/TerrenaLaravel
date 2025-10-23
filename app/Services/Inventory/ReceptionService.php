<?php
namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
class ReceptionService
{
    /**
     * $header = ['supplier_id'=>int,'branch_id'=>?,'warehouse_id'=>?,'user_id'=>int]
     * $lines = [[
     *   'item_id'=>int,'qty_pack'=>numeric,'uom_purchase'=>'PZ',
     *   'pack_size'=>numeric, // ej 12 para caja de 12
     *   'uom_base'=>'ML|GR|PZ', // canónica del item
     *   'lot'=>'','exp_date'=>'YYYY-MM-DD','temp'=>numeric,'doc_url'=>string|null
     * ]]
     */
    public function createReception(array $header, array $lines): int
    {
        return DB::transaction(function () use ($header, $lines) {
            $now = now();
            $numero = $this->buildSequentialNumber();

            $cabecera = [
                'proveedor_id'        => $header['supplier_id'],
                'sucursal_id'        => $header['branch_id'] ?? null,
                'almacen_id'         => $header['warehouse_id'] ?? null,
                'usuario_id'         => $header['user_id'] ?? null,
                'numero_recepcion'   => $numero,
                'fecha_recepcion'    => $now,
                'estado'             => 'RECIBIDO',
                'total_presentaciones' => 0,
                'total_canonico'       => 0,
                'created_at'           => $now,
                'updated_at'           => $now,
            ];

            $receptionId = (int) DB::table('recepcion_cab')->insertGetId($cabecera);

            $totals = ['presentaciones' => 0.0, 'canonico' => 0.0];

            foreach ($lines as $line) {
                $qtyPack = (float) ($line['qty_pack'] ?? 0);
                $packSize = (float) ($line['pack_size'] ?? 1);
                $qtyCanonical = $qtyPack * ($packSize ?: 1);

                $batchId = (int) DB::table('inventory_batch')->insertGetId([
                    'item_id'               => $line['item_id'],
                    'lote'                  => $line['lot'] ?: (string) Str::uuid(),
                    'cantidad_original'     => $qtyCanonical,
                    'cantidad_actual'       => $qtyCanonical,
                    'uom_base'              => $line['uom_base'],
                    'caducidad'             => $line['exp_date'] ?? null,
                    'estado'                => 'ACTIVO',
                    'temperatura_recepcion' => $line['temp'] ?? null,
                    'doc_url'               => $line['doc_url'] ?? null,
                    'sucursal_id'           => $header['branch_id'] ?? null,
                    'almacen_id'            => $header['warehouse_id'] ?? null,
                    'meta'                  => json_encode([
                        'uom_purchase' => $line['uom_purchase'],
                        'qty_pack'     => $qtyPack,
                        'pack_size'    => $packSize,
                    ]),
                    'created_at'            => $now,
                    'updated_at'            => $now,
                ]);

                DB::table('recepcion_det')->insert([
                    'recepcion_id'           => $receptionId,
                    'item_id'                => $line['item_id'],
                    'batch_id'               => $batchId,
                    'lote_proveedor'         => $line['lot'] ?: null,
                    'fecha_caducidad'        => $line['exp_date'] ?? null,
                    'qty_presentacion'       => $qtyPack,
                    'pack_size'              => $packSize,
                    'uom_compra'             => $line['uom_purchase'],
                    'qty_canonica'           => $qtyCanonical,
                    'uom_base'               => $line['uom_base'],
                    'precio_unit'            => $line['precio_unit'] ?? null,
                    'temperatura_recepcion'  => $line['temp'] ?? null,
                    'meta'                   => $line['doc_url'] ? json_encode(['doc_url' => $line['doc_url']]) : null,
                    'created_at'             => $now,
                    'updated_at'             => $now,
                ]);

                $movimiento = [
                    'item_id'    => $line['item_id'],
                    'batch_id'   => $batchId,
                    'tipo'       => 'RECEPCION',
                    'qty'        => $qtyCanonical,
                    'uom'        => $line['uom_base'],
                    'sucursal_id'=> $header['branch_id'] ?? null,
                    'almacen_id' => $header['warehouse_id'] ?? null,
                    'ref_tipo'   => 'recepcion',
                    'ref_id'     => $receptionId,
                    'user_id'    => $header['user_id'] ?? null,
                    'ts'         => $now,
                    'meta'       => json_encode(['temperatura' => $line['temp'] ?? null]),
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                DB::table('mov_inv')->insert($movimiento);

                $totals['presentaciones'] += $qtyPack;
                $totals['canonico'] += $qtyCanonical;
            }

            DB::table('recepcion_cab')
                ->where('id', $receptionId)
                ->update([
                    'total_presentaciones' => $totals['presentaciones'],
                    'total_canonico'       => $totals['canonico'],
                    'updated_at'           => $now,
                ]);

            return $receptionId;
        });
    }

    protected function buildSequentialNumber(): string
    {
        $today = now()->format('Ymd');

        $count = DB::table('recepcion_cab')
            ->whereDate('fecha_recepcion', now()->toDateString())
            ->count();

        return sprintf('RC-%s-%04d', $today, $count + 1);
    }
}
