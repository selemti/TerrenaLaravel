-- Script para crear vistas del dashboard de ventas
-- Fecha: 2025-11-06
-- Propósito: Crear vistas necesarias para los reportes de ventas por hora

SET search_path TO selemti, public;

-- Vista base: Tickets normalizados para dashboard
CREATE OR REPLACE VIEW selemti.vw_dashboard_ticket_base AS
SELECT
  t.id AS ticket_id,
  date_trunc('day', t.closing_date)::date AS fecha,
  date_trunc('hour', t.closing_date) AS hora,
  COALESCE(
    NULLIF(term.location, ''),
    NULLIF((row_to_json(t)->>'branch_key'), ''),
    'Sin sucursal'
  ) AS sucursal_id,
  t.terminal_id,
  COALESCE(t.total_price, 0)::numeric(12,2) AS total,
  COALESCE(t.sub_total, 0)::numeric(12,2) AS sub_total,
  t.paid,
  t.voided,
  t.closing_date,
  COALESCE(
    NULLIF(t.daily_folio::text, ''),
    NULLIF(t.global_id::text, ''),
    (row_to_json(t)->>'ticket_number'),
    t.id::text
  ) AS ticket_ref
FROM public.ticket t
LEFT JOIN public.terminal term
  ON term.id = t.terminal_id
WHERE t.closing_date IS NOT NULL;

-- Ventas por hora agregadas desde tickets normalizados
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_hora AS
SELECT
  base.fecha,
  date_trunc('hour', base.hora) AS hora,
  base.sucursal_id,
  base.terminal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, date_trunc('hour', base.hora), base.sucursal_id, base.terminal_id;

-- Resumen diario por sucursal
CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_sucursal AS
SELECT
  base.fecha,
  base.sucursal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total,
  SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.sucursal_id;

-- Resumen diario por terminal
CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_terminal AS
SELECT
  base.fecha,
  base.terminal_id,
  base.sucursal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total,
  SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.terminal_id, base.sucursal_id;

-- Verificación
SELECT 'Vista creada: vw_dashboard_ticket_base' AS resultado
UNION ALL
SELECT 'Vista creada: vw_dashboard_ventas_hora'
UNION ALL
SELECT 'Vista creada: vw_dashboard_resumen_sucursal'
UNION ALL
SELECT 'Vista creada: vw_dashboard_resumen_terminal';
