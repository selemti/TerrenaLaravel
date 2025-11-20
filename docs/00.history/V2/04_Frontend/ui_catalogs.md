# UI · Catálogos

Componentes Livewire bajo `app/Livewire/Catalogs/` con vistas en `resources/views/livewire/catalogs/`.

## 1. Resumen de Catálogos

| Componente | Tabla principal | Funcionalidad | Estado |
|------------|-----------------|---------------|--------|
| `UnidadesIndex` | `selemti.unidades_medida` | CRUD directo sobre unidades del POS (código, nombre, tipo, categoría, decimales). | ✅ Funcional, requiere permisos sobre esquema `selemti`. |
| `UomConversionIndex` | `cat_uom_conversion` | Mantenimiento de factores de conversión entre unidades (`origen_id`, `destino_id`, `factor`). | ✅ Listo. Validación de unicidad origen+destino. |
| `SucursalesIndex` | `cat_sucursales` | Sucursales con `clave`, `nombre`, `ubicacion`, `activo`. | ✅ |
| `AlmacenesIndex` | `cat_almacenes` | Almacenes asociados a sucursales. | ✅ (selección de sucursal). |
| `ProveedoresIndex` | `cat_proveedores` | RFC, nombre, contacto, activo. | ✅ |
| `StockPolicyIndex` | `inv_stock_policy` | Min/máx por ítem y sucursal. | ⚠ Depende de `items` y `cat_sucursales` existentes. |

## 2. Dependencias

- Layout `resources/views/layouts/terrena.blade.php`.
- Estilos en `public/assets/terrena.js` y `public/assets/css/*`.
- Validaciones en cada componente (uso de `Rule::unique`, `Schema::hasTable`).

## 3. Pendientes UX / Datos

- Cargar catálogos iniciales (seeders/manual).
- Unificar mensajes flash (éxito/error) y componentes de confirmación.
- Revisar tablas relacionadas (`cat_unidades` vs `selemti.unidades_medida`) para evitar confusión.
- Documentar pasos para habilitar `cat_uom_conversion` cuando `cat_unidades` está vacío.

## 4. Recursos Externos

- Mockups o lineamientos: revisar `D:\Tavo\2025\UX\Inventarios\Relacion de Modulos.xlsx` y `Pantallas.xlsx` (migrar a `docs/V2/assets/ux/`).

Actualiza este documento tras cambios en componentes Livewire de catálogos.
