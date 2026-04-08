<?php
require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Crear instancia del servicio
$service = new App\Services\Reports\ItemModsReportService();

// Convertir fechas
$startDate = Carbon\Carbon::createFromFormat('d/m/Y', '15/12/2025')->startOfDay();
$endDate = Carbon\Carbon::createFromFormat('d/m/Y', '15/12/2025')->endOfDay();

// Filtros para hoy
$filters = [
    'view' => 'item_mod_combos',
    'include_empty' => false
];

// Ejecutar el reporte
$result = $service->fetch($startDate, $endDate, $filters);

echo "=== REPORTE LARAVEL - 15/12/2025 ===\n";
echo "Total items procesados: " . $result->count() . "\n\n";

// Mostrar resumen por item
$resumen = [];
foreach ($result as $row) {
    $item = $row->menu_item;
    if (!isset($resumen[$item])) {
        $resumen[$item] = [
            'unidades' => 0,
            'tickets' => 0,
            'ingreso_base' => 0,
            'costo_mods' => 0,
            'ingreso_total' => 0
        ];
    }
    $resumen[$item]['unidades'] += $row->unidades_item;
    $resumen[$item]['tickets'] += $row->tickets;
    $resumen[$item]['ingreso_base'] += $row->ingreso_base;
    $resumen[$item]['costo_mods'] += $row->costo_modificadores;
    $resumen[$item]['ingreso_total'] += $row->ingreso_total;
}

echo "RESUMEN POR ITEM:\n";
foreach ($resumen as $item => $data) {
    echo sprintf(
        "%-12s: %d unidades | %d tickets | $%6.2f base | $%6.2f mods | $%6.2f total\n",
        $item,
        $data['unidades'],
        $data['tickets'],
        $data['ingreso_base'],
        $data['costo_mods'],
        $data['ingreso_total']
    );
}

echo "\n=== TOTALES ===\n";
$total_unidades = array_sum(array_column($resumen, 'unidades'));
$total_tickets = array_sum(array_column($resumen, 'tickets'));
$total_base = array_sum(array_column($resumen, 'ingreso_base'));
$total_mods = array_sum(array_column($resumen, 'costo_mods'));
$total_ventas = array_sum(array_column($resumen, 'ingreso_total'));

echo sprintf(
    "UNIDADES: %d | TICKETS: %d | BASE: $%6.2f | MODS: $%6.2f | TOTAL: $%6.2f\n",
    $total_unidades,
    $total_tickets,
    $total_base,
    $total_mods,
    $total_ventas
);