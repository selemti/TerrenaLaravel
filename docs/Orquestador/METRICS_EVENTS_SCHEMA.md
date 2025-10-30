
# Esquema de Eventos & Métricas (logging JSON)
> Canal sugerido: `daily_close` (Monolog). Si ya tienes tabla, usa los mismos campos y guarda el `payload` JSON.

## Campos comunes
- `trace_id` (uuid)
- `branch_id` (string = `sucursal_key`)
- `date` (ISO YYYY-MM-DD)
- `step` (cadena): ej. `step_check_pos_sync`, `step_process_consumption`, `step_generate_snapshot`
- `level` (`info`|`warning`|`error`)
- `meta` (objeto JSON específico del paso)

## Meta por paso (ejemplos)

### step_check_pos_sync
```json
{
  "pos_batches": {"expected": 1, "completed": 1},
  "tickets_day": 324,
  "terminals": [{"id": 9939, "location": "1"}]
}
```

### step_process_consumption
```json
{
  "tickets_scanned": 324,
  "tickets_processed": 320,
  "skipped_already_posted": 4,
  "map_missing": [{"ticket_id": 123, "menu_item_id": 456, "type": "MENU"}]
}
```

### step_check_operational_moves
```json
{"pending_receptions": 0, "pending_transfers": 2}
```

### step_check_inventory_counts
```json
{"open_counts": 1, "details": [{"id": 55, "estado": "EN_PROCESO"}]}
```

### step_generate_snapshot
```json
{"items_snapshotted": 1456, "with_physical_counts": 320, "negatives": 12}
```

### cost_recalc
```json
{"mp_changed": 28, "recipes_recosted": 76, "alerts": 3}
```

## Reglas
- **Nunca** inventar columnas: usa exclusivamente las detectadas.
- Los IDs externos: `ref_tipo`, `ref_id` para trazar POS→mov_inv.
- Tiempos: usa timezone `America/Mexico_City`.
