<?php

namespace App\Services\Purchasing;

use InvalidArgumentException;
use RuntimeException;

/**
 * Servicio que gestiona devoluciones a proveedor y su impacto en inventario.
 */
class ReturnService
{
    /**
     * Crea una devolución en BORRADOR vinculada a una purchase order.
     *
     * @route POST /api/purchasing/returns/create-from-po/{purchase_order_id}
     * @param int $purchaseOrderId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @todo Persistir cabecera BORRADOR asociada a la compra original.
     */
    public function createDraftReturn(int $purchaseOrderId, int $userId): array
    {
        $this->guardPositiveId($purchaseOrderId, 'purchase order');
        $this->guardPositiveId($userId, 'user');

        // TODO: Create devolucion cabecera in BORRADOR based on purchase_order/reception data.
        return [
            'return_id' => null,
            'status' => 'BORRADOR',
        ];
    }

    /**
     * Aprueba una devolución y la avanza a estado APROBADA.
     *
     * @route POST /api/purchasing/returns/{return_id}/approve
     * @param int $returnId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Validar estado actual BORRADOR y registrar auditoría de aprobación.
     */
    public function approveReturn(int $returnId, int $userId): array
    {
        $this->guardPositiveId($returnId, 'return');
        $this->guardPositiveId($userId, 'user');

        // TODO: Validate current estado == BORRADOR and persist APROBADA with approver metadata.
        return [
            'return_id' => $returnId,
            'status' => 'APROBADA',
        ];
    }

    /**
     * Marca la devolución como enviada al proveedor y almacena tracking.
     *
     * @route POST /api/purchasing/returns/{return_id}/ship
     * @param int $returnId
     * @param array $trackingInfo
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Persistir datos de guía, transportista y estado EN_TRANSITO.
     */
    public function markShipped(int $returnId, array $trackingInfo, int $userId): array
    {
        $this->guardPositiveId($returnId, 'return');
        $this->guardPositiveId($userId, 'user');

        // TODO: Persist tracking details, estado=EN_TRANSITO, and timestamps without touching inventory.
        return [
            'return_id' => $returnId,
            'status' => 'EN_TRANSITO',
        ];
    }

    /**
     * Confirma que el proveedor recibió físicamente la devolución.
     *
     * @route POST /api/purchasing/returns/{return_id}/confirm
     * @param int $returnId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Registrar evidencia de recepción y fecha de confirmación.
     */
    public function confirmVendorReceived(int $returnId, int $userId): array
    {
        $this->guardPositiveId($returnId, 'return');
        $this->guardPositiveId($userId, 'user');

        // TODO: Record confirmation docs (e.g., signed manifest) and transition to RECIBIDA_PROVEEDOR.
        return [
            'return_id' => $returnId,
            'status' => 'RECIBIDA_PROVEEDOR',
        ];
    }

    /**
     * Genera los movimientos negativos de inventario y pasa a NOTA_CREDITO.
     *
     * @route POST /api/purchasing/returns/{return_id}/post
     * @param int $returnId
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Insertar mov_inv DEVOLUCION_PROVEEDOR y cerrar inventario del lote devuelto.
     */
    public function postInventoryAdjustment(int $returnId, int $userId): array
    {
        $this->guardPositiveId($returnId, 'return');
        $this->guardPositiveId($userId, 'user');

        // TODO: Ensure estado == RECIBIDA_PROVEEDOR before generating negative mov_inv rows (qty < 0).
        // TODO: Mark movements immutable and set estado NOTA_CREDITO pending credit documentation.
        $movimientosGenerados = 0;

        return [
            'return_id' => $returnId,
            'movimientos_generados' => $movimientosGenerados,
            'status' => 'NOTA_CREDITO',
        ];
    }

    /**
     * Adjunta la nota de crédito del proveedor y cierra la devolución.
     *
     * @route POST /api/purchasing/returns/{return_id}/credit-note
     * @param int $returnId
     * @param array $notaCreditoData
     * @param int $userId
     * @return array
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Guardar folio/monto/fecha y cambiar estado a CERRADA.
     */
    public function attachCreditNote(int $returnId, array $notaCreditoData, int $userId): array
    {
        $this->guardPositiveId($returnId, 'return');
        $this->guardPositiveId($userId, 'user');

        // TODO: Persist folio_nota_credito, monto, fecha, and transition NOTA_CREDITO → CERRADA.
        return [
            'return_id' => $returnId,
            'status' => 'CERRADA',
        ];
    }

    /**
     * Valida que un identificador sea positivo.
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
