<?php
/**
 * Análisis Completo de Discrepancias en Reportes de Ventas
 * Agosto, Septiembre y Octubre 2025
 * 
 * Incluye TODOS los métodos de pago: CASH, CREDIT, DEBIT, TRANSFER
 * Analiza descuentos al 100%, tickets no pagados, anulaciones, etc.
 */

require __DIR__ . '/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Configuración de conexión PostgreSQL
$host = $_ENV['DB_HOST'] ?? 'localhost';
$port = $_ENV['DB_PORT'] ?? '5432';
$dbname = $_ENV['DB_DATABASE'] ?? 'terrena';
$user = $_ENV['DB_USERNAME'] ?? 'postgres';
$password = $_ENV['DB_PASSWORD'] ?? '';

$dsn = "pgsql:host=$host;port=$port;dbname=$dbname";

try {
    $pdo = new PDO($dsn, $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ
    ]);
    
    echo "═══════════════════════════════════════════════════════════════════════════\n";
    echo "  ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS - AGO/SEP/OCT 2025\n";
    echo "═══════════════════════════════════════════════════════════════════════════\n\n";

    // Meses a analizar
    $meses = [
        ['nombre' => 'AGOSTO', 'inicio' => '2025-08-01', 'fin' => '2025-08-31'],
        ['nombre' => 'SEPTIEMBRE', 'inicio' => '2025-09-01', 'fin' => '2025-09-30'],
        ['nombre' => 'OCTUBRE', 'inicio' => '2025-10-01', 'fin' => '2025-10-31']
    ];

    foreach ($meses as $mes) {
        analizarMes($pdo, $mes['nombre'], $mes['inicio'], $mes['fin']);
    }

} catch (PDOException $e) {
    echo "ERROR DE CONEXIÓN: " . $e->getMessage() . "\n";
    exit(1);
}

function analizarMes($pdo, $nombreMes, $fechaInicio, $fechaFin) {
    echo "\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "  MES: $nombreMes ($fechaInicio al $fechaFin)\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

    // 1. RESUMEN GENERAL DE TICKETS
    echo "┌─ 1. RESUMEN GENERAL DE TICKETS ─────────────────────────────────────┐\n";
    $query = "
        SELECT 
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN paid = TRUE THEN 1 END) as tickets_pagados,
            COUNT(CASE WHEN paid = FALSE THEN 1 END) as tickets_no_pagados,
            COUNT(CASE WHEN voided = TRUE THEN 1 END) as tickets_anulados,
            COUNT(CASE WHEN closed_at IS NOT NULL THEN 1 END) as tickets_cerrados,
            COUNT(CASE WHEN closed_at IS NULL THEN 1 END) as tickets_abiertos
        FROM public.ticket
        WHERE DATE(created_at) BETWEEN :inicio AND :fin
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $resumen = $stmt->fetch();
    
    echo "  Total de Tickets:        " . number_format($resumen->total_tickets) . "\n";
    echo "  ├─ Pagados:              " . number_format($resumen->tickets_pagados) . "\n";
    echo "  ├─ No Pagados:           " . number_format($resumen->tickets_no_pagados) . "\n";
    echo "  ├─ Anulados:             " . number_format($resumen->tickets_anulados) . "\n";
    echo "  ├─ Cerrados:             " . number_format($resumen->tickets_cerrados) . "\n";
    echo "  └─ Abiertos:             " . number_format($resumen->tickets_abiertos) . "\n";
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 2. ANÁLISIS DE VENTAS POR MÉTODO DE PAGO
    echo "┌─ 2. VENTAS POR MÉTODO DE PAGO (Según transacciones reales) ────────┐\n";
    $query = "
        SELECT 
            tt.payment_type,
            COUNT(DISTINCT t.id) as cantidad_tickets,
            SUM(tt.amount) as total_monto,
            AVG(tt.amount) as promedio_monto,
            MIN(tt.amount) as monto_minimo,
            MAX(tt.amount) as monto_maximo
        FROM public.ticket t
        INNER JOIN public.ticket_transaction tt ON t.id = tt.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
            AND tt.payment_type IN ('CASH', 'CREDIT', 'DEBIT', 'TRANSFER')
        GROUP BY tt.payment_type
        ORDER BY total_monto DESC
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $pagos = $stmt->fetchAll();
    
    $totalGeneral = 0;
    foreach ($pagos as $pago) {
        $totalGeneral += $pago->total_monto;
    }
    
    foreach ($pagos as $pago) {
        $porcentaje = $totalGeneral > 0 ? ($pago->total_monto / $totalGeneral * 100) : 0;
        echo sprintf("  %-10s │ Tickets: %5d │ Total: $%12s │ Promedio: $%8s │ %5.2f%%\n",
            $pago->payment_type,
            $pago->cantidad_tickets,
            number_format($pago->total_monto, 2),
            number_format($pago->promedio_monto, 2),
            $porcentaje
        );
    }
    echo "  ────────────────────────────────────────────────────────────────────\n";
    echo "  TOTAL GENERAL:                      $" . number_format($totalGeneral, 2) . "\n";
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 3. ANÁLISIS DE DESCUENTOS AL 100%
    echo "┌─ 3. DESCUENTOS AL 100% (Completos) ─────────────────────────────────┐\n";
    $query = "
        SELECT 
            t.id as ticket_id,
            t.created_at,
            t.closed_at,
            t.paid,
            t.voided,
            ti.name as discount_name,
            SUM(ti.quantity * ti.price) as subtotal_original,
            SUM(ti.discount) as total_descuento,
            SUM(ti.quantity * ti.price - ti.discount) as total_final
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
            AND ti.discount > 0
        GROUP BY t.id, t.created_at, t.closed_at, t.paid, t.voided, ti.name
        HAVING SUM(ti.quantity * ti.price - ti.discount) = 0
            OR (SUM(ti.discount) / NULLIF(SUM(ti.quantity * ti.price), 0) * 100) >= 99
        ORDER BY t.created_at
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $descuentos100 = $stmt->fetchAll();
    
    if (count($descuentos100) > 0) {
        $totalDescuentos100 = 0;
        echo sprintf("  %-8s │ %-19s │ %-8s │ Subtotal │ Descuento │ Final\n", 
            "Ticket", "Fecha", "Estado");
        echo "  ────────┼─────────────────────┼──────────┼──────────┼───────────┼────────\n";
        
        foreach ($descuentos100 as $desc) {
            $totalDescuentos100 += $desc->total_descuento;
            $estado = [];
            if ($desc->paid) $estado[] = 'PAGADO';
            if (!$desc->paid) $estado[] = 'NO PAGADO';
            if ($desc->voided) $estado[] = 'ANULADO';
            $estadoStr = implode(',', $estado);
            
            echo sprintf("  %8d │ %19s │ %-8s │ $%7.2f │ $%8.2f │ $%5.2f\n",
                $desc->ticket_id,
                substr($desc->created_at, 0, 19),
                substr($estadoStr, 0, 8),
                $desc->subtotal_original,
                $desc->total_descuento,
                $desc->total_final
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        echo "  Total de tickets con descuento 100%: " . count($descuentos100) . "\n";
        echo "  Monto total de descuentos 100%: $" . number_format($totalDescuentos100, 2) . "\n";
    } else {
        echo "  No se encontraron descuentos del 100%\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 4. TODOS LOS DESCUENTOS (NO SOLO 100%)
    echo "┌─ 4. RESUMEN DE TODOS LOS DESCUENTOS ────────────────────────────────┐\n";
    $query = "
        SELECT 
            COUNT(DISTINCT t.id) as tickets_con_descuento,
            SUM(ti.discount) as total_descuentos,
            AVG(ti.discount) as promedio_descuento,
            MAX(ti.discount) as descuento_maximo
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
            AND ti.discount > 0
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $descuentos = $stmt->fetch();
    
    echo "  Tickets con descuento:    " . number_format($descuentos->tickets_con_descuento) . "\n";
    echo "  Total descuentos:         $" . number_format($descuentos->total_descuentos, 2) . "\n";
    echo "  Promedio por descuento:   $" . number_format($descuentos->promedio_descuento, 2) . "\n";
    echo "  Descuento máximo:         $" . number_format($descuentos->descuento_maximo, 2) . "\n";
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 5. TICKETS NO PAGADOS CON MONTO > 0
    echo "┌─ 5. TICKETS NO PAGADOS (Con monto pendiente) ──────────────────────┐\n";
    $query = "
        SELECT 
            t.id,
            t.created_at,
            t.closed_at,
            t.voided,
            SUM(ti.quantity * ti.price - ti.discount) as total
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
            AND t.paid = FALSE
        GROUP BY t.id, t.created_at, t.closed_at, t.voided
        HAVING SUM(ti.quantity * ti.price - ti.discount) > 0
        ORDER BY total DESC
        LIMIT 20
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $noPagados = $stmt->fetchAll();
    
    if (count($noPagados) > 0) {
        $totalNoPagado = 0;
        echo sprintf("  %-8s │ %-19s │ %-8s │ Monto\n", "Ticket", "Creado", "Estado");
        echo "  ────────┼─────────────────────┼──────────┼─────────\n";
        
        foreach ($noPagados as $np) {
            $totalNoPagado += $np->total;
            $estado = $np->voided ? 'ANULADO' : ($np->closed_at ? 'CERRADO' : 'ABIERTO');
            echo sprintf("  %8d │ %19s │ %-8s │ $%8.2f\n",
                $np->id,
                substr($np->created_at, 0, 19),
                $estado,
                $np->total
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        echo "  Total no pagado (primeros 20): $" . number_format($totalNoPagado, 2) . "\n";
    } else {
        echo "  No se encontraron tickets no pagados con monto > 0\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 6. TICKETS ANULADOS CON TRANSACCIONES
    echo "┌─ 6. TICKETS ANULADOS CON TRANSACCIONES ─────────────────────────────┐\n";
    $query = "
        SELECT 
            t.id,
            t.created_at,
            t.paid,
            COUNT(tt.id) as num_transacciones,
            SUM(tt.amount) as total_transacciones,
            SUM(ti.quantity * ti.price - ti.discount) as total_ticket
        FROM public.ticket t
        INNER JOIN public.ticket_transaction tt ON t.id = tt.ticket_id
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
            AND t.voided = TRUE
        GROUP BY t.id, t.created_at, t.paid
        ORDER BY total_transacciones DESC
        LIMIT 20
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $anulados = $stmt->fetchAll();
    
    if (count($anulados) > 0) {
        echo sprintf("  %-8s │ %-19s │ Trans. │ Monto Trans. │ Monto Ticket\n", "Ticket", "Creado");
        echo "  ────────┼─────────────────────┼────────┼──────────────┼─────────────\n";
        
        foreach ($anulados as $anu) {
            echo sprintf("  %8d │ %19s │ %6d │ $%11.2f │ $%10.2f\n",
                $anu->id,
                substr($anu->created_at, 0, 19),
                $anu->num_transacciones,
                $anu->total_transacciones,
                $anu->total_ticket
            );
        }
    } else {
        echo "  No se encontraron tickets anulados con transacciones\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 7. DISCREPANCIAS: MONTO PAGADO VS MONTO TICKET
    echo "┌─ 7. DISCREPANCIAS: Monto Pagado vs Monto Ticket ───────────────────┐\n";
    $query = "
        SELECT 
            t.id,
            t.created_at,
            t.paid,
            t.voided,
            SUM(ti.quantity * ti.price - ti.discount) as total_ticket,
            COALESCE(SUM(tt.amount), 0) as total_pagado,
            COALESCE(SUM(tt.amount), 0) - SUM(ti.quantity * ti.price - ti.discount) as diferencia
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        LEFT JOIN public.ticket_transaction tt ON t.id = tt.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
        GROUP BY t.id, t.created_at, t.paid, t.voided
        HAVING ABS(COALESCE(SUM(tt.amount), 0) - SUM(ti.quantity * ti.price - ti.discount)) > 0.01
        ORDER BY ABS(COALESCE(SUM(tt.amount), 0) - SUM(ti.quantity * ti.price - ti.discount)) DESC
        LIMIT 30
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $discrepancias = $stmt->fetchAll();
    
    if (count($discrepancias) > 0) {
        echo sprintf("  %-8s │ Ticket │ Pagado │ Diferencia │ Estado\n", "Ticket");
        echo "  ────────┼────────┼────────┼────────────┼──────────────\n";
        
        $sumaDiferencias = 0;
        foreach ($discrepancias as $disc) {
            $sumaDiferencias += $disc->diferencia;
            $estado = [];
            if ($disc->paid) $estado[] = 'PAGADO';
            if ($disc->voided) $estado[] = 'ANULADO';
            $estadoStr = implode(',', $estado) ?: 'PENDIENTE';
            
            echo sprintf("  %8d │ $%5.2f │ $%5.2f │ $%9.2f │ %s\n",
                $disc->id,
                $disc->total_ticket,
                $disc->total_pagado,
                $disc->diferencia,
                $estadoStr
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        echo "  Suma total de diferencias: $" . number_format($sumaDiferencias, 2) . "\n";
    } else {
        echo "  No se encontraron discrepancias significativas\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 8. COMPARACIÓN CON DRAWER PULL REPORTS
    echo "┌─ 8. COMPARACIÓN CON DRAWER PULL REPORTS ────────────────────────────┐\n";
    $query = "
        SELECT 
            DATE(report_time) as fecha,
            COUNT(*) as num_reportes,
            SUM(cash_in_drawer) as efectivo_reportado,
            SUM(net_sales) as ventas_netas_reportadas,
            SUM(total_revenue) as ingresos_totales_reportados,
            SUM(ticket_count) as tickets_reportados
        FROM public.drawer_pull_report
        WHERE DATE(report_time) BETWEEN :inicio AND :fin
        GROUP BY DATE(report_time)
        ORDER BY fecha
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $reportes = $stmt->fetchAll();
    
    if (count($reportes) > 0) {
        echo sprintf("  %-12s │ Rep. │ Efectivo │ Ventas Netas │ Tickets\n", "Fecha");
        echo "  ────────────┼──────┼──────────┼──────────────┼─────────\n";
        
        foreach ($reportes as $rep) {
            echo sprintf("  %12s │ %4d │ $%7.2f │ $%11.2f │ %7d\n",
                $rep->fecha,
                $rep->num_reportes,
                $rep->efectivo_reportado,
                $rep->ventas_netas_reportadas,
                $rep->tickets_reportados
            );
        }
    } else {
        echo "  No se encontraron drawer pull reports para este periodo\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 9. RESUMEN FINAL DEL MES
    echo "┌─ 9. RESUMEN FINAL DEL MES ──────────────────────────────────────────┐\n";
    
    // Calcular totales reales
    $query = "
        SELECT 
            SUM(ti.quantity * ti.price) as ventas_brutas,
            SUM(ti.discount) as descuentos_totales,
            SUM(ti.quantity * ti.price - ti.discount) as ventas_netas,
            COUNT(DISTINCT t.id) as total_tickets
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE DATE(t.created_at) BETWEEN :inicio AND :fin
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $totales = $stmt->fetch();
    
    echo "  Ventas Brutas:           $" . number_format($totales->ventas_brutas, 2) . "\n";
    echo "  Descuentos Totales:      $" . number_format($totales->descuentos_totales, 2) . "\n";
    echo "  Ventas Netas:            $" . number_format($totales->ventas_netas, 2) . "\n";
    echo "  Total de Tickets:        " . number_format($totales->total_tickets) . "\n";
    echo "  ────────────────────────────────────────────────────────────────────\n";
    echo "  Total cobrado (todos los métodos): $" . number_format($totalGeneral, 2) . "\n";
    
    $diferencia = $totales->ventas_netas - $totalGeneral;
    echo "  Diferencia (Ventas Netas - Cobrado): $" . number_format($diferencia, 2) . "\n";
    
    if (abs($diferencia) > 0.01) {
        $porcentaje = ($diferencia / $totales->ventas_netas * 100);
        echo "  Porcentaje de diferencia: " . number_format($porcentaje, 2) . "%\n";
    }
    
    echo "└────────────────────────────────────────────────────────────────────┘\n";
}

echo "\n";
echo "═══════════════════════════════════════════════════════════════════════════\n";
echo "  ANÁLISIS COMPLETADO\n";
echo "═══════════════════════════════════════════════════════════════════════════\n";
