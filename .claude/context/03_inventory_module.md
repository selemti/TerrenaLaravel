# Módulo Inventario · Referencia

**Modelo de datos (v3)**
- `items` (`App\Models\Inv\Item`): `id` varchar(20) con regex `[A-Z0-9-]{1,20}`, `categoria_id` con prefijo `CAT-`, `unidad_medida` restringida (KG/LT/PZ/BULTO/CAJA), flags `perishable/activo`, factores `factor_conversion`, `factor_compra`, campos `unidad_medida_id`, `unidad_compra_id`, `unidad_salida_id`, enum `tipo`. Definido en `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` con checks de temperaturas y costo ≥ 0.
- `inventory_batch` (`App\Models\Inv\Batch`): `cantidad_original` > 0, `cantidad_actual` ≥ 0 y ≤ original, `estado` (ACTIVO/BLOQUEADO/RECALL), `fecha_caducidad` ≥ today, `ubicacion_id` con prefijo `UBIC-`. Timestamps `created_at/updated_at` se usan para caducidad.
- `mov_inv` (`App\Models\Inv\MovimientoInventario`): registra `ts`, `cantidad` normalizada, `qty_original`/`uom_original_id`, `costo_unit`, `tipo` (ENTRADA/SALIDA/AJUSTE/MERMA/TRASPASO), `ref_tipo` y `ref_id`, `sucursal_id`, `usuario_id`. Sin timestamps automáticos aparte de `created_at` manual.
- Unidades: `unidades_medida` (`App\Models\Inv\Unidad`) define `factor_conversion_base`, `decimales`; `conversiones_unidad` (`App\Models\Inv\ConversionUnidad`) asegura `factor_conversion > 0` y pareja única (`unidad_origen_id`, `unidad_destino_id`).
- Catálogos auxiliares en `public` (`cat_unidades`, `cat_uom_conversion`, `inv_stock_policy`) están documentados en `docs/V2/02_Database/schema_public.md`; sincronizarlos con `selemti`.

**Flujos principales**
- Recepciones: `App\Services\Inventory\ReceptionService` persiste `recepcion_cab/det`, lotes y movimientos en una transacción `DB::connection('pgsql')`. Triggers descritos en `BD/patches/selemti/50_triggers.sql` recalculan costos y stock.
- Kardex/stock: `Api\Inventory\StockController` consulta vistas `vw_stock_actual`, `vw_stock_valorizado`, `vw_stock_brechas` generadas en los parches v3. Si faltan, endpoints `GET /api/inventory/kpis`, `/stock`, `/stock/list` devolverán errores.
- Movimientos manuales: `POST /api/inventory/movements` valida `tipo`, normaliza cantidad según la unidad seleccionada (`ConversionUnidad`) y escribe en `mov_inv`.
- Consultas por ítem: `GET /api/inventory/items/{id}/kardex` y `/batches` cruzan `mov_inv`, `inventory_batch`, `items`. Respetar filtros `from`, `to`, `lote_id`.

**Recetas y costeo (Terrena POS Funcional V1.2)**
- Modelos `App\Models\Rec` consumen tablas `receta_cab`, `receta_version`, `receta_det`, `receta_shadow`, `modificadores_pos` descritas en `docs/v3/Terrena Pos Funcional V1 2.pdf` y en el ERD `docs/DOC_ERD_INVENTARIO_RECETAS-20251017-081732.md`.
- `Receta` conserva metadata del plato y los métodos `publishedVersion()`/`latestVersion()` para transitar de borrador a publicado.
- `RecetaVersion` controla `version`, `version_publicada`, `fecha_efectiva`, `usuario_publicador`; su BOM `RecetaDetalle` ordenado (`item_id`, `cantidad`, `unidad_medida`, `merma_porcentaje`) debe apuntar a `App\Models\Inv\Item`.
- Integración POS: `RecetaShadow` enlaza modificadores y combos; `scripts/sync_menu_recipes.php` genera versiones iniciales y escribe `menu_item.recepie` con la publicación activa.
- Costeo: `historial_costos_receta`, `ticket_det_consumo` y `ticket_venta_det` soportan conciliación ventas vs consumo. El plan V1.2 exige recalcular costos tras cambios de precio/merma y publicar el snapshot.
- Ordenes de producción: `App\Models\Rec\OrdenProduccion` vincula versiones con producción; registrar `mov_inv` `TRASPASO`/`SALIDA` según escenario (central vs sucursal).

**Riesgos y tareas**
- Sincronizar catálogos `public` ↔︎ `selemti` para evitar unidades divergentes; ver tareas abiertas en `docs/V2/02_Database/schema_public.md`.
- Bloquear egresos cuando `cantidad_actual` quedaría negativa; actualmente depende de validación manual.
- Añadir autenticación (`auth:sanctum`/JWT) y políticas antes de exponer CRUD de items/movimientos.
- Documentar cualquier cambio estructural en `.claude/agents/inventory_manager.md` y actualizar los diccionarios en `docs/V2/02_Database/`.
