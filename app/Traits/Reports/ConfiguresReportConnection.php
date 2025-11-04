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
        DB::connection('pgsql')->statement("SET search_path TO public, selemti");
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
        return "t.paid = TRUE AND t.voided = FALSE";
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
     * Calcula neto de ticket
     */
    protected function getTicketNetAmount(): string
    {
        return "(t.total_price - COALESCE(t.total_discount, 0))";
    }
}
