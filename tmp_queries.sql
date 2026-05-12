\set bdate '2026-04-07'
\set sucursal_key '1'

-- BLOQUE 2
SELECT
  d.id, h.ticket_id, h.sucursal_id, h.terminal_id, h.created_at::date AS fecha,
  d.mp_id, d.uom_id, d.factor, d.cantidad, d.requiere_reproceso, d.procesado, h.fecha_proceso
FROM selemti.inv_consumo_pos h
JOIN selemti.inv_consumo_pos_det d ON d.consumo_id = h.id
LEFT JOIN selemti.items mp ON d.mp_id::text = mp.id::text
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND (d.requiere_reproceso = true OR d.procesado = false OR mp.id IS NULL)
ORDER BY h.ticket_id, d.id;

-- BLOQUE 3
SELECT DISTINCT h.ticket_id
FROM selemti.inv_consumo_pos h
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi
    WHERE mi.sucursal_id = :'sucursal_key' AND mi.ref_id = h.ticket_id
      AND mi.ref_tipo IN ('TICKET','AJUSTE_REPROCESO_POS')
  )
ORDER BY h.ticket_id;

-- BLOQUE 7
WITH map_menu AS (
  SELECT pm.* FROM selemti.pos_map pm
  WHERE pm.tipo = 'MENU'
    AND ((pm.valid_from IS NULL OR pm.valid_from <= :'bdate'::date)
     AND (pm.valid_to   IS NULL OR pm.valid_to   >= :'bdate'::date)
      OR (pm.vigente_desde IS NOT NULL AND pm.vigente_desde::date <= :'bdate'::date))
)
SELECT h.ticket_id, d.id AS detalle_id, d.mp_id AS mp_id, d.cantidad, h.sucursal_id, h.terminal_id
FROM selemti.inv_consumo_pos h
JOIN selemti.inv_consumo_pos_det d ON d.consumo_id = h.id
LEFT JOIN selemti.items mp ON d.mp_id::text = mp.id::text
JOIN public.ticket_item ti ON ti.id = h.ticket_item_id
JOIN public.menu_item mi ON mi.id = ti.item_id
JOIN map_menu pm ON pm.plu IN (mi.id::text, mi.pg_id::text)
WHERE h.created_at::date = :'bdate'::date
  AND h.sucursal_id::text = :'sucursal_key'
  AND d.requiere_reproceso = true
  AND mp.id IS NULL
ORDER BY h.ticket_id, detalle_id;
