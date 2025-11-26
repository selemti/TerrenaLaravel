<?php
/**
 * TEST 1: Flujo Completo de Recepciones
 *
 * Prueba el flujo completo:
 * 1. Crear recepción BORRADOR
 * 2. Validar → VALIDADA
 * 3. Postear → POSTEADA (crea lote + kardex)
 *
 * Ejecutar: php artisan tinker
 * > include 'test_reception_complete.php';
 */

use App\Services\Inventory\ReceptionService;
use Illuminate\Support\Facades\DB;

echo "\n";
echo "==========================================================\n";
echo "TEST 1: FLUJO COMPLETO DE RECEPCIONES\n";
echo "==========================================================\n\n";

$service = app(ReceptionService::class);
$userId = 1; // Usuario soporte@selemti.com

// ===================================================================
// PASO 1: Crear recepción BORRADOR
// ===================================================================
echo "PASO 1: Creando recepción BORRADOR...\n";

$header = [
    'supplier_id' => 1,
    'branch_id' => 1,
    'warehouse_id' => 1,
    'user_id' => $userId,
];

$lines = [
    [
        'item_id' => 'ACEITE-NUT-01',
        'qty_pack' => 2.0,
        'uom_purchase' => 'CAJA',
        'pack_size' => 12.0,
        'uom_base' => 'L',
        'lot' => 'LOTE-TEST-001',
        'exp_date' => '2026-12-31',
        'temp' => 22.5,
        'doc_url' => null,
        'cost_per_pack' => 350.00,
    ],
];

try {
    $receptionId = $service->createDraftReception($header, $lines);
    echo "✅ Recepción creada: ID = {$receptionId}\n";

    // Verificar estado en BD
    $reception = DB::connection('pgsql')
        ->table('selemti.recepcion_cab')
        ->where('id', $receptionId)
        ->first(['id', 'estado', 'proveedor_id', 'almacen_id', 'total_canonico']);

    echo "   Estado: {$reception->estado}\n";
    echo "   Proveedor: {$reception->proveedor_id}\n";
    echo "   Almacén: {$reception->almacen_id}\n";
    echo "   Total canónico: {$reception->total_canonico}\n";

    if ($reception->estado !== 'BORRADOR') {
        throw new Exception("❌ ERROR: Estado esperado BORRADOR, obtenido: {$reception->estado}");
    }

    $lineCount = DB::connection('pgsql')
        ->table('selemti.recepcion_det')
        ->where('recepcion_id', $receptionId)
        ->count();
    echo "   Líneas creadas: {$lineCount}\n\n";

} catch (Exception $e) {
    echo "❌ ERROR en PASO 1: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}

// ===================================================================
// PASO 2: Validar recepción (BORRADOR → VALIDADA)
// ===================================================================
echo "PASO 2: Validando recepción...\n";

try {
    $service->validateReception($receptionId, $userId);
    echo "✅ Recepción validada\n";

    // Verificar estado en BD
    $reception = DB::connection('pgsql')
        ->table('selemti.recepcion_cab')
        ->where('id', $receptionId)
        ->first(['estado', 'validada_por', 'validada_at']);

    echo "   Estado: {$reception->estado}\n";
    echo "   Validada por: {$reception->validada_por}\n";
    echo "   Validada at: {$reception->validada_at}\n\n";

    if ($reception->estado !== 'VALIDADA') {
        throw new Exception("❌ ERROR: Estado esperado VALIDADA, obtenido: {$reception->estado}");
    }

    if ($reception->validada_por !== $userId) {
        throw new Exception("❌ ERROR: validada_por esperado {$userId}, obtenido: {$reception->validada_por}");
    }

} catch (Exception $e) {
    echo "❌ ERROR en PASO 2: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}

// ===================================================================
// PASO 3: Postear recepción (VALIDADA → POSTEADA)
// ===================================================================
echo "PASO 3: Posteando recepción a inventario...\n";

try {
    // Verificar que NO existan lotes ni movimientos antes
    $lotesBefore = DB::connection('pgsql')
        ->table('selemti.inventory_batch')
        ->count();
    $movsBefore = DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->count();

    echo "   Lotes antes: {$lotesBefore}\n";
    echo "   Movimientos antes: {$movsBefore}\n";

    $service->postReception($receptionId, $userId);
    echo "✅ Recepción posteada\n";

    // Verificar estado en BD
    $reception = DB::connection('pgsql')
        ->table('selemti.recepcion_cab')
        ->where('id', $receptionId)
        ->first(['estado', 'posteada_por', 'posteada_at']);

    echo "   Estado: {$reception->estado}\n";
    echo "   Posteada por: {$reception->posteada_por}\n";
    echo "   Posteada at: {$reception->posteada_at}\n";

    if ($reception->estado !== 'POSTEADA') {
        throw new Exception("❌ ERROR: Estado esperado POSTEADA, obtenido: {$reception->estado}");
    }

    // Verificar creación de lote
    $lotesAfter = DB::connection('pgsql')
        ->table('selemti.inventory_batch')
        ->count();
    $newLotes = $lotesAfter - $lotesBefore;
    echo "   Lotes creados: {$newLotes}\n";

    if ($newLotes < 1) {
        throw new Exception("❌ ERROR: Se esperaba al menos 1 lote creado");
    }

    $lote = DB::connection('pgsql')
        ->table('selemti.inventory_batch')
        ->orderBy('id', 'desc')
        ->first(['id', 'item_id', 'cantidad_actual', 'estado']);
    echo "   Lote ID: {$lote->id}, Item: {$lote->item_id}, Cantidad: {$lote->cantidad_actual}, Estado: {$lote->estado}\n";

    // Verificar creación de movimiento kardex
    $movsAfter = DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->count();
    $newMovs = $movsAfter - $movsBefore;
    echo "   Movimientos creados: {$newMovs}\n";

    if ($newMovs < 1) {
        throw new Exception("❌ ERROR: Se esperaba al menos 1 movimiento en kardex");
    }

    $mov = DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->orderBy('id', 'desc')
        ->first(['id', 'item_id', 'tipo', 'cantidad', 'ref_tipo', 'ref_id']);
    echo "   Mov ID: {$mov->id}, Item: {$mov->item_id}, Tipo: {$mov->tipo}, Cantidad: {$mov->cantidad}\n";
    echo "   Referencia: {$mov->ref_tipo} #{$mov->ref_id}\n\n";

    if ($mov->ref_tipo !== 'recepcion' || $mov->ref_id !== $receptionId) {
        throw new Exception("❌ ERROR: Movimiento no referencia correctamente a la recepción");
    }

} catch (Exception $e) {
    echo "❌ ERROR en PASO 3: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}

// ===================================================================
// RESUMEN FINAL
// ===================================================================
echo "==========================================================\n";
echo "✅ TEST 1 COMPLETADO EXITOSAMENTE\n";
echo "==========================================================\n";
echo "Recepción ID: {$receptionId}\n";
echo "Estado final: POSTEADA\n";
echo "Lotes creados: {$newLotes}\n";
echo "Movimientos kardex: {$newMovs}\n";
echo "==========================================================\n\n";

echo "Para verificar en BD:\n";
echo "psql> SELECT * FROM selemti.recepcion_cab WHERE id = {$receptionId};\n";
echo "psql> SELECT * FROM selemti.inventory_batch WHERE id = {$lote->id};\n";
echo "psql> SELECT * FROM selemti.mov_inv WHERE id = {$mov->id};\n\n";
