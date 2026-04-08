<?php
require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Simular los filtros para hoy
$filters = [
    'view' => 'item_mod_combos',
    'group_by_day' => false,
    'branch_ids' => [],
    'terminal_ids' => [],
    'include_empty' => true
];

// Crear instancia del servicio
$service = new App\Services\Reports\ItemModsReportService();

// Convertir fechas
$startDate = Carbon\Carbon::createFromFormat('d/m/Y', '15/12/2025')->startOfDay();
$endDate = Carbon\Carbon::createFromFormat('d/m/Y', '15/12/2025')->endOfDay();

// Ejecutar el reporte
$dataset = $service->fetch($startDate, $endDate, $filters);
$summary = $service->summarize($dataset, 'item_mod_combos');

echo "=== REPORTE V2.0 - 15/12/2025 ===\n";
echo "Dataset rows: " . $dataset->count() . "\n\n";

echo "=== DATOS ESTRUCTURA V2 ===\n";

// Agrupar por categoría → grupo → item como lo hace la vista v2
$agrupadoPorCategoria = [];
foreach ($dataset as $row) {
    $categoria = $row->categoria ?? 'Sin categoría';
    $grupo = $row->grupo_menu ?? 'Sin grupo';
    $item = $row->menu_item;

    if (!isset($agrupadoPorCategoria[$categoria])) {
        $agrupadoPorCategoria[$categoria] = [
            'nombre' => $categoria,
            'grupos' => [],
            'totales' => (object) [
                'base' => 0,
                'mods' => 0,
                'total' => 0,
                'unidades' => 0,
                'tickets' => 0,
                'items' => 0,
                'combos' => 0
            ]
        ];
    }

    if (!isset($agrupadoPorCategoria[$categoria]['grupos'][$grupo])) {
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo] = [
            'nombre' => $grupo,
            'items' => [],
            'totales' => (object) [
                'base' => 0,
                'mods' => 0,
                'total' => 0,
                'unidades' => 0,
                'tickets' => 0,
                'items' => 0,
                'combos' => 0
            ]
        ];
    }

    // Agregar item
    $itemKey = $item . '|' . ($row->combo ?? '');
    if (!isset($agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey])) {
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey] = [
            'row' => $row,
            'combos' => []
        ];
    }

    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey]['combos'][] = $row;

    // Actualizar totales
    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->base += $row->ingreso_base;
    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->mods += $row->costo_modificadores;
    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->total += $row->ingreso_total;
    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->unidades += $row->unidades_item;
    $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->tickets += $row->tickets;

    $agrupadoPorCategoria[$categoria]['totales']->base += $row->ingreso_base;
    $agrupadoPorCategoria[$categoria]['totales']->mods += $row->costo_modificadores;
    $agrupadoPorCategoria[$categoria]['totales']->total += $row->ingreso_total;
    $agrupadoPorCategoria[$categoria]['totales']->unidades += $row->unidades_item;
    $agrupadoPorCategoria[$categoria]['totales']->tickets += $row->tickets;
}

// Mostrar estructura jerárquica
foreach ($agrupadoPorCategoria as $categoria) {
    echo "📁 {$categoria['nombre']}\n";
    echo "   └── {$categoria['totales']->unidades}u | {$categoria['totales']->tickets}t | Base: \${$categoria['totales']->base} | Mods: +\${$categoria['totales']->mods} | Total: \${$categoria['totales']->total}\n";

    foreach ($categoria['grupos'] as $grupo) {
        echo "       📂 {$grupo['nombre']}\n";
        echo "           └── {$grupo['totales']->unidades}u | {$grupo['totales']->tickets}t | Base: \${$grupo['totales']->base} | Mods: +\${$grupo['totales']->mods} | Total: \${$grupo['totales']->total}\n";

        foreach ($grupo['items'] as $itemKey => $itemData) {
            $mainRow = $itemData['row'];
            echo "               🥙 {$mainRow->menu_item}\n";
            echo "                  └── {$mainRow->unidades_item}u | {$mainRow->tickets}t | Base: \${$mainRow->ingreso_base} | Mods: +\${$mainRow->costo_modificadores} | Total: \${$mainRow->ingreso_total} | {$mainRow->mods_distintos} mods\n";

            foreach ($itemData['combos'] as $comboIndex => $combo) {
                echo "                     • Combinación " . ($comboIndex + 1) . ": {$combo->combo}\n";
            }
        }
    }
    echo "\n";
}

echo "=== TOTALES GENERALES ===\n";
$totalBase = $dataset->sum('ingreso_base');
$totalMods = $dataset->sum('costo_modificadores');
$totalTotal = $dataset->sum('ingreso_total');
$totalUnidades = $dataset->sum('unidades_item');
$totalTickets = $dataset->sum('tickets');
$totalItems = $dataset->unique('menu_item')->count();
$totalCombos = $dataset->unique('combo')->count();

echo "Ventas Totales: \${$totalTotal} (Base: \${$totalBase} + Mods: +\${$totalMods})\n";
echo "Tickets: {$totalTickets} | Unidades: {$totalUnidades} | Ítems: {$totalItems} | Combos: {$totalCombos}\n";
echo "Porcentaje mods: " . round($totalTotal > 0 ? ($totalMods / $totalTotal) * 100 : 0, 1) . "%\n";