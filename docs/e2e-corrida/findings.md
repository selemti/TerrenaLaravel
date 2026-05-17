# E2E Corrida — Hallazgos

Documento vivo. Se actualiza conforme se detectan fallas durante la corrida.

---

## BUG-001 — `TransferService::approveTransfer` filtra `mov_inv` por `sucursal_id = almacen_id`

**Archivo:** `app/Services/Inventory/TransferService.php` ~línea 103  
**Severidad:** Alta (bloquea flujo de aprobación de traspasos)

**Descripción:**
```php
$stocks = DB::connection('pgsql')
    ->table('selemti.mov_inv')
    ->where('sucursal_id', (string) $transfer->from_bodega_id)  // ← from_bodega_id es almacen_id, no sucursal_id
    ->whereIn('item_id', $itemIds)
    ->groupBy('item_id')
    ->pluck('cantidad_actual', 'item_id');
```
`from_bodega_id` es el ID del almacén (`selemti.cat_almacenes`), pero el filtro lo aplica sobre `mov_inv.sucursal_id` (que almacena el ID de `selemti.cat_sucursales`). El resultado es siempre 0, lo que provoca `InsufficientStockException` para cualquier traspaso con stock real.

**Workaround aplicado en TransactionalFlowSeeder:**
Después de `createTransfer()`, se actualiza el estado directamente a `RECIBIDA` via SQL y se llama `postTransferToInventory()` (que acepta estado `APROBADA|RECIBIDA`).

**Fix recomendado:**
```php
// Opción A — filtrar por almacen_id (columna correcta en mov_inv):
->where('almacen_id', (string) $transfer->from_bodega_id)

// Opción B — agregar columna almacen_id separada y filtrar por ambas
```
La opción A es correcta si `mov_inv.almacen_id` se llena consistentemente en todos los servicios.

---

## FINDING-001 — `ProductionService` escribe en tablas sin prefijo de schema

**Archivo:** `app/Services/Inventory/ProductionService.php` líneas 53, 73, 105  
**Severidad:** Media (funciona sólo si `search_path` de PostgreSQL incluye `selemti`)

```php
DB::table('production_orders')->insertGetId(...)         // sin 'selemti.'
DB::table('production_order_inputs')->insert(...)        // sin 'selemti.'
DB::table('production_order_outputs')->insert(...)       // sin 'selemti.'
```

A diferencia de otros servicios que usan `DB::table('selemti.xxx')`, ProductionService omite el prefijo. Funciona si el usuario de PostgreSQL tiene `search_path = selemti` configurado por defecto. Si no, falla con `relation "production_orders" does not exist`.

**Verificar:** `SHOW search_path;` en la sesión de la conexión `pgsql`. Si retorna `"$user", public`, agregar `options=-c search_path=selemti` en `config/database.php` o agregar el prefijo explícito.

---

*Última actualización: 2026-05-16*
