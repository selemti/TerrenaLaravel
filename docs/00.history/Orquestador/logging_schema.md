
# Terrena · Esquema de eventos y métricas a loggear

> Objetivo: tener **observabilidad** del cierre (22:00) y del recálculo (01:10) sin abrir la BD.

Formato sugerido: **JSON por línea** en canal `daily_close` y `recipe_recalc` con `JSON_UNESCAPED_UNICODE`.

## Campos base (todas las entradas)

- `trace_id`: id del proceso (ej. `close_...` / `recalc_...`)
- `timestamp`: ISO8601 (Laravel los añade; opcional incluirlo en el payload)
- `branch_id`: sucursal
- `date`: fecha objetivo (AAAA-MM-DD, negocio)
- `step`: nombre del paso (ver catálogo abajo)
- `level`: `info` | `warning` | `error` (del logger)
- `duration_ms` (opcional): tiempo del paso si es medible

## Catálogo de eventos (cierre 22:00)

- `start` `{ branch, date }`
- `step_check_pos_sync.started`
- `step_check_pos_sync.completed` `{ result: true|false, batch_id?, records_in?, records_ok? }`
- `step_process_consumption.started`
- `step_process_consumption.completed` `{ tickets_pending, tickets_processed }`
- `step_check_operational_moves.completed`  
  `{ pending_receptions, pending_transfers }` (si alguno >0, logger en `warning`)
- `step_check_inventory_counts.completed` `{ open_counts }` (warning si >0)
- `step_generate_snapshot.started`
- `step_generate_snapshot.completed` `{ items_snapshotted }`
- `finish`  
  `{ semaphore: { pos_ok, consumo_ok, movs_ok, conteos_ok, snapshot_ok }, closed }`

## Catálogo de eventos (re-cálculo 01:10)

- `start` `{ date, branch? }`
- `detect_item_cost_changes.completed` `{ items_changed }`
- `recalc_subrecipes.completed` `{ affected_subrecipes }`
- `recalc_recipes.completed` `{ affected_recipes }`
- `alerts.generated` `[{ receta_id, nombre, tipo, nivel, margen, pct_margen }]` (si aplica)
- `history.persist.completed` `{ rows_inserted }`
- `finish` `{ success: true|false, message? }`

## Métricas clave (para gráficos)

- `tickets_pending`, `tickets_processed`, `%tickets_processed`
- `pending_receptions`, `pending_transfers`, `open_counts`
- `items_snapshotted`
- `recetas_cost_updated`, `subrecetas_cost_updated`
- `alertas_margen_negativo`, `alertas_margen_bajo`

## Ejemplos (líneas JSON)

```json
{"trace_id":"close_6731a","branch_id":"1","date":"2025-10-29","step":"step_process_consumption.completed","tickets_pending":10,"tickets_processed":10}
```
```json
{"trace_id":"recalc_01b2","date":"2025-10-29","step":"recalc_recipes.completed","affected_recipes":42}
```
