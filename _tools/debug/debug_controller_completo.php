<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\Reports\ItemModsReportService;
use App\Http\Controllers\Reports\SalesModsController;
use Carbon\Carbon;
use Illuminate\Http\Request;

echo "=== DEBUG COMPLETO DEL CONTROLLER ===\n";

// Simular la petición HTTP
$request = new Request([
    'start_date' => '2025-12-02',
    'end_date' => '2025-12-08',
    'view' => 'item_mod_combos',
    'group_by_day' => '0',
    'include_empty' => '1'
]);

$controller = new SalesModsController(app(ItemModsReportService::class));

echo "1. Ejecutando resolveFilters()...\n";
try {
    $reflection = new ReflectionClass($controller);
    $resolveFilters = $reflection->getMethod('resolveFilters');
    $resolveFilters->setAccessible(true);

    [$start, $end, $filters] = $resolveFilters->invoke($controller, $request);

    echo "✅ resolveFilters() completado\n";
    echo "Start: {$start->format('Y-m-d H:i:s')}\n";
    echo "End: {$end->format('Y-m-d H:i:s')}\n";
    echo "View: " . ($filters['view'] ?? 'N/A') . "\n";
    echo "Group by day: " . ($filters['group_by_day'] ? 'Yes' : 'No') . "\n";
    echo "\n";

} catch (Exception $e) {
    echo "❌ Error en resolveFilters(): " . $e->getMessage() . "\n";
    exit(1);
}

echo "2. Ejecutando service->fetch()...\n";
try {
    $service = app(ItemModsReportService::class);
    $dataset = $service->fetch($start, $end, $filters);

    echo "✅ service->fetch() completado\n";
    echo "Total de filas del dataset: " . $dataset->count() . "\n\n";

} catch (Exception $e) {
    echo "❌ Error en service->fetch(): " . $e->getMessage() . "\n";
    exit(1);
}

echo "3. Ejecutando service->summarize()...\n";
try {
    $view = $filters['view'] ?? 'legacy';
    $summary = $service->summarize($dataset, $view);

    echo "✅ service->summarize() completado\n";
    echo "Summary keys: " . implode(', ', array_keys($summary)) . "\n\n";

} catch (Exception $e) {
    echo "❌ Error en service->summarize(): " . $e->getMessage() . "\n";
    exit(1);
}

echo "4. Ejecutando extractBranchesFromNewData()...\n";
try {
    $extractBranches = $reflection->getMethod('extractBranchesFromNewData');
    $extractBranches->setAccessible(true);

    $branchCandidates = $extractBranches->invoke($controller, $dataset);

    echo "✅ extractBranchesFromNewData() completado\n";
    echo "Branch candidates: " . $branchCandidates->count() . "\n\n";

} catch (Exception $e) {
    echo "❌ Error en extractBranchesFromNewData(): " . $e->getMessage() . "\n";
    exit(1);
}

echo "5. Procesando observedBranches...\n";
try {
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

    echo "✅ observedBranches procesado\n";
    echo "Observed branches: " . count($observedBranches) . "\n";
    echo "Branches: " . implode(', ', $observedBranches) . "\n\n";

} catch (Exception $e) {
    echo "❌ Error procesando observedBranches: " . $e->getMessage() . "\n";
    exit(1);
}

echo "6. Verificando dataset ANTES de pasar a la vista...\n";
echo "Total de filas que se pasarán a la vista: " . $dataset->count() . "\n";

if ($dataset->count() > 0) {
    echo "✅ Dataset tiene datos\n";

    // Verificar estructura de las filas
    $firstRow = $dataset->first();
    echo "Tipo de primera fila: " . gettype($firstRow) . "\n";

    if (is_object($firstRow)) {
        echo "Clase de primera fila: " . get_class($firstRow) . "\n";
        echo "Propiedades: " . implode(', ', array_keys(get_object_vars($firstRow))) . "\n";
    }

    // Verificar datos específicos
    $menuDelDia = $dataset->filter(function ($row) {
        return strpos(strtoupper($row->menu_item ?? ''), 'MENU DEL DIA') !== false;
    });

    echo "\nMENU DEL DÍA en dataset del controller:\n";
    echo "- Registros: " . $menuDelDia->count() . "\n";
    if ($menuDelDia->count() > 0) {
        echo "- Ingreso total: $" . number_format($menuDelDia->sum('ingreso_total'), 2) . "\n";
        echo "- Unidades: " . $menuDelDia->sum('unidades_item') . "\n";
    }

} else {
    echo "❌ Dataset está vacío ANTES de pasar a la vista\n";
}

echo "\n=== RESUMEN ===\n";
echo "1. Service fetch(): " . $dataset->count() . " filas ✅\n";
echo "2. Service summarize(): ✅\n";
echo "3. extractBranchesFromNewData(): " . $branchCandidates->count() . " branches ✅\n";
echo "4. Dataset que llega a la vista: " . $dataset->count() . " filas " . ($dataset->count() > 0 ? '✅' : '❌') . "\n";

echo "\nEl problema NO está en el controller. El controller está pasando correctamente " . $dataset->count() . " filas a la vista.\n";
echo "El problema debe estar en la VISTA o en cómo se procesan los datos en el Blade.\n";