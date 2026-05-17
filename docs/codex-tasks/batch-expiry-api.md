# Codex Task: Batch Expiry Alerts API

**Branch:** `work/codex-batch-expiry` (create from `work/inicio-limpio-abril-2026`)  
**Assignee:** Codex  
**Scope:** Backend only — service, controller, route, tests. No UI.

---

## Context

TerrenaLaravel receives inventory into `selemti.inventory_batch` with an optional `fecha_caducidad` (expiry date). Currently there is no endpoint that surfaces lots nearing expiry. This matters for perishable items (proteins, dairy, produce) — the kitchen needs 7-day advance notice to rotate stock before waste occurs.

**All models use `protected $connection = 'pgsql'` and `protected $table = 'selemti.<table>'`.**

---

## Objective

Implement `GET /api/inventory/batches/expiring` — a list of inventory batches whose `fecha_caducidad` falls within a configurable horizon (default 7 days), with remaining quantity and cost exposure.

---

## Database Schema

### `selemti.inventory_batch`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `item_id` | VARCHAR(50) | FK to `selemti.items.id` |
| `lote` | VARCHAR(80) nullable | Lot/batch number |
| `fecha_caducidad` | DATE nullable | Expiry date — NULL means no expiry |
| `qty_inicial` | NUMERIC(18,6) | Original received quantity |
| `qty_actual` | NUMERIC(18,6) | Current quantity on hand |
| `costo_unit` | NUMERIC(14,4) nullable | Unit cost at reception |
| `uom_base` | VARCHAR(20) nullable | Base UOM clave |
| `almacen_id` | VARCHAR(36) nullable | FK to `cat_almacenes.id` |
| `created_at` | TIMESTAMPTZ | |

> If column names differ, check `database/migrations/` for the actual `inventory_batch` migration.

### Related tables

- `selemti.items` — `id` (VARCHAR(50)), `nombre`, `item_code`, `costo_promedio`
- `selemti.cat_almacenes` — `id`, `clave`, `nombre`
- `selemti.cat_unidades` — `id`, `clave`, `nombre`

---

## Existing Models (use as-is)

```php
App\Models\Inv\Item              // table: selemti.items
App\Models\Inv\LoteInventario    // table: selemti.inventory_batch (check actual table name in model)
App\Models\Catalogs\Almacen      // table: selemti.cat_almacenes
```

> **Important:** Verify the actual table name by reading `App\Models\Inv\LoteInventario`. If it doesn't exist or points to a different table, use `DB::connection('pgsql')` raw queries scoped to the correct table.

---

## Deliverables

### 1. `BatchExpiryService` — `app/Services/Inventory/BatchExpiryService.php`

```php
class BatchExpiryService
{
    public function getExpiringBatches(array $filters): array
```

**`$filters` keys:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `days` | int | 7 | Horizon: include batches expiring within N days from today |
| `almacen_id` | string\|null | null | Filter by warehouse |
| `include_expired` | bool | false | Also include already-expired batches (`fecha_caducidad < today`) |
| `only_with_qty` | bool | true | Exclude batches where `qty_actual <= 0` |
| `per_page` | int | 50 | Max 200 |
| `page` | int | 1 | |

**Return structure:**

```php
[
    'batches'    => [...],    // paginated batch rows
    'summary'    => [
        'expiring_soon'  => int,    // batches expiring within `days` horizon (qty > 0)
        'already_expired'=> int,    // batches past expiry date (qty > 0)
        'total_exposure' => float,  // sum of (qty_actual * costo_unit) across all expiring batches
    ],
    'pagination' => [
        'page'      => int,
        'per_page'  => int,
        'total'     => int,
        'last_page' => int,
    ],
    'query_date' => string,   // ISO date used as "today"
]
```

**Each batch row:**

```php
[
    'batch_id'        => int,
    'lote'            => string|null,
    'item_id'         => string,
    'item_code'       => string|null,
    'item_nombre'     => string,
    'uom_base'        => string|null,
    'qty_actual'      => float,
    'costo_unit'      => float|null,
    'valor_en_riesgo' => float|null,       // qty_actual * costo_unit
    'fecha_caducidad' => string,           // ISO date
    'dias_restantes'  => int,              // negative = already expired
    'estado'          => string,           // 'VENCIDO' | 'CRITICO' (≤2 days) | 'PROXIMO' (≤7) | 'OK' (>7)
    'almacen'         => [
        'id'    => string,
        'clave' => string,
        'nombre'=> string,
    ] | null,
]
```

**Business rules:**
- Only include batches where `fecha_caducidad IS NOT NULL`
- Default: include batches where `fecha_caducidad <= CURRENT_DATE + days`
- `include_expired = true`: also include `fecha_caducidad < CURRENT_DATE`
- `only_with_qty = true` (default): exclude batches where `qty_actual <= 0`
- `estado` logic:
  - `dias_restantes < 0` → `'VENCIDO'`
  - `dias_restantes <= 2` → `'CRITICO'`
  - `dias_restantes <= 7` → `'PROXIMO'`
  - `dias_restantes > 7` → `'OK'`
- Sort: `fecha_caducidad ASC` (soonest first), then `qty_actual DESC`

### 2. `BatchExpiryController` — `app/Http/Controllers/Api/Inventory/BatchExpiryController.php`

```php
class BatchExpiryController extends Controller
{
    public function __construct(private BatchExpiryService $service) {}

    public function index(Request $request): JsonResponse
```

**Validation:**
```php
'days'            => 'nullable|integer|min:1|max:365',
'almacen_id'      => 'nullable|string|max:36',
'include_expired' => 'nullable|boolean',
'only_with_qty'   => 'nullable|boolean',
'per_page'        => 'nullable|integer|min:1|max:200',
'page'            => 'nullable|integer|min:1',
```

Response: `{ ok: true, data: <service result>, timestamp: <ISO> }`

**Middleware:** `auth:sanctum` only.

### 3. Route — `routes/api.php`

Add inside the existing `Route::prefix('inventory')->middleware(['auth:sanctum'])` group:

```php
Route::get('/batches/expiring', [BatchExpiryController::class, 'index']);
```

### 4. Tests — `tests/Feature/Services/Inventory/BatchExpiryServiceTest.php`

```
test_returns_batches_within_default_7_day_horizon
test_respects_custom_days_filter
test_excludes_expired_by_default
test_includes_expired_when_flag_true
test_excludes_empty_batches_by_default
test_includes_empty_batches_when_flag_false
test_estado_vencido_when_past_expiry
test_estado_critico_within_2_days
test_estado_proximo_within_7_days
test_valor_en_riesgo_is_qty_times_costo
test_almacen_filter_works
test_sorted_by_fecha_caducidad_ascending
test_summary_counts_correct
test_pagination_works
test_null_fecha_caducidad_never_included
```

---

## Constraints

1. **PG 9.5** — no window functions, no `ADD COLUMN IF NOT EXISTS`.
2. **Schema prefix** — all raw SQL uses `selemti.` prefix. Never touch `public.*`.
3. **String item IDs** — `items.id` is VARCHAR(50).
4. **No writes** — read-only endpoint.
5. **Response envelope** — `{ ok: bool, data: any, timestamp: ISO }`.
6. **Date arithmetic** — use `CURRENT_DATE` in SQL; avoid passing PHP `date()` strings raw into queries.

---

## Reference Pattern

Follow `app/Services/Inventory/StockAlertService.php` for query style and controller pattern.

---

## Definition of Done

- [x] `BatchExpiryService::getExpiringBatches()` implemented
- [x] `BatchExpiryController::index()` with validation
- [x] Route registered under `auth:sanctum`
- [x] All test cases pass
- [x] `php artisan test` — 0 failures (338 passing)
- [x] `null` `fecha_caducidad` rows never appear in results
