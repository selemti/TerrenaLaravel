<?php

/**
 * Análisis de Discrepancias en Reportes de Ventas
 * Compara datos de tickets vs precortes/postcortes
 * Enfoque especial en terminales 101 y 102
 */

require __DIR__ . '/../vendor/autoload.php';

use Illuminate\Support\Facades\DB;

echo "=== ANÁLISIS DE DISCREPANCIAS EN VENTAS ===\n";
echo "Período: Últimos 7 días\n";
echo "Terminales: 101 y 102\n";
echo "Fecha: " . date('Y-m-d H:i:s') . "\n\n";

try {
    // 1. Análisis básico de tickets por terminal
    echo "1. RESUMEN DE TICKETS ÚLTIMA SEMANA\n";
    echo "===================================\n";

    $ticketsPorTerminal = DB::connection('pgsql')->select("
        SELECT
            terminal_id,
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN voided = true THEN 1 END) as anulados,
            COUNT(CASE WHEN paid = true AND voided = false THEN 1 END) as pagados,
            SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_brutas,
            SUM(CASE WHEN voided = false THEN total_discount ELSE 0 END) as descuentos
        FROM public.ticket
        WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
            AND terminal_id IN (101, 102)
        GROUP BY terminal_id
        ORDER BY terminal_id
    ");

    foreach ($ticketsPorTerminal as $row) {
        $ventasNetas = $row->ventas_brutas - $row->descuentos;
        echo "Terminal {$row->terminal_id}:\n";
        echo "  Tickets totales: {$row->total_tickets}\n";
        echo "  Pagados: {$row->pagados}\n";
        echo "  Anulados: {$row->anulados}\n";
        echo "  Ventas brutas: $" . number_format($row->ventas_brutas, 2) . "\n";
        echo "  Descuentos: $" . number_format($row->descuentos, 2) . "\n";
        echo "  Ventas netas: $" . number_format($ventasNetas, 2) . "\n\n";
    }

    // 2. Análisis diario por terminal
    echo "2. ANÁLISIS DIARIO POR TERMINAL\n";
    echo "==============================\n";

    $ventasDiarias = DB::connection('pgsql')->select("
        SELECT
            closing_date::date as fecha,
            terminal_id,
            COUNT(*) as tickets,
            SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_dia
        FROM public.ticket
        WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
            AND terminal_id IN (101, 102)
        GROUP BY closing_date::date, terminal_id
        ORDER BY fecha, terminal_id
    ");

    $datosPorDia = [];
    foreach ($ventasDiarias as $row) {
        $datosPorDia[$row->fecha][$row->terminal_id] = [
            'tickets' => $row->tickets,
            'ventas' => $row->ventas_dia
        ];
    }

    foreach ($datosPorDia as $fecha => $terminales) {
        echo "Fecha: {$fecha}\n";
        foreach ($terminales as $terminal => $datos) {
            echo "  Terminal {$terminal}: {$datos['tickets']} tickets, $" . number_format($datos['ventas'], 2) . "\n";
        }
        echo "\n";
    }

    // 3. Análisis de formas de pago desde transactions
    echo "3. FORMAS DE PAGO ÚLTIMA SEMANA\n";
    echo "===============================\n";

    $formasPago = DB::connection('pgsql')->select("
        SELECT
            t.terminal_id,
            tr.payment_type,
            COUNT(*) as transacciones,
            SUM(tr.amount) as monto_total
        FROM public.transactions tr
        JOIN public.ticket t ON tr.ticket_id = t.id
        WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
            AND t.terminal_id IN (101, 102)
            AND tr.amount > 0
        GROUP BY t.terminal_id, tr.payment_type
        ORDER BY t.terminal_id, monto_total DESC
    ");

    $pagosPorTerminal = [];
    foreach ($formasPago as $pago) {
        $pagosPorTerminal[$pago->terminal_id][] = $pago;
    }

    foreach ($pagosPorTerminal as $terminal => $pagos) {
        $total = array_sum(array_column($pagos, 'monto_total'));
        echo "Terminal {$terminal} - Total: $" . number_format($total, 2) . "\n";

        foreach ($pagos as $pago) {
            $porcentaje = $total > 0 ? ($pago->monto_total / $total) * 100 : 0;
            echo "  {$pago->payment_type}: " . number_format($pago->monto_total, 2) .
                 " (" . number_format($porcentaje, 1) . "%) - {$pago->transacciones} txs\n";
        }
        echo "\n";
    }

    // 4. Precortes de la última semana
    echo "4. PRECORTES ÚLTIMA SEMANA\n";
    echo "==========================\n";

    $precortes = DB::connection('pgsql')->select("
        SELECT
            sc.terminal_id,
            p.fecha_hora::date as fecha,
            COUNT(*) as precortes,
            SUM(p.ventas_reportadas) as ventas_reportadas,
            SUM(p.efectivo_reportado) as efectivo_reportado,
            SUM(p.tarjetas_reportadas) as tarjetas_reportadas
        FROM selemti.precorte p
        JOIN selemti.sesion_cajon sc ON p.sesion_cajon_id = sc.id
        WHERE p.fecha_hora >= CURRENT_DATE - INTERVAL '7 days'
            AND sc.terminal_id IN (101, 102)
        GROUP BY sc.terminal_id, p.fecha_hora::date
        ORDER BY sc.terminal_id, fecha
    ");

    $precortesPorDia = [];
    foreach ($precortes as $precorte) {
        $precortesPorDia[$precorte->terminal_id][$precorte->fecha] = $precorte;
    }

    foreach ($precortesPorDia as $terminal => $dias) {
        echo "Terminal {$terminal}:\n";
        foreach ($dias as $fecha => $precorte) {
            echo "  {$fecha}: Ventas $" . number_format($precorte->ventas_reportadas, 2) .
                 ", Efectivo $" . number_format($precorte->efectivo_reportado, 2) .
                 ", Tarjetas $" . number_format($precorte->tarjetas_reportadas, 2) . "\n";
        }
        echo "\n";
    }

    // 5. Comparación: Tickets vs Precortes
    echo "5. COMPARACIÓN TICKETS vs PRECORTES\n";
    echo "===================================\n";

    // Obtener datos de tickets por día y terminal
    $ticketsVsPrecortes = DB::connection('pgsql')->select("
        SELECT
            closing_date::date as fecha,
            terminal_id,
            SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END) as ventas_tickets,
            COUNT(*) as tickets_count
        FROM public.ticket
        WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
            AND terminal_id IN (101, 102)
        GROUP BY closing_date::date, terminal_id
    ");

    echo "Diferencias detectadas:\n\n";

    foreach ($ticketsVsPrecortes as $ticketsData) {
        $fecha = $ticketsData->fecha;
        $terminal = $ticketsData->terminal_id;

        // Buscar precorte correspondiente
        $precorteCorrespondiente = null;
        if (isset($precortesPorDia[$terminal]) && isset($precortesPorDia[$terminal][$fecha])) {
            $precorteCorrespondiente = $precortesPorDia[$terminal][$fecha];
        }

        echo "Fecha: {$fecha} - Terminal: {$terminal}\n";
        echo "  Tickets: {$ticketsData->tickets_count} - Ventas: $" . number_format($ticketsData->ventas_tickets, 2) . "\n";

        if ($precorteCorrespondiente) {
            $diferencia = $ticketsData->ventas_tickets - $precorteCorrespondiente->ventas_reportadas;
            $porcentaje = $precorteCorrespondiente->ventas_reportadas > 0 ?
                         ($diferencia / $precorteCorrespondiente->ventas_reportadas) * 100 : 0;

            echo "  Precorte: $" . number_format($precorteCorrespondiente->ventas_reportadas, 2) . "\n";
            echo "  Diferencia: $" . number_format($diferencia, 2) .
                 " (" . number_format($porcentaje, 1) . "%)\n";

            if (abs($diferencia) > 100) { // Diferencia significativa
                echo "  ⚠️  DIFERENCIA SIGNIFICATIVA\n";
            }
        } else {
            echo "  ❌ SIN PRECORTE REGISTRADO\n";
        }
        echo "\n";
    }

    // 6. Análisis de anomalías
    echo "6. ANÁLISIS DE ANOMALÍAS\n";
    echo "=======================\n";

    // Tickets voided por día y terminal
    $anulados = DB::connection('pgsql')->select("
        SELECT
            closing_date::date as fecha,
            terminal_id,
            COUNT(*) as anulados,
            SUM(total_price) as monto_anulado
        FROM public.ticket
        WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
            AND terminal_id IN (101, 102)
            AND voided = true
        GROUP BY closing_date::date, terminal_id
        HAVING COUNT(*) > 0
        ORDER BY fecha, terminal_id
    ");

    if (count($anulados) > 0) {
        echo "Tickets anulados:\n";
        foreach ($anulados as $anulado) {
            echo "  {$anulado->fecha} - Terminal {$anulado->terminal_id}: " .
                 "{$anulado->anulados} tickets, $" . number_format($anulado->monto_anulado, 2) . "\n";
        }
    } else {
        echo "No se encontraron tickets anulados en el período.\n";
    }

    echo "\n";

    // 7. Resumen y recomendaciones
    echo "7. RESUMEN Y RECOMENDACIONES\n";
    echo "============================\n";

    $totalTickets101 = $ticketsPorTerminal[0]->total_tickets ?? 0;
    $totalTickets102 = $ticketsPorTerminal[1]->total_tickets ?? 0;

    echo "• Terminal 101: {$totalTickets101} tickets en la semana\n";
    echo "• Terminal 102: {$totalTickets102} tickets en la semana\n";
    echo "\n";

    echo "Próximos pasos recomendados:\n";
    echo "1. Revisar manualmente los días con diferencias significativas\n";
    echo "2. Verificar si los precortes se están haciendo correctamente\n";
    echo "3. Comprobar si hay tickets fuera de sistema (offline)\n";
    echo "4. Analizar patrones de anomalías por día/hora\n";
    echo "5. Validar integridad de datos en transactions vs ticket\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Line: " . $e->getLine() . "\n";
}

echo "\n=== FIN DEL ANÁLISIS ===\n";

?>