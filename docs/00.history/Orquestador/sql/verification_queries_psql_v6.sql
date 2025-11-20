
-- verification_queries_psql_v6.sql
-- Terrena · Verificaciones clave (Cierre Diario, Consumo POS, Reproceso, Snapshots) · psql 9.5
-- Basado en el esquema detectado por discover_schema_psql.sql
-- public: ticket, ticket_item, ticket_item_modifier, menu_item, terminal
-- selemti: pos_map(plu,tipo,receta_id,valid_from,valid_to,vigente_desde),
--          inv_consumo_pos, inv_consumo_pos_det(mp_id,uom_id,factor,...),
--          mov_inv(sucursal_id TEXT, ref_id, ref_tipo, cantidad, created_at),
--          inventory_snapshot(branch_id TEXT, item_id UUID, snapshot_date DATE),
--          inventory_counts(estado,sucursal_id,programado_para,iniciado_en,...),
--          inventory_count_lines,
--          recipe_cost_history(recipe_id, snapshot_at), recipe_extended_cost_history(...)
--
-- Uso (ejemplo):
--   \set bdate 2025-10-29
--   \set sucursal_key '1'        -- Clave textual usada en selemti (mov_inv.sucursal_id, snapshot.branch_id, etc.)
--   -- \set terminal_id 9939     -- (opcional) si quieres filtrar por una sola terminal
--   \i verification_queries_psql_v6.sql
--
-- NOTA: Para los bloques 1 y 1.b (POS), la sucursal se infiere por public.terminal.location = :'sucursal_key'.

/* =======================================================================
 1) Ventas del día sin mapeo POS→Receta (MENÚ)
    pm.plu se compara contra menu_item.id::text o menu_item.pg_id::text
======================================================================== */
SELECT
  ti.id               AS ticket_item_id,
  mi.id               AS menu_item_id,
  mi.pg_id            AS menu_item_pg_id,
  mi.name             AS menu_item_name,
  t.id                AS ticket_id,
  t.create_date::date AS fecha_venta,
  t.terminal_id
FROM public.ticket t
JOIN public.terminal term
  ON term.id = t.terminal_id
 AND term.location::text = :'sucursal_key'
JOIN public.ticket_item ti
  ON ti.ticket_id = t.id
LEFT JOIN public.menu_item mi
  ON mi.id = ti.item_id
LEFT JOIN selemti.pos_map pm
  ON pm.tipo = 'MENU'
 AND (pm.plu = mi.id::text OR pm.plu = mi.pg_id::text)
 AND (
      (pm.valid_from IS NULL OR pm.valid_from <= :'bdate'::date)
  AND (pm.valid_to   IS NULL OR pm.valid_to   >= :'bdate'::date)
   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= :'bdate'::date)
 )
WHERE t.create_date::date = :'bdate'::date
  -- AND t.terminal_id = :'terminal_id'::int  -- habilita si definiste :terminal_id
  AND pm.plu IS NULL
ORDER BY mi.name;

/* =======================================================================
 1.b) Modificadores del día sin mapeo (MODIFIER)
======================================================================== */
SELECT
  tim.id               AS ticket_item_mod_id,
  tim.item_id          AS modifier_item_id,
  t.id                 AS ticket_id,
  t.create_date::date  AS fecha_venta,
  t.terminal_id
FROM public.ticket t
JOIN public.terminal term
  ON term.id = t.terminal_id
 AND term.location::text = :'sucursal_key'
JOIN public.ticket_item ti
  ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim
  ON tim.ticket_item_id = ti.id
LEFT JOIN selemti.pos_map pm
  ON pm.tipo = 'MODIFIER'
 AND pm.plu = tim.item_id::text
 AND (
      (pm.valid_from IS NULL OR pm.valid_from <= :'bdate'::date)
  AND (pm.valid_to   IS NULL OR pm.valid_to   >= :'bdate'::date)
   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= :'bdate'::date)
 )
WHERE t.create_date::date = :'bdate'::date
  -- AND t.terminal_id = :'terminal_id'::int  -- habilita si definiste :terminal_id
  AND pm.plu IS NULL
ORDER BY tim.id;

/* =======================================================================
 2) Líneas inv_consumo_pos/_det pendientes (requiere_reproceso o no procesado)
    IMPORTANTE: inv_consumo_pos_det no tiene item_id; usa mp_id/uom_id/factor.
    Ajustado para verificar mp_id en mov_inv.
======================================================================== */
SELECT
  d.id,
  h.ticket_id,
  h.sucursal_id,
  h.terminal_id,
  h.created_at::date AS fecha,
  d.mp_id,           -- <== columna real
  d.uom_id,
  d.factor,
  d.cantidad,
  d.requiere_reproceso,
  d.procesado,
  h.fecha_proceso
FROM selemti.inv_consumo_pos      h
JOIN selemti.inv_consumo_pos_det  d ON d.consumo_id = h.id
LEFT JOIN selemti.materia_prima mp ON d.mp_id = mp.id
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND (d.requiere_reproceso = true OR d.procesado = false OR mp.id IS NULL)
ORDER BY h.ticket_id, d.id;

/* =======================================================================
 3) Tickets expandidos (inv_consumo_pos) pero sin movimientos definitivos en selemti.mov_inv
======================================================================== */
SELECT DISTINCT h.ticket_id
FROM selemti.inv_consumo_pos h
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND NOT EXISTS (
    SELECT 1
    FROM selemti.mov_inv mi
    WHERE mi.sucursal_id = :'sucursal_key'
      AND mi.ref_id = h.ticket_id
      AND mi.ref_tipo IN ('TICKET','AJUSTE_REPROCESO_POS')
  )
ORDER BY h.ticket_id;

/* =======================================================================
 4) Cobertura de snapshot diario por sucursal
======================================================================== */
WITH items_mov AS (
  SELECT DISTINCT item_id
  FROM selemti.mov_inv
  WHERE sucursal_id = :'sucursal_key'
    AND created_at::date <= :'bdate'::date
),
snap AS (
  SELECT item_id
  FROM selemti.inventory_snapshot
  WHERE branch_id = :'sucursal_key'
    AND snapshot_date = :'bdate'::date
)
SELECT
  (SELECT count(*) FROM items_mov) AS items_con_mov_historico,
  (SELECT count(*) FROM snap)      AS items_snapshoteados,
  ((SELECT count(*) FROM items_mov) - (SELECT count(*) FROM snap)) AS faltantes_en_snapshot;

/* =======================================================================
 5) Stocks teóricos negativos al cierre
======================================================================== */
SELECT item_id,
       SUM(cantidad) AS stock_teorico
FROM selemti.mov_inv
WHERE sucursal_id = :'sucursal_key'
  AND created_at <= (:'bdate'::date + interval '1 day' - interval '1 second')
GROUP BY item_id
HAVING SUM(cantidad) < 0
ORDER BY stock_teorico;

/* =======================================================================
 6) Recetas mapeadas sin snapshot de costo a la fecha
======================================================================== */
WITH recetas_mapeadas AS (
  SELECT DISTINCT (pm.receta_id)::bigint AS recipe_id
  FROM selemti.pos_map pm
  WHERE pm.receta_id IS NOT NULL
    AND (
         (pm.valid_from IS NULL OR pm.valid_from <= :'bdate'::date)
     AND (pm.valid_to   IS NULL OR pm.valid_to   >= :'bdate'::date)
      OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= :'bdate'::date)
    )
),
costeadas AS (
  SELECT DISTINCT rch.recipe_id
  FROM selemti.recipe_cost_history rch
  WHERE rch.snapshot_at::date <= :'bdate'::date
)
SELECT rm.recipe_id
FROM recetas_mapeadas rm
LEFT JOIN costeadas c ON c.recipe_id = rm.recipe_id
WHERE c.recipe_id IS NULL
ORDER BY rm.recipe_id;

/* =======================================================================
 7) Candidatos a reproceso (hay mapeo vigente y banderas pendientes en _det)
    IMPORTANTE: usar d.mp_id; cruzar ti/mi para validar el PLU del ítem vendido.
    Ajustado para verificar mp_id en materia_prima.
======================================================================== */
WITH map_menu AS (
  SELECT pm.*
  FROM selemti.pos_map pm
  WHERE pm.tipo = 'MENU'
    AND (
         (pm.valid_from IS NULL OR pm.valid_from <= :'bdate'::date)
     AND (pm.valid_to   IS NULL OR pm.valid_to   >= :'bdate'::date)
      OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= :'bdate'::date)
    )
)
SELECT
  h.ticket_id,
  d.id       AS detalle_id,
  d.mp_id    AS mp_id,     -- <== columna real
  d.cantidad,
  h.sucursal_id,
  h.terminal_id
FROM selemti.inv_consumo_pos      h
JOIN selemti.inv_consumo_pos_det  d ON d.consumo_id = h.id
LEFT JOIN selemti.materia_prima mp ON d.mp_id = mp.id
JOIN public.ticket_item ti ON ti.id = h.ticket_item_id
JOIN public.menu_item mi   ON mi.id = ti.item_id
JOIN map_menu pm ON pm.plu IN (mi.id::text, mi.pg_id::text)
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND d.requiere_reproceso = true
  AND mp.id IS NULL -- Check for invalid mp_id
ORDER BY h.ticket_id, detalle_id;

/* =======================================================================
 8) Conteos físicos abiertos en el día (por sucursal)
======================================================================== */
SELECT
  h.id,
  h.sucursal_id,
  h.programado_para::date AS programado_para,
  h.iniciado_en::date     AS iniciado_en,
  h.estado,
  (SELECT count(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id) AS renglones
FROM selemti.inventory_counts h
WHERE h.sucursal_id::text = :'sucursal_key'
  AND (h.programado_para::date = :'bdate'::date OR h.iniciado_en::date = :'bdate'::date)
  AND COALESCE(h.estado,'') NOT IN ('CERRADO','CLOSED')
ORDER BY h.id;
