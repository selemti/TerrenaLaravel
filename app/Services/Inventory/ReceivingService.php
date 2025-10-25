<?php

namespace App\Services\Inventory;

use InvalidArgumentException;

class ReceivingService
{
    /**
     * Drafts a reception header in estado EN_PROCESO leveraging purchase_order data as described
     * in docs/Replenishment/STATUS_SPRINT_1.2.md (steps 1-3).
     *
     * @param int $purchaseOrderId Approved purchase_order identifier that will seed cab+det info.
     * @param int $userId User creating the draft reception.
     * @return array Placeholder payload for controller consumers.
     */
    public function createDraftReception(int $purchaseOrderId, int $userId): array
    {
        $this->guardPositiveId($purchaseOrderId, 'purchase order');
        $this->guardPositiveId($userId, 'user');

        // TODO: Pull purchase_order cab/det and persist recepcion_cab/det EN_PROCESO.
        return [
            'recepcion_id' => null,
            'status' => 'EN_PROCESO',
        ];
    }

    /**
     * Receives physical quantities for each item (step 3 detail) keeping tolerances ready for later
     * validation. Expects already drafted reception in EN_PROCESO state.
     *
     * @param int $recepcionId Target reception header identifier.
     * @param array $lineItems Array of line DTOs (item_id, qty_recibida, costo_unitario, uom, etc.).
     * @param int $userId User capturing the physical receipt.
     * @return array Placeholder payload for controller consumers.
     */
    public function updateReceptionLines(int $recepcionId, array $lineItems, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        if (empty($lineItems)) {
            throw new InvalidArgumentException('Line items array cannot be empty.');
        }

        // TODO: Upsert recepcion_det rows, track qty_recibida vs qty_ordenada for tolerance checks.
        return [
            'recepcion_id' => $recepcionId,
            'lines_processed' => count($lineItems),
        ];
    }

    /**
     * Moves reception from EN_PROCESO to VALIDADA once quantities are confirmed (flow step 4) and
     * flags those beyond tolerance for review.
     *
     * @param int $recepcionId Reception identifier being validated.
     * @param int $userId Approver validating the reception.
     * @return array Placeholder payload for controller consumers.
     */
    public function validateReception(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Check EN_PROCESO state, evaluate tolerance vs config('inventory.reception_tolerance_pct').
        return [
            'recepcion_id' => $recepcionId,
            'status' => 'VALIDADA',
        ];
    }

    /**
     * Posts validated reception to inventory by creating selemti.mov_inv COMPRA rows and closes the
     * process (flow steps 5-6). Makes inventory immutable and finalizes estado POSTEADA_A_INVENTARIO → CERRADA.
     *
     * @param int $recepcionId Reception identifier ready for posting.
     * @param int $userId User executing the posting (almacenista / supervisor).
     * @return array Placeholder payload for controller consumers.
     */
    public function postToInventory(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Generate mov_inv lines (tipo COMPRA), update reception states, mark immutable.
        return [
            'recepcion_id' => $recepcionId,
            'status' => 'POSTEADA_A_INVENTARIO',
        ];
    }

    /**
     * Basic guard for positive identifiers.
     */
    protected function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new InvalidArgumentException(sprintf('The %s id must be greater than zero.', $label));
        }
    }
}
