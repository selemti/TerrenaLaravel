<?php

namespace App\Services\Production;

use App\Exceptions\Production\ProductionException;

/**
 * Servicio para planear, consumir y postear batches de producción interna.
 */
class ProductionService
{
    /**
     * Planea un batch de producción basado en una receta.
     *
     * @route POST /api/production/batch/plan
     *
     * @throws InvalidArgumentException
     *
     * @todo Persistir batch PLANIFICADA y asociar recipe_version vigente.
     */
    public function planBatch(int $recipeId, float $qtyTarget, int $userId): array
    {
        $this->guardPositiveId($recipeId, 'recipe');
        $this->guardPositiveQty($qtyTarget);
        $this->guardPositiveId($userId, 'user');

        // TODO: Persist batch header with estado=PLANIFICADA, qty objetivo y ruta de producción.
        return [
            'batch_id' => null,
            'status' => 'PLANIFICADA',
        ];
    }

    /**
     * Registra consumo de insumos y pasa a EN_PROCESO.
     *
     * @route POST /api/production/batch/{batch_id}/consume
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Validar disponibilidad en inventario y bloquear lotes agotados.
     */
    public function consumeIngredients(int $batchId, array $consumedLines, int $userId): array
    {
        $this->guardPositiveId($batchId, 'batch');
        $this->guardPositiveId($userId, 'user');

        if (empty($consumedLines)) {
            throw new ProductionException('Consumed ingredient lines required.');
        }

        // TODO: Register insumo consumption, track lots, validate inventory availability.
        return [
            'batch_id' => $batchId,
            'status' => 'EN_PROCESO',
            'lines_consumed' => count($consumedLines),
        ];
    }

    /**
     * Registra las salidas de producto terminado y marca COMPLETADA.
     *
     * @route POST /api/production/batch/{batch_id}/complete
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Asociar lotes creados, métricas de merma y firmas de control de calidad.
     */
    public function completeBatch(int $batchId, array $producedLines, int $userId): array
    {
        $this->guardPositiveId($batchId, 'batch');
        $this->guardPositiveId($userId, 'user');

        if (empty($producedLines)) {
            throw new ProductionException('Produced lines are required to complete batch.');
        }

        // TODO: Persist produced outputs, quality checks, yield metrics.
        return [
            'batch_id' => $batchId,
            'status' => 'COMPLETADA',
            'lines_produced' => count($producedLines),
        ];
    }

    /**
     * Genera mov_inv para insumos y productos terminados y sella POSTEADA.
     *
     * @route POST /api/production/batch/{batch_id}/post
     *
     * @throws InvalidArgumentException
     * @throws RuntimeException
     *
     * @todo Insertar movimientos negativos/positivos y cerrar el batch transaccionalmente.
     */
    public function postBatchToInventory(int $batchId, int $userId): array
    {
        $this->guardPositiveId($batchId, 'batch');
        $this->guardPositiveId($userId, 'user');

        // TODO: Ensure estado=COMPLETADA.
        // TODO: Create mov_inv negativos for consumed insumos and positivos for finished products.
        // TODO: Finalize estado=POSTEADA and lock editing.
        $movimientosGenerados = 0;

        return [
            'batch_id' => $batchId,
            'movimientos_generados' => $movimientosGenerados,
            'status' => 'POSTEADA',
        ];
    }

    /**
     * Garantiza que el identificador sea positivo.
     *
     * @throws InvalidArgumentException
     */
    protected function guardPositiveId(int $id, string $label): void
    {
        if ($id <= 0) {
            throw new ProductionException(sprintf('The %s id must be greater than zero.', $label));
        }
    }

    /**
     * Garantiza que la cantidad planeada sea mayor que cero.
     *
     * @throws InvalidArgumentException
     */
    protected function guardPositiveQty(float $qty): void
    {
        if ($qty <= 0) {
            throw new ProductionException('Quantity target must be greater than zero.');
        }
    }
}
