<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "Debug: Items SIN modificadores en el rango 2-8 diciembre\n\n";

$start = Carbon::parse('2025-12-02');
$end = Carbon::parse('2025-12-08');

// Consulta directa para ver items sin modificadores
$query = DB::connection('pgsql')
    ->table('public.ticket as t')
    ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
    ->leftJoin('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
    ->whereBetween('t.closing_date', [
        $start->format('Y-m-d 00:00:00'),
        $end->format('Y-m-d 23:59:59')
    ])
    ->where('t.paid', true)
    ->where('t.voided', false)
    ->selectRaw("
        ti.item_name,
        COUNT(DISTINCT ti.id) as ticket_items_count,
        SUM(COALESCE(ti.item_count, 0)) as total_unidades,
        SUM(ti.total_price) as total_ventas,
        COUNT(tim.id) as modificadores_count,
        CASE WHEN COUNT(tim.id) = 0 THEN 'SIN MODS' ELSE 'CON MODS' END as tipo
    ")
    ->groupBy('ti.item_name')
    ->orderBy('total_unidades', 'desc')
    ->limit(20);

$results = $query->get();

echo "Items más vendidos (con y sin modificadores):\n";
echo str_repeat("=", 120) . "\n";
printf("%-40s %10s %12s %12s %15s\n", "ITEM", "TICKETS", "UNIDADES", "VENTAS", "TIPO");
echo str_repeat("-", 120) . "\n";

foreach ($results as $row) {
    printf("%-40s %10d %12d %12.2f %15s\n",
        substr($row->item_name, 0, 40),
        $row->ticket_items_count,
        $row->total_unidades,
        $row->total_ventas,
        $row->tipo
    );
}

echo "\n" . str_repeat("=", 120) . "\n";

// Contar específicamente items sin modificadores
$sinMods = $results->filter(fn($row) => $row->tipo === 'SIN MODS');
$conMods = $results->filter(fn($row) => $row->tipo === 'CON MODS');

echo "RESUMEN:\n";
echo "Items CON modificadores: " . $conMods->count() . " diferentes\n";
echo "Items SIN modificadores: " . $sinMods->count() . " diferentes\n";

// Verificar específicamente MENU DEL DÍA y EMPANADA
$menuDia = $results->firstWhere('item_name', 'MENU DEL DÍA');
$empanada = $results->filter(fn($row) => stripos($row->item_name, 'EMPANADA') !== false);

echo "\nDETALLE ESPECÍFICO:\n";
if ($menuDia) {
    echo "MENU DEL DÍA: {$menuDia->total_unidades} unidades, \${$menuDia->total_ventas}\n";
} else {
    echo "MENU DEL DÍA: NO ENCONTRADO\n";
}

echo "\nEMPANADAS:\n";
foreach ($empanada as $emp) {
    echo "- {$emp->item_name}: {$emp->total_unidades} unidades, \${$emp->total_ventas} ({$emp->tipo})\n";
}