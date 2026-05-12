# Development Guide — TerrenaLaravel ERP
> Laravel 12 | Livewire 3.7 | PostgreSQL 9.5 | Bootstrap 5

## Índice

1. [Ambiente de desarrollo](#1-ambiente-de-desarrollo)
2. [Stack y versiones](#2-stack-y-versiones)
3. [Estructura de directorios](#3-estructura-de-directorios)
4. [Convenciones de modelos](#4-convenciones-de-modelos)
5. [Capa de servicios](#5-capa-de-servicios)
6. [API Controllers](#6-api-controllers)
7. [Livewire components](#7-livewire-components)
8. [Sistema UOM](#8-sistema-uom)
9. [Transacciones de inventario](#9-transacciones-de-inventario)
10. [Domain Exceptions](#10-domain-exceptions)
11. [Autenticación y permisos](#11-autenticación-y-permisos)
12. [Tests](#12-tests)
13. [Migraciones](#13-migraciones)
14. [Reglas críticas](#14-reglas-críticas)

---

## 1. Ambiente de Desarrollo

### Requisitos

- PHP 8.2+
- Node.js 18+
- PostgreSQL 9.5 (producción), SQLite (tests)
- XAMPP (Windows dev)

### Setup inicial

```bash
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
```

### Iniciar todos los servicios

```bash
composer dev
# Equivalente a: php artisan serve + npm run dev + php artisan queue:listen + php artisan pail
```

### Conexión a la base de datos

| Variable | Desarrollo | Producción |
|----------|-----------|-----------|
| `DB_CONNECTION` | pgsql | pgsql |
| `DB_HOST` | localhost | 100.126.124.101 |
| `DB_PORT` | 5433 | 5432 |
| `DB_DATABASE` | pos | pos |
| `DB_USERNAME` | postgres | floreant |
| `DB_SCHEMA` | selemti | selemti |

La app corre en subdirectorio `/TerrenaLaravel`. La URL base se fuerza en `AppServiceProvider`:
```php
URL::forceRootUrl(config('app.url'));
```

---

## 2. Stack y Versiones

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Framework | Laravel | 12.x |
| UI reactiva | Livewire | 3.7 |
| Frontend CSS | Bootstrap | 5.x |
| JS interactividad | Alpine.js | 3.x |
| Build | Vite | 6.x |
| Auth API | Sanctum | 4.x |
| Auth web | Sesión Laravel | — |
| RBAC | Spatie Permission | 6.x |
| Base de datos | PostgreSQL | 9.5 |
| Tests | PHPUnit / Pest | — |
| Linter | Laravel Pint | — |

---

## 3. Estructura de Directorios

```
app/
├── Console/Commands/          Comandos artisan
├── Exceptions/                Domain exceptions (jerarquía DDD)
│   ├── DomainException.php    Base de todas las excepciones de dominio
│   ├── Inventory/             InsufficientStockException, etc.
│   ├── Transfer/              InvalidTransferStateException
│   └── CashFund/              CashFundException
├── Http/
│   ├── Controllers/
│   │   ├── Api/Caja/          Controllers del módulo Caja
│   │   ├── Api/Inventory/     ItemController, StockController, TransferApiController
│   │   ├── Production/        ProductionController
│   │   ├── Purchasing/        ReturnController, ReceivingController
│   │   ├── Reports/           SalesSummaryController, SalesMixController, etc.
│   │   └── Admin/             TicketManagementController
│   └── Middleware/
├── Livewire/                  Componentes Livewire por módulo
│   ├── Inventory/
│   ├── Purchasing/
│   ├── Transfers/
│   ├── CashFund/
│   └── Catalogs/
├── Models/
│   ├── Inv/                   ← CANÓNICO: Item, Batch, MovimientoInventario
│   ├── Caja/                  Precorte, Postcorte, SesionCajon, Terminal, FormasPago
│   ├── Rec/                   Receta, RecetaVersion, RecetaDetalle, OrdenProduccion
│   ├── Pos/                   Ticket, TicketItem, MenuItem, Transaccion
│   ├── Catalogs/              Unidad, Almacen, Sucursal, StockPolicy, Proveedor
│   ├── Purchasing/            PurchaseRequest, PurchaseOrder (Eloquent ricos)
│   └── Inventory/             TransferHeader, TransferLine, ItemCategory
└── Services/
    ├── Inventory/             ReceptionService, TransferService, UomConversionService
    ├── Operations/            DailyCloseService
    ├── Production/            ProductionService (interno, sin ProductionService en Inventory)
    ├── Purchasing/            PurchasingService, ReturnService
    ├── Recetas/               RecalcularCostosRecetasService
    ├── Replenishment/         ReplenishmentService
    └── Reports/               SalesSummaryService, SalesExceptionsReportService, etc.
```

---

## 4. Convenciones de Modelos

### Modelo canónico de ítem

```php
// ✅ CORRECTO
use App\Models\Inv\Item;

// ❌ INCORRECTO — alias legacy, no usar
use App\Models\Inventory\Item;
use App\Models\Item;
```

### Configuración de modelos PostgreSQL

```php
class Item extends Model
{
    protected $connection = 'pgsql';       // SIEMPRE especificar
    protected $table = 'selemti.items';    // SIEMPRE con schema

    public $incrementing = false;          // si el PK es string
    protected $keyType = 'string';

    protected $casts = [
        'activo' => 'boolean',
        'costo_promedio' => 'decimal:2',
        'factor_compra' => 'decimal:6',
    ];
}
```

### Eager loading obligatorio antes de loops

```php
// ✅ CORRECTO — pre-cargar para evitar N+1
$itemIds = collect($lines)->pluck('item_id')->filter()->unique();
$itemsMap = Item::with(['uom', 'uomCompra'])->findMany($itemIds)->keyBy('id');

foreach ($lines as $line) {
    $item = $itemsMap->get($line['item_id']); // sin query
}

// ❌ INCORRECTO — N+1 query
foreach ($lines as $line) {
    $item = Item::with(['uom', 'uomCompra'])->find($line['item_id']); // 1 query por iteración
}
```

---

## 5. Capa de Servicios

### Patrón estándar

```php
class ReceptionService
{
    public function postReception(int $receptionId, int $userId): array
    {
        return DB::connection('pgsql')->transaction(function () use ($receptionId, $userId) {
            // 1. Bloquear el registro principal
            $reception = DB::table('selemti.recepciones')
                ->lockForUpdate()
                ->find($receptionId);

            // 2. Validar estado antes de actuar
            if ($reception->estado !== 'VALIDADA') {
                throw new InventoryValidationException('Solo recepciones VALIDADAS se pueden postear.');
            }

            // 3. Pre-cargar datos relacionados fuera del loop
            $lines = DB::table('selemti.recepcion_lineas')
                ->where('recepcion_id', $receptionId)->get();
            $itemIds = $lines->pluck('item_id')->unique();
            $itemsMap = Item::with(['uom', 'uomCompra'])->findMany($itemIds)->keyBy('id');

            // 4. Operar dentro del loop sin queries adicionales
            foreach ($lines as $line) {
                $item = $itemsMap->get($line->item_id);
                $qtyBase = $this->uomService->resolveToBase($line->qty_recibida, $line->uom, $item);
                // ... insertar en inventory_batch y mov_inv
            }

            // 5. Actualizar estado
            DB::table('selemti.recepciones')
                ->where('id', $receptionId)
                ->update(['estado' => 'POSTEADA', 'posteado_en' => now(), 'posteado_por' => $userId]);

            return ['reception_id' => $receptionId, 'estado' => 'POSTEADA'];
        });
    }
}
```

### Reglas de servicios

- **Siempre** usar `DB::transaction()` en operaciones multi-tabla
- **Siempre** pre-cargar ítems antes de loops (evitar N+1)
- **Siempre** `lockForUpdate()` en el registro principal dentro de la transacción
- **Nunca** lanzar `\Exception` genérica — usar excepciones de dominio
- **Nunca** incluir lógica HTTP (request/response) en servicios

---

## 6. API Controllers

### Patrón estándar

```php
class ProductionController extends Controller
{
    public function __construct(protected ProductionService $productionService)
    {
        $this->middleware(['auth:sanctum', 'permission:can_edit_production_order']);
    }

    public function plan(Request $request): JsonResponse
    {
        try {
            $userId = (int) auth()->id(); // auth garantizado por middleware, sin ?? 1
            $data = $this->productionService->planBatch(
                (int) $request->input('recipe_id'),
                (float) $request->input('qty_target', 0),
                $userId
            );

            return response()->json(['ok' => true, 'data' => $data, 'message' => 'Batch planificado.']);
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => 'plan_error', 'message' => $e->getMessage()], 422);
        }
    }
}
```

### Anti-patrones prohibidos

```php
// ❌ NUNCA — si el middleware garantiza auth, id() nunca es null
$userId = auth()->id() ?? 1;

// ❌ NUNCA — devuelve 200 cuando debería ser 422/500
public function create(Request $request) {
    $data = $this->service->create($request->all());
    return response()->json($data);
    // sin try/catch = excepciones no capturadas rompen la respuesta
}

// ❌ NUNCA — verificar auth manualmente cuando el middleware lo garantiza
$user = $request->user();
if (!$user) {
    return response()->json(['ok' => false], 401);
}
```

### Estructura de respuesta

```json
// Éxito
{ "ok": true, "data": {...}, "message": "Operación exitosa." }

// Error de negocio (422)
{ "ok": false, "error": "CODIGO_ERROR", "message": "Descripción legible." }

// No encontrado (404)
{ "ok": false, "error": "not_found", "message": "El recurso no existe." }
```

---

## 7. Livewire Components

### Layout estándar

```php
// Nuevos componentes — usar Bootstrap 5
#[Layout('layouts.terrena')]
class MiComponente extends Component
{
    // ❌ NO usar layouts.app — es el legacy Tailwind
}
```

### Autenticación en Livewire

En componentes Livewire, el usuario está autenticado vía sesión web:

```php
// ✅ CORRECTO — usuario siempre disponible en Livewire
$userId = (int) auth()->id();

// ❌ NUNCA en Livewire
$userId = auth()->id() ?? 1;
```

### Estructura de un componente

```php
class ReceptionCreate extends Component
{
    // Propiedades del formulario
    public string $proveedor_id = '';
    public array $lines = [];

    // Acciones
    public function save(): void
    {
        $this->validate([
            'proveedor_id' => 'required',
            'lines' => 'required|array|min:1',
        ]);

        try {
            $id = $this->receptionService->createReception(
                ['proveedor_id' => $this->proveedor_id, 'user_id' => (int) auth()->id()],
                $this->lines
            );
            $this->dispatch('reception-created', id: $id);
            session()->flash('success', 'Recepción creada.');
        } catch (InventoryValidationException $e) {
            $this->addError('form', $e->getMessage());
        }
    }

    public function render(): View
    {
        return view('livewire.inventory.reception-create');
    }
}
```

---

## 8. Sistema UOM

### Regla fundamental

**Todos los registros en `mov_inv` e `inventory_batch` deben estar en UOM base (KG, L, PZ).**

### Cómo convertir

```php
use App\Services\Inventory\UomConversionService;

// Siempre eager-load el ítem con sus UOMs
$item = Item::with(['uom', 'uomCompra'])->find($itemId);

$qtyBase = $this->uomConversionService->resolveToBase(
    qty: 5.0,       // 5 CAJAS
    fromClave: 'CAJA',
    item: $item     // factor_compra = 12 → resultado: 60 KG
);
```

### Lógica de resolución

1. Si `fromClave` == clave de UOM base del ítem → retornar sin cambio
2. Si `fromClave` == clave de UOM compra → multiplicar por `item->factor_compra`
3. Buscar en `selemti.cat_uom_conversion` (L↔ML, KG↔G)
4. Fallback conservador → retornar qty sin cambio

---

## 9. Transacciones de Inventario

### Anatomía de un movimiento de kardex

```php
DB::connection('pgsql')->table('selemti.mov_inv')->insert([
    'item_id'        => $item->id,
    'lote_id'        => $batchId,            // null si no hay lote
    'tipo'           => 'ENTRADA',           // ENTRADA | SALIDA | AJUSTE | TRANSFERENCIA
    'cantidad'       => $qtyBase,            // ← SIEMPRE en UOM base, puede ser negativo
    'qty_original'   => $qtyOriginal,        // cantidad en UOM de origen
    'uom_original_id'=> $item->unidad_compra_id,
    'costo_unit'     => $item->costo_promedio,
    'sucursal_id'    => $sucursalId,
    'ref_tipo'       => 'reception',         // entidad que origina el movimiento
    'ref_id'         => $receptionId,
    'usuario_id'     => $userId,
    'ts'             => $now,                // timestamp del evento de negocio
    'created_at'     => $now,
]);
```

### Tipos de movimiento y su referencia

| tipo | ref_tipo | Módulo |
|------|----------|--------|
| `ENTRADA` | `reception` | Recepción de compra |
| `SALIDA` | `transfer` | Transferencia (almacén origen) |
| `ENTRADA` | `transfer` | Transferencia (almacén destino) |
| `AJUSTE` | `inventory_count` | Conteo físico |
| `ENTRADA` | `batch` | Producción (producto terminado) |
| `SALIDA` | `batch` | Producción (insumos consumidos) |
| `SALIDA` | `pos_ticket` | Consumo POS (automático) |

---

## 10. Domain Exceptions

### Jerarquía

```
DomainException (App\Exceptions\DomainException)
├── Inventory\
│   ├── InsufficientStockException
│   ├── InventoryValidationException
│   └── ItemNotFoundException
├── Transfer\
│   └── InvalidTransferStateException
└── CashFund\
    └── CashFundException
```

### Cuándo usar cada una

```php
// Stock insuficiente al despachar transferencia
throw new InsufficientStockException("Stock insuficiente para {$item->nombre}: se requieren {$qty} {$uom}.");

// Dato de entrada inválido en operación de inventario
throw new InventoryValidationException('El conteo requiere al menos una línea.');

// ítem no encontrado al operar
throw new ItemNotFoundException("Ítem {$itemId} no encontrado en el catálogo.");

// Transición de estado inválida
throw new InvalidTransferStateException("No se puede aprobar una transferencia en estado {$transfer->estado}.");
```

### Mapeo HTTP (bootstrap/app.php)

Las excepciones de dominio se mapean automáticamente:

| Excepción | HTTP Status |
|-----------|------------|
| `InsufficientStockException` | 422 |
| `InventoryValidationException` | 422 |
| `ItemNotFoundException` | 404 |
| `InvalidTransferStateException` | 409 |
| `CashFundException` | 422 |

---

## 11. Autenticación y Permisos

### API — Sanctum

Todos los endpoints (excepto `/ping`, `/health`, `/auth/*`) requieren `auth:sanctum`:

```php
Route::prefix('inventory')->middleware(['auth:sanctum'])->group(function () {
    // ...
});
```

Obtener token:
```bash
POST /api/auth/login
Content-Type: application/json
{ "email": "soporte@selemti.com", "password": "soporte" }
```

Usar token:
```bash
Authorization: Bearer 1|abc123...
```

### Web — Sesión Laravel

Los componentes Livewire usan sesión web estándar. El middleware `auth` protege las rutas web.

### Permisos (Spatie)

```php
// En constructor del controller
$this->middleware(['auth:sanctum', 'permission:can_manage_purchasing']);

// En código de negocio (validar antes de acción sensible)
if (!auth()->user()->hasPermissionTo('reports.view')) {
    abort(403);
}

// En Blade
@can('reports.view')
    <a href="/reports">Reportes</a>
@endcan
```

### Permisos del sistema

| Permiso | Descripción |
|---------|-------------|
| `can_manage_purchasing` | Gestión de compras, recepciones, devoluciones |
| `can_edit_production_order` | Operación de batches de producción |
| `reports.view` | Acceso a reportes de ventas |
| `audit.view` | Log de auditoría de operaciones |
| `people.users.manage` | Gestión de usuarios y permisos |

---

## 12. Tests

### Ejecutar tests

```bash
# Todos
php artisan test

# Solo Unit
php artisan test --testsuite=Unit

# Archivo específico
php artisan test tests/Feature/Inventory/ReceptionTest.php

# Con cobertura
php artisan test --coverage
```

### Convenciones de tests

```php
// Feature test — ciclo HTTP completo
class TransferApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_approve_transfer_requires_auth(): void
    {
        $response = $this->postJson('/api/inventory/transfers/1/approve');
        $response->assertStatus(401);
    }
}

// Unit test — servicio sin HTTP
class TransferServiceTest extends TestCase
{
    public function test_throws_exception_when_insufficient_stock(): void
    {
        $this->expectException(InsufficientStockException::class);
        $this->transferService->postTransferToInventory($transferId, $userId);
    }
}
```

### Estado actual de tests

- 56 tests pasan / ~27 fallan (fallos por tablas PG ausentes en entorno SQLite de tests)
- Los fallos son de entorno, no de lógica de negocio
- **No agregar nuevos fallos** — cualquier PR debe mantener o mejorar el conteo de passing

---

## 13. Migraciones

### Formato de nombre

```
YYYY_MM_DD_HHMMSS_descripcion_del_cambio.php
```

### PostgreSQL 9.5 — restricciones

PG 9.5 no soporta `ADD COLUMN IF NOT EXISTS`. Usar:

```sql
DO $$ BEGIN
    BEGIN
        ALTER TABLE selemti.mi_tabla ADD COLUMN nueva_col VARCHAR DEFAULT '';
    EXCEPTION WHEN duplicate_column THEN NULL;
    END;
END $$;
```

### Convenciones

```php
public function up(): void
{
    // Usar Schema::connection('pgsql') para tablas selemti
    Schema::connection('pgsql')->create('selemti.mi_tabla', function (Blueprint $table) {
        $table->id();
        $table->string('item_id');  // FK a selemti.items
        $table->decimal('qty', 12, 4);
        $table->string('uom', 10);
        $table->timestamps();

        $table->index('item_id');   // siempre indexar FKs
    });
}
```

---

## 14. Reglas Críticas

### Lo que NUNCA hacer

| Prohibición | Motivo |
|-------------|--------|
| Escribir en `public.*` schema | FloreantPOS en producción — rompe el POS |
| Usar `auth()->id() ?? 1` | Enmascara usuarios no autenticados, crea registros con `user_id=1` |
| `Item::find($id)` dentro de un loop | N+1 query — pre-cargar siempre con `findMany()->keyBy()` |
| Lanzar `\Exception` genérica desde un servicio | Usar excepciones de dominio específicas |
| Operar sin `DB::transaction()` en multi-tabla | Inconsistencia de datos si algo falla a mitad |
| Registrar en `mov_inv` con cantidad en UOM no base | Kardex incorrecto — siempre convertir primero |
| Usar `layouts.app` en nuevos componentes | Es el legacy Tailwind — usar `layouts.terrena` (Bootstrap 5) |
| Modificar `fn_expandir_consumo_ticket` o `fn_postcorte_after_insert` | Triggers de POS en producción |

### Flujo correcto para un nuevo módulo

```
1. Backend (service + models + migration)
   └── Verificar que las tablas existen en selemti
   └── Implementar state machine si el módulo tiene estados
   └── Registrar en mov_inv si el módulo afecta inventario

2. API (controller + routes)
   └── middleware auth:sanctum en el grupo de rutas
   └── try/catch en cada action
   └── (int) auth()->id() directamente

3. UI (Livewire + Blade)
   └── layout terrena.blade.php
   └── Bootstrap 5 components
   └── Validar con $this->validate() antes de llamar al servicio

4. Tests
   └── Unit test del servicio con casos de excepción
   └── Feature test del endpoint (401, 422, 200)
```

### Compatibilidad PG 9.5

Funciones no disponibles en PG 9.5:
- `ADD COLUMN IF NOT EXISTS` → usar bloque `DO $$ BEGIN ... EXCEPTION WHEN duplicate_column`
- `CREATE INDEX IF NOT EXISTS` → verificar existencia primero
- JSON operators avanzados → usar `->` y `->>`  (disponibles desde 9.3)
- `GENERATED ALWAYS AS IDENTITY` → usar `SERIAL` o `BIGSERIAL`
