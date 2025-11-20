
# Backlog orientado a agentes (100% alineado a tu esquema)

1) **UI: POS Map Gaps (MENU/MODIFIER)**
   - Lista por sucursal (usando `public.terminal.location`).
   - Alta/edición `selemti.pos_map`: campos `tipo, plu, receta_id(text->bigint), recipe_version_id, valid_from/valid_to, vigente_desde, pos_system, meta`.
   - Acciones masivas: activar/desactivar vigencia.

2) **Servicio: Reproceso POS**
   - Entrada: `ticket_id` (o rango por fecha/sucursal).
   - Lógica: rehacer `_det` donde `requiere_reproceso = true`, postear `mov_inv` con `ref_tipo='AJUSTE_REPROCESO_POS'`.
   - Idempotencia: verificar `mov_inv` previo por `ticket_id`.

3) **Reporte: Cobertura Snapshot / Negativos**
   - Fuente: bloques 4 y 5 del SQL v6.
   - Tableros KPI: items con movimiento vs snap, negativos por sucursal.

4) **Costos recetas (recurring 01:10)**
   - Integrar `item_cost_history` si aparece; fallback WAC por recepciones del día (tablas ya existentes).
   - Persistir en `recipe_cost_history`/`recipe_extended_cost_history`.

5) **Bitácora orquestador**
   - Si no hay tabla, mantener solo canal `daily_close` con JSON (payload definido).
   - UI simple para filtrar por `branch_id` y `date` y renderizar JSON.

6) **CLI Helpers**
   - Script `.sql` empaquetado (v6) y alias de PowerShell/cmd para setear `bdate/sucursal_key` rápido.
