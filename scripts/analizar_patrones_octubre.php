<?php

/**
 * ANÁLISIS DE PATRONES - MÚLTIPLES FECHAS
 * 
 * Este script analiza todo el mes de octubre 2025 para identificar patrones
 * en las discrepancias entre Drawer Pull Reports y datos reales
 */

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "     ANÁLISIS DE PATRONES - OCTUBRE 2025 (Múltiples Fechas)                       \n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";

$fechaInicio = '2025-10-01';
$fechaFin = '2025-10-31';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. OBTENER TODAS LAS FECHAS CON DRAWER PULL REPORTS
// ═══════════════════════════════════════════════════════════════════════════════
echo "📋 1. DRAWER PULL REPORTS DISPONIBLES\n";
echo str_repeat("─", 90) . "\n";

$reports = DB::select("
    SELECT 
        report_time::date as fecha,
        terminal_id,
        COUNT(*) as num_reportes,
        SUM(ticket_count) as total_tickets,
        ROUND(SUM(net_sales)::numeric, 2) as total_ventas,
        ROUND(SUM(totaldiscountamount)::numeric, 2) as total_descuentos
    FROM public.drawer_pull_report
    WHERE report_time::date BETWEEN ? AND ?
    GROUP BY report_time::date, terminal_id
    ORDER BY report_time::date, terminal_id
", [$fechaInicio, $fechaFin]);

if (empty($reports)) {
    echo "❌ NO HAY DRAWER PULL REPORTS en el rango de fechas\n\n";
    exit(1);
}

printf("%-12s %-10s %-10s %-12s %-15s %-15s\n", 
    "Fecha", "Terminal", "#Reportes", "Tickets", "Ventas", "Descuentos");
echo str_repeat("─", 90) . "\n";

foreach ($reports as $r) {
    printf("%-12s %-10s %-10d %-12d $%-14.2f $%-14.2f\n",
        $r->fecha, $r->terminal_id, $r->num_reportes, 
        $r->total_tickets, $r->total_ventas, $r->total_descuentos
    );
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 2. ANÁLISIS FECHA POR FECHA
// ═══════════════════════════════════════════════════════════════════════════════
echo "🔍 2. ANÁLISIS COMPARATIVO (Reportado vs Real)\n";
echo str_repeat("─", 110) . "\n";

printf("%-12s %-4s | %-10s %-10s %-8s | %-10s %-10s %-8s | %-10s %-10s\n",
    "Fecha", "Term", 
    "Tix.Rep", "Tix.Real", "Diff",
    "Vent.Rep", "Vent.Real", "Diff",
    "Desc.Rep", "Desc.Real"
);
echo str_repeat("─", 110) . "\n";

$resumen = [];

foreach ($reports as $report) {
    // Calcular valores reales
    $realData = DB::select("
        SELECT 
            COUNT(DISTINCT t.id) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_pagados,
            ROUND(COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)) 
                FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0)::numeric, 2) AS ventas_netas,
            ROUND(COALESCE(SUM(t.total_discount) 
                FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0)::numeric, 2) AS total_descuentos,
            COUNT(DISTINCT t.id) FILTER (WHERE t.paid = FALSE AND t.voided = FALSE) AS tickets_no_pagados,
            COUNT(DISTINCT t.id) FILTER (WHERE t.voided = TRUE) AS tickets_anulados
        FROM public.ticket t
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = ?
          AND t.terminal_id = ?
    ", [$report->fecha, $report->terminal_id]);
    
    if (!empty($realData)) {
        $real = $realData[0];
        
        $diffTickets = $report->total_tickets - $real->tickets_pagados;
        $diffVentas = $report->total_ventas - $real->ventas_netas;
        
        printf("%-12s %-4s | %-10d %-10d %-8d | $%-9.2f $%-9.2f %-8.2f | $%-9.2f $%-9.2f %s\n",
            $report->fecha, 
            $report->terminal_id,
            $report->total_tickets,
            $real->tickets_pagados,
            $diffTickets,
            $report->total_ventas,
            $real->ventas_netas,
            $diffVentas,
            $report->total_descuentos,
            $real->total_descuentos,
            (abs($diffVentas) > 50 || abs($diffTickets) > 3) ? '⚠️' : ''
        );
        
        // Guardar para resumen
        $resumen[] = [
            'fecha' => $report->fecha,
            'terminal' => $report->terminal_id,
            'diff_tickets' => $diffTickets,
            'diff_ventas' => $diffVentas,
            'diff_descuentos' => $report->total_descuentos - $real->total_descuentos,
            'tickets_no_pagados' => $real->tickets_no_pagados,
            'tickets_anulados' => $real->tickets_anulados,
        ];
    }
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 3. PATRONES IDENTIFICADOS
// ═══════════════════════════════════════════════════════════════════════════════
echo "📊 3. PATRONES IDENTIFICADOS\n";
echo str_repeat("─", 90) . "\n\n";

// Fechas con mayores discrepancias
echo "🚨 Fechas con Mayores Discrepancias en Ventas:\n";
usort($resumen, function($a, $b) {
    return abs($b['diff_ventas']) - abs($a['diff_ventas']);
});

$top10 = array_slice($resumen, 0, 10);
printf("%-12s %-10s %-15s %-15s %-15s\n", 
    "Fecha", "Terminal", "Diff Tickets", "Diff Ventas", "Diff Descuentos");
echo str_repeat("─", 90) . "\n";

foreach ($top10 as $item) {
    printf("%-12s %-10s %-15d $%-14.2f $%-14.2f %s\n",
        $item['fecha'],
        $item['terminal'],
        $item['diff_tickets'],
        $item['diff_ventas'],
        $item['diff_descuentos'],
        abs($item['diff_ventas']) > 200 ? '🚨' : (abs($item['diff_ventas']) > 100 ? '⚠️' : '')
    );
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 4. ANÁLISIS DE TICKETS PROBLEMÁTICOS POR TIPO
// ═══════════════════════════════════════════════════════════════════════════════
echo "🔍 4. RESUMEN DE TICKETS PROBLEMÁTICOS (TODO OCTUBRE)\n";
echo str_repeat("─", 90) . "\n";

// Tickets no pagados
$noPagados = DB::select("
    SELECT 
        COUNT(*) as total,
        ROUND(COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)), 0)::numeric, 2) as monto_total
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
      AND t.paid = FALSE
      AND t.voided = FALSE
      AND t.closing_date IS NOT NULL
", [$fechaInicio, $fechaFin]);

if (!empty($noPagados)) {
    printf("Tickets Cerrados NO Pagados:       %d tickets | Monto: $%.2f\n", 
        $noPagados[0]->total, $noPagados[0]->monto_total);
}

// Tickets con descuento 100%
$desc100 = DB::select("
    SELECT COUNT(*) as total
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
      AND t.total_price > 0
      AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99
", [$fechaInicio, $fechaFin]);

if (!empty($desc100)) {
    printf("Tickets con Descuento 100%%:        %d tickets\n", $desc100[0]->total);
}

// Tickets anulados
$anulados = DB::select("
    SELECT COUNT(*) as total
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
      AND t.voided = TRUE
", [$fechaInicio, $fechaFin]);

if (!empty($anulados)) {
    printf("Tickets Anulados:                   %d tickets\n", $anulados[0]->total);
}

// Tickets con mismatch pago vs neto
$mismatch = DB::select("
    WITH ticket_payments AS (
        SELECT 
            t.id,
            t.total_price - COALESCE(t.total_discount, 0) AS neto,
            COALESCE(SUM(tx.amount) FILTER (
                WHERE tx.voided = FALSE 
                  AND tx.transaction_type = 'CREDIT'
                  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')
            ), 0) AS pagado
        FROM public.ticket t
        LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
        WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) BETWEEN ? AND ?
          AND t.paid = TRUE
          AND t.voided = FALSE
        GROUP BY t.id, t.total_price, t.total_discount
    )
    SELECT 
        COUNT(*) as total,
        ROUND(COALESCE(SUM(ABS(neto - pagado)), 0)::numeric, 2) as diferencia_total
    FROM ticket_payments
    WHERE ABS(neto - pagado) > 0.50
", [$fechaInicio, $fechaFin]);

if (!empty($mismatch)) {
    printf("Tickets con Pago ≠ Neto:            %d tickets | Diferencia: $%.2f\n", 
        $mismatch[0]->total, $mismatch[0]->diferencia_total);
}

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 5. ESTADÍSTICAS GENERALES
// ═══════════════════════════════════════════════════════════════════════════════
echo "📈 5. ESTADÍSTICAS GENERALES DEL MES\n";
echo str_repeat("─", 90) . "\n";

$totalDiffVentas = array_sum(array_column($resumen, 'diff_ventas'));
$totalDiffTickets = array_sum(array_column($resumen, 'diff_tickets'));
$totalDiffDescuentos = array_sum(array_column($resumen, 'diff_descuentos'));

$diasConDiscrepancia = count(array_filter($resumen, function($item) {
    return abs($item['diff_ventas']) > 50;
}));

printf("Total Días Analizados:              %d días\n", count($resumen));
printf("Días con Discrepancia > $50:        %d días (%.1f%%)\n", 
    $diasConDiscrepancia, 
    ($diasConDiscrepancia / count($resumen)) * 100
);
printf("Diferencia Acumulada en Tickets:    %d tickets\n", $totalDiffTickets);
printf("Diferencia Acumulada en Ventas:     $%.2f\n", abs($totalDiffVentas));
printf("Diferencia Acumulada en Descuentos: $%.2f\n", abs($totalDiffDescuentos));

echo "\n";

// ═══════════════════════════════════════════════════════════════════════════════
// 6. DÍAS CRÍTICOS PARA ANÁLISIS DETALLADO
// ═══════════════════════════════════════════════════════════════════════════════
echo "🎯 6. DÍAS RECOMENDADOS PARA ANÁLISIS DETALLADO\n";
echo str_repeat("─", 90) . "\n\n";

echo "Ejecuta el análisis detallado para estas fechas:\n\n";

$contador = 1;
foreach (array_slice($top10, 0, 5) as $item) {
    if (abs($item['diff_ventas']) > 50) {
        printf("%d. Fecha: %s | Terminal: %s | Diferencia: $%.2f\n",
            $contador++,
            $item['fecha'],
            $item['terminal'],
            $item['diff_ventas']
        );
        printf("   Comando: php scripts/analizar_fecha_especifica.php %s %s\n\n",
            $item['fecha'],
            $item['terminal']
        );
    }
}

echo "═══════════════════════════════════════════════════════════════════════════════════\n";
echo "Análisis de patrones completado\n";
echo "═══════════════════════════════════════════════════════════════════════════════════\n\n";
