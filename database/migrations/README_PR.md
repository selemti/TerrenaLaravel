# TerrenaLaravel – Pack de migraciones (categorías, códigos, histórico de costos y alertas)

**Incluye**
- Categorías con ID autoincrement y código `CAT-0001` (+ prefijo `INS`, `BEB`, etc.).
- Items con `item_code` por categoría (`PREF-00001`).
- Enriquecer `cat_proveedores` e `item_vendor` (SKU proveedor, pack, etc.).
- Histórico de precios por proveedor `item_vendor_prices` con vigencias.
- Funciones de costo de insumo/receta a fecha, snapshots y alertas por variación.

## Pasos
1. Copia estos archivos a `database/migrations/` en tu repo.
2. Corre `php artisan migrate`.
3. Asigna prefijos a categorías (una sola vez):
   ```sql
   UPDATE selemti.item_categories SET prefijo='INS' WHERE nombre ILIKE '%insumo%';
   UPDATE selemti.item_categories SET prefijo='BEB' WHERE nombre ILIKE '%bebida%';
   ```
4. Verifica `selemti.cat_uom_conversion` (KG↔G, LT↔ML, PZA↔PZA).

## Pruebas útiles
```sql
INSERT INTO selemti.item_vendor_prices(item_id,vendor_id,price,pack_qty,pack_uom,source,effective_from)
VALUES (1,1,200.00,1,'KG','RECEPCION', now());

SELECT selemti.fn_item_unit_cost_at(1, now(), 'G');
SELECT * FROM selemti.fn_recipe_cost_at(1, now());
SELECT selemti.sp_snapshot_recipe_cost(1, now());
```

## Alertas
```sql
INSERT INTO selemti.alert_rules(recipe_id, threshold_pct, active, notes)
VALUES (1, 7.5, true, 'Alerta sensible para receta 1');
```
Al subir un nuevo precio de insumo, se recalcula la(s) receta(s) impactada(s), se guarda snapshot y, si el cambio supera el umbral, se inserta en `selemti.alert_events`.
