# AGENT 01 Orquestador Cierre Diario

## Objetivo
Operar el cierre diario para una sucursal/fecha: verificar sync POS, procesar consumo teórico por tickets del día, revisar pendientes (no bloqueantes), generar snapshot diario idempotente.

## Alcance
Sucursal/fecha controladas por parámetros `:sucursal_key` y `:bdate`. Usar servicios existentes en `app/Operations/DailyCloseService.php` (ya actualizado por Gemini). No crear endpoints nuevos; exponer estado por log y, si existe, endpoint actual.

## Pasos de trabajo (alto nivel)
1. **checkPosSync**: Validar lote en `selemti.pos_sync_batches` si existe; en su ausencia, validar por presencia de tickets del día.
2. **processTheoreticalConsumption**: Ejecutar `fn_confirmar_consumo_ticket(ticket_id)` para tickets **sin** movimientos definitivos (verificación por `mov_inv` ref_tipo/ref_id).
3. **checkOperationalMoves**: Contar recepciones/transferencias/otros no finalizados. Solo loggear warning.
4. **checkInventoryCounts**: Conteos del día abiertos → warning.
5. **generateDailySnapshot**: UPSERT por (`snapshot_date`, `branch_id`, `item_id`). Cargar `teorico_qty` sumando `mov_inv` hasta fin del día; `fisico_qty` desde `inventory_count_lines` cerrados en el día.


## Validación mínima (checklist)
- `verification_queries_psql_v5.sql` devuelve **0 errores** en bloques 3,4,5 para `:sucursal_key, :bdate` tras el cierre.
- Logs contienen `trace_id`, counters (`tickets_processed`, `items_snapshotted`), warnings 0..n.
- Re-ejecución del cierre **no duplica** movimientos ni snapshots.

## Entregables
- Evidencia psql (capturas).
- Log `daily_close` (adjuntar JSON).
- Sección `## Evidencia <fecha>` en `docs/Orquestador/IMPLEMENTACION_COMPLETA.md` o archivo nuevo `CierreDiario_Evidencia_<fecha>.md`.

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



