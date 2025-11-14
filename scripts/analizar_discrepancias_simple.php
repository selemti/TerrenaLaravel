<?php

/**
 * Análisis Simplificado de Discrepancias en Ventas
 * Enfocado en los tickets y transacciones directamente
 */

require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "    ANÁLISIS DE DISCREPANCIAS EN TICKETS - OCTUBRE 2025 (1-31)                     \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$fechaInicio = '2025-10-01';
$fechaFin = '2025-11-01';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. TICKETS CON DESCUENTO DEL 100%
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 1. TICKETS CON DESCUENTO DEL 100%\n";
echo str_repeat('─', 90)."\n";

$desc100 = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id,
        t.terminal_id,
        ROUND(t.total_price::numeric, 2) AS total,
        ROUND(COALESCE(t.total_discount, 0)::numeric, 2) AS descuento,
        t.paid,
        t.voided,
        (SELECT STRING_AGG(ti.item_name, ', ') 
         FROM public.ticket_item ti 
         WHERE ti.ticket_id = t.id 
         LIMIT 5) AS items
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= ?
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < ?
      AND t.total_price > 0
      AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99
    ORDER BY fecha, t.total_price DESC
", [$fechaInicio, $fechaFin]);

if (count($desc100) > 0) {
    printf("%-12s %-8s %-8s %-10s %-10s %-6s %-6s %s\n",
        'Fecha', 'Ticket', 'Term', 'Total', 'Desc', 'Pago', 'Anul', 'Items');
    echo str_repeat('─', 90)."\n";

    $totalAfectado = 0;
    foreach ($desc100 as $t) {
        $items = substr($t->items ?? 'N/A', 0, 30);
        printf("%-12s %-8d %-8s $%-9.2f $%-9.2f %-6s %-6s %s\n",
            $t->fecha,
            $t->id,
            $t->terminal_id,
            $t->total,
            $t->descuento,
            $t->paid ? 'SÍ' : 'NO',
            $t->voided ? 'SÍ' : 'NO',
            $items
        );
        $totalAfectado += $t->total;
    }
    echo str_repeat('─', 90)."\n";
    echo 'Total: '.count($desc100).' tickets | Monto total: $'.number_format($totalAfectado, 2)."\n\n";
} else {
    echo "✓ No se encontraron tickets con descuento del 100%\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. TICKETS NO PAGADOS (PAID = FALSE) CON MONTO > 0
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 2. TICKETS NO PAGADOS (PÉRDIDA POTENCIAL)\n";
echo str_repeat('─', 90)."\n";

$noPagados = DB::select('
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id,
        t.terminal_id,
        ROUND(t.total_price::numeric, 2) AS total,
        ROUND(COALESCE(t.total_discount, 0)::numeric, 2) AS descuento,
        ROUND((t.total_price - COALESCE(t.total_discount, 0))::numeric, 2) AS neto,
        t.voided,
        t.closing_date IS NOT NULL AS cerrado
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= ?
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < ?
      AND t.paid = FALSE
      AND t.voided = FALSE
      AND t.total_price > 0
    ORDER BY t.total_price DESC
    LIMIT 30
', [$fechaInicio, $fechaFin]);

if (count($noPagados) > 0) {
    printf("%-12s %-8s %-8s %-10s %-10s %-10s %-8s\n",
        'Fecha', 'Ticket', 'Term', 'Total', 'Desc', 'Neto', 'Cerrado');
    echo str_repeat('─', 90)."\n";

    $montoNoPagado = 0;
    foreach ($noPagados as $t) {
        printf("%-12s %-8d %-8s $%-9.2f $%-9.2f $%-9.2f %-8s\n",
            $t->fecha,
            $t->id,
            $t->terminal_id,
            $t->total,
            $t->descuento,
            $t->neto,
            $t->cerrado ? 'SÍ' : 'NO'
        );
        $montoNoPagado += $t->neto;
    }
    echo str_repeat('─', 90)."\n";
    echo 'Total: '.count($noPagados).' tickets | Monto no cobrado: $'.number_format($montoNoPagado, 2)."\n\n";
} else {
    echo "✓ Todos los tickets fueron pagados\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. TICKETS ANULADOS CON TRANSACCIONES
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 3. TICKETS ANULADOS QUE TIENEN TRANSACCIONES\n";
echo str_repeat('─', 90)."\n";

$anuladosConTx = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id,
        t.terminal_id,
        ROUND(t.total_price::numeric, 2) AS total,
        COUNT(tx.id) AS num_tx,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'CASH'), 0)::numeric, 2) AS cash,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'REFUND'), 0)::numeric, 2) AS refund,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'VOID_TRANS'), 0)::numeric, 2) AS void_trans
    FROM public.ticket t
    INNER JOIN public.transactions tx ON tx.ticket_id = t.id
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= ?
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < ?
      AND t.voided = TRUE
    GROUP BY t.id, t.folio_date, t.closing_date, t.create_date, t.terminal_id, t.total_price
    ORDER BY COUNT(tx.id) DESC
    LIMIT 20
", [$fechaInicio, $fechaFin]);

if (count($anuladosConTx) > 0) {
    printf("%-12s %-8s %-8s %-10s %-6s %-10s %-10s %-10s\n",
        'Fecha', 'Ticket', 'Term', 'Total', '#Tx', 'Cash', 'Refund', 'Void');
    echo str_repeat('─', 90)."\n";

    foreach ($anuladosConTx as $t) {
        printf("%-12s %-8d %-8s $%-9.2f %-6d $%-9.2f $%-9.2f $%-9.2f\n",
            $t->fecha,
            $t->id,
            $t->terminal_id,
            $t->total,
            $t->num_tx,
            $t->cash,
            $t->refund,
            $t->void_trans
        );
    }
    echo str_repeat('─', 90)."\n";
    echo 'Total: '.count($anuladosConTx)." tickets anulados con transacciones\n\n";
} else {
    echo "✓ No hay tickets anulados con transacciones\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. DISCREPANCIAS: PAGOS NO COINCIDEN CON TOTAL NETO
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 4. DISCREPANCIAS: TOTAL NETO ≠ TOTAL PAGADO\n";
echo str_repeat('─', 90)."\n";

$discrepancias = DB::select("
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.id,
        t.terminal_id,
        ROUND(t.total_price::numeric, 2) AS total,
        ROUND(COALESCE(t.total_discount, 0)::numeric, 2) AS descuento,
        ROUND((t.total_price - COALESCE(t.total_discount, 0))::numeric, 2) AS neto,
        ROUND(COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                                AND tx.transaction_type = 'CREDIT'
                                                AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0)::numeric, 2) AS pagado,
        ROUND(((t.total_price - COALESCE(t.total_discount, 0)) - 
              COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                                AND tx.transaction_type = 'CREDIT'
                                                AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0))::numeric, 2) AS diferencia
    FROM public.ticket t
    LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= ?
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < ?
      AND t.paid = TRUE
      AND t.voided = FALSE
    GROUP BY t.id, t.folio_date, t.closing_date, t.create_date, t.terminal_id, t.total_price, t.total_discount
    HAVING ABS((t.total_price - COALESCE(t.total_discount, 0)) - 
               COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                                 AND tx.transaction_type = 'CREDIT'
                                                 AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0)) > 0.50
    ORDER BY ABS(diferencia) DESC
    LIMIT 30
", [$fechaInicio, $fechaFin]);

if (count($discrepancias) > 0) {
    printf("%-12s %-8s %-8s %-10s %-10s %-10s %-10s %-10s\n",
        'Fecha', 'Ticket', 'Term', 'Total', 'Desc', 'Neto', 'Pagado', 'Diferencia');
    echo str_repeat('─', 90)."\n";

    $totalDiff = 0;
    foreach ($discrepancias as $t) {
        $alert = abs($t->diferencia) > 10 ? '⚠️ ' : '⚡ ';
        printf("%s%-12s %-8d %-8s $%-9.2f $%-9.2f $%-9.2f $%-9.2f $%-9.2f\n",
            $alert,
            $t->fecha,
            $t->id,
            $t->terminal_id,
            $t->total,
            $t->descuento,
            $t->neto,
            $t->pagado,
            $t->diferencia
        );
        $totalDiff += abs($t->diferencia);
    }
    echo str_repeat('─', 90)."\n";
    echo 'Total: '.count($discrepancias).' tickets | Diferencia acumulada: $'.number_format($totalDiff, 2)."\n\n";
} else {
    echo "✓ Todos los tickets tienen pagos correctos\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. RESUMEN CONSOLIDADO POR FECHA
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 5. RESUMEN CONSOLIDADO POR FECHA\n";
echo str_repeat('─', 90)."\n";

$resumen = DB::select('
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        COUNT(*) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_pagados,
        COUNT(*) FILTER (WHERE t.paid = FALSE AND t.voided = FALSE) AS tickets_no_pagados,
        COUNT(*) FILTER (WHERE t.voided = TRUE) AS tickets_anulados,
        COUNT(*) FILTER (WHERE COALESCE(t.total_discount, 0) >= t.total_price * 0.99 AND t.total_price > 0) AS desc_100pct,
        ROUND(SUM(t.total_price - COALESCE(t.total_discount, 0)) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE)::numeric, 2) AS ventas_netas,
        ROUND(SUM(t.total_price - COALESCE(t.total_discount, 0)) FILTER (WHERE t.paid = FALSE)::numeric, 2) AS monto_no_cobrado
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= ?
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < ?
    GROUP BY COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
    ORDER BY fecha
', [$fechaInicio, $fechaFin]);

if (count($resumen) > 0) {
    printf("%-12s %-10s %-12s %-10s %-10s %-15s %-15s\n",
        'Fecha', 'Pagados', 'No Pagados', 'Anulados', 'Desc100%', 'Ventas Netas', 'No Cobrado');
    echo str_repeat('─', 110)."\n";

    $totalVentas = 0;
    $totalNoCobrado = 0;
    $totalPagados = 0;

    foreach ($resumen as $r) {
        printf("%-12s %-10d %-12d %-10d %-10d $%-14.2f $%-14.2f\n",
            $r->fecha,
            $r->tickets_pagados,
            $r->tickets_no_pagados,
            $r->tickets_anulados,
            $r->desc_100pct,
            $r->ventas_netas ?? 0,
            $r->monto_no_cobrado ?? 0
        );
        $totalVentas += ($r->ventas_netas ?? 0);
        $totalNoCobrado += ($r->monto_no_cobrado ?? 0);
        $totalPagados += $r->tickets_pagados;
    }
    echo str_repeat('─', 110)."\n";
    echo "TOTAL: Tickets pagados: $totalPagados | Ventas: $".number_format($totalVentas, 2).
         ' | No cobrado: $'.number_format($totalNoCobrado, 2)."\n\n";
}

echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "Análisis completado\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
