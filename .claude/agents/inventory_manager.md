# Manual · Responsable de Inventario

**Modelos base (`App\Models\Inv`)**
- `Item` → `selemti.items`: `id` varchar(20) (regex `[A-Z0-9-]{1,20}`), `categoria_id` tipo `CAT-*`, flags `perishable/activo`, temperaturas opcionales y factores `factor_conversion`, `factor_compra`, `unidad_*_id`. `tipo` usa enum `producto_tipo`. Refiere las definiciones v3 en `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` y el resumen en `docs/V2/02_Database/schema_selemti.md`.
- `Batch` → `selemti.inventory_batch`: controla `cantidad_original` ≥ 0 y `cantidad_actual` ≤ original, `estado` (`ACTIVO|BLOQUEADO|RECALL`), `fecha_caducidad` ≥ hoy y prefijo `UBIC-` en `ubicacion_id`. Dispara triggers documentados en `BD/patches/selemti/50_triggers.sql`.
- `MovimientoInventario` → `selemti.mov_inv`: kardex con `tipo` restringido (`ENTRADA|SALIDA|AJUSTE|MERMA|TRASPASO`), soporta `qty_original` + `uom_original_id` para registrar la unidad declarada y `ref_tipo/ref_id` para enlazar documentos.

**Unidades y conversiones**
- `Unidad` consume `selemti.unidades_medida` (`factor_conversion_base`, `decimales`). Mantén sincronía con los catálogos Laravel (`public.cat_unidades`) descritos en `docs/V2/02_Database/schema_public.md`.
- `ConversionUnidad` usa `conversiones_unidad` (único `unidad_origen_id` + `unidad_destino_id`, `factor_conversion > 0`). Ajusta UI cuando falte la pareja.

**Políticas y parámetros**
- `PoliticaStock` (`public.inv_stock_policy`): mínimo/máximo/reorder por `item_id` + `sucursal_id`. Coordina con `selemti.stock_policy` según estrategia de despliegue.

**Flujos y endpoints**
- Recepciones: `App\Services\Inventory\ReceptionService` crea `recepcion_cab/det`, lotes y `mov_inv` en una transacción PostgreSQL. Referencia reglas operativas en `docs/V2/03_Backend/INVENTORY_MODULE.md` y valida funciones v3 (`fn_generar_lote`, `fn_mov_inv_bi`).
- API `routes/api.php`:
  - KPIs `/api/inventory/kpis`, stock consolidado `/stock`, listado detallado `/stock/list` (dependen de vistas `vw_stock_actual`, `vw_stock_valorizado` definidas en parches v3).
  - `POST /api/inventory/movements` normaliza cantidades según la unidad seleccionada antes de persistir en `mov_inv`.
  - `GET /api/inventory/items/{id}/kardex` y `/batches` consultan movimientos y lotes vigentes.

**Recetas y costeo (`App\Models\Rec`)**
- `Receta` (`receta_cab`) centraliza metadata del plato y flags `activo`.
- Versionado: `RecetaVersion` (`selemti.receta_version`) + `RecetaDetalle` (`selemti.receta_det`) siguen Terrena POS Funcional V1.2 (`docs/v3/Terrena Pos Funcional V1 2.pdf`): `version_publicada`, BOM ordenado (`item_id`, `cantidad`, `unidad_medida`, `merma_porcentaje`). Relaciones `versiones`, `publishedVersion`, `detalles` permiten recuperar el estado vigente.
- Complementos POS: `RecetaShadow` y `Modificador` vinculan `menu_item` y `menu_modifiers`; `scripts/sync_menu_recipes.php` crea datos iniciales.
- Costos y consumo: `hist_costos_receta`, `ticket_det_consumo`, `ticket_venta_det` (ver ERD) soportan conciliación; planifica comando `recipes:cost-sync` tras cambios de precios.

**Buenas prácticas Recetas**
- Cada `RecetaDetalle` debe apuntar a `Item` activo y unidad convertible.
- Antes de publicar, recalcula costo con mermas del PDF funcional y guarda snapshot en `historial_costos_receta`.
- Escribe `menu_item.recepie` con la versión publicada y agenda `recipes:sync-pos` cuando haya nuevos PLU/modificadores.

**Buenas prácticas**
- Antes de descontar, comprueba `cantidad_actual` del lote; bloquear si quedará negativa y registrar incidente.
- Ejecuta `php artisan catalogs:verify-tables --details` tras cualquier migración y compara contra parches v3.
- Documenta ajustes de conversiones, vistas o triggers en `.claude/context/03_inventory_module.md` para mantener alineación entre código y la base de datos vigente.
