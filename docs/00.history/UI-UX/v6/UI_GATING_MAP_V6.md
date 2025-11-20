# UI_GATING_MAP_V6

> Mapa de elementos UI ↔ permisos requeridos.  
> Usar en Livewire: `@can('permiso')` o `Gate::allows('permiso')` y ocultar elementos si no hay permiso.

## Inventario
- **/inventario/items**
  - Botón “Nuevo Ítem” → `inventory.items.manage`
  - Acción “Editar” → `inventory.items.manage`
  - Acción “Ajuste manual” → `inventory.moves.adjust`
- **/inventario/recepciones**
  - Botón “Postear” → `inventory.receptions.post`
- **/inventario/conteos**
  - Botón “Abrir conteo” → `inventory.counts.open`
  - Botón “Cerrar conteo” → `inventory.counts.close`
- **/inventario/snapshot**
  - Botón “Generar snapshot” → `inventory.snapshot.generate`

## POS
- **/pos/map**
  - Botón “Nuevo mapeo” → `pos.map.manage`
  - Acción “Editar mapeo” → `pos.map.manage`
- **/pos/auditoria**
  - Botón “Ejecutar auditoría SQL v6” → `pos.audit.run`
- **/pos/reprocess**
  - Botón “Reprocesar pendientes” → `pos.reprocess.run`

## Recetas / Costos
- **/recetas**
  - Botón “Nueva receta” → `recipes.manage`
  - Acción “Snapshot costo” → `recipes.costs.snapshot`

## Compras
- **/compras/sugerido** → `purchasing.suggested.view`
- **/compras/ordenes**
  - Botón “Nueva orden” → `purchasing.orders.manage`
  - Botón “Aprobar” → `purchasing.orders.approve`

## Producción
- **/produccion/ordenes**
  - Botón “Cerrar OP” → `production.orders.close`

## Reportes
- **/reportes/kpis** → `reports.kpis.view`
- **/reportes/auditoria** → `reports.audit.view`

## Sistema
- **/sistema/usuarios** → `system.users.view`
- **/sistema/plantillas**
  - CRUD Plantillas → `system.templates.manage`
- **/sistema/usuarios/{id}/permisos**
  - Asignar especiales → `system.permissions.direct.manage`
