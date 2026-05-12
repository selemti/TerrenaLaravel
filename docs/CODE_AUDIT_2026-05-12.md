# Auditoría de Código — TerrenaLaravel
**Fecha:** 2026-05-12  
**Alcance:** `app/`, `routes/`, `tests/`  
**Baseline tests:** 42 failed / 59 passed (Unit suite, SQLite — mayoria por esquema selemti ausente)

---

## Resumen Ejecutivo

| Categoría | Crítico | Alto | Medio | Bajo |
|-----------|---------|------|-------|------|
| Seguridad | 4 | 3 | 1 | 0 |
| Rendimiento | 0 | 2 | 3 | 1 |
| Calidad de código | 0 | 1 | 4 | 3 |
| Deuda técnica | 0 | 2 | 3 | 2 |

**Total de archivos analizados:** 317 PHP  
**Archivos con issues de estilo (Pint):** 262 de 317  
**TODOs/FIXMEs activos:** 110 en 36 archivos  
**Cobertura de try/catch en controllers:** 34% (92 bloques / 267 métodos)

---

## 🔴 CRÍTICOS — Requieren acción inmediata

### C-01: Rutas de inventario, producción, catálogos y purchasing sin autenticación
**Archivos:** `routes/api.php` líneas 172, 193, 295, 336, 353

Las siguientes agrupaciones de rutas no tienen `middleware(['auth:sanctum'])`:

```
/api/unidades/*          (línea 172) — lectura/escritura de unidades de medida
/api/inventory/*         (línea 193) — stock, items, precios, transferencias
/api/production/*        (línea 295) — órdenes de producción
/api/catalogs/*          (línea 336) — almacenes, sucursales
/api/purchasing/*        (línea 353) — recepciones, devoluciones
/api/close/*             (línea 415) — cierre diario
/api/reports/* (2x)      (líneas 50 y 72) — reportes de KPIs, ventas
```

Cualquiera con acceso a red puede leer/modificar inventario, crear órdenes de producción, y ver reportes financieros sin autenticar.

**Contraste:** `/api/caja/*`, `/api/recipes/*`, `/api/reports/sales/*` SÍ tienen auth.

**Fix:** Añadir `->middleware(['auth:sanctum'])` a cada grupo afectado.

---

### C-02: Fallback `auth()->id() ?? 1` en código de producción
**Archivos:** 16 ocurrencias en controllers y Livewire

```php
// app/Http/Controllers/Api/Inventory/TransferController.php:97
$userId = auth()->id() ?? 1; // TODO: Usar auth real

// app/Livewire/Transfers/TransferDetail.php:108
$service->approveTransfer($this->transferId, auth()->id() ?? 1);
```

Cuando no hay sesión (o el token expiró), todas las acciones se atribuyen al usuario ID=1 (normalmente el administrador). Esto corrompe el trail de auditoría y puede permitir operaciones no autorizadas si se combina con C-01.

**Afecta:** `TransferController` (5 métodos), `TicketManagementController` (1), 5 componentes Livewire.

**Fix:** Una vez activado auth en rutas (C-01), eliminar `?? 1`. En Livewire, `auth()->id()` siempre es válido porque pasa por el middleware de sesión web.

---

### C-03: Ruta `/api/people` sin auth ni documentación de protección
**Archivo:** `app/Http/Controllers/Api/PeopleController.php:18`

```php
// TODO: protección con auth:sanctum + permission:people.users.manage en routes/api.php
```

Expone datos de usuarios sin autenticación. Agravado porque el TODO lleva tiempo sin resolverse.

---

### C-04: Dos grupos duplicados `Route::prefix('reports')` sin auth
**Archivo:** `routes/api.php` líneas 50 y 72

Dos bloques separados con el mismo prefix y sin middleware. Uno contiene KPIs de ventas por sucursal/terminal; el otro, stock valorizado y anomalías. Ambos exponen datos financieros sensibles.

---

## 🟠 ALTO — Resolver en el sprint actual

### A-01: N+1 queries — `Item::find()` dentro de foreach en servicios
**Archivos:** `ProductionService.php`, `InventoryCountService.php`, `ReceptionService.php`, `TransferService.php`

```php
// ProductionService.php:63 — dentro de foreach ($inputs as $input)
$inputItem = Item::with(['uom', 'uomCompra'])->find($normalized['item_id']);

// InventoryCountService.php:162 — dentro de foreach ($lines as $line)
$itemModel = Item::with('uom')->find(Arr::get($line, 'item_id'));
```

Cada línea de una orden/recepción lanza una query individual. Una recepción de 50 líneas = 50 queries de Item + 100 queries de relaciones.

**Fix:** Pre-cargar items antes del loop:
```php
$itemIds = collect($inputs)->pluck('item_id')->unique();
$items = Item::with(['uom', 'uomCompra'])->findMany($itemIds)->keyBy('id');
// luego: $items[$normalized['item_id']]
```

---

### A-02: Cobertura de manejo de errores en controllers: 34%
**Archivos:** 68 controllers, 267 métodos públicos, sólo 92 con try/catch

Controllers sin manejo de excepciones devuelven stack traces HTML en errores no anticipados, incluso cuando `APP_DEBUG=false`. El `ApiResponseMiddleware` sólo formatea respuestas 500+ genéricas; los errores de dominio sin try/catch no llegan formateados al cliente.

Los grupos más afectados:
- `app/Http/Controllers/Inventory/` — transferencias con TODO auth
- `app/Http/Controllers/Production/` — producción sin auth ni try/catch  
- `app/Http/Controllers/Admin/` — gestión de tickets con lógica compleja

**Fix recomendado:** Aprovechar el HTTP mapping ya existente en `bootstrap/app.php` — las excepciones de dominio se convierten automáticamente a JSON. Sólo agregar try/catch para excepciones inesperadas (QueryException, etc.) en endpoints críticos.

---

### A-03: `PosConsumptionService` eliminado pero su test aún existe
**Archivo:** `tests/Unit/Inventory/PosConsumptionServiceTest.php`

`app/Services/Operations/PosConsumptionService.php` fue eliminado (aparece como `D` en git status). El test referencia la clase eliminada y falla con `Class not found`. Debe eliminarse el test o decidirse si el servicio se recupera.

---

## 🟡 MEDIO — Backlog prioritario

### M-01: 110 TODOs de seguridad/auth sin resolver
Concentrados en:

| Archivo | TODOs críticos |
|---------|----------------|
| `TransferController.php` | 5 × "TODO: Usar auth real" |
| `InsumoController.php` | "TODO: autorización granular" |
| `EvidenceController.php` | "TODO: mover al storage definitivo o S3" |
| `CloseDaily.php` | "TODO: Replace with actual logic to get all branch IDs" |
| `PeopleController.php` | "TODO: protección con auth:sanctum" |

Los TODOs de autenticación se vuelven críticos cuando los endpoints están expuestos (ver C-01).

---

### M-02: 262 de 317 archivos PHP con violaciones de estilo (Pint)
El 83% del codebase no pasa `pint --test`. Las reglas más comunes: `single_quote`, `concat_space`, `ordered_imports`, `line_ending`. Es ruido que dificulta los diffs y reviews.

**Fix (Quick Win):** `./vendor/bin/pint` — auto-corrige todo en ~30 segundos. Hacer un commit dedicado.

---

### M-03: Dos TransferControllers en namespaces distintos
- `app/Http/Controllers/Api/Inventory/TransferController.php` — API JSON
- `app/Http/Controllers/Inventory/TransferController.php` — Blade views

Ambos manejan las mismas operaciones (create, approve, ship, receive, post) pero el segundo tiene más TODOs y menos lógica. El API controller es el canónico; el blade controller está a medio implementar y genera confusión.

---

### M-04: `ReplenishmentService` con `Item::find()` dentro de loop masivo
**Archivo:** `app/Services/Replenishment/ReplenishmentService.php:118`

```php
foreach ($policies as $policy) {
    $item = Item::find($policy->item_id); // N+1 para cada política
}
```

La replenishment puede evaluar decenas de políticas a la vez. Mismo patrón que A-01.

---

### M-05: `InventoryCountService` usa conexión `pgsql` hardcoded con schema `selemti`
**Archivo:** `app/Services/Inventory/InventoryCountService.php:15-16`

```php
protected string $connection = 'pgsql';
protected string $schema = 'selemti';
```

No usa el trait `ConfiguresReportConnection` disponible en `app/Traits/Reports/`. Inconsistente con otros servicios. Dificulta tests.

---

## 🔵 BAJO — Deuda técnica menor

### B-01: `ReceivingService` es un stub redundante de `ReceptionService`
**Archivo:** `app/Services/Inventory/ReceivingService.php`

100 líneas que sólo delegan a `ReceptionService` sin agregar lógica. El CLAUDE.md mismo lo nota: "Delete or implement `ReceivingService`". Nada en el codebase lo referencia excepto sus propios tests.

**Fix:** Eliminar `ReceivingService` y su test `ReceivingServiceTest`.

---

### B-02: `finalizeCosting()` en `ReceivingService` es un stub hardcodeado
**Archivo:** `app/Services/Inventory/ReceivingService.php:85-92`

```php
public function finalizeCosting(int $recepcionId, int $userId): array
{
    // ReceptionService maneja costeo en el posteo — marcamos como completado
    return ['recepcion_id' => $recepcionId, 'total_valorizado' => 0.0, 'status' => 'COSTO_FINAL_APLICADO'];
}
```

Retorna `total_valorizado: 0.0` siempre. Si algún consumidor confía en este valor, los costos serán incorrectos.

---

### B-03: `tmp_validate_recursion_*.php` y `verify_final.php` en raíz del proyecto
Archivos de depuración temporal en la raíz. No deben estar en el repositorio.

**Fix:** Agregar a `.gitignore` o eliminar.

---

### B-04: Dos grupos `Route::prefix('inventory/transfers')` con distinto middleware
- Línea 204: `inventory/transfers` sin auth (dentro del grupo `inventory`)
- Línea 280: `inventory/transfers` con `auth:sanctum`

El mismo prefix está definido dos veces. Las rutas del grupo con auth (línea 280) podrían ser sobreescritas o duplicadas por las de la línea 204 dependiendo del orden de resolución.

---

## Plan de Acción Priorizado

### Sprint inmediato (esta semana)

| # | Acción | Esfuerzo | Impacto |
|---|--------|----------|---------|
| 1 | Agregar `auth:sanctum` a `/inventory`, `/production`, `/catalogs`, `/purchasing`, `/unidades`, `/close`, `/reports` (líneas 172, 193, 295, 336, 353, 415, 50, 72) | 30 min | Crítico |
| 2 | Eliminar `?? 1` fallbacks una vez activo el auth | 1 h | Crítico |
| 3 | `./vendor/bin/pint` — fix de estilo masivo + commit dedicado | 5 min | Medio (limpieza) |
| 4 | Eliminar `ReceivingService` y su test | 15 min | Bajo |
| 5 | Eliminar `PosConsumptionServiceTest` o recuperar el servicio | 15 min | Bajo |

### Backlog (próximas 2 semanas)

| # | Acción | Esfuerzo | Impacto |
|---|--------|----------|---------|
| 6 | Pre-cargar items en loops de `ProductionService`, `InventoryCountService`, `ReceptionService`, `ReplenishmentService` | 2 h | Alto perf |
| 7 | Agregar try/catch a los 50+ métodos de controller sin cobertura (priorizar endpoints de escritura) | 4 h | Alto |
| 8 | Resolver los 15 TODOs de auth/seguridad (especialmente `PeopleController`, `InsumoController`) | 2 h | Alto |
| 9 | Consolidar los dos `TransferController` (eliminar el Blade, dejar sólo el API) | 3 h | Medio |
| 10 | Resolver prefix duplicado `inventory/transfers` en routes | 30 min | Medio |

---

## Métricas de Referencia

| Métrica | Valor actual | Objetivo |
|---------|-------------|----------|
| Rutas sin auth | ~8 grupos | 0 |
| `auth() ?? 1` fallbacks | 16 | 0 |
| TODOs en código | 110 | <20 |
| Archivos con style issues | 262 (83%) | 0 (0%) |
| N+1 patterns en servicios | 6+ | 0 |
| try/catch coverage controllers | 34% | >80% |
| Unit tests passing | 59/101 | >90/101 |
