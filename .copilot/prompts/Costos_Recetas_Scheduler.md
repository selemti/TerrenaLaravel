Rol: Dev Laravel (tareas programadas). No crear tablas.

Objetivo:
- Confirmar comando `recetas:recalcular-costos` diario a **01:10 America/Mexico_City**.
- Persistir snapshots en `selemti.recipe_cost_history` (campo `snapshot_at` del día).
- Si no hay `item_cost_history`, calcular WAC por recepciones del día (no inventar tablas nuevas).

Validación:
- Generar `docs/Orquestador/Costos_Scheduler_Log_<fecha>.md` con:
  - Conteo de recetas afectadas.
  - `SELECT count(*) FROM selemti.recipe_cost_history WHERE snapshot_at::date = :'bdate'`.

Entrega:
- Rama: `feat/scheduler-costos-<fecha>`.
- Citar `docs/Orquestador/RECETA_COST_CALCULATION*.md` como contrato.
