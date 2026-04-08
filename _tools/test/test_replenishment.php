<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$service = app(\App\Services\Replenishment\ReplenishmentService::class);

$resultado = $service->generateDailySuggestions([
    'sucursal_id'   => 1,
    'almacen_id'    => null,
    'algoritmo'     => 'MIN_MAX',
    'dias_analisis' => 30,
    'dry_run'       => true,
]);

echo "\n=== RESULTADO DE PRUEBA REPLENISHMENT ===\n";
print_r($resultado);
echo "\n";
