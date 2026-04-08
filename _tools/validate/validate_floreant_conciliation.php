<?php
/**
 * Validation script for "Conciliación Floreant" mode
 * Should produce exactly: Items $631.00, Modifiers $50.00, Discounts $8.80, Net $622.20
 */

require_once __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

echo "=== VALIDACIÓN: MODO CONCILIACIÓN FLOREANT ===\n\n";

try {
    // Connect to PostgreSQL
    $pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Expected totals from JasperReports PDF - actual Floreant values
    $expected = [
        'items' => 681.00,
        'discounts' => 76.80,
        'net' => 604.20
    ];

    echo "FLOREANT ESPERADO:\n";
    echo "==================\n";
    echo "Items: \${$expected['items']}\n";
    echo "Discounts: \${$expected['discounts']}\n";
    echo "Net: \${$expected['net']}\n\n";

    // Execute exact Conciliación Floreant calculation
    $sql = "
    SELECT
        -- Items: total_price from ticket_item (includes base items + modifiers)
        SUM(ti.total_price) as items_total,

        -- Discounts: ticket discounts only (matches JasperReports)
        (SELECT SUM(total_discount) FROM public.ticket
         WHERE DATE(folio_date) = '2025-12-16' AND paid = true AND voided = false) as discounts_total,

        -- Net: should match transaction totals
        (SELECT SUM(total_price) FROM public.ticket
         WHERE DATE(folio_date) = '2025-12-16' AND paid = true AND voided = false) as net_total

    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE
        DATE(t.folio_date) = '2025-12-16'
        AND t.paid = true
        AND t.voided = false  -- INCLUDE ALL PAID TICKETS
    ";

    $stmt = $pdo->query($sql);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    $actual = [
        'items' => round($result['items_total'], 2),
        'discounts' => round($result['discounts_total'], 2),
        'net' => round($result['net_total'], 2)
    ];

    echo "CONCILIACIÓN FLOREANT ACTUAL:\n";
    echo "=============================\n";
    echo "Items: \${$actual['items']}\n";
    echo "Discounts: \${$actual['discounts']}\n";
    echo "Net: \${$actual['net']}\n\n";

    // Validation
    echo "VALIDACIÓN:\n";
    echo "============\n";

    $checks = [
        'items' => abs($actual['items'] - $expected['items']) < 0.01,
        'discounts' => abs($actual['discounts'] - $expected['discounts']) < 0.01,
        'net' => abs($actual['net'] - $expected['net']) < 0.01
    ];

    foreach ($checks as $metric => $match) {
        echo $metric . ": " . ($match ? "✅ EXACTO (\${$actual[$metric]})" : "❌ DIFERENTE (\${$actual[$metric]} vs \${$expected[$metric]})") . "\n";
    }

    // Overall validation
    $allMatch = array_values($checks);
    if (in_array(false, $allMatch, true)) {
        echo "\n❌ VALIDACIÓN FALLIDA: No todos los montos coinciden exactamente\n";
    } else {
        echo "\n🎉 VALIDACIÓN EXITOSA: Todos los montos coinciden exactamente con Floreant!\n";
    }

    // Additional validation: Check which tickets are included/excluded
    echo "\n\nTICKETS INCLUIDOS (total_price > 0):\n";
    echo "=====================================\n";

    $sqlTickets = "
    SELECT
        t.id,
        t.folio_date,
        t.total_price as ticket_total,
        COUNT(ti.id) as item_count,
        SUM(ti.item_price * ti.item_count) as items_total
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE
        DATE(t.folio_date) = '2025-12-16'
        AND t.paid = true
        AND t.voided = false  -- INCLUDE ALL PAID TICKETS (even those with 100% discount)
    GROUP BY t.id, t.folio_date, t.total_price
    ORDER BY t.id
    ";

    $stmt = $pdo->query($sqlTickets);
    $tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $ticketsSum = 0;
    foreach ($tickets as $ticket) {
        echo "Ticket {$ticket['id']}: Total=\${$ticket['ticket_total']}, Items=\${$ticket['items_total']}\n";
        $ticketsSum += $ticket['items_total'];
    }

    echo "\nSuma total de tickets incluidos: \${$ticketsSum}\n";

    $pdo = null;

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}