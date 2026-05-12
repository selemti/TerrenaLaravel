<?php

namespace App\Traits\Reports;

use Illuminate\Support\Facades\DB;

/**
 * Trait para configurar conexiones de reportes
 * Solo lectura, con timezone y search_path correctos
 */
trait ConfiguresReportConnection
{
    /**
     * Configura la conexión para reportes
     * Ejecuta en cada request para asegurar configuración correcta
     */
    protected function configureReportConnection(): void
    {
        DB::connection('pgsql')->statement("SET TIME ZONE 'America/Mexico_City'");
        DB::connection('pgsql')->statement('SET search_path TO public, selemti');
    }

    /**
     * Obtiene fecha de folio usando prioridad correcta
     * folio_date > settled_at > paid_at > closed_at
     */
    protected function getFolioDate(): string
    {
        return "COALESCE(
            t.folio_date::text,
            DATE(t.closing_date AT TIME ZONE 'America/Mexico_City')::text,
            DATE(t.create_date AT TIME ZONE 'America/Mexico_City')::text
        )";
    }

    /**
     * Condición para tickets válidos
     */
    protected function getValidTicketCondition(): string
    {
        return 't.paid = TRUE AND t.voided = FALSE';
    }

    /**
     * Condición para transacciones válidas
     */
    protected function getValidTransactionCondition(): string
    {
        return "tr.transaction_type = 'CREDIT' 
                AND tr.voided = FALSE 
                AND tr.payment_type NOT IN ('REFUND', 'VOID_TRANS')";
    }

    /**
     * Determina si se debe usar el modelo financiero canónico (SSOT via transactions)
     * Activado vía query param 'mode=canon' o configuración global.
     */
    protected function isCanonMode(): bool
    {
        return request()->query('mode') === 'canon'
            || config('finance.use_canon_mode', false);
    }

    /**
     * Calcula neto de ticket
     * AS-IS (Legacy): Resta aritmética de total_price - total_discount.
     * TO-BE (Canon): Suma de transacciones liquidadas (Fuente de Verdad Monetaria).
     */
    protected function getTicketNetAmount(): string
    {
        if ($this->isCanonMode()) {
            return "COALESCE((
                SELECT SUM(tx.amount) 
                FROM public.transactions tx 
                WHERE tx.ticket_id = t.id 
                  AND (tx.voided = FALSE OR tx.voided IS NULL)
                  AND tx.transaction_type IN ('CREDIT', 'DEBIT') 
                  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS', 'REFUND_CARD')
                  AND tx.amount > 0
            ), 0)";
        }

        return '(t.total_price - COALESCE(t.total_discount, 0))';
    }
}
