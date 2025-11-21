
# Wireflows · Terrena (alineado a esquema actual)
> POS (schema `public`) + Backend operando en `selemti` · Sin DDL, solo lectura/escritura donde ya existe.

## Leyenda rápida
- 📄 Vista / Pantalla (CLI o Web existente)
- 🧠 Servicio / Job (Laravel)
- 🗃️ Tablas / Orígenes
- ✅ Paso OK · ⚠️ Advertencia · ❌ Error
- 🔁 Idempotencia (Redis lock / verificación previa)

---

## WF-01 · Cierre Diario (Orquestador)
**Objetivo:** Consolidar día por sucursal, validar pendientes y generar snapshot.

**Entradas**
- Parámetros: `bdate`, `sucursal_key` (string que coincide con `selemti.mov_inv.sucursal_id` y `inventory_snapshot.branch_id`).
- Mapeo terminal→sucursal por `public.terminal.location`.

**Flujo**
1. 📄 CLI: `php artisan close:daily --date={bdate} --branch={sucursal_key}`
2. 🧠 `DailyCloseService::checkPosSync()`
   - 🗃️ `selemti.pos_sync_batches` (si existe) o heurística por `public.ticket` del día.
   - ✅ Continúa / ⚠️ Log de lote incompleto.
3. 🧠 `processTheoreticalConsumption()`
   - 🗃️ `public.ticket`/`ticket_item` + `selemti.pos_map` (vigencias) → expandir a `selemti.inv_consumo_pos/_det` (si aún no existen) vía función `fn_confirmar_consumo_ticket(ticket_id)`.
   - 🔁 Verifica que **NO** existan movimientos previos en `selemti.mov_inv` con `ref_tipo IN ('TICKET', 'AJUSTE_REPROCESO_POS')` y `ref_id = ticket_id`.
4. 🧠 `checkOperationalMoves()`
   - 🗃️ `selemti.recepcion_*`, `selemti.transfer_*` (si existen) → solo loguea pendientes.
5. 🧠 `checkInventoryCounts()`
   - 🗃️ `selemti.inventory_counts` con `estado NOT IN ('CERRADO','CLOSED')` en `{bdate}` → log de advertencia si hay abiertos.
6. 🧠 `generateDailySnapshot()`
   - 🗃️ `selemti.mov_inv` (acumulado ≤ fin de `{bdate}`) → `selemti.inventory_snapshot` (UPSERT por `snapshot_date, branch_id, item_id`), respetando columnas: `teorico_qty`, `fisico_qty` (si existe conteo cerrado), `teorico_cost`/`valor_teorico`.
7. 📄 Resultado
   - ✅ Guarda semáforo en log canal `daily_close` (o tabla si ya existe) con payload JSON (ver esquema de métricas).

**Exits**
- ✅ `closed=true` si POS ok + consumo ok + snapshot ok.
- ⚠️ `open_counts>0` / `pending_receptions/transfers>0` no bloquean cierre, solo warnings.

---

## WF-02 · Consumo POS (expansión ticket→MP)
**Entrada**
- `ticket.id` del día, sucursal inferida por `terminal.location`.

**Flujo**
1. Validar mapeo:
   - MENÚ: `selemti.pos_map (tipo='MENU')` con `plu ∈ (menu_item.id::text, menu_item.pg_id::text)` y vigencia válida al `{bdate}`.
   - MODS: `selemti.pos_map (tipo='MODIFIER')` con `plu = ticket_item_modifier.item_id::text`.
2. Generar/validar `selemti.inv_consumo_pos` (cabecera) y `selemti.inv_consumo_pos_det`:
   - Columnas disponibles: cab (`ticket_id, ticket_item_id, sucursal_id(int), terminal_id, created_at, procesado, requiere_reproceso`), det (`mp_id, uom_id, factor, cantidad, procesado, requiere_reproceso, origen, fecha_proceso`).
3. Idempotencia:
   - Si existe en `selemti.mov_inv` algún registro con `ref_tipo IN ('TICKET','AJUSTE_REPROCESO_POS')` y `ref_id = {ticket_id}` → **no** reinsertar ni re-postear.
4. Posteo a `mov_inv` (si corresponde por política actual).

**Errores típicos**
- Falta de mapeo (ver WF-05).

---

## WF-03 · Reproceso POS
**Detonantes**
- `inv_consumo_pos_det.requiere_reproceso = true`
- Nuevo mapeo válido en `selemti.pos_map` posterior a la venta.

**Flujo**
1. Identificar candidatos (archivo v6 bloque 7).
2. Recalcular líneas `_det` con el mapeo vigente a `{bdate}` (respetar `origen` y `uom_id/factor`).
3. Postear ajustes `mov_inv` con `ref_tipo='AJUSTE_REPROCESO_POS'`, `ref_id=ticket_id`.
4. Marcar `procesado=true` y limpiar `requiere_reproceso`.

---

## WF-04 · Snapshots de Inventario
**Flujo**
1. Recopilar `item_id` con movimiento (`mov_inv`) por sucursal hasta `{bdate}`.
2. Calcular `teorico_qty = SUM(cantidad)` y, si hay cierres físicos del día (`inventory_counts` cerrados), asignar `fisico_qty` y `variance_qty`.
3. UPSERT `inventory_snapshot`:
   - keys: `(snapshot_date, branch_id, item_id)`
   - update: `teorico_qty, fisico_qty, variance_* , updated_at`

---

## WF-05 · Mantenimiento de Mapeos POS (MENU/MODIFIER)
**Objetivo**
- Mantener `selemti.pos_map` al día.

**Pantallas/Acciones**
- Lista de ventas sin mapa (bloques 1 y 1.b del SQL).
- Alta de mapeos con: `tipo`, `plu` (texto), `receta_id`(text/bigint), `recipe_version_id` (si se usa), vigencias `valid_from/valid_to` o `vigente_desde`.
- Filtro por `term.location` (= sucursal).

---

## WF-06 · Recalculo de Costos de Recetas
**Entrada**
- Cambios en costo MP: `item_cost_history` (si existe) o cálculo WAC desde recepciones del día.
- Vigencia receta: versión publicada efectiva `<= bdate`.

**Flujo**
1. Detectar MP con cambio costo (tabla o WAC).
2. Recalcular costo por versión vigente y subrecetas afectadas.
3. Persistir snapshot:
   - `selemti.recipe_cost_history` o `selemti.recipe_extended_cost_history` (si existe).
4. Alertas de margen (JSON/log o tabla existente).

---

## WF-07 · Conteos Físicos
**Flujo resumido**
1. Programar/iniciar conteo en `inventory_counts` (estado != CERRADO).
2. Capturar `inventory_count_lines` con `qty_contada`.
3. Al cerrar, registrar variaciones y alimentar `inventory_snapshot` del día.

