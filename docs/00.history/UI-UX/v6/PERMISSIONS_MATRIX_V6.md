# PERMISSIONS_MATRIX_V6

> Terrena · Plantillas y permisos atómicos alineados a v6 (POS solo lectura en `public.*`, ERP en `selemti.*`).  
> **Principio rector:** no modificar esquema; todos los permisos se aplican a nivel UI (visibilidad / habilitación) y en backend (policies/middleware).

## Convenciones
- Clave: `dominio.subdominio.accion`
- Tipo: `read`, `create`, `update`, `delete`, `execute`
- Alcance: `own` | `branch` | `all` (si aplica)
- Notas: tablas/endpoints involucrados para **contexto de prompts** (no para enforcement rígido).

| Módulo | Submódulo | Acción | Clave permiso | Tipo | Alcance | UI / Elemento | Back (service / route) | Notas |
|---|---|---|---|---|---|---|---|---|
| Inventario | Ítems | Ver | inventory.items.view | read | branch | /inventario/items | GET /api/inventory/items | Lectura catálogos |
| Inventario | Ítems | Crear/Editar | inventory.items.manage | update | branch | Modal Crear/Editar | POST/PUT /api/inventory/items | Sin cambios de esquema |
| Inventario | Presentaciones | Ver | inventory.uoms.view | read | branch | Tab Presentaciones | GET /api/inventory/uoms |  |
| Inventario | Presentaciones | Gestionar | inventory.uoms.manage | update | branch | CRUD presentaciones | POST/PUT /api/inventory/uoms |  |
| Inventario | Conversiones | Gestionar | inventory.uoms.convert.manage | update | branch | Tabla conversiones | POST/PUT /api/inventory/uoms/convert | Factores |
| Inventario | Recepciones | Ver | inventory.receptions.view | read | branch | /inventario/recepciones | GET /api/purchasing/receptions |  |
| Inventario | Recepciones | Postear | inventory.receptions.post | execute | branch | Botón “Postear” | POST /api/purchasing/receptions/{id}/post | Genera mov_inv |
| Inventario | Conteos | Ver | inventory.counts.view | read | branch | /inventario/conteos | GET /api/inventory/counts |  |
| Inventario | Conteos | Abrir | inventory.counts.open | execute | branch | Botón “Abrir conteo” | POST /api/inventory/counts/open |  |
| Inventario | Conteos | Cerrar | inventory.counts.close | execute | branch | Botón “Cerrar conteo” | POST /api/inventory/counts/{id}/close | Valida v6 §8 |
| Inventario | Movimientos | Ver | inventory.moves.view | read | branch | /inventario/movimientos | GET /api/inventory/moves |  |
| Inventario | Movimientos | Ajuste Manual | inventory.moves.adjust | execute | branch | Botón “Ajuste” | POST /api/inventory/moves/adjust |  |
| Inventario | Snapshot | Generar | inventory.snapshot.generate | execute | branch | Botón “Generar snapshot” | POST /api/inventory/snapshot | Upsert por (date, branch, item) |
| Inventario | Snapshot | Ver | inventory.snapshot.view | read | branch | /inventario/snapshot | GET /api/inventory/snapshot |  |
| Compras | Sugerido | Ver | purchasing.suggested.view | read | branch | /compras/sugerido | GET /api/purchasing/suggested |  |
| Compras | Órdenes | Crear/Editar | purchasing.orders.manage | update | branch | CRUD Órdenes | POST/PUT /api/purchasing/orders |  |
| Compras | Órdenes | Aprobar | purchasing.orders.approve | execute | branch | Botón “Aprobar” | POST /api/purchasing/orders/{id}/approve |  |
| Recetas | Recetas | Ver | recipes.view | read | branch | /recetas | GET /api/recipes |  |
| Recetas | Recetas | Gestionar | recipes.manage | update | branch | CRUD receta | POST/PUT /api/recipes | Versionado |
| Recetas | Costos | Recalcular (scheduler) | recipes.costs.recalc.schedule | execute | all | Cron 01:10 | `php artisan recetas:recalcular-costos` | Debe correr diario |
| Recetas | Costos | Snapshot manual | recipes.costs.snapshot | execute | branch | Botón “Snapshot costo” | POST /api/recipes/{id}/snapshot | Persiste en `recipe_cost_history` |
| POS | Mapeos | Ver | pos.map.view | read | branch | /pos/map | GET /api/pos/map | `selemti.pos_map` |
| POS | Mapeos | Gestionar | pos.map.manage | update | branch | CRUD mapeos | POST/PUT /api/pos/map | Claves: MENU/MODIFIER |
| POS | Auditoría | Ejecutar SQL v6 | pos.audit.run | execute | branch | Botón “Auditar POS” | Exec scripts v6 | Solo lectura `public.*` |
| POS | Reprocesos | Procesar | pos.reprocess.run | execute | branch | Botón “Reprocesar tickets” | POST /api/pos/reprocess | Usa flags inv_consumo_pos_det |
| Producción | Órdenes | Ver | production.orders.view | read | branch | /produccion/ordenes | GET /api/production/orders |  |
| Producción | Órdenes | Cerrar | production.orders.close | execute | branch | Botón “Cerrar OP” | POST /api/production/orders/{id}/close |  |
| Caja | Cortes | Precorte | cashier.preclose.run | execute | branch | /caja/precorte | POST /api/caja/precorte |  |
| Caja | Cortes | Corte final | cashier.close.run | execute | branch | /caja/corte | POST /api/caja/corte |  |
| Reportes | KPIs | Ver | reports.kpis.view | read | branch | /reportes/kpis | GET /api/reports/kpis |  |
| Reportes | Auditoría | Ver | reports.audit.view | read | branch | /reportes/auditoria | GET /api/reports/audit |  |
| Sistema | Usuarios | Ver | system.users.view | read | all | /sistema/usuarios | GET /api/system/users |  |
| Sistema | Plantillas | Gestionar | system.templates.manage | update | all | /sistema/plantillas | POST/PUT /api/system/templates |  |
| Sistema | Permisos directos | Gestionar | system.permissions.direct.manage | update | all | /sistema/usuarios/{id}/permisos | POST/PUT /api/system/users/{id}/permissions |  |

> **Sugerencia de enforcement:** Middleware por prefijo de ruta + `Gate::allows($perm)` en Livewire Actions/Buttons.  
> **Fallback:** ocultar elementos UI si el permiso no está presente (no solo deshabilitar).

## Grupos de plantillas sugeridos
- **Almacenista**: `inventory.items.view`, `inventory.counts.view`, `inventory.counts.open`, `inventory.counts.close`, `inventory.moves.view`, `inventory.snapshot.view`.
- **Jefe de Almacén**: Almacenista + `inventory.receptions.view`, `inventory.receptions.post`, `inventory.moves.adjust`, `pos.map.view`.
- **Compras**: `purchasing.suggested.view`, `purchasing.orders.manage`, `purchasing.orders.approve`, `inventory.receptions.view`.
- **Costos / Recetas**: `recipes.view`, `recipes.manage`, `recipes.costs.recalc.schedule`, `recipes.costs.snapshot`, `pos.map.manage`.
- **Producción**: `production.orders.view`, `production.orders.close`, `inventory.items.view`.
- **Auditoría / Reportes**: `reports.kpis.view`, `reports.audit.view`, `pos.audit.run`, `inventory.snapshot.view`.
- **Administrador del Sistema**: todos los permisos (`*`).

## Apéndice A — Endpoints / Policies (alias sugeridos)
- `InventoryPolicy` → `inventory.*`
- `PurchasingPolicy` → `purchasing.*`
- `RecipesPolicy` → `recipes.*`
- `PosPolicy` → `pos.*`
- `ProductionPolicy` → `production.*`
- `CashierPolicy` → `cashier.*`
- `ReportsPolicy` → `reports.*`
- `SystemPolicy` → `system.*`

## Apéndice B — Enlaces con Scripts v6
- SQL v6 Bloque 1/1.b → Permisos `pos.audit.run` y `pos.map.view/manage`.
- SQL v6 Bloque 8 → `inventory.counts.view/close`.
- Snapshots → `inventory.snapshot.generate` y `recipes.costs.snapshot`.
