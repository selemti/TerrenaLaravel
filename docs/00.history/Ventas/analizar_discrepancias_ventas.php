<?php

/**
 * ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS
 * Agosto, Septiembre y Octubre 2025
 *
 * Versión CORREGIDA con nombres correctos de tablas y columnas
 */

require __DIR__.'/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$host = $_ENV['DB_HOST'];
$port = $_ENV['DB_PORT'];
$dbname = $_ENV['DB_DATABASE'];
$user = $_ENV['DB_USERNAME'];
$password = str_replace('"', '', $_ENV['DB_PASSWORD']);

try {
    $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ,
    ]);

    echo "═══════════════════════════════════════════════════════════════════════════\n";
    echo "  ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS - AGO/SEP/OCT 2025\n";
    echo "═══════════════════════════════════════════════════════════════════════════\n\n";

    $meses = [
        ['nombre' => 'AGOSTO', 'inicio' => '2025-08-01', 'fin' => '2025-08-31'],
        ['nombre' => 'SEPTIEMBRE', 'inicio' => '2025-09-01', 'fin' => '2025-09-30'],
        ['nombre' => 'OCTUBRE', 'inicio' => '2025-10-01', 'fin' => '2025-10-31'],
    ];

    foreach ($meses as $mes) {
        analizarMes($pdo, $mes['nombre'], $mes['inicio'], $mes['fin']);
    }

} catch (PDOException $e) {
    echo 'ERROR: '.$e->getMessage()."\n";
    exit(1);
}

function analizarMes($pdo, $nombreMes, $fechaInicio, $fechaFin)
{
    echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "  MES: $nombreMes ($fechaInicio al $fechaFin)\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

    // 1. RESUMEN GENERAL DE TICKETS
    echo "┌─ 1. RESUMEN GENERAL DE TICKETS ─────────────────────────────────────┐\n";
    $query = '
        SELECT 
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN paid = TRUE THEN 1 END) as tickets_pagados,
            COUNT(CASE WHEN paid = FALSE OR paid IS NULL THEN 1 END) as tickets_no_pagados,
            COUNT(CASE WHEN voided = TRUE THEN 1 END) as tickets_anulados,
            COUNT(CASE WHEN closing_date IS NOT NULL THEN 1 END) as tickets_cerrados,
            COUNT(CASE WHEN closing_date IS NULL THEN 1 END) as tickets_abiertos
        FROM public.ticket
        WHERE folio_date BETWEEN :inicio AND :fin
    ';
    $resumen = $pdo->prepare($query);
    $resumen->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $r = $resumen->fetch();

    printf("  Total de Tickets:        %s\n", number_format($r->total_tickets));
    printf("  ├─ Pagados:              %s (%.1f%%)\n", number_format($r->tickets_pagados),
        $r->total_tickets > 0 ? ($r->tickets_pagados / $r->total_tickets * 100) : 0);
    printf("  ├─ No Pagados:           %s (%.1f%%)\n", number_format($r->tickets_no_pagados),
        $r->total_tickets > 0 ? ($r->tickets_no_pagados / $r->total_tickets * 100) : 0);
    printf("  ├─ Anulados:             %s (%.1f%%)\n", number_format($r->tickets_anulados),
        $r->total_tickets > 0 ? ($r->tickets_anulados / $r->total_tickets * 100) : 0);
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 2. VENTAS POR MÉTODO DE PAGO (TODOS)
    echo "┌─ 2. VENTAS POR MÉTODO DE PAGO (Transacciones reales) ──────────────┐\n";
    $query = '
        SELECT 
            tr.payment_type,
            COUNT(DISTINCT t.id) as cantidad_tickets,
            COUNT(tr.id) as cantidad_transacciones,
            SUM(tr.amount) as total_monto,
            AVG(tr.amount) as promedio_monto
        FROM public.ticket t
        INNER JOIN public.transactions tr ON t.id = tr.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
        GROUP BY tr.payment_type
        ORDER BY total_monto DESC
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $pagos = $stmt->fetchAll();

    $totalGeneral = array_sum(array_column($pagos, 'total_monto'));

    if (count($pagos) > 0) {
        foreach ($pagos as $p) {
            $pct = $totalGeneral > 0 ? ($p->total_monto / $totalGeneral * 100) : 0;
            printf("  %-12s │ Tickets: %5d │ Trans: %5d │ Total: $%13s │ %5.1f%%\n",
                $p->payment_type,
                $p->cantidad_tickets,
                $p->cantidad_transacciones,
                number_format($p->total_monto, 2),
                $pct
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        printf("  TOTAL COBRADO (Todos los métodos): $%s\n", number_format($totalGeneral, 2));
    } else {
        echo "  No se encontraron transacciones\n";
        $totalGeneral = 0;
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 3. ANÁLISIS DETALLADO DE DESCUENTOS AL 100%
    echo "┌─ 3. DESCUENTOS AL 100% (Detallado) ─────────────────────────────────┐\n";
    $query = '
        SELECT 
            t.id,
            t.create_date,
            t.closing_date,
            t.paid,
            t.voided,
            SUM(ti.item_quantity * ti.item_price) as subtotal_original,
            SUM(ti.discount) as total_descuento,
            SUM(ti.total_price) as total_final,
            COUNT(ti.id) as num_items
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
            AND ti.discount > 0
        GROUP BY t.id, t.create_date, t.closing_date, t.paid, t.voided
        HAVING SUM(ti.total_price) = 0 
            OR (SUM(ti.discount) / NULLIF(SUM(ti.item_quantity * ti.item_price), 0) * 100) >= 99
        ORDER BY subtotal_original DESC
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $desc100 = $stmt->fetchAll();

    $totalDesc100 = 0;
    if (count($desc100) > 0) {
        printf("  %-8s │ %-19s │ %-9s │ Subtotal │ Descuento │ Final\n", 'Ticket', 'Fecha', 'Estado');
        echo "  ────────┼─────────────────────┼───────────┼──────────┼───────────┼────────\n";

        foreach ($desc100 as $d) {
            $totalDesc100 += $d->total_descuento;
            $est = [];
            if ($d->paid) {
                $est[] = 'PAGADO';
            }
            if (! $d->paid) {
                $est[] = 'NO PAGADO';
            }
            if ($d->voided) {
                $est[] = 'ANULADO';
            }

            printf("  %8d │ %19s │ %-9s │ $%7.2f │ $%8.2f │ $%5.2f\n",
                $d->id,
                substr($d->create_date, 0, 19),
                substr(implode(',', $est), 0, 9),
                $d->subtotal_original,
                $d->total_descuento,
                $d->total_final
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        printf("  Tickets con desc. 100%%: %d │ Monto total descontado: $%s\n",
            count($desc100), number_format($totalDesc100, 2));
    } else {
        echo "  ✓ No se encontraron descuentos del 100%\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 4. TODOS LOS DESCUENTOS
    echo "┌─ 4. RESUMEN DE TODOS LOS DESCUENTOS ────────────────────────────────┐\n";
    $query = '
        SELECT 
            COUNT(DISTINCT t.id) as tickets_con_descuento,
            SUM(ti.discount) as total_descuentos,
            AVG(ti.discount) as promedio_descuento,
            MAX(ti.discount) as descuento_maximo
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
            AND ti.discount > 0
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $desc = $stmt->fetch();

    printf("  Tickets con descuentos:   %s\n", number_format($desc->tickets_con_descuento));
    printf("  Total descuentos:         $%s\n", number_format($desc->total_descuentos, 2));
    printf("  ├─ Descuentos 100%%:       $%s (%.1f%%)\n",
        number_format($totalDesc100, 2),
        $desc->total_descuentos > 0 ? ($totalDesc100 / $desc->total_descuentos * 100) : 0);
    printf("  └─ Otros descuentos:      $%s (%.1f%%)\n",
        number_format($desc->total_descuentos - $totalDesc100, 2),
        $desc->total_descuentos > 0 ? (($desc->total_descuentos - $totalDesc100) / $desc->total_descuentos * 100) : 0);
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 5. TICKETS NO PAGADOS CON MONTO
    echo "┌─ 5. TICKETS NO PAGADOS (Con monto pendiente) ──────────────────────┐\n";
    $query = '
        SELECT 
            t.id,
            t.create_date,
            t.closing_date,
            t.voided,
            SUM(ti.total_price) as total
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
            AND (t.paid = FALSE OR t.paid IS NULL)
        GROUP BY t.id, t.create_date, t.closing_date, t.voided
        HAVING SUM(ti.total_price) > 0
        ORDER BY total DESC
        LIMIT 30
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $noPag = $stmt->fetchAll();

    $totalNoPagado = 0;
    if (count($noPag) > 0) {
        printf("  %-8s │ %-19s │ %-10s │ Monto\n", 'Ticket', 'Creado', 'Estado');
        echo "  ────────┼─────────────────────┼────────────┼─────────\n";

        foreach ($noPag as $np) {
            $totalNoPagado += $np->total;
            $est = $np->voided ? 'ANULADO' : ($np->closing_date ? 'CERRADO' : 'ABIERTO');
            printf("  %8d │ %19s │ %-10s │ $%8.2f\n",
                $np->id,
                substr($np->create_date, 0, 19),
                $est,
                $np->total
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        printf("  Total no pagado (primeros 30): $%s\n", number_format($totalNoPagado, 2));
    } else {
        echo "  ✓ No se encontraron tickets no pagados con monto > 0\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 6. DISCREPANCIAS: MONTO PAGADO VS MONTO TICKET
    echo "┌─ 7. DISCREPANCIAS: Monto Pagado vs Monto Ticket ───────────────────┐\n";
    $query = '
        SELECT 
            t.id,
            t.paid,
            t.voided,
            SUM(ti.total_price) as total_ticket,
            COALESCE(SUM(tr.amount), 0) as total_pagado,
            COALESCE(SUM(tr.amount), 0) - SUM(ti.total_price) as diferencia
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
        GROUP BY t.id, t.paid, t.voided
        HAVING ABS(COALESCE(SUM(tr.amount), 0) - SUM(ti.total_price)) > 0.01
        ORDER BY ABS(COALESCE(SUM(tr.amount), 0) - SUM(ti.total_price)) DESC
        LIMIT 30
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $discrep = $stmt->fetchAll();

    $sumaDif = 0;
    if (count($discrep) > 0) {
        printf("  %-8s │ Ticket │ Pagado │ Diferencia │ Estado\n", 'Ticket');
        echo "  ────────┼────────┼────────┼────────────┼──────────────\n";

        foreach ($discrep as $disc) {
            $sumaDif += $disc->diferencia;
            $est = [];
            if ($disc->paid) {
                $est[] = 'PAGADO';
            }
            if ($disc->voided) {
                $est[] = 'ANULADO';
            }
            $estadoStr = implode(',', $est) ?: 'PENDIENTE';

            printf("  %8d │ $%5.2f │ $%5.2f │ $%9.2f │ %s\n",
                $disc->id,
                $disc->total_ticket,
                $disc->total_pagado,
                $disc->diferencia,
                $estadoStr
            );
        }
        echo "  ────────────────────────────────────────────────────────────────────\n";
        printf("  Suma de diferencias (primeras 30): $%s\n", number_format($sumaDif, 2));
    } else {
        echo "  ✓ No se encontraron discrepancias significativas\n";
    }
    echo "└────────────────────────────────────────────────────────────────────┘\n\n";

    // 8. RESUMEN FINAL DEL MES
    echo "┌─ 8. RESUMEN FINAL DEL MES ──────────────────────────────────────────┐\n";

    $query = '
        SELECT 
            SUM(ti.item_quantity * ti.item_price) as ventas_brutas,
            SUM(ti.discount) as descuentos_totales,
            SUM(ti.total_price) as ventas_netas,
            COUNT(DISTINCT t.id) as total_tickets
        FROM public.ticket t
        INNER JOIN public.ticket_item ti ON t.id = ti.ticket_id
        WHERE t.folio_date BETWEEN :inicio AND :fin
    ';
    $stmt = $pdo->prepare($query);
    $stmt->execute(['inicio' => $fechaInicio, 'fin' => $fechaFin]);
    $tot = $stmt->fetch();

    printf("  Ventas Brutas:                    $%s\n", number_format($tot->ventas_brutas, 2));
    printf("  Descuentos Totales:               $%s\n", number_format($tot->descuentos_totales, 2));
    printf("  ├─ Descuentos 100%%:               $%s\n", number_format($totalDesc100, 2));
    printf("  └─ Otros descuentos:              $%s\n", number_format($tot->descuentos_totales - $totalDesc100, 2));
    printf("  Ventas Netas (Brutas - Desc):     $%s\n", number_format($tot->ventas_netas, 2));
    printf("  Total de Tickets:                 %s\n", number_format($tot->total_tickets));
    echo "  ────────────────────────────────────────────────────────────────────\n";
    printf("  Total Cobrado (todos métodos):    $%s\n", number_format($totalGeneral, 2));

    $dif = $tot->ventas_netas - $totalGeneral;
    printf('  Diferencia (Netas - Cobrado):     $%s', number_format($dif, 2));

    if (abs($dif) > 0.01) {
        $pct = ($dif / $tot->ventas_netas * 100);
        printf(" (%.2f%%)\n", $pct);

        echo "\n";
        if ($dif > 0) {
            echo "  ⚠️  HAY MÁS VENTAS REGISTRADAS QUE DINERO COBRADO\n";
            echo "      Causas probables:\n";
            echo "      • Tickets cerrados pero no pagados\n";
            echo "      • Descuentos al 100% registrados como ventas\n";
            echo "      • Tickets anulados después del cierre\n";
        } else {
            echo "  ⚠️  HAY MÁS DINERO COBRADO QUE VENTAS REGISTRADAS\n";
            echo "      Causas probables:\n";
            echo "      • Transacciones duplicadas\n";
            echo "      • Propinas o cargos no incluidos en items\n";
        }
    } else {
        echo " ✓\n";
    }

    echo "└────────────────────────────────────────────────────────────────────┘\n";
}

echo "\n═══════════════════════════════════════════════════════════════════════════\n";
echo "  ANÁLISIS COMPLETADO\n";
echo "═══════════════════════════════════════════════════════════════════════════\n";
