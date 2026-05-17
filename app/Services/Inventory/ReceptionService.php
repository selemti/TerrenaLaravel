<?php

namespace App\Services\Inventory;

use App\Events\Inventory\ReceptionPosted;
use App\Exceptions\Inventory\InvalidInventoryStateException;
use App\Exceptions\Inventory\ItemNotFoundException;
use App\Models\Inv\Item;
use App\Models\Inventory\ReceptionHeader;
use App\Models\PurchaseOrder;
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
    private const TIPO_RECEPCION_COMPRA = 'RECEPCION_COMPRA';

    // Delegate to model constants for a single source of truth
    const ESTADO_BORRADOR = ReceptionHeader::STATUS_BORRADOR;

    const ESTADO_VALIDADA = ReceptionHeader::STATUS_VALIDADA;

    const ESTADO_POSTEADA = ReceptionHeader::STATUS_POSTEADA;

    const ESTADO_CANCELADA = ReceptionHeader::STATUS_CANCELADA;

    /**
     * Crea una recepción BORRADOR desde una orden de compra aprobada/enviada.
     */
    public function createFromPurchaseOrder(PurchaseOrder $po): ReceptionHeader
    {
        return DB::transaction(function () use ($po) {
            $po->loadMissing('lines');

            if (! $po->is_aprobada) {
                throw new InvalidInventoryStateException("No se puede crear recepción para una OC en estado {$po->estado}.");
            }

            $header = [
                'supplier_id' => $po->vendor_id,
                'branch_id' => $po->sucursal_id,
                'warehouse_id' => data_get($po->meta, 'almacen_id'),
                'user_id' => auth()->id() ?? $po->creado_por,
                'meta' => [
                    'purchase_order_id' => $po->id,
                    'purchase_order_folio' => $po->folio,
                ],
            ];

            $lines = $po->lines->map(fn ($line) => [
                'item_id' => (string) $line->item_id,
                'qty_pack' => (float) $line->qty,
                'pack_size' => (float) data_get($line->meta, 'pack_size', 1),
                'uom_purchase' => $line->uom,
                'uom_base' => data_get($line->meta, 'uom_base', $line->uom),
                'costo_unit' => (float) $line->precio_unitario,
                'lot' => data_get($line->meta, 'lot'),
                'exp_date' => data_get($line->meta, 'exp_date'),
                'temp' => data_get($line->meta, 'temp'),
                'doc_url' => data_get($line->meta, 'doc_url'),
                'meta' => [
                    'purchase_order_line_id' => $line->id,
                ],
            ])->all();

            $receptionId = $this->insertDraftReception($header, $lines);

            return ReceptionHeader::with('lines')->findOrFail($receptionId);
        });
    }

    /**
     * Reemplaza las líneas de una recepción BORRADOR.
     */
    public function setLines(int $receptionId, array $lines): void
    {
        DB::transaction(function () use ($receptionId, $lines) {
            $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->first();

            if (! $reception) {
                throw ItemNotFoundException::reception($receptionId);
            }

            if ($reception->estado !== self::ESTADO_BORRADOR) {
                throw InvalidInventoryStateException::transition($receptionId, $reception->estado, self::ESTADO_BORRADOR);
            }

            DB::table('selemti.recepcion_det')->where('recepcion_id', $receptionId)->delete();
            $totals = $this->insertReceptionLines($receptionId, $lines, now());
            $this->updateReceptionTotals($receptionId, $totals);
        });
    }

    /**
     * Cierra el costeo de la recepción y genera movimientos de inventario.
     */
    public function finalizeCosting(int $receptionId): void
    {
        DB::transaction(function () use ($receptionId) {
            $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->lockForUpdate()->first();

            if (! $reception) {
                throw ItemNotFoundException::reception($receptionId);
            }

            if (! in_array($reception->estado, [self::ESTADO_BORRADOR, self::ESTADO_VALIDADA], true)) {
                throw InvalidInventoryStateException::transition($receptionId, $reception->estado, self::ESTADO_BORRADOR.'|'.self::ESTADO_VALIDADA);
            }

            $this->postLinesToInventory($reception, auth()->id() ?? (int) ($reception->creado_por ?? 0), true);
        });
    }

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
     * @param  array  $header  Datos del encabezado
     * @param  array  $lines  Líneas de detalle
     * @return int ID de la recepción creada
     */
    public function createDraftReception(array $header, array $lines): int
    {
        return DB::transaction(function () use ($header, $lines) {
            return $this->insertDraftReception($header, $lines);
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
     * @param  int  $receptionId  ID de la recepción
     * @param  int  $userId  ID del usuario que valida
     *
     * @throws InvalidArgumentException Si la recepción no está en BORRADOR
     */
    public function validateReception(int $receptionId, int $userId): void
    {
        $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->first();

        if (! $reception) {
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
     * @param  int  $receptionId  ID de la recepción
     * @param  int  $userId  ID del usuario que postea
     *
     * @throws InvalidArgumentException Si la recepción no está en VALIDADA
     */
    public function postReception(int $receptionId, int $userId): void
    {
        DB::transaction(function () use ($receptionId, $userId) {
            $reception = DB::table('selemti.recepcion_cab')->where('id', $receptionId)->first();

            if (! $reception) {
                throw ItemNotFoundException::reception($receptionId);
            }

            if ($reception->estado !== self::ESTADO_VALIDADA) {
                throw InvalidInventoryStateException::transition($receptionId, $reception->estado, self::ESTADO_VALIDADA);
            }

            $this->postLinesToInventory($reception, $userId);
        });
    }

    /**
     * Genera número secuencial para recepciones
     * Formato: RC-YYYYMMDD-####
     */
    protected function buildSequentialNumber(): string
    {
        $today = now()->format('Ymd');

        $count = DB::table('selemti.recepcion_cab')
            ->whereDate('fecha_recepcion', now()->toDateString())
            ->count();

        return sprintf('RC-%s-%04d', $today, $count + 1);
    }

    private function insertDraftReception(array $header, array $lines): int
    {
        $now = now();
        $numero = $this->buildSequentialNumber();

        $receptionId = (int) DB::table('selemti.recepcion_cab')->insertGetId([
            'proveedor_id' => $header['supplier_id'],
            'sucursal_id' => $header['branch_id'] ?? null,
            'almacen_id' => $header['warehouse_id'] ?? null,
            'creado_por' => $header['user_id'],
            'numero_recepcion' => $numero,
            'fecha_recepcion' => $now,
            'estado' => self::ESTADO_BORRADOR,
            'total_presentaciones' => 0,
            'total_canonico' => 0,
            'meta' => isset($header['meta']) ? json_encode($header['meta']) : null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $totals = $this->insertReceptionLines($receptionId, $lines, $now);
        $this->updateReceptionTotals($receptionId, $totals);

        return $receptionId;
    }

    private function insertReceptionLines(int $receptionId, array $lines, Carbon $now): array
    {
        $totals = ['presentaciones' => 0.0, 'canonico' => 0.0];

        foreach ($lines as $line) {
            $qtyPack = (float) ($line['qty_pack'] ?? $line['qty'] ?? 0);
            $packSize = (float) ($line['pack_size'] ?? 1);
            $qtyCanonical = $qtyPack * ($packSize ?: 1);
            $meta = array_merge([
                'qty_pack' => $qtyPack,
                'pack_size' => $packSize,
            ], $line['meta'] ?? []);

            DB::table('selemti.recepcion_det')->insert([
                'recepcion_id' => $receptionId,
                'item_id' => (string) $line['item_id'],
                'qty_presentacion' => $qtyPack,
                'qty_recibida' => (float) ($line['qty_received'] ?? $qtyPack),
                'qty_canonica' => $qtyCanonical,
                'pack_size' => $packSize,
                'uom_compra' => strtoupper($line['uom_purchase'] ?? $line['uom'] ?? 'PZ'),
                'uom_base' => strtoupper($line['uom_base'] ?? $line['uom'] ?? 'PZ'),
                'precio_unit' => $line['costo_unit'] ?? $line['precio_unitario'] ?? 0,
                'lote_proveedor' => $line['lot'] ?? null,
                'fecha_caducidad' => $line['exp_date'] ?? null,
                'temperatura_recepcion' => $line['temp'] ?? null,
                'certificado_calidad_url' => $line['doc_url'] ?? null,
                'meta' => json_encode($meta),
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $totals['presentaciones'] += $qtyPack;
            $totals['canonico'] += $qtyCanonical;
        }

        return $totals;
    }

    private function updateReceptionTotals(int $receptionId, array $totals): void
    {
        DB::table('selemti.recepcion_cab')
            ->where('id', $receptionId)
            ->update([
                'total_presentaciones' => $totals['presentaciones'],
                'total_canonico' => $totals['canonico'],
                'updated_at' => now(),
            ]);
    }

    private function postLinesToInventory(object $reception, int $userId, bool $updateAverageCost = false): void
    {
        $lines = DB::table('selemti.recepcion_det')
            ->where('recepcion_id', $reception->id)
            ->get();

        $now = now();
        $uomSvc = app(UomConversionService::class);
        $itemIds = $lines->pluck('item_id')->unique();
        $itemsMap = Item::with(['uom', 'uomCompra'])->findMany($itemIds)->keyBy('id');

        foreach ($lines as $line) {
            $meta = json_decode($line->meta, true) ?? [];
            $fechaCaducidad = $line->fecha_caducidad
                ? Carbon::parse($line->fecha_caducidad)->toDateString()
                : $now->copy()->addYear()->toDateString();

            $item = $itemsMap->get($line->item_id);
            $qtyPresentacion = (float) ($meta['qty_pack'] ?? $line->qty_presentacion);
            $uomCompra = $line->uom_compra ?? $item?->uomCompra?->clave;

            $cantidadBase = $item
                ? $uomSvc->resolveToBase($qtyPresentacion, $uomCompra, $item)
                : (float) $line->qty_canonica;

            $uomBaseClave = $item?->uom?->clave ?? ($line->uom_base ?? 'PZ');
            $uomCompraId = $item?->unidad_compra_id;

            $batchId = DB::table('selemti.inventory_batch')->insertGetId([
                'item_id' => $line->item_id,
                'lote_proveedor' => $line->lote_proveedor ?? (string) Str::uuid(),
                'caducidad' => $fechaCaducidad,
                'temperatura_recepcion' => $line->temperatura_recepcion,
                'documento_url' => $line->certificado_calidad_url,
                'cantidad_original' => $cantidadBase,
                'cantidad_actual' => $cantidadBase,
                'uom_base' => $uomBaseClave,
                'estado' => 'ACTIVO',
                'sucursal_id' => $reception->sucursal_id,
                'almacen_id' => $reception->almacen_id,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('selemti.recepcion_det')
                ->where('id', $line->id)
                ->update(['inventory_batch_id' => $batchId, 'updated_at' => $now]);

            DB::table('selemti.mov_inv')->insert([
                'item_id' => $line->item_id,
                'tipo' => self::TIPO_RECEPCION_COMPRA,
                'cantidad' => $cantidadBase,
                'qty' => $cantidadBase,
                'uom' => $uomBaseClave,
                'qty_original' => $qtyPresentacion,
                'uom_original_id' => $uomCompraId,
                'costo_unit' => $line->precio_unit ?? 0,
                'sucursal_id' => $reception->sucursal_id,
                'almacen_id' => $reception->almacen_id,
                'ref_tipo' => 'recepcion',
                'ref_id' => $reception->id,
                'usuario_id' => $userId ?: null,
                'user_id' => $userId ?: null,
                'lote_id' => $batchId,
                'inventory_batch_id' => $batchId,
                'ts' => $now,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            if ($updateAverageCost && $item && $cantidadBase > 0) {
                $unitCost = (float) ($line->precio_unit ?? 0) / max($cantidadBase, 1);
                $currentQty = (float) DB::table('selemti.mov_inv')
                    ->where('item_id', $line->item_id)
                    ->where('id', '<', DB::getPdo()->lastInsertId())
                    ->sum('cantidad');
                $currentCost = (float) ($item->costo_promedio ?? 0);
                $newAverage = (($currentQty * $currentCost) + ($cantidadBase * $unitCost)) / max($currentQty + $cantidadBase, 1);

                DB::table('selemti.items')->where('id', $line->item_id)->update([
                    'costo_promedio' => $newAverage,
                    'updated_at' => $now,
                ]);
            }
        }

        DB::table('selemti.recepcion_cab')
            ->where('id', $reception->id)
            ->update([
                'estado' => self::ESTADO_POSTEADA,
                'posteada_por' => $userId ?: null,
                'posteada_at' => $now,
                'updated_at' => $now,
            ]);

        event(new ReceptionPosted(
            receptionId: (string) $reception->id,
            almacenId: (string) ($reception->almacen_id ?? ''),
            postedAt: new \DateTimeImmutable($now),
        ));
    }
}
