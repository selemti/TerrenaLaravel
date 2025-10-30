# AGENT 04 Reproceso POS

## Objetivo
Implementar flujo de reproceso que toma `inv_consumo_pos_det.requiere_reproceso = true`, revalida mapeos y genera ajustes `mov_inv` (`ref_tipo='AJUSTE_REPROCESO_POS'`).

## Alcance
Sin DDL. Solo usar mapeos vigentes a `:bdate`. Idempotencia por `mov_inv` existente del mismo `ref_id/ref_tipo`.

## Pasos de trabajo (alto nivel)
1. Seleccionar candidatos (sql v5 bloque 7).
2. Revalidar mapeo con `map_menu`/`map_mod` a fecha.
3. Generar movimientos faltantes solo si no existe ya el ajuste para ese `detalle_id`.

## Validación mínima (checklist)
- Candidatos descienden tras reproceso exitoso.
- No se duplican movimientos de ajuste.

## Entregables
- Script Artisan/Command `pos:reprocess --date=YYYY-MM-DD --branch='X'` (si ya existe, usar). Evidencias.

## Restricciones y contexto compartido

# Lineamientos generales (aplican a todos los agentes)

- **Prohibido DDL**: No crear/alterar tablas, columnas ni índices. Solo lecturas/escrituras permitidas por los servicios existentes.
- **Esquema real**: Respetar las tablas/columnas confirmadas por `discover_schema_psql.sql` y los archivos existentes en `C:\xampp3\htdocs\TerrenaLaravel\docs\Orquestador`.
- **POS (public)**: `ticket`, `ticket_item`, `ticket_item_modifier`, `menu_item`, `terminal`.
- **Selemti**: `pos_map(plu,tipo,receta_id,valid_from,valid_to,vigente_desde,meta,sys_from,sys_to)`, `inv_consumo_pos`, `inv_consumo_pos_det(cantidad,factor,mp_id,uom_id,requiere_reproceso,procesado,origen,fecha_proceso)`, `mov_inv(sucursal_id TEXT, ref_id, ref_tipo, cantidad, created_at)`, `inventory_snapshot(branch_id TEXT, item_id UUID, snapshot_date, teorico_qty, fisico_qty, valor_teorico, variance_qty, variance_cost, ...)`, `inventory_counts(estado,sucursal_id,programado_para,iniciado_en,...)` + `inventory_count_lines`, `recipe_cost_history(recipe_id,portion_cost,batch_cost,yield_portions,snapshot_at,...)`, `recipe_extended_cost_history(...)`.
- **Idempotencia**: Usar locks Redis/Laravel (`Cache::lock(...)`) y verificaciones de existencia (ej. ya existe mov_inv para ticket).
- **Vigencias**: En `pos_map`, respetar `(valid_from <= :bdate AND (valid_to IS NULL OR valid_to >= :bdate)) OR vigente_desde <= :bdate`.
- **Sucursal/Terminal**:
  - Sucursal operativa se infiere por `public.terminal.location` y se cruza con `selemti.*` vía `sucursal_id` (TEXT en `mov_inv`, TEXT en `inventory_snapshot.branch_id`, TEXT en `inventory_counts.sucursal_id`).
  - Tickets se filtran por `public.ticket.create_date::date = :bdate` y `terminal.location = :sucursal_key`.
- **Log y Métricas**: Estructura JSON en canal `daily_close` (o tabla existente). Campos: `trace_id, step, branch_id, date, counts, warnings, errors`.
- **Rendimiento**: Paginación/cursors donde aplique. Batch size recomendado 500–1000.
- **Testing local**: cimentar pruebas con `psql` 9.5 y `Artisan` (comandos ya existentes). Variables `:bdate`, `:sucursal_key`, `:terminal_id`.
- **Rutas**: Mantener/usar nombres existentes. No romper interfaces actuales.



# Consultas de verificación disponibles

Usar el paquete validado **verification_queries_psql_v5.sql** (el que ya corrió correctamente). Parámetros en psql:
```
\set bdate 2025-10-29
\set sucursal_key '1'
-- \set terminal_id 9939   -- opcional
\i verification_queries_psql_v5.sql
```
Bloques incluidos: ventas/modificadores sin mapa, pendientes inv_consumo_pos, expandidos sin mov, cobertura snapshot, negativos, recetas sin snapshot, candidatos a reproceso, conteos abiertos.



