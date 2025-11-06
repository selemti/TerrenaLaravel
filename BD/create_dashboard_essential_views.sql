-- Script simplificado para crear vistas ESENCIALES del dashboard
-- Fecha: 2025-11-06
-- Solo incluye vistas que usan tablas y columnas confirmadas

SET search_path TO selemti, public;

-- ============================================================
-- VISTAS DE DASHBOARD - PRODUCTOS Y CATEGORÍAS
-- ============================================================

-- Ventas por producto (PLU) con categoría
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_productos AS
SELECT
  base.fecha,
  base.sucursal_id,
  base.terminal_id,
  ti.item_id AS plu,
  COALESCE(NULLIF(ti.item_name, ''), mi.name, ti.item_id::text) AS descripcion,
  COALESCE(mg.name, 'SIN CATEGORIA') AS categoria,
  SUM(
    COALESCE(
      NULLIF(ti.item_quantity, 0),
      NULLIF(ti.item_count, 0),
      0
    )
  ) AS unidades,
  SUM(COALESCE(ti.total_price, 0)) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
JOIN public.ticket_item ti
  ON ti.ticket_id = base.ticket_id
LEFT JOIN public.menu_item mi
  ON mi.id = ti.item_id
LEFT JOIN public.menu_group mg
  ON mg.id = mi.group_id
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.sucursal_id, base.terminal_id, ti.item_id, descripcion, categoria;

-- Ventas agregadas por categoría de producto
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_categorias AS
SELECT
  fecha,
  sucursal_id,
  categoria,
  SUM(unidades) AS unidades,
  SUM(venta_total) AS venta_total
FROM selemti.vw_dashboard_ventas_productos
GROUP BY fecha, sucursal_id, categoria;

-- ============================================================
-- VISTAS DE DASHBOARD - FORMAS DE PAGO
-- ============================================================

-- Formas de pago normalizadas (VERSION SIMPLIFICADA sin función)
CREATE OR REPLACE VIEW selemti.vw_dashboard_formas_pago AS
SELECT
  t.transaction_time::date AS fecha,
  COALESCE(NULLIF(term.location, ''), 'Sin sucursal') AS sucursal_id,
  COALESCE(fp.codigo, t.payment_type, 'OTRO') AS codigo_fp,
  SUM(t.amount)::numeric(12,2) AS monto
FROM public.transactions t
LEFT JOIN selemti.formas_pago fp
  ON fp.payment_type = t.payment_type
 AND COALESCE(fp.transaction_type, '') = COALESCE(t.transaction_type, '')
 AND COALESCE(fp.payment_sub_type, '') = COALESCE(t.payment_sub_type, '')
LEFT JOIN public.terminal term
  ON term.id = t.terminal_id
WHERE t.transaction_time IS NOT NULL
GROUP BY t.transaction_time::date, COALESCE(NULLIF(term.location, ''), 'Sin sucursal'), COALESCE(fp.codigo, t.payment_type, 'OTRO');

-- ============================================================
-- VISTAS DE DASHBOARD - ÓRDENES
-- ============================================================

-- Órdenes recientes
CREATE OR REPLACE VIEW selemti.vw_dashboard_ordenes AS
SELECT
  base.ticket_id,
  base.fecha,
  base.hora,
  base.sucursal_id,
  base.terminal_id,
  base.ticket_ref,
  base.total,
  base.closing_date
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE;

-- ============================================================
-- VISTA ADICIONAL - Ticket promedio
-- ============================================================

-- Ticket promedio por sucursal/dia
CREATE OR REPLACE VIEW selemti.vw_ticket_promedio_sucursal_dia AS
WITH tbase AS (
  SELECT
    fecha,
    sucursal_id,
    ticket_id,
    total
  FROM selemti.vw_dashboard_ticket_base
  WHERE paid = TRUE
    AND voided = FALSE
)
SELECT
  fecha,
  sucursal_id,
  COUNT(DISTINCT ticket_id) AS tickets,
  SUM(total) AS venta_total,
  CASE WHEN COUNT(DISTINCT ticket_id) > 0 THEN SUM(total) / COUNT(DISTINCT ticket_id) ELSE 0 END AS ticket_promedio
FROM tbase
GROUP BY fecha, sucursal_id;

-- Ventas por hora (tickets y monto) por sucursal y terminal
CREATE OR REPLACE VIEW selemti.vw_ventas_por_hora AS
SELECT
  fecha,
  hora,
  sucursal_id,
  terminal_id,
  tickets,
  venta_total
FROM selemti.vw_dashboard_ventas_hora
ORDER BY hora DESC;

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================

SELECT 'Vistas esenciales del dashboard creadas correctamente' AS resultado;
