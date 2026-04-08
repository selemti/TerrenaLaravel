<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Http\Request;

echo "Debug: Buscar MENU DEL DÍA y Empanadas en el servicio\n\n";

$request = new Request([
    'start_date' => '2025-12-02',
    'end_date' => '2025-12-08',
    'view' => 'item_mod_combos',
    'include_empty' => '1'
]);

$service = new App\Services\Reports\ItemModsReportService();

// Obtener filtros
$filters = [
    'view' => 'item_mod_combos',
    'group_by_day' => false,
    'branch_ids' => [],
    'terminal_ids' => [],
    'include_empty' => true
];

// Llamar al servicio
$start = \Carbon\Carbon::parse('2025-12-02');
$end = \Carbon\Carbon::parse('2025-12-08');

$dataset = $service->fetch($start, $end, $filters);

echo "Total de filas retornadas: " . $dataset->count() . "\n\n";

// Buscar MENU DEL DÍA (varias variantes)
$menuDelDia = $dataset->filter(function($row) {
    return stripos($row->menu_item ?? '', 'MENU DEL') !== false ||
           stripos($row->menu_item ?? '', 'MENU DEL DIA') !== false ||
           stripos($row->menu_item ?? '', 'MENU DIA') !== false ||
           stripos($row->menu_item ?? '', 'MENÚ DEL') !== false ||
           stripos($row->menu_item ?? '', 'MENÚ DIA') !== false ||
           stripos($row->menu_item ?? '', 'MENU DEL') !== false ||
           strpos($row->menu_item ?? '', 'MENU DEL DÍA') !== false;
});

echo "=== BÚSQUEDA DE MENU DEL DÍA ===\n";
echo "Coincidencias encontradas: " . $menuDelDia->count() . "\n";

if ($menuDelDia->isNotEmpty()) {
    foreach ($menuDelDia as $item) {
        echo "- '" . $item->menu_item . "': " . $item->unidades_item . " unidades, $" . number_format($item->ingreso_total, 2) . "\n";
    }
} else {
    // Mostrar items que contienen "MENU"
    echo "\nItems con 'MENU' en el nombre:\n";
    $withMenu = $dataset->filter(function($row) {
        return stripos($row->menu_item ?? '', 'MENU') !== false;
    });
    foreach ($withMenu->take(5) as $item) {
        echo "- '" . $item->menu_item . "'\n";
    }
}

echo "\n=== BÚSQUEDA DE EMPANADAS ===\n";
$empanadas = $dataset->filter(function($row) {
    return stripos($row->menu_item ?? '', 'EMPANADA') !== false ||
           stripos($row->menu_item ?? '', 'EMPANADA') !== false ||
           strpos($row->menu_item ?? '', 'EMPANADA') !== false;
});

echo "Coincidencias encontradas: " . $empanadas->count() . "\n";
$totalUnidades = 0;
$totalIngreso = 0;

foreach ($empanadas as $emp) {
    echo "- '" . $emp->menu_item . "': " . $emp->unidades_item . " unidades, $" . number_format($emp->ingreso_total, 2) . " (" . ($emp->combo ?? 'N/A') . ")\n";
    $totalUnidades += $emp->unidades_item ?? 0;
    $totalIngreso += $emp->ingreso_total ?? 0;
}

echo "\nTOTAL EMPANADAS: " . $totalUnidades . " unidades, $" . number_format($totalIngreso, 2) . "\n";

// Mostrar los primeros 20 items para ver qué hay
echo "\n=== PRIMEROS 20 ITEMS DEL DATASET ===\n";
foreach ($dataset->take(20) as $i => $row) {
    printf("%2d. %-40s %5d u %10.2f %s\n",
        $i+1,
        substr($row->menu_item ?? '', 0, 40),
        $row->unidades_item ?? 0,
        $row->ingreso_total ?? 0,
        $row->combo ?? ''
    );
}