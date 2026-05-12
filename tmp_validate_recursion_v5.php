<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

// Configure pos_pg connection
$base = config('database.connections.pgsql');
$host = env('POS_DB_HOST', env('DB_HOST', '127.0.0.1'));
if ($host === '127.0.0.1') $host = '172.24.240.1';
$base['host'] = $host;
$base['port'] = env('POS_DB_PORT', env('DB_PORT', '5432'));
$base['database'] = env('POS_DB_DATABASE', env('DB_DATABASE', 'pos'));
$base['username'] = env('POS_DB_USERNAME', env('DB_USERNAME', 'postgres'));
$base['password'] = env('POS_DB_PASSWORD', env('DB_PASSWORD', ''));
config(['database.connections.pos_pg' => $base]);

function q($sql, $params = []) {
    return DB::connection('pgsql')->select($sql, $params);
}

try {
    DB::connection('pgsql')->beginTransaction();

    // 1. SETUP TEST DATA
    $p1 = 'REC-TEST-BBASE';
    $p2 = 'REC-TEST-SUB';
    $i1 = 'ITEM-TEST-INSUMO';
    $cat = 'CAT-ABARR';

    // Clean up
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_det WHERE receta_version_id IN (SELECT id FROM selemti.receta_version WHERE receta_id IN (?, ?))", [$p1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_version WHERE receta_id IN (?, ?)", [$p1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_cab WHERE id IN (?, ?)", [$p1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.items WHERE id IN (?, ?)", [$i1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.mov_inv WHERE item_id IN (?, ?)", [$p2, $i1]);

    // Create Items
    DB::connection('pgsql')->table('selemti.items')->insert([
        ['id' => $i1, 'nombre' => 'Insumo de Prueba', 'unidad_medida' => 'KG', 'perishable' => false, 'activo' => true, 'categoria_id' => $cat],
        ['id' => $p2, 'nombre' => 'Sub-receta de Prueba', 'unidad_medida' => 'PZ', 'perishable' => false, 'activo' => true, 'categoria_id' => $cat]
    ]);

    // Create Recipe Cab
    DB::connection('pgsql')->table('selemti.receta_cab')->insert([
        ['id' => $p1, 'nombre_plato' => 'Plato Base Prueba', 'codigo_plato_pos' => '99999', 'porciones_standard' => 1, 'activo' => true],
        ['id' => $p2, 'nombre_plato' => 'Sub-receta Prueba', 'codigo_plato_pos' => 'MOD-99999', 'porciones_standard' => 1, 'activo' => true]
    ]);

    // Create Versions
    $v1 = DB::connection('pgsql')->table('selemti.receta_version')->insertGetId([
        'receta_id' => $p1, 'version' => 1, 'version_publicada' => true, 'fecha_efectiva' => now()->toDateString(), 'created_at' => now()
    ]);
    $v2 = DB::connection('pgsql')->table('selemti.receta_version')->insertGetId([
        'receta_id' => $p2, 'version' => 1, 'version_publicada' => true, 'fecha_efectiva' => now()->toDateString(), 'created_at' => now()
    ]);

    // Create Relations
    DB::connection('pgsql')->table('selemti.receta_det')->insert([
        ['receta_version_id' => $v1, 'item_id' => $p2, 'cantidad' => 2, 'unidad_medida' => 'PZ', 'orden' => 1], 
        ['receta_version_id' => $v2, 'item_id' => $i1, 'cantidad' => 0.5, 'unidad_medida' => 'KG', 'orden' => 1]
    ]);

    // Create a Mock Ticket
    $ticketId = 123456789;
    DB::connection('pos_pg')->unprepared("INSERT INTO public.ticket (id, ticket_id, create_date, sucursal_id) VALUES ($ticketId, 'T-99', now(), 'SUR') ON CONFLICT DO NOTHING");
    DB::connection('pos_pg')->table('public.ticket_item')->updateOrInsert(
        ['ticket_id' => $ticketId, 'item_id' => 99999],
        ['item_name' => 'Test Base', 'item_quantity' => 1, 'item_price' => 100, 'item_tax' => 0]
    );

    // -------------------------------------------------------------------------
    // TEST 1: NO STOCK OF SUB-RECETA
    // -------------------------------------------------------------------------
    echo "--- TEST 1: NO STOCK (Expected: Explosion to Insumo) ---\n";
    DB::connection('pgsql')->delete("DELETE FROM selemti.inv_consumo_pos WHERE ticket_id = ?", [$ticketId]);
    DB::connection('pgsql')->statement("SELECT selemti.fn_expandir_consumo_ticket(?)", [$ticketId]);
    
    $results = q("SELECT * FROM selemti.inv_consumo_pos_det WHERE consumo_id IN (SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = ?)", [$ticketId]);
    if (count($results) == 0) echo "   -> NO CONSUMPTION RECORDED!\n";
    foreach ($results as $r) {
        echo "   -> Consumed: {$r->item_id} | Qty: {$r->cantidad} | Type: {$r->origen}\n";
    }

    // -------------------------------------------------------------------------
    // TEST 2: WITH STOCK OF SUB-RECETA
    // -------------------------------------------------------------------------
    echo "\n--- TEST 2: WITH STOCK (Expected: Consume Sub-receta directly) ---\n";
    DB::connection('pgsql')->table('selemti.mov_inv')->insert([
        'item_id' => $p2, 'tipo_movimiento' => 'E', 'cantidad' => 10, 'fecha_movimiento' => now(), 'costo_unitario' => 0, 
        'referencia_tipo' => 'INICIAL', 'referencia_id' => 1, 'ubicacion_id' => 'UBIC-TEST', 'usuario_id' => 1
    ]);
    
    DB::connection('pgsql')->delete("DELETE FROM selemti.inv_consumo_pos WHERE ticket_id = ?", [$ticketId]);
    DB::connection('pgsql')->statement("SELECT selemti.fn_expandir_consumo_ticket(?)", [$ticketId]);

    $results = q("SELECT * FROM selemti.inv_consumo_pos_det WHERE consumo_id IN (SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = ?)", [$ticketId]);
    if (count($results) == 0) echo "   -> NO CONSUMPTION RECORDED!\n";
    foreach ($results as $r) {
        echo "   -> Consumed: {$r->item_id} | Qty: {$r->cantidad} | Type: {$r->origen}\n";
    }

    DB::connection('pgsql')->rollBack();
    echo "\nSUCCESS: Validation finished.\n";

} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n" . $e->getTraceAsString();
    DB::connection('pgsql')->rollBack();
}
