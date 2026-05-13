<?php

namespace App\Services\Finance;

use App\Adapters\FloreantPos\FloreantPosAdapter;

/**
 * Service Canónico para Resolución de Ventas y Liquidación.
 *
 * Implementa la Fase 1 del Roadmap 2026: Saneamiento de Ingresos (SSOT).
 * Centraliza la lógica de normalización de descuentos (BUG-04) y la validación
 * contra public.transactions.
 */
class SalesResolutionService
{
    public function __construct(private readonly FloreantPosAdapter $pos) {}

    // Constantes de Floreant POS para tipos de descuento
    const DISCOUNT_TYPE_FIXED = 0;

    const DISCOUNT_TYPE_PERCENTAGE = 1;

    /**
     * Resuelve la liquidación neta de un ticket basándose en el SSOT (Transactions).
     *
     * @return array [net_liquidation, resolved_discount, source]
     */
    public function resolveNetLiquidation(int $ticketId): array
    {
        $ticket = $this->pos->getTicketById($ticketId);

        if (! $ticket) {
            return ['net' => 0, 'discount' => 0, 'error' => 'Ticket not found'];
        }

        $txSum = $this->pos->getEffectiveTransactionSum($ticketId);

        // 2. Resolver descuentos con Normalización (% vs $)
        $resolvedDiscount = $this->calculateNormalizedDiscounts($ticketId, (float) $ticket->sub_total);

        // 3. Resolución Logica (TO-BE)
        // Si hay transacciones, mandan sobre el total_price calculado.
        // Si no hay transacciones y el descuento normalizado cubre el subtotal, es 0.
        $netLiquidation = 0;

        if ($txSum > 0) {
            $netLiquidation = (float) $txSum;
        } elseif ($resolvedDiscount >= (float) $ticket->sub_total) {
            $netLiquidation = 0;
        } else {
            // Fallback preventivo (AS-IS logic normalized)
            $netLiquidation = max(0, (float) $ticket->sub_total - $resolvedDiscount);
        }

        return [
            'ticket_id' => $ticketId,
            'net_liquidation' => round($netLiquidation, 2),
            'resolved_discount' => round($resolvedDiscount, 2),
            'legacy_total_price' => (float) $ticket->total_price,
            'legacy_total_discount' => (float) $ticket->total_discount,
            'tx_sum' => (float) $txSum,
            'is_normalized' => ($resolvedDiscount != (float) $ticket->total_discount),
        ];
    }

    /**
     * Calcula los descuentos normalizados analizando ticket_discount y ticket_item_discount.
     * Implementa la corrección del BUG-04.
     */
    private function calculateNormalizedDiscounts(int $ticketId, float $subTotal): float
    {
        $totalResolved = 0;

        // A. Descuentos a nivel de Ticket
        $ticketDiscounts = $this->pos->getTicketDiscounts($ticketId);

        foreach ($ticketDiscounts as $td) {
            $totalResolved += $this->normalizeValue($td->type, $td->value, $subTotal);
        }

        // B. Descuentos a nivel de Item
        $itemDiscounts = $this->pos->getTicketItemDiscounts($ticketId);

        foreach ($itemDiscounts as $tid) {
            // Floreant a veces guarda el monto ya calculado en 'amount'
            if (isset($tid->amount) && $tid->amount > 0 && $tid->type == self::DISCOUNT_TYPE_FIXED) {
                $totalResolved += (float) $tid->amount;
            } else {
                $totalResolved += $this->normalizeValue($tid->type, $tid->value, (float) $tid->item_sub_total);
            }
        }

        return $totalResolved;
    }

    /**
     * Normaliza el valor basándose en el tipo.
     * BUG-04 fix: Si el tipo es Porcentaje, calcula sobre la base.
     */
    private function normalizeValue($type, $value, $base): float
    {
        $value = (float) $value;
        $base = (float) $base;

        if ($type == self::DISCOUNT_TYPE_PERCENTAGE) {
            // Si es 100%, el descuento es la base completa.
            if ($value >= 100) {
                return $base;
            }

            return round(($base * $value) / 100, 2);
        }

        // Tipo fijo
        return $value;
    }
}
