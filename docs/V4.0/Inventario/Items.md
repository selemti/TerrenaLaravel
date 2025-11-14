# Inventario · Alta de Items (V4.0)

## 1. Alcance

Fuente de verdad para el flujo de creación y mantenimiento de insumos en `selemti.items`. Esta versión sustituye cualquier documento legacy (`docs/Inventario/insumos_alta.md`, `docs/UI-UX/MASTER/02_MODULOS/Inventario.md` para este tema) y se mantiene sincronizada con:

- Componentes Livewire `Inventory\InsumoCreate` y `Inventory\ItemsManage`.
- API REST `App\Http\Controllers\Api\Inventory\ItemController`.
- Servicios `App\Services\Inventory\InsumoCodeService` y `App\Models\Inv\Item`.
- Esquema Postgres `selemti` (tablas `items`, `item_categories`, `cat_unidades`, `item_vendor`).

Todo flujo o controlador que no aparezca aquí se considera legacy y debe eliminarse (ej. `App\Http\Controllers\Inventory\InsumoController` que aún escribe en `insumo`).

## 2. Tablas y catálogos

| Tabla | Campos relevantes | Comentarios |
|-------|-------------------|-------------|
| `selemti.items` | `id` (PK string `CAT-SUB-#####`), `nombre`, `descripcion`, `categoria_id`, `category_id`, `unidad_medida_id`, `unidad_compra_id`, `unidad_salida_id`, `factor_compra`, `factor_conversion`, `perishable`, `temperatura_min/max`, `tipo`, `activo`, `costo_promedio`, `created_at`, `updated_at` | Definida por las migraciones históricas y reflejada en `App\Models\Inv\Item` |
| `selemti.item_categories` | `id`, `nombre`, `codigo`, `prefijo`, `slug`, `activo` | Trigger `fn_gen_cat_codigo` genera códigos; usado para mapear CAT/SUB |
| `selemti.cat_unidades` | `id`, `clave` (KG, L, PZ, etc.), `nombre`, `categoria`, `activo`, `created_at`, `updated_at` | Modelo `App\Models\Catalogs\Unidad` aplica upper-case y scopes |
| `selemti.item_vendor` | `item_id`, `vendor_id`, `presentacion`, `unidad_presentacion_id`, `factor_a_canonica`, `costo_ultimo`, `moneda`, `lead_time_dias`, `codigo_proveedor`, `preferente`, `activo`, `created_at` | Cargado desde el modal de Items (`ItemsManage`) |

> Nota: `selemti.insumo` ya no es parte del flujo; cualquier escritura a esa tabla debe eliminarse junto con los controladores legacy.

## 3. Flujo operativo

### Paso 1 · Alta rápida

- **Ruta:** `GET /inventory/items/new`
- **Componente:** `App\Livewire\Inventory\InsumoCreate`
- **Archivos:** `resources/views/livewire/inventory/insumo-create.blade.php`
- **Validaciones:** categoría y subcategoría obligatorias, nombre ≤ 255, única selección de UOM base (`KG`, `L`, `PZ`), merma entre 0 y 100 (`app/Livewire/Inventory/InsumoCreate.php`).
- **Acciones:**
  1. Se verifica permiso `inventory.items.manage` o rol `Super Admin`.
  2. Se genera el código interno usando `InsumoCodeService::generateCode($cat,$sub)` que inspecciona `selemti.items` para calcular el consecutivo.
  3. Se inserta el registro base en `selemti.items` con `tipo = MATERIA_PRIMA`, `activo = true`, UOM canónica y categoría formateada `CAT-0001`.
  4. Se redirige a `/inventory/items` con `session('openItemModal')` para abrir el modal automáticamente.

### Paso 2 · Completar información

- **Ruta:** `GET /inventory/items`
- **Componente:** `App\Livewire\Inventory\ItemsManage`
- **Vista:** `resources/views/livewire/inventory/items-manage.blade.php`
- **Funciones:**
  - Listado con filtros y ordenamiento (`q`, categoría, estado, proveedor preferente).
  - Modal de edición que carga datos desde `selemti.items`, proveedores (`selemti.item_vendor`) e historial de costos (`HistorialCostoItem`).
  - Guardado con validaciones: SKU alfanumérico, categoría `CAT-XXXX`, factores ≥ 0.0001, temperaturas coherentes.
  - CRUD de proveedores con obligación de un proveedor preferente (actualiza `item_vendor` y `costo_promedio`).
  - Registro de historial de costos al guardar un proveedor preferente.

### Servicios auxiliares

- **InsumoCodeService**: consulta `selemti.items` y genera códigos formateados; pendiente encapsular en transacción con bloqueo por par CAT/SUB si se requiere concurrencia.
- **API `/api/inventory/items`**: controlador `App\Http\Controllers\Api\Inventory\ItemController` expone CRUD para integraciones (GET list/show, POST create, PUT update, DELETE soft delete). Usa `App\Models\Inv\Item`.

## 4. Datos y reglas

1. **Código interno**: `CAT-SUB-#####` (CAT = categoría operativa, SUB = subcategoría, consecutivo de 5 dígitos). No se captura manualmente.
2. **UOM base**: restringida a `KG`, `L`, `PZ` (catálogo `selemti.cat_unidades`). Las unidades de compra/salida se definen en el modal. La estrategia completa de conversiones está documentada en `docs/Inventario/UOM_STRATEGY_TERRENA.md`.
3. **Categorías**: `selemti.item_categories` debe tener las combinaciones necesarias. `InsumoCreate` mapea CAT (`MP`, `PT`, `EM`, `LIM`, `SRV`) a IDs numéricos definidos en la tabla.
4. **Permisos**: todo acceso a `/inventory/items*` requiere sesión y el permiso `inventory.items.manage`. El modal de precios adicionales exige `inventory.prices.manage`.
5. **Estado**: los ítems nuevos se crean activos; para deshabilitarlos se usa `ItemsManage` (toggle) o la API (`DELETE` marca `activo = false`).

## 5. Rutas y endpoints activos

| Ruta | Propósito | Fuente |
|------|-----------|--------|
| `GET /inventory/items/new` | Formulario de alta rápida | `routes/web.php` (alias `inventory.items.new`) |
| `GET /inventory/items` | Gestión de catálogo, modal de edición | `routes/web.php` (alias `inventory.items.index`) |
| `GET /api/inventory/items` | Listado paginado con filtros `q`, `categoria_id`, `activo` | `routes/api.php` |
| `POST /api/inventory/items` | Crear ítem vía API | `routes/api.php` |
| `PUT /api/inventory/items/{id}` | Actualizar | `routes/api.php` |
| `DELETE /api/inventory/items/{id}` | Baja lógica (activo = false) | `routes/api.php` |

## 6. Riesgos y tareas abiertas

1. **Eliminar `App\Http\Controllers\Inventory\InsumoController`**: sigue insertando en una tabla legacy (`insumo`). Debe retirarse para evitar divergencia.
2. **Concurrencia del generador de códigos**: hoy no bloquea por CAT/SUB; si se harán altas simultáneas se debe envolver en transacción con `FOR UPDATE` o secuencias dedicadas.
3. **Catálogo de categorías**: `InsumoCreate` usa un `categoryMap` estático (IDs 1-5). Validar que coincida con los registros reales de `selemti.item_categories` y documentar cómo mantenerlo (idealmente leer de la tabla en lugar de hardcode).
4. **Duplicidad de fuentes**: confirmar que sólo `selemti.items` es el padrón. Cualquier referencia a `public.item` se considera legacy y no interviene en este flujo.

---

Todo cambio al flujo de alta debe actualizar este archivo **antes** de mergear código relacionado.
