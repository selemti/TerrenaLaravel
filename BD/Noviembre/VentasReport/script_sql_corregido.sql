-- ============================================
-- SCRIPT SQL CORREGIDO PARA TU BASE DE DATOS
-- Versión adaptada al esquema real de tu BD
-- PostgreSQL 9.5 - FloreantPOS
-- ============================================

-- IMPORTANTE: Ejecutar primero para configurar el entorno
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- ============================================
-- SECCIÓN 1: VISTAS CORE CORREGIDAS
-- ============================================

-- 1.1 Vista wrapper para estadísticas diarias
-- Ya existe la función get_daily_stats, solo creamos el wrapper
CREATE OR REPLACE VIEW vw_sales_daily_branch AS
SELECT * FROM public.get_daily_stats(CURRENT_DATE);

-- 1.2 Vista de ventas diarias por rango
CREATE OR REPLACE VIEW vw_sales_daily_branch_range AS
SELECT c.d AS folio_date, x.*
FROM generate_series(CURRENT_DATE - INTERVAL '365 days', CURRENT_DATE, INTERVAL '1 day') AS c(d)
CROSS JOIN LATERAL public.get_daily_stats(c.d) AS x;

-- 1.3 Vista de ventas por terminal (CORREGIDA)
CREATE OR REPLACE VIEW vw_sales_by_terminal AS
SELECT
  t.folio_date,
  t.branch_key,
  term.id        AS terminal_id,
  term.name      AS terminal_name,
  term.location  AS sucursal,
  COUNT(*)       AS tickets,
  ROUND(CAST(SUM(COALESCE(t.total_price,0)) AS numeric),2)                   AS bruto,
  ROUND(CAST(SUM(COALESCE(t.total_discount,0)) AS numeric),2)                AS descuento,
  ROUND(CAST(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) AS numeric),2) AS neto
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3,4,5;

-- 1.4 Vista mix de formas de pago (CORREGIDA)
CREATE OR REPLACE VIEW vw_sales_mix_payment AS
SELECT
  t.folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(
    tx.payment_type, 
    tx.transaction_type, 
    tx.payment_sub_type, 
    tx.custom_payment_name
  ) AS normalized_payment,
  ROUND(CAST(SUM(
    CASE WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(tx.amount,0) ELSE 0 END
  ) AS numeric),2) AS total
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;

-- 1.5 Vista de ventas por hora (CORREGIDA - usa create_date)
CREATE OR REPLACE VIEW vw_sales_by_hour AS
SELECT
  t.folio_date,
  t.branch_key,
  EXTRACT(HOUR FROM (t.create_date AT TIME ZONE 'America/Mexico_City'))::int AS hour_local,
  ROUND(CAST(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) AS numeric),2) AS neto
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;

-- 1.6 Vista top items del día (CORREGIDA - usa nombres reales de columnas)
CREATE OR REPLACE VIEW vw_top_items_today AS
SELECT
  t.folio_date,
  t.branch_key,
  ti.item_id,
  ti.item_name,
  ROUND(CAST(SUM(COALESCE(ti.item_quantity,0)) AS numeric),2) AS qty,
  ROUND(CAST(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount,0)) AS numeric),2) AS neto
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.folio_date = CURRENT_DATE
  -- ticket_item no tiene campo voided, usamos el del ticket
  AND t.voided = FALSE
GROUP BY 1,2,3,4
ORDER BY neto DESC;

-- ============================================
-- SECCIÓN 2: DIAGNÓSTICOS CORE CORREGIDOS
-- ============================================

-- 2.1 Diagnóstico: Neto vs Cobros
CREATE OR REPLACE VIEW vw_diag_neto_vs_cobros AS
WITH tx AS (
  SELECT ticket_id, ROUND(CAST(SUM(
    CASE WHEN voided=FALSE AND UPPER(transaction_type)='CREDIT'
         AND payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(amount,0) ELSE 0 END
  ) AS numeric),2) AS paid_sum
  FROM public.transactions GROUP BY ticket_id
),
base AS (
  SELECT t.id AS ticket_id, t.folio_date, t.branch_key,
         ROUND(CAST(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0) AS numeric),2) AS net_ticket,
         COALESCE(tx.paid_sum,0) AS paid_sum,
         ROUND(CAST(COALESCE(tx.paid_sum,0)-(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) AS numeric),2) AS diff
  FROM public.ticket t
  LEFT JOIN tx ON tx.ticket_id=t.id
  WHERE t.paid=TRUE AND t.voided=FALSE
)
SELECT *,
  'PAYMENT_VS_NET_MISMATCH' AS error_code,
  CASE WHEN ABS(diff) > 1 THEN 'CRITICAL' ELSE 'WARN' END AS severity
FROM base
WHERE ABS(diff) > 0.01;

-- 2.2 Diagnóstico: Descuento header vs líneas (CORREGIDO)
CREATE OR REPLACE VIEW vw_diag_discount_header_vs_lines AS
WITH line_disc AS (
  SELECT ti.ticket_id, 
         ROUND(CAST(SUM(COALESCE(ti.discount,0)) AS numeric),2) AS sum_line_disc
  FROM public.ticket_item ti 
  GROUP BY ti.ticket_id
)
SELECT
  t.id AS ticket_id, 
  t.folio_date, 
  t.branch_key,
  ROUND(CAST(COALESCE(t.total_discount,0) AS numeric),2) AS hdr_discount,
  COALESCE(ld.sum_line_disc,0) AS sum_line_disc,
  ROUND(CAST(COALESCE(ld.sum_line_disc,0)-COALESCE(t.total_discount,0) AS numeric),2) AS diff,
  'DISCOUNT_MISMATCH' AS error_code,
  'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN line_disc ld ON ld.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE
  AND ABS(ROUND(CAST(COALESCE(ld.sum_line_disc,0)-COALESCE(t.total_discount,0) AS numeric),2))>0.01;

-- 2.3 Transacciones huérfanas
CREATE OR REPLACE VIEW vw_diag_orphans_tx AS
SELECT tx.id, 
       tx.ticket_id, 
       ROUND(CAST(tx.amount AS numeric),2) AS amount, 
       'ORPHAN_TX' AS error_code, 
       'CRITICAL' AS severity
FROM public.transactions tx
LEFT JOIN public.ticket t ON t.id = tx.ticket_id
WHERE t.id IS NULL AND tx.voided=FALSE;

-- 2.4 Tickets pagados sin transacciones
CREATE OR REPLACE VIEW vw_diag_orphans_tickets AS
SELECT t.id AS ticket_id, 
       t.folio_date, 
       t.branch_key, 
       'ORPHAN_TICKET' AS error_code, 
       'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id=t.id AND tx.voided=FALSE
WHERE t.paid=TRUE AND t.voided=FALSE AND tx.ticket_id IS NULL;

-- 2.5 Pagos de egresos
CREATE OR REPLACE VIEW vw_diag_pagos_egresos AS
SELECT terminal_id, 
       ROUND(CAST(SUM(amount) AS numeric),2) AS egresos,
       'NON_SALES_CASHFLOW' AS error_code, 
       'WARN' AS severity
FROM public.transactions
WHERE payment_type IN ('REFUND','PAY_OUT','CASH_DROP') AND voided=FALSE
GROUP BY terminal_id;

-- ============================================
-- SECCIÓN 3: MÓDULO DE DESCUENTOS
-- ============================================

-- 3.1 Resumen diario de descuentos
CREATE OR REPLACE VIEW vw_discounts_daily AS
SELECT t.folio_date, 
       t.branch_key, 
       term.location AS sucursal, 
       term.name AS terminal,
       COUNT(*) AS tickets_con_desc,
       ROUND(CAST(SUM(COALESCE(t.total_discount,0)) AS numeric),2) AS descuento_total,
       ROUND(CAST(AVG(COALESCE(t.total_discount,0)) AS numeric),2) AS descuento_prom_ticket
FROM public.ticket t
JOIN public.terminal term ON term.id=t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE AND COALESCE(t.total_discount,0) > 0
GROUP BY 1,2,3,4;

-- 3.2 Detalle de descuentos por línea (CORREGIDO)
CREATE OR REPLACE VIEW vw_discounts_detail_line AS
SELECT t.folio_date, 
       t.branch_key, 
       term.location AS sucursal, 
       term.name AS terminal,
       t.id AS ticket_id, 
       ti.id AS ticket_item_id, 
       ti.item_name,
       ROUND(CAST(COALESCE(ti.total_price,0) AS numeric),2) AS line_total_bruto,
       ROUND(CAST(COALESCE(ti.discount,0) AS numeric),2) AS line_descuento,
       ROUND(CAST(COALESCE(ti.total_price,0)-COALESCE(ti.discount,0) AS numeric),2) AS line_neto,
       -- ticket_item no tiene discount_name, buscar en ticket_item_discount si existe
       NULL AS discount_name  
FROM public.ticket t
JOIN public.terminal term ON term.id=t.terminal_id
JOIN public.ticket_item ti ON ti.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE AND COALESCE(ti.discount,0)>0;

-- 3.3 Excepciones del día
CREATE OR REPLACE VIEW vw_sales_exceptions_today AS
WITH base AS (
  SELECT t.folio_date, 
         t.branch_key, 
         term.location AS sucursal, 
         term.name AS terminal,
         t.id AS ticket_id,
         ROUND(CAST(COALESCE(t.total_price,0) AS numeric),2) AS total_bruto,
         ROUND(CAST(COALESCE(t.total_discount,0) AS numeric),2) AS total_descuento,
         ROUND(CAST(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0) AS numeric),2) AS total_neto,
         t.voided,
         (COALESCE(t.total_discount,0) >= COALESCE(t.total_price,0)*0.30) AS descuento_mayor_30
  FROM public.ticket t
  JOIN public.terminal term ON term.id=t.terminal_id
  WHERE t.folio_date = CURRENT_DATE
)
SELECT b.*,
       CASE WHEN b.voided THEN 'VOID_TICKET'
            WHEN b.descuento_mayor_30 THEN 'HIGH_DISCOUNT'
            ELSE 'NORMAL' END AS exception_code,
       CASE WHEN b.voided THEN 'CRITICAL'
            WHEN b.descuento_mayor_30 THEN 'WARN'
            ELSE 'INFO' END AS severity
FROM base b
WHERE b.voided OR b.descuento_mayor_30;

-- ============================================
-- SECCIÓN 4: DIAGNÓSTICOS ADICIONALES
-- ============================================

-- 4.1 Descuentos altos (>30%)
CREATE OR REPLACE VIEW vw_diag_high_discounts AS
SELECT t.id AS ticket_id, 
       t.folio_date, 
       t.branch_key,
       ROUND(CAST(COALESCE(t.total_discount,0) AS numeric),2) AS total_discount,
       ROUND(CAST((COALESCE(t.total_discount,0) / NULLIF(t.total_price,0)) * 100 AS numeric),2) AS discount_percentage,
       'DISCOUNT_OVER_THRESHOLD' AS error_code, 
       'WARN' AS severity
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
  AND COALESCE(t.total_discount,0) >= COALESCE(t.total_price,0)*0.30;

-- 4.2 Diagnóstico de inconsistencia en folio_date vs closing_date
CREATE OR REPLACE VIEW vw_diag_folio_date_inconsistency AS
SELECT t.id, 
       t.folio_date, 
       t.create_date,
       t.closing_date,
       t.settled,
       'FOLIO_DATE_MISMATCH' AS error_code, 
       'CRITICAL' AS severity
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
  AND t.closing_date IS NOT NULL
  AND t.folio_date <> t.closing_date::date;

-- 4.3 Tickets pagados sin transacciones con monto > 0
CREATE OR REPLACE VIEW vw_diag_paid_but_no_payments AS
SELECT t.id AS ticket_id, 
       t.folio_date, 
       t.branch_key,
       ROUND(CAST(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0) AS numeric),2) AS neto,
       'PAID_WITHOUT_TX' AS error_code, 
       'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id=t.id 
  AND tx.voided=FALSE 
  AND UPPER(tx.transaction_type)='CREDIT'
WHERE t.paid=TRUE 
  AND t.voided=FALSE
  AND tx.ticket_id IS NULL
  AND (COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))>0.01;

-- 4.4 Pagos no normalizados
CREATE OR REPLACE VIEW vw_diag_unnormalized_payments AS
SELECT DISTINCT 
       payment_type, 
       transaction_type, 
       payment_sub_type, 
       custom_payment_name,
       'UNNORMALIZED_PAYMENT' AS error_code, 
       'WARN' AS severity
FROM public.transactions
WHERE selemti.fn_normalizar_forma_pago(
  payment_type, 
  transaction_type, 
  payment_sub_type, 
  custom_payment_name
) IS NULL
AND voided=FALSE;

-- 4.5 Reconciliación de cajón (usando función existente)
CREATE OR REPLACE VIEW vw_diag_drawer_vs_cash_transactions AS
WITH drawer AS (
  SELECT * FROM public.fn_correct_drawer_report(CURRENT_DATE)
),
cash_tx AS (
  SELECT terminal_id, 
         ROUND(CAST(SUM(amount) AS numeric),2) AS cash_in
  FROM public.transactions
  WHERE UPPER(payment_type)='CASH' 
    AND voided=FALSE
    AND UPPER(transaction_type)='CREDIT'
    AND transaction_time::date = CURRENT_DATE
  GROUP BY terminal_id
)
SELECT d.terminal_id, 
       d.corrected_neto_tickets AS expected_cash, 
       COALESCE(c.cash_in,0) AS cash_in,
       ROUND(CAST(COALESCE(c.cash_in,0)-COALESCE(d.corrected_neto_tickets,0) AS numeric),2) AS diff,
       'DRAWER_CASH_MISMATCH' AS error_code, 
       'CRITICAL' AS severity
FROM drawer d
LEFT JOIN cash_tx c ON c.terminal_id=d.terminal_id
WHERE ABS(COALESCE(c.cash_in,0)-COALESCE(d.corrected_neto_tickets,0)) > 0.01;

-- 4.6 Service charge vs pagado (CORREGIDO)
CREATE OR REPLACE VIEW vw_diag_service_charge_vs_paid AS
WITH svc_tx AS (
  SELECT ticket_id, 
         ROUND(CAST(SUM(CASE
           WHEN selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)='CARGO_SERVICIO'
                AND voided=FALSE
           THEN COALESCE(amount,0) ELSE 0 END) AS numeric),2) AS paid_svc
  FROM public.transactions 
  GROUP BY ticket_id
)
SELECT t.id AS ticket_id, 
       t.folio_date,
       COALESCE(t.service_charge,0) AS declared, 
       COALESCE(s.paid_svc,0) AS paid,
       ROUND(CAST(ABS(COALESCE(t.service_charge,0)-COALESCE(s.paid_svc,0)) AS numeric),2) AS diff,
       'SERVICE_CHARGE_MISMATCH' AS error_code, 
       'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN svc_tx s ON s.ticket_id = t.id
WHERE ABS(COALESCE(t.service_charge,0)-COALESCE(s.paid_svc,0)) > 0.01;

-- ============================================
-- SECCIÓN 5: MATERIALIZED VIEWS
-- ============================================

-- Nota: Las materialized views mejoran el performance
-- Ejecutar REFRESH MATERIALIZED VIEW CONCURRENTLY diariamente

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_sales_by_terminal AS
SELECT * FROM vw_sales_by_terminal
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_sales_mix_payment AS
SELECT * FROM vw_sales_mix_payment
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_sales_by_hour AS
SELECT * FROM vw_sales_by_hour
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

-- Crear índices para las materialized views (ejecutar con autocommit ON)
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mv_sales_by_terminal_folio
--   ON mv_sales_by_terminal (folio_date, branch_key, terminal_id);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mv_sales_mix_payment
--   ON mv_sales_mix_payment (folio_date, branch_key, normalized_payment);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mv_sales_by_hour_folio
--   ON mv_sales_by_hour (folio_date, branch_key);

-- ============================================
-- SECCIÓN 6: KPIs
-- ============================================

CREATE OR REPLACE VIEW vw_sales_kpis AS
SELECT
  t.folio_date,
  t.branch_key,
  COUNT(DISTINCT t.id) AS total_tickets,
  ROUND(CAST(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) / NULLIF(COUNT(DISTINCT t.id),0) AS numeric),2) AS avg_ticket,
  ROUND(CAST(SUM(COALESCE(ti.item_quantity,0)) / NULLIF(COUNT(DISTINCT t.id),0) AS numeric),2) AS items_per_ticket,
  ROUND(CAST(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) AS numeric),2) AS total_neto,
  ROUND(CAST(SUM(COALESCE(t.total_discount,0)) AS numeric),2) AS total_descuentos,
  ROUND(CAST((SUM(COALESCE(t.total_discount,0)) / NULLIF(SUM(COALESCE(t.total_price,0)),0)) * 100 AS numeric),2) AS descuento_percentage
FROM public.ticket t
LEFT JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2;

-- ============================================
-- SECCIÓN 7: VISTAS DE AUDITORÍA
-- ============================================

-- Vista resumen de diagnósticos del día
CREATE OR REPLACE VIEW vw_daily_diagnostics_summary AS
WITH all_diags AS (
  SELECT 'PAYMENT_VS_NET' AS diagnostic_type, COUNT(*) AS issues, MAX(severity) AS max_severity
  FROM vw_diag_neto_vs_cobros
  WHERE folio_date = CURRENT_DATE
  UNION ALL
  SELECT 'DISCOUNT_HEADER_VS_LINES', COUNT(*), MAX(severity)
  FROM vw_diag_discount_header_vs_lines
  WHERE folio_date = CURRENT_DATE
  UNION ALL
  SELECT 'ORPHAN_TX', COUNT(*), 'CRITICAL'
  FROM vw_diag_orphans_tx
  UNION ALL
  SELECT 'ORPHAN_TICKETS', COUNT(*), MAX(severity)
  FROM vw_diag_orphans_tickets
  WHERE folio_date = CURRENT_DATE
  UNION ALL
  SELECT 'HIGH_DISCOUNTS', COUNT(*), MAX(severity)
  FROM vw_diag_high_discounts
  WHERE folio_date = CURRENT_DATE
)
SELECT * FROM all_diags WHERE issues > 0
ORDER BY 
  CASE max_severity 
    WHEN 'CRITICAL' THEN 1 
    WHEN 'WARN' THEN 2 
    ELSE 3 
  END,
  issues DESC;

-- ============================================
-- SECCIÓN 8: QUERIES DE VERIFICACIÓN
-- ============================================

-- Verificar que todas las vistas se crearon correctamente
SELECT 
  schemaname,
  viewname,
  CASE 
    WHEN viewname LIKE 'mv_%' THEN 'MATERIALIZED VIEW'
    ELSE 'VIEW'
  END as view_type
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname LIKE 'vw_%'
ORDER BY viewname;

-- Verificar funciones existentes
SELECT 
  proname AS function_name,
  pronargs AS num_arguments
FROM pg_proc 
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'get_daily_stats',
    'fn_daily_reconciliation',
    'fn_reconciliation_detail',
    'fn_correct_drawer_report',
    'fn_normalizar_forma_pago'
  );

-- Contar registros en tablas principales
SELECT 
  'ticket' as table_name, COUNT(*) as total_records,
  COUNT(*) FILTER (WHERE paid=true AND voided=false) as valid_records
FROM ticket
UNION ALL
SELECT 
  'transactions', COUNT(*),
  COUNT(*) FILTER (WHERE voided=false)
FROM transactions
UNION ALL
SELECT 
  'ticket_item', COUNT(*), COUNT(*)
FROM ticket_item;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- NOTAS IMPORTANTES:
-- 1. Este script está adaptado a la estructura real de tu BD
-- 2. Se corrigieron los nombres de columnas incorrectos
-- 3. Se ajustaron los tipos de datos (double precision a numeric)
-- 4. Se removieron referencias a columnas inexistentes
-- 5. Los índices CONCURRENTLY deben ejecutarse con autocommit ON
-- 6. Recuerda hacer REFRESH de las materialized views diariamente
-- 7. Verifica que el schema selemti tenga la función fn_normalizar_forma_pago
