<?php

/**
 * Análisis Profundo de Discrepancias en Ventas - Octubre 2025
 * 
 * Este script analiza las discrepancias entre los Drawer Pull Reports
 * y los datos reales de la base de datos, expandiendo el análisis
 * del 1 de octubre a todo el mes.
 */

require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "          ANÁLISIS PROFUNDO DE DISCREPANCIAS EN VENTAS - OCTUBRE 2025             \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

// ───────────────────────────────────────────────────────────────────────────────
// 1. RESUMEN GENERAL DE DISCREPANCIAS POR DÍA
// ───────────────────────────────────────────────────────────────────────────────
echo "1. RESUMEN DE DISCREPANCIAS POR DÍA\n";
echo str_repeat("─", 100) . "\n";

$discrepancias = DB::select("
    WITH drawer_data AS (
        SELECT 
            dp.drawer_pull_date::date AS fecha,
            dp.terminal_id,
            dp.drawer_pull_ticket_count AS tickets_reportados,
            dp.drawer_pull_net_sales AS ventas_netas_reportadas,
            dp.drawer_pull_cash_receipt AS efectivo_reportado
        FROM public.drawer_pull_report dp
        WHERE dp.drawer_pull_date >= '2025-10-01' 
          AND dp.drawer_pull_date < '2025-11-01'
    ),
    real_data AS (
        SELECT 
            COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
            t.terminal_id,
            COUNT(DISTINCT t.id) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_reales,
            COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)) 
                FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0) AS ventas_reales,
            COALESCE(SUM(tx.amount) 
                FILTER (WHERE tx.payment_type = 'CASH' 
                        AND tx.voided = FALSE 
                        AND tx.transaction_type = 'CREDIT'
                        AND t.paid = TRUE 
                        AND t.voided = FALSE), 0) AS efectivo_real
        FROM public.ticket t
        LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
          AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
        GROUP BY COALESCE(t.folio_date, t.closing_date::date, t.create_date::date), t.terminal_id
    )
    SELECT 
        dd.fecha,
        dd.terminal_id,
        dd.tickets_reportados,
        COALESCE(rd.tickets_reales, 0) AS tickets_reales,
        dd.tickets_reportados - COALESCE(rd.tickets_reales, 0) AS diff_tickets,
        ROUND(dd.ventas_netas_reportadas::numeric, 2) AS ventas_reportadas,
        ROUND(COALESCE(rd.ventas_reales, 0)::numeric, 2) AS ventas_reales,
        ROUND((dd.ventas_netas_reportadas - COALESCE(rd.ventas_reales, 0))::numeric, 2) AS diff_ventas,
        ROUND(dd.efectivo_reportado::numeric, 2) AS efectivo_reportado,
        ROUND(COALESCE(rd.efectivo_real, 0)::numeric, 2) AS efectivo_real,
        ROUND((dd.efectivo_reportado - COALESCE(rd.efectivo_real, 0))::numeric, 2) AS diff_efectivo
    FROM drawer_data dd
    LEFT JOIN real_data rd ON rd.fecha = dd.fecha AND rd.terminal_id = dd.terminal_id
    WHERE ABS(dd.tickets_reportados - COALESCE(rd.tickets_reales, 0)) > 0
       OR ABS(dd.ventas_netas_reportadas - COALESCE(rd.ventas_reales, 0)) > 1
       OR ABS(dd.efectivo_reportado - COALESCE(rd.efectivo_real, 0)) > 1
    ORDER BY ABS(dd.ventas_netas_reportadas - COALESCE(rd.ventas_reales, 0)) DESC
");

printf("%-12s %-8s %-10s %-10s %-10s %-12s %-12s %-10s\n",
    "Fecha", "Term", "Tkt Rep", "Tkt Real", "Diff Tkt", "Diff Ventas", "Diff Efect", "Impact");
echo str_repeat("─", 100) . "\n";

$totalDiffVentas = 0;
$totalDiffEfectivo = 0;
$diasConProblemas = 0;

foreach ($discrepancias as $disc) {
    $impact = abs($disc->diff_ventas) > 50 ? '⚠️ ALTO' : (abs($disc->diff_ventas) > 10 ? '⚡ MEDIO' : '✓ BAJO');
    
    printf("%-12s %-8s %-10d %-10d %-10d $%-11.2f $%-11.2f %-10s\n",
        $disc->fecha,
        $disc->terminal_id,
        $disc->tickets_reportados,
        $disc->tickets_reales,
        $disc->diff_tickets,
        $disc->diff_ventas,
        $disc->diff_efectivo,
        $impact
    );
    
    $totalDiffVentas += $disc->diff_ventas;
    $totalDiffEfectivo += $disc->diff_efectivo;
    $diasConProblemas++;
}

echo str_repeat("─", 100) . "\n";
echo "TOTAL: Días con problemas: $diasConProblemas | ";
echo "Diff Ventas: $" . number_format($totalDiffVentas, 2) . " | ";
echo "Diff Efectivo: $" . number_format($totalDiffEfectivo, 2) . "\n\n";

// ───────────────────────────────────────────────────────────────────────────────
// 2. TICKETS CON DESCUENTO DEL 100%
// ───────────────────────────────────────────────────────────────────────────────
echo "2. TICKETS CON DESCUENTO DEL 100% (PATRÓN CRÍTICO)\n";
echo str_repeat("─", 100) . "\n";

$descuentos100 = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id AS ticket_id,
        t.terminal_id,
        t.total_price,
        COALESCE(t.total_discount, 0) AS descuento,
        ROUND((COALESCE(t.total_discount, 0) / NULLIF(t.total_price, 0) * 100)::numeric, 2) AS porcentaje,
        t.paid,
        t.voided
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
      AND t.total_price > 0
      AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99
    ORDER BY fecha, t.total_price DESC
");

if (count($descuentos100) > 0) {
    printf("%-12s %-10s %-8s %-12s %-12s %-8s %-8s %-8s\n",
        "Fecha", "Ticket", "Term", "Total", "Descuento", "%Desc", "Pagado", "Anulado");
    echo str_repeat("─", 100) . "\n";
    
    $montoTotal = 0;
    foreach ($descuentos100 as $desc) {
        printf("%-12s %-10d %-8s $%-11.2f $%-11.2f %-8.1f%% %-8s %-8s\n",
            $desc->fecha,
            $desc->ticket_id,
            $desc->terminal_id,
            $desc->total_price,
            $desc->descuento,
            $desc->porcentaje,
            $desc->paid ? 'SÍ' : 'NO',
            $desc->voided ? 'SÍ' : 'NO'
        );
        $montoTotal += $desc->total_price;
    }
    echo str_repeat("─", 100) . "\n";
    echo "Total de tickets con descuento 100%: " . count($descuentos100) . " | Monto afectado: $" . number_format($montoTotal, 2) . "\n\n";
} else {
    echo "✓ No se encontraron tickets con descuento del 100%\n\n";
}

// ───────────────────────────────────────────────────────────────────────────────
// 3. TICKETS NO PAGADOS PERO CERRADOS
// ───────────────────────────────────────────────────────────────────────────────
echo "3. TICKETS NO PAGADOS PERO CERRADOS (POTENCIAL PÉRDIDA)\n";
echo str_repeat("─", 100) . "\n";

$noPagados = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id AS ticket_id,
        t.terminal_id,
        t.total_price,
        COALESCE(t.total_discount, 0) AS descuento,
        t.total_price - COALESCE(t.total_discount, 0) AS neto,
        (SELECT COUNT(*) FROM public.transactions tx WHERE tx.ticket_id = t.id) AS num_tx
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
      AND t.paid = FALSE
      AND t.voided = FALSE
      AND t.total_price > 0
    ORDER BY fecha, t.total_price DESC
    LIMIT 50
");

if (count($noPagados) > 0) {
    printf("%-12s %-10s %-8s %-12s %-12s %-12s %-8s\n",
        "Fecha", "Ticket", "Term", "Total", "Descuento", "Neto", "#Tx");
    echo str_repeat("─", 100) . "\n";
    
    $montoTotalNoPagado = 0;
    foreach ($noPagados as $np) {
        printf("%-12s %-10d %-8s $%-11.2f $%-11.2f $%-11.2f %-8d\n",
            $np->fecha,
            $np->ticket_id,
            $np->terminal_id,
            $np->total_price,
            $np->descuento,
            $np->neto,
            $np->num_tx
        );
        $montoTotalNoPagado += $np->neto;
    }
    echo str_repeat("─", 100) . "\n";
    echo "Total de tickets no pagados: " . count($noPagados) . " | Monto no cobrado: $" . number_format($montoTotalNoPagado, 2) . "\n\n";
} else {
    echo "✓ No se encontraron tickets no pagados\n\n";
}

// ───────────────────────────────────────────────────────────────────────────────
// 4. PAYMENT VS NET MISMATCH
// ───────────────────────────────────────────────────────────────────────────────
echo "4. DISCREPANCIAS ENTRE TOTAL NETO Y PAGOS RECIBIDOS\n";
echo str_repeat("─", 100) . "\n";

$paymentMismatch = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id AS ticket_id,
        t.total_price,
        COALESCE(t.total_discount, 0) AS descuento,
        t.total_price - COALESCE(t.total_discount, 0) AS neto,
        COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                          AND tx.transaction_type = 'CREDIT'
                                          AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0) AS pagado,
        (t.total_price - COALESCE(t.total_discount, 0)) - 
            COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                              AND tx.transaction_type = 'CREDIT'
                                              AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0) AS diferencia
    FROM public.ticket t
    LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
      AND t.paid = TRUE
      AND t.voided = FALSE
    GROUP BY t.id, t.folio_date, t.closing_date, t.create_date, t.total_price, t.total_discount
    HAVING ABS((t.total_price - COALESCE(t.total_discount, 0)) - 
               COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                                 AND tx.transaction_type = 'CREDIT'
                                                 AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0)) > 0.01
    ORDER BY ABS(diferencia) DESC
    LIMIT 50
");

if (count($paymentMismatch) > 0) {
    printf("%-12s %-10s %-12s %-12s %-12s %-12s %-12s\n",
        "Fecha", "Ticket", "Total", "Descuento", "Neto", "Pagado", "Diferencia");
    echo str_repeat("─", 100) . "\n";
    
    foreach ($paymentMismatch as $pm) {
        $status = abs($pm->diferencia) > 10 ? '⚠️' : '⚡';
        printf("%s %-12s %-10d $%-11.2f $%-11.2f $%-11.2f $%-11.2f $%-11.2f\n",
            $status,
            $pm->fecha,
            $pm->ticket_id,
            $pm->total_price,
            $pm->descuento,
            $pm->neto,
            $pm->pagado,
            $pm->diferencia
        );
    }
    echo str_repeat("─", 100) . "\n";
    echo "Total de tickets con discrepancia: " . count($paymentMismatch) . "\n\n";
} else {
    echo "✓ No se encontraron discrepancias entre neto y pagos\n\n";
}

// ───────────────────────────────────────────────────────────────────────────────
// 5. RESUMEN DE EXCEPCIONES POR DÍA
// ───────────────────────────────────────────────────────────────────────────────
echo "5. RESUMEN DIARIO DE TIPOS DE EXCEPCIONES\n";
echo str_repeat("─", 100) . "\n";

$resumenDiario = DB::select("
    SELECT 
        fecha,
        COUNT(*) FILTER (WHERE descuento_100) AS desc_100,
        COUNT(*) FILTER (WHERE no_pagado) AS no_pagados,
        COUNT(*) FILTER (WHERE anulado_con_tx) AS anulados_con_tx,
        SUM(total_price) FILTER (WHERE descuento_100) AS monto_desc_100,
        SUM(neto) FILTER (WHERE no_pagado) AS monto_no_pagado
    FROM (
        SELECT 
            COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
            t.total_price,
            t.total_price - COALESCE(t.total_discount, 0) AS neto,
            (t.total_price > 0 AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99) AS descuento_100,
            (t.paid = FALSE AND t.voided = FALSE AND t.total_price > 0) AS no_pagado,
            (t.voided = TRUE AND EXISTS(SELECT 1 FROM transactions tx WHERE tx.ticket_id = t.id)) AS anulado_con_tx
        FROM public.ticket t
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
          AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
    ) sub
    GROUP BY fecha
    HAVING COUNT(*) FILTER (WHERE descuento_100) > 0
        OR COUNT(*) FILTER (WHERE no_pagado) > 0
        OR COUNT(*) FILTER (WHERE anulado_con_tx) > 0
    ORDER BY fecha
");

if (count($resumenDiario) > 0) {
    printf("%-12s %-10s %-10s %-15s %-15s %-15s\n",
        "Fecha", "Desc 100%", "No Pagados", "Anul+Tx", "$ Desc 100%", "$ No Pagado");
    echo str_repeat("─", 100) . "\n";
    
    foreach ($resumenDiario as $rd) {
        printf("%-12s %-10d %-10d %-15d $%-14.2f $%-14.2f\n",
            $rd->fecha,
            $rd->desc_100,
            $rd->no_pagados,
            $rd->anulados_con_tx,
            $rd->monto_desc_100 ?? 0,
            $rd->monto_no_pagado ?? 0
        );
    }
} else {
    echo "✓ No se encontraron excepciones en el período\n";
}

echo "\n═══════════════════════════════════════════════════════════════════════════════════\n";
echo "Análisis completado. Revisar hallazgos para identificar patrones.\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
