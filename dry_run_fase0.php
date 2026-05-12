<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$queries = [
    'items_a_borrar' => 'SELECT COUNT(*) AS count FROM selemti.items',
    'total_receta_cab' => 'SELECT COUNT(*) AS count FROM selemti.receta_cab',
    'total_receta_det' => 'SELECT COUNT(*) AS count FROM selemti.receta_det',
    'total_mov_inv' => 'SELECT COUNT(*) AS count FROM selemti.mov_inv',
    'total_recepcion_det' => 'SELECT COUNT(*) AS count FROM selemti.recepcion_det'
];

$res = [];
foreach ($queries as $key => $sql) {
    try {
        $result = \Illuminate\Support\Facades\DB::selectOne($sql);
        $res[$key] = $result->count;
    } catch (\Exception $e) {
        $res[$key] = 'ERROR: ' . $e->getMessage();
    }
}

echo json_encode($res, JSON_PRETTY_PRINT);
