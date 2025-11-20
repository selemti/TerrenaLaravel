
# Terrena — Esquema de eventos y métricas a loggear

> Objetivo: tener trazabilidad + KPIs del **Cierre Diario** y del **Reproceso de Costos**, sin crear tablas nuevas. Los eventos se emiten como logs JSON (canal `daily_close`) y/o insert en tablas existentes donde aplique.

## Canal de log
- Canal: `daily_close`
- Formato: **JSON Lines** (una línea por evento)
- Campos base en **TODOS** los eventos:
  - `trace_id` (string) — correlación por ejecución.
  - `branch_id` (string)
  - `date` (YYYY-MM-DD) — fecha objetivo del cierre.
  - `step` (string) — nombre del paso o evento.
  - `level` (info|warning|error)
  - `ts` (ISO8601) — timestamp del evento.
  - `context` (object) — datos específicos del evento.

## Eventos principales (nombres sugeridos)
- `pos.sync.completed` — POS listo para la fecha/branch.
  - context: `{ batch_id, total_tickets, processed_tickets }`
- `consumption.started` / `consumption.finished`
  - context start: `{ pending_tickets }`
  - context finish: `{ tickets_processed }`
- `operational.pending_docs`
  - context: `{ pending_receptions, pending_transfers }`
  - *No bloquea* cierre, solo warning.
- `counts.pending_or_closed`
  - context: `{ open_counts }` (warning si >0)
- `snapshot.upserted`
  - context: `{ items_snapshotted }`
- `close.finished`
  - context: `{ pos_ok, consumo_ok, snapshot_ok }` + semáforo.

### Reproceso de costos (01:10)
- `costs.recalc.started`
  - context: `{ date, branch_id, insumos_con_cambio }`
- `costs.recalc.subrecipes.updated`
  - context: `[{ receta_id, version_id, costo_anterior, nuevo_costo }]`
- `costs.recalc.recipes.updated`
  - context: `[{ receta_id, costo_anterior, nuevo_costo }]`
- `costs.recalc.alert.margin`
  - context: `{ receta_id, nombre, costo, precio_venta, margen, porcentaje_margen, tipo (NEGATIVO|BAJO) }`
  - Si existe `selemti.alertas_costos`, insertar también.

## Métricas (derivables de logs/DB)
- % de cierres **completos** por semana (pos_ok ∧ consumo_ok ∧ snapshot_ok).
- `tickets_processed` por día y por sucursal.
- `pending_receptions`, `pending_transfers`, `open_counts` (tendencia semanal).
- `items_snapshotted` por día (cobertura).
- # recetas afectadas en recálculo, y # alertas de margen.
- Tiempo por paso: medir `ts` de started/finished → `duration_ms`.

## Convenciones de payload
- Evitar datos personales.
- IDs como string; montos en **centavos** (int) si es posible para evitar problemas de coma flotante.
- No loggear contenido sensible de .env, rutas del SO, ni SQL sin parametrizar.

## Ejemplos de líneas JSON
```json
{"trace_id":"close_abc123","branch_id":"1","date":"2025-10-29","step":"consumption.started","level":"info","ts":"2025-10-29T22:00:04-06:00","context":{"pending_tickets":14}}
{"trace_id":"close_abc123","branch_id":"1","date":"2025-10-29","step":"snapshot.upserted","level":"info","ts":"2025-10-29T22:03:10-06:00","context":{"items_snapshotted":412}}
{"trace_id":"cost_abc999","branch_id":"1","date":"2025-10-30","step":"costs.recalc.recipes.updated","level":"info","ts":"2025-10-30T01:14:52-06:00","context":[{"receta_id":"R-102","costo_anterior":28.5,"nuevo_costo":30.1}]}
```
