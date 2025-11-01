<?php

namespace App\Services\Inventory;

use App\Models\Inventory\TransferHeader;
use App\Models\Inventory\TransferLine;
use App\Models\Inv\Movement;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

/**
 * Servicio que gestiona transferencias internas entre almacenes.
 */
class TransferService
{
    /**
     * Crea una transferencia SOLICITADA entre almacenes.
     *
     * @route POST /api/inventory/transfers/create
     * @param int $fromAlmacenId
     * @param int $toAlmacenId
     * @param array $lines
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @todo Persistir cabecera/detalle y validar stocks iniciales.
     */
    public function createTransfer(int $fromAlmacenId, int $toAlmacenId, array $lines, int $userId): array
    {
        $this->guardPositiveId($fromAlmacenId, 'almacén origen');
        $this->guardPositiveId($toAlmacenId, 'almacén destino');
        $this->guardPositiveId($userId, 'user');

        if ($fromAlmacenId === $toAlmacenId) {
            throw new InvalidArgumentException('Almacén origen y destino deben ser diferentes.');
        }

        if (empty($lines)) {
            throw new InvalidArgumentException('At least one line item is required for a transfer.');
        }

        return DB::transaction(function () use ($fromAlmacenId, $toAlmacenId, $lines, $userId) {
            $header = TransferHeader::create([
                'origen_almacen_id' => $fromAlmacenId,
                'destino_almacen_id' => $toAlmacenId,
                'estado' => TransferHeader::STATUS_SOLICITADA,
                'creada_por' => $userId,
                'fecha_solicitada' => now(),
                'observaciones' => $lines[0]['observaciones'] ?? null,
            ]);

            foreach ($lines as $line) {
                TransferLine::create([
                    'transfer_id' => $header->id,
                    'item_id' => $line['item_id'],
                    'cantidad_solicitada' => $line['cantidad'],
                    'unidad_medida' => $line['unidad_medida'],
                    'observaciones' => $line['observaciones'] ?? null,
                    'created_at' => now(),
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
     * @param int $transferId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Validar estado SOLICITADA y registrar quién aprobó.
     */
    public function approveTransfer(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId) {
            $transfer = TransferHeader::with('lineas.item')->findOrFail($transferId);

            if (!$transfer->canApprove()) {
                throw new RuntimeException("Transfer must be in SOLICITADA status to be approved. Current: {$transfer->estado}");
            }

            // Validar stock disponible en almacén origen
            foreach ($transfer->lineas as $line) {
                $stock = DB::connection('pgsql')
                    ->table('selemti.stock')
                    ->where('almacen_id', $transfer->origen_almacen_id)
                    ->where('item_id', $line->item_id)
                    ->value('cantidad_actual');

                if (!$stock || $stock < $line->cantidad_solicitada) {
                    throw new RuntimeException(
                        "Stock insuficiente para item {$line->item->nombre}. Disponible: {$stock}, Requerido: {$line->cantidad_solicitada}"
                    );
                }
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_APROBADA,
                'aprobada_por' => $userId,
                'fecha_aprobada' => now(),
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
     * @param int $transferId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Guardar datos de transporte y hora de salida.
     */
    public function markInTransit(int $transferId, int $userId, ?string $numeroGuia = null): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId, $numeroGuia) {
            $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

            if (!$transfer->canShip()) {
                throw new RuntimeException("Transfer must be in APROBADA status to be shipped. Current: {$transfer->estado}");
            }

            // Actualizar cantidades despachadas (igual a solicitadas por defecto)
            foreach ($transfer->lineas as $line) {
                $line->update([
                    'cantidad_despachada' => $line->cantidad_solicitada,
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_EN_TRANSITO,
                'despachada_por' => $userId,
                'fecha_despachada' => now(),
                'numero_guia' => $numeroGuia,
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
     * @param int $transferId
     * @param array $receivedLines
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Calcular diferencias y preparar ajustes antes del posteo.
     */
    public function receiveTransfer(int $transferId, array $receivedLines, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        if (empty($receivedLines)) {
            throw new InvalidArgumentException('Received lines data is required.');
        }

        return DB::transaction(function () use ($transferId, $receivedLines, $userId) {
            $transfer = TransferHeader::with('lineas')->findOrFail($transferId);

            if (!$transfer->canReceive()) {
                throw new RuntimeException("Transfer must be in EN_TRANSITO status to be received. Current: {$transfer->estado}");
            }

            // Actualizar cantidades recibidas y observaciones
            foreach ($receivedLines as $lineData) {
                $line = $transfer->lineas()->where('id', $lineData['line_id'])->first();
                
                if (!$line) {
                    throw new InvalidArgumentException("Line {$lineData['line_id']} not found in transfer {$transferId}");
                }

                $line->update([
                    'cantidad_recibida' => $lineData['cantidad_recibida'],
                    'observaciones_recepcion' => $lineData['observaciones'] ?? null,
                ]);
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_RECIBIDA,
                'recibida_por' => $userId,
                'fecha_recibida' => now(),
                'observaciones_recepcion' => $receivedLines[0]['observaciones_generales'] ?? null,
            ]);

            // Calcular varianzas
            $varianzas = [];
            foreach ($transfer->lineas()->get() as $line) {
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
     * @param int $transferId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Insertar TRANSFER_OUT/TRANSFER_IN y sellar estado CERRADA.
     */
    public function postTransferToInventory(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        return DB::transaction(function () use ($transferId, $userId) {
            $transfer = TransferHeader::with('lineas.item', 'origenAlmacen', 'destinoAlmacen')->findOrFail($transferId);

            if (!$transfer->canPost()) {
                throw new RuntimeException("Transfer must be in RECIBIDA status to be posted. Current: {$transfer->estado}");
            }

            $movimientos = [];

            foreach ($transfer->lineas as $line) {
                // Movimiento de SALIDA en almacén origen
                $movOut = Movement::create([
                    'almacen_id' => $transfer->origen_almacen_id,
                    'item_id' => $line->item_id,
                    'tipo_movimiento' => 'TRASPASO_OUT',
                    'cantidad' => -abs($line->cantidad_despachada),
                    'unidad_medida' => $line->unidad_medida,
                    'fecha_movimiento' => now(),
                    'usuario_id' => $userId,
                    'referencia_tipo' => 'TRANSFER',
                    'referencia_id' => $transfer->id,
                    'observaciones' => "Transferencia #{$transfer->id} a {$transfer->destinoAlmacen->nombre}",
                ]);

                // Movimiento de ENTRADA en almacén destino
                $movIn = Movement::create([
                    'almacen_id' => $transfer->destino_almacen_id,
                    'item_id' => $line->item_id,
                    'tipo_movimiento' => 'TRASPASO_IN',
                    'cantidad' => abs($line->cantidad_recibida),
                    'unidad_medida' => $line->unidad_medida,
                    'fecha_movimiento' => now(),
                    'usuario_id' => $userId,
                    'referencia_tipo' => 'TRANSFER',
                    'referencia_id' => $transfer->id,
                    'observaciones' => "Transferencia #{$transfer->id} desde {$transfer->origenAlmacen->nombre}",
                ]);

                $movimientos[] = [
                    'out' => $movOut->id,
                    'in' => $movIn->id,
                ];
            }

            $transfer->update([
                'estado' => TransferHeader::STATUS_POSTEADA,
                'posteada_por' => $userId,
                'fecha_posteada' => now(),
            ]);

            return [
                'transfer_id' => $transfer->id,
                'movimientos_generados' => count($movimientos) * 2,
                'status' => $transfer->estado,
                'movimientos' => $movimientos,
            ];
        });
    }

    /**
     * Garantiza que un identificador numérico sea válido.
     *
     * @param int $id
     * @param string $label
     * @return void
     * @throws InvalidArgumentException
     */
    protected function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new InvalidArgumentException(sprintf('The %s id must be greater than zero.', $label));
        }
    }
}
