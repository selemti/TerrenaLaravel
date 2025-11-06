<?php
/**
 * Análisis Completo de Discrepancias de Ventas
 * Agosto, Septiembre y Octubre 2025
 * 
 * Analiza:
 * - Todos los tipos de pago (CASH, CREDIT_CARD, DEBIT_CARD, etc.)
 * - Descuentos del 100% y otros descuentos
 * - Tickets no pagados, anulados, cerrados
 * - Discrepancias entre drawer reports y datos reales
 */

// Configuración de base de datos
$host = '127.0.0.1';
$port = '5433';
$dbname = 'pos';
$user = 'postgres';
$password = 'T3rr3n4#p0s';

try {
    $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✓ Conexión exitosa a la base de datos\n\n";
} catch (PDOException $e) {
    die("ERROR: No se pudo conectar a la base de datos: " . $e->getMessage() . "\n");
}

// Definir los meses a analizar
$meses = [
    ['nombre' => 'AGOSTO', 'inicio' => '2025-08-01', 'fin' => '2025-08-31'],
    ['nombre' => 'SEPTIEMBRE', 'inicio' => '2025-09-01', 'fin' => '2025-09-30'],
    ['nombre' => 'OCTUBRE', 'inicio' => '2025-10-01', 'fin' => '2025-10-31'],
];

echo str_repeat('=', 100) . "\n";
echo "ANÁLISIS COMPLETO DE DISCREPANCIAS DE VENTAS - AGOSTO, SEPTIEMBRE Y OCTUBRE 2025\n";
echo str_repeat('=', 100) . "\n\n";

foreach ($meses as $mes) {
    echo "\n" . str_repeat('━', 100) . "\n";
    echo "MES: {$mes['nombre']} ({$mes['inicio']} al {$mes['fin']})\n";
    echo str_repeat('━', 100) . "\n\n";
    
    analizarMes($pdo, $mes['nombre'], $mes['inicio'], $mes['fin']);
}

echo "\n" . str_repeat('=', 100) . "\n";
echo "ANÁLISIS COMPLETADO\n";
echo str_repeat('=', 100) . "\n";

/**
 * Analiza un mes completo
 */
function analizarMes($pdo, $nombreMes, $fechaInicio, $fechaFin) {
    
    // 1. RESUMEN DE DRAWER PULL REPORTS
    echo "1. RESUMEN DE DRAWER PULL REPORTS\n";
    echo str_repeat('-', 80) . "\n";
    
    $sql = "
    SELECT 
        COUNT(*) as total_reportes,
        SUM(CAST(cash_receipt_amount AS DECIMAL(10,2))) as total_efectivo_reportado,
        SUM(CAST(credit_card_receipt_amount AS DECIMAL(10,2))) as total_tarjeta_credito,
        SUM(CAST(debit_card_receipt_amount AS DECIMAL(10,2))) as total_tarjeta_debito,
        SUM(CAST(ticket_count AS INTEGER)) as total_tickets_reportados,
        SUM(CAST(net_sales AS DECIMAL(10,2))) as total_ventas_netas_reportadas,
        SUM(CAST(totaldiscountamount AS DECIMAL(10,2))) as total_descuentos_reportados,
        MIN(report_time::DATE) as primer_reporte,
        MAX(report_time::DATE) as ultimo_reporte
    FROM public.drawer_pull_report
    WHERE report_time::DATE BETWEEN :inicio AND :fin
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $reportes = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "  Total de reportes: " . number_format($reportes['total_reportes']) . "\n";
    echo "  Efectivo reportado: $" . number_format($reportes['total_efectivo_reportado'], 2) . "\n";
    echo "  Tarjeta crédito reportado: $" . number_format($reportes['total_tarjeta_credito'], 2) . "\n";
    echo "  Tarjeta débito reportado: $" . number_format($reportes['total_tarjeta_debito'], 2) . "\n";
    echo "  Tickets reportados: " . number_format($reportes['total_tickets_reportados']) . "\n";
    echo "  Ventas netas reportadas: $" . number_format($reportes['total_ventas_netas_reportadas'], 2) . "\n";
    echo "  Descuentos reportados: $" . number_format($reportes['total_descuentos_reportados'], 2) . "\n";
    echo "  Período: {$reportes['primer_reporte']} a {$reportes['ultimo_reporte']}\n\n";
    
    // 2. DATOS REALES DE TICKETS
    echo "2. DATOS REALES DE TICKETS\n";
    echo str_repeat('-', 80) . "\n";
    
    $sql = "
    SELECT 
        COUNT(*) as total_tickets,
        COUNT(CASE WHEN closing_date IS NOT NULL THEN 1 END) as tickets_cerrados,
        COUNT(CASE WHEN paid = TRUE THEN 1 END) as tickets_pagados,
        COUNT(CASE WHEN voided = TRUE THEN 1 END) as tickets_anulados,
        COUNT(CASE WHEN closing_date IS NOT NULL AND paid = FALSE THEN 1 END) as cerrados_no_pagados,
        SUM(CAST(sub_total AS DECIMAL(10,2))) as total_subtotal,
        SUM(CAST(total_discount AS DECIMAL(10,2))) as total_descuentos,
        SUM(CAST(total_price AS DECIMAL(10,2))) as total_neto,
        SUM(CAST(total_tax AS DECIMAL(10,2))) as total_impuestos
    FROM public.ticket
    WHERE create_date::DATE BETWEEN :inicio AND :fin
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $tickets = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "  Total de tickets: " . number_format($tickets['total_tickets']) . "\n";
    echo "  Tickets cerrados: " . number_format($tickets['tickets_cerrados']) . "\n";
    echo "  Tickets pagados: " . number_format($tickets['tickets_pagados']) . "\n";
    echo "  Tickets anulados: " . number_format($tickets['tickets_anulados']) . "\n";
    echo "  Cerrados no pagados: " . number_format($tickets['cerrados_no_pagados']) . "\n";
    echo "  Subtotal: $" . number_format($tickets['total_subtotal'], 2) . "\n";
    echo "  Descuentos: $" . number_format($tickets['total_descuentos'], 2) . "\n";
    echo "  Neto: $" . number_format($tickets['total_neto'], 2) . "\n";
    echo "  Impuestos: $" . number_format($tickets['total_impuestos'], 2) . "\n\n";
    
    // 3. ANÁLISIS DE TRANSACCIONES POR TIPO DE PAGO
    echo "3. TRANSACCIONES POR TIPO DE PAGO\n";
    echo str_repeat('-', 80) . "\n";
    
    $sql = "
    SELECT 
        COALESCE(pt.payment_type, 'SIN_TIPO') as tipo_pago,
        COUNT(*) as cantidad,
        SUM(CAST(pt.amount AS DECIMAL(10,2))) as monto_total
    FROM public.transactions pt
    INNER JOIN public.ticket t ON pt.ticket_id = t.id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
    GROUP BY pt.payment_type
    ORDER BY monto_total DESC
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $transacciones = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $total_transacciones = 0;
    foreach ($transacciones as $trans) {
        echo sprintf("  %-20s: %6d transacciones = $%15s\n", 
            $trans['tipo_pago'], 
            $trans['cantidad'], 
            number_format($trans['monto_total'], 2)
        );
        $total_transacciones += $trans['monto_total'];
    }
    echo "  " . str_repeat('-', 75) . "\n";
    echo sprintf("  %-20s: %6s               = $%15s\n", 
        'TOTAL', 
        '', 
        number_format($total_transacciones, 2)
    );
    echo "\n";
    
    // 4. DESCUENTOS APLICADOS
    echo "4. ANÁLISIS DE DESCUENTOS\n";
    echo str_repeat('-', 80) . "\n";
    
    $sql = "
    SELECT 
        td.name as nombre_descuento,
        td.type as tipo,
        COUNT(*) as cantidad_aplicaciones,
        SUM(CAST(td.value AS DECIMAL(10,2))) as valor_total,
        AVG(CAST(td.value AS DECIMAL(10,2))) as valor_promedio,
        MIN(CAST(td.value AS DECIMAL(10,2))) as valor_minimo,
        MAX(CAST(td.value AS DECIMAL(10,2))) as valor_maxima
    FROM public.ticket_discount td
    INNER JOIN public.ticket t ON td.ticket_id = t.id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
    GROUP BY td.name, td.type
    ORDER BY cantidad_aplicaciones DESC
    LIMIT 20
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $descuentos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($descuentos) > 0) {
        echo sprintf("  %-25s %6s %8s %12s %12s %12s %12s\n", 
            'NOMBRE', 'TIPO', 'CANT', 'TOTAL', 'PROMEDIO', 'MIN', 'MAX'
        );
        echo "  " . str_repeat('-', 100) . "\n";
        
        foreach ($descuentos as $desc) {
            echo sprintf("  %-25s %6s %8d $%11s $%11s $%11s $%11s\n", 
                substr($desc['nombre_descuento'] ?? 'N/A', 0, 25),
                $desc['tipo'] ?? 'N/A',
                $desc['cantidad_aplicaciones'],
                number_format($desc['valor_total'], 2),
                number_format($desc['valor_promedio'], 2),
                number_format($desc['valor_minimo'], 2),
                number_format($desc['valor_maxima'], 2)
            );
        }
    } else {
        echo "  No se encontraron descuentos aplicados\n";
    }
    echo "\n";
    
    // 5. DESCUENTOS DEL 100%
    echo "5. DESCUENTOS DEL 100% (TICKETS COMPLETAMENTE DESCONTADOS)\n";
    echo str_repeat('-', 80) . "\n";
    
    $sql = "
    SELECT 
        t.id as ticket_id,
        t.create_date,
        t.closing_date,
        CAST(t.sub_total AS DECIMAL(10,2)) as subtotal,
        CAST(t.total_discount AS DECIMAL(10,2)) as descuento,
        CAST(t.total_price AS DECIMAL(10,2)) as total,
        t.paid,
        t.voided,
        td.name as nombre_descuento,
        td.value as valor_descuento
    FROM public.ticket t
    INNER JOIN public.ticket_discount td ON t.id = td.ticket_id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
      AND CAST(t.sub_total AS DECIMAL(10,2)) > 0
      AND CAST(t.total_price AS DECIMAL(10,2)) = 0
      AND CAST(t.total_discount AS DECIMAL(10,2)) >= CAST(t.sub_total AS DECIMAL(10,2))
    ORDER BY t.create_date
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $desc100 = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($desc100) > 0) {
        echo "  Total de tickets con descuento del 100%: " . count($desc100) . "\n";
        
        $total_valor_descontado = 0;
        echo "\n  Detalle:\n";
        echo sprintf("  %8s %20s %20s %12s %12s %8s %25s\n", 
            'TICKET', 'CREADO', 'CERRADO', 'SUBTOTAL', 'DESCUENTO', 'PAGADO', 'NOMBRE DESCUENTO'
        );
        echo "  " . str_repeat('-', 120) . "\n";
        
        foreach ($desc100 as $d) {
            echo sprintf("  %8d %20s %20s $%11s $%11s %8s %25s\n",
                $d['ticket_id'],
                $d['create_date'],
                $d['closing_date'] ?? 'NO CERRADO',
                number_format($d['subtotal'], 2),
                number_format($d['descuento'], 2),
                $d['paid'] ? 'SI' : 'NO',
                substr($d['nombre_descuento'] ?? 'N/A', 0, 25)
            );
            $total_valor_descontado += $d['subtotal'];
        }
        
        echo "  " . str_repeat('-', 120) . "\n";
        echo "  TOTAL VALOR DESCONTADO AL 100%: $" . number_format($total_valor_descontado, 2) . "\n";
    } else {
        echo "  No se encontraron tickets con descuento del 100%\n";
    }
    echo "\n";
    
    // 6. TICKETS PROBLEMÁTICOS
    echo "6. TICKETS PROBLEMÁTICOS (Cerrados no pagados, anulados con pagos, etc.)\n";
    echo str_repeat('-', 80) . "\n";
    
    // 6.1 Cerrados no pagados
    $sql = "
    SELECT 
        t.id,
        t.create_date,
        t.closing_date,
        CAST(t.total_price AS DECIMAL(10,2)) as total,
        CAST(t.total_discount AS DECIMAL(10,2)) as descuento,
        COUNT(pt.id) as num_transacciones,
        COALESCE(SUM(CAST(pt.amount AS DECIMAL(10,2))), 0) as total_pagado
    FROM public.ticket t
    LEFT JOIN public.transactions pt ON t.id = pt.ticket_id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
      AND t.closing_date IS NOT NULL
      AND t.paid = FALSE
      AND t.voided = FALSE
    GROUP BY t.id, t.create_date, t.closing_date, t.total_price, t.total_discount
    HAVING CAST(t.total_price AS DECIMAL(10,2)) > 0
    ORDER BY t.create_date
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $cerrados_no_pagados = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "  6.1 Tickets cerrados no pagados (con monto > 0):\n";
    if (count($cerrados_no_pagados) > 0) {
        echo "      Total: " . count($cerrados_no_pagados) . " tickets\n\n";
        echo sprintf("      %8s %20s %20s %12s %12s %8s %12s\n", 
            'TICKET', 'CREADO', 'CERRADO', 'TOTAL', 'DESCUENTO', 'TRANS', 'PAGADO'
        );
        echo "      " . str_repeat('-', 100) . "\n";
        
        $total_perdido = 0;
        foreach ($cerrados_no_pagados as $cnp) {
            echo sprintf("      %8d %20s %20s $%11s $%11s %8d $%11s\n",
                $cnp['id'],
                $cnp['create_date'],
                $cnp['closing_date'] ?? 'N/A',
                number_format($cnp['total'], 2),
                number_format($cnp['descuento'], 2),
                $cnp['num_transacciones'],
                number_format($cnp['total_pagado'], 2)
            );
            $total_perdido += $cnp['total'];
        }
        echo "      " . str_repeat('-', 100) . "\n";
        echo "      TOTAL POTENCIALMENTE PERDIDO: $" . number_format($total_perdido, 2) . "\n";
    } else {
        echo "      No se encontraron tickets cerrados no pagados\n";
    }
    echo "\n";
    
    // 6.2 Tickets anulados con transacciones
    $sql = "
    SELECT 
        t.id,
        t.create_date,
        t.closing_date as voided_time,
        CAST(t.total_price AS DECIMAL(10,2)) as total,
        COUNT(pt.id) as num_transacciones,
        SUM(CAST(pt.amount AS DECIMAL(10,2))) as total_transacciones,
        STRING_AGG(DISTINCT pt.payment_type, ', ') as tipos_pago
    FROM public.ticket t
    INNER JOIN public.transactions pt ON t.id = pt.ticket_id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
      AND t.voided = TRUE
    GROUP BY t.id, t.create_date, t.closing_date, t.total_price
    ORDER BY t.create_date
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $anulados_con_pagos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "  6.2 Tickets anulados con transacciones de pago:\n";
    if (count($anulados_con_pagos) > 0) {
        echo "      Total: " . count($anulados_con_pagos) . " tickets\n\n";
        echo sprintf("      %8s %20s %20s %12s %8s %12s %30s\n", 
            'TICKET', 'CREADO', 'ANULADO', 'TOTAL', 'TRANS', 'PAGADO', 'TIPOS PAGO'
        );
        echo "      " . str_repeat('-', 120) . "\n";
        
        foreach ($anulados_con_pagos as $acp) {
            echo sprintf("      %8d %20s %20s $%11s %8d $%11s %30s\n",
                $acp['id'],
                $acp['create_date'],
                $acp['voided_time'] ?? 'N/A',
                number_format($acp['total'], 2),
                $acp['num_transacciones'],
                number_format($acp['total_transacciones'], 2),
                substr($acp['tipos_pago'], 0, 30)
            );
        }
    } else {
        echo "      No se encontraron tickets anulados con transacciones\n";
    }
    echo "\n";
    
    // 7. DISCREPANCIAS IDENTIFICADAS
    echo "7. DISCREPANCIAS IDENTIFICADAS\n";
    echo str_repeat('-', 80) . "\n";
    
    $efectivo_reportado = $reportes['total_efectivo_reportado'] ?? 0;
    $tickets_reportados = $reportes['total_tickets_reportados'] ?? 0;
    $ventas_netas_reportadas = $reportes['total_ventas_netas_reportadas'] ?? 0;
    
    // Calcular efectivo real (solo CASH de tickets pagados no anulados)
    $sql = "
    SELECT 
        COALESCE(SUM(CAST(pt.amount AS DECIMAL(10,2))), 0) as efectivo_real
    FROM public.transactions pt
    INNER JOIN public.ticket t ON pt.ticket_id = t.id
    WHERE t.create_date::DATE BETWEEN :inicio AND :fin
      AND pt.payment_type = 'CASH'
      AND t.voided = FALSE
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $efectivo_real = $stmt->fetchColumn();
    
    $tickets_reales = $tickets['tickets_cerrados'];
    $ventas_netas_reales = $tickets['total_neto'];
    
    $diff_efectivo = $efectivo_reportado - $efectivo_real;
    $diff_tickets = $tickets_reportados - $tickets_reales;
    $diff_ventas = $ventas_netas_reportadas - $ventas_netas_reales;
    
    echo sprintf("  %-30s %20s %20s %20s\n", 'CONCEPTO', 'REPORTADO', 'REAL', 'DIFERENCIA');
    echo "  " . str_repeat('-', 95) . "\n";
    echo sprintf("  %-30s $%19s $%19s $%19s\n", 
        'Efectivo', 
        number_format($efectivo_reportado, 2),
        number_format($efectivo_real, 2),
        number_format($diff_efectivo, 2)
    );
    echo sprintf("  %-30s %20s %20s %20s\n", 
        'Tickets', 
        number_format($tickets_reportados),
        number_format($tickets_reales),
        number_format($diff_tickets)
    );
    echo sprintf("  %-30s $%19s $%19s $%19s\n", 
        'Ventas Netas', 
        number_format($ventas_netas_reportadas, 2),
        number_format($ventas_netas_reales, 2),
        number_format($diff_ventas, 2)
    );
    echo "\n";
    
    // 8. POSIBLES CAUSAS DE DISCREPANCIAS
    echo "8. ANÁLISIS DE POSIBLES CAUSAS\n";
    echo str_repeat('-', 80) . "\n";
    
    $total_desc_100 = 0;
    if (isset($total_valor_descontado)) {
        $total_desc_100 = $total_valor_descontado;
    }
    
    $total_cerrados_no_pagados = 0;
    if (isset($total_perdido)) {
        $total_cerrados_no_pagados = $total_perdido;
    }
    
    echo "  - Descuentos del 100%: $" . number_format($total_desc_100, 2) . "\n";
    echo "  - Tickets cerrados no pagados: $" . number_format($total_cerrados_no_pagados, 2) . "\n";
    echo "  - Tickets anulados con transacciones: " . count($anulados_con_pagos) . " tickets\n";
    echo "\n";
    
    echo "  RESUMEN:\n";
    echo "  Si ajustamos por descuentos del 100% y tickets cerrados no pagados:\n";
    $diferencia_ajustada = $diff_ventas - $total_desc_100 - $total_cerrados_no_pagados;
    echo "  Diferencia ajustada: $" . number_format($diferencia_ajustada, 2) . "\n";
    echo "\n";
}

?>
