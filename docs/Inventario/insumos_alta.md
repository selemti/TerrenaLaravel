# Alta de insumos (`selemti.insumo`)

## ¿Qué es un insumo?
- `selemti.insumo` es el padrón maestro usado por compras, inventario y producción.
- `public.item` pertenece al POS legacy; **no** se modifica desde este flujo de alta.
- Toda orden de compra, requisición, receta o producción debe referenciar registros de `selemti.insumo`.

## Código interno CAT-SUB-#####
- Formato: `CAT-SUB-00001`.
- **CAT** (2-3 letras) identifica la categoría operativa:
  - `MP` = Materia prima (ingredientes de cocina, crudos o procesados).
  - `PT` = Producto terminado que se compra y se vende tal cual (ej. bebida embotellada).
  - `EM` = Empaque / consumible de empaque (vasos, tapas, charolas).
  - `LIM` = Limpieza / químicos operativos.
  - `SRV` = Servicio / costo operativo sin stock físico (maquila, renta de horno, etc.).
- **SUB** (3 letras) detalla una subcategoría específica (ejemplos: `LAC` lácteos, `BOT` bebida embotellada, `DET` detergente, `CAR` cárnicos, `FRU` frutas/verduras).
- **#####** es un consecutivo de 5 dígitos reseteado por cada par (CAT, SUB).
- El usuario **no** captura el código; el sistema lo genera automáticamente usando `InsumoCodeService`.

## Política operativa
- PT + subcategoría BOT modela “producto comprado que vendo igual” (agua embotellada, cacahuates, refrescos en lata).
- Los consumibles de empaque (`EM-*`) se controlan en inventario pero no van al costo alimenticio directo.
- Activos fijos, herramientas o equipo mayor no se registran como insumo; se manejarán en un módulo independiente.
- El endpoint de carga masiva (`/api/inventory/insumos/bulk-import`) utilizará el mismo generador para cada fila (implementación pendiente).

## Permisos y acceso
- Sólo usuarios con `inventory.items.manage` o `can_manage_purchasing` pueden crear insumos.
- El usuario `soporte` con rol `Super Admin` **siempre** puede crear insumos aunque no tenga explícitamente el permiso `inventory.items.manage`, para evitar lockout operativo.
- El menú y la pantalla utilizan el layout `layouts.terrena` y verifican los permisos antes de mostrar el formulario.

## Flujo de alta individual
1. Seleccionar Categoría (CAT) y Subcategoría (SUB) en la UI de alta.
2. Completar datos obligatorios: nombre, unidad base, banderas (perecible, merma, SKU opcional).
3. El sistema valida la unidad base (solo `KG`, `L`, `PZA`) y completa los datos obligatorios.
4. Al guardar se invoca el servicio `InsumoCodeService`, se genera el consecutivo y se persiste en `selemti.insumo`.
5. El backend devuelve `{ ok: true, id, codigo }` y la interfaz limpia el formulario.

## Notas de UI
- La “Unidad base (KG/L/PZA)” del formulario se carga desde `selemti.cat_unidades` y solo permite seleccionar esas tres claves.

## Consideraciones adicionales
- `um_id` referencia el catálogo de unidades existente y se selecciona a través del dropdown filtrado de `selemti.cat_unidades`.
- `perecible` y `merma_pct` ayudan al costeo y a la política FEFO/PEPS en inventario.
