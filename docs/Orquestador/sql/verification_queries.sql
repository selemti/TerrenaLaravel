
-- Terrena / SelemTI — Verificación de Cierre Diario y Consumos
-- Ajusta nombres de columnas si difieren en tu dump. Todos los objetos están en el esquema selemti.
-- Usa: \set date '2025-10-29'   \set branch_id '1'

/* ========== 0. Contexto de fecha / sucursal (helpers) ========== */
-- Variables (psql): :date, :branch_id

/* ========== 1. POS Sync ========== */
-- ¿Hay batch COMPLETED para la fecha/sucursal?
SELECT id, branch_id, batch_date, status, total_tickets, processed_tickets, created_at, updated_at
FROM selemti.pos_sync_batches
WHERE branch_id = :'branch_id'
  AND batch_date::date = :'date'::date
ORDER BY created_at DESC;

-- ¿Faltantes? (no completados o sin registro)
WITH d AS (
  SELECT :'date'::date AS dte
)
SELECT d.dte AS target_date,
       NOT EXISTS (
         SELECT 1 FROM selemti.pos_sync_batches b
         WHERE b.branch_id = :'branch_id'
           AND b.batch_date::date = d.dte
           AND b.status IN ('COMPLETED','DONE','OK')
       ) AS missing_or_incomplete;

/* ========== 2. Tickets sin consumo postead@ ========== */
-- Tickets del día que no han generado movimientos (idempotencia)
SELECT t.id AS ticket_id, t.branch_id, t.created_at
FROM selemti.tickets t
WHERE t.branch_id = :'branch_id'
  AND t.created_at::date = :'date'::date
  AND NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi
    WHERE mi.ref_tipo = 'TICKET'
      AND mi.ref_id::text = t.id::text
  )
ORDER BY t.created_at;

-- Conteo rápido
SELECT COUNT(*) AS tickets_pendientes
FROM selemti.tickets t
WHERE t.branch_id = :'branch_id'
  AND t.created_at::date = :'date'::date
  AND NOT EXISTS (
    SELECT 1 FROM selemti.mov_inv mi
    WHERE mi.ref_tipo = 'TICKET'
      AND mi.ref_id::text = t.id::text
  );

/* ========== 3. Movimientos del día (auditoría) ========== */
-- Resumen por tipo
SELECT branch_id, tipo_mov, COUNT(*) AS movimientos, SUM(cantidad) AS qty, SUM(coalesce(costo_unit,0)*cantidad) AS monto
FROM selemti.mov_inv
WHERE branch_id = :'branch_id'
  AND created_at::date = :'date'::date
GROUP BY branch_id, tipo_mov
ORDER BY tipo_mov;

-- Movs con referencias no válidas (ref_id huérfano)
SELECT mi.*
FROM selemti.mov_inv mi
LEFT JOIN selemti.tickets t ON (mi.ref_tipo = 'TICKET' AND mi.ref_id::text = t.id::text)
LEFT JOIN selemti.recepcion_cab rc ON (mi.ref_tipo = 'RECEPCION' AND mi.ref_id::text = rc.id::text)
LEFT JOIN selemti.transferencias tr ON (mi.ref_tipo = 'TRANSFER' AND mi.ref_id::text = tr.id::text)
WHERE mi.created_at::date = :'date'::date
  AND (
    (mi.ref_tipo = 'TICKET'    AND t.id IS NULL) OR
    (mi.ref_tipo = 'RECEPCION' AND rc.id IS NULL) OR
    (mi.ref_tipo = 'TRANSFER'  AND tr.id IS NULL)
  );

/* ========== 4. Operación: recepciones y transferencias pendientes ========== */
-- Recepciones no “POSTED” del día
SELECT id, proveedor_id, sucursal_id, almacen_id, fecha_recepcion, status
FROM selemti.recepcion_cab
WHERE sucursal_id::text = :'branch_id'
  AND fecha_recepcion::date = :'date'::date
  AND status NOT IN ('POSTED','CLOSED','APPLIED')
ORDER BY fecha_recepcion;

-- Transferencias no “APPLIED” del día (origen/destino)
SELECT id, origen_id, destino_id, fecha_transferencia, status
FROM selemti.transferencias
WHERE (origen_id::text = :'branch_id' OR destino_id::text = :'branch_id')
  AND fecha_transferencia::date = :'date'::date
  AND status NOT IN ('APPLIED','CLOSED')
ORDER BY fecha_transferencia;

/* ========== 5. Conteos de inventario abiertos ========== */
SELECT h.id, h.branch_id, h.count_date, h.status, COUNT(l.id) AS lineas
FROM selemti.inventory_counts h
LEFT JOIN selemti.inventory_count_lines l ON l.inventory_count_id = h.id
WHERE h.branch_id = :'branch_id'
  AND h.count_date::date = :'date'::date
  AND h.status <> 'CLOSED'
GROUP BY h.id, h.branch_id, h.count_date, h.status
ORDER BY h.count_date, h.id;

/* ========== 6. Snapshot diario (existencia / consistencia) ========== */
-- ¿Existen snapshots para la fecha?
SELECT COUNT(*) AS snapshots_del_dia
FROM selemti.inventory_snapshot s
WHERE s.branch_id = :'branch_id'
  AND s.snapshot_date::date = :'date'::date;

-- Diferencia entre stock teórico (mov_inv acumulado) y snapshot.teorico_qty
WITH tec AS (
  SELECT item_id, SUM(cantidad) AS qty
  FROM selemti.mov_inv
  WHERE branch_id = :'branch_id'
    AND created_at::date <= :'date'::date
  GROUP BY item_id
)
SELECT s.item_id,
       s.teorico_qty AS snapshot_qty,
       coalesce(tec.qty,0) AS teorico_calculado,
       (coalesce(tec.qty,0) - s.teorico_qty) AS delta
FROM selemti.inventory_snapshot s
LEFT JOIN tec ON tec.item_id = s.item_id
WHERE s.branch_id = :'branch_id'
  AND s.snapshot_date::date = :'date'::date
ORDER BY ABS(coalesce(tec.qty,0) - s.teorico_qty) DESC, s.item_id;

/* ========== 7. Cambios de costo de insumos (item_cost_history si existe) ========== */
-- Cambios de costo del día
-- Si tu dump no tiene item_cost_history, ignora esta sección y deriva del WAC de recepciones.
SELECT item_id, costo, fecha_efectiva, tipo_cambio
FROM selemti.item_cost_history
WHERE fecha_efectiva::date = :'date'::date
ORDER BY item_id;

-- (Alternativa) Cálculo WAC por recepciones del día
-- Asume inv_recepcion_cab / inv_recepcion_det (ajusta a tu esquema real)
SELECT rd.item_id,
       SUM(rd.cantidad * rd.costo_unitario) / NULLIF(SUM(rd.cantidad),0) AS wac_dia
FROM selemti.inv_recepcion_det rd
JOIN selemti.inv_recepcion_cab rc ON rc.id = rd.recepcion_id
WHERE rc.fecha_recepcion::date = :'date'::date
GROUP BY rd.item_id
ORDER BY rd.item_id;

/* ========== 8. Historial de costo de recetas del día ========== */
-- Usa recipe_cost_history y/o recipe_extended_cost_history si existen
SELECT receta_id, costo_unitario, fecha_efectiva, fecha_registro, tipo_cambio
FROM selemti.recipe_cost_history
WHERE fecha_efectiva::date = :'date'::date
ORDER BY receta_id;

SELECT receta_id, costo_unitario, fecha_efectiva, fecha_registro, tipo_cambio
FROM selemti.recipe_extended_cost_history
WHERE fecha_efectiva::date = :'date'::date
ORDER BY receta_id;

/* ========== 9. Integridad de recetas (vigencias y mapeo POS) ========== */
-- Versiones publicadas vigentes a la fecha sin mapear a Item POS (si tienes tabla de mapeo)
SELECT rv.receta_id, rv.id AS receta_version_id, rv.fecha_efectiva
FROM selemti.receta_version rv
LEFT JOIN selemti.pos_item_recipe_map m ON m.receta_id = rv.receta_id
WHERE rv.version_publicada = TRUE
  AND rv.fecha_efectiva <= :'date'::date
  AND m.receta_id IS NULL
ORDER BY rv.receta_id;

-- Detalles de receta con item faltante
SELECT rd.receta_version_id, rd.item_id
FROM selemti.receta_det rd
LEFT JOIN selemti.items i ON i.id = rd.item_id
WHERE i.id IS NULL;

/* ========== 10. Calidad de datos ========== */
-- Items con costo_promedio negativo o nulo que aparecen en mov_inv hoy
SELECT i.id, i.nombre, i.costo_promedio
FROM selemti.items i
JOIN selemti.mov_inv mi ON mi.item_id = i.id
WHERE mi.created_at::date = :'date'::date
  AND i.costo_promedio <= 0
GROUP BY i.id, i.nombre, i.costo_promedio;

-- Movimientos con cantidad = 0 o costo_unit incoherente
SELECT *
FROM selemti.mov_inv
WHERE created_at::date = :'date'::date
  AND (cantidad = 0 OR costo_unit < 0);
