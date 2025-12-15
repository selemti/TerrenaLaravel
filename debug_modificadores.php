<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\Reports\ItemModsReportService;
use Carbon\Carbon;

echo "=== DEBUG ESPECÍFICO DE MODIFICADORES ===\n";

$service = new ItemModsReportService();

$start = Carbon::parse('2025-12-02');
$end = Carbon::parse('2025-12-08');
$filters = [
    'view' => 'item_mod_combos',
    'group_by_day' => false,
    'branch_ids' => null,
    'terminal_ids' => null
];

$dataset = $service->fetch($start, $end, $filters);

echo "Total de filas: " . $dataset->count() . "\n\n";

// 1. Verificar cuántos items Tienen modificadores vs Sin modificadores
$conMods = $dataset->filter(fn($row) => !empty($row->combo) && $row->combo !== 'Sin modificadores');
$sinMods = $dataset->filter(fn($row) => empty($row->combo) || $row->combo === 'Sin modificadores');

echo "=== ANÁLISIS DE MODIFICADORES ===\n";
echo "Items CON modificadores: " . $conMods->count() . "\n";
echo "Items SIN modificadores: " . $sinMods->count() . "\n\n";

// 2. Verificar EMPANADA específicamente
$empanadas = $dataset->filter(function ($row) {
    return strpos(strtoupper($row->menu_item ?? ''), 'EMPANADA') !== false;
});

echo "=== ANÁLISIS DE EMPANADA ===\n";
echo "Registros de EMPANADA: " . $empanadas->count() . "\n\n";

if ($empanadas->count() > 0) {
    echo "Detalles de EMPANADA:\n";
    $empanadas->each(function ($row, $index) {
        echo "\nRegistro " . ($index + 1) . ":\n";
        echo "  - menu_item: " . ($row->menu_item ?? 'N/A') . "\n";
        echo "  - combo: " . ($row->combo ?? 'N/A') . "\n";
        echo "  - unidades_item: " . ($row->unidades_item ?? 0) . "\n";
        echo "  - selecciones_modificador: " . ($row->selecciones_modificador ?? 0) . "\n";
        echo "  - monto_extra_modificador: $" . number_format(($row->monto_extra_modificador ?? 0), 2) . "\n";
        echo "  - tickets: " . ($row->tickets ?? 0) . "\n";
        echo "  - mods_distintos: " . ($row->mods_distintos ?? 0) . "\n";
    });
}

// 3. Verificar items con más modificadores
echo "\n=== TOP 10 ITEMS CON MÁS MODIFICADORES ===\n";
$topMods = $dataset->sortByDesc('monto_extra_modificador')->take(10);

foreach ($topMods as $index => $row) {
    if (($row->monto_extra_modificador ?? 0) > 0) {
        echo ($index + 1) . ". " . ($row->menu_item ?? 'N/A') . "\n";
        echo "   - Combo: " . ($row->combo ?? 'N/A') . "\n";
        echo "   - Unidades: " . ($row->unidades_item ?? 0) . "\n";
        echo "   - Extra en mods: $" . number_format(($row->monto_extra_modificador ?? 0), 2) . "\n";
        echo "   - Selecciones: " . ($row->selecciones_modificador ?? 0) . "\n\n";
    }
}

// 4. Verificar distribución de modificadores
echo "\n=== DISTRIBUCIÓN DE MODIFICADORES ===\n";
$modsGrouped = $dataset->groupBy('combo');

$topCombos = $modsGrouped->map(function ($group) {
    return [
        'total_unidades' => $group->sum('unidades_item'),
        'total_extra' => $group->sum('monto_extra_modificador'),
        'tickets' => $group->sum('tickets'),
        'items_count' => $group->count(),
    ];
})->sortByDesc('total_extra')->take(10);

foreach ($topCombos as $combo => $stats) {
    echo $combo . "\n";
    echo "  - Unidades totales: " . number_format($stats['total_unidades']) . "\n";
    echo "  - Extra total: $" . number_format($stats['total_extra'], 2) . "\n";
    echo "  - Tickets: " . $stats['tickets'] . "\n";
    echo "  - Items diferentes: " . $stats['items_count'] . "\n\n";
}

// 5. Verificar el método fetchItemModifierCombos directamente
echo "\n=== VERIFICANDO MÉTODO fetchItemModifierCombos ===\n";

// Intentar ejecutar el método directamente por reflexión
$reflection = new ReflectionClass($service);
$method = $reflection->getMethod('fetchItemModifierCombos');
$method->setAccessible(true);

try {
    $rawData = $method->invoke($service, $start, $end, false, null, null);
    echo "Datos crudos del método: " . $rawData->count() . " filas\n\n";

    // Verificar primeros registros con modificadores
    $conModsRaw = $rawData->filter(fn($row) => !empty($row->modificador));
    echo "Registros con modificador no nulo: " . $conModsRaw->count() . "\n";

    if ($conModsRaw->count() > 0) {
        echo "\nPrimeros 5 registros con modificadores:\n";
        $conModsRaw->take(5)->each(function ($row) {
            echo "  - Item: " . ($row->menu_item ?? 'N/A') . "\n";
            echo "  - Modificador: " . ($row->modificador ?? 'N/A') . "\n";
            echo "  - Grupo: " . ($row->mod_group ?? 'N/A') . "\n";
            echo "  - Cantidad: " . ($row->cantidad_modificador ?? 0) . "\n";
            echo "  - Precio: $" . number_format(($row->precio_modificador ?? 0), 2) . "\n\n";
        });
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}