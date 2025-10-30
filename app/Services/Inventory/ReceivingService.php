<?php

namespace App\Services\Inventory;

use InvalidArgumentException;
use RuntimeException;

/**
 * Servicio para orquestar el ciclo de vida de recepciones de compra.
 *
 * @author
 *  Gustavo Selem - Terrena Project (2025-10-26)
 */
class ReceivingService
{
    /**
     * Genera una recepción EN_PROCESO a partir de una PO aprobada.
     *
     * @route POST /api/purchasing/receptions/create-from-po/{purchase_order_id}
     * @param int $purchaseOrderId Identificador de la orden de compra.
     * @param int $userId Usuario que inicia el borrador.
     * @return array Datos placeholder de la recepción creada.
     * @throws InvalidArgumentException
     * @todo Persistir recepcion_cab/det con estatus EN_PROCESO y vincular purchase_order.
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
     * Actualiza el detalle físico recibido manteniendo tolerancias listas para validación.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/lines
     * @param int $recepcionId Recepción objetivo.
     * @param array $lineItems Líneas capturadas (item_id, qty, costo, uom).
     * @param int $userId Usuario que captura cantidades.
     * @return array Resultados con cantidad de líneas procesadas.
     * @throws InvalidArgumentException
     * @todo Upsert real en recepcion_det y enlazar lotes / tolerancias.
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
     * Valida cantidades vs PO aplicando tolerancias, deja estado VALIDADA y marca si requiere aprobación.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/validate
     * @param int $recepcionId Recepción a validar.
     * @param int $userId Usuario que valida.
     * @return array Estado VALIDADA y si requiere aprobación.
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Calcular diferencia_pct, persistir requiere_aprobacion y auditoría de usuario/fecha.
     */
    public function validateReception(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Load recepcion EN_PROCESO with lines, join purchase_order det to compute qty_ordenada.
        // TODO: Calculate diferencia_pct per line vs config('inventory.reception_tolerance_pct', 5).
        // TODO: Set requiere_aprobacion=true if any line exceeds tolerance and block posting until approved.
        // TODO: Persist estado=VALIDADA, validator user/time, and requiere_aprobacion flag.
        $requiresApproval = false;

        return [
            'recepcion_id' => $recepcionId,
            'status' => 'VALIDADA',
            'requiere_aprobacion' => $requiresApproval,
        ];
    }

    /**
     * Autoriza una recepción fuera de tolerancia limpiando el bloqueo para posteo.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/approve
     * @param int $recepcionId Recepción pendiente de override.
     * @param int $userId Usuario que aprueba.
     * @return array Estado VALIDADA sin requerir aprobación adicional.
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Verificar requiere_aprobacion, registrar aprobada_por/fecha y remover bloqueos.
     */
    public function approveReception(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Load recepcion VALIDADA con requiere_aprobacion=true, marcar override por usuario.
        return [
            'recepcion_id' => $recepcionId,
            'status' => 'VALIDADA',
            'requiere_aprobacion' => false,
            'aprobada_por' => $userId,
        ];
    }

    /**
     * Obtiene información detallada de la recepción para supervisión y UI.
     *
     * @route GET /api/purchasing/receptions/{recepcion_id}
     * @param int $recepcionId Identificador de la recepción.
     * @return array Resumen con estado, tolerancias y líneas.
     * @throws InvalidArgumentException
     * @todo Cargar recepcion_cab, recepcion_det y métricas de tolerancia desde la BD.
     */
    public function getReception(int $recepcionId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');

        // TODO: Replace with real query to recepcion_cab/det and tolerance calculations.
        return [
            'recepcion_id' => $recepcionId,
            'estado' => 'VALIDADA',
            'requiere_aprobacion' => true,
            'lineas' => [
                [
                    'item_id' => 999,
                    'item_nombre' => 'Aceite Canola 20L',
                    'qty_ordenada' => '5.000000',
                    'qty_recibida' => '7.000000',
                    'diferencia_pct' => 40.0,
                    'fuera_tolerancia' => true,
                ],
            ],
        ];
    }

    /**
     * Postea la recepción validada/aprobada a inventario y la deja CERRADA.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/post
     * @param int $recepcionId Recepción lista para Kardex.
     * @param int $userId Usuario que postea.
     * @return array Movimiento generado y estado final.
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Insertar mov_inv COMPRA, actualizar estados POSTEADA_A_INVENTARIO/CERRADA y bloquear edición.
     */
    public function postToInventory(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Assert estado actual == VALIDADA; if not, throw domain exception.
        // TODO: If requiere_aprobacion=true && no approval recorded, throw domain exception (block posting).
        // TODO: Generate mov_inv rows (tipo COMPRA) per recepcion_det with qty/costo, mark immutable.
        // TODO: Set estado POSTEADA_A_INVENTARIO ➜ CERRADA, stamp user/time, and prevent further edits.
        $movimientosGenerados = 0;

        return [
            'recepcion_id' => $recepcionId,
            'movimientos_generados' => $movimientosGenerados,
            'status' => 'CERRADA',
        ];
    }

    /**
     * Aplica costeo final valuando la recepción y actualizando últimos costos de compra.
     *
     * @route POST /api/purchasing/receptions/{recepcion_id}/costing
     * @param int $recepcionId Recepción posteada a costear.
     * @param int $userId Usuario de finanzas/compras.
     * @return array Totales valorizados y estado COSTO_FINAL_APLICADO.
     * @throws InvalidArgumentException
     * @throws RuntimeException
     * @todo Calcular total_valorizado, marcar last_cost_applied y sincronizar costos de catálogos.
     */
    public function finalizeCosting(int $recepcionId, int $userId): array
    {
        $this->guardPositiveId($recepcionId, 'recepcion');
        $this->guardPositiveId($userId, 'user');

        // TODO: Load recepcion lines (qty_recibida, costo_unitario_final) and cabecera currency.
        // TODO: Calculate total_valorizado = sum(qty_recibida * costo_unitario_final).
        // TODO: Update recepcion_cab set total_valorizado, last_cost_applied=true, status=COSTO_FINAL_APLICADO, user/time.
        // TODO: Update latest purchase cost for each item/vendor to feed future suggestions.
        $totalValorizado = 0.0;

        return [
            'recepcion_id' => $recepcionId,
            'total_valorizado' => $totalValorizado,
            'status' => 'COSTO_FINAL_APLICADO',
        ];
    }

    /**
     * Basic guard for positive identifiers.
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
