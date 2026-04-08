<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\Reports\ItemModsReportService;
use Carbon\Carbon;
use Illuminate\Support\Str;

echo "=== SIMULACIÓN EXACTA DE LA VISTA ===\n";

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

echo "Dataset recibido: " . $dataset->count() . " filas\n\n";

// Replicar la lógica de la vista mods-table-combos.blade.php
$grouped = $dataset->groupBy(fn($row) => $row->categoria ?? 'N/D')
    ->map(function ($catGroup) {
        return $catGroup->groupBy(fn($row) => $row->grupo_menu ?? 'N/D');
    })
    ->sortKeys();

echo "Categorías encontradas: " . $grouped->keys()->implode(', ') . "\n\n";

// Buscar MENU DEL DÍA
$menuDelDiaFound = false;
foreach ($grouped as $categoria => $grupos) {
    foreach ($grupos as $grupoMenu => $items) {
        $itemsByMenu = $items->groupBy(fn($row) => $row->menu_item ?? '—')
            ->sortKeys()
            ->map(function ($list, $itemName) {
                $units = (int) $list->sum('unidades_item');
                $extra = (float) $list->sum('monto_extra_modificador');
                $income = (float) $list->sum('ingreso_total');
                $price = (float) ($list->first()->precio_item ?? 0);

                // Si el income del servicio es 0 pero hay extra, usar el cálculo tradicional
                if ($income == 0 && $extra > 0) {
                    $income = round(($price * $units) + $extra, 2);
                }

                $avg = $units > 0 ? round($income / $units, 2) : 0;

                $combos = $list->sortByDesc('unidades_item')->values();
                $combos = $combos->values();

                return [
                    'name' => $itemName,
                    'units' => $units,
                    'extra' => $extra,
                    'price' => $price,
                    'income' => $income,
                    'avg_price' => $avg,
                    'combos' => $combos,
                ];
            });

        // Verificar si MENU DEL DÍA está en este grupo
        if (isset($itemsByMenu['MENU DEL DIA '])) {
            $menuDelDiaFound = true;
            $data = $itemsByMenu['MENU DEL DIA '];

            echo "¡MENU DEL DÍA ENCONTRADO!\n";
            echo "  - Categoría: $categoria\n";
            echo "  - Grupo: $grupoMenu\n";
            echo "  - Unidades: " . number_format($data['units']) . "\n";
            echo "  - Precio unitario: $" . number_format($data['price'], 2) . "\n";
            echo "  - Ingreso total: $" . number_format($data['income'], 2) . "\n";
            echo "  - Precio promedio: $" . number_format($data['avg_price'], 2) . "\n";
            echo "  - Extra en modificadores: $" . number_format($data['extra'], 2) . "\n";
            echo "  - Número de combos: " . count($data['combos']) . "\n\n";

            if (count($data['combos']) > 0) {
                echo "Combos de MENU DEL DÍA:\n";
                foreach ($data['combos'] as $index => $combo) {
                    echo "  Combo " . ($index + 1) . ":\n";
                    echo "    - Combo: " . ($combo->combo ?? 'N/A') . "\n";
                    echo "    - Unidades: " . ($combo->unidades_item ?? 0) . "\n";
                    echo "    - Tickets: " . ($combo->tickets ?? 0) . "\n";
                    echo "    - Selecciones mods: " . ($combo->selecciones_modificador ?? 0) . "\n";
                    echo "    - Monto extra: $" . number_format(($combo->monto_extra_modificador ?? 0), 2) . "\n";
                }
            }
        }
    }
}

if (!$menuDelDiaFound) {
    echo "❌ MENU DEL DÍA NO ENCONTRADO en los datos procesados\n\n";

    // Buscar si existe con otro nombre
    echo "Buscando items que contengan 'MENU' en el nombre:\n";
    $menuItems = $dataset->filter(function ($row) {
        return strpos(strtoupper($row->menu_item ?? ''), 'MENU') !== false;
    });

    if ($menuItems->count() > 0) {
        echo "Items con MENU encontrados: " . $menuItems->count() . "\n";
        $menuItems->take(5)->each(function ($row) {
            echo "  - " . ($row->menu_item ?? '') . " | Unidades: " . ($row->unidades_item ?? 0) . " | Ingreso: $" . number_format(($row->ingreso_total ?? 0), 2) . "\n";
        });
    } else {
        echo "No se encontraron items con 'MENU' en el nombre\n";
    }
}

echo "\n=== ESTADÍSTICAS FINALES ===\n";
echo "Total filas originales: " . $dataset->count() . "\n";
echo "Total categorías: " . $grouped->count() . "\n";
echo "Total items procesados: " . $grouped->flatten(1)->count() . "\n";

// Verificar si hay items con income = 0
$zeroIncomeItems = $dataset->filter(fn($row) => ($row->ingreso_total ?? 0) == 0);
echo "Items con income = 0: " . $zeroIncomeItems->count() . "\n";

if ($zeroIncomeItems->count() > 0 && $zeroIncomeItems->count() < 10) {
    echo "Items con income = 0 (primeros 10):\n";
    $zeroIncomeItems->take(10)->each(function ($row) {
        echo "  - " . ($row->menu_item ?? '') . " | Unidades: " . ($row->unidades_item ?? 0) . " | Precio: $" . ($row->precio_item ?? 0) . "\n";
    });
}