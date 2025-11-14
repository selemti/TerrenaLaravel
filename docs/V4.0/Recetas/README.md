# Recetas & Costeo (V4.0)

## 1. Alcance y fuentes

Fuente vigente para todo lo relacionado con recetas, sub-recetas, costeo y sincronización con POS. Se basa únicamente en:

- Livewire: `App\Livewire\Recipes\{RecipesIndex,RecipeEditor,UnidadesIndex,ConversionesIndex}` y vistas `resources/views/livewire/recipes/*.blade.php`.
- Modelos `App\Models\Rec\*` (`Receta`, `RecetaVersion`, `RecetaDetalle`, `RecetaShadow`, `RecipeCostSnapshot`) y catálogos `App\Models\Inv\{Unidad,ConversionUnidad}`.
- Servicios `App\Services\Costing\RecipeCostingService`, `App\Services\Recetas\RecalcularCostosRecetasService`, `App\Services\Pos\PosConsumptionService` + repositorios POS.
- APIs: `App\Http\Controllers\Api\Inventory\RecipeCostController` (rutas `/api/recipes/*`) y jobs/commands (`recipes:sync-pos`, `recetas:recalcular-costos`).
- Base de datos `selemti` (tablas `receta_*`, `recipe_cost_*`, `recipe_labor_steps`, `recipe_overhead_allocations`, `modificadores_pos`, `unidades_medida`, `conversiones_unidad`, funciones `fn_recipe_cost_at`, `sp_snapshot_recipe_cost`).

Revisa siempre la BD real (WSL → `172.24.240.1`) y los documentos legacy en `docs/Recetas/*` solo como referencia histórica.

## 2. Tablas y funciones clave

| Recurso | Descripción |
|---------|-------------|
| `selemti.receta_cab` (`App\Models\Rec\Receta`) | Cabecera de cada receta/sub-receta. IDs `REC-#####`, `SUB-#####`, `REC-MOD-#####`. Campos de PLU, categoría, porciones, costo estándar, precio sugerido. |
| `selemti.receta_version` (`RecetaVersion`) | Versiones con `version_publicada`, `fecha_efectiva`, `descripcion_cambios`. El editor actual solo usa versión 1. |
| `selemti.receta_det` (`RecetaDetalle`) | Ingredientes por versión (item o IDs de otras recetas), incluye `cantidad`, `unidad_medida`, `merma`, `orden`. |
| `selemti.receta_shadow` (`RecetaShadow`) | Placeholder generado desde POS para productos aún no validados (campos de confianza, ventas, ingredientes inferidos). |
| `selemti.recipe_cost_history` / `recipe_extended_cost_history` (`RecipeCostSnapshot`) | Snapshots de costo estándar por receta. El servicio escribe aquí al crear snapshots; `extended` almacena breakdown JSON cuando la tabla existe. |
| `selemti.recipe_labor_steps`, `labor_roles` | Definen pasos y tarifas de mano de obra para `RecipeCostingService::resolveLaborCost`. |
| `selemti.recipe_overhead_allocations`, `overhead_definitions` | Configuración de gastos indirectos aplicados en `resolveOverheadCost`. |
| `selemti.unidades_medida` (`Unidad`) y `conversiones_unidad` (`ConversionUnidad`) | Catálogos de UOM y factores usados en Recetas/Inventario. |
| `selemti.modificadores_pos` | Vincula modificadores POS con `receta_modificador_id`. |
| Funciones/procs | `selemti.fn_recipe_cost_at(recipe_id, timestamp)` (costo teórico), `selemti.sp_snapshot_recipe_cost` (persistencia), vistas `vw_recipe_cost_history` (reportes). |

## 3. Flujos operativos

### 3.1 Catálogo de recetas
- **Listing**: `GET /recipes` → `App\Livewire\Recipes\RecipesIndex` + `resources/views/livewire/recipes/recipes-index.blade.php`. Permite buscar por nombre/PLU, filtrar por categoría (`categoria_plato`) y eliminar recetas (`Receta::whereKey()->delete()`).
- **Editor**: `GET /recipes/editor/{id?}` → `RecipeEditor`. Genera IDs secuenciales (`REC` o `SUB`) usando `receta_cab`; carga/crea versión (`RecetaVersion::create`) y reescribe `receta_det` en cada guardado. No existe UI para publicar/despublicar ni para múltiples versiones; siempre opera sobre `version=1`.
- **Recipe hub**: `Route::view('/recetas', 'recetas')` es un landing que enlaza al editor y a catálogos de unidades/conversiones; el resto del flujo se hace en las rutas anteriores.

### 3.2 Catálogo de unidades y conversiones
- `GET /catalogos/unidades` → `App\Livewire\Recipes\UnidadesIndex` gestiona `unidades_medida` (código, tipo, factor base). Las reglas permiten tipos `PESO/VOLUMEN/UNIDAD/TIEMPO`.
- `GET /catalogos/uom` → `App\Livewire\Recipes\ConversionesIndex` mantiene `conversiones_unidad`. El Livewire actual usa campos `from_id/to_id/factor`, mientras que la vista Blade heredada (`resources/views/livewire/recipes/conversiones-index.blade.php`) todavía espera propiedades antiguas (`u_origen/u_destino`), por lo que la UI necesita alinearse.

### 3.3 Costeo, snapshots y APIs
- **Calcular costo**: `App\Services\Costing\RecipeCostingService::calculate($recipeId, $at)` consume `fn_recipe_cost_at`, pasos de mano de obra (`recipe_labor_steps`) y overhead (`recipe_overhead_allocations`). Devuelve lote, porción, yield y breakdowns.
- **Snapshots**: `createSnapshot()` invoca `sp_snapshot_recipe_cost` y registra en `recipe_extended_cost_history`. El historial se obtiene vía `getHistory()`/`compareSnapshots()`.
- **APIs REST** (`routes/api.php:266-274`, middleware `auth:sanctum` + `permission:can_view_recipe_dashboard` en el controller):
  - `GET /api/recipes/{id}/cost` → costo puntual (usa `fn_recipe_cost_at` directamente).
  - `GET /api/recipes/{id}/bom/implode` → `implodeBom()` recorre recursivamente sub-recetas (IDs `REC-*`) y devuelve solo ingredientes base.
  - `POST /api/recipes/{id}/cost/snapshot`, `GET /api/recipes/{id}/cost/history`, `GET /api/recipes/{id}/cost/compare` usan `RecipeCostingService`.
- **POS endpoints auxiliares**: `App\Http\Controllers\Pos\RecipeCostController` recalcula costo con `PosConsumptionService` y repos `CostosRepository`/`RecetaRepository`. Aún no tiene ruta registrada; cuando se exponga deberá agregarse a `routes/api.php`.

### 3.4 Recalculo diario y sync con POS
- **Job programado**: `app/Console/Kernel.php:19` agenda `recetas:recalcular-costos` (01:10 MX). El comando (`app/Console/Commands/RecalcularCostosRecetasCommand.php`) llama a `RecalcularCostosRecetasService`, que:
  1. Detecta insumos con cambios en `item_cost_history` o calculados desde `inv_recepcion_*`.
  2. Recalcula sub-recetas publicadas (`RecetaVersion::where('version_publicada', true)`).
  3. Propaga a recetas padre y registra en el historial (`registrarHistorialCosto`).
  4. Genera alertas (aún por implementar).
  Usa Redis para locks (`cost:lock:{date}`).
- **Sincronización POS**: `recipes:sync-pos` (`app/Console/Commands/SyncPosRecipes.php`) lee `public.menu_item` y `public.menu_modifier` del POS Floreant, crea/actualiza recetas `REC-#####` y placeholders `REC-MOD-#####`, y vincula `modificadores_pos`. Opciones `--modifiers` y `--dry-run`. Este comando se debe correr cada vez que se agreguen PLUs/modificadores nuevos en el POS.

### 3.5 Integraciones complementarias
- `App\Services\Pos\PosConsumptionService` (`recalcularCostoReceta`, `implosion` de BOM) es usado por el controlador POS y por procesos de consumo en `docs/PosConsumption/IMPLEMENTACION_COMPLETA.md`.
- `RecetaShadow` almacena recetas inferidas desde ventas POS para depuración y se espera que la UI futura permita validarlas (aún sin componente V4.0).

## 4. Rutas, permisos y componentes

| Tipo | Ruta | Handler | Permisos |
|------|------|---------|----------|
| Web (vista placeholder) | `/recetas` | `resources/views/recetas.blade.php` | `auth` |
| Livewire | `/recipes` | `RecipesIndex` | `auth` + menú `recetas` |
| Livewire | `/recipes/editor/{id?}` | `RecipeEditor` | `auth` |
| Catálogo UOM | `/catalogos/unidades` | `UnidadesIndex` | `auth` |
| Catálogo conversiones | `/catalogos/uom` | `ConversionesIndex` | `auth` |
| API cost | `/api/recipes/{id}/cost` | `Api\Inventory\RecipeCostController@show` | `auth:sanctum` + `can_view_recipe_dashboard` |
| API BOM | `/api/recipes/{id}/bom/implode` | idem | `auth:sanctum` + permission |
| API snapshots/history/compare | `/api/recipes/{id}/cost/*` | idem | `auth:sanctum` + permission |
| Console | `recipes:sync-pos`, `recetas:recalcular-costos` | Kernel schedule/manual | CLI |

El layout de todas las pantallas nuevas debe ser `layouts.terrena` con `['active' => 'recetas']` para mantener el sidebar correcto.

## 5. Reglas y buenas prácticas

1. **IDs estandarizados**: usa `RecipeEditor` para generar IDs `REC`/`SUB`. No crees registros manuales sin seguir el patrón.
2. **Versiones**: cada cambio en ingredientes debería crear una nueva versión en `receta_version`. El editor actual sobreescribe `version=1`; si se implementan múltiples versiones documenta aquí cómo se publican (`version_publicada=true`).
3. **Costeo real vs estándar**: `RecipeCostingService` consume funciones PostgreSQL, por lo que cualquier cambio en `fn_recipe_cost_at`/`sp_snapshot_recipe_cost` debe documentarse y probarse en la BD real.
4. **Permisos**: todas las rutas `/api/recipes/*` exigen `auth:sanctum` + permiso `can_view_recipe_dashboard`. Cualquier UI que exponga snapshots nuevos también debe validar `recipes.costs.snapshot` (ver `docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md`).
5. **POS ↔ Recetas**: al publicar nuevos PLUs/modificadores, corre `recipes:sync-pos` y completa la receta en el editor antes de permitir ventas para evitar ventas sin BOM.
6. **UOM**: mantén `unidades_medida`/`conversiones_unidad` sincronizados; cualquier cambio afecta inventario y costeo. Usa los Livewire de catálogo para preservar validaciones y paleta.

## 6. Riesgos y pendientes

1. **Versionado limitado**: `RecipeEditor` siempre trabaja con `version=1` y borra/recrea los detalles; no hay publicación, historial ni descripción de cambios. Implementar control real de versiones antes de abrir el módulo a usuarios finales.
2. **UI inconsistente en conversiones**: la vista Blade espera propiedades (`u_origen`, `showForm`, etc.) que no existen en `ConversionesIndex`. Se requiere unificar componente/vista para evitar errores al guardar conversiones.
3. **Dependencia de tablas opcionales**: `RecipeCostingService` y `RecalcularCostosRecetasService` invocan tablas como `item_cost_history`, `recipe_labor_steps`, `recipe_overhead_allocations`, `recipe_extended_cost_history` que no están garantizadas. Documenta su creación o maneja caminos alternos antes de desplegar.
4. **Loop potencial en BOM**: `implodeBom()` recorre sub-recetas por ID `REC-*` sin cachear; aunque limita la profundidad a 10 niveles, puede generar consultas pesadas o ciclos si existe referencia circular.
5. **POS controller sin ruta**: `App\Http\Controllers\Pos\RecipeCostController` no está expuesto en `routes/api.php`. Antes de usarlo, define endpoints y protege con permisos.
6. **Job diario sin pruebas de integración**: `RecalcularCostosRecetasService` mezcla cálculos WAC, Redis y escritura directa; faltan pruebas que validen los escenarios reales (`tests/Feature` no cubren el flujo completo).
7. **RecetaShadow sin UI**: no hay componente V4.0 para validar `receta_shadow` ni para mapear ventas pendientes, lo cual impide limpiar la cola de “productos sin receta”.

## 7. Checklist al modificar el módulo

- [ ] Verificaste las tablas/funciones en la BD real (`selemti.receta_*`, `recipe_cost_*`, `unidades_medida`, etc.) conectando a `172.24.240.1`.
- [ ] Las rutas web (`routes/web.php:216-252`) y API (`routes/api.php:266-274`) reflejan cualquier cambio y están cubiertas por `auth`/permisos adecuados.
- [ ] Si cambiaste el editor, versiones o catálogos UOM, actualizaste los componentes Livewire y documentaste el comportamiento aquí.
- [ ] Antes de exponer un endpoint nuevo, añadiste tests o al menos ejecutaste `php artisan test` y validaste `fn_recipe_cost_at`/`sp_snapshot_recipe_cost` en la BD.
- [ ] Corriste `./vendor/bin/pint` y `npm run build` (si tocaste UI), y registraste cambios relevantes en `docs/V4.0/Frontend/{Layout,Componentes}.md` si se añadieron componentes.
- [ ] Documentaste en esta ficha (y en `docs/V4.0/README.md`) cualquier dependencia adicional (ej. nuevas tablas de costos, permisos, jobs) al momento de abrir un PR.

Cumpliendo esta guía mantenemos alineado el flujo de recetas con inventario, producción y POS dentro de Terrena V4.0.
