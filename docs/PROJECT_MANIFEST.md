# TerrenaLaravel — Project Manifest

> **Living document.** Every AI agent (Claude, Codex, Gemini) MUST update the relevant section when completing a delegated task.  
> Last updated: 2026-05-16 — 338 tests passing | Branch: `work/inicio-limpio-abril-2026`

---

## Quick Status

| Layer | Done | In Progress | Pending |
|-------|------|-------------|---------|
| Domain Models | ✅ 47 models, 8 domains | — | — |
| Domain Exceptions | ✅ 21 exceptions, 6 domains | — | Pos/, Recetas/ still generic |
| Value Objects | ✅ Money, BaseQuantity, Variance, SequentialFolio, DateRange | — | — |
| Domain Events | ✅ Defined + dispatched from services | — | — |
| Anti-Corruption Layer | ✅ FloreantPosAdapter | — | — |
| API Endpoints | ✅ ~180 routes, 19 groups | Codex: stock-alerts, production-read | Kardex UI |
| Services | ✅ 48 services | — | — |
| Livewire UI | ✅ 73 components | Claude: Domain Events done | KardexView wiring, Production UI review |
| Tests | ✅ 276 + 37 DDD nuevos = 313 passing | — | — |
| Migrations | ✅ 29/29 ran | — | — |

---

## Module Status

### 🗄️ Inventory (Inv/)

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | `Inv\Item`, `Inv\Batch`, `Inv\MovimientoInventario`, `Inv\PerdidaLog`, `Inv\HistorialCostoItem`, `Inv\ItemProveedor`, `Inv\ItemVendor`, `Inv\LoteInventario`, `Inv\ParametroSucursal`, `Inv\PoliticaStock`, `Inv\ConversionUnidad`, `Inv\Movimiento` | ✅ | All have `$connection = 'pgsql'` |
| **ReceptionService** | `Services/Inventory/ReceptionService.php` | ✅ | `createFromPurchaseOrder`, `setLines`, `finalizeCosting`, `postReception` — dispatches `ReceptionPosted` |
| **TransferService** | `Services/Inventory/TransferService.php` | ✅ | Full state machine, dispatches `TransferPosted` |
| **KardexService** | `Services/Inventory/KardexService.php` | ✅ | Running balance, pagination, enrichment — Codex |
| **StockAlertService** | `Services/Inventory/StockAlertService.php` | ✅ | Low stock alerts vs `stock_policy` — Codex |
| **InventoryCountService** | `Services/Inventory/InventoryCountService.php` | ✅ | `createCount`, variance, adjustments — Codex |
| **UomConversionService** | `Services/Inventory/UomConversionService.php` | ✅ | `resolveToBase`, 3 canonical UOMs |
| **KardexController** | `Controllers/Api/Inventory/KardexController.php` | ✅ | `GET /api/inventory/items/{id}/kardex` |
| **StockAlertController** | `Controllers/Api/Inventory/StockAlertController.php` | ✅ | `GET /api/inventory/alerts` — Codex |
| **StockController** | `Controllers/Api/Inventory/StockController.php` | ✅ | kpis, stockList, batches, createMovement |
| **ItemController** | `Controllers/Api/Inventory/ItemController.php` | ✅ | CRUD |
| **Livewire: ItemsIndex** | `Livewire/Inventory/ItemsIndex.php` | ✅ | |
| **Livewire: KardexView** | `Livewire/Inventory/KardexView.php` | ⚠️ | Exists but may need wiring to new KardexService |
| **Livewire: ReceptionsIndex** | `Livewire/Inventory/ReceptionsIndex.php` | ✅ | |
| **Livewire: ReceptionCreate/Detail** | `Livewire/Inventory/ReceptionCreate.php`, `ReceptionDetail.php` | ✅ | |
| **Livewire: TransferDetail/Dispatch/Receive** | `Livewire/Transfers/` | ✅ | |
| **Livewire: AlertsList** | `Livewire/Inventory/AlertsList.php` | ✅ | |

**Pending:** Wire `KardexView` to `KardexService` (currently may use old stub).

---

### 🍳 Recipes (Rec/)

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | `Rec\Receta`, `Rec\RecetaDetalle`, `Rec\RecetaVersion`, `Rec\RecetaShadow`, `Rec\RecipeCostSnapshot`, `Rec\OrdenProduccion`, `Rec\Modificador` | ✅ | All have `$connection = 'pgsql'` |
| **RecipeCostService** | `Services/Recetas/RecipeCostService.php` | ✅ | `calculateCostAtDate`, `fn_recipe_cost_at` |
| **RecipeCostSnapshotService** | `Services/Recipes/RecipeCostSnapshotService.php` | ✅ | Manual + auto snapshots |
| **RecipeVersionService** | `Services/Recetas/RecipeVersionService.php` | ✅ | Versioning workflow |
| **RecipeCostController** | `Controllers/Api/Inventory/RecipeCostController.php` | ✅ | BOM implosion, snapshots, cost history |
| **Livewire: RecipesIndex** | `Livewire/Recipes/RecipesIndex.php` | ✅ | |
| **Livewire: RecipeEditor** | `Livewire/Recipes/RecipeEditor.php` | ✅ | |
| **Livewire: VersionActivator/Comparator** | `Livewire/Recipes/VersionActivator.php` etc. | ✅ | |

**Pending:** Nothing critical.

---

### 🏭 Production

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Model: OrdenProduccion** | `Rec\OrdenProduccion` → `selemti.op_produccion_cab` | ⚠️ | Legacy model; `production_orders` is the active table |
| **ProductionService** | `Services/Production/ProductionService.php` | ✅ | `planBatch`, `consumeIngredients`, `completeBatch`, `postBatchToInventory` |
| **ProductionOrderReadService** | `Services/Production/ProductionOrderReadService.php` | ✅ | `list()`, `detail()` — Codex |
| **ProductionController (write)** | `Controllers/Production/ProductionController.php` | ✅ | plan, consume, complete, post |
| **ProductionOrderController (read)** | `Controllers/Production/ProductionOrderController.php` | ✅ | `GET /api/production/orders`, `GET /api/production/orders/{id}` — Codex |
| **Livewire: OrdersIndex** | `Livewire/Production/OrdersIndex.php` | ✅ | State names aligned (COMPLETADO/CANCELADO), filters correct |
| **Livewire: OrderCreate** | `Livewire/Production/OrderCreate.php` | ✅ | Reviewed — correct |
| **Livewire: OrderDetail** | `Livewire/Production/OrderDetail.php` | ✅ | State names corrected (CANCELADO), transitions OK |
| **Livewire: OrderCapture** | `Livewire/Production/OrderCapture.php` | ✅ | COMPLETADO corrected, column names match migration |

**Reviewed:** All 4 Production Livewire components aligned to production_orders schema and ProductionOrderReadService states.

---

### 🛒 Purchasing

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | `PurchaseRequest`, `PurchaseRequestLine`, `PurchaseOrder`, `PurchaseSuggestion`, `PurchaseSuggestionLine` | ✅ | All `$connection = 'pgsql'` |
| **PurchasingService** | `Services/Purchasing/PurchasingService.php` | ✅ | Full procurement workflow — Codex |
| **ReturnService** | `Services/Purchasing/ReturnService.php` | ✅ | |
| **ReplenishmentService** | `Services/Replenishment/ReplenishmentService.php` | ✅ | |
| **ReplenishmentController** | `Controllers/Api/Purchasing/ReplenishmentController.php` | ✅ | suggestions, calculate, approve |
| **Livewire: Requests/** | `Livewire/Purchasing/Requests/Index, Create, Detail` | ✅ | |
| **Livewire: Orders/** | `Livewire/Purchasing/Orders/Index, Detail` | ✅ | |
| **Exceptions** | `Purchasing/` (4 exceptions) | ✅ | |

**Pending:** Nothing critical.

---

### 💰 Cash Fund (Caja Chica)

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | Root models: `CashFund`, `CashFundMovement`, `CashFundSettlement` (no `Models/CashFund/` dir) | ✅ | |
| **CashFundService** | `Services/Cash/CashFundService.php` | ✅ | Full state machine + audit |
| **Livewire: 6 components** | `Livewire/CashFund/Index, Detail, Create, Movements, Settlements, Approvals` | ✅ | |
| **Exceptions** | `CashFund/` (2 exceptions) | ✅ | |

**Pending:** Nothing critical.

---

### 🏪 Caja (POS Integration)

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | `Caja\SesionCajon`, `Caja\Precorte`, `Caja\Postcorte`, `Caja\Terminal`, `Caja\FormasPago`, `Caja\TicketItemModifier` | ✅ | `$connection = 'pgsql'` |
| **Anti-Corruption Layer** | `Adapters/FloreantPos/FloreantPosAdapter.php` | ✅ | Centralizes all `public.*` reads |
| **DTOs** | `Adapters/FloreantPos/Dtos/PosTicketDto`, `PosMenuModifierDto` | ✅ | |
| **Controllers** | `Api/Caja/` — 10 controllers (auth, cajas, precorte, postcorte, sesiones, conciliación, etc.) | ✅ | |
| **AuthController** | `Api/Caja/AuthController.php` | ✅ | Accepts `email` or `username` |
| **`fn_postcorte_after_insert`** | PostgreSQL trigger | ⚠️ | Migration + backfill ready — apply on prod when tables exist |

**Pending:** Run `2026_05_16_000000_fix_postcorte_trigger_sales.php` on staging/prod + execute `database/sql/postcorte_backfill.sql` to populate existing NULL rows.

---

### 📊 Reports

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Controllers** | `Controllers/Reports/` — 11 controllers | ✅ | |
| **Services** | `Services/Reports/` — 4 services | ✅ | ItemMods, SalesExceptions, Products, Export |
| **Livewire** | `Livewire/Reports/Dashboard, DrillDown` | ✅ | |
| **OpenAPI** | `docs/api-spec.yml` | ✅ | 90+ endpoints documented |

---

### 🧾 Inventory Count

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | Root: `InventoryCount`, `InventoryCountLine` (+ thin wrappers in `Inventory/`) | ✅ | `$connection = 'pgsql'` |
| **InventoryCountService** | `Services/Inventory/InventoryCountService.php` | ✅ | `createCount`, variance, adjustments — Codex |
| **Livewire: 5 components** | `Livewire/InventoryCount/Index, Create, Capture, Detail, Review` | ✅ | |

---

### 📦 Catalogs

| Component | File / Class | Status | Notes |
|-----------|-------------|--------|-------|
| **Models** | `Catalogs\Almacen`, `Catalogs\Sucursal`, `Catalogs\Unidad`, `Catalogs\Proveedor`, `Catalogs\StockPolicy`, `Catalogs\UomConversion` | ✅ | |
| **UomConversionService** | `Services/Inventory/UomConversionService.php` | ✅ | |
| **Livewire: 6 components** | `Livewire/Catalogs/` | ✅ | |

---

## Domain Architecture Status

| DDD Component | Status | Location |
|---------------|--------|----------|
| Domain Exceptions | ✅ 21 exceptions, 6 domains | `app/Exceptions/` |
| Value Objects | ✅ Money, BaseQuantity, Variance, SequentialFolio | `app/ValueObjects/` |
| Value Object: DateRange | ✅ Implemented | `app/ValueObjects/DateRange.php` |
| Domain Events: ReceptionPosted | ✅ Defined + dispatched | `app/Events/Inventory/` |
| Domain Events: TransferPosted | ✅ Defined + dispatched | `app/Events/Inventory/` |
| Domain Events: PosTicketIngested | ✅ Defined + dispatched from PosConsumptionService | `app/Events/Pos/` |
| Listeners: LogReceptionPosted | ✅ | `app/Listeners/Inventory/` |
| Listeners: LogTransferPosted | ✅ | `app/Listeners/Inventory/` |
| Listeners: InvalidateStockCache | ✅ | `app/Listeners/Inventory/` |
| Anti-Corruption Layer | ✅ FloreantPosAdapter + 2 DTOs | `app/Adapters/FloreantPos/` |
| State Machines (formal) | ✅ ReceptionHeader with assertCanTransitionTo + can*() | — | Transfer is already formalized via can*() on model |
| Repository Pattern (Pos) | ✅ 5 repositories | `app/Services/Pos/Repositories/` |

---

## Current Agent Assignments

| Agent | Task | Branch | Status |
|-------|------|--------|--------|
| **Codex** | Stock Alerts API | `work/codex-stock-alerts` | ✅ Done — integrated |
| **Codex** | Production Orders Read API | `work/codex-production-read-api` | ✅ Done — integrated |
| **Codex** | Inventory Valuation API | `work/codex-inventory-valuation` | ✅ Done — integrated (338 tests) |
| **Codex** | Batch Expiry Alerts API | `work/codex-batch-expiry` | ✅ Done — integrated (338 tests) |
| **Claude** | Domain Events wiring | `work/inicio-limpio-abril-2026` | ✅ Done |
| **Claude** | DateRange Value Object | `work/inicio-limpio-abril-2026` | 🔜 Next |
| **Claude** | auth:sanctum on /api/caja/* | `work/inicio-limpio-abril-2026` | 🔜 Next |
| **Claude** | PosTicketIngested wiring | `work/inicio-limpio-abril-2026` | 🔜 Next |
| **Claude** | KardexView Livewire wiring | `work/inicio-limpio-abril-2026` | 🔜 Next |
| **Claude** | Production UI review (4 components) | `work/inicio-limpio-abril-2026` | ✅ Done |
| **Gemini** | Fix `fn_postcorte_after_insert` | — | ⚠️ Migration ready (`2026_05_16_000000_fix_postcorte_trigger_sales.php`) + backfill SQL — pending apply on staging/prod (tables absent locally) |

---

## Prioritized Backlog

### 🔴 High — Technical debt / broken in prod

| # | Task | Module | Assign to |
|---|------|--------|-----------|
| 1 | Fix `fn_postcorte_after_insert` trigger (totals NULL) | Caja | Gemini |
| 2 | `DateRange` Value Object | DDD | Claude |
| 3 | Wire `PosTicketIngested` event in `PosConsumptionService` | Events | Claude |
| 4 | `KardexView` Livewire — wire to new `KardexService` | Inventory UI | Claude |

### 🟡 Medium — Features with backend ready

| # | Task | Module | Assign to |
|---|------|--------|-----------|
| 5 | Review + connect Production Livewire components to read API | Production UI | Claude |
| 6 | State Machines formal (Reception, Transfer) | DDD | Claude (after Codex done) |
| 7 | Formal exceptions in Pos/ and Recetas/ (DDD Brecha ② remainder) | DDD | Claude |
| 8 | Kardex UI prompt for Codex if KardexView is incomplete | Inventory | Codex |

### 🟢 Low — New features

| # | Task | Module | Assign to |
|---|------|--------|-----------|
| 9 | Inventory Valuation endpoint (`GET /api/inventory/valuation`) | Inventory | Codex 🔜 |
| 10 | Batch expiry alerts (items with `fecha_caducidad` < 7 days) | Inventory | Codex 🔜 |
| 11 | KDS (Kitchen Display) — `Livewire/Kds/Board.php` review | KDS | Claude |
| 12 | `auth:sanctum` on `/api/caja/*` routes (currently unprotected) | Auth | Claude |

---

## Agent Update Protocol

When completing a task, update this file:

1. Change the module table row: `⚠️` → `✅` or add new row
2. Update **Current Agent Assignments** table: `🔄 In progress` → `✅ Done`
3. Move the backlog item to "Done" or remove it
4. Update "Last updated" date at the top

**Format conventions:**
- `✅` = Complete and tested
- `⚠️` = Exists but needs review/wiring
- `❌` = Missing or broken
- `🔄` = In progress
- `🔜` = Queued (next up)

---

## Key Invariants (never break)

```
DB_SCHEMA in phpunit.xml = "selemti"  (never add "public" — destroys 108 FloreantPOS tables)
All selemti models:  protected $connection = 'pgsql'
All selemti models:  protected $table = 'selemti.<table>'   (or relying on search_path for receta_cab)
public.* schema:     READ ONLY — never INSERT/UPDATE/DELETE/ALTER
```
