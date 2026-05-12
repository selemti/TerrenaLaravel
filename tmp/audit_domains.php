<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$domainTables = [
    'Inventario / Insumos' => [
        'public.inventory_item',
        'selemti.insumo',
        'selemti.items',
        'selemti.insumo_presentacion'
    ],
    'Unidades' => [
        'public.inventory_unit',
        'selemti.cat_unidades',
        'selemti.unidades_medida'
    ],
    'Proveedores' => [
        'public.inventory_vendor',
        'selemti.proveedor',
        'selemti.cat_proveedores'
    ],
    'Precios' => [
        'selemti.item_vendor_prices',
        'selemti.vendor_price', // No existía antes, verificar
        'selemti.hist_cost_insumo'
    ],
    'Existencias / Lotes' => [
        'selemti.inventory_snapshot',
        'selemti.inventory_batch',
        'selemti.lote',
        'selemti.v_stock_actual' // Vista
    ],
    'Recetas' => [
        'public.recepie',
        'selemti.receta',
        'selemti.receta_cab',
        'selemti.receta_det',
        'selemti.receta_insumo'
    ],
    'Movimientos' => [
        'public.inventory_transaction',
        'selemti.mov_inv',
        'selemti.inv_consumo_pos'
    ],
    'Producción' => [
        'selemti.production_orders',
        'selemti.prod_cab'
    ],
    'Mermas' => [
        'selemti.merma',
        'selemti.inventory_wastes',
        'selemti.perdida_log'
    ]
];

echo "AUDIT DE COBERTURA DE DATOS (DETALLADO POR DOMINIO)\n";
echo str_repeat("=", 50) . "\n";

foreach ($domainTables as $domain => $tables) {
    echo "\n[$domain]\n";
    foreach ($tables as $table) {
        try {
            $count = DB::connection('pgsql')->table($table)->count();
            echo "  " . str_pad($table, 35) . ": " . $count . "\n";
        } catch (\Exception $e) {
            // Ver si es una vista
            try {
                $count = DB::connection('pgsql')->select("SELECT COUNT(*) as c FROM $table")[0]->c;
                echo "  " . str_pad($table, 35) . ": " . $count . " (VIEW/SELECT)\n";
            } catch (\Exception $e2) {
                echo "  " . str_pad($table, 35) . ": [NO EXISTE]\n";
            }
        }
    }
}
