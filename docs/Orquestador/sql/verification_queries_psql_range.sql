-- verification_queries_psql_range.sql
-- Terrena · Verificaciones clave para rangos de fechas (Cierre Diario, Consumo POS, Reproceso, Snapshots) · psql 9.5
-- Basado en el esquema detectado por discover_schema_psql.sql
-- Uso para análisis de rangos: ventas, mapeos, procesamientos, etc.
--
-- Uso (ejemplo):
--   \set fecha_inicio '2025-10-01'
--   \set fecha_fin '2025-10-31'
--   \set sucursal_key '1'        -- Clave textual usada en selemti (mov_inv.sucursal_id, snapshot.branch_id, etc.)
--   -- \set terminal_id 9939     -- (opcional) si quieres filtrar por una sola terminal
--   \i verification_queries_psql_range.sql

/* =======================================================================
 1) Ventas en rango de fechas sin mapeo POS→Receta (MENÚ)
======================================================================== */
SELECT
  ti.id               AS ticket_item_id,
  mi.id               AS menu_item_id,
  mi.pg_id            AS menu_item_pg_id,
  mi.name             AS menu_item_name,
  t.id                AS ticket_id,
  t.create_date::date AS fecha_venta,
  t.terminal_id,
  term.location       AS sucursal
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
      (pm.valid_from IS NULL OR pm.valid_from <= t.create_date::date)
  AND (pm.valid_to   IS NULL OR pm.valid_to   >= t.create_date::date)
   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= t.create_date::date)
 )
WHERE t.create_date::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  -- AND t.terminal_id = :'terminal_id'::int  -- habilita si definiste :terminal_id
  AND pm.plu IS NULL
ORDER BY t.create_date::date, mi.name;

/* =======================================================================
 1.b) Modificadores en rango de fechas sin mapeo (MODIFIER)
======================================================================== */
SELECT
  tim.id               AS ticket_item_mod_id,
  tim.item_id          AS modifier_item_id,
  t.id                 AS ticket_id,
  t.create_date::date  AS fecha_venta,
  t.terminal_id,
  term.location       AS sucursal
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
      (pm.valid_from IS NULL OR pm.valid_from <= t.create_date::date)
  AND (pm.valid_to   IS NULL OR pm.valid_to   >= t.create_date::date)
   OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= t.create_date::date)
 )
WHERE t.create_date::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  -- AND t.terminal_id = :'terminal_id'::int  -- habilita si definiste :terminal_id
  AND pm.plu IS NULL
ORDER BY t.create_date::date, tim.id;

/* =======================================================================
 2) Líneas inv_consumo_pos/_det pendientes en rango de fechas
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
WHERE h.created_at::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND (d.requiere_reproceso = true OR d.procesado = false)
ORDER BY h.created_at::date, h.ticket_id, d.id;

/* =======================================================================
 3) Tickets expandidos en rango pero sin movimientos definitivos en selemti.mov_inv
======================================================================== */
SELECT 
  h.ticket_id,
  h.created_at::date AS fecha_ticket,
  h.sucursal_id
FROM selemti.inv_consumo_pos h
WHERE h.created_at::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND NOT EXISTS (
    SELECT 1
    FROM selemti.mov_inv mi
    WHERE mi.sucursal_id = :'sucursal_key'
      AND mi.ref_id = h.ticket_id
      AND mi.ref_tipo IN ('TICKET','AJUSTE_REPROCESO_POS')
  )
ORDER BY h.created_at::date, h.ticket_id;

/* =======================================================================
 4) Recetas mapeadas en rango de fechas sin snapshot de costo
======================================================================== */
WITH recetas_mapeadas AS (
  SELECT DISTINCT (pm.receta_id)::bigint AS recipe_id,
         MIN(pm.valid_from) AS primer_mapeo
  FROM selemti.pos_map pm
  WHERE pm.receta_id IS NOT NULL
    AND (
         (pm.valid_from IS NOT NULL AND pm.valid_from BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date)
         OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date)
    )
  GROUP BY pm.receta_id
),
costeadas AS (
  SELECT DISTINCT rch.recipe_id,
         MIN(rch.fecha_registro) AS primer_costo
  FROM selemti.recipe_cost_history rch
  WHERE rch.fecha_registro::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  GROUP BY rch.recipe_id
)
SELECT 
    rm.recipe_id,
    rm.primer_mapeo,
    c.primer_costo
FROM recetas_mapeadas rm
LEFT JOIN costeadas c ON c.recipe_id = rm.recipe_id
WHERE c.recipe_id IS NULL
ORDER BY rm.recipe_id;

/* =======================================================================
 5) Conteos físicos abiertos en rango de fechas (por sucursal)
======================================================================== */
SELECT
  h.id,
  h.sucursal_id,
  h.programado_para::date AS programado_para,
  h.iniciado_en::date     AS iniciado_en,
  h.estado,
  h.cerrado_en::date      AS cerrado_en,
  (SELECT count(*) FROM selemti.inventory_count_lines l WHERE l.inventory_count_id = h.id) AS renglones
FROM selemti.inventory_counts h
WHERE h.sucursal_id::text = :'sucursal_key'
  AND (h.programado_para::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date 
       OR h.iniciado_en::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date)
  AND COALESCE(h.estado,'') NOT IN ('CERRADO','CLOSED')
ORDER BY h.programado_para::date, h.id;

/* =======================================================================
 6) Movimientos de inventario en rango por sucursal
======================================================================== */
SELECT 
  mi.ref_tipo,
  COUNT(*) as total_movimientos,
  COUNT(DISTINCT mi.item_id) as items_afectados,
  SUM(mi.cantidad) as suma_cantidades
FROM selemti.mov_inv mi
WHERE mi.sucursal_id = :'sucursal_key'
  AND mi.created_at::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
GROUP BY mi.ref_tipo
ORDER BY total_movimientos DESC;

/* =======================================================================
 7) Recuentos de tickets y consumos POS por día en el rango
======================================================================== */
WITH tickets_por_dia AS (
  SELECT t.create_date::date as fecha, COUNT(*) as tickets
  FROM public.ticket t
  JOIN public.terminal term ON term.id = t.terminal_id AND term.location::text = :'sucursal_key'
  WHERE t.create_date::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
  GROUP BY t.create_date::date
),
consumos_por_dia AS (
  SELECT h.created_at::date as fecha, COUNT(*) as consumos
  FROM selemti.inv_consumo_pos h
  WHERE h.created_at::date BETWEEN :'fecha_inicio'::date AND :'fecha_fin'::date
    AND h.sucursal_id::text = :'sucursal_key'
  GROUP BY h.created_at::date
)
SELECT 
    tp.fecha,
    tp.tickets,
    COALESCE(cp.consumos, 0) as consumos_expandidos
FROM tickets_por_dia tp
LEFT JOIN consumos_por_dia cp ON cp.fecha = tp.fecha
ORDER BY tp.fecha;