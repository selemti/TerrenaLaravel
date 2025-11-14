<?php

/**
 * ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS
 * Agosto, Septiembre y Octubre 2025
 * Incluye TODOS los métodos de pago: Cash, Credit, Debit, Transfer
 */

require __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

DB::connection('pgsql')->statement('SET search_path TO selemti,public');
DB::connection('pgsql')->statement("SET TIME ZONE 'America/Mexico_City'");

echo "\n╔══════════════════════════════════════════════════════════════════════════════╗\n";
echo "║     ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS - AGO/SEP/OCT 2025         ║\n";
echo "║              INCLUYE TODOS LOS MÉTODOS DE PAGO                               ║\n";
echo "╚══════════════════════════════════════════════════════════════════════════════╝\n\n";

$months = [
    ['name' => 'AGOSTO 2025', 'start' => '2025-08-01', 'end' => '2025-08-31'],
    ['name' => 'SEPTIEMBRE 2025', 'start' => '2025-09-01', 'end' => '2025-09-30'],
    ['name' => 'OCTUBRE 2025', 'start' => '2025-10-01', 'end' => '2025-10-31'],
];

foreach ($months as $month) {
    analyzeMonth($month['name'], $month['start'], $month['end']);
}

function analyzeMonth($monthName, $startDate, $endDate)
{
    echo "\n".str_repeat('=', 80)."\n";
    echo "  📅 ANÁLISIS DE {$monthName}\n";
    echo str_repeat('=', 80)."\n\n";

    // 1. RESUMEN GENERAL POR DÍA
    echo "📊 RESUMEN DIARIO DE VENTAS Y PAGOS\n";
    echo str_repeat('-', 80)."\n";

    $dailySummary = DB::connection('pgsql')->select("
        WITH daily_data AS (
            SELECT 
                t.folio_date AS fecha,
                COUNT(DISTINCT t.id) AS total_tickets,
                COUNT(DISTINCT CASE WHEN t.paid = TRUE THEN t.id END) AS tickets_pagados,
                COUNT(DISTINCT CASE WHEN t.voided = TRUE THEN t.id END) AS tickets_anulados,
                COUNT(DISTINCT CASE WHEN t.paid = FALSE AND t.voided = FALSE THEN t.id END) AS tickets_no_pagados,
                
                -- TOTALES DE TICKETS
                COALESCE(SUM(ti.item_price * ti.item_quantity), 0) AS total_items_bruto,
                COALESCE(SUM(t.total_discount), 0) AS total_descuentos,
                COALESCE(SUM(CASE WHEN t.total_discount >= t.total_price THEN t.total_discount ELSE 0 END), 0) AS descuentos_100_pct,
                
                -- PAGOS POR MÉTODO
                COALESCE(SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END), 0) AS total_cash,
                COALESCE(SUM(CASE WHEN tr.payment_type = 'CREDIT_CARD' THEN tr.amount ELSE 0 END), 0) AS total_credit,
                COALESCE(SUM(CASE WHEN tr.payment_type = 'DEBIT_CARD' THEN tr.amount ELSE 0 END), 0) AS total_debit,
                COALESCE(SUM(CASE WHEN tr.payment_type = 'BANK_TRANSFER' THEN tr.amount ELSE 0 END), 0) AS total_transfer,
                COALESCE(SUM(CASE WHEN tr.transaction_type IN ('REFUND', 'VOID') THEN tr.amount ELSE 0 END), 0) AS total_refunds,
                
                -- TOTALES GENERALES
                COALESCE(SUM(CASE WHEN tr.transaction_type NOT IN ('REFUND', 'VOID') THEN tr.amount ELSE 0 END), 0) AS total_pagos,
                COALESCE(SUM(tr.amount), 0) AS total_transacciones
                
            FROM public.ticket t
            LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
            LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
            WHERE t.folio_date BETWEEN ? AND ?
            GROUP BY t.folio_date
        )
        SELECT 
            fecha,
            total_tickets,
            tickets_pagados,
            tickets_anulados,
            tickets_no_pagados,
            total_items_bruto,
            total_descuentos,
            descuentos_100_pct,
            total_cash,
            total_credit,
            total_debit,
            total_transfer,
            total_refunds,
            total_pagos,
            total_transacciones,
            (total_items_bruto - total_descuentos) AS venta_neta_esperada,
            (total_pagos - ABS(total_refunds)) AS pagos_netos,
            ((total_items_bruto - total_descuentos) - (total_pagos - ABS(total_refunds))) AS diferencia
        FROM daily_data
        ORDER BY fecha
    ", [$startDate, $endDate]);

    $totalDifferencia = 0;
    $totalVentaNeta = 0;
    $totalPagosNetos = 0;

    foreach ($dailySummary as $day) {
        echo sprintf(
            '📆 %s | Tickets: %d (Pag:%d, Anul:%d, NoPag:%d) | '.
            "Venta Bruta: $%s | Desc: $%s (100%%: $%s)\n".
            "   💰 PAGOS: Cash $%s | Credit $%s | Debit $%s | Transfer $%s | Refund $%s\n".
            "   📈 Venta Neta Esperada: $%s | Pagos Netos: $%s | ⚠️  DIFERENCIA: $%s\n\n",
            $day->fecha,
            $day->total_tickets,
            $day->tickets_pagados,
            $day->tickets_anulados,
            $day->tickets_no_pagados,
            number_format($day->total_items_bruto, 2),
            number_format($day->total_descuentos, 2),
            number_format($day->descuentos_100_pct, 2),
            number_format($day->total_cash, 2),
            number_format($day->total_credit, 2),
            number_format($day->total_debit, 2),
            number_format($day->total_transfer, 2),
            number_format($day->total_refunds, 2),
            number_format($day->venta_neta_esperada, 2),
            number_format($day->pagos_netos, 2),
            number_format($day->diferencia, 2)
        );

        $totalDifferencia += $day->diferencia;
        $totalVentaNeta += $day->venta_neta_esperada;
        $totalPagosNetos += $day->pagos_netos;
    }

    echo "\n".str_repeat('-', 80)."\n";
    echo sprintf(
        "🎯 TOTAL DEL MES:\n".
        "   Venta Neta Esperada: $%s\n".
        "   Pagos Netos Recibidos: $%s\n".
        "   ⚠️  DIFERENCIA TOTAL: $%s (%.2f%%)\n",
        number_format($totalVentaNeta, 2),
        number_format($totalPagosNetos, 2),
        number_format($totalDifferencia, 2),
        $totalVentaNeta > 0 ? ($totalDifferencia / $totalVentaNeta * 100) : 0
    );
    echo str_repeat('-', 80)."\n\n";

    // 2. ANÁLISIS DE TICKETS PROBLEMÁTICOS
    echo "\n🔍 TICKETS PROBLEMÁTICOS EN {$monthName}\n";
    echo str_repeat('-', 80)."\n";

    $problematicTickets = DB::connection('pgsql')->select("
        SELECT 
            t.id,
            t.folio_date AS fecha,
            t.paid,
            t.voided,
            COALESCE(SUM(ti.item_price * ti.item_quantity), 0) AS total_items,
            COALESCE(t.total_discount, 0) AS descuento,
            (COALESCE(SUM(ti.item_price * ti.item_quantity), 0) - COALESCE(t.total_discount, 0)) AS total_neto,
            
            COALESCE(SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END), 0) AS pago_cash,
            COALESCE(SUM(CASE WHEN tr.payment_type = 'CREDIT_CARD' THEN tr.amount ELSE 0 END), 0) AS pago_credit,
            COALESCE(SUM(CASE WHEN tr.payment_type = 'DEBIT_CARD' THEN tr.amount ELSE 0 END), 0) AS pago_debit,
            COALESCE(SUM(CASE WHEN tr.payment_type = 'BANK_TRANSFER' THEN tr.amount ELSE 0 END), 0) AS pago_transfer,
            COALESCE(SUM(CASE WHEN tr.transaction_type NOT IN ('REFUND', 'VOID') THEN tr.amount ELSE 0 END), 0) AS total_pagado,
            
            CASE 
                WHEN t.paid = FALSE AND t.voided = FALSE THEN 'NO_PAGADO'
                WHEN t.voided = TRUE THEN 'ANULADO'
                WHEN t.total_discount >= COALESCE(SUM(ti.item_price * ti.item_quantity), 0) THEN 'DESC_100_PCT'
                WHEN ABS((COALESCE(SUM(ti.item_price * ti.item_quantity), 0) - COALESCE(t.total_discount, 0)) - 
                     COALESCE(SUM(CASE WHEN tr.transaction_type NOT IN ('REFUND', 'VOID') THEN tr.amount ELSE 0 END), 0)) > 0.01 
                THEN 'PAGO_DIFERENTE'
                ELSE 'OTRO'
            END AS tipo_problema
            
        FROM public.ticket t
        LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
        LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
        WHERE t.folio_date BETWEEN ? AND ?
        GROUP BY t.id, t.folio_date, t.paid, t.voided, t.total_discount
        HAVING 
            t.paid = FALSE AND t.voided = FALSE
            OR t.voided = TRUE
            OR t.total_discount >= COALESCE(SUM(ti.item_price * ti.item_quantity), 0)
            OR ABS((COALESCE(SUM(ti.item_price * ti.item_quantity), 0) - COALESCE(t.total_discount, 0)) -
               COALESCE(SUM(CASE WHEN tr.transaction_type NOT IN ('REFUND', 'VOID') THEN tr.amount ELSE 0 END), 0)) > 0.01
        ORDER BY t.folio_date, tipo_problema, t.id
    ", [$startDate, $endDate]);

    $problemCounts = [
        'NO_PAGADO' => 0,
        'ANULADO' => 0,
        'DESC_100_PCT' => 0,
        'PAGO_DIFERENTE' => 0,
        'OTRO' => 0,
    ];

    $problemTotals = [
        'NO_PAGADO' => 0,
        'ANULADO' => 0,
        'DESC_100_PCT' => 0,
        'PAGO_DIFERENTE' => 0,
        'OTRO' => 0,
    ];

    foreach ($problematicTickets as $ticket) {
        $problemCounts[$ticket->tipo_problema]++;
        $problemTotals[$ticket->tipo_problema] += $ticket->total_neto;

        if ($ticket->tipo_problema == 'DESC_100_PCT' || $ticket->tipo_problema == 'NO_PAGADO') {
            echo sprintf(
                "🎫 Ticket #%d [%s] - %s\n".
                "   Items: $%s | Desc: $%s | Neto: $%s | Pagado: $%s (C:$%s Cr:$%s D:$%s T:$%s)\n",
                $ticket->id,
                $ticket->fecha,
                $ticket->tipo_problema,
                number_format($ticket->total_items, 2),
                number_format($ticket->descuento, 2),
                number_format($ticket->total_neto, 2),
                number_format($ticket->total_pagado, 2),
                number_format($ticket->pago_cash, 2),
                number_format($ticket->pago_credit, 2),
                number_format($ticket->pago_debit, 2),
                number_format($ticket->pago_transfer, 2)
            );
        }
    }

    echo "\n📊 RESUMEN DE PROBLEMAS:\n";
    foreach ($problemCounts as $tipo => $count) {
        if ($count > 0) {
            echo sprintf(
                "   %s: %d tickets | Total afectado: $%s\n",
                $tipo,
                $count,
                number_format($problemTotals[$tipo], 2)
            );
        }
    }

    // 3. ANÁLISIS DE DESCUENTOS
    echo "\n\n💸 ANÁLISIS DE DESCUENTOS EN {$monthName}\n";
    echo str_repeat('-', 80)."\n";

    $discountAnalysis = DB::connection('pgsql')->select('
        SELECT 
            t.folio_date AS fecha,
            COUNT(DISTINCT t.id) AS tickets_con_descuento,
            COUNT(DISTINCT CASE WHEN t.total_discount >= (SELECT SUM(ti2.item_price * ti2.item_quantity) 
                                                     FROM public.ticket_item ti2 
                                                     WHERE ti2.ticket_id = t.id) 
                           THEN t.id END) AS descuentos_100_pct,
            COALESCE(SUM(t.total_discount), 0) AS total_descuentos,
            COALESCE(SUM(CASE WHEN t.total_discount >= (SELECT SUM(ti2.item_price * ti2.item_quantity) 
                                                  FROM public.ticket_item ti2 
                                                  WHERE ti2.ticket_id = t.id)
                         THEN t.total_discount ELSE 0 END), 0) AS monto_desc_100_pct
        FROM public.ticket t
        WHERE t.folio_date BETWEEN ? AND ?
          AND t.total_discount > 0
        GROUP BY t.folio_date
        ORDER BY fecha
    ', [$startDate, $endDate]);

    foreach ($discountAnalysis as $disc) {
        echo sprintf(
            "📅 %s | Tickets c/desc: %d (100%%: %d) | Total desc: $%s (100%%: $%s)\n",
            $disc->fecha,
            $disc->tickets_con_descuento,
            $disc->descuentos_100_pct,
            number_format($disc->total_descuentos, 2),
            number_format($disc->monto_desc_100_pct, 2)
        );
    }

    echo "\n".str_repeat('=', 80)."\n";
}

echo "\n✅ Análisis completado\n\n";
