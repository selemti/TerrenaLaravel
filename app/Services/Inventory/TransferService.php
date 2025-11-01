<?php

namespace App\Services\Inventory;

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

        if (empty($lines)) {
            throw new InvalidArgumentException('At least one line item is required for a transfer.');
        }

        // TODO: Persist transfer cabecera with estado=SOLICITADA and attach line detail.
        return [
            'transfer_id' => null,
            'status' => 'SOLICITADA',
        ];
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

        // TODO: Validate estado=SOLICITADA and update to APROBADA with approval metadata.
        return [
            'transfer_id' => $transferId,
            'status' => 'APROBADA',
        ];
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
    public function markInTransit(int $transferId, int $userId): array
    {
        $this->guardPositiveId($transferId, 'transfer');
        $this->guardPositiveId($userId, 'user');

        // TODO: Capture shipping details (carrier, guía) and set estado=EN_TRANSITO without stock impact yet.
        return [
            'transfer_id' => $transferId,
            'status' => 'EN_TRANSITO',
        ];
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

        // TODO: Validate estado=EN_TRANSITO, store received lines, compute diffs to flag adjustments.
        $receivedCount = count($receivedLines);

        return [
            'transfer_id' => $transferId,
            'lines_confirmed' => $receivedCount,
            'status' => 'RECIBIDA',
        ];
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

        // TODO: Ensure estado=RECIBIDA before generating mov_inv.
        // TODO: Insert NEGATIVE movements for origen (tipo TRANSFER_OUT) and POSITIVE for destino (TRANSFER_IN).
        // TODO: Set estado=CERRADA and lock further edits.
        $movimientosGenerados = 0;

        return [
            'transfer_id' => $transferId,
            'movimientos_generados' => $movimientosGenerados,
            'status' => 'CERRADA',
        ];
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
