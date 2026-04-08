<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Http\Request;

echo "Debug paso a paso del controller...\n";

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

    // Obtener los filtros como lo hace el controller
    $reflection = new ReflectionClass($controller);
    $method = $reflection->getMethod('resolveFilters');
    $method->setAccessible(true);

    echo "=== 1. RESOLVE FILTERS ===\n";
    [$start, $end, $filters] = $method->invoke($controller, $request);
    echo "Start: " . $start->format('Y-m-d') . "\n";
    echo "End: " . $end->format('Y-m-d') . "\n";
    echo "View: " . ($filters['view'] ?? 'null') . "\n";
    echo "Include empty: " . ($filters['include_empty'] ?? 'false') . "\n";

    echo "\n=== 2. VERIFICAR RAMA DEL CONTROLLER ===\n";
    $view = $filters['view'] ?? 'legacy';
    echo "View a procesar: '$view'\n";
    echo "¿Es diferente de 'legacy'? " . ($view !== 'legacy' ? 'SÍ' : 'NO') . "\n";

    if ($view !== 'legacy') {
        echo "ENTRAMOS A LA RAMA NUEVA (usando ItemModsReportService)\n";

        echo "\n=== 3. SERVICE FETCH ===\n";
        // Acceder al servicio por reflection
        $serviceProperty = $reflection->getProperty('service');
        $serviceProperty->setAccessible(true);
        $service = $serviceProperty->getValue($controller);

        $dataset = $service->fetch($start, $end, $filters);
        echo "Dataset después de fetch: " . $dataset->count() . " rows\n";

        echo "\n=== 4. SERVICE SUMMARIZE ===\n";
        $summary = $service->summarize($dataset, $view);
        echo "Summary calculado\n";
        var_dump($summary);

        echo "\n=== 5. EXTRACT BRANCHES ===\n";
        $extractMethod = $reflection->getMethod('extractBranchesFromNewData');
        $extractMethod->setAccessible(true);
        $branchCandidates = $extractMethod->invoke($controller, $dataset);
        echo "Branch candidates: " . $branchCandidates->count() . "\n";

        echo "\n=== 6. OBSERVED BRANCHES ===\n";
        $observedBranches = $branchCandidates
            ->pluck('key')
            ->merge($dataset->map(function ($row) {
                if (is_object($row)) {
                    return $row->branch_key ?? $row->branch ?? $row->sucursal ?? null;
                } elseif (is_array($row)) {
                    return $row['branch_key'] ?? $row['branch'] ?? $row['sucursal'] ?? null;
                }
                return null;
            }))
            ->filter()
            ->all();
        echo "Observed branches: " . json_encode($observedBranches) . "\n";

        echo "\n=== 7. BUILD BRANCH CONTEXT ===\n";
        $branches = $filters['branch_ids'] ?? [];
        $buildContextMethod = $reflection->getMethod('buildBranchContext');
        $buildContextMethod->setAccessible(true);
        [$branchColors, $branchOptions, $branchLabels] = $buildContextMethod->invoke($controller, $observedBranches, $branches);
        echo "Branch context construido\n";

        echo "\n=== 8. DATOS ANTES DE ENVIAR A VISTA ===\n";
        echo "Dataset count: " . $dataset->count() . "\n";
        echo "Primeras 3 filas del dataset:\n";
        foreach ($dataset->take(3) as $i => $row) {
            echo "Row " . ($i + 1) . ": " . json_encode($row) . "\n";
        }

        echo "\n=== 9. PREPARAR DATA PARA VIEW ===\n";
        $getTerminalMethod = $reflection->getMethod('getTerminalOptions');
        $getTerminalMethod->setAccessible(true);

        $viewData = [
            'active' => 'reportes',
            'view' => $view,
            'groupByDay' => $filters['group_by_day'] ?? false,
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $filters['terminal_ids'] ?? [],
            'branchOptions' => $branchOptions,
            'terminalOptions' => $getTerminalMethod->invoke($controller),
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'rows' => $dataset,  // <-- El dataset original
            'summary' => $summary,
            'includeEmpty' => $filters['include_empty'] ?? false,
            'generatedAt' => now('America/Mexico_City'),
        ];

        echo "Rows a enviar a vista: " . $viewData['rows']->count() . "\n";

        echo "\n=== 10. EMULAR CARGA DE VISTA ===\n";
        // Simular lo que haría la vista mods.blade.php
        $rows = $viewData['rows'];
        $view = $viewData['view'];

        echo "Rows en vista: " . $rows->count() . "\n";

        // Verificar si hay empanadas
        $empanadas = $rows->filter(function($row) {
            return stripos($row->menu_item ?? '', 'empanada') !== false;
        });

        echo "Empanadas encontradas: " . $empanadas->count() . "\n";
        echo "Total unidades empanadas: " . $empanadas->sum('unidades_item') . "\n";

        if ($empanadas->count() > 0) {
            echo "\nDetalle empanadas:\n";
            foreach ($empanadas as $emp) {
                echo "- Menu: " . ($emp->menu_item ?? 'null') . "\n";
                echo "  Combo: " . ($emp->combo ?? 'null') . "\n";
                echo "  Unidades: " . ($emp->unidades_item ?? 0) . "\n";
                echo "  Tickets: " . ($emp->tickets ?? 0) . "\n";
                echo "  Ingreso: $" . number_format($emp->ingreso_total ?? 0, 2) . "\n";
            }
        }

    } else {
        echo "ENTRAMOS A LA RAMA LEGACY\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}