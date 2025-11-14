<?php

/**
 * ANÁLISIS FORENSE COMPLETO - AGOSTO A OCTUBRE 2025
 *
 * Análisis profundo de tickets, transacciones, descuentos, anulaciones
 * para identificar EXACTAMENTE cuál es el problema con las discrepancias
 */

require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "     ANÁLISIS FORENSE DE TICKETS - AGOSTO A OCTUBRE 2025                           \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$fechaInicio = '2025-08-01';
$fechaFin = '2025-10-31';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. RESUMEN GENERAL POR MES
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 1. RESUMEN GENERAL POR MES\n";
echo str_repeat('─', 120)."\n";

$resumenMensual = DB::select("
    SELECT 
        TO_CHAR(COALESCE(t.folio_date, t.closing_date::date, t.create_date::date), 'YYYY-MM') AS mes,
        COUNT(*) AS total_tickets,
        COUNT(*) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_pagados,
        COUNT(*) FILTER (WHERE t.paid = FALSE AND t.voided = FALSE) AS tickets_no_pagados,
        COUNT(*) FILTER (WHERE t.voided = TRUE) AS tickets_anulados,
        COUNT(*) FILTER (WHERE t.closing_date IS NULL) AS tickets_abiertos,
        ROUND(SUM(t.total_price)::numeric, 2) AS total_bruto,
        ROUND(SUM(COALESCE(t.total_discount, 0))::numeric, 2) AS total_descuentos,
        ROUND(SUM(t.total_price - COALESCE(t.total_discount, 0))::numeric, 2) AS total_neto
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
    GROUP BY TO_CHAR(COALESCE(t.folio_date, t.closing_date::date, t.create_date::date), 'YYYY-MM')
    ORDER BY mes
", [$fechaInicio, $fechaFin]);

printf("%-10s | %-7s | %-7s | %-9s | %-8s | %-8s | %-12s | %-13s | %-12s\n",
    'Mes', 'Total', 'Pagados', 'No Pagados', 'Anulados', 'Abiertos', 'Bruto', 'Descuentos', 'Neto');
echo str_repeat('─', 120)."\n";

foreach ($resumenMensual as $mes) {
    printf("%-10s | %-7d | %-7d | %-9d | %-8d | %-8d | $%-11.2f | $%-12.2f | $%-11.2f\n",
        $mes->mes, $mes->total_tickets, $mes->tickets_pagados, $mes->tickets_no_pagados,
        $mes->tickets_anulados, $mes->tickets_abiertos, $mes->total_bruto,
        $mes->total_descuentos, $mes->total_neto
    );
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 2. ANÁLISIS DE DESCUENTOS (TU OBSERVACIÓN SOBRE 100%)
// ═══════════════════════════════════════════════════════════════════════════════
echo "🔍 2. ANÁLISIS DETALLADO DE DESCUENTOS 100%\n";
echo str_repeat('─', 120)."\n";

$descuentos100 = DB::select("
    SELECT 
        TO_CHAR(COALESCE(t.folio_date, t.closing_date::date, t.create_date::date), 'YYYY-MM') AS mes,
        COUNT(*) AS cantidad,
        COUNT(*) FILTER (WHERE t.paid = TRUE) AS pagados,
        COUNT(*) FILTER (WHERE t.paid = FALSE AND t.voided = FALSE) AS no_pagados,
        COUNT(*) FILTER (WHERE t.voided = TRUE) AS anulados,
        COUNT(*) FILTER (WHERE t.closing_date IS NULL) AS abiertos,
        ROUND(SUM(t.total_price)::numeric, 2) AS total_price_sum,
        ROUND(SUM(t.total_discount)::numeric, 2) AS total_discount_sum,
        ROUND(AVG(t.total_price)::numeric, 2) AS avg_total_price,
        ROUND(AVG(t.total_discount)::numeric, 2) AS avg_total_discount
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
      AND t.total_price > 0
      AND t.total_discount >= t.total_price * 0.99
    GROUP BY TO_CHAR(COALESCE(t.folio_date, t.closing_date::date, t.create_date::date), 'YYYY-MM')
    ORDER BY mes
", [$fechaInicio, $fechaFin]);

echo "🎯 TICKETS CON DESCUENTO DEL 100% (o casi):\n\n";

if (! empty($descuentos100)) {
    printf("%-10s | %-8s | %-7s | %-9s | %-8s | %-8s | %-12s | %-13s\n",
        'Mes', 'Cantidad', 'Pagados', 'No Pagados', 'Anulados', 'Abiertos', 'Suma Total', 'Suma Desc');
    echo str_repeat('─', 120)."\n";

    foreach ($descuentos100 as $d) {
        printf("%-10s | %-8d | %-7d | %-9d | %-8d | %-8d | $%-11.2f | $%-12.2f %s\n",
            $d->mes, $d->cantidad, $d->pagados, $d->no_pagados,
            $d->anulados, $d->abiertos, $d->total_price_sum, $d->total_discount_sum,
            $d->no_pagados > 0 ? '⚠️' : ''
        );
    }
} else {
    echo "✅ NO HAY tickets con descuento del 100%\n";
}

echo "\n";

// Detalles de tickets con descuento 100% NO pagados
echo "📋 DETALLE DE TICKETS CON DESC 100% NO PAGADOS:\n";
echo str_repeat('─', 150)."\n";

$desc100NoPagados = DB::select("
    SELECT 
        t.id,
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.terminal_id,
        t.total_price,
        t.total_discount,
        t.paid,
        t.voided,
        t.closing_date IS NULL AS abierto,
        t.create_date,
        t.closing_date,
        (
            SELECT STRING_AGG(ti.item_name || ' ($' || ti.item_price || ')', ', ')
            FROM public.ticket_item ti
            WHERE ti.ticket_id = t.id
            LIMIT 5
        ) AS items
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
      AND t.total_price > 0
      AND t.total_discount >= t.total_price * 0.99
      AND t.paid = FALSE
      AND t.voided = FALSE
    ORDER BY fecha, t.id
    LIMIT 50
", [$fechaInicio, $fechaFin]);

if (! empty($desc100NoPagados)) {
    printf("%-8s | %-12s | %-4s | %-10s | %-10s | %-7s | %-7s | %-50s\n",
        'ID', 'Fecha', 'Term', 'Total', 'Descuento', 'Pagado', 'Abierto', 'Items');
    echo str_repeat('─', 150)."\n";

    foreach ($desc100NoPagados as $t) {
        printf("%-8d | %-12s | %-4s | $%-9.2f | $%-9.2f | %-7s | %-7s | %-50s\n",
            $t->id, $t->fecha, $t->terminal_id, $t->total_price, $t->total_discount,
            $t->paid ? 'Sí' : 'NO', $t->abierto ? 'SÍ' : 'No',
            substr($t->items, 0, 50)
        );
    }

    echo "\n⚠️ TOTAL: ".count($desc100NoPagados)." tickets con descuento 100% NO pagados\n";
} else {
    echo "✅ NO HAY tickets con descuento 100% sin pagar\n";
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 3. ANÁLISIS DE TICKETS PROBLEMÁTICOS: TU HIPÓTESIS
// ═══════════════════════════════════════════════════════════════════════════════
echo "🔬 3. VALIDACIÓN DE HIPÓTESIS: Tickets con total_discount = total_price pero total_price < monto_real_items\n";
echo str_repeat('─', 150)."\n";

$hipotesis = DB::select("
    WITH ticket_analysis AS (
        SELECT 
            t.id,
            COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
            t.terminal_id,
            t.total_price AS total_ticket,
            t.total_discount AS descuento_ticket,
            t.paid,
            t.voided,
            t.closing_date IS NULL AS abierto,
            ROUND(COALESCE(SUM(ti.item_price * ti.item_quantity), 0)::numeric, 2) AS suma_items,
            COUNT(ti.id) AS num_items
        FROM public.ticket t
        LEFT JOIN public.ticket_item ti ON ti.ticket_id = t.id
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
          AND t.total_discount > 0
        GROUP BY t.id, fecha, t.terminal_id, t.total_price, t.total_discount, 
                 t.paid, t.voided, t.closing_date
    )
    SELECT 
        *,
        (total_ticket - descuento_ticket) AS neto_calculado,
        (suma_items - total_ticket) AS diferencia_items_vs_total,
        CASE 
            WHEN descuento_ticket >= total_ticket * 0.99 AND total_ticket < suma_items * 0.5 
            THEN '🚨 TOTAL_PRICE SOSPECHOSO (debería ser mayor)'
            WHEN descuento_ticket >= total_ticket * 0.99 
            THEN '⚠️ Descuento 100%'
            WHEN ABS(suma_items - total_ticket) > 1.00 
            THEN '⚠️ Items no coinciden con total'
            ELSE 'OK'
        END AS diagnostico
    FROM ticket_analysis
    WHERE (
        (descuento_ticket >= total_ticket * 0.99 AND total_ticket < suma_items * 0.5)
        OR (descuento_ticket >= total_ticket * 0.99 AND paid = FALSE AND voided = FALSE)
    )
    ORDER BY fecha, id
    LIMIT 100
", [$fechaInicio, $fechaFin]);

if (! empty($hipotesis)) {
    echo "🎯 CASOS SOSPECHOSOS ENCONTRADOS:\n\n";

    printf("%-8s | %-12s | %-4s | %-10s | %-10s | %-10s | %-10s | %-7s | %-7s | %-50s\n",
        'ID', 'Fecha', 'Term', 'Total', 'Descuento', 'Suma Items', 'Diferencia', 'Pagado', 'Abierto', 'Diagnóstico');
    echo str_repeat('─', 150)."\n";

    $total_diferencia = 0;
    foreach ($hipotesis as $t) {
        printf("%-8d | %-12s | %-4s | $%-9.2f | $%-9.2f | $%-9.2f | $%-9.2f | %-7s | %-7s | %-50s\n",
            $t->id, $t->fecha, $t->terminal_id, $t->total_ticket, $t->descuento_ticket,
            $t->suma_items, $t->diferencia_items_vs_total,
            $t->paid ? 'Sí' : 'NO', $t->abierto ? 'SÍ' : 'No',
            $t->diagnostico
        );
        $total_diferencia += $t->diferencia_items_vs_total;
    }

    echo str_repeat('─', 150)."\n";
    echo '📊 TOTAL DIFERENCIA ACUMULADA: $'.number_format($total_diferencia, 2)."\n";
    echo '📊 TICKETS PROBLEMÁTICOS: '.count($hipotesis)."\n";
} else {
    echo "✅ NO SE ENCONTRARON casos con esta característica\n";
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 4. ANÁLISIS DE TRANSACCIONES VS TICKETS
// ═══════════════════════════════════════════════════════════════════════════════
echo "💰 4. ANÁLISIS DE PAGOS: Tickets Pagados vs Transacciones\n";
echo str_repeat('─', 120)."\n";

$pagosMismatch = DB::select("
    WITH ticket_payments AS (
        SELECT 
            t.id,
            COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
            t.terminal_id,
            t.total_price,
            t.total_discount,
            (t.total_price - COALESCE(t.total_discount, 0)) AS neto_esperado,
            COALESCE(SUM(tx.amount) FILTER (
                WHERE tx.voided = FALSE 
                  AND tx.transaction_type = 'CREDIT'
                  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')
            ), 0) AS total_pagado,
            COUNT(tx.id) FILTER (WHERE tx.voided = FALSE) AS num_transacciones,
            STRING_AGG(DISTINCT tx.payment_type, ', ') AS tipos_pago
        FROM public.ticket t
        LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
          AND t.paid = TRUE
          AND t.voided = FALSE
        GROUP BY t.id, fecha, t.terminal_id, t.total_price, t.total_discount
    )
    SELECT 
        TO_CHAR(fecha, 'YYYY-MM') AS mes,
        COUNT(*) AS tickets_con_mismatch,
        ROUND(SUM(ABS(neto_esperado - total_pagado))::numeric, 2) AS diferencia_total,
        ROUND(AVG(ABS(neto_esperado - total_pagado))::numeric, 2) AS diferencia_promedio,
        ROUND(MIN(neto_esperado - total_pagado)::numeric, 2) AS diferencia_min,
        ROUND(MAX(neto_esperado - total_pagado)::numeric, 2) AS diferencia_max
    FROM ticket_payments
    WHERE ABS(neto_esperado - total_pagado) > 0.50
    GROUP BY TO_CHAR(fecha, 'YYYY-MM')
    ORDER BY mes
", [$fechaInicio, $fechaFin]);

if (! empty($pagosMismatch)) {
    printf("%-10s | %-20s | %-15s | %-18s | %-12s | %-12s\n",
        'Mes', 'Tickets con Mismatch', 'Diff Total', 'Diff Promedio', 'Min', 'Max');
    echo str_repeat('─', 120)."\n";

    foreach ($pagosMismatch as $p) {
        printf("%-10s | %-20d | $%-14.2f | $%-17.2f | $%-11.2f | $%-11.2f\n",
            $p->mes, $p->tickets_con_mismatch, $p->diferencia_total,
            $p->diferencia_promedio, $p->diferencia_min, $p->diferencia_max
        );
    }
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 5. TICKETS ABIERTOS (SIN CERRAR)
// ═══════════════════════════════════════════════════════════════════════════════
echo "📂 5. TICKETS ABIERTOS (SIN CLOSING_DATE)\n";
echo str_repeat('─', 120)."\n";

$ticketsAbiertos = DB::select("
    SELECT 
        TO_CHAR(t.create_date::date, 'YYYY-MM') AS mes,
        COUNT(*) AS cantidad,
        ROUND(SUM(t.total_price)::numeric, 2) AS total_price_sum,
        ROUND(SUM(COALESCE(t.total_discount, 0))::numeric, 2) AS total_discount_sum,
        ROUND(SUM(t.total_price - COALESCE(t.total_discount, 0))::numeric, 2) AS neto_potencial
    FROM public.ticket t
    WHERE t.create_date::date BETWEEN ? AND ?
      AND t.closing_date IS NULL
      AND t.voided = FALSE
    GROUP BY TO_CHAR(t.create_date::date, 'YYYY-MM')
    ORDER BY mes
", [$fechaInicio, $fechaFin]);

if (! empty($ticketsAbiertos)) {
    printf("%-10s | %-10s | %-12s | %-13s | %-15s\n",
        'Mes', 'Cantidad', 'Total', 'Descuentos', 'Neto Potencial');
    echo str_repeat('─', 120)."\n";

    foreach ($ticketsAbiertos as $ta) {
        printf("%-10s | %-10d | $%-11.2f | $%-12.2f | $%-14.2f %s\n",
            $ta->mes, $ta->cantidad, $ta->total_price_sum,
            $ta->total_discount_sum, $ta->neto_potencial,
            $ta->cantidad > 10 ? '⚠️' : ''
        );
    }
} else {
    echo "✅ NO HAY tickets abiertos\n";
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 6. RESUMEN EJECUTIVO
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 6. RESUMEN EJECUTIVO Y DIAGNÓSTICO\n";
echo str_repeat('─', 120)."\n";

// Totales generales
$totales = DB::selectOne('
    SELECT 
        COUNT(*) AS total_tickets,
        COUNT(*) FILTER (WHERE paid = TRUE AND voided = FALSE) AS pagados,
        COUNT(*) FILTER (WHERE paid = FALSE AND voided = FALSE AND closing_date IS NOT NULL) AS cerrados_no_pagados,
        COUNT(*) FILTER (WHERE closing_date IS NULL) AS abiertos,
        ROUND(SUM(total_price)::numeric, 2) AS suma_total_price,
        ROUND(SUM(total_discount)::numeric, 2) AS suma_total_discount
    FROM public.ticket
    WHERE COALESCE(folio_date, closing_date::date, create_date::date) BETWEEN ? AND ?
', [$fechaInicio, $fechaFin]);

echo "PERÍODO: $fechaInicio a $fechaFin\n\n";
echo 'Total Tickets:               '.number_format($totales->total_tickets)."\n";
echo 'Tickets Pagados:             '.number_format($totales->pagados)."\n";
echo 'Cerrados NO Pagados:         '.number_format($totales->cerrados_no_pagados)." ⚠️\n";
echo 'Tickets Abiertos:            '.number_format($totales->abiertos)." ⚠️\n";
echo 'Suma Total Price:            $'.number_format($totales->suma_total_price, 2)."\n";
echo 'Suma Total Discount:         $'.number_format($totales->suma_total_discount, 2)."\n";

echo "\n═══════════════════════════════════════════════════════════════════════════════════\n";
echo "Análisis forense completado\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
