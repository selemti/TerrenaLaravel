<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Test del controller directamente
use Illuminate\Http\Request;

echo "Test directo del controller...\n";

try {
    $request = new Request([
        'start_date' => '2025-12-02',
        'end_date' => '2025-12-08',
        'view' => 'item_mod_combos',
        'include_empty' => '1'
    ]);

    $controller = new App\Http\Controllers\Reports\SalesModsController(
        new App\Services\Reports\ItemModsReportService()
    );

    // Debug de resolveFilters
    $reflection = new ReflectionClass($controller);
    $method = $reflection->getMethod('resolveFilters');
    $method->setAccessible(true);

    [$start, $end, $filters] = $method->invoke($controller, $request);

    echo "=== DEBUG FILTERS ===\n";
    echo "Start: " . $start->format('Y-m-d') . "\n";
    echo "End: " . $end->format('Y-m-d') . "\n";
    echo "View: " . ($filters['view'] ?? 'null') . "\n";
    echo "Include empty: " . ($filters['include_empty'] ?? 'false') . "\n";
    echo "Branch IDs: " . json_encode($filters['branch_ids'] ?? []) . "\n";

    try {
        echo "=== ANTES DE LLAMAR A SERVICE ===\n";

        $service = new App\Services\Reports\ItemModsReportService();
        echo "Servicio creado\n";

        $dataset = $service->fetch($start, $end, $filters);
        echo "Dataset fetched: " . $dataset->count() . " rows\n";

        $summary = $service->summarize($dataset, $filters['view']);
        echo "Summary calculated\n";

        echo "=== DATASET PRIMERAS 3 FILAS ===\n";
        foreach ($dataset->take(3) as $index => $row) {
            echo "Row " . ($index + 1) . ": " . json_encode($row) . "\n";
        }

        $response = $controller->show($request);
        $data = $response->getData();

        echo "=== RESPUESTA DEL CONTROLLER ===\n";
        echo "Vista: " . ($data->view ?? 'null') . "\n";
        echo "Total rows: " . count($data->rows ?? []) . "\n";

    } catch (Exception $e) {
        echo "ERROR EN SERVICE: " . $e->getMessage() . "\n";
        echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
        echo "Trace: " . $e->getTraceAsString() . "\n";

        $response = $controller->show($request);
        $data = $response->getData();

        echo "=== RESPUESTA DESPUÉS DEL ERROR ===\n";
        echo "Vista: " . ($data->view ?? 'null') . "\n";
        echo "Total rows: " . count($data->rows ?? []) . "\n";
    }

    // Filtrar empanadas
    $empanadas = collect($data->rows ?? [])->filter(function($row) {
        return stripos($row->menu_item ?? '', 'empanada') !== false;
    });

    echo "Total empanadas en controller: " . $empanadas->count() . "\n";
    echo "Total unidades empanadas: " . $empanadas->sum('unidades_item') . "\n";

    echo "\n=== DETALLE EMPANADAS ===\n";
    foreach ($empanadas as $emp) {
        echo "Menu: " . ($emp->menu_item ?? 'null') . "\n";
        echo "Combo: " . ($emp->combo ?? 'null') . "\n";
        echo "Unidades: " . ($emp->unidades_item ?? 0) . "\n";
        echo "Tickets: " . ($emp->tickets ?? 0) . "\n";
        echo "Ingreso: $" . number_format($emp->ingreso_total ?? 0, 2) . "\n";
        echo "--------------------\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
}