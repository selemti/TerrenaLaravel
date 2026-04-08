<?php
/**
 * Test the fixed "Conciliación Floreant" mode implementation
 */

require_once __DIR__ . '/vendor/autoload.php';

use App\Services\Reports\ItemModsReportService;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "=== VALIDACIÓN: CONCILIACIÓN FLOREANT (CORREGIDO) ===\n\n";

try {
    // Expected totals from Floreant PDF
    $expected = [
        'items' => 631.00,
        'modifiers' => 50.00,
        'discounts' => 8.80,
        'net' => 622.20
    ];

    echo "FLOREANT ESPERADO:\n";
    echo "==================\n";
    echo "Items: \${$expected['items']}\n";
    echo "Modifiers: \${$expected['modifiers']}\n";
    echo "Discounts: \${$expected['discounts']}\n";
    echo "Net: \${$expected['net']}\n\n";

    // Create service instance
    $service = new ItemModsReportService();

    // Test for 2025-12-16 with floreant_conciliation mode
    $start = Carbon::create(2025, 12, 16)->startOfDay();
    $end = Carbon::create(2025, 12, 16)->endOfDay();
    $filters = [
        'view' => 'item_mod_combos',
        'sales_mode' => 'floreant_conciliation',
        'include_empty' => true,
    ];

    // Get data using the service
    $dataset = $service->fetch($start, $end, $filters);
    $summary = $service->summarize($dataset, 'item_mod_combos', 'floreant_conciliation');

    echo "CONCILIACIÓN FLOREANT ACTUAL (CORREGIDO):\n";
    echo "=======================================\n";
    echo "Items: \${$summary['items_total'] ?? 'N/A'}\n";
    echo "Modifiers: \${$summary['modifiers_total'] ?? 'N/A'}\n";
    echo "Discounts: \${$summary['discounts_total'] ?? 'N/A'}\n";
    echo "Net: \${$summary['net_total'] ?? 'N/A'}\n\n";

    // Validation
    echo "VALIDACIÓN:\n";
    echo "============\n";

    $actual = [
        'items' => round($summary['items_total'] ?? 0, 2),
        'modifiers' => round($summary['modifiers_total'] ?? 0, 2),
        'discounts' => round($summary['discounts_total'] ?? 0, 2),
        'net' => round($summary['net_total'] ?? 0, 2)
    ];

    $checks = [
        'items' => abs($actual['items'] - $expected['items']) < 0.01,
        'modifiers' => abs($actual['modifiers'] - $expected['modifiers']) < 0.01,
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

    // Show raw data for debugging
    echo "\n\nDATOS CRUDOS PARA DEBUGGING:\n";
    echo "============================\n";
    echo "Total registros: {$dataset->count()}\n";

    $itemsTotal = 0;
    $modifiersTotal = 0;
    foreach ($dataset as $row) {
        $itemsTotal += $row->ingreso_base ?? 0;
        $modifiersTotal += $row->costo_modificadores ?? 0;
    }
    echo "Items total desde crudos: \${$itemsTotal}\n";
    echo "Modifiers total desde crudos: \${$modifiersTotal}\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}