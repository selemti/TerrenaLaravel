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
        return DB::transaction(function() use ($header,$lines) {

            $receptionId = (int) DB::table('recepcion_cab')->insertGetId([
                'proveedor_id' => $header['supplier_id'],
                'sucursal_id'  => $header['branch_id'] ?? null,
                'almacen_id'   => $header['warehouse_id'] ?? null,
                'usuario_id'   => $header['user_id'],
                'ts'           => now(),
            ]);

            foreach ($lines as $l) {
                // normaliza cantidad a UOM canónica (qty_can = qty_pack * pack_size)
                $qtyCan = (float)$l['qty_pack'] * (float)($l['pack_size'] ?? 1);

                // crea/obtiene batch (lote)
                $batchId = (int) DB::table('inventory_batch')->insertGetId([
                    'item_id'   => $l['item_id'],
                    'lote'      => $l['lot'] ?: Str::uuid(),
                    'caducidad' => $l['exp_date'] ?? null,
                    'estado'    => 'ACTIVO',
                    'metadata'  => json_encode([
                        'temperatura' => $l['temp'] ?? null,
                        'doc_url'     => $l['doc_url'] ?? null
                    ]),
                    'created_at'=> now(),
                ]);

                // detalle de recepción (si existe tu tabla recepcion_det)
                DB::table('recepcion_det')->insert([
                    'recepcion_id' => $receptionId,
                    'item_id'      => $l['item_id'],
                    'batch_id'     => $batchId,
                    'qty_presentacion' => $l['qty_pack'],
                    'pack_size'    => $l['pack_size'] ?? 1,
                    'uom_compra'   => $l['uom_purchase'],
                    'qty_canonica' => $qtyCan,
                    'uom_base'     => $l['uom_base'],
                    'precio_unit'  => $l['precio_unit'] ?? 0,
                    'ts'           => now(),
                ]);

                // movimiento de inventario (kardex) tipo RECEPCION
                DB::table('mov_inv')->insert([
                    'item_id'  => $l['item_id'],
                    'batch_id' => $batchId,
                    'tipo'     => 'RECEPCION',
                    'qty'      => $qtyCan,           // positivo
                    'uom'      => $l['uom_base'],    // GR/ML/PZ
                    'ref_tipo' => 'RECEPCION',
                    'ref_id'   => $receptionId,
                    'sucursal_id' => $header['branch_id'] ?? null,
                    'almacen_id'  => $header['warehouse_id'] ?? null,
                    'ts'       => now(),
                    'meta'     => json_encode(['temp'=>$l['temp'] ?? null])
                ]);
            }

            return $receptionId;
        });
    }
}
