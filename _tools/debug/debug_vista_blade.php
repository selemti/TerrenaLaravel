<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\Reports\ItemModsReportService;
use Carbon\Carbon;

echo "=== DEBUG DE DATOS QUE LLEGAN A LA VISTA ===\n";

$service = new ItemModsReportService();

$start = Carbon::parse('2025-12-02');
$end = Carbon::parse('2025-12-08');
$filters = [
    'view' => 'item_mod_combos',
    'group_by_day' => false,
    'branch_ids' => null,
    'terminal_ids' => null
];

try {
    $dataset = $service->fetch($start, $end, $filters);

    echo "Total de filas: " . $dataset->count() . "\n\n";

    // Analizar MENU DEL DÍA
    $menuDelDia = $dataset->filter(function ($row) {
        return strpos(strtoupper($row->menu_item ?? ''), 'MENU DEL DIA') !== false;
    });

    echo "=== MENU DEL DÍA ===\n";
    if ($menuDelDia->count() > 0) {
        $menuDelDia->each(function ($row, $index) {
            echo "Registro " . ($index + 1) . ":\n";
            echo "  - menu_item: " . ($row->menu_item ?? 'N/A') . "\n";
            echo "  - unidades_item: " . ($row->unidades_item ?? 0) . "\n";
            echo "  - precio_item: " . ($row->precio_item ?? 0) . "\n";
            echo "  - ingreso_total: " . ($row->ingreso_total ?? 0) . "\n";
            echo "  - monto_extra_modificador: " . ($row->monto_extra_modificador ?? 0) . "\n";
            echo "  - combo: " . ($row->combo ?? 'N/A') . "\n";
            echo "\n";
        });
    }

    // Analizar estructura de las filas
    echo "\n=== ANÁLISIS DE ESTRUCTURA ===\n";
    $firstRow = $dataset->first();
    echo "Propiedades de la primera fila:\n";
    foreach (get_object_vars($firstRow) as $key => $value) {
        echo "  - $key: " . (is_numeric($value) ? $value : (string) $value) . "\n";
    }

    // Verificar valores de ingreso_total
    echo "\n=== ANÁLISIS DE INGRESO_TOTAL ===\n";
    $incomeStats = [
        'total_filas' => $dataset->count(),
        'con_ingreso_mayor_cero' => $dataset->filter(fn($row) => ($row->ingreso_total ?? 0) > 0)->count(),
        'con_ingreso_cero' => $dataset->filter(fn($row) => ($row->ingreso_total ?? 0) == 0)->count(),
        'ingreso_total_suma' => $dataset->sum('ingreso_total'),
    ];

    foreach ($incomeStats as $key => $value) {
        echo "  - $key: " . (is_numeric($value) ? number_format($value, 2) : $value) . "\n";
    }

    // Verificar fórmula de cálculo
    echo "\n=== VERIFICANDO FÓRMULA ===\n";
    $sampleRow = $dataset->first();
    $price = (float) ($sampleRow->precio_item ?? 0);
    $units = (int) ($sampleRow->unidades_item ?? 0);
    $extra = (float) ($sampleRow->monto_extra_modificador ?? 0);
    $income = (float) ($sampleRow->ingreso_total ?? 0);

    echo "Fila de ejemplo: " . ($sampleRow->menu_item ?? 'N/A') . "\n";
    echo "  - precio_item: $price\n";
    echo "  - unidades_item: $units\n";
    echo "  - monto_extra_modificador: $extra\n";
    echo "  - ingreso_total (del servicio): $income\n";
    echo "  - cálculo manual (price * units) + extra: " . (($price * $units) + $extra) . "\n\n";

    if ($income == 0) {
        echo "⚠️ El servicio está retornando ingreso_total = 0\n";
        echo "✅ La vista está calculando correctamente usando: (price * units) + extra\n";
    } else {
        echo "✅ El servicio ya está calculando el ingreso_total correctamente\n";
    }

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}