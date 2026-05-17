# Codex Task: Inventory Valuation API

**Branch:** `work/codex-inventory-valuation` (create from `work/inicio-limpio-abril-2026`)  
**Assignee:** Codex  
**Scope:** Backend only — service, controller, route, tests. No UI.

---

## Context

TerrenaLaravel has a `selemti.vw_stock_valorizado` view already referenced in `StockController::kpis()` and `StockController::stockList()` for overview numbers. However there is no dedicated endpoint that returns a **full inventory valuation breakdown** — item by item, optionally scoped to a warehouse — with unit cost, quantity on hand, and total value. Finance and purchasing teams need this to close periods and track inventory exposure.

**All models use `protected $connection = 'pgsql'` and `protected $table = 'selemti.<table>'`.**

---

## Objective

Implement `GET /api/inventory/valuation` — paginated inventory valuation by item (and optionally warehouse), returning current stock × cost for each item, with an aggregate summary (total items valued, total inventory value).

---

## Database Schema

### Stock calculation

Current stock for an item scoped to a warehouse:

```sql
SELECT COALESCE(SUM(COALESCE(m.cantidad, m.qty)), 0)
FROM selemti.mov_inv m
WHERE m.item_id = :item_id
  AND (:almacen_id IS NULL OR m.almacen_id = :almacen_id)
```

> Use `COALESCE(m.cantidad, m.qty)` to handle both column name variants in `mov_inv`.

### `selemti.items` — relevant columns

| Column | Type | Notes |
|--------|------|-------|
| `id` | VARCHAR(50) PK | |
| `nombre` | VARCHAR(255) | |
| `item_code` | VARCHAR(100) nullable | |
| `costo_promedio` | NUMERIC(14,4) | Unit cost in base UOM |
| `unidad_medida_id` | VARCHAR(36) | FK to `cat_unidades.id` |
| `activo` | BOOLEAN | Only active items |
| `almacen_id` | VARCHAR(36) nullable | Default warehouse |

### `selemti.cat_unidades`

| Column | Type |
|--------|------|
| `id` | VARCHAR(36) PK |
| `clave` | VARCHAR(20) |
| `nombre` | VARCHAR(100) |

### `selemti.cat_almacenes`

| Column | Type |
|--------|------|
| `id` | VARCHAR(36) PK |
| `clave` | VARCHAR(20) |
| `nombre` | VARCHAR(100) |

---

## Existing Models (use as-is)

```php
App\Models\Inv\Item              // table: selemti.items
App\Models\Catalogs\Unidad       // table: selemti.cat_unidades
App\Models\Catalogs\Almacen      // table: selemti.cat_almacenes
```

---

## Deliverables

### 1. `InventoryValuationService` — `app/Services/Inventory/InventoryValuationService.php`

```php
class InventoryValuationService
{
    public function getValuation(array $filters): array
```

**`$filters` keys:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `almacen_id` | string\|null | null | Scope stock to this warehouse |
| `sucursal_id` | string\|null | null | Filter items by branch |
| `categoria` | string\|null | null | Filter by item category if column exists |
| `only_with_stock` | bool | true | Exclude items with stock ≤ 0 |
| `per_page` | int | 50 | Max 200 |
| `page` | int | 1 | |

**Return structure:**

```php
[
    'items'      => [...],     // paginated valuation rows
    'summary'    => [
        'total_items'      => int,     // rows returned (matching filters)
        'total_value'      => float,   // sum of valor_total across ALL matching items (not just page)
        'total_qty'        => float,   // sum of current_stock across ALL matching items
        'currency'         => 'MXN',
    ],
    'pagination' => [
        'page'      => int,
        'per_page'  => int,
        'total'     => int,
        'last_page' => int,
    ],
    'filters_applied' => [
        'almacen_id'    => string|null,
        'only_with_stock' => bool,
    ],
]
```

**Each valuation row:**

```php
[
    'item_id'       => string,
    'item_code'     => string|null,
    'item_nombre'   => string,
    'uom_base'      => string,         // KG | L | PZ
    'current_stock' => float,
    'costo_promedio'=> float|null,     // unit cost
    'valor_total'   => float|null,     // current_stock * costo_promedio
    'almacen'       => [
        'id'    => string,
        'clave' => string,
        'nombre'=> string,
    ] | null,
]
```

**Business rules:**
- Only active items (`activo = true`)
- When `only_with_stock = true` (default): exclude items where `current_stock <= 0`
- `valor_total = null` when `costo_promedio` is null or zero
- Stock aggregation must be a single query (no N+1 per item)
- Sort by `valor_total DESC` (highest value items first), NULL last
- `summary.total_value` and `summary.total_qty` must reflect ALL matching items, not just the current page

**Performance:** Use a single SQL query with a subquery/CTE joining items → stock aggregate → uom. Do not loop per item.

### 2. `InventoryValuationController` — `app/Http/Controllers/Api/Inventory/InventoryValuationController.php`

```php
class InventoryValuationController extends Controller
{
    public function __construct(private InventoryValuationService $service) {}

    public function index(Request $request): JsonResponse
```

**Validation:**
```php
'almacen_id'      => 'nullable|string|max:36',
'sucursal_id'     => 'nullable|string|max:36',
'only_with_stock' => 'nullable|boolean',
'per_page'        => 'nullable|integer|min:1|max:200',
'page'            => 'nullable|integer|min:1',
```

Response: `{ ok: true, data: <service result>, timestamp: <ISO> }`

**Middleware:** `auth:sanctum` only.

### 3. Route — `routes/api.php`

Add inside the existing `Route::prefix('inventory')->middleware(['auth:sanctum'])` group:

```php
Route::get('/valuation', [InventoryValuationController::class, 'index']);
```

### 4. Tests — `tests/Feature/Services/Inventory/InventoryValuationServiceTest.php`

```
test_returns_items_with_stock_and_cost
test_excludes_items_with_zero_stock_by_default
test_includes_zero_stock_items_when_flag_false
test_valor_total_is_stock_times_costo_promedio
test_valor_total_null_when_costo_promedio_is_null
test_summary_totals_match_all_matching_items_not_just_page
test_almacen_filter_scopes_stock_aggregation
test_only_active_items_returned
test_pagination_works
test_sort_by_valor_total_descending
```

---

## Constraints

1. **PG 9.5** — no window functions, no `ADD COLUMN IF NOT EXISTS`. Use `COALESCE(m.cantidad, m.qty)` for qty.
2. **Schema prefix** — all raw SQL uses `selemti.` prefix.
3. **String item IDs** — `items.id` is VARCHAR(50).
4. **No writes** — read-only endpoint.
5. **No N+1** — stock aggregation must be a single joined query.
6. **Response envelope** — `{ ok: bool, data: any, timestamp: ISO }`.

---

## Reference Pattern

Follow `app/Services/Inventory/StockAlertService.php` for the single-query stock aggregation pattern.  
Follow `app/Http/Controllers/Api/Inventory/StockAlertController.php` for controller pattern.

---

## Definition of Done

- [x] `InventoryValuationService::getValuation()` implemented with single-query stock aggregation
- [x] `InventoryValuationController::index()` with validation
- [x] Route registered under `auth:sanctum`
- [x] All test cases pass
- [x] `php artisan test` — 0 failures (338 passing)
- [x] No N+1 queries
- [x] `summary.total_value` sums all matching items, not just current page
