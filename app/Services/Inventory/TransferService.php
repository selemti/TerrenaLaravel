<?php

namespace App\Services\Inventory;

use App\Exceptions\Inventory\InventoryValidationException;
use App\Exceptions\Transfer\InvalidTransferStateException;
use App\Exceptions\Transfer\TransferNotFoundException;
use App\Models\Inv\Item;
use App\Models\Inventory\Movement;
use App\Models\Inventory\TransferHeader;
use App\Models\Inventory\TransferLine;
use App\Services\Inventory\UomConversionService;
use Illuminate\Support\Facades\DB;

/**
 * Servicio que gestiona transferencias internas entre almacenes.
 */
class TransferService
{
    /**
     * Crea una transferencia SOLICITADA entre almacenes.
     *
     * @route POST /api/inventory/transfers/create
     *
     * @throws InvalidArgumentException
     *
     * @todo Persistir cabecera/detalle y validar stocks iniciales.
     */
    public function createTransfer(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): array
    {
        $this->guardPositiveId($fromAlmacenId, 'almacén origen');
        $this->guardPositiveId($toAlmacenId, 'almacén destino');
        $this->guardPositiveId($userId, 'user');

        if ($fromAlmacenId === $toAlmacenId) {
            throw new InventoryValidationException('Almacén origen y destino deben ser diferentes.');
        }

        if (empty($lines)) {
            throw new InventoryValidationException('At least one line item is required for a transfer.');
        }

        return DB::transaction(function () use ($fromAlmacenId, $toAlmacenId, $lines, $userId) {
            $header = TransferHeader::create([
                'from_bodega_id' => $fromAlmacenId,
                'to_bodega_id' => $toAlmacenId,
                'estado' => TransferHeader::STATUS_SOLICITADA,
                'usuario_id' => $userId,
            ]);

            foreach ($lines as $line) {
                // Usar la UOM base del item como unidad del traspaso por defecto.
                // Si el llamador especifica um_id (ej: UI envía PZ para cuernitos), se respeta.
                $item = Item::with('uom')->find($line['item_id']);
                $umId = $line['um_id'] ?? $item?->unidad_medida_id ?? null;

                TransferLine::create([
                    'traspaso_id' => $header->id,
                    'item_id' => $line['item_id'],
                    'qty' => $line['qty_requested'] ?? $line['cantidad'] ?? 0,
                    'um_id' => $umId,
                ]);
            }

            return [
                'transfer_id' => $header->id,
                'status' => $header->estado,
            ];
        });
    }

    /**
     * Aprueba la transferencia y avanza a estado APROBADA.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/approve
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Validar estado SOLICITADA y registrar quién aprobó.
     */
    public function approveTransfer(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId) {
            $transfer = TransferHeader::with('lineas.item')->findOrFail($transferId);

            if (! $transfer->canApprove()) {
                throw InvalidTransferStateException::transition($transferId, $transfer->estado, 'SOLICITADA');
            }

            // Optimized: Fetch all required stock data in a single query
            // TODO: this table (stock) does not exist in BD. Revisar diseño de Inventario.
            // Placeholder: For now, we'll use a different approach to get stock
            $itemIds = $transfer->lineas->pluck('item_id')->toArray();

            // Calculate stock from mov_inv records
            $stocks = DB::connection('pgsql')
                ->table('selemti.mov_inv')
                ->select('item_id', DB::raw('SUM(cantidad) as cantidad_actual'))
                ->where('sucursal_id', (string) $transfer->from_bodega_id)
                ->whereIn('item_id', $itemIds)
                ->groupBy('item_id')
                ->pluck('cantidad_actual', 'item_id');

            // Validar stock disponible en almacén origen
            foreach ($transfer->lineas as $line) {
                $stock = $stocks->get($line->item_id, 0);

                if ($stock < $line->qty) {
                    throw \App\Exceptions\Inventory\InsufficientStockException::forItem($line->item_id, $line->qty, $stock);
                }
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_APROBADA,
                'validada_por' => $userId,
                'validada_at' => now(),
            ]);

            return [
                'transfer_id' => $transfer->id,
                'status' => $transfer->estado,
            ];
        });
    }

    /**
     * Marca la transferencia como EN_TRANSITO cuando sale de origen.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/ship
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Guardar datos de transporte y hora de salida.
     */
    public function markInTransit(int $transferId, int $userId, ?string $numeroGuia = null): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId, $numeroGuia) {
            $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

            if (! $transfer->canShip()) {
                throw InvalidTransferStateException::transition($transferId, $transfer->estado, 'APROBADA');
            }

            // Actualizar cantidades despachadas (igual a solicitadas por defecto)
            foreach ($transfer->lineas as $line) {
                $line->update([
                    'cantidad_despachada' => $line->qty,
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_EN_TRANSITO,
                'despachada_por' => $userId,
                'guia' => $numeroGuia,
            ]);

            return [
                'transfer_id' => $transfer->id,
                'status' => $transfer->estado,
                'numero_guia' => $numeroGuia,
            ];
        });
    }

    /**
     * Registra cantidades recibidas en destino y pasa a RECIBIDA.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/receive
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Calcular diferencias y preparar ajustes antes del posteo.
     */
    public function receiveTransfer(int $transferId, array $receivedLines, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        if (empty($receivedLines)) {
            throw new InventoryValidationException('Received lines data is required.');
        }

        return DB::transaction(function () use ($transferId, $receivedLines, $userId) {
            $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

            if (! $transfer->canReceive()) {
                throw InvalidTransferStateException::transition($transferId, $transfer->estado, 'EN_TRANSITO');
            }

            // Actualizar cantidades recibidas y observaciones
            foreach ($receivedLines as $lineData) {
                $line = $transfer->lineas()->where('id', $lineData['line_id'])->first();

                if (! $line) {
                    throw new InventoryValidationException("Line {$lineData['line_id']} not found in transfer {$transferId}");
                }

                $line->update([
                    'cantidad_recibida' => $lineData['cantidad_recibida'],
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_RECIBIDA,
                'recibida_por' => $userId,
            ]);

            // Calcular varianzas
            $varianzas = [];
            foreach ($transfer->lineas as $line) {
                if ($line->hasVariance()) {
                    $varianzas[] = [
                        'line_id' => $line->id,
                        'item_id' => $line->item_id,
                        'varianza' => $line->varianza,
                        'varianza_porcentaje' => $line->varianza_porcentaje,
                    ];
                }
            }

            return [
                'transfer_id' => $transfer->id,
                'status' => $transfer->estado,
                'varianzas' => $varianzas,
                'lines_confirmed' => count($receivedLines),
            ];
        });
    }

    /**
     * Genera mov_inv negativos/positivos y cierra la transferencia.
     *
     * @route POST /api/inventory/transfers/{transfer_id}/post
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Insertar TRANSFER_OUT/TRANSFER_IN y sellar estado CERRADA.
     */
    public function postTransferToInventory(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId) {
            $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

            $postableStatuses = [TransferHeader::STATUS_APROBADA, TransferHeader::STATUS_RECIBIDA];
            if (! in_array($transfer->estado, $postableStatuses)) {
                throw InvalidTransferStateException::transition($transferId, $transfer->estado, 'APROBADA|RECIBIDA');
            }

            $movimientos = [];
            $uomSvc = app(UomConversionService::class);

            foreach ($transfer->lineas as $line) {
                $qtyEntered = abs($line->cantidad_recibida ?? $line->qty);

                // Convertir a unidades base según la UOM del traspaso (um_id de la línea)
                $item = Item::with(['uom', 'uomCompra'])->find($line->item_id);
                $lineUomClave = null;
                if ($line->um_id) {
                    $lineUomClave = DB::table('selemti.cat_unidades')->where('id', $line->um_id)->value('clave');
                }
                $qtyToTransfer = $item
                    ? $uomSvc->resolveToBase($qtyEntered, $lineUomClave, $item)
                    : $qtyEntered;

                // Decrementar lote origen (FEFO: tomar el lote más antiguo disponible con stock)
                $sourceBatch = DB::table('selemti.inventory_batch')
                    ->where('item_id', $line->item_id)
                    ->where('cantidad_actual', '>', 0)
                    ->orderBy('fecha_caducidad')
                    ->first();

                if ($sourceBatch) {
                    DB::table('selemti.inventory_batch')
                        ->where('id', $sourceBatch->id)
                        ->decrement('cantidad_actual', $qtyToTransfer);
                }

                // Movimiento de SALIDA en almacén origen (en unidades base)
                $movOut = Movement::create([
                    'sucursal_id' => (string) $transfer->from_bodega_id,
                    'item_id' => $line->item_id,
                    'lote_id' => $sourceBatch->id ?? null,
                    'tipo' => 'TRASPASO',
                    'cantidad' => -$qtyToTransfer,
                    'qty_original' => -$qtyEntered,
                    'uom_original_id' => $line->um_id,
                    'ts' => now(),
                    'usuario_id' => $userId,
                    'ref_tipo' => 'traspaso',
                    'ref_id' => $transfer->id,
                ]);

                // Movimiento de ENTRADA en almacén destino (en unidades base)
                $movIn = Movement::create([
                    'sucursal_id' => (string) $transfer->to_bodega_id,
                    'item_id' => $line->item_id,
                    'tipo' => 'TRASPASO',
                    'cantidad' => $qtyToTransfer,
                    'qty_original' => $qtyEntered,
                    'uom_original_id' => $line->um_id,
                    'ts' => now(),
                    'usuario_id' => $userId,
                    'ref_tipo' => 'traspaso',
                    'ref_id' => $transfer->id,
                ]);

                $movimientos[] = [
                    'out' => $movOut->id,
                    'in' => $movIn->id,
                ];
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_POSTEADA,
                'posteada_por' => $userId,
                'posteada_at' => now(),
            ]);

            return [
                'transfer_id' => $transfer->id,
                'movements_created' => count($movimientos) * 2,
                'status' => $transfer->estado,
                'movimientos' => $movimientos,
            ];
        });
    }

    /**
     * Garantiza que un identificador numérico sea válido.
     *
     * @throws InvalidArgumentException
     */
    protected function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new InventoryValidationException(sprintf('The %s id must be greater than zero.', $label));
        }
    }
}
