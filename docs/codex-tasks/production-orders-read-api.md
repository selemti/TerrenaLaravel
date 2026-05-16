# Codex Task: Production Orders Read API

**Branch:** `work/codex-production-read-api` (create from `work/inicio-limpio-abril-2026`)  
**Assignee:** Codex  
**Scope:** Backend only — read endpoints (GET list + GET detail). No UI.

---

## Context

TerrenaLaravel has a `ProductionController` at `app/Http/Controllers/Production/ProductionController.php` with write-only operations (`plan`, `consume`, `complete`, `post`). The production orders table (`selemti.production_orders`) and its related tables exist and are populated, but there are no `GET` endpoints for the UI to list or inspect orders. Claude will build the Livewire UI on top of these endpoints — your job is the API layer.

**All models use `protected $connection = 'pgsql'` and `protected $table = 'selemti.<table>'`.**

---

## Objective

Add two read endpoints to the existing production route group:

- `GET /api/production/orders` — paginated list with filters
- `GET /api/production/orders/{id}` — full order detail with all lines

---

## Database Schema

### `selemti.production_orders`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `folio` | VARCHAR(40) nullable | Sequential order number |
| `recipe_id` | BIGINT nullable | FK to `selemti.receta_cab.id` (string) |
| `item_id` | BIGINT nullable | FK to `selemti.items.id` (string) |
| `qty_programada` | NUMERIC(18,6) | Planned quantity in base UOM |
| `qty_producida` | NUMERIC(18,6) | Actual produced quantity |
| `qty_merma` | NUMERIC(18,6) | Waste quantity |
| `uom_base` | VARCHAR(20) nullable | Base UOM clave |
| `sucursal_id` | VARCHAR(36) nullable | Branch |
| `almacen_id` | VARCHAR(36) nullable | Warehouse |
| `programado_para` | TIMESTAMPTZ nullable | Scheduled datetime |
| `iniciado_en` | TIMESTAMPTZ nullable | Started at |
| `cerrado_en` | TIMESTAMPTZ nullable | Closed/completed at |
| `estado` | VARCHAR(24) | `BORRADOR`, `EN_PROCESO`, `COMPLETADO`, `POSTEADO`, `CANCELADO` |
| `creado_por` | BIGINT nullable | FK to `selemti.users.id` |
| `aprobado_por` | BIGINT nullable | FK to `selemti.users.id` |
| `notas` | TEXT nullable | |
| `meta` | JSONB nullable | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

### `selemti.production_order_inputs` — Ingredients consumed

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `order_id` | BIGINT | FK to `production_orders.id` |
| `item_id` | VARCHAR(50) | Ingredient item ID |
| `qty_planned` | NUMERIC(18,6) | Planned consume qty in base UOM |
| `qty_actual` | NUMERIC(18,6) nullable | Actual consumed qty |
| `uom_base` | VARCHAR(20) nullable | |
| `lote_id` | BIGINT nullable | FK to `inventory_batch.id` |
| `costo_unit` | NUMERIC(14,4) nullable | |

### `selemti.production_order_outputs` — Products produced

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `order_id` | BIGINT | FK to `production_orders.id` |
| `item_id` | VARCHAR(50) | Output item ID |
| `qty_planned` | NUMERIC(18,6) | |
| `qty_actual` | NUMERIC(18,6) nullable | |
| `uom_base` | VARCHAR(20) nullable | |
| `lote_resultado` | VARCHAR(80) nullable | Resulting batch lot number |

> If these tables don't exist yet, check `database/migrations/2025_11_15_020000_create_production_tables.php` for the actual column names — use whatever is in that migration.

---

## Existing Models and Services (use as-is, do not recreate)

```php
App\Models\Rec\OrdenProduccion      // table: selemti.op_produccion_cab (legacy model, may differ from production_orders)
App\Models\Rec\Receta               // table: receta_cab (uses pgsql connection + search_path)
App\Models\Inv\Item                 // table: selemti.items
App\Models\Catalogs\Almacen         // table: selemti.cat_almacenes
App\Models\Catalogs\Unidad          // table: selemti.cat_unidades
```

> **Important:** `production_orders` is the table created by `ProductionService::createOrder()`. `op_produccion_cab` is the older `OrdenProduccion` model. The service writes to `production_orders` — use that table for the read API. If there's ambiguity, read `ProductionService` to confirm which table it writes to.

---

## Deliverables

### 1. `ProductionOrderReadService` — `app/Services/Production/ProductionOrderReadService.php`

```php
class ProductionOrderReadService
{
    public function list(array $filters): array
    public function detail(int $orderId): array
```

#### `list(array $filters)` filters:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `estado` | string\|null | null | Filter by status |
| `sucursal_id` | string\|null | null | Filter by branch |
| `from` | string (Y-m-d)\|null | null | `programado_para` start |
| `to` | string (Y-m-d)\|null | null | `programado_para` end |
| `recipe_id` | int\|null | null | Filter by recipe |
| `per_page` | int | 25 | Max 100 |
| `page` | int | 1 | |

**List row structure:**

```php
[
    'id'              => int,
    'folio'           => string|null,
    'estado'          => string,
    'estado_label'    => string,          // human label
    'recipe'          => ['id' => int, 'nombre' => string] | null,
    'item_producido'  => ['id' => string, 'nombre' => string, 'uom_base' => string] | null,
    'qty_programada'  => float,
    'qty_producida'   => float,
    'qty_merma'       => float,
    'pct_cumplimiento'=> float|null,      // (qty_producida / qty_programada) * 100, null if qty_programada = 0
    'programado_para' => string|null,     // ISO 8601
    'iniciado_en'     => string|null,
    'cerrado_en'      => string|null,
    'almacen'         => ['id' => string, 'nombre' => string] | null,
    'creado_por'      => string|null,     // user name
    'created_at'      => string,
]
```

**`estado_label` mapping:**

| estado | label |
|--------|-------|
| BORRADOR | Borrador |
| EN_PROCESO | En proceso |
| COMPLETADO | Completado |
| POSTEADO | Posteado |
| CANCELADO | Cancelado |

Return:
```php
[
    'orders'     => [...],
    'pagination' => ['page', 'per_page', 'total', 'last_page'],
]
```

#### `detail(int $orderId)` — Full order with lines

Return 404-friendly: throw `\Illuminate\Database\Eloquent\ModelNotFoundException` if not found (the controller catches it).

```php
[
    'id'             => int,
    'folio'          => string|null,
    'estado'         => string,
    'estado_label'   => string,
    'recipe'         => ['id' => int, 'nombre' => string, 'version' => string|null] | null,
    'item_producido' => ['id' => string, 'nombre' => string, 'uom_base' => string] | null,
    'qty_programada' => float,
    'qty_producida'  => float,
    'qty_merma'      => float,
    'pct_cumplimiento'=> float|null,
    'uom_base'       => string|null,
    'sucursal_id'    => string|null,
    'almacen'        => ['id' => string, 'clave' => string, 'nombre' => string] | null,
    'programado_para'=> string|null,
    'iniciado_en'    => string|null,
    'cerrado_en'     => string|null,
    'notas'          => string|null,
    'creado_por'     => string|null,
    'aprobado_por'   => string|null,
    'inputs'         => [   // ingredients consumed
        [
            'item_id'     => string,
            'item_nombre' => string,
            'uom_base'    => string|null,
            'qty_planned' => float,
            'qty_actual'  => float|null,
            'costo_unit'  => float|null,
            'costo_total' => float|null,  // qty_actual * costo_unit
            'lote_id'     => int|null,
        ],
        ...
    ],
    'outputs'        => [   // products produced
        [
            'item_id'       => string,
            'item_nombre'   => string,
            'uom_base'      => string|null,
            'qty_planned'   => float,
            'qty_actual'    => float|null,
            'lote_resultado'=> string|null,
        ],
        ...
    ],
    'created_at'     => string,
    'updated_at'     => string,
]
```

### 2. `ProductionOrderController` — `app/Http/Controllers/Production/ProductionOrderController.php`

```php
class ProductionOrderController extends Controller
{
    public function __construct(private ProductionOrderReadService $service) {}

    public function index(Request $request): JsonResponse
    public function show(Request $request, int $id): JsonResponse
```

**`index` validation:**
```php
'estado'      => 'nullable|string|in:BORRADOR,EN_PROCESO,COMPLETADO,POSTEADO,CANCELADO',
'sucursal_id' => 'nullable|string|max:36',
'from'        => 'nullable|date_format:Y-m-d',
'to'          => 'nullable|date_format:Y-m-d|after_or_equal:from',
'recipe_id'   => 'nullable|integer',
'per_page'    => 'nullable|integer|min:1|max:100',
'page'        => 'nullable|integer|min:1',
```

**`show`:** return 404 `{ ok: false, error: 'order_not_found' }` if order doesn't exist.

Both return `{ ok: true, data: <result>, timestamp: <ISO> }`.

**Middleware:** `auth:sanctum` only (no extra permission gate — this is read-only).

### 3. Routes — `routes/api.php`

Add inside the existing `Route::prefix('production')->middleware(['auth:sanctum'])` group:

```php
Route::get('/orders', [ProductionOrderController::class, 'index']);
Route::get('/orders/{id}', [ProductionOrderController::class, 'show']);
```

### 4. Tests — `tests/Feature/Services/Production/ProductionOrderReadServiceTest.php`

```
test_list_returns_paginated_orders
test_list_filters_by_estado
test_list_filters_by_date_range
test_list_includes_recipe_and_item_names
test_pct_cumplimiento_calculated
test_detail_returns_full_order
test_detail_includes_inputs_and_outputs
test_detail_throws_not_found_for_unknown_id
test_estado_label_mapped_correctly
```

---

## Constraints

1. **PG 9.5** — no window functions needed here; no `ADD COLUMN IF NOT EXISTS`.
2. **Schema prefix** — `selemti.` on all raw queries.
3. **String item IDs** — `items.id` is VARCHAR(50).
4. **Read-only** — zero writes.
5. **Table name** — use `selemti.production_orders` (written by `ProductionService`), not `selemti.op_produccion_cab` (legacy model).
6. **Response envelope** — `{ ok, data, timestamp }`.

---

## Reference

- `app/Http/Controllers/Production/ProductionController.php` — existing controller in the same namespace; follow the same response pattern
- `app/Services/Inventory/KardexService.php` — follow DB::connection('pgsql') + enrichment pattern

---

## Definition of Done

- [ ] `ProductionOrderReadService::list()` and `::detail()` implemented
- [ ] `ProductionOrderController::index()` and `::show()` with validation and 404 handling
- [ ] Routes registered under `auth:sanctum`
- [ ] All test cases pass
- [ ] `php artisan test` — 0 failures (currently 255 passing)
- [ ] No references to `op_produccion_cab` — use `production_orders`
