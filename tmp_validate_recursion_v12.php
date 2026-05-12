<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

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
    $real_pos_id = '99999';
    $ticketId = 649428;

    // Clean up
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_det WHERE receta_version_id IN (SELECT id FROM selemti.receta_version WHERE receta_id IN (?, ?))", [$p1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_version WHERE receta_id IN (?, ?)", [$p1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.receta_cab WHERE id IN (?, ?) OR codigo_plato_pos = ?", [$p1, $p2, $real_pos_id]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.items WHERE id IN (?, ?)", [$i1, $p2]);
    DB::connection('pgsql')->delete("DELETE FROM selemti.mov_inv WHERE item_id IN (?, ?)", [$p2, $i1]);

    // Create Items
    DB::connection('pgsql')->table('selemti.items')->insert([
        ['id' => $i1, 'nombre' => 'Insumo de Prueba', 'unidad_medida' => 'KG', 'perishable' => false, 'activo' => true, 'categoria_id' => $cat],
        ['id' => $p2, 'nombre' => 'Sub-receta de Prueba', 'unidad_medida' => 'PZ', 'perishable' => false, 'activo' => true, 'categoria_id' => $cat]
    ]);

    // Create Recipe Cab
    DB::connection('pgsql')->table('selemti.receta_cab')->insert([
        ['id' => $p1, 'nombre_plato' => 'Plato Base Prueba', 'codigo_plato_pos' => $real_pos_id, 'porciones_standard' => 1, 'activo' => true],
        ['id' => $p2, 'nombre_plato' => 'Sub-receta Prueba', 'codigo_plato_pos' => 'MOD-' . $real_pos_id, 'porciones_standard' => 1, 'activo' => true]
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

    // -------------------------------------------------------------------------
    // TEST 1: NO STOCK OF SUB-RECETA
    // -------------------------------------------------------------------------
    echo "--- TEST 1: NO STOCK (Expected: Explosion to Insumo) ---\n";
    DB::connection('pgsql')->delete("DELETE FROM selemti.inv_consumo_pos WHERE ticket_id = ?", [$ticketId]);
    DB::connection('pgsql')->statement("SELECT selemti.fn_expandir_consumo_ticket(?)", [$ticketId]);
    
    $results = q("SELECT * FROM selemti.inv_consumo_pos_det WHERE consumo_id IN (SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = ?)", [$ticketId]);
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
    foreach ($results as $r) {
        echo "   -> Consumed: {$r->item_id} | Qty: {$r->cantidad} | Type: {$r->origen}\n";
    }

    DB::connection('pgsql')->rollBack();
    echo "\nSUCCESS: Validation finished.\n";

} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n" . $e->getTraceAsString();
    DB::connection('pgsql')->rollBack();
}
