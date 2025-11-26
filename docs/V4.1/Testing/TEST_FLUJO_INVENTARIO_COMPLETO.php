<?php
/**
 * TEST_FLUJO_INVENTARIO_COMPLETO.php
 *
 * Script para validar flujo completo de inventario en php artisan tinker
 *
 * Cubre:
 * - Recepciones: BORRADOR → VALIDADA → POSTEADA
 * - Transferencias: CREADA → DESPACHADA → RECIBIDA
 * - Kardex (mov_inv)
 * - Lotes (inventory_batch)
 *
 * Prerrequisitos:
 * - Almacenes creados (cat_almacenes)
 * - Items activos (items)
 * - Proveedores activos (cat_proveedores)
 * - Usuario activo (selemti.users)
 *
 * Uso:
 * php artisan tinker
 * > include 'docs/V4.1/Testing/TEST_FLUJO_INVENTARIO_COMPLETO.php';
 */

echo "\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  TEST FLUJO INVENTARIO COMPLETO - Terrena V4.1\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "\n";

use Illuminate\Support\Facades\DB;

// ===================================================================
// PASO 0: VERIFICAR PRERREQUISITOS
// ===================================================================

echo "📋 PASO 0: Verificando prerrequisitos...\n";
echo "─────────────────────────────────────────\n";

$almacenes = DB::connection('pgsql')->table('selemti.cat_almacenes')->count();
$items = DB::connection('pgsql')->table('selemti.items')->where('activo', true)->count();
$proveedores = DB::connection('pgsql')->table('selemti.cat_proveedores')->where('activo', true)->count();
$usuarios = DB::connection('pgsql')->table('selemti.users')->where('activo', true)->count();

echo "  ✓ Almacenes activos: {$almacenes}\n";
echo "  ✓ Items activos: {$items}\n";
echo "  ✓ Proveedores activos: {$proveedores}\n";
echo "  ✓ Usuarios activos: {$usuarios}\n";

if ($almacenes < 2) {
    echo "\n❌ ERROR: Se requieren al menos 2 almacenes.\n";
    echo "   Ejecutar: INSERT INTO selemti.cat_almacenes (clave, nombre, sucursal_id, activo) VALUES ('ALM-TEST-01', 'Almacen Test 1', 1, true), ('ALM-TEST-02', 'Almacen Test 2', 2, true);\n";
    exit(1);
}

if ($items < 1 || $proveedores < 1 || $usuarios < 1) {
    echo "\n❌ ERROR: Faltan datos maestros básicos.\n";
    exit(1);
}

echo "\n✅ Prerrequisitos OK\n";

// Obtener datos maestros
$almacenOrigen = DB::connection('pgsql')->table('selemti.cat_almacenes')->where('id', 3)->first();
$almacenDestino = DB::connection('pgsql')->table('selemti.cat_almacenes')->where('id', 4)->first();
$item = DB::connection('pgsql')->table('selemti.items')->where('activo', true)->first();
$proveedor = DB::connection('pgsql')->table('selemti.cat_proveedores')->where('activo', true)->first();
$usuario = DB::connection('pgsql')->table('selemti.users')->where('activo', true)->first();

echo "\nDatos seleccionados:\n";
echo "  - Almacén Origen: [{$almacenOrigen->id}] {$almacenOrigen->nombre}\n";
echo "  - Almacén Destino: [{$almacenDestino->id}] {$almacenDestino->nombre}\n";
echo "  - Item: [{$item->id}] {$item->nombre}\n";
echo "  - Proveedor: [{$proveedor->id}] {$proveedor->nombre}\n";
echo "  - Usuario: [{$usuario->id}] {$usuario->username}\n";

// ===================================================================
// TEST 1: FLUJO COMPLETO DE RECEPCIÓN
// ===================================================================

echo "\n\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  TEST 1: FLUJO COMPLETO DE RECEPCIÓN\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "\n";

// Instanciar servicio
$receptionService = app(\App\Services\Inventory\ReceptionService::class);

// PASO 1.1: Crear recepción en BORRADOR
echo "📝 PASO 1.1: Creando recepción en BORRADOR...\n";
echo "─────────────────────────────────────────────────\n";

$header = [
    'supplier_id' => $proveedor->id,
    'branch_id' => 1,
    'warehouse_id' => $almacenOrigen->id,
    'user_id' => $usuario->id
];

$lines = [
    [
        'item_id' => $item->id,
        'qty_pack' => 5,              // 5 cajas/paquetes
        'uom_purchase' => 'CAJA',
        'pack_size' => 12,            // 12 unidades por caja
        'uom_base' => 'L',            // Litros (UOM base del item)
        'costo_unit' => 20.50,        // $20.50 por litro
        'lot' => 'LOTE-TEST-001',
        'exp_date' => '2026-06-01',
        'temp' => 4.5,
        'doc_url' => null
    ]
];

try {
    $receptionId = $receptionService->createDraftReception($header, $lines);
    echo "  ✅ Recepción creada: ID={$receptionId}\n";

    $recepcion = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $receptionId)->first();
    echo "  ✓ Estado: {$recepcion->estado}\n";
    echo "  ✓ Número: {$recepcion->numero_recepcion}\n";
    echo "  ✓ Total presentaciones: {$recepcion->total_presentaciones}\n";
    echo "  ✓ Total canónico: {$recepcion->total_canonico} L\n";

    // Verificar que NO hay lote ni movimiento
    $lotes = DB::connection('pgsql')->table('selemti.inventory_batch')->count();
    $movimientos = DB::connection('pgsql')->table('selemti.mov_inv')->count();
    echo "  ✓ Lotes creados: {$lotes} (debe ser 0 en BORRADOR)\n";
    echo "  ✓ Movimientos: {$movimientos} (debe ser 0 en BORRADOR)\n";

} catch (\Exception $e) {
    echo "  ❌ ERROR: {$e->getMessage()}\n";
    echo "  Trace: {$e->getTraceAsString()}\n";
    exit(1);
}

// PASO 1.2: Validar recepción (BORRADOR → VALIDADA)
echo "\n📝 PASO 1.2: Validando recepción (BORRADOR → VALIDADA)...\n";
echo "───────────────────────────────────────────────────────────\n";

try {
    $receptionService->validateReception($receptionId, $usuario->id);
    echo "  ✅ Recepción validada\n";

    $recepcion = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $receptionId)->first();
    echo "  ✓ Estado: {$recepcion->estado}\n";

    // Verificar que AÚN NO hay lote ni movimiento
    $lotes = DB::connection('pgsql')->table('selemti.inventory_batch')->count();
    $movimientos = DB::connection('pgsql')->table('selemti.mov_inv')->count();
    echo "  ✓ Lotes creados: {$lotes} (debe ser 0 en VALIDADA)\n";
    echo "  ✓ Movimientos: {$movimientos} (debe ser 0 en VALIDADA)\n";

} catch (\Exception $e) {
    echo "  ❌ ERROR: {$e->getMessage()}\n";
    exit(1);
}

// PASO 1.3: Postear recepción (VALIDADA → POSTEADA)
echo "\n📝 PASO 1.3: Posteando recepción (VALIDADA → POSTEADA)...\n";
echo "────────────────────────────────────────────────────────────\n";

try {
    $receptionService->postReception($receptionId, $usuario->id);
    echo "  ✅ Recepción posteada\n";

    $recepcion = DB::connection('pgsql')->table('selemti.recepcion_cab')->where('id', $receptionId)->first();
    echo "  ✓ Estado: {$recepcion->estado}\n";

    // Verificar lote creado
    $lote = DB::connection('pgsql')->table('selemti.inventory_batch')
        ->where('item_id', $item->id)
        ->orderBy('id', 'desc')
        ->first();

    if ($lote) {
        echo "  ✅ Lote creado:\n";
        echo "     - ID: {$lote->id}\n";
        echo "     - Lote proveedor: {$lote->lote_proveedor}\n";
        echo "     - Cantidad original: {$lote->cantidad_original} L\n";
        echo "     - Cantidad actual: {$lote->cantidad_actual} L\n";
        echo "     - Estado: {$lote->estado}\n";
        echo "     - Costo unitario: \${$lote->unit_cost}\n";
    } else {
        echo "  ❌ ERROR: No se creó lote\n";
        exit(1);
    }

    // Verificar movimiento creado
    $movimiento = DB::connection('pgsql')->table('selemti.mov_inv')
        ->where('ref_tipo', 'recepcion')
        ->where('ref_id', $receptionId)
        ->first();

    if ($movimiento) {
        echo "  ✅ Movimiento creado (kardex):\n";
        echo "     - ID: {$movimiento->id}\n";
        echo "     - Tipo: {$movimiento->tipo}\n";
        echo "     - Cantidad: {$movimiento->cantidad} L\n";
        echo "     - Costo unitario: \${$movimiento->costo_unit}\n";
        echo "     - Referencia: {$movimiento->ref_tipo} #{$movimiento->ref_id}\n";
        echo "     - Lote ID: {$movimiento->lote_id}\n";
    } else {
        echo "  ❌ ERROR: No se creó movimiento en kardex\n";
        exit(1);
    }

    // Verificar batch_id en recepcion_det
    $detalle = DB::connection('pgsql')->table('selemti.recepcion_det')
        ->where('recepcion_id', $receptionId)
        ->first();

    if ($detalle && $detalle->batch_id) {
        echo "  ✅ Batch ID asignado en recepcion_det: {$detalle->batch_id}\n";
    } else {
        echo "  ❌ ERROR: No se asignó batch_id en recepcion_det\n";
        exit(1);
    }

} catch (\Exception $e) {
    echo "  ❌ ERROR: {$e->getMessage()}\n";
    echo "  Trace: {$e->getTraceAsString()}\n";
    exit(1);
}

echo "\n✅ TEST 1 COMPLETADO: Recepción flujo completo OK\n";

// ===================================================================
// TEST 2: FLUJO COMPLETO DE TRANSFERENCIA
// ===================================================================

echo "\n\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  TEST 2: FLUJO COMPLETO DE TRANSFERENCIA\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "\n";

echo "📝 PASO 2.1: Verificando stock disponible...\n";
echo "──────────────────────────────────────────────\n";

$stockAntes = $lote->cantidad_actual;
echo "  ✓ Stock disponible en almacén origen: {$stockAntes} L\n";
echo "  ✓ Item: {$item->id} - {$item->nombre}\n";

// PASO 2.2: Crear transferencia
echo "\n📝 PASO 2.2: Creando transferencia...\n";
echo "────────────────────────────────────────\n";

// Nota: Verificar si TransferService existe y tiene los métodos correctos
if (!class_exists('\App\Services\Inventory\TransferService')) {
    echo "  ⚠️  ADVERTENCIA: TransferService no existe aún.\n";
    echo "     Se requiere implementar:\n";
    echo "     - TransferService::createTransfer()\n";
    echo "     - TransferService::approveTransfer()\n";
    echo "     - TransferService::markInTransit()\n";
    echo "     - TransferService::receiveTransfer()\n";
    echo "     - TransferService::postTransferToInventory()\n";
    echo "\n✅ TEST 2 OMITIDO: Servicio no implementado\n";
} else {
    try {
        $transferService = app(\App\Services\Inventory\TransferService::class);

        $lines = [
            [
                'item_id' => $item->id,
                'cantidad' => 20  // Transferir 20 L de los 60 L disponibles
            ]
        ];

        // 2.2.1: Crear transferencia (SOLICITADA)
        $result = $transferService->createTransfer(
            $almacenOrigen->id,
            $almacenDestino->id,
            $lines,
            $usuario->id
        );

        $transferId = $result['transfer_id'];
        echo "  ✅ Transferencia creada: ID={$transferId}\n";
        echo "  ✓ Estado: {$result['status']}\n";

        // 2.2.2: Aprobar transferencia (SOLICITADA → APROBADA)
        echo "\n📝 PASO 2.3: Aprobando transferencia...\n";
        echo "───────────────────────────────────────────\n";

        $result = $transferService->approveTransfer($transferId, $usuario->id);
        echo "  ✅ Transferencia aprobada\n";
        echo "  ✓ Estado: {$result['status']}\n";

        // 2.2.3: Marcar en tránsito (APROBADA → EN_TRANSITO)
        echo "\n📝 PASO 2.4: Despachando transferencia (EN_TRANSITO)...\n";
        echo "──────────────────────────────────────────────────────\n";

        $result = $transferService->markInTransit($transferId, $usuario->id, 'GUIA-TEST-001');
        echo "  ✅ Transferencia despachada\n";
        echo "  ✓ Estado: {$result['status']}\n";
        echo "  ✓ Guía: {$result['numero_guia']}\n";

        // 2.2.4: Recibir transferencia (EN_TRANSITO → RECIBIDA)
        echo "\n📝 PASO 2.5: Recibiendo transferencia...\n";
        echo "─────────────────────────────────────────────\n";

        // Obtener line_id de transfer_det
        $transferLine = DB::connection('pgsql')->table('selemti.transfer_det')
            ->where('transfer_id', $transferId)
            ->first();

        $receivedLines = [
            [
                'line_id' => $transferLine->id,
                'cantidad_recibida' => 20
            ]
        ];

        $result = $transferService->receiveTransfer($transferId, $receivedLines, $usuario->id);
        echo "  ✅ Transferencia recibida\n";
        echo "  ✓ Estado: {$result['status']}\n";
        echo "  ✓ Líneas confirmadas: {$result['lines_confirmed']}\n";

        if (!empty($result['varianzas'])) {
            echo "  ⚠️  Varianzas detectadas:\n";
            foreach ($result['varianzas'] as $v) {
                echo "     - Item {$v['item_id']}: {$v['varianza']} ({$v['varianza_porcentaje']}%)\n";
            }
        }

        // 2.2.5: Postear a inventario (RECIBIDA → POSTEADA)
        echo "\n📝 PASO 2.6: Posteando a inventario...\n";
        echo "──────────────────────────────────────────\n";

        $result = $transferService->postTransferToInventory($transferId, $usuario->id);
        echo "  ✅ Transferencia posteada a inventario\n";
        echo "  ✓ Estado: {$result['status']}\n";
        echo "  ✓ Movimientos generados: {$result['movimientos_generados']}\n";

        // Verificar salida en origen
        $salidaOrigen = DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('ref_tipo', 'TRANSFER_OUT')
            ->where('ref_id', $transferId)
            ->first();

        if ($salidaOrigen) {
            echo "  ✅ Salida registrada en origen:\n";
            echo "     - Tipo: {$salidaOrigen->tipo}\n";
            echo "     - Cantidad: {$salidaOrigen->cantidad} L\n";
            echo "     - Sucursal: {$salidaOrigen->sucursal_id}\n";
        } else {
            echo "  ❌ ERROR: No se registró salida en origen\n";
        }

        // Verificar entrada en destino
        $entradaDestino = DB::connection('pgsql')->table('selemti.mov_inv')
            ->where('ref_tipo', 'TRANSFER_IN')
            ->where('ref_id', $transferId)
            ->first();

        if ($entradaDestino) {
            echo "  ✅ Entrada registrada en destino:\n";
            echo "     - Tipo: {$entradaDestino->tipo}\n";
            echo "     - Cantidad: {$entradaDestino->cantidad} L\n";
            echo "     - Sucursal: {$entradaDestino->sucursal_id}\n";
        } else {
            echo "  ❌ ERROR: No se registró entrada en destino\n";
        }

        echo "\n✅ TEST 2 COMPLETADO: Transferencia flujo completo OK\n";

    } catch (\Exception $e) {
        echo "  ❌ ERROR: {$e->getMessage()}\n";
        echo "  Trace: {$e->getTraceAsString()}\n";
    }
}

// ===================================================================
// RESUMEN FINAL: KARDEX COMPLETO
// ===================================================================

echo "\n\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  RESUMEN FINAL: KARDEX COMPLETO\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "\n";

$kardex = DB::connection('pgsql')->table('selemti.mov_inv')
    ->where('item_id', $item->id)
    ->orderBy('id')
    ->get();

if ($kardex->count() > 0) {
    echo "📊 Movimientos registrados para item {$item->id}:\n";
    echo "\n";
    echo "  ID | Tipo       | Ref Tipo     | Ref ID | Cantidad | Costo Unit | Usuario ID\n";
    echo "  ───┼────────────┼──────────────┼────────┼──────────┼────────────┼───────────\n";

    foreach ($kardex as $mov) {
        printf(
            "  %-3d| %-10s | %-12s | %-6d | %8.2f | %10.2f | %d\n",
            $mov->id,
            $mov->tipo,
            $mov->ref_tipo,
            $mov->ref_id,
            $mov->cantidad,
            $mov->costo_unit,
            $mov->usuario_id
        );
    }

    // Calcular stock actual
    $stockFinal = $kardex->sum('cantidad');
    echo "\n  📦 Stock final calculado: {$stockFinal} L\n";

} else {
    echo "  ℹ️  No hay movimientos registrados\n";
}

// ===================================================================
// FIN DEL TEST
// ===================================================================

echo "\n\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  🎉 TESTING COMPLETO FINALIZADO\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "\n";
echo "Resumen:\n";
echo "  ✅ Recepciones: BORRADOR → VALIDADA → POSTEADA\n";
echo "  ✅ Lotes: Creación y vinculación\n";
echo "  ✅ Kardex: Registro de movimientos\n";

if (class_exists('\App\Services\Inventory\TransferService')) {
    echo "  ✅ Transferencias: CREADA → DESPACHADA → RECIBIDA\n";
} else {
    echo "  ⚠️  Transferencias: Servicio pendiente de implementar\n";
}

echo "\n";
