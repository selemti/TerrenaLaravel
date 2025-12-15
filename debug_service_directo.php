<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\Reports\ItemModsReportService;
use Carbon\Carbon;

echo "=== DEBUG DIRECTO DEL SERVICE ===\n";

$service = new ItemModsReportService();

$start = Carbon::parse('2025-12-02');
$end = Carbon::parse('2025-12-08');
$filters = [
    'view' => 'item_mod_combos',
    'group_by_day' => false,
    'branch_ids' => null,
    'terminal_ids' => null
];

echo "Fechas: {$start->format('Y-m-d')} - {$end->format('Y-m-d')}\n";
echo "Vista: item_mod_combos\n\n";

try {
    $dataset = $service->fetch($start, $end, $filters);

    echo "✅ Service fetch() completado\n";
    echo "Total de filas retornadas: " . $dataset->count() . "\n\n";

    if ($dataset->count() > 0) {
        echo "Primeras 3 filas:\n";
        $dataset->take(3)->each(function ($row, $index) {
            echo "Fila " . ($index + 1) . ":\n";
            echo "  - menu_item: " . ($row->menu_item ?? 'N/A') . "\n";
            echo "  - mod_group: " . ($row->mod_group ?? 'N/A') . "\n";
            echo "  - mod_name: " . ($row->mod_name ?? 'N/A') . "\n";
            echo "  - unidades_item: " . ($row->unidades_item ?? 0) . "\n";
            echo "  - ingreso_total: " . ($row->ingreso_total ?? 0) . "\n";
            echo "\n";
        });

        // Buscar "MENU DEL DÍA"
        $menuDelDia = $dataset->filter(function ($row) {
            return strpos(strtoupper($row->menu_item ?? ''), 'MENU DEL DIA') !== false;
        });

        echo "\n=== BÚSQUEDA DE MENU DEL DÍA ===\n";
        echo "Menús del día encontrados: " . $menuDelDia->count() . "\n";

        if ($menuDelDia->count() > 0) {
            echo "Total ingreso MENU DEL DÍA: $" . number_format($menuDelDia->sum('ingreso_total'), 2) . "\n";
            echo "Total unidades MENU DEL DÍA: " . $menuDelDia->sum('unidades_item') . "\n";
        }

        // Buscar "EMPANADA"
        $empanadas = $dataset->filter(function ($row) {
            return strpos(strtoupper($row->menu_item ?? ''), 'EMPANADA') !== false;
        });

        echo "\n=== BÚSQUEDA DE EMPANADA ===\n";
        echo "Empanadas encontradas: " . $empanadas->count() . "\n";

        if ($empanadas->count() > 0) {
            echo "Total unidades EMPANADA: " . $empanadas->sum('unidades_item') . "\n";
            echo "Total ingreso EMPANADA: $" . number_format($empanadas->sum('ingreso_total'), 2) . "\n";
        }

        // Verificar estructura de datos
        echo "\n=== ANÁLISIS DE DATOS ===\n";
        echo "Items con ingresos > 0: " . $dataset->filter(fn($row) => ($row->ingreso_total ?? 0) > 0)->count() . "\n";
        echo "Items con ingresos = 0: " . $dataset->filter(fn($row) => ($row->ingreso_total ?? 0) == 0)->count() . "\n";
        echo "Items sin modificadores: " . $dataset->filter(fn($row) => empty($row->mod_name))->count() . "\n";

    } else {
        echo "❌ El dataset está vacío\n";
    }

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}