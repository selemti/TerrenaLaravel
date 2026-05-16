# Codex Task: Stock Alerts API

**Branch:** `work/codex-stock-alerts` (create from `work/inicio-limpio-abril-2026`)  
**Assignee:** Codex  
**Scope:** Backend only — service, controller, route, tests. No UI.

---

## Context

TerrenaLaravel already has `selemti.stock_policy` (model: `App\Models\Inv\PoliticaStock`) storing min/max/reorder quantities per item+warehouse, and `selemti.vw_stock_brechas` which is referenced in `StockController::kpis()` for a count of low-stock items. However, there is no dedicated endpoint that returns the full list of items in alert state with actionable detail for buyers and warehouse managers.

**All models use `protected $connection = 'pgsql'` and `protected $table = 'selemti.<table>'`.**

---

## Objective

Implement `GET /api/inventory/alerts` — a paginated list of inventory alerts, each one identifying an item whose current stock is below its configured minimum, along with the shortage quantity and suggested reorder amount.

---

## Database Schema

### `selemti.stock_policy` — Min/max thresholds per item+warehouse

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `item_id` | VARCHAR(50) | FK to `selemti.items.id` (string) |
| `sucursal_id` | VARCHAR(36) nullable | Branch scope |
| `almacen_id` | VARCHAR(36) nullable | Warehouse scope |
| `min_qty` | NUMERIC(18,6) | Alert threshold in base UOM |
| `max_qty` | NUMERIC(18,6) nullable | Target stock level |
| `reorder_lote` | NUMERIC(18,6) nullable | Suggested order quantity |
| `activo` | BOOLEAN | Only active policies trigger alerts |

### Current stock calculation

Current stock for an item (optionally scoped to a warehouse) is:

```sql
SELECT COALESCE(SUM(COALESCE(m.cantidad, m.qty)), 0)
FROM selemti.mov_inv m
WHERE m.item_id = :item_id
  AND (:almacen_id IS NULL OR m.almacen_id = :almacen_id)
```

> Note: `mov_inv` uses column aliases — prefer `COALESCE(m.cantidad, m.qty)` to handle both column variants safely.

### Related tables

- `selemti.items` — `id` (string), `nombre`, `item_code`, `unidad_medida_id`, `costo_promedio`
- `selemti.cat_unidades` — `id`, `clave`, `nombre`
- `selemti.cat_almacenes` — `id`, `clave`, `nombre`

---

## Existing Models (use as-is)

```php
App\Models\Inv\PoliticaStock    // table: selemti.stock_policy
App\Models\Inv\Item              // table: selemti.items
App\Models\Catalogs\Unidad       // table: selemti.cat_unidades
App\Models\Catalogs\Almacen      // table: selemti.cat_almacenes
```

---

## Deliverables

### 1. `StockAlertService` — `app/Services/Inventory/StockAlertService.php`

```php
class StockAlertService
{
    public function getAlerts(array $filters): array
```

**`$filters` keys:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sucursal_id` | string\|null | null | Filter by branch |
| `almacen_id` | string\|null | null | Filter by warehouse |
| `severity` | string\|null | null | `critical` (stock=0), `low` (0<stock<min), or null (both) |
| `per_page` | int | 50 | Max 200 |
| `page` | int | 1 | |

**Return structure:**

```php
[
    'alerts'     => [...],   // paginated alert rows (see below)
    'summary'    => [
        'total_alerts'    => int,
        'critical'        => int,   // stock = 0
        'low'             => int,   // 0 < stock < min_qty
        'total_shortage'  => float, // sum of shortage_qty across all alerts
    ],
    'pagination' => [
        'page'      => int,
        'per_page'  => int,
        'total'     => int,
        'last_page' => int,
    ],
]
```

**Each alert row:**

```php
[
    'item_id'        => string,
    'item_code'      => string|null,
    'item_nombre'    => string,
    'uom_base'       => string,           // KG | L | PZ
    'current_stock'  => float,            // current qty in base UOM
    'min_qty'        => float,            // threshold from stock_policy
    'max_qty'        => float|null,       // target from stock_policy
    'shortage_qty'   => float,            // min_qty - current_stock (always > 0)
    'reorder_qty'    => float|null,       // reorder_lote from policy, or (max_qty - current_stock) if max_qty set
    'severity'       => string,           // 'critical' (stock=0) | 'low' (stock<min)
    'almacen'        => [
        'id'    => string,
        'clave' => string,
        'nombre'=> string,
    ] | null,
    'costo_promedio' => float|null,       // item.costo_promedio
    'costo_reponer'  => float|null,       // reorder_qty * costo_promedio
]
```

**Business rules:**
- Only include policies where `activo = true`
- Only include rows where `current_stock < min_qty`
- `severity = 'critical'` when `current_stock <= 0`, else `'low'`
- `reorder_qty`: use `reorder_lote` from policy if set; otherwise use `max_qty - current_stock` if `max_qty` is set; otherwise null
- `costo_reponer`: only if both `reorder_qty` and `costo_promedio` are non-null
- Sort by severity DESC (critical first), then shortage_qty DESC

**Performance note:** Calculate current stock per item+warehouse in a single aggregated query, not N+1 individual queries. Use a subquery or CTE joined against `stock_policy`.

### 2. `StockAlertController` — `app/Http/Controllers/Api/Inventory/StockAlertController.php`

```php
class StockAlertController extends Controller
{
    public function __construct(private StockAlertService $service) {}

    public function index(Request $request): JsonResponse
```

**Validation:**
```php
'sucursal_id' => 'nullable|string|max:36',
'almacen_id'  => 'nullable|string|max:36',
'severity'    => 'nullable|string|in:critical,low',
'per_page'    => 'nullable|integer|min:1|max:200',
'page'        => 'nullable|integer|min:1',
```

Response: `{ ok: true, data: <service result>, timestamp: <ISO> }`

### 3. Route — `routes/api.php`

Add inside the existing `Route::prefix('inventory')->middleware(['auth:sanctum'])` group:

```php
Route::get('/alerts', [StockAlertController::class, 'index']);
```

### 4. Tests — `tests/Feature/Services/Inventory/StockAlertServiceTest.php`

Minimum test cases:

```
test_returns_only_items_below_min_qty
test_critical_severity_when_stock_is_zero
test_low_severity_when_stock_between_zero_and_min
test_shortage_qty_calculated_correctly
test_reorder_qty_uses_reorder_lote_when_set
test_reorder_qty_falls_back_to_max_minus_current
test_severity_filter_critical_only
test_severity_filter_low_only
test_almacen_filter_scopes_stock_calculation
test_summary_counts_match_rows
test_pagination_works
test_inactive_policies_excluded
```

---

## Constraints

1. **PG 9.5** — no `ADD COLUMN IF NOT EXISTS`. Use `COALESCE(m.cantidad, m.qty)` for qty.
2. **Schema prefix** — all raw SQL uses `selemti.` prefix.
3. **String item IDs** — `items.id` is VARCHAR(50).
4. **No writes** — read-only endpoint.
5. **No N+1** — stock aggregation must be a single query joined to policy rows.
6. **Response envelope** — `{ ok: bool, data: any, timestamp: ISO }`.

---

## Reference pattern

Follow `app/Services/Inventory/KardexService.php` for the query style (DB::connection('pgsql'), COALESCE aliases, PHP-side enrichment). Follow `app/Http/Controllers/Api/Inventory/KardexController.php` for the controller pattern.

---

## Definition of Done

- [x] `StockAlertService::getAlerts()` implemented
- [x] `StockAlertController::index()` with validation
- [x] Route registered under `auth:sanctum`
- [x] All test cases pass
- [x] `php artisan test` — 0 failures (currently 276 passing)
- [x] No N+1 queries in stock aggregation
