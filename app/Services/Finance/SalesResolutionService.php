<?php

namespace App\Services\Finance;

use Illuminate\Support\Facades\DB;

/**
 * Service Canónico para Resolución de Ventas y Liquidación
 *
 * Implementa la Fase 1 del Roadmap 2026: Saneamiento de Ingresos (SSOT).
 * Centraliza la lógica de normalización de descuentos (BUG-04) y la validación
 * contra public.transactions.
 */
class SalesResolutionService
{
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
        $ticket = DB::connection('pgsql')
            ->table('public.ticket')
            ->where('id', $ticketId)
            ->select('sub_total', 'total_price', 'total_discount')
            ->first();

        if (! $ticket) {
            return ['net' => 0, 'discount' => 0, 'error' => 'Ticket not found'];
        }

        // 1. Obtener suma de transacciones efectivas (SSOT Monetario)
        // Aplicamos los mismos filtros que SalesExceptionsReportService para "Effective Payments"
        $txSum = DB::connection('pgsql')
            ->table('public.transactions as tx')
            ->where('tx.ticket_id', $ticketId)
            ->where(function ($q) {
                $q->where('tx.voided', false)
                    ->orWhereNull('tx.voided');
            })
            ->whereIn(DB::raw('UPPER(COALESCE(tx.transaction_type, \'\'))'), ['CREDIT', 'DEBIT'])
            ->whereNotIn(DB::raw('UPPER(COALESCE(tx.payment_type, \'\'))'), ['REFUND', 'VOID_TRANS', 'REFUND_CARD'])
            ->where('tx.amount', '>', 0)
            ->sum('tx.amount');

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
        $ticketDiscounts = DB::connection('pgsql')
            ->table('public.ticket_discount as td')
            ->select('td.type', 'td.value', 'td.name')
            ->where('td.ticket_id', $ticketId)
            ->get();

        foreach ($ticketDiscounts as $td) {
            $totalResolved += $this->normalizeValue($td->type, $td->value, $subTotal);
        }

        // B. Descuentos a nivel de Item
        $itemDiscounts = DB::connection('pgsql')
            ->table('public.ticket_item as ti')
            ->join('public.ticket_item_discount as tid', 'tid.ticket_itemid', '=', 'ti.id')
            ->select('tid.type', 'tid.value', 'tid.amount', 'ti.sub_total as item_sub_total')
            ->where('ti.ticket_id', $ticketId)
            ->get();

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
