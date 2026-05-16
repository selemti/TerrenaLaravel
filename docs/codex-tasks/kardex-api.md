# Codex Task: Kardex API — Full Inventory Ledger Endpoint

**Branch:** `work/codex-kardex-api` (create from `work/inicio-limpio-abril-2026`)  
**Assignee:** Codex  
**Scope:** Backend only — controller, service, route, tests. No Livewire UI (Claude handles that separately).

---

## Context

TerrenaLaravel is a Laravel 12 restaurant ERP on PostgreSQL 9.5 (`selemti` schema).  
The existing `StockController::kardex()` (routes/api.php line ~161) is a minimal stub: no pagination, no enrichment, no running balance, no cost data. This task replaces/extends it with a production-grade Kardex endpoint used by the inventory UI and management reports.

**All models use `protected $connection = 'pgsql'` and `protected $table = 'selemti.<table>'`.**

---

## Objective

Implement `GET /api/inventory/items/{itemId}/kardex` as a full inventory ledger (libro mayor de inventario) with:

- Complete movement data with human-readable context
- Running stock balance per row (saldo acumulado)
- Both base-UOM and original-UOM quantities
- Cost data per movement (unit cost + line total)
- Lot/batch traceability
- Source/destination for transfers
- Filters: date range, warehouse, movement type
- Pagination
- Opening balance row before the filtered period (saldo inicial)

---

## Database Schema

### `selemti.mov_inv` — Core ledger table

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `item_id` | VARCHAR(50) | FK to `selemti.items.id` (string, not int) |
| `inventory_batch_id` | BIGINT nullable | FK to `selemti.inventory_batch.id` (alias: `lote_id` in model) |
| `tipo` | VARCHAR(24) | `ENTRADA`, `SALIDA`, `AJUSTE`, `MERMA`, `PRODUCCION`, `CONSUMO`, `TRASPASO_SALIDA`, `TRASPASO_ENTRADA` |
| `qty` | NUMERIC(18,6) | Quantity in base UOM (canonical) |
| `qty_original` | NUMERIC(18,6) | Quantity in original UOM as recorded |
| `uom` | VARCHAR(20) | Base UOM clave (KG, L, PZ) |
| `uom_original_id` | BIGINT nullable | FK to `selemti.cat_unidades.id` |
| `costo_unit` | NUMERIC(14,4) | Unit cost in base UOM |
| `sucursal_id` | VARCHAR(36) | Origin branch |
| `sucursal_dest` | VARCHAR(36) nullable | Destination branch (transfers) |
| `almacen_id` | VARCHAR(36) nullable | Origin warehouse |
| `ref_tipo` | VARCHAR(40) | Source document type: `RECEPCION`, `AJUSTE_MANUAL`, `PRODUCCION`, `TRASPASO`, `CONTEO_FISICO`, `CONSUMO_POS` |
| `ref_id` | BIGINT nullable | Source document ID |
| `usuario_id` | BIGINT nullable | FK to `users.id` |
| `ts` | TIMESTAMPTZ | Movement timestamp |
| `notas` | TEXT nullable | Free notes |
| `meta` | JSONB nullable | Extra metadata |

### Related tables (for enrichment)

- `selemti.items` — `id` (string), `nombre`, `item_code`, `unidad_medida_id`, `costo_promedio`
- `selemti.cat_unidades` — `id`, `clave`, `nombre` (UOM catalog)
- `selemti.inventory_batch` — `id`, `lote_proveedor`, `fecha_recepcion`, `fecha_caducidad`
- `selemti.cat_almacenes` — `id`, `clave`, `nombre`, `sucursal_id`
- `selemti.users` — `id`, `name`

---

## Existing Models (use as-is, do not recreate)

```php
App\Models\Inv\MovimientoInventario   // table: selemti.mov_inv
App\Models\Inv\Item                   // table: selemti.items
App\Models\Inv\Batch                  // table: selemti.inventory_batch
App\Models\Catalogs\Unidad            // table: selemti.cat_unidades
App\Models\Catalogs\Almacen           // table: selemti.cat_almacenes
```

---

## Deliverables

### 1. `KardexService` — `app/Services/Inventory/KardexService.php`

```php
class KardexService
{
    public function getKardex(string $itemId, array $filters): array
```

**`$filters` keys:**
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `from` | string (Y-m-d) | 30 days ago | Start date (inclusive) |
| `to` | string (Y-m-d) | today | End date (inclusive) |
| `almacen_id` | string\|null | null | Filter by warehouse |
| `tipo` | string\|null | null | Filter by movement type |
| `per_page` | int | 50 | Items per page (max 200) |
| `page` | int | 1 | Page number |

**Return structure:**

```php
[
    'item'            => [...],   // item summary (id, code, nombre, uom_base)
    'opening_balance' => float,   // stock qty in base UOM before `from` date
    'movements'       => [...],   // paginated movement rows (see below)
    'closing_balance' => float,   // opening_balance + net movement in period
    'totals'          => [
        'entradas'    => float,   // sum of all positive movements
        'salidas'     => float,   // sum of all negative movements
        'net'         => float,   // entradas - salidas
        'costo_total' => float,   // sum of (qty * costo_unit) for all rows
    ],
    'pagination' => [
        'page'       => int,
        'per_page'   => int,
        'total'      => int,
        'last_page'  => int,
    ],
]
```

**Each movement row:**

```php
[
    'id'             => int,
    'ts'             => string,           // ISO 8601
    'tipo'           => string,           // ENTRADA | SALIDA | AJUSTE | ...
    'tipo_label'     => string,           // human label: "Recepción de compra", "Consumo POS", etc.
    'signo'          => int,              // +1 or -1 (entradas positive, salidas negative)
    'qty_base'       => float,            // quantity in base UOM
    'uom_base'       => string,           // KG | L | PZ
    'qty_original'   => float|null,       // quantity in original UOM
    'uom_original'   => string|null,      // original UOM clave
    'costo_unit'     => float|null,       // cost per base unit
    'costo_total'    => float|null,       // qty_base * costo_unit
    'saldo'          => float,            // running balance after this movement
    'ref_tipo'       => string|null,      // RECEPCION | AJUSTE_MANUAL | ...
    'ref_id'         => int|null,         // source document ID
    'lote'           => [                 // null if no batch
        'id'            => int,
        'lote_proveedor'=> string|null,
        'fecha_caducidad'=> string|null,
    ] | null,
    'almacen'        => [                 // null if no warehouse
        'id'    => string,
        'clave' => string,
        'nombre'=> string,
    ] | null,
    'almacen_dest'   => [...] | null,     // destination warehouse (transfers only)
    'usuario'        => string|null,      // user name
    'notas'          => string|null,
]
```

**Business rules:**
- `signo`: `ENTRADA`, `TRASPASO_ENTRADA`, `AJUSTE` (if qty > 0) → +1. Everything else → -1
- `tipo_label` mapping (minimum set, extend as needed):

| tipo | ref_tipo | label |
|------|----------|-------|
| ENTRADA | RECEPCION | Recepción de compra |
| ENTRADA | PRODUCCION | Entrada por producción |
| SALIDA | CONSUMO_POS | Consumo POS |
| SALIDA | PRODUCCION | Consumo en producción |
| TRASPASO_SALIDA | TRASPASO | Traspaso salida |
| TRASPASO_ENTRADA | TRASPASO | Traspaso entrada |
| AJUSTE | CONTEO_FISICO | Ajuste por conteo |
| AJUSTE | AJUSTE_MANUAL | Ajuste manual |
| MERMA | * | Merma / pérdida |

- `opening_balance`: sum of `qty` in `mov_inv` WHERE `item_id = ?` AND `ts < :from` (and `almacen_id = ?` if filter active)
- `closing_balance` = `opening_balance` + sum of `qty * signo` for the period rows
- `saldo` per row: computed in PHP as a running total starting from `opening_balance`, iterating oldest→newest. Return rows newest→oldest in the response (reverse after computing).
- Paginate AFTER computing running balances (sort by ts DESC for display, but compute balance ascending first)
- Use `DB::connection('pgsql')` for all raw queries; use Eloquent with eager-loads for enrichment

### 2. `KardexController` — `app/Http/Controllers/Api/Inventory/KardexController.php`

```php
class KardexController extends Controller
{
    public function __construct(private KardexService $service) {}

    public function show(Request $request, string $itemId): JsonResponse
```

**Validation rules:**
```php
'from'       => 'nullable|date_format:Y-m-d',
'to'         => 'nullable|date_format:Y-m-d|after_or_equal:from',
'almacen_id' => 'nullable|string|max:36',
'tipo'       => 'nullable|string|in:ENTRADA,SALIDA,AJUSTE,MERMA,PRODUCCION,CONSUMO,TRASPASO_SALIDA,TRASPASO_ENTRADA',
'per_page'   => 'nullable|integer|min:1|max:200',
'page'       => 'nullable|integer|min:1',
```

- Return 404 with `{ ok: false, error: 'item_not_found' }` if item doesn't exist
- Return 200 with `{ ok: true, data: <KardexService result>, timestamp: <ISO> }`

### 3. Route registration — `routes/api.php`

Replace the existing minimal `kardex()` stub under `GET /api/inventory/items/{id}/kardex` with:

```php
Route::get('/items/{itemId}/kardex', [KardexController::class, 'show']);
```

Make sure the import for `KardexController` is added. The route is already inside the `auth:sanctum` middleware group.

### 4. Tests — `tests/Feature/Services/Inventory/KardexServiceTest.php`

Minimum test coverage:

```
test_returns_item_summary_with_uom
test_opening_balance_calculated_before_from_date
test_running_balance_computed_correctly
test_closing_balance_matches_opening_plus_net
test_tipo_label_mapped_correctly
test_date_filter_applied
test_almacen_filter_applied
test_tipo_filter_applied
test_pagination_works
test_empty_period_returns_zero_totals
test_404_for_unknown_item
```

Use the `pgsql` test DB (configured in `phpunit.xml`). Use factories/DB seeding for `mov_inv` rows. Do NOT use SQLite mocks for this test — the service queries real PostgreSQL features (JSONB, TIMESTAMPTZ).

---

## Constraints

1. **PG 9.5 compatibility** — no `ADD COLUMN IF NOT EXISTS`. No window functions if avoidable (compute running balance in PHP instead).
2. **Schema prefix required** — all raw SQL must use `selemti.` prefix: `DB::connection('pgsql')->table('selemti.mov_inv')`.
3. **String item IDs** — `items.id` is VARCHAR(50), never cast to int.
4. **Do not modify** `mov_inv` schema or existing `StockController` methods other than replacing the kardex stub.
5. **Response envelope** — always `{ ok: bool, data: any, timestamp: ISO }`.
6. **No write operations** — this endpoint is read-only. Zero inserts/updates.

---

## Reference: Existing Pattern

`app/Http/Controllers/Api/Inventory/StockController.php` — follow its constructor injection pattern, validation style, and response format.

`app/Services/Inventory/ReceptionService.php` — follow its DB transaction and eager-load patterns (even though this service is read-only).

---

## Definition of Done

- [x] `KardexService::getKardex()` implemented with all fields above
- [x] `KardexController::show()` with proper validation and 404 handling
- [x] Route registered under `auth:sanctum` group
- [x] All test cases in `KardexServiceTest` pass
- [x] `php artisan test` — 0 failures (currently 255 passing)
- [x] No references to `App\Models\Inventory\*` namespace (use `App\Models\Inv\*`)
- [x] No hardcoded schema without `selemti.` prefix
