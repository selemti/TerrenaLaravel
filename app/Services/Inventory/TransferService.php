<?php

namespace App\Services\Inventory;

use App\Models\Catalogs\Almacen;
use App\Models\Inventory\TransferHeader;
use App\Models\Inventory\TransferLine;
use App\Models\Inv\Item;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;
use RuntimeException;

/**
 * Servicio que gestiona el flujo de transferencias entre almacenes.
 *
 * Las transferencias siguen el flujo:
 * SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA.
 */
class TransferService
{
    /**
     * Crear una transferencia en estado SOLICITADA.
     *
     * @param int   $fromAlmacenId ID almacén origen.
     * @param int   $toAlmacenId   ID almacén destino.
     * @param array $lines         Detalle con item_id, cantidad, uom_id.
     * @param int   $userId        Usuario creador.
     *
     * @return array{transfer_id:int,status:string}
     */
    public function createTransfer(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): array
    {
        $this->guardPositiveId($fromAlmacenId, 'almacén origen');
        $this->guardPositiveId($toAlmacenId, 'almacén destino');
        $this->guardPositiveId($userId, 'user');

        if ($fromAlmacenId === $toAlmacenId) {
            throw new InvalidArgumentException('El almacén origen y destino no pueden ser el mismo.');
        }

        if (empty($lines)) {
            throw new InvalidArgumentException('Se requiere al menos un ítem para la transferencia.');
        }

        DB::beginTransaction();

        try {
            $header = TransferHeader::create([
                'origen_almacen_id' => $fromAlmacenId,
                'destino_almacen_id' => $toAlmacenId,
                'estado' => TransferHeader::STATUS_SOLICITADA,
                'creada_por' => $userId,
                'fecha_solicitada' => now(),
            ]);

            foreach (array_values($lines) as $index => $line) {
                $this->validateLine($line);

                TransferLine::create([
                    'transfer_id' => $header->id,
                    'linea' => $index + 1,
                    'item_id' => Arr::get($line, 'item_id'),
                    'cantidad_solicitada' => Arr::get($line, 'cantidad'),
                    'cantidad_despachada' => 0,
                    'cantidad_recibida' => 0,
                    'uom_id' => Arr::get($line, 'uom_id'),
                    'costo_unitario' => Arr::get($line, 'costo_unitario'),
                ]);
            }

            DB::commit();

            Log::info('Transferencia creada', [
                'transfer_id' => $header->id,
                'from' => $fromAlmacenId,
                'to' => $toAlmacenId,
                'lines' => count($lines),
            ]);

            return [
                'transfer_id' => $header->id,
                'status' => TransferHeader::STATUS_SOLICITADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Error creando transferencia', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Aprobar una transferencia si hay stock suficiente en el almacén origen.
     */
    public function approveTransfer(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

        if (! $transfer->puedeAprobar()) {
            throw new RuntimeException("La transferencia no puede ser aprobada en estado: {$transfer->estado}");
        }

        foreach ($transfer->lineas as $linea) {
            $stockDisponible = $this->getStockDisponible($linea->item_id, $transfer->origen_almacen_id);

            if ($stockDisponible < (float) $linea->cantidad_solicitada) {
                throw new RuntimeException(
                    sprintf(
                        'Stock insuficiente para %s. Disponible: %.3f, Solicitado: %.3f',
                        $linea->item_id,
                        $stockDisponible,
                        (float) $linea->cantidad_solicitada
                    )
                );
            }
        }

        DB::beginTransaction();

        try {
            $transfer->update([
                'estado' => TransferHeader::STATUS_APROBADA,
                'aprobada_por' => $userId,
                'fecha_aprobada' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia aprobada', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_APROBADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Marcar transferencia como EN_TRANSITO al salir del almacén origen.
     */
    public function markInTransit(int $transferId, int $userId, ?string $guia = null): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

        if (! $transfer->puedeDespachar()) {
            throw new RuntimeException("La transferencia no puede ser despachada en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            foreach ($transfer->lineas as $linea) {
                if ($linea->cantidad_despachada === null || $linea->cantidad_despachada == 0) {
                    $linea->update(['cantidad_despachada' => $linea->cantidad_solicitada]);
                }
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_EN_TRANSITO,
                'despachada_por' => $userId,
                'fecha_despachada' => now(),
                'guia' => $guia,
            ]);

            DB::commit();

            Log::info('Transferencia en tránsito', ['transfer_id' => $transferId, 'guia' => $guia]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_EN_TRANSITO,
                'guia' => $guia,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Registrar cantidades recibidas en destino.
     */
    public function receiveTransfer(int $transferId, array $receivedLines, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

        if (! $transfer->puedeRecibir()) {
            throw new RuntimeException("La transferencia no puede ser recibida en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            foreach ($receivedLines as $payload) {
                $lineId = Arr::get($payload, 'line_id');
                $cantidad = Arr::get($payload, 'cantidad_recibida');

                if (! $lineId || $cantidad === null) {
                    throw new InvalidArgumentException('Cada línea recibida requiere line_id y cantidad_recibida.');
                }

                /** @var TransferLine|null $linea */
                $linea = $transfer->lineas->firstWhere('id', $lineId);

                if (! $linea) {
                    throw new RuntimeException("Línea {$lineId} no encontrada en la transferencia.");
                }

                $linea->update([
                    'cantidad_recibida' => $cantidad,
                    'observaciones' => Arr::get($payload, 'observaciones'),
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_RECIBIDA,
                'recibida_por' => $userId,
                'fecha_recibida' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia recibida', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_RECIBIDA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Postear transferencia generando movimientos en el kardex.
     */
    public function postTransferToInventory(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        $transfer = TransferHeader::with(['lineas', 'origenAlmacen', 'destinoAlmacen'])->findOrFail($transferId);

        if (! $transfer->puedePostear()) {
            throw new RuntimeException("La transferencia no puede ser posteada en estado: {$transfer->estado}");
        }

        DB::beginTransaction();

        try {
            foreach ($transfer->lineas as $linea) {
                $cantidad = (float) ($linea->cantidad_recibida ?? $linea->cantidad_despachada ?? $linea->cantidad_solicitada);

                if ($cantidad <= 0) {
                    throw new RuntimeException('Las cantidades recibidas deben ser mayores a 0 para postear.');
                }

                $this->insertMovement(
                    itemId: $linea->item_id,
                    cantidad: -1 * $cantidad,
                    almacen: $transfer->origenAlmacen,
                    userId: $userId,
                    refId: $transfer->id
                );

                $this->insertMovement(
                    itemId: $linea->item_id,
                    cantidad: $cantidad,
                    almacen: $transfer->destinoAlmacen,
                    userId: $userId,
                    refId: $transfer->id
                );
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_POSTEADA,
                'posteada_por' => $userId,
                'fecha_posteada' => now(),
            ]);

            DB::commit();

            Log::info('Transferencia posteada a inventario', ['transfer_id' => $transferId]);

            return [
                'transfer_id' => $transferId,
                'status' => TransferHeader::STATUS_POSTEADA,
            ];
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Error posteando transferencia', [
                'transfer_id' => $transferId,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    private function insertMovement(string $itemId, float $cantidad, ?Almacen $almacen, int $userId, int $refId): void
    {
        DB::connection('pgsql')->table('selemti.mov_inv')->insert([
            'item_id' => $itemId,
            'cantidad' => $cantidad,
            'tipo' => 'TRASPASO',
            'ref_tipo' => 'TRANSFER',
            'ref_id' => $refId,
            'sucursal_id' => $almacen?->sucursal_id,
            'usuario_id' => $userId,
            'ts' => now(),
        ]);
    }

    private function getStockDisponible(string $itemId, int $almacenId): float
    {
        $almacen = Almacen::find($almacenId);

        $query = DB::connection('pgsql')
            ->table('selemti.mov_inv')
            ->where('item_id', $itemId);

        if ($almacen && $almacen->sucursal_id) {
            $query->where('sucursal_id', $almacen->sucursal_id);
        }

        $result = $query
            ->selectRaw('COALESCE(SUM(cantidad), 0) AS total_qty')
            ->first();

        return (float) ($result->total_qty ?? 0);
    }

    private function validateLine(array $line): void
    {
        if (! isset($line['item_id'], $line['cantidad'], $line['uom_id'])) {
            throw new InvalidArgumentException('Cada línea debe tener item_id, cantidad y uom_id');
        }

        if ($line['cantidad'] <= 0) {
            throw new InvalidArgumentException('La cantidad debe ser mayor a 0');
        }

        if (! Item::find($line['item_id'])) {
            throw new InvalidArgumentException("Item {$line['item_id']} no encontrado");
        }
    }

    private function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new InvalidArgumentException(sprintf('El %s debe ser un ID positivo.', $label));
        }
    }
}
