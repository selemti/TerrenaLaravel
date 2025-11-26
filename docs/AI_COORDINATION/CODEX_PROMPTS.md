# PROMPTS PARA CODEX - Terrena POS
**Fecha**: 25-Nov-2025
**Proyecto**: TerrenaLaravel - Sistema POS Multi-Almacén
**Coordinador**: Claude Code (CLAUDE-WORKER-FRONTEND-V4.1)

## 🚨 RESTRICCIONES CRÍTICAS DE SEGURIDAD

**IMPORTANTE**: CODEX NO DEBE ejecutar:
- ❌ **NINGUNA** migración de Laravel (`php artisan migrate`)
- ❌ **NINGÚN** query SQL directo a PostgreSQL
- ❌ **NINGUNA** modificación de esquema de BD
- ❌ **NINGÚN** comando DDL (ALTER, CREATE TABLE, DROP, etc.)

**Razón**: Ejecuciones previas no coordinadas corrompieron la base de datos. La BD actual (182 tablas) está validada y DEBE mantenerse intacta.

## ✅ ROL DE CODEX: Implementación de Servicios y APIs

CODEX implementará:
- ✅ Clases de servicio (Service Layer)
- ✅ Controladores API
- ✅ Requests de validación
- ✅ Tests unitarios (PHPUnit)
- ✅ Tests de integración (sin afectar BD)

**PATRÓN A SEGUIR**: Los módulos de Recepciones y Transferencias están 100% funcionales y sirven como referencia arquitectónica.

---

## REFERENCIAS OBLIGATORIAS

Antes de implementar CUALQUIER módulo, CODEX debe estudiar estos archivos de referencia:

### Servicios de Referencia (VALIDADOS ✅)
```
app/Services/Inventory/ReceptionService.php    ← Patrón de state machine
app/Services/Inventory/TransferService.php     ← Patrón de transacciones
```

### Modelos de Referencia
```
app/Models/Inventory/TransferHeader.php        ← Configuración PostgreSQL
app/Models/Inventory/TransferLine.php          ← Relaciones
app/Models/Inventory/Movement.php              ← Kardex pattern
app/Models/Inventory/Batch.php                 ← Trazabilidad de lotes
```

### Tests de Referencia
```
test_reception_complete.php                    ← Patrón de test completo
test_transfer_complete.php                     ← Verificación end-to-end
```

---

## PROMPT 1: Implementar InventoryCountService (Conteos Físicos)

```markdown
CONTEXTO:
El módulo de Conteos Físicos requiere un servicio para gestionar el flujo completo de inventario físico.

TABLA BD EXISTENTE (NO MODIFICAR):
- selemti.inventory_counts (cabecera)
- selemti.inventory_count_lines (detalle)

REFERENCIA:
Seguir el patrón exacto de `app/Services/Inventory/ReceptionService.php`

OBJETIVO:
Crear `app/Services/Inventory/InventoryCountService.php`

STATE MACHINE REQUERIDA:
ABIERTO → EN_PROGRESO → CERRADO → POSTEADO
         ↓
      CANCELADO

MÉTODOS A IMPLEMENTAR:

### 1. createCount(int $warehouseId, int $userId, ?string $description = null): int
**Comportamiento**:
- Crea registro en estado ABIERTO
- Genera número secuencial: `CNT-YYYYMMDD-####`
- Inicializa totales en 0
- Registra usuario creador

**Retorna**: ID del conteo creado

**Validaciones**:
- warehouseId debe existir en selemti.cat_almacenes
- userId debe existir en selemti.users

**Transacción**: Sí (DB::transaction)

### 2. addCountLine(int $countId, string $itemId, float $qtyFisica, int $userId): void
**Comportamiento**:
- Verifica que conteo esté en ABIERTO o EN_PROGRESO
- Inserta línea en inventory_count_lines
- Registra qty_fisica (cantidad contada físicamente)
- qty_sistema se calculará al cerrar

**Validaciones**:
- Count debe estar en estado permitido
- itemId debe existir
- qtyFisica >= 0

**Transacción**: Sí

### 3. closeCount(int $countId, int $userId): array
**Comportamiento**:
- Verifica estado EN_PROGRESO
- Calcula qty_sistema para cada línea (consulta mov_inv)
- Calcula varianza = qty_fisica - qty_sistema
- Marca como CERRADO
- Registra cerrado_por y cerrado_at

**Retorna**:
```php
[
    'count_id' => int,
    'total_lines' => int,
    'total_variance' => float,
    'lines_with_variance' => int
]
```

**Cálculo de qty_sistema**:
```php
SELECT SUM(cantidad)
FROM selemti.mov_inv
WHERE item_id = ?
  AND sucursal_id = ?
  AND ts <= (SELECT fecha_conteo FROM selemti.inventory_counts WHERE id = ?)
```

**Transacción**: Sí

### 4. postAdjustments(int $countId, int $userId): void
**Comportamiento**:
- Verifica estado CERRADO
- Para cada línea con varianza != 0:
  - Crea movimiento en selemti.mov_inv
  - tipo = 'AJUSTE_CONTEO'
  - cantidad = varianza (positiva o negativa)
  - ref_tipo = 'inventory_count'
  - ref_id = countId
- Marca conteo como POSTEADO
- Registra posteado_por y posteado_at

**Transacción**: Sí

### 5. cancelCount(int $countId, int $userId, string $reason): void
**Comportamiento**:
- Permite cancelar solo si NO está POSTEADO
- Marca como CANCELADO
- Guarda razón en campo meta (JSON)

**Transacción**: Sí

CONSTANTES DE CLASE:
```php
const ESTADO_ABIERTO = 'ABIERTO';
const ESTADO_EN_PROGRESO = 'EN_PROGRESO';
const ESTADO_CERRADO = 'CERRADO';
const ESTADO_POSTEADO = 'POSTEADO';
const ESTADO_CANCELADO = 'CANCELADO';
```

VALIDACIONES COMUNES (helper method):
```php
protected function guardPositiveId(int $id, string $label): void
{
    if ($id <= 0) {
        throw new InvalidArgumentException("The {$label} id must be greater than zero.");
    }
}
```

RESTRICCIONES:
- ❌ NO ejecutar migraciones
- ❌ NO crear/alterar tablas
- ✅ SÍ usar DB::transaction() para operaciones multi-tabla
- ✅ SÍ lanzar excepciones descriptivas
- ✅ SÍ documentar cada método con PHPDoc

ENTREGABLE:
`app/Services/Inventory/InventoryCountService.php` completo y funcional
```

---

## PROMPT 2: Implementar ProductionService (Órdenes de Producción)

```markdown
CONTEXTO:
Módulo para gestionar producción de recetas (conversión de ingredientes en productos terminados).

TABLAS BD EXISTENTES (NO MODIFICAR):
- selemti.production_orders (cabecera)
- selemti.production_order_lines (detalle)
- selemti.recipes (recetas)
- selemti.recipe_ingredients (ingredientes)

REFERENCIA:
`app/Services/Inventory/TransferService.php` para manejo de movimientos duales

OBJETIVO:
Crear `app/Services/Inventory/ProductionService.php`

STATE MACHINE:
BORRADOR → PROGRAMADA → EN_PROCESO → COMPLETADA
         ↓
      CANCELADA

MÉTODOS PRINCIPALES:

### 1. createProductionOrder(string $recipeId, float $quantity, int $warehouseId, int $userId): int
**Comportamiento**:
- Obtiene receta y sus ingredientes
- Calcula cantidades de ingredientes necesarios (qty * factor_receta)
- Crea orden en estado BORRADOR
- Crea líneas de ingredientes (tipo: INPUT)
- Crea línea de producto terminado (tipo: OUTPUT)
- Genera número: `OP-YYYYMMDD-####`

**Validaciones**:
- Receta debe existir y estar activa
- Warehouse debe existir
- quantity > 0

**Transacción**: Sí

### 2. scheduleOrder(int $orderId, string $scheduledDate, int $userId): void
**Comportamiento**:
- Valida estado BORRADOR
- Verifica disponibilidad de ingredientes en warehouse
- Si stock suficiente: marca como PROGRAMADA
- Si stock insuficiente: lanza RuntimeException con detalles

**Validación de Stock**:
```php
// Para cada ingrediente INPUT:
$stock = $this->getStockAtWarehouse($itemId, $warehouseId);
if ($stock < $requiredQty) {
    throw new RuntimeException("Stock insuficiente para {$itemId}. Disponible: {$stock}, Requerido: {$requiredQty}");
}
```

**Transacción**: Sí

### 3. startProduction(int $orderId, int $userId): void
**Comportamiento**:
- Valida estado PROGRAMADA
- Reserva ingredientes (marca líneas INPUT como consumidas)
- Marca orden como EN_PROCESO
- Registra inicio_produccion_at

**Transacción**: Sí

### 4. completeProduction(int $orderId, float $yieldActual, int $userId): void
**Comportamiento**:
- Valida estado EN_PROCESO
- Registra rendimiento real vs esperado
- Calcula varianza de producción
- Genera movimientos en mov_inv:
  - Salidas negativas para ingredientes (tipo: PRODUCCION_CONSUMO)
  - Entrada positiva para producto terminado (tipo: PRODUCCION_OUTPUT)
- Marca como COMPLETADA
- Registra completada_por y completada_at

**Cálculo de Yield**:
```php
$yieldExpected = $order->quantity_expected;
$variance = $yieldActual - $yieldExpected;
$variancePercent = ($variance / $yieldExpected) * 100;
```

**Transacción**: Sí

### 5. cancelOrder(int $orderId, string $reason, int $userId): void
**Comportamiento**:
- Solo si NO está COMPLETADA
- Si EN_PROCESO: liberar ingredientes reservados
- Marca como CANCELADA
- Guarda razón

**Transacción**: Sí

HELPER METHODS:
```php
protected function getStockAtWarehouse(string $itemId, int $warehouseId): float
{
    return DB::connection('pgsql')
        ->table('selemti.mov_inv')
        ->where('item_id', $itemId)
        ->where('sucursal_id', (string)$warehouseId)
        ->sum('cantidad') ?? 0.0;
}

protected function getRecipeIngredients(string $recipeId): Collection
{
    return DB::connection('pgsql')
        ->table('selemti.recipe_ingredients')
        ->where('recipe_id', $recipeId)
        ->get();
}
```

RESTRICCIONES:
- ❌ NO modificar estructura de tablas
- ✅ SÍ usar patrón de TransferService para movimientos duales
- ✅ SÍ calcular y registrar varianzas

ENTREGABLE:
`app/Services/Inventory/ProductionService.php`
```

---

## PROMPT 3: Implementar API Controllers (REST)

```markdown
CONTEXTO:
Crear controladores API REST para exponer los servicios implementados.

REFERENCIA ARQUITECTÓNICA:
- `app/Http/Controllers/API/UnidadesController.php`
- Middleware: ApiResponseMiddleware (ya configurado)

PATRÓN DE RESPUESTA ESTÁNDAR:
```php
// Success
return response()->json([
    'ok' => true,
    'data' => $result,
    'timestamp' => now()->toIso8601String()
]);

// Error
return response()->json([
    'ok' => false,
    'error' => 'error_code',
    'message' => 'Human readable message',
    'timestamp' => now()->toIso8601String()
], 400);
```

CONTROLADORES A CREAR:

### 1. app/Http/Controllers/API/InventoryCountController.php

**Rutas** (agregar a routes/api.php):
```php
Route::prefix('inventory/counts')->group(function () {
    Route::post('/', [InventoryCountController::class, 'create']);
    Route::post('/{id}/lines', [InventoryCountController::class, 'addLine']);
    Route::post('/{id}/close', [InventoryCountController::class, 'close']);
    Route::post('/{id}/post', [InventoryCountController::class, 'post']);
    Route::post('/{id}/cancel', [InventoryCountController::class, 'cancel']);
    Route::get('/{id}', [InventoryCountController::class, 'show']);
    Route::get('/', [InventoryCountController::class, 'index']);
});
```

**Métodos**:
```php
public function create(Request $request)
{
    $validated = $request->validate([
        'warehouse_id' => 'required|integer|min:1',
        'description' => 'nullable|string|max:500',
        'user_id' => 'required|integer|min:1',
    ]);

    try {
        $countId = $this->countService->createCount(
            $validated['warehouse_id'],
            $validated['user_id'],
            $validated['description'] ?? null
        );

        return response()->json([
            'ok' => true,
            'data' => ['count_id' => $countId],
            'timestamp' => now()->toIso8601String()
        ], 201);
    } catch (\InvalidArgumentException $e) {
        return response()->json([
            'ok' => false,
            'error' => 'validation_error',
            'message' => $e->getMessage(),
            'timestamp' => now()->toIso8601String()
        ], 400);
    } catch (\Exception $e) {
        return response()->json([
            'ok' => false,
            'error' => 'server_error',
            'message' => 'Failed to create count',
            'timestamp' => now()->toIso8601String()
        ], 500);
    }
}

// Similar para addLine, close, post, cancel...
```

### 2. app/Http/Controllers/API/ProductionController.php
[Similar estructura para ProductionService]

VALIDACIONES:
Usar Form Requests para validaciones complejas:
```php
// app/Http/Requests/CreateCountRequest.php
class CreateCountRequest extends FormRequest
{
    public function rules()
    {
        return [
            'warehouse_id' => 'required|integer|exists:selemti.cat_almacenes,id',
            'description' => 'nullable|string|max:500',
            'user_id' => 'required|integer|exists:selemti.users,id',
        ];
    }
}
```

INYECCIÓN DE DEPENDENCIAS:
```php
public function __construct(
    protected InventoryCountService $countService
) {}
```

RESTRICCIONES:
- ❌ NO crear rutas que ejecuten queries directos
- ✅ SÍ validar todos los inputs
- ✅ SÍ usar try-catch para manejo de errores
- ✅ SÍ retornar códigos HTTP apropiados (201, 400, 404, 500)

ENTREGABLES:
- `app/Http/Controllers/API/InventoryCountController.php`
- `app/Http/Controllers/API/ProductionController.php`
- `app/Http/Requests/Inventory/CreateCountRequest.php`
- `app/Http/Requests/Inventory/CreateProductionRequest.php`
- Rutas agregadas a `routes/api.php`
```

---

## PROMPT 4: Crear Tests Unitarios (PHPUnit)

```markdown
CONTEXTO:
Tests unitarios para servicios usando PHPUnit (NO integración con BD real).

REFERENCIAS:
- tests/Feature/ExampleTest.php
- test_reception_complete.php (como referencia de flujo, NO como patrón de test unitario)

OBJETIVO:
Crear tests UNITARIOS con mocks (sin afectar BD).

TEST SUITE: tests/Unit/Services/InventoryCountServiceTest.php

PATRÓN DE TEST:
```php
<?php

namespace Tests\Unit\Services;

use App\Services\Inventory\InventoryCountService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Mockery;

class InventoryCountServiceTest extends TestCase
{
    protected InventoryCountService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new InventoryCountService();
    }

    /** @test */
    public function it_creates_count_in_abierto_state()
    {
        // Mock DB calls
        DB::shouldReceive('transaction')
            ->once()
            ->andReturnUsing(function ($callback) {
                return $callback();
            });

        DB::shouldReceive('table')
            ->with('selemti.inventory_counts')
            ->andReturnSelf();

        DB::shouldReceive('insertGetId')
            ->once()
            ->andReturn(1);

        // Execute
        $countId = $this->service->createCount(1, 1);

        // Assert
        $this->assertEquals(1, $countId);
    }

    /** @test */
    public function it_throws_exception_for_invalid_warehouse_id()
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('warehouse');

        $this->service->createCount(0, 1);
    }

    /** @test */
    public function it_calculates_variance_correctly()
    {
        // Mock DB para closeCount
        // Simular qty_sistema = 100, qty_fisica = 95
        // Esperar varianza = -5

        // ... setup mocks ...

        $result = $this->service->closeCount(1, 1);

        $this->assertArrayHasKey('total_variance', $result);
        $this->assertEquals(-5, $result['total_variance']);
    }
}
```

TESTS REQUERIDOS POR MÉTODO:

### createCount:
- ✅ Crea conteo en estado ABIERTO
- ✅ Lanza excepción si warehouse_id <= 0
- ✅ Lanza excepción si user_id <= 0
- ✅ Genera número secuencial correcto

### addCountLine:
- ✅ Agrega línea si conteo está ABIERTO
- ✅ Agrega línea si conteo está EN_PROGRESO
- ✅ Lanza excepción si conteo está CERRADO
- ✅ Valida que qty_fisica >= 0

### closeCount:
- ✅ Calcula qty_sistema correctamente
- ✅ Calcula varianzas positivas y negativas
- ✅ Marca como CERRADO
- ✅ Lanza excepción si no está EN_PROGRESO

### postAdjustments:
- ✅ Crea movimientos solo para líneas con varianza
- ✅ Usa cantidad positiva para faltantes
- ✅ Usa cantidad negativa para sobrantes
- ✅ Marca como POSTEADO

MOCKING DE DB:
```php
use Illuminate\Support\Facades\DB;

// Mock query builder
DB::shouldReceive('connection')
    ->with('pgsql')
    ->andReturnSelf();

DB::shouldReceive('table')
    ->with('selemti.mov_inv')
    ->andReturnSelf();

DB::shouldReceive('where')
    ->andReturnSelf();

DB::shouldReceive('sum')
    ->with('cantidad')
    ->andReturn(100.0);
```

RESTRICCIONES:
- ❌ NO usar RefreshDatabase (no tocar BD real)
- ❌ NO ejecutar queries reales
- ✅ SÍ usar Mockery para DB facade
- ✅ SÍ probar edge cases y excepciones
- ✅ SÍ usar annotations (@test, @dataProvider)

ENTREGABLES:
- `tests/Unit/Services/InventoryCountServiceTest.php`
- `tests/Unit/Services/ProductionServiceTest.php`
- Coverage de al menos 80% de los métodos públicos
```

---

## PROMPT 5: Crear Tests de Integración (Patrón Tinker)

```markdown
CONTEXTO:
Tests de integración end-to-end siguiendo el patrón de test_reception_complete.php

REFERENCIA OBLIGATORIA:
`test_reception_complete.php` (analizar estructura completa)

PATRÓN IDENTIFICADO:
1. Preparar datos maestros (si no existen)
2. Ejecutar flujo completo de servicio
3. Verificar en BD después de cada paso
4. Imprimir resultados con ✅/❌

OBJETIVO:
Crear `test_count_complete.php` para InventoryCountService

ESTRUCTURA DEL TEST:
```php
<?php
/**
 * TEST 3: Flujo Completo de Conteos Físicos
 */

use App\Services\Inventory\InventoryCountService;
use Illuminate\Support\Facades\DB;

echo "\n=== TEST 3: INVENTORY COUNTS ===\n\n";

$service = app(InventoryCountService::class);
$userId = 1;
$warehouseId = 1; // ALM-SUR-01
$itemId = 'ACEITE-NUT-01';

// PREPARACIÓN: Verificar stock actual
echo "PREPARACIÓN: Verificando stock actual...\n";
$stockActual = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('item_id', $itemId)
    ->where('sucursal_id', (string)$warehouseId)
    ->sum('cantidad');

echo "Stock actual de {$itemId}: {$stockActual}\n\n";

// PASO 1: Crear conteo
echo "PASO 1: Creando conteo físico...\n";
try {
    $countId = $service->createCount($warehouseId, $userId, 'Conteo mensual');
    echo "✅ Conteo creado: ID = {$countId}\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// PASO 2: Agregar líneas
echo "PASO 2: Agregando líneas de conteo...\n";
try {
    // Simular conteo físico con diferencia
    $qtyFisica = $stockActual - 2; // Faltante de 2 unidades
    $service->addCountLine($countId, $itemId, $qtyFisica, $userId);
    echo "✅ Línea agregada: qty_fisica = {$qtyFisica}\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// PASO 3: Cerrar conteo
echo "PASO 3: Cerrando conteo...\n";
try {
    $result = $service->closeCount($countId, $userId);
    echo "✅ Conteo cerrado\n";
    echo "   Total varianza: {$result['total_variance']}\n";
    echo "   Líneas con varianza: {$result['lines_with_variance']}\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// PASO 4: Postear ajustes
echo "PASO 4: Posteando ajustes a inventario...\n";
try {
    $service->postAdjustments($countId, $userId);
    echo "✅ Ajustes posteados\n\n";
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// VERIFICACIÓN FINAL
echo "VERIFICACIÓN FINAL:\n";

// 1. Estado del conteo
$count = DB::connection('pgsql')
    ->table('selemti.inventory_counts')
    ->where('id', $countId)
    ->first();

$estadoOK = $count->estado === 'POSTEADO' ? '✅' : '❌';
echo "{$estadoOK} Estado: {$count->estado}\n";

// 2. Movimiento de ajuste creado
$ajuste = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('ref_tipo', 'inventory_count')
    ->where('ref_id', $countId)
    ->first();

$ajusteOK = $ajuste !== null ? '✅' : '❌';
echo "{$ajusteOK} Movimiento ajuste creado: ID = " . ($ajuste->id ?? 'N/A') . "\n";
echo "   Cantidad ajuste: " . ($ajuste->cantidad ?? 'N/A') . "\n";

// 3. Stock actualizado
$stockNuevo = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('item_id', $itemId)
    ->where('sucursal_id', (string)$warehouseId)
    ->sum('cantidad');

$stockOK = abs($stockNuevo - $qtyFisica) < 0.01 ? '✅' : '❌';
echo "{$stockOK} Stock actualizado: {$stockNuevo} (esperado: {$qtyFisica})\n";

echo "\n✅ TEST 3 COMPLETADO\n\n";
```

EJECUCIÓN DEL TEST:
```bash
php -r "require 'vendor/autoload.php'; \$app = require_once 'bootstrap/app.php'; \$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap(); require 'test_count_complete.php';"
```

VALIDACIONES INCLUIDAS:
- ✅ Creación exitosa de conteo
- ✅ Estado ABIERTO → CERRADO → POSTEADO
- ✅ Cálculo correcto de varianza
- ✅ Generación de movimiento de ajuste
- ✅ Actualización de stock en kardex

CASOS A PROBAR:
1. Faltante (qty_fisica < qty_sistema)
2. Sobrante (qty_fisica > qty_sistema)
3. Sin varianza (qty_fisica == qty_sistema)

RESTRICCIONES:
- ✅ SÍ ejecutar en BD real (solo para este tipo de test)
- ✅ SÍ limpiar datos de prueba después
- ❌ NO modificar estructura de tablas
- ✅ SÍ imprimir resultados paso a paso

ENTREGABLES:
- `test_count_complete.php`
- `test_production_complete.php`
```

---

## COORDINACIÓN CON CLAUDE Y QWEN

### CODEX recibe de QWEN:
1. `INVENTARIO_SCHEMA_ACTUAL.md` → Para alinear servicios con BD real
2. `BUSINESS_FLOWS/*.md` → Para entender flujos de negocio
3. `INTEGRATION_TEST_PLAN.md` → Para implementar tests planeados

### CODEX entrega a CLAUDE:
1. Servicios completados → Para integrar en Livewire components
2. Controllers API → Para conectar desde frontend
3. Tests passing → Evidencia de funcionalidad

### CODEX entrega a QWEN:
1. Código de servicios → Para review de seguridad/performance
2. Tests implementados → Para validar cobertura

---

## CHECKLIST DE SEGURIDAD PARA CODEX

Antes de CUALQUIER implementación, verificar:
- [ ] ¿El código SOLO usa ORM/Query Builder de Laravel?
- [ ] ¿NO incluye comandos SQL raw de DDL?
- [ ] ¿NO ejecuta php artisan migrate?
- [ ] ¿Usa DB::transaction() para operaciones críticas?
- [ ] ¿Valida todos los inputs antes de procesarlos?
- [ ] ¿Sigue el patrón de servicios de referencia?

Si CUALQUIER respuesta es NO → **REVISAR** antes de continuar.

---

## ORDEN DE EJECUCIÓN RECOMENDADO

1. **PRIMERO**: Implementar InventoryCountService (PROMPT 1)
2. **SEGUNDO**: Crear test_count_complete.php (PROMPT 5) y ejecutar
3. **TERCERO**: Implementar InventoryCountController (PROMPT 3)
4. **CUARTO**: Crear tests unitarios (PROMPT 4)
5. **REPETIR** para ProductionService

**Razón**: Este orden permite validar cada servicio antes de construir capas superiores.

---

**Última actualización**: 25-Nov-2025
**Preparado por**: Claude Code (CLAUDE-WORKER-FRONTEND-V4.1)
**Estado**: Listo para ejecución coordinada
**BD**: 182 tablas validadas (NO MODIFICAR)
