<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tables = [
    'selemti.inventory_item', 
    'selemti.uom', 
    'selemti.uom_conversion', 
    'selemti.vendor', 
    'selemti.vendor_price', 
    'selemti.storage_location', 
    'selemti.inventory_batch', 
    'selemti.inventory_transaction', 
    'selemti.recipe', 
    'selemti.recipe_version', 
    'selemti.recipe_version_item', 
    'selemti.production_order', 
    'selemti.inventory_waste', 
    'selemti.inventory_count', 
    'selemti.inventory_transfer', 
    'selemti.purchase_order',
    'public.menu_item'
];

echo "AUDIT DE COBERTURA DE DATOS\n";
echo str_repeat("-", 40) . "\n";

foreach ($tables as $table) {
    try {
        $count = DB::connection('pgsql')->table($table)->count();
        echo str_pad($table, 30) . ": " . $count . "\n";
    } catch (\Exception $e) {
        echo str_pad($table, 30) . ": ERROR - " . substr($e->getMessage(), 0, 50) . "...\n";
    }
}

// Analizar cobertura de recetas en productos vendibles
$vendediblesConReceta = DB::connection('pgsql')
    ->table('public.menu_item as mi')
    ->join('selemti.recipe as r', 'r.menu_item_id', '=', 'mi.id')
    ->count();

$totalVendedibles = DB::connection('pgsql')->table('public.menu_item')->count();

echo str_repeat("-", 40) . "\n";
echo "COBERTURA DE RECETAS\n";
echo "Productos con Receta: $vendediblesConReceta / $totalVendedibles\n";

// Analizar precios de proveedor
$itemsConPrecio = DB::connection('pgsql')
    ->table('selemti.inventory_item as ii')
    ->join('selemti.vendor_price as vp', 'vp.inventory_item_id', '=', 'ii.id')
    ->distinct('ii.id')
    ->count();

echo "Items con Precio Proveedor: $itemsConPrecio / " . DB::connection('pgsql')->table('selemti.inventory_item')->count() . "\n";
