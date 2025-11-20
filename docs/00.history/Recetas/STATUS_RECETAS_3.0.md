# Estado Recetas v3.0 (Noviembre 2025)

## Resumen Ejecutivo
- ✅ Snapshots históricos de costo (`recipe_cost_snapshots`).
- ✅ Servicio de snapshots con detección >2 % y consultas rápidas.
- ✅ Implosión de BOM vía API (`GET /api/recipes/{id}/bom/implode`).
- ✅ Seeders de catálogos y receta demo listos para producción.
- ✅ Interfaces Livewire con validación inline, skeletons y toasts.

## Cambios Técnicos

### Base de Datos
- Nueva tabla `selemti.recipe_cost_snapshots` (id BIGSERIAL, JSONB `cost_breakdown`, `reason`).
- Índices por `recipe_id` y `snapshot_date`.
- FK `created_by_user_id` → `users.id` (ON DELETE SET NULL).

### Backend
- `RecipeCostSnapshot` (modelo) + scopes `forRecipe`, `beforeDate`, `latestPerRecipe`.
- `RecipeCostSnapshotService`:
  - `createSnapshot()` utiliza `RecipeCostController::calculateCostAtDate`.
  - `checkAndCreateIfThresholdExceeded()` evalúa 2 %.
  - `getCostAtDate()` prioriza snapshots, fallback a cálculo en vivo.
  - `createSnapshotsForAllRecipes()` orientado a jobs.
- `RecipeCostController::implodeRecipeBom()` + helper recursivo con protección depth=10.

### Frontend Livewire
- Formulario de proveedores, sucursales, almacenes y recetas con `wire:model.live` y mensajes en español.
- Skeleton loaders (`resources/css/app.css`) para tablas.
- Modales responsive + componente `<x-toast-notification />` en layout general.
- Nuevos componentes Blade: `search-input`, `status-badge`, `action-buttons`, `empty-state`.

### Seeders
- `CatalogosProductionSeeder`: unifica `cat_unidades`, `cat_sucursales`, `cat_almacenes`, categorías, proveedores.
- `RecipesProductionSeeder`: receta demo `REC-DEMO-001` + versión inicial.

### Tests
- `tests/Feature/RecipeCostSnapshotTest.php` (5 escenarios).
- `tests/Feature/RecipeBomImplosionTest.php` (3 escenarios).
- `tests/Feature/WeekendDeploymentIntegrationTest.php` (API + snapshots + BOM).

## Endpoints Relevantes
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/recipes/{id}/cost` | Consulta histórica (usa snapshots cuando existen) |
| GET | `/api/recipes/{id}/bom/implode` | Implosionar BOM hacia ingredientes base |
| POST | `/api/recipes/{id}/cost/snapshot` *(pendiente UI)* | Crear snapshot manual |

## Próximos Pasos
1. Programar job nocturno para snapshots (`php artisan schedule:list`).
2. Integrar UI para disparar snapshots manuales.
3. Exponer filtro "Usar snapshot más cercano" en reportes de rentabilidad.
4. Ampliar documentación de mermas y relación con snapshots.

