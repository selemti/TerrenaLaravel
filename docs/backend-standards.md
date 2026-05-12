---
description: Estándares de desarrollo backend para TerrenaLaravel — Laravel 12/PHP 8.2. Incluye arquitectura DDD, principios SOLID, API design, testing y seguridad. Aplica a todos los agentes.
globs: ["app/**/*.php", "database/**/*.php", "routes/**/*.php", "tests/**/*.php"]
alwaysApply: true
---

# Backend Standards — TerrenaLaravel

---

## 1. Stack técnico

- **Laravel 12** + **PHP 8.2+**
- **PostgreSQL 9.5** (schema `selemti` propio + schema `public` FloreantPOS read-only)
- **Eloquent ORM** con connections explícitas (`pgsql` / `sqlite`)
- **Livewire 3.7** para UI reactiva (ver `docs/frontend-standards.md`)
- **PHPUnit** / **Pest** para testing
- **JWT** (tymon/jwt-auth) para autenticación API
- **Spatie Permission** para RBAC

---

## 2. Arquitectura — Capas

TerrenaLaravel sigue una arquitectura en capas inspirada en DDD:

```
Presentation  → Controllers (API) + Livewire components (UI)
Application   → Services (business logic)
Domain        → Models (Eloquent) + Traits
Infrastructure → DB connections, external APIs (POS)
```

### 2.1 Capa de Servicios (Application Layer)

Toda lógica de negocio vive en `app/Services/`. Los controladores son delegadores delgados.

**Antes (anti-patrón):**
```php
// Controller con lógica de negocio mezclada
public function store(Request $request)
{
    $item = Item::create($request->all());
    MovimientoInventario::create([
        'item_id' => $item->id,
        'tipo' => 'ENTRADA',
        'qty' => $request->qty,
    ]);
    return response()->json(['ok' => true, 'data' => $item]);
}
```

**Después (correcto):**
```php
// Controller delgado
public function store(Request $request)
{
    $result = $this->receptionService->createReception(
        $request->only(['fecha', 'proveedor_id', 'almacen_id']),
        $request->input('lineas')
    );
    return response()->json(['ok' => true, 'data' => $result]);
}

// Service con lógica de negocio
class ReceptionService
{
    public function createReception(array $header, array $lines): int
    {
        return DB::transaction(function () use ($header, $lines) {
            $reception = Reception::create($header);
            foreach ($lines as $line) {
                $this->processLine($reception, $line);
            }
            return $reception->id;
        });
    }
}
```

### 2.2 Modelos (Domain Layer)

- Modelos en `app/Models/<Modulo>/`
- Siempre especificar `$table` (muchas tablas no siguen convención Laravel)
- Siempre especificar `$connection` en modelos PostgreSQL
- Usar `$guarded = []` o `$fillable` explícito

```php
class Item extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'selemti.inv_items';
    protected $guarded = [];

    protected $casts = [
        'costo_promedio' => 'decimal:2',
        'activo' => 'boolean',
        'fecha_creacion' => 'datetime',
    ];

    public function uom(): BelongsTo
    {
        return $this->belongsTo(Unidad::class, 'unidad_medida_id');
    }
}
```

---

## 3. Principios SOLID

### Single Responsibility (SRP)
Cada clase tiene una sola razón para cambiar.

```php
// MAL: Service que valida, persiste y envía notificaciones
class TransferService {
    public function create($data) {
        $this->validate($data);       // validación
        $transfer = Transfer::create($data); // persistencia
        Mail::send(...);              // notificación — NO va aquí
    }
}

// BIEN: Separar responsabilidades
class TransferService {
    public function create(array $data): Transfer { /* solo persiste */ }
}
class TransferValidator {
    public function validate(array $data): void { /* solo valida */ }
}
```

### Open/Closed (OCP)
Abierto a extensión, cerrado a modificación. Usar Contracts/Interfaces.

```php
interface InventoryMovementHandler
{
    public function handle(array $data): void;
}

class ReceptionMovementHandler implements InventoryMovementHandler { ... }
class TransferMovementHandler implements InventoryMovementHandler { ... }
class AdjustmentMovementHandler implements InventoryMovementHandler { ... }
```

### Dependency Inversion (DIP)
Depender de abstracciones, no de implementaciones concretas.

```php
// MAL: dependencia directa
class ReceptionService {
    public function __construct() {
        $this->uomService = new UomConversionService();
    }
}

// BIEN: inyección de dependencias
class ReceptionService {
    public function __construct(
        private UomConversionService $uomService
    ) {}
}
```

### DRY (Don't Repeat Yourself)
Centralizar lógica repetida.

```php
// MAL: validación de UOM duplicada en 3 servicios
// BIEN: centralizar en UomConversionService::resolveToBase()

// MAL: respuestas JSON con estructura diferente en cada controlador
// BIEN: usar ApiResponseMiddleware + estructura estándar {ok, data, error, timestamp}
```

---

## 4. API Design Standards

### Naming de endpoints
```
GET    /api/inventory/items          # Listar
GET    /api/inventory/items/{id}     # Detalle
POST   /api/inventory/items          # Crear
PUT    /api/inventory/items/{id}     # Actualizar completo
PATCH  /api/inventory/items/{id}     # Actualizar parcial
DELETE /api/inventory/items/{id}     # Eliminar
```

### Estructura de respuesta (obligatoria)
```php
// Éxito
return response()->json([
    'ok' => true,
    'data' => $result,
    'timestamp' => now()->toIso8601String(),
], 200);

// Error de validación
return response()->json([
    'ok' => false,
    'error' => 'validation_error',
    'message' => 'Los datos proporcionados no son válidos',
    'details' => $validator->errors(),
    'timestamp' => now()->toIso8601String(),
], 422);

// Error de negocio
return response()->json([
    'ok' => false,
    'error' => 'insufficient_stock',
    'message' => 'Stock insuficiente para realizar la transferencia',
    'timestamp' => now()->toIso8601String(),
], 400);

// Not found
return response()->json([
    'ok' => false,
    'error' => 'not_found',
    'message' => 'Item no encontrado',
    'timestamp' => now()->toIso8601String(),
], 404);
```

### HTTP Status Codes
| Situación | Código |
|-----------|--------|
| OK / creado correctamente | 200 / 201 |
| Validación fallida | 422 |
| Error de negocio | 400 |
| No autenticado | 401 |
| Sin permiso | 403 |
| No encontrado | 404 |
| Error de servidor | 500 |

---

## 5. Patrones de base de datos

### Transacciones (obligatorio para multi-tabla)
```php
// Toda operación que toque más de una tabla DEBE usar DB::transaction()
public function postReception(int $receptionId): void
{
    DB::transaction(function () use ($receptionId) {
        $reception = Reception::findOrFail($receptionId);
        foreach ($reception->lines as $line) {
            $this->createBatch($line);
            $this->createKardexEntry($line);
        }
        $reception->update(['estado' => 'POSTEADA']);
    });
}
```

### Reglas críticas de schema
```php
// SIEMPRE en modelos PostgreSQL
protected $connection = 'pgsql';
protected $table = 'selemti.nombre_tabla';

// NUNCA escribir en schema public (FloreantPOS production)
// public.tickets, public.order_items, etc. — solo lectura
```

### Migrations para PostgreSQL 9.5
```php
// NO soporta: ADD COLUMN IF NOT EXISTS
// USAR: bloque DO con EXCEPTION
DB::statement("
    DO \$\$ BEGIN
        BEGIN ALTER TABLE selemti.inv_items ADD COLUMN notas TEXT DEFAULT NULL;
        EXCEPTION WHEN duplicate_column THEN NULL; END;
    END \$\$;
");
```

### Evitar N+1 queries
```php
// MAL — N+1
$items = Item::all();
foreach ($items as $item) {
    echo $item->uom->clave; // query por cada item
}

// BIEN — eager loading
$items = Item::with(['uom', 'uomCompra'])->get();
```

---

## 6. Pipeline de UOM (crítico)

Todo `mov_inv` e `inventory_batch` DEBE estar en unidades base (KG, L, PZ).

```php
// SIEMPRE convertir antes de registrar en kardex
$baseQty = $this->uomConversionService->resolveToBase(
    qty: $line['cantidad'],
    fromClave: $line['uom_clave'],
    item: $item  // debe tener uom y uomCompra eager-loaded
);

MovimientoInventario::create([
    'item_id' => $item->id,
    'qty' => $baseQty,          // en unidades BASE
    'uom' => $item->uom->clave, // clave de la UOM base
    ...
]);
```

---

## 7. Testing Standards

### Estructura (AAA Pattern)
```php
/** @test */
public function it_creates_reception_and_posts_to_kardex(): void
{
    // Arrange
    $item = Item::factory()->create(['unidad_medida_id' => $this->uomKg->id]);
    $header = ['fecha' => now(), 'almacen_id' => 1];
    $lines = [['item_id' => $item->id, 'qty' => 10, 'uom' => 'KG']];

    // Act
    $receptionId = $this->receptionService->createReception($header, $lines);

    // Assert
    $this->assertDatabaseHas('selemti.recepciones', ['id' => $receptionId]);
    $this->assertDatabaseHas('selemti.mov_inv', [
        'item_id' => $item->id,
        'qty' => 10,
        'tipo' => 'ENTRADA',
    ]);
}
```

### Convenciones de naming
```php
// Formato: it_[comportamiento_esperado]_when_[condición]
public function it_throws_exception_when_stock_is_insufficient(): void {}
public function it_converts_purchase_uom_to_base_before_recording(): void {}
public function it_rolls_back_transaction_when_kardex_fails(): void {}
```

### Organización
```php
// Agrupar por feature/servicio
// tests/Feature/Inventory/ReceptionServiceTest.php
// tests/Feature/Inventory/TransferServiceTest.php
// tests/Unit/Services/UomConversionServiceTest.php
```

### Qué testear
1. **Happy path**: flujo normal con datos válidos
2. **Error handling**: datos inválidos, stock insuficiente, item no encontrado
3. **Edge cases**: qty = 0, conversión de UOM desconocida, transacción que falla
4. **State transitions**: BORRADOR → VALIDADA → POSTEADA
5. **Kardex integrity**: cantidades en base UOM, referencias correctas

### Threshold de cobertura
- Servicios críticos (inventory, caja): **80%+**
- Services nuevos: **90%+** desde el inicio

### No hacer en tests
- No mockear la BD en Feature tests (usar `RefreshDatabase`)
- No hacer queries al schema `public` en tests (usar factories con datos propios)
- No dejar datos de prueba sin limpiar

---

## 8. Seguridad

### Validación de inputs
```php
// SIEMPRE validar en el controller antes de pasar al service
$validated = $request->validate([
    'item_id' => 'required|integer|exists:selemti.inv_items,id',
    'qty' => 'required|numeric|min:0.001',
    'uom' => 'required|string|max:10',
    'almacen_id' => 'required|integer',
]);
```

### Variables de entorno
```php
// NUNCA hardcodear credenciales o configuración
// MAL:
$host = '100.126.124.101';

// BIEN:
$host = config('database.connections.pgsql.host');
```

### Protección contra SQL injection
```php
// NUNCA interpolación directa en queries raw
// MAL:
DB::select("SELECT * FROM selemti.items WHERE clave = '$clave'");

// BIEN: bindings
DB::select("SELECT * FROM selemti.items WHERE clave = ?", [$clave]);
// O mejor aún: Eloquent
Item::where('clave', $clave)->first();
```

---

## 9. Git Workflow

- **Ramas de feature**: prefijo `work/` (ej. `work/kardex-ui-mayo-2026`)
- **Commits en inglés**: descriptivos, imperativos (`Add kardex filter by date range`)
- **Ramas pequeñas y enfocadas**: un feature o fix por rama
- **Code review antes de merge** a `main`
- **Usar skill `commit`** para crear commits y PRs estandarizados

---

## 10. Anti-patrones a evitar

| Anti-patrón | Alternativa |
|-------------|-------------|
| Lógica de negocio en controllers | Mover a Service |
| Queries directas en Blade/Livewire | Usar Service o Model scope |
| `DB::statement` con string interpolado | Usar bindings o Eloquent |
| Model sin `$connection` usando PG | Siempre declarar `protected $connection` |
| Olvidar `DB::transaction()` en multi-tabla | Siempre wrappear en transacción |
| Quantities en UOM de compra en kardex | Siempre convertir a base UOM primero |
| `Model::all()` sin limit en tablas grandes | Usar pagination o `take()` |
| Escribir en `public` schema sin confirmación | Solo lectura — coordinar con equipo |
