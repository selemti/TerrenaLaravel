<?php

/**
 * ANÁLISIS EXHAUSTIVO DE DISCREPANCIAS - 1 DE OCTUBRE 2025
 *
 * Basado en el Drawer Pull Report ID: 92
 * Usuario: Jose Eumir Rodriguez Rranco
 * Terminal: 101
 */

require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "     ANÁLISIS PROFUNDO DE DISCREPANCIAS - 1 DE OCTUBRE 2025                       \n";
echo "     Drawer Pull Report ID: 92 | Terminal: 101                                    \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$fecha = '2025-10-01';
$terminal = 101;

// ═══════════════════════════════════════════════════════════════════════════════
// 1. VALIDAR DRAWER PULL REPORT
// ═══════════════════════════════════════════════════════════════════════════════
echo "📋 1. DRAWER PULL REPORT - VALORES REPORTADOS\n";
echo str_repeat('─', 90)."\n";

$drawerReport = DB::select('
    SELECT 
        id,
        ticket_count,
        net_sales,
        cash_receipt_amount,
        total_revenue,
        terminal_id,
        report_time::date as fecha,
        user_id,
        cash_to_deposit,
        variance,
        totaldiscountcount,
        totaldiscountamount
    FROM public.drawer_pull_report
    WHERE report_time::date = ?
      AND terminal_id = ?
    LIMIT 1
', [$fecha, $terminal]);

if (empty($drawerReport)) {
    echo "⚠️  NO SE ENCONTRÓ DRAWER PULL REPORT PARA ESTA FECHA/TERMINAL\n\n";
    echo "Buscando reportes disponibles para esta fecha...\n";

    $available = DB::select('
        SELECT id, terminal_id, report_time, ticket_count, net_sales
        FROM public.drawer_pull_report
        WHERE report_time::date = ?
    ', [$fecha]);

    if (! empty($available)) {
        echo "\nReportes encontrados:\n";
        foreach ($available as $r) {
            printf("  ID: %d | Terminal: %s | Hora: %s | Tickets: %d | Ventas: $%.2f\n",
                $r->id, $r->terminal_id, $r->report_time, $r->ticket_count, $r->net_sales);
        }
    } else {
        echo "\n❌ NO HAY DRAWER PULL REPORTS para el 1 de octubre\n";
    }
    echo "\n";
} else {
    $report = $drawerReport[0];
    printf("ID Reporte:         %d\n", $report->id);
    printf("Terminal:           %s\n", $report->terminal_id);
    printf("Fecha:              %s\n", $report->fecha);
    printf("User ID:            %d\n", $report->user_id);
    printf("Tickets Reportados: %d\n", $report->ticket_count);
    printf("Ventas Netas:       $%.2f\n", $report->net_sales);
    printf("Efectivo Recibos:   $%.2f\n", $report->cash_receipt_amount);
    printf("Ingresos Totales:   $%.2f\n", $report->total_revenue);
    printf("Efectivo a Depositar: $%.2f\n", $report->cash_to_deposit);
    printf("Varianza:           $%.2f\n", $report->variance);
    printf("Total Descuentos:   $%.2f (%d tickets)\n\n",
        $report->totaldiscountamount, $report->totaldiscountcount);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. CALCULAR VALORES REALES DESDE TICKETS
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 2. VALORES REALES CALCULADOS DESDE TICKETS\n";
echo str_repeat('─', 90)."\n";

$realData = DB::select("
    SELECT 
        COUNT(DISTINCT t.id) AS total_tickets,
        COUNT(DISTINCT t.id) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_pagados,
        COUNT(DISTINCT t.id) FILTER (WHERE t.paid = FALSE AND t.voided = FALSE) AS tickets_no_pagados,
        COUNT(DISTINCT t.id) FILTER (WHERE t.voided = TRUE) AS tickets_anulados,
        
        -- Ventas brutas
        ROUND(COALESCE(SUM(t.total_price) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0)::numeric, 2) AS ventas_brutas,
        
        -- Descuentos
        ROUND(COALESCE(SUM(t.total_discount) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0)::numeric, 2) AS total_descuentos,
        
        -- Ventas netas
        ROUND(COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)) 
            FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0)::numeric, 2) AS ventas_netas,
        
        -- Efectivo en transacciones
        ROUND(COALESCE(SUM(tx.amount) FILTER (
            WHERE tx.payment_type = 'CASH' 
              AND tx.voided = FALSE 
              AND tx.transaction_type = 'CREDIT'
              AND t.paid = TRUE 
              AND t.voided = FALSE
        ), 0)::numeric, 2) AS efectivo_real
        
    FROM public.ticket t
    LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
      AND t.terminal_id = ?
", [$fecha, $terminal]);

if (! empty($realData)) {
    $real = $realData[0];
    printf("Total Tickets:           %d\n", $real->total_tickets);
    printf("  - Pagados:             %d\n", $real->tickets_pagados);
    printf("  - No Pagados:          %d\n", $real->tickets_no_pagados);
    printf("  - Anulados:            %d\n", $real->tickets_anulados);
    printf("Ventas Brutas:           $%.2f\n", $real->ventas_brutas);
    printf("Total Descuentos:        $%.2f\n", $real->total_descuentos);
    printf("Ventas Netas (Real):     $%.2f\n", $real->ventas_netas);
    printf("Efectivo Real:           $%.2f\n\n", $real->efectivo_real);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. CALCULAR DISCREPANCIAS
// ═══════════════════════════════════════════════════════════════════════════════
if (! empty($drawerReport) && ! empty($realData)) {
    echo "⚠️  3. DISCREPANCIAS DETECTADAS\n";
    echo str_repeat('─', 90)."\n";

    $diffTickets = $report->ticket_count - $real->tickets_pagados;
    $diffVentas = $report->net_sales - $real->ventas_netas;
    $diffEfectivo = $report->cash_receipt_amount - $real->efectivo_real;

    printf("%-30s %10s %10s %10s\n", 'Concepto', 'Reportado', 'Real', 'Diferencia');
    echo str_repeat('─', 90)."\n";
    printf("%-30s %10d %10d %10d %s\n",
        'Tickets',
        $report->ticket_count,
        $real->tickets_pagados,
        $diffTickets,
        abs($diffTickets) > 0 ? '⚠️' : '✓'
    );
    printf("%-30s %10.2f %10.2f %10.2f %s\n",
        'Ventas Netas',
        $report->net_sales,
        $real->ventas_netas,
        $diffVentas,
        abs($diffVentas) > 1 ? '⚠️' : '✓'
    );
    printf("%-30s %10.2f %10.2f %10.2f %s\n",
        'Efectivo',
        $report->cash_receipt_amount,
        $real->efectivo_real,
        $diffEfectivo,
        abs($diffEfectivo) > 1 ? '⚠️' : '✓'
    );
    echo "\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. TICKETS CON DESCUENTO DEL 100% (CRÍTICO)
// ═══════════════════════════════════════════════════════════════════════════════
echo "🎁 4. TICKETS CON DESCUENTO DEL 100%\n";
echo str_repeat('─', 90)."\n";

$desc100 = DB::select("
    SELECT 
        t.id,
        t.total_price,
        COALESCE(t.total_discount, 0) AS descuento,
        t.paid,
        t.voided,
        t.create_date,
        t.closing_date,
        (SELECT STRING_AGG(ti.item_name || ' ($' || ti.total_price || ')', ', ')
         FROM public.ticket_item ti
         WHERE ti.ticket_id = t.id) AS items
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
      AND t.terminal_id = ?
      AND t.total_price > 0
      AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99
    ORDER BY t.id
", [$fecha, $terminal]);

if (! empty($desc100)) {
    foreach ($desc100 as $t) {
        printf("Ticket ID: %d\n", $t->id);
        printf("  Total:     $%.2f\n", $t->total_price);
        printf("  Descuento: $%.2f (%.1f%%)\n", $t->descuento, ($t->descuento / $t->total_price * 100));
        printf("  Pagado:    %s\n", $t->paid ? 'SÍ' : 'NO');
        printf("  Anulado:   %s\n", $t->voided ? 'SÍ' : 'NO');
        printf("  Creado:    %s\n", $t->create_date);
        printf("  Cerrado:   %s\n", $t->closing_date ?? 'N/A');
        printf("  Items:     %s\n", substr($t->items ?? 'N/A', 0, 70));
        echo "\n";
    }
} else {
    echo "✓ No se encontraron tickets con descuento del 100%\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. TICKETS NO PAGADOS
// ═══════════════════════════════════════════════════════════════════════════════
echo "💰 5. TICKETS NO PAGADOS (paid = FALSE)\n";
echo str_repeat('─', 90)."\n";

$noPagados = DB::select("
    SELECT 
        t.id,
        t.total_price,
        COALESCE(t.total_discount, 0) AS descuento,
        t.total_price - COALESCE(t.total_discount, 0) AS neto,
        t.voided,
        t.closing_date IS NOT NULL AS cerrado,
        (SELECT STRING_AGG(ti.item_name, ', ')
         FROM public.ticket_item ti
         WHERE ti.ticket_id = t.id
         LIMIT 3) AS items
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
      AND t.terminal_id = ?
      AND t.paid = FALSE
      AND t.voided = FALSE
    ORDER BY t.total_price DESC
", [$fecha, $terminal]);

if (! empty($noPagados)) {
    printf("%-10s %-10s %-10s %-10s %-8s %s\n", 'Ticket', 'Total', 'Desc', 'Neto', 'Cerrado', 'Items');
    echo str_repeat('─', 90)."\n";

    $totalNoPagado = 0;
    foreach ($noPagados as $t) {
        printf("%-10d $%-9.2f $%-9.2f $%-9.2f %-8s %s\n",
            $t->id,
            $t->total_price,
            $t->descuento,
            $t->neto,
            $t->cerrado ? 'SÍ' : 'NO',
            substr($t->items ?? 'N/A', 0, 30)
        );
        $totalNoPagado += $t->neto;
    }
    echo str_repeat('─', 90)."\n";
    printf("Total: %d tickets | Monto no cobrado: $%.2f\n\n", count($noPagados), $totalNoPagado);
} else {
    echo "✓ Todos los tickets fueron pagados\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. TICKETS ANULADOS CON TRANSACCIONES
// ═══════════════════════════════════════════════════════════════════════════════
echo "🔄 6. TICKETS ANULADOS CON TRANSACCIONES\n";
echo str_repeat('─', 90)."\n";

$anulados = DB::select("
    SELECT 
        t.id,
        t.total_price,
        COUNT(tx.id) AS num_tx,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'CASH'), 0)::numeric, 2) AS cash,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'REFUND'), 0)::numeric, 2) AS refund,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'VOID_TRANS'), 0)::numeric, 2) AS void_trans,
        STRING_AGG(DISTINCT tx.payment_type || '($' || tx.amount || ')', ', ') AS detalle
    FROM public.ticket t
    INNER JOIN public.transactions tx ON tx.ticket_id = t.id
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
      AND t.terminal_id = ?
      AND t.voided = TRUE
    GROUP BY t.id, t.total_price
    ORDER BY t.id
", [$fecha, $terminal]);

if (! empty($anulados)) {
    printf("%-10s %-10s %-6s %-10s %-10s %-10s\n", 'Ticket', 'Total', '#Tx', 'Cash', 'Refund', 'Void');
    echo str_repeat('─', 90)."\n";

    foreach ($anulados as $t) {
        printf("%-10d $%-9.2f %-6d $%-9.2f $%-9.2f $%-9.2f\n",
            $t->id, $t->total_price, $t->num_tx, $t->cash, $t->refund, $t->void_trans
        );
    }
    echo str_repeat('─', 90)."\n";
    printf("Total: %d tickets anulados\n\n", count($anulados));
} else {
    echo "✓ No hay tickets anulados con transacciones\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. DISCREPANCIAS: TOTAL NETO ≠ TOTAL PAGADO
// ═══════════════════════════════════════════════════════════════════════════════
echo "⚡ 7. PAYMENT VS NET MISMATCH (Tickets con diferencias > $0.50)\n";
echo str_repeat('─', 90)."\n";

$mismatch = DB::select("
    WITH ticket_payments AS (
        SELECT 
            t.id,
            t.total_price,
            COALESCE(t.total_discount, 0) AS descuento,
            t.total_price - COALESCE(t.total_discount, 0) AS neto,
            COALESCE(SUM(tx.amount) FILTER (
                WHERE tx.voided = FALSE 
                  AND tx.transaction_type = 'CREDIT'
                  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')
            ), 0) AS pagado
        FROM public.ticket t
        LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
          AND t.terminal_id = ?
          AND t.paid = TRUE
          AND t.voided = FALSE
        GROUP BY t.id, t.total_price, t.total_discount
    )
    SELECT 
        id,
        ROUND(total_price::numeric, 2) AS total,
        ROUND(descuento::numeric, 2) AS descuento,
        ROUND(neto::numeric, 2) AS neto,
        ROUND(pagado::numeric, 2) AS pagado,
        ROUND((neto - pagado)::numeric, 2) AS diferencia
    FROM ticket_payments
    WHERE ABS(neto - pagado) > 0.50
    ORDER BY ABS(neto - pagado) DESC
", [$fecha, $terminal]);

if (! empty($mismatch)) {
    printf("%-10s %-10s %-10s %-10s %-10s %-10s\n",
        'Ticket', 'Total', 'Desc', 'Neto', 'Pagado', 'Diferencia');
    echo str_repeat('─', 90)."\n";

    $totalDiff = 0;
    foreach ($mismatch as $t) {
        $alert = abs($t->diferencia) > 10 ? '⚠️ ' : '⚡ ';
        printf("%s%-10d $%-9.2f $%-9.2f $%-9.2f $%-9.2f $%-9.2f\n",
            $alert, $t->id, $t->total, $t->descuento, $t->neto, $t->pagado, $t->diferencia
        );
        $totalDiff += abs($t->diferencia);
    }
    echo str_repeat('─', 90)."\n";
    printf("Total: %d tickets | Diferencia acumulada: $%.2f\n\n", count($mismatch), $totalDiff);
} else {
    echo "✓ Todos los tickets tienen pagos correctos\n\n";
}

echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "Análisis completado\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
