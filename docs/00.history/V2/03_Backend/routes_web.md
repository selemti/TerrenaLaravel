# Rutas Web (Blade / Livewire)

Referencia: `routes/web.php` (`commit feat/crud-catalogos`, octubre 2025).

## 1. Rutas Base

- `GET /` → Landing básica con enlace al dashboard (`home`).
- `GET /dashboard` → `resources/views/dashboard.blade.php`.
- `GET /compras`, `/inventario`, `/personal`, `/produccion`, `/recetas` → Vistas Blade estáticas.
- `GET /kds` → Livewire `App\Livewire\Kds\Board`.
- `GET /caja/cortes` → `App\Http\Controllers\Api\Caja\CajaController@index` (vista legacy renderizada desde controlador API).

## 2. Catálogos (`/catalogos/*`)

| Ruta | Componente Livewire | Descripción |
|------|---------------------|-------------|
| `/catalogos/unidades` | `Catalogs\UnidadesIndex` | CRUD de `selemti.unidades_medida`. |
| `/catalogos/uom` | `Catalogs\UomConversionIndex` | Conversión entre unidades (`cat_uom_conversion`). |
| `/catalogos/almacenes` | `Catalogs\AlmacenesIndex` | Catálogo de almacenes (`cat_almacenes`). |
| `/catalogos/proveedores` | `Catalogs\ProveedoresIndex` | Proveedores (`cat_proveedores`). |
| `/catalogos/sucursales` | `Catalogs\SucursalesIndex` | Sucursales (`cat_sucursales`). |
| `/catalogos/stock-policy` | `Catalogs\StockPolicyIndex` | Políticas de stock (`inv_stock_policy`). |

## 3. Inventario (`/inventory/*`)

| Ruta | Componente | Notas |
|------|------------|-------|
| `/inventory/items` | `Inventory\ItemsIndex` | Requiere vistas `v_stock_resumen`, `v_kardex_item`. |
| `/inventory/receptions` | `Inventory\ReceptionsIndex` | Listado (estructura en progreso). |
| `/inventory/receptions/new` | `Inventory\ReceptionCreate` | Formulario demo con `ReceptionService`. |
| `/inventory/lots` | `Inventory\LotsIndex` | Seguimiento de lotes (pendiente datos reales). |

## 4. Recetas (`/recipes`…)

- `GET /recipes` → `Livewire\Recipes\RecipesIndex` (usa datos demo si falta tabla `recipes`).
- `GET /recipes/editor/{id?}` → `Livewire\Recipes\RecipeEditor` (esqueleto).

## 5. Autenticación

- Rutas Breeze (`/login`, `/register`, `/forgot-password`, etc.) incluidas por `require __DIR__.'/auth.php'`.
- Rutas autenticadas: `/profile` (edit/update/destroy) bajo middleware `auth`.

## 6. Endpoint Diagnóstico

- `GET /__probe` → JSON con información de la request/config (usado para validar deployment).

## Pendientes

- Documentar vistas Blade personalizadas (`resources/views/*`).
- Añadir notas sobre middleware específicos (auth/role) cuando se activen.
- Incluir rutas de módulos nuevos (reportes UI, wizard corte) conforme se implementen.

Actualiza este archivo al modificar `routes/web.php`.
