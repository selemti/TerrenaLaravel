<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

function q($sql) {
    return \Illuminate\Support\Facades\DB::select($sql);
}

try {
    // 1. Identificar items
    $items = q("SELECT id, nombre FROM selemti.items ORDER BY id");

    // 2. Mapear mov_inv
    $mov_inv = q("
        SELECT m.* 
        FROM selemti.mov_inv m 
        WHERE m.item_id IN (SELECT id FROM selemti.items) 
        ORDER BY m.item_id
    ");

    // 3. Mapear recepciones
    $recepcion = q("
        SELECT rd.* 
        FROM selemti.recepcion_det rd 
        WHERE rd.item_id IN (SELECT id FROM selemti.items) 
        ORDER BY rd.item_id
    ");

    // 4. Detectar FKs
    $fks = q("
        SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name 
        FROM information_schema.table_constraints tc 
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name 
        JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name 
        WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'items' 
        AND tc.table_schema = 'selemti'
        ORDER BY tc.table_name
    ");

    // 5. Validar si existen registros activos en las tablas con FK
    $fk_counts = [];
    foreach ($fks as $fk) {
        try {
            $count = q("SELECT COUNT(*) as c FROM selemti." . $fk->table_name)[0]->c;
            $fk_counts[$fk->table_name] = $count;
        } catch (\Exception $e) {
            $fk_counts[$fk->table_name] = "ERROR_AL_CONTAR";
        }
    }

    $output = json_encode([
        'items' => $items,
        'mov_inv' => $mov_inv,
        'recepcion' => $recepcion,
        'fks' => $fks,
        'fk_counts' => $fk_counts
    ], JSON_PRETTY_PRINT);

    file_put_contents('forensic_audit_result.json', $output);
    echo "Done! File saved.";
} catch (\Exception $ex) {
    echo "ERROR GLOBAL: " . $ex->getMessage();
}
