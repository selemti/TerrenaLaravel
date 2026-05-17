# Alineacion BD selemti - 2026-05-16

## Objetivo

Hacer reproducibles por migraciones las tablas y vistas legacy que el front/API ya consumen, sin escribir ni alterar `public.*`.

## Backup previo

- Archivo: `database/backups/codex/pos_before_bd_alignment_20260516_214441.dump`
- Formato: `pg_dump` custom format
- Alcance: base completa antes de aplicar la alineacion
- Uso previsto de reversa: restaurar solo el schema `selemti` con `pg_restore -n selemti --clean --if-exists`

## Cambios versionados

- `database/migrations/2026_05_16_214500_align_selemti_legacy_reporting_views.php`
  - Crea `selemti.item_vendor` si falta.
  - Crea `selemti.stock_policy` si falta.
  - Inicializa `stock_policy` desde `inv_stock_policy` cuando aplique.
  - Crea/actualiza vistas de dashboard, sesion DPR, stock FEFO, stock valorizado, brechas y movimientos anomalos.
- `database/migrations/2026_05_16_214600_add_updated_at_to_stock_policy.php`
  - Agrega `selemti.stock_policy.updated_at` si falta.
- `database/migrations/2026_05_16_214700_make_stock_policy_max_qty_nullable.php`
  - Permite `NULL` en `selemti.stock_policy.max_qty`.
- `app/Http/Controllers/Api/Inventory/StockController.php`
  - Tolera nombres reales de columnas en batches: `fecha_caducidad`/`caducidad` y `ubicacion_id`/`almacen_id`.

## Hallazgo sobre migraciones anteriores

Las migraciones anteriores no cubrian completamente los objetos requeridos:

- `item_vendor`: habia migraciones que la alteraban o la consultaban, pero no una creacion base.
- `item_vendor_prices`: ya estaba cubierta por migracion previa.
- `inv_stock_policy`: ya estaba cubierta por migracion previa.
- `stock_policy`: no estaba cubierta; algunos modelos legacy la esperan.
- `vw_dashboard_*`, `vw_sesion_dpr`, `vw_stock_por_lote_fefo`, `vw_stock_brechas`, `vw_movimientos_anomalos`: estaban en dumps, no en migraciones.
- `vw_stock_valorizado`: no estaba en dumps ni migraciones; el codigo actual la consume.

## Plan de aplicacion

1. Restaurar solo `selemti` desde el backup previo.
2. Ejecutar `php artisan migrate`.
3. Validar existencia de tablas/vistas requeridas.
4. Validar conteos basicos de datos operativos.
5. Validar endpoints/paginas afectadas.
6. Ejecutar `php artisan test`.

## Reversa

Si la alineacion causa una regresion:

1. Restaurar solo `selemti` desde `database/backups/codex/pos_before_bd_alignment_20260516_214441.dump`.
2. No tocar `public.*`.
3. Si se necesita revertir codigo, revertir unicamente:
   - Las tres migraciones nuevas `2026_05_16_2145xx`.
   - El ajuste de `StockController.php`.
4. Volver a validar login, dashboard, inventario, reportes y pruebas.

## Validaciones esperadas

- `php artisan migrate` sin errores.
- `php artisan test` sin regresiones.
- HTTP 200 esperado en:
  - `/dashboard`
  - `/inventory/items`
  - `/caja/cortes/historico`
  - `/reports`
  - `/reports/sales`
  - `/api/inventory/kpis`
  - `/api/inventory/stock/list`
  - `/api/inventory/alerts`
  - `/api/reports/stock/val`

## Resultado aplicado

- Backup restaurado sobre `selemti` y migraciones reaplicadas.
- `pg_restore --clean -n selemti` reporto advertencias por funciones `selemti.*` usadas por triggers/vistas en `public.*`; se dejaron intactas para no tocar FloreantPOS.
- Se retiraron temporalmente las vistas de alineacion antes de la segunda restauracion para evitar dependencias sobre tablas base de `selemti`; despues se ejecutaron migraciones otra vez.
- Objetos validados:
  - Tablas: `item_vendor`, `stock_policy`, `alertas_cortes`.
  - Vistas: `vw_dashboard_*`, `vw_sesion_dpr`, `vw_stock_por_lote_fefo`, `vw_stock_valorizado`, `vw_stock_brechas`, `vw_movimientos_anomalos`, `vw_item_last_price_pref`.
- Conteos post-restore:
  - `users`: 22
  - `roles`: 8
  - `permissions`: 49
  - `items`: 0
  - `mov_inv`: 0
  - `cat_proveedores`: 0
- El backup contiene `items`, `mov_inv` y `cat_proveedores` sin filas; esos ceros no fueron causados por la restauracion.
- Login validado:
  - `soporte@selemti.com` / `Terrena2026!` autentica correctamente.
- HTTP con sesion web validado en `http://localhost/TerrenaLaravel`:
  - `/dashboard`: 200
  - `/inventory/items`: 200
  - `/caja/cortes/historico`: 200
  - `/reports`: 200
  - `/reports/sales`: 200
- API validada con token temporal Sanctum, eliminado al terminar:
  - `/api/inventory/kpis`: 200
  - `/api/inventory/stock/list`: 200
  - `/api/inventory/alerts`: 200
  - `/api/reports/stock/val`: 200
- Pruebas:
  - `php artisan test`: 347 passed, 1394 assertions.
  - Advertencias remanentes: metadata PHPUnit en doc-comments de tests existentes.
