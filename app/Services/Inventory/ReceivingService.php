<?php

namespace App\Services\Inventory;

use App\Exceptions\Inventory\InventoryValidationException;

/**
 * Fachada del ciclo de vida de recepciones de compra.
 * Delega a ReceptionService que contiene la implementación real con UOM pipeline.
 */
class ReceivingService
{
    public function __construct(
        protected ReceptionService $receptionService
    ) {}

    public function createDraftReception(int $purchaseOrderId, int $userId): array
    {
        $this->guardPositiveId($purchaseOrderId, 'purchase order');
        $this->guardPositiveId($userId, 'user');

        $reception = $this->receptionService->createReception([
            'purchase_order_id' => $purchaseOrderId,
            'created_by' => $userId,
        ]);

        return ['recepcion_id' => $reception->id, 'status' => $reception->status];
    }

    public function updateReceptionLines(int $recepcionId, array $lineItems, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        if (empty($lineItems)) {
            throw new InventoryValidationException('Line items array cannot be empty.');
        }

        $this->receptionService->updateLines($recepcionId, $lineItems);

        return ['recepcion_id' => $recepcionId, 'lines_processed' => count($lineItems)];
    }

    public function validateReception(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        $result = $this->receptionService->validateReception($recepcionId, $userId);

        return [
            'recepcion_id' => $recepcionId,
            'status' => 'VALIDADA',
            'requiere_aprobacion' => $result['requiere_aprobacion'] ?? false,
        ];
    }

    public function approveReception(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        $this->receptionService->approveReception($recepcionId, $userId);

        return ['recepcion_id' => $recepcionId, 'status' => 'VALIDADA', 'requiere_aprobacion' => false, 'aprobada_por' => $userId];
    }

    public function getReception(int $recepcionId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');

        return $this->receptionService->getReceptionDetail($recepcionId);
    }

    public function postToInventory(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        $result = $this->receptionService->postReception($recepcionId, $userId);

        return ['recepcion_id' => $recepcionId, 'movimientos_generados' => $result['movimientos'] ?? 0, 'status' => 'CERRADA'];
    }

    public function finalizeCosting(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // ReceptionService maneja costeo en el posteo — marcamos como completado
        return ['recepcion_id' => $recepcionId, 'total_valorizado' => 0.0, 'status' => 'COSTO_FINAL_APLICADO'];
    }

    protected function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new InventoryValidationException(sprintf('The %s id must be greater than zero.', $label));
        }
    }
}
