<?php

namespace App\Services\Inventory;

use App\Exceptions\Inventory\InvalidInventoryStateException;
use App\Exceptions\Inventory\ItemNotFoundException;
use App\Models\Inv\Item;
use App\Services\Inventory\UomConversionService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Servicio para gestión de recepciones de inventario
 * 
 * Implementa:
 * - Creación de recepciones en estado BORRADOR
 * - State machine: BORRADOR → VALIDADA → POSTEADA
 * - Posteo a inventario (mov_inv)
 * 
 * @version 2.0 - Sprint 1 (INV-002)
 */
class ReceptionService
{
    // Estados de recepción
    const ESTADO_BORRADOR = 'BORRADOR';
    const ESTADO_VALIDADA = 'VALIDADA';
    const ESTADO_POSTEADA = 'POSTEADA';
    const ESTADO_CANCELADA = 'CANCELADA';

    /**
     * Crea una recepción en estado BORRADOR (editable, no afecta inventario)
     * 
     * $header = [
     *   'supplier_id' => int,
     *   'branch_id' => int|null,
     *   'warehouse_id' => int|null,
     *   'user_id' => int
     * ]
     * 
     * $lines = [[
     *   'item_id' => string,
     *   'qty_pack' => numeric,
     *   'uom_purchase' => string,
     *   'pack_size' => numeric,
     *   'uom_base' => string,
     *   'costo_unit' => numeric,
     *   'lot' => string|null,
     *   'exp_date' => string|null,
     *   'temp' => numeric|null,
     *   'doc_url' => string|null
     * ]]
     * 
     * @param array $header Datos del encabezado
     * @param array $lines Líneas de detalle
     * @return int ID de la recepción creada
     */
    public function createDraftReception(array $header, array $lines): int
    {
        return DB::transaction(function () use ($header, $lines) {
            $now = now();
            $numero = $this->buildSequentialNumber();

            $cabecera = [
                'proveedor_id' => $header['supplier_id'],
                'sucursal_id' => $header['branch_id'] ?? null,
                'almacen_id' => $header['warehouse_id'] ?? null,
                'usuario_id' => $header['user_id'],
                'numero_recepcion' => $numero,
                'fecha_recepcion' => $now,
                'estado' => self::ESTADO_BORRADOR,
                'total_presentaciones' => 0,
                'total_canonico' => 0,
                'ts' => $now,
                'created_at' => $now,
                'updated_at' => $now,
            ];

            $receptionId = (int) DB::table('selemti.recepcion_cab')->insertGetId($cabecera);

            $totals = ['presentaciones' => 0.0, 'canonico' => 0.0];

            foreach ($lines as $line) {
                $qtyPack = (float) ($line['qty_pack'] ?? 0);
                $packSize = (float) ($line['pack_size'] ?? 1);
                $qtyCanonical = $qtyPack * ($packSize ?: 1);

                // En BORRADOR no se crea batch ni se afecta inventario
                DB::table('selemti.recepcion_det')->insert([
                    'recepcion_id' => $receptionId,
                    'item_id' => $line['item_id'],
                    'bodega_id' => $header['warehouse_id'] ?? 1, // TODO: usar bodega correcta
                    'qty' => $qtyCanonical,
                    'um_id' => 1, // TODO: mapear UOM correctamente
                    'costo_unit' => $line['costo_unit'] ?? 0,
                    'batch_id' => null, // Se crea al postear
                    'temperatura' => $line['temp'] ?? null,
                    'doc_url' => $line['doc_url'] ?? null,
                    'meta' => json_encode([
                        'uom_purchase' => $line['uom_purchase'],
                        'qty_pack' => $qtyPack,
                        'pack_size' => $packSize,
                        'uom_base' => $line['uom_base'],
                        'lote_proveedor' => $line['lot'],
                        'fecha_caducidad' => $line['exp_date'],
                    ]),
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);

                $totals['presentaciones'] += $qtyPack;
                $totals['canonico'] += $qtyCanonical;
            }

            // Actualizar totales
            DB::table('selemti.recepcion_cab')
                ->where('id', $receptionId)
                ->update([
                    'total_presentaciones' => $totals['presentaciones'],
                    'total_canonico' => $totals['canonico'],
                ]);

            return $receptionId;
        });
    }

    /**
     * Valida una recepción (BORRADOR → VALIDADA)
     * 
     * Una recepción validada NO es editable y NO afecta inventario aún.
     * Requiere permiso 'recepciones.validar'
     * 
     * TODO: Agregar columnas validada_por, validada_at en migraciones (INV-002-QWEN-BD)
     * 
     * @param int $receptionId ID de la recepción
     * @param int $userId ID del usuario que valida
     * @return void
     * @throws InvalidArgumentException Si la recepción no está en BORRADOR
     */
    public function validateReception(int $receptionId, int $userId): void
    {
        $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->first();

        if (!$reception) {
            throw ItemNotFoundException::reception($receptionId);
        }

        if ($reception->estado !== self::ESTADO_BORRADOR) {
            throw InvalidInventoryStateException::transition($receptionId, $reception->estado, self::ESTADO_BORRADOR);
        }

        DB::table('selemti.recepcion_cab')
            ->where('id', $receptionId)
            ->update([
                'estado' => self::ESTADO_VALIDADA,
                'validada_por' => $userId,
                'validada_at' => now(),
                'updated_at' => now(),
            ]);
    }

    /**
     * Postea una recepción al inventario (VALIDADA → POSTEADA)
     * 
     * Flujo:
     * 1. Verifica que esté en estado VALIDADA
     * 2. Crea lotes (inventory_batch) por cada línea
     * 3. Genera movimientos en mov_inv tipo RECEPCION
     * 4. Marca recepción como POSTEADA (irreversible)
     * 
     * TODO: Agregar columnas posteada_por, posteada_at en migraciones (INV-002-QWEN-BD)
     * 
     * @param int $receptionId ID de la recepción
     * @param int $userId ID del usuario que postea
     * @return void
     * @throws InvalidArgumentException Si la recepción no está en VALIDADA
     */
    public function postReception(int $receptionId, int $userId): void
    {
        DB::transaction(function () use ($receptionId, $userId) {
            $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->first();

            if (!$reception) {
                throw ItemNotFoundException::reception($receptionId);
            }

            if ($reception->estado !== self::ESTADO_VALIDADA) {
                throw InvalidInventoryStateException::transition($receptionId, $reception->estado, self::ESTADO_VALIDADA);
            }

            // Obtener líneas de detalle
            $lines = DB::table('selemti.recepcion_det')
                ->where('recepcion_id', $receptionId)
                ->get();

            $now = now();

            $uomSvc = app(UomConversionService::class);

            foreach ($lines as $line) {
                $meta = json_decode($line->meta, true) ?? [];
                $fechaRecepcion = $reception->fecha_recepcion
                    ? Carbon::parse($reception->fecha_recepcion)->toDateString()
                    : $now->toDateString();
                $fechaCaducidad = isset($meta['fecha_caducidad']) && $meta['fecha_caducidad']
                    ? Carbon::parse($meta['fecha_caducidad'])->toDateString()
                    : $now->copy()->addYear()->toDateString();
                $ubicacion = 'UBIC-' . str_pad((string) ($reception->almacen_id ?? 1), 5, '0', STR_PAD_LEFT);

                // Resolver cantidad a unidades base del item
                $item = Item::with(['uom', 'uomCompra'])->find($line->item_id);
                $qtyPresentacion = (float) ($meta['qty_pack'] ?? $line->qty);
                $uomCompra = $meta['uom_purchase'] ?? $item?->uomCompra?->clave;

                $cantidadBase = $item
                    ? $uomSvc->resolveToBase($qtyPresentacion, $uomCompra, $item)
                    : $line->qty;

                $uomBaseClave = $item?->uom?->clave ?? ($meta['uom_base'] ?? 'PZ');
                $uomCompraId  = $item?->unidad_compra_id;

                // Crear lote de inventario en unidades base
                $batchId = DB::table('selemti.inventory_batch')->insertGetId([
                    'item_id' => $line->item_id,
                    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
                    'fecha_recepcion' => $fechaRecepcion,
                    'fecha_caducidad' => $fechaCaducidad,
                    'temperatura_recepcion' => $line->temperatura,
                    'documento_url' => $line->doc_url,
                    'cantidad_original' => $cantidadBase,
                    'cantidad_actual' => $cantidadBase,
                    'estado' => 'ACTIVO',
                    'ubicacion_id' => $ubicacion,
                    'unit_cost' => $line->costo_unit ?? 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);

                // Actualizar batch_id en recepcion_det
                DB::table('selemti.recepcion_det')
                    ->where('id', $line->id)
                    ->update(['batch_id' => $batchId]);

                // Movimiento en unidades base; qty_original conserva la cantidad en UOM compra
                DB::table('selemti.mov_inv')->insert([
                    'item_id' => $line->item_id,
                    'tipo' => 'ENTRADA',
                    'cantidad' => $cantidadBase,
                    'qty_original' => $qtyPresentacion,
                    'uom_original_id' => $uomCompraId,
                    'costo_unit' => $line->costo_unit ?? 0,
                    'sucursal_id' => $reception->almacen_id !== null ? (string) $reception->almacen_id : null,
                    'ref_tipo' => 'recepcion',
                    'ref_id' => $receptionId,
                    'usuario_id' => $userId,
                    'lote_id' => $batchId,
                    'ts' => $now,
                    'created_at' => $now,
                ]);
            }

            // Marcar recepción como POSTEADA
            DB::table('selemti.recepcion_cab')
                ->where('id', $receptionId)
                ->update([
                    'estado' => self::ESTADO_POSTEADA,
                    'posteada_por' => $userId,
                    'posteada_at' => $now,
                    'updated_at' => $now,
                ]);
        });
    }

    /**
     * Genera número secuencial para recepciones
     * Formato: RC-YYYYMMDD-#### 
     * 
     * @return string
     */
    protected function buildSequentialNumber(): string
    {
        $today = now()->format('Ymd');

        $count = DB::table('selemti.recepcion_cab')
            ->whereDate('fecha_recepcion', now()->toDateString())
            ->count();

        return sprintf('RC-%s-%04d', $today, $count + 1);
    }
}
