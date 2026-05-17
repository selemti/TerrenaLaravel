# Codex Task: Phase 0 — Estandarizar tipos de movimiento + TransactionalFlowSeeder

**Assignee:** Codex
**Rama sugerida:** `work/phase0-tipo-canonico`
**Tests requeridos:** `php artisan test` sin regresiones después de cada subtarea.

---

## Contexto — Vocabulario canónico aprobado

El plan en `C:\Users\Tavo\.claude\plans\curried-humming-tulip.md` define el vocabulario canónico
de `mov_inv.tipo`. **Gemini** agrega `signo`/`afecta_costo`/`activo` a `cat_tipo_mov_inv` y lo puebla.
**Tu trabajo es migrar los literales en los servicios PHP** para que escriban las claves canónicas.

### Mapa de migración de literales

| Servicio | Literal actual | Nuevo literal canónico |
|----------|---------------|------------------------|
| `ReceptionService` | `'ENTRADA'` (tipo en mov_inv) | `'RECEPCION_COMPRA'` |
| `ProductionService` | `'PROD_OUT'` (inputs) | `'PRODUCCION_SALIDA'` |
| `ProductionService` | `'PROD_IN'` (outputs) | `'PRODUCCION_ENTRADA'` |
| `ProductionService` | `'MERMA'` | `'MERMA'` ← sin cambio |
| `TransferService` | salida | `'TRASPASO_SALIDA'` |
| `TransferService` | entrada | `'TRASPASO_ENTRADA'` |
| `InventoryCountService` | ajuste positivo | `'AJUSTE_ENTRADA'` |
| `InventoryCountService` | ajuste negativo | `'AJUSTE_SALIDA'` |
| `PosConsumptionService` | tipo de consumo POS | `'VENTA_POS'` |

**Patrón a seguir**: definir constantes de clase en cada servicio, no literales inline:
```php
private const TIPO_ENTRADA = 'RECEPCION_COMPRA';
// ... y usar self::TIPO_ENTRADA en los DB::insert / update
```

---

## Subtarea 1 — Migrar literales en los 5 servicios

Archivos a modificar:
- `app/Services/Inventory/ReceptionService.php`
- `app/Services/Inventory/ProductionService.php`
- `app/Services/Inventory/TransferService.php`
- `app/Services/Inventory/InventoryCountService.php`
- `app/Services/Inventory/PosConsumptionService.php`

Para cada uno: busca dónde escribe `mov_inv.tipo`, reemplaza el literal con la constante canónica.
Si un servicio ya tiene constantes, úsalas; si no, agrégalas.

**Verifica**: después de cambiar, corre `php artisan test`. Los tests de cada servicio deben pasar
(los unit tests usan mocks o SQLite, los feature tests con pgsql aún pueden fallar hasta que Gemini
aplique su migración — anota qué tests fallan si los hay).

---

## Subtarea 2 — Corregir `ProductionOrderReadService`

Archivo: `app/Services/Production/ProductionOrderReadService.php`

**Problema actual**: el servicio joinea `production_orders.recipe_id` (bigint) contra
`selemti.receta_cab.id` (varchar) con cast `::text` para resolver el nombre de la receta.
Esto es incorrecto — el esquema canónico es `selemti.recipes`.

**Fix**: cambiar el join/lookup para que use `selemti.recipes` en lugar de `selemti.receta_cab`.
El campo a mostrar en la UI es `recipes.nombre` (equivalente a `receta_cab.nombre_plato`).
Si hay join a `selemti.receta_version` para obtener ingredientes, cambiarlo a `selemti.recipe_versions`.

---

## Subtarea 3 — `TransactionalFlowSeeder`

Archivo nuevo: `database/seeders/E2E/TransactionalFlowSeeder.php`

Este seeder ejecuta el flujo completo de negocio **llamando servicios reales**, no inserts directos.
Depende de que `MasterDataSeeder` ya haya poblado: items, almacenes, sucursales, proveedores,
cat_tipo_mov_inv canónico (Gemini lo aplica).

### Estructura general

```php
namespace Database\Seeders\E2E;

use App\Services\Purchasing\PurchasingService;
use App\Services\Inventory\ReceptionService;
use App\Services\Inventory\ProductionService;
use App\Services\Inventory\TransferService;
use App\Services\Inventory\InventoryCountService;
use Illuminate\Database\Seeder;

class TransactionalFlowSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedApertura();       // mov_inv APERTURA — insert directo (no hay servicio de apertura)
        $this->seedComprasRecepciones(); // PR→PO→postReception → mov_inv RECEPCION_COMPRA
        $this->seedProduccion();        // createOrder → mov_inv PRODUCCION_SALIDA/ENTRADA/MERMA
        $this->seedTraspasos();         // postTransferToInventory → TRASPASO_SALIDA + TRASPASO_ENTRADA
        $this->seedConteo();            // finalize → AJUSTE_ENTRADA / AJUSTE_SALIDA
        $this->seedConsumoPos();        // confirmTicket (si hay mapeo) → VENTA_POS
    }
}
```

### Detalles por paso

**seedApertura**: insert directo en `selemti.inventory_batch` (tipo=`APERTURA`, cantidad inicial
para 5-6 items clave) + `selemti.mov_inv` con `tipo='APERTURA'`. Usar `lote_proveedor='APERTURA-'.date('Y')`.

**seedComprasRecepciones** — ~3 ciclos completos:
```php
$po = app(PurchasingService::class)->createRequest([...]);
// submitQuote → approveQuote → issuePurchaseOrder
$reception = app(ReceptionService::class)->createFromPurchaseOrder($po);
app(ReceptionService::class)->validateReception($reception->id, 1);
app(ReceptionService::class)->postReception($reception->id, 1);
// → genera mov_inv RECEPCION_COMPRA + inventory_batch
```

**seedProduccion** — ~5 órdenes de producción:
```php
app(ProductionService::class)->createOrder(
    header: ['recipe_id' => $recipeId, 'item_id' => $itemId, ...],
    inputs: [['item_id' => $insumoId, 'qty' => 2.5, 'uom' => 'KG', 'inventory_batch_id' => $batchId]],
    outputs: [['item_id' => $productoId, 'qty' => 4.0, 'uom' => 'KG']],
    wastes: [['item_id' => $insumoId, 'qty' => 0.1, 'uom' => 'KG', 'reason' => 'Merma normal']]
);
// → PRODUCCION_SALIDA (inputs) + PRODUCCION_ENTRADA (outputs) + MERMA (wastes)
```
Post-seed: `DB::table('selemti.production_orders')->limit(2)->update(['estado' => 'POSTEADO'])` — la UI
de producción necesita ver órdenes en ese estado.

**seedTraspasos** — 1 traspaso de Almacén General → Cocina:
```php
// createTransfer → approveTransfer → markInTransit → receiveTransfer → postTransferToInventory
```

**seedConteo** — 1 conteo físico completo con 5-8 líneas, algunas con varianza positiva
(→ AJUSTE_ENTRADA) y algunas negativa (→ AJUSTE_SALIDA).

**seedConsumoPos**:
```php
// Toma 3 ticket_id reales de public.ticket (READ ONLY)
$tickets = DB::connection('pgsql')->table('public.ticket')->limit(3)->pluck('id');
foreach ($tickets as $ticketId) {
    try {
        app(PosConsumptionService::class)->confirmTicket($ticketId, userId: 1);
    } catch (\Throwable $e) {
        $this->command?->warn("POS ticket {$ticketId}: " . $e->getMessage()); // no falla todo
    }
}
```
Si no hay mapeo receta↔ticket, los warn se documentan en `docs/e2e-corrida/findings.md`.

### Idempotencia
- Lotes: `lote_proveedor` con prefijo único por ciclo (`'E2E-RCP-'.now()->format('Ymd').'-01'`) o
  usar `Str::uuid()` — la unique constraint en `inventory_batch` colisiona si se repite.
- Toda la corrida en un try/catch con rollback en caso de falla crítica.
- Proteger con `if (DB::connection('pgsql')->table('selemti.mov_inv')->where('ref_tipo', 'E2E')->exists()) return;`
  al inicio de cada método para que sea re-entrant.

---

## Subtarea 4 — Registrar en `DatabaseSeeder`

Agregar al final de `database/seeders/DatabaseSeeder.php`:
```php
if ($this->command?->confirm('¿Ejecutar corrida E2E completa (transaccional)?', false)) {
    $this->call(\Database\Seeders\E2E\MasterDataSeeder::class);
    $this->call(\Database\Seeders\E2E\TransactionalFlowSeeder::class);
}
```

---

## Invariantes críticos

- `public.*` → READ ONLY — solo `DB::connection('pgsql')->table('public.ticket')->select(...)`, nunca INSERT/UPDATE
- Todas las tablas: `selemti.<tabla>` — siempre prefijo de schema
- PG 9.5 — no window functions en queries propias; los servicios existentes ya son compatibles
- No tocar `public.fn_expandir_consumo_ticket` ni ningún trigger de `public`
- Usar `DB::connection('pgsql')` para todo — no mezclar con SQLite default
- Cada servicio llamado debe poder fallar individualmente sin romper todo el seeder

## Tests esperados
- `php artisan test` — 121 unit + feature passing, sin regresiones
- Los tipos en `mov_inv` después de la corrida: al hacer `SELECT tipo, COUNT(*) FROM selemti.mov_inv GROUP BY tipo` deben aparecer únicamente claves del vocabulario canónico
