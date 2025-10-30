# TerrenaLaravel – Contexto para Copilot

## Tech stack
- Laravel 12 + Livewire 3 + Tailwind
- PostgreSQL 9.5 (esquemas: `public` (solo lectura POS), `selemti` (estado/banderas))
- Políticas: **No cambiar esquema** salvo en `selemti` cuando ya está previsto. `public` es inmutable.

## Rutas/áreas clave
- app/Http/Controllers/** (Purchasing, Inventory, Orquestador)
- app/Livewire/** (componentes UI)
- routes/web.php, routes/api.php
- docs/Orquestador/**  (fuente de verdad de procesos)
- docs/Orquestador/sql/** (consultas psql finales)
- docs/Orquestador/WIREFLOWS_Terrena_v1.md  (flujo UI/UX)
- docs/Orquestador/RECETA_COST_CALCULATION*.md  (lógica de costos y scheduler)
- docs/Orquestador/Cierre_Diario.md, POS_* (consumo POS, reproceso, snapshot)

## Tablas reales (extracto)
- public: ticket, ticket_item, ticket_item_modifier, menu_item, terminal(id,location)
- selemti: pos_map(plu,tipo,receta_id,valid_from,valid_to,vigente_desde,meta),
           inv_consumo_pos(id, ticket_id, sucursal_id, terminal_id, created_at, ...),
           inv_consumo_pos_det(id, consumo_id, mp_id, cantidad, requiere_reproceso, procesado, ...),
           mov_inv(sucursal_id TEXT, ref_id, ref_tipo, item_id, cantidad, created_at, ...),
           inventory_snapshot(branch_id TEXT, item_id UUID, snapshot_date DATE, teorico_qty, fisico_qty, ...),
           inventory_counts/ inventory_count_lines,
           recipe_cost_history(recipe_id, recipe_version_id, portion_cost, snapshot_at, ...),
           recipe_extended_cost_history(...)

## Reglas duras para IA
- **Prohibido**: crear tablas nuevas, columnas nuevas o tocar `public.*`.
- Validar SIEMPRE contra scripts en `docs/Orquestador/sql/` antes de codificar cambios.
- Usar **nombres/columnas reales** (ver discover_schema_psql_v2.sql) y **queries v5** como contrato.
