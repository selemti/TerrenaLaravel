<?php
/**
 * TEST 2: Flujo Completo de Transferencias
 */

use App\Services\Inventory\TransferService;
use Illuminate\Support\Facades\DB;

echo "\n=== TEST 2: TRANSFERENCIAS ===\n\n";

$service = app(TransferService::class);
$userId = 1;

$itemId = 'ACEITE-NUT-01';
$fromAlmacen = 1;
$toAlmacen = 2;

// PASO 1: Crear transferencia
echo "PASO 1: Creando transferencia...\n";
$lines = [['item_id' => $itemId, 'qty_requested' => 5.0]];

try {
    $result = $service->createTransfer($fromAlmacen, $toAlmacen, $lines, $userId);
    $transferId = $result['transfer_id'];
    echo "✅ Transferencia creada: ID = {$transferId}\n";
    echo "   Estado: {$result['status']}\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// PASO 2: Aprobar
echo "PASO 2: Aprobando transferencia...\n";
try {
    $result = $service->approveTransfer($transferId, $userId);
    echo "✅ Transferencia aprobada\n";
    echo "   Estado: {$result['status']}\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// PASO 3: Postear a inventario
echo "PASO 3: Posteando a inventario...\n";
try {
    $result = $service->postTransferToInventory($transferId, $userId);
    echo "✅ Transferencia posteada\n";
    echo "   Movimientos creados: {$result['movements_created']}\n\n";

    $transfer = DB::connection('pgsql')->table('selemti.traspaso_cab')->where('id', $transferId)->first();
    echo "Estado final: {$transfer->estado}\n";
    echo "✅ TEST 2 COMPLETADO\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
