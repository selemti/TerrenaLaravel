
-- =============================================
-- Terrena • Verificación de Cierre Diario (22:00)
-- y Re-cálculo de Costos (01:10)
-- Esquema: selemti
-- Uso en psql:
--   \set branch_id '1'
--   \set fecha '2025-10-29'
-- Reemplaza valores si no usas psql.
-- =============================================

-- 0) Contexto rápido
SELECT now() AS ahora_cdmx;

-- 1) POS sync completo
SELECT *
FROM selemti.pos_sync_batches b
WHERE b.branch_id = :branch_id
  AND b.business_date = :fecha
  AND b.status IN ('COMPLETED','CLOSED')
ORDER BY b.created_at DESC
LIMIT 5;

-- 2) Tickets pendientes de consumo (deben ser 0 tras cierre)
SELECT count(*) AS tickets_pendientes
FROM selemti.tickets t
WHERE t.branch_id = :branch_id
  AND DATE(t.created_at) = :fecha
  AND NOT EXISTS (
    SELECT 1
    FROM selemti.mov_inv mi
    WHERE mi.ref_tipo = 'TICKET'
      AND mi.ref_id = t.id
  );

-- 3) Movimientos operativos abiertos (solo warning)
-- 3.1 Recepciones
SELECT count(*) AS recepciones_pendientes
FROM selemti.recepcion_cab r
WHERE r.sucursal_id = :branch_id
  AND DATE(r.fecha_recepcion) = :fecha
  AND r.status NOT IN ('POSTED','APPLIED','CONFIRMED');

-- 3.2 Transferencias
SELECT count(*) AS transfer_pendientes
FROM selemti.transferencias tr
WHERE (tr.origen_id = :branch_id OR tr.destino_id = :branch_id)
  AND DATE(tr.fecha_transferencia) = :fecha
  AND tr.status NOT IN ('APPLIED','POSTED','CONFIRMED');

-- 4) Conteos abiertos (solo warning)
SELECT count(*) AS conteos_abiertos
FROM selemti.inventory_counts h
WHERE h.branch_id = :branch_id
  AND DATE(h.count_date) = :fecha
  AND h.status <> 'CLOSED';

-- 5) Snapshot del día (debe existir para la sucursal/fecha)
SELECT count(*) AS snapshot_rows
FROM selemti.inventory_snapshot s
WHERE s.snapshot_date = :fecha
  AND s.branch_id = :branch_id;

-- 5.1 Muestra 20 renglones representativos
SELECT item_id, teorico_qty, costo_unit_efectivo, fisico_qty, valor_teorico, variance_qty, variance_cost
FROM selemti.inventory_snapshot
WHERE snapshot_date = :fecha AND branch_id = :branch_id
ORDER BY COALESCE(ABS(variance_cost),0) DESC NULLS LAST
LIMIT 20;

-- 6) Coherencia de teórico (opcional: costoso si no hay índices)
--    Compara qty teórica de snapshot vs suma de mov_inv al cierre.
--    Ajusta el item_id a inspeccionar.
-- En psql:
--   \set item_id 'ITEM-TEST'
WITH qty_mov AS (
  SELECT SUM(mi.cantidad) AS qty
  FROM selemti.mov_inv mi
  WHERE mi.branch_id = :branch_id
    AND mi.item_id = :item_id
    AND mi.created_at <= (:fecha || ' 23:59:59')::timestamp
)
SELECT s.item_id, s.teorico_qty AS snapshot_qty, q.qty AS suma_movimientos
FROM selemti.inventory_snapshot s
JOIN qty_mov q ON TRUE
WHERE s.snapshot_date = :fecha
  AND s.branch_id = :branch_id
  AND s.item_id = :item_id;

-- 7) Re-cálculo de costos (01:10)
-- 7.1 Insumos con cambio de costo el día (si existe item_cost_history)
SELECT COUNT(*) AS insumos_con_cambio
FROM selemti.item_cost_history ich
WHERE ich.fecha_efectiva = :fecha;

-- 7.2 Recetas con histórico insertado el día
SELECT COUNT(*) AS recetas_historico
FROM selemti.recipe_cost_history rch
WHERE rch.fecha_efectiva = :fecha;

-- 7.3 Ver 20 recetas con mayor variación de costo (si guardas costo_anterior)
SELECT receta_id, costo_anterior, costo_unitario AS costo_nuevo,
       (costo_unitario - COALESCE(costo_anterior,0)) AS delta
FROM selemti.recipe_cost_history
WHERE fecha_efectiva = :fecha
ORDER BY ABS(costo_unitario - COALESCE(costo_anterior,0)) DESC
LIMIT 20;

-- 8) Calidad de margen (si no hay tabla de alertas, revisa logs)
SELECT tipo_alerta, COUNT(*) AS total
FROM selemti.alertas_costos
WHERE fecha_alerta = :fecha
GROUP BY 1;

-- 9) Métricas rápidas (para dashboard de cierre)
WITH t_all AS (
  SELECT COUNT(*) AS total
  FROM selemti.tickets t
  WHERE t.branch_id = :branch_id AND DATE(t.created_at) = :fecha
),
t_proc AS (
  SELECT COUNT(DISTINCT mi.ref_id) AS procesados
  FROM selemti.mov_inv mi
  WHERE mi.ref_tipo='TICKET'
    AND mi.branch_id=:branch_id
    AND DATE(mi.created_at)=:fecha
)
SELECT t_all.total, t_proc.procesados,
       ROUND(100.0 * t_proc.procesados / NULLIF(t_all.total,0),2) AS pct_procesado
FROM t_all, t_proc;

-- 10) Índices recomendados (solo para verificar existencia)
-- SELECT * FROM pg_indexes WHERE schemaname='selemti' AND tablename IN ('mov_inv','tickets','inventory_snapshot');
