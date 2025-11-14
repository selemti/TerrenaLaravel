# Diagnóstico Inventario · Definición de Ítems

**Fecha:** 2025-11-11  
**Contexto:** Revisión completa de BD, modelos, controladores y vistas para comparar el wireflow documentado en `docs/Inventario/` contra la implementación real (Laravel + PostgreSQL 9.5 en `172.24.240.1:5433`, esquema `selemti`).

---

## 1. Base de Datos

- `selemti.items` ya incluye los campos descritos en `ESTRUCTURA_ITEMS_PRESENTACIONES.md` (unidades base/compra/salida, `categoria_id`, `item_code`, flags `es_producible`, `es_consumible_operativo`, `es_empaque_to_go`). Sin embargo:
  - No existe columna para `sku` ni `merma_pct`, aunque la UI de alta rápida solicita ambos.
  - `item_vendor`, `item_vendor_prices` y `historial_costos_item` están vacías; por tanto, la checklist “Completar” nunca puede marcar ítems como terminados ni alimentar `vw_item_last_price_pref`.
  - La FK `item_vendor.unidad_presentacion_id` sigue apuntando a `selemti.unidades_medida_legacy`, mientras el flujo actual usa `selemti.cat_unidades`.
  - `vw_item_last_price_pref` depende de que haya un `item_vendor` preferente y al menos un registro en `vw_item_last_price`; hoy todas las columnas regresan `NULL`.

## 2. Modelos y Controladores

- Existen tres modelos distintos para la misma tabla (`App\Models\Item`, `App\Models\Inventory\Item`, `App\Models\Inv\Item`), cada uno con casts diferentes. Esto dificulta mantener los campos nuevos y provoca divergencias (ej. algunos modelos no exponen los flags `es_*`).
- `App\Http\Controllers\Inventory\InsumoController` todavía escribe en `selemti.insumo` y la vista (`resources/views/livewire/inventory/items-manage.blade.php:25`) instruye al usuario a usar ese flujo legacy, aunque `App\Livewire\Inventory\InsumoCreate` ya inserta en `selemti.items`.
- El API `ItemController` (rutas `/api/inventory/items`) valida únicamente campos básicos y nunca establece `unidad_medida` (NOT NULL) ni los flags `es_producible`, etc. Cualquier alta vía API queda incompleta.
- `VendorPriceValidation` consulta `selemti.item_vendor` y `selemti.unidades_medida` en vez de `cat_unidades`, por lo que rechaza unidades válidas capturadas en la UI.

## 3. Vistas / Wireflow

- **Paso 1 (Alta rápida):** `InsumoCreate` pide `SKU` y `Merma %`, pero el payload insertado en `selemti.items` ignora ambos (no se rellena `item_code` ni existe un campo para `merma_pct`).
- **Paso 2 (Modal ItemsManage):**
  - Solo valida que exista `unidad_compra_id` y un proveedor preferente para mostrar el badge “Pendiente completar”. La documentación exige también temperaturas para perecederos, checklist de presentaciones, etc.
  - La selección de categoría es un `input` libre; aunque se cargan `categoryOptions`, nunca se muestra un combo que actualice `items.category_id`.
  - No hay switches para `es_producible`, `es_consumible_operativo` ni `es_empaque_to_go`, impidiendo marcar empaques to-go o consumibles operativos.
  - El acordeón de proveedores graba directamente en `item_vendor`, pero no implementa el CRUD “Proveedor ↔ Insumo” requerido (validaciones `unique (insumo_id, uom_code)`, catálogos de presentaciones, etc.).
- **Modal de precios (`ItemPriceCreate`):** requiere que exista al menos un registro en `item_vendor`; al no haber datos, la pantalla queda inutilizable y no se puede llenar `item_vendor_prices`.
- Existe un componente alterno `ItemCreate` que apunta a rutas inexistentes y mezcla lógica con `InsumoCodeService`. Es un flujo duplicado que puede confundir a los usuarios.

## 4. Brechas vs. Documentación

| Expectativa (docs) | Estado actual | Impacto |
|--------------------|---------------|---------|
| SKU + merma % guardados en BD | No se persisten | Los reportes de merma y POS no pueden usar esos valores. |
| Flag `es_*` configurable por UI/API | Siempre `false` | Diagnósticos POS no detectan empaques to-go ni consumibles. |
| Checklist completa (unidades, proveedores, temperaturas, presentaciones) | Solo unidad de compra + proveedor | Los badges & métricas de items incompletos no reflejan la realidad. |
| CRUD de presentaciones por proveedor (seccionado en `item_vendor`) | Sin UI dedicada, sin datos | No se pueden capturar presentaciones, costos ni factores. |
| API y controladores usando `cat_unidades` | Continúan consultando tablas legacy | Validaciones fallan aunque se seleccione una unidad válida. |

## 5. Acciones Recomendadas

1. **Modelo único y campos faltantes:** consolidar el modelo `Item`, agregar columnas para `sku`/`merma_pct` o reutilizar `item_code` para guardar el SKU. Ajustar `InsumoCreate` y `ItemController` para persistirlos.
2. **Completar flagging:** añadir controles en el modal (y en la API) para `es_producible`, `es_consumible_operativo`, `es_empaque_to_go`; poblarlos cuando corresponda.
3. **Categorías y checklists:** reemplazar el `input` libre por un `select` que use `item_categories`, y extender `needsCompletion` para validar temperaturas, presentaciones y proveedores.
4. **Proveedor ↔ Insumo:** implementar el CRUD de presentaciones conforme a `PRESENTACIONES_POR_ITEM.md`, migrar `item_vendor.unidad_presentacion_id` a `cat_unidades` y poblar datos para que el modal de precios funcione.
5. **Actualizar mensajes/legacy:** remover referencias a `selemti.insumo` en vistas/controladores para evitar duplicidad con tablas legacy.
6. **Validaciones:** apuntar `VendorPriceValidation` y demás reglas a `cat_unidades`, y asegurar que todas las altas llenen `unidad_medida` + `item_code`.

Con estos cambios, el wireflow descrito en `docs/Inventario/FLUJO_ALTA_ITEMS_V2.md` podrá materializarse: los datos capturados en UI se reflejarán en BD, los badges indicarán verdaderas brechas y el módulo de precios tendrá la información necesaria para alimentar reportes, POS y el orquestador.
