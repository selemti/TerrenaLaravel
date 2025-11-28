# Plan de Test de Integración - Módulos de Inventario

## 1. Patrón de Test Identificado

### test_reception_complete.php y test_transfer_complete.php
Ambos tests siguen una estructura consistente de pruebas de extremo a extremo:

**Patrón de Test Identificado**:
```php
// PASO 1: Acción
$result = $service->metodo(...);

// PASO 2: Verificación inmediata
echo $result['status'] === 'ESPERADO' ? '✅' : '❌';

// PASO 3: Verificación en BD
$record = DB::connection('pgsql')
    ->table('selemti.tabla')
    ->where('id', $id)
    ->first();

echo $record->campo === 'esperado' ? '✅' : '❌';
```

**Características del Patrón**:
- Tests end-to-end que cubren el flujo completo de state machine
- Verificación de estado después de cada transición
- Validación directa en la base de datos
- Verificación de efectos colaterales (creación de lotes, movimientos de kardex)
- Manejo de errores con try/catch y mensajes claros
- Verificación de campos de auditoría (usuario, timestamp, etc.)

## 2. Plan Detallado para Módulos Pendientes

### TEST 3: Inventory Counts (Conteos Físicos)
**Servicio**: `app/Services/Inventory/InventoryCountService.php`  
**Tablas**: `selemti.inventory_counts`, `selemti.inventory_count_lines`

**Flujo a Testear**:
```
ABIERTO → CERRADO → POSTEADO
```

**Test Steps Planificados**:
```php
// PASO 1: Crear conteo ABIERTO
$countId = $service->createCount($warehouseId, $userId);
// VERIFICAR: Estado inicial es ABIERTO, campos de auditoría

// PASO 2: Agregar líneas de conteo
$service->addCountLine($countId, $itemId, $qtyFisica);
// VERIFICAR: Línea agregada correctamente en BD

// PASO 3: Cerrar conteo
$service->closeCount($countId, $userId);
// VERIFICAR: Estado cambia a CERRADO, no se permite edición

// PASO 4: Calcular varianzas
$variances = $service->calculateVariances($countId);
// VERIFICAR: Varianzas calculadas correctamente

// PASO 5: Postear ajustes
$service->postAdjustments($countId, $userId);
// VERIFICAR: Estado cambia a POSTEADA, movimientos de ajuste creados

// VERIFICACIONES FINALES:
// - Count en estado POSTEADA
// - Varianzas calculadas correctamente
// - Movimientos de ajuste en mov_inv (tipo AJUSTE_POSITIVO/NEGATIVO)
// - Campos de auditoría completos: cerrada_por, cerrada_at, posteada_por, posteada_at
```

### TEST 4: Production Orders (Órdenes de Producción)
**Servicio**: `app/Services/Production/ProductionOrderService.php`  
**Tablas**: `selemti.production_orders`, `selemti.production_order_inputs`, `selemti.production_order_outputs`

**Flujo a Testear**:
```
SOLICITADA → APROBADA → EN_PRODUCCION → CERRADA → POSTEADA
```

**Test Steps Planificados**:
```php
// PASO 1: Crear orden de producción SOLICITADA
$orderId = $service->createOrder($recipeId, $warehouseId, $userId);
// VERIFICAR: Estado inicial es SOLICITADA, ingredientes y productos calculados

// PASO 2: Aprobar orden
$service->approveOrder($orderId, $userId);
// VERIFICAR: Estado cambia a APROBADA, stock suficiente para ingredientes

// PASO 3: Iniciar producción
$service->startProduction($orderId, $userId);
// VERIFICAR: Estado cambia a EN_PRODUCCION, consumo de ingredientes

// PASO 4: Cerrar orden
$service->closeOrder($orderId, $userId);
// VERIFICAR: Estado cambia a CERRADA, creación de productos finales

// PASO 5: Postear a inventario
$service->postToInventory($orderId, $userId);
// VERIFICAR: Estado cambia a POSTEADA, efectos en mov_inv

// VERIFICACIONES FINALES:
// - Orden en estado POSTEADA
// - Movimientos de consumo de ingredientes en mov_inv
// - Movimientos de creación de productos en mov_inv
// - Campos de auditoría completos
```

### TEST 5: POS Consumption (Consumo desde Punto de Venta)
**Servicio**: `app/Services/Inventory/PosConsumptionService.php`  
**Tablas**: `selemti.pos_consumptions`, `selemti.pos_consumption_lines`

**Flujo a Testear**:
```
CREADO → PROCESADO → POSTEADA
```

**Test Steps Planificados**:
```php
// PASO 1: Crear consumo POS
$consumptionId = $service->registerConsumption($posData, $userId);
// VERIFICAR: Consumo registrado, estado CREADO

// PASO 2: Procesar consumo
$service->processConsumption($consumptionId, $userId);
// VERIFICAR: Estado cambia a PROCESADO, cálculo de ingredientes

// PASO 3: Postear a inventario
$service->postToInventory($consumptionId, $userId);
// VERIFICAR: Estado cambia a POSTEADA, efectos en mov_inv

// VERIFICACIONES FINALES:
// - Consumo en estado POSTEADA
// - Movimientos de consumo en mov_inv (tipo CONSUMO_POS)
// - Verificación de que los ingredientes se redujeron en inventario
// - Campos de auditoría completos
```

### TEST 6: Purchase Orders (Órdenes de Compra)
**Servicio**: `app/Services/Purchasing/PurchaseOrderService.php`  
**Tablas**: `selemti.purchase_orders`, `selemti.purchase_order_lines`

**Flujo a Testear**:
```
BORRADOR → SOLICITADA → APROBADA → PARCIALMENTE_RECIBIDA → COMPLETADA
```

**Test Steps Planificados**:
```php
// PASO 1: Crear orden de compra BORRADOR
$orderId = $service->createDraftOrder($supplierId, $lines, $userId);
// VERIFICAR: Orden en borrador, campos de auditoría

// PASO 2: Solicitar orden
$service->requestOrder($orderId, $userId);
// VERIFICAR: Estado cambia a SOLICITADA

// PASO 3: Aprobar orden
$service->approveOrder($orderId, $userId);
// VERIFICAR: Estado cambia a APROBADA, validación de límites

// PASO 4: Recibir parcialmente
$service->partialReceive($orderId, $receptionLines, $userId);
// VERIFICAR: Estado cambia a PARCIALMENTE_RECIBIDA

// PASO 5: Recibir completamente
$service->completeReceive($orderId, $userId);
// VERIFICAR: Estado cambia a COMPLETADA

// VERIFICACIONES FINALES:
// - Orden en estado COMPLETADA
// - Relación con recepciones de inventario
// - Campos de auditoría completos
```

### TEST 7: Inventory Adjustments (Ajustes de Inventario)
**Servicio**: `app/Services/Inventory/InventoryAdjustmentService.php`  
**Tablas**: `selemti.inventory_adjustments`, `selemti.inventory_adjustment_lines`

**Flujo a Testear**:
```
BORRADOR → APROBADA → POSTEADA
```

**Test Steps Planificados**:
```php
// PASO 1: Crear ajuste BORRADOR
$adjustmentId = $service->createDraftAdjustment($warehouseId, $lines, $userId);
// VERIFICAR: Ajuste en borrador, campos de auditoría

// PASO 2: Aprobar ajuste
$service->approveAdjustment($adjustmentId, $userId);
// VERIFICAR: Estado cambia a APROBADA, validación de stock

// PASO 3: Postear ajuste
$service->postAdjustment($adjustmentId, $userId);
// VERIFICAR: Estado cambia a POSTEADA, efectos en mov_inv

// VERIFICACIONES FINALES:
// - Ajuste en estado POSTEADA
// - Movimientos de ajuste en mov_inv (AJUSTE_POSITIVO/NEGATIVO)
// - Cambios reflejados en cantidad actual de lotes
// - Campos de auditoría completos
```

## 3. Principios de Diseño de Tests

**Consistencia**: Todos los tests deben seguir el mismo patrón de estructura y verificaciones.

**Completitud**: Cada test debe cubrir todo el flujo de la state machine, no solo transiciones parciales.

**Verificación Directa**: Validación de estados y efectos colaterales directamente en la base de datos, no solo en valores de retorno.

**Manejo de Errores**: Cada paso debe incluir manejo de excepciones con mensajes claros.

**Rastreabilidad**: Verificación de campos de auditoría para garantizar trazabilidad completa de las operaciones.

**Efectos en Inventario**: Confirmación de que los movimientos de kardex se crean adecuadamente en los estados correspondientes.