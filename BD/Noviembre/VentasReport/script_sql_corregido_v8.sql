-- ============================================
-- SCRIPT SQL CORREGIDO (V8) PARA TU BASE DE DATOS REAL
-- PostgreSQL 9.5 - FloreantPOS  ·  Schemas: public, selemti
-- Autor: ChatGPT (GPT-5 Thinking)
-- ============================================

-- =========== PREPARACIÓN DE SESIÓN ===========
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- =====================================================
-- SECCIÓN 0 · LIMPIEZA (DROP de vistas que vamos a crear)
-- (NO es fatal si no existen; se ignoran con IF EXISTS)
-- =====================================================
DROP VIEW IF EXISTS
  vw_sales_daily_branch,
  vw_sales_daily_branch_range,
  vw_sales_by_terminal,
  vw_sales_mix_payment,
  vw_sales_by_hour,
  vw_top_items_today,
  vw_diag_neto_vs_cobros,
  vw_diag_discount_header_vs_lines,
  vw_diag_orphans_tx,
  vw_diag_orphans_tickets,
  vw_diag_pagos_egresos,
  vw_diag_high_discounts,
  vw_diag_folio_date_inconsistency,
  vw_diag_paid_but_no_payments,
  vw_diag_unnormalized_payments,
  vw_diag_service_charge_vs_paid,
  vw_diag_drawer_vs_cash_transactions,
  vw_sales_mix_payment_today,
  vw_daily_diagnostics_summary
;

-- =====================================================
-- SECCIÓN 1 · VISTAS CORE
-- =====================================================

-- 1.1 Resumen diario (usa función existente)
CREATE OR REPLACE VIEW vw_sales_daily_branch AS
SELECT * FROM public.get_daily_stats(CURRENT_DATE);

-- 1.2 Rango de días (nota: get_daily_stats(date) → castea a ::date)
CREATE OR REPLACE VIEW vw_sales_daily_branch_range AS
SELECT c.d::date AS folio_date, x.*
FROM generate_series(CURRENT_DATE - INTERVAL '365 days', CURRENT_DATE, INTERVAL '1 day') AS c(d)
CROSS JOIN LATERAL public.get_daily_stats(c.d::date) AS x;

-- 1.3 Ventas por terminal
CREATE OR REPLACE VIEW vw_sales_by_terminal AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  term.id        AS terminal_id,
  term.name      AS terminal_name,
  term.location  AS sucursal,
  COUNT(*)       AS tickets,
  ROUND(SUM(COALESCE(t.total_price,0))::numeric,2)                                     AS bruto,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2)                                  AS descuento,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)))::numeric,2)      AS neto
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid = TRUE AND t.voided = FALSE
GROUP BY 1,2,3,4,5;

-- 1.4 Mix de formas de pago (LEFT JOIN para conservar tickets válidos sin pago)
CREATE OR REPLACE VIEW vw_sales_mix_payment AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(
    tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
  ) AS normalized_payment,
  ROUND(SUM(
    CASE
      WHEN tx.voided = FALSE
       AND UPPER(tx.transaction_type) = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount,0) ELSE 0 END
  )::numeric, 2) AS total
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid = TRUE AND t.voided = FALSE
GROUP BY 1,2,3;

-- 1.5 Ventas por hora (usa create_date real)
CREATE OR REPLACE VIEW vw_sales_by_hour AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  EXTRACT(HOUR FROM (t.create_date AT TIME ZONE 'America/Mexico_City'))::int AS hour_local,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)))::numeric,2) AS neto
FROM public.ticket t
WHERE t.paid = TRUE AND t.voided = FALSE
GROUP BY 1,2,3;

-- 1.6 Top items del día (usa nombres reales en ticket_item)
CREATE OR REPLACE VIEW vw_top_items_today AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ti.item_id,
  ti.item_name,
  ROUND(SUM(COALESCE(ti.item_quantity,0))::numeric,2) AS qty,
  ROUND(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric,2) AS neto
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = CURRENT_DATE
  AND t.voided = FALSE
GROUP BY 1,2,3,4
ORDER BY neto DESC;

-- =====================================================
-- SECCIÓN 2 · DIAGNÓSTICOS CORE
-- =====================================================

-- 2.1 Neto vs cobros
CREATE OR REPLACE VIEW vw_diag_neto_vs_cobros AS
WITH tx AS (
  SELECT
    ticket_id,
    ROUND(SUM(
      CASE WHEN voided = FALSE
         AND UPPER(transaction_type)='CREDIT'
         AND payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(amount,0) ELSE 0 END
    )::numeric, 2) AS paid_sum
  FROM public.transactions
  GROUP BY ticket_id
),
base AS (
  SELECT
    t.id AS ticket_id,
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key,
    ROUND((COALESCE(t.total_price,0) - COALESCE(t.total_discount,0))::numeric, 2) AS net_ticket,
    COALESCE(tx.paid_sum,0) AS paid_sum,
    ROUND((COALESCE(tx.paid_sum,0) - (COALESCE(t.total_price,0) - COALESCE(t.total_discount,0)))::numeric, 2) AS diff
  FROM public.ticket t
  LEFT JOIN tx ON tx.ticket_id = t.id
  WHERE t.paid = TRUE AND t.voided = FALSE
)
SELECT
  *,
  'PAYMENT_VS_NET_MISMATCH'::text AS error_code,
  (CASE WHEN ABS(diff) > 1 THEN 'CRITICAL' ELSE 'WARN' END)::text AS severity
FROM base
WHERE ABS(diff) > 0.01;

-- 2.2 Header vs líneas (descuentos)
CREATE OR REPLACE VIEW vw_diag_discount_header_vs_lines AS
WITH line_disc AS (
  SELECT
    ti.ticket_id,
    ROUND(SUM(COALESCE(ti.discount,0))::numeric, 2) AS sum_line_disc
  FROM public.ticket_item ti
  GROUP BY ti.ticket_id
)
SELECT
  t.id AS ticket_id,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ROUND(COALESCE(t.total_discount,0)::numeric, 2) AS hdr_discount,
  COALESCE(ld.sum_line_disc,0) AS sum_line_disc,
  ROUND((COALESCE(ld.sum_line_disc,0) - COALESCE(t.total_discount,0))::numeric, 2) AS diff,
  'DISCOUNT_MISMATCH'::text AS error_code,
  'CRITICAL'::text       AS severity
FROM public.ticket t
LEFT JOIN line_disc ld ON ld.ticket_id = t.id
WHERE t.paid = TRUE AND t.voided = FALSE
  AND ABS(ROUND((COALESCE(ld.sum_line_disc,0) - COALESCE(t.total_discount,0))::numeric, 2)) > 0.01;

-- 2.3 Transacciones huérfanas
CREATE OR REPLACE VIEW vw_diag_orphans_tx AS
SELECT
  tx.id,
  tx.ticket_id,
  ROUND(COALESCE(tx.amount,0)::numeric,2) AS amount,
  'ORPHAN_TX'::text AS error_code,
  'CRITICAL'::text  AS severity
FROM public.transactions tx
LEFT JOIN public.ticket t ON t.id = tx.ticket_id
WHERE t.id IS NULL AND tx.voided = FALSE;

-- 2.4 Tickets pagados sin transacciones
CREATE OR REPLACE VIEW vw_diag_orphans_tickets AS
SELECT
  t.id AS ticket_id,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  'ORPHAN_TICKET'::text AS error_code,
  'CRITICAL'::text AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx
  ON tx.ticket_id = t.id
 AND tx.voided = FALSE
 AND UPPER(tx.transaction_type) = 'CREDIT'
WHERE t.paid = TRUE AND t.voided = FALSE
  AND tx.ticket_id IS NULL;

-- 2.5 Egresos (no ventas)
CREATE OR REPLACE VIEW vw_diag_pagos_egresos AS
SELECT
  terminal_id,
  ROUND(SUM(amount)::numeric, 2) AS egresos,
  'NON_SALES_CASHFLOW'::text AS error_code,
  'WARN'::text              AS severity
FROM public.transactions
WHERE payment_type IN ('REFUND','PAY_OUT','CASH_DROP') AND voided = FALSE
GROUP BY terminal_id;

-- 2.6 Descuentos altos (>30%)
CREATE OR REPLACE VIEW vw_diag_high_discounts AS
SELECT
  t.id AS ticket_id,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ROUND(COALESCE(t.total_discount,0)::numeric,2) AS total_discount,
  ROUND((COALESCE(t.total_discount,0) / NULLIF(t.total_price,0) * 100)::numeric,2) AS discount_percentage,
  'DISCOUNT_OVER_THRESHOLD'::text AS error_code,
  'WARN'::text AS severity
FROM public.ticket t
WHERE t.paid = TRUE AND t.voided = FALSE
  AND COALESCE(t.total_discount,0) >= COALESCE(t.total_price,0) * 0.30;

-- 2.7 folio_date inconsistente vs closing/create
CREATE OR REPLACE VIEW vw_diag_folio_date_inconsistency AS
SELECT
  t.id AS ticket_id,
  t.folio_date,
  t.create_date,
  t.closing_date,
  t.settled,
  'FOLIO_DATE_MISMATCH'::text AS error_code,
  'CRITICAL'::text AS severity
FROM public.ticket t
WHERE t.paid = TRUE AND t.voided = FALSE
  AND t.closing_date IS NOT NULL
  AND t.folio_date IS DISTINCT FROM t.closing_date::date
  AND t.folio_date IS DISTINCT FROM t.create_date::date;

-- 2.8 paid=TRUE sin cobros > 0
CREATE OR REPLACE VIEW vw_diag_paid_but_no_payments AS
SELECT
  t.id AS ticket_id,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ROUND((COALESCE(t.total_price,0) - COALESCE(t.total_discount,0))::numeric, 2) AS neto,
  'PAID_WITHOUT_TX'::text AS error_code,
  'CRITICAL'::text AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx
  ON tx.ticket_id = t.id
 AND tx.voided = FALSE
 AND UPPER(tx.transaction_type) = 'CREDIT'
WHERE t.paid = TRUE
  AND t.voided = FALSE
  AND tx.ticket_id IS NULL
  AND (COALESCE(t.total_price,0) - COALESCE(t.total_discount,0)) > 0.01;

-- 2.9 Pagos no normalizados
CREATE OR REPLACE VIEW vw_diag_unnormalized_payments AS
SELECT DISTINCT
  COALESCE(payment_type,'')::text        AS payment_type,
  COALESCE(transaction_type,'')::text    AS transaction_type,
  COALESCE(payment_sub_type,'')::text    AS payment_sub_type,
  COALESCE(custom_payment_name,'')::text AS custom_payment_name,
  'UNNORMALIZED_PAYMENT'::text           AS error_code,
  'WARN'::text                           AS severity
FROM public.transactions
WHERE voided = FALSE
  AND selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name) IS NULL;

-- 2.10 Service charge declarado vs cobrado
CREATE OR REPLACE VIEW vw_diag_service_charge_vs_paid AS
WITH svc_tx AS (
  SELECT
    ticket_id,
    ROUND(SUM(CASE
      WHEN selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name) = 'CARGO_SERVICIO'
       AND voided = FALSE
      THEN COALESCE(amount,0) ELSE 0 END)::numeric, 2) AS paid_svc
  FROM public.transactions
  GROUP BY ticket_id
)
SELECT
  t.id AS ticket_id,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  ROUND(COALESCE(t.service_charge,0)::numeric, 2) AS declared,
  ROUND(COALESCE(s.paid_svc,0)::numeric, 2)      AS paid,
  ROUND(ABS(COALESCE(s.paid_svc,0) - COALESCE(t.service_charge,0))::numeric, 2) AS diff,
  'SERVICE_CHARGE_MISMATCH'::text AS error_code,
  (CASE WHEN ABS(COALESCE(s.paid_svc,0) - COALESCE(t.service_charge,0)) > 1
        THEN 'CRITICAL' ELSE 'WARN' END)::text AS severity
FROM public.ticket t
LEFT JOIN svc_tx s ON s.ticket_id = t.id
WHERE ABS(COALESCE(s.paid_svc,0) - COALESCE(t.service_charge,0)) > 0.01;

-- =====================================================
-- SECCIÓN 3 · CAJÓN vs EFECTIVO · FUNCIÓN PARAMETRIZADA + WRAPPER
-- =====================================================

-- 3.1 Función parametrizada (p_date)
DROP FUNCTION IF EXISTS public.f_diag_drawer_vs_cash_transactions_on(date);
CREATE FUNCTION public.f_diag_drawer_vs_cash_transactions_on(p_date date)
RETURNS TABLE(
  terminal_id             integer,
  original_total_revenue  numeric(12,2),
  corrected_neto_tickets  numeric(12,2),
  adjustment              numeric(12,2),
  cash_in                 numeric(12,2),
  non_cash_in             numeric(12,2),
  expected_cash           numeric(12,2),
  diff                    numeric(12,2),
  error_code              text,
  severity                text
) LANGUAGE sql AS $$
WITH drawer AS (
  SELECT
    terminal_id,
    COALESCE(original_total_revenue,0)::numeric(12,2) AS original_total_revenue,
    COALESCE(corrected_neto_tickets,0)::numeric(12,2) AS corrected_neto_tickets,
    COALESCE(adjustment,0)::numeric(12,2)             AS adjustment
  FROM public.fn_correct_drawer_report(p_date)
),
tx AS (
  SELECT
    t.terminal_id,
    SUM(CASE
          WHEN tx.voided = FALSE
           AND UPPER(tx.transaction_type) = 'CREDIT'
           AND selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) = 'CASH'
          THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(12,2) AS cash_in,
    SUM(CASE
          WHEN tx.voided = FALSE
           AND UPPER(tx.transaction_type) = 'CREDIT'
           AND selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) IS DISTINCT FROM 'CASH'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(12,2) AS non_cash_in
  FROM public.transactions tx
  JOIN public.ticket t ON t.id = tx.ticket_id
  WHERE t.closing_date::date = p_date
  GROUP BY t.terminal_id
),
calc AS (
  SELECT
    d.terminal_id,
    d.original_total_revenue,
    d.corrected_neto_tickets,
    d.adjustment,
    COALESCE(x.cash_in,0)::numeric(12,2)     AS cash_in,
    COALESCE(x.non_cash_in,0)::numeric(12,2) AS non_cash_in,
    (d.corrected_neto_tickets - COALESCE(x.non_cash_in,0))::numeric(12,2) AS expected_cash
  FROM drawer d
  LEFT JOIN tx x ON x.terminal_id = d.terminal_id
)
SELECT
  terminal_id,
  original_total_revenue,
  corrected_neto_tickets,
  adjustment,
  cash_in,
  non_cash_in,
  expected_cash,
  ROUND((cash_in - expected_cash)::numeric, 2) AS diff,
  'DRAWER_CASH_MISMATCH'::text AS error_code,
  (CASE WHEN ABS(cash_in - expected_cash) > 1 THEN 'CRITICAL' ELSE 'WARN' END)::text AS severity
FROM calc
WHERE ABS(cash_in - expected_cash) > 0.01;
$$;

-- 3.2 Wrapper a CURRENT_DATE
CREATE OR REPLACE VIEW vw_diag_drawer_vs_cash_transactions AS
SELECT
  t.terminal_id::int                                   AS terminal_id,
  t.original_total_revenue::numeric(12,2)              AS original_total_revenue,
  t.corrected_neto_tickets::numeric(12,2)              AS corrected_neto_tickets,
  t.adjustment::numeric(12,2)                          AS adjustment,
  t.cash_in::numeric(12,2)                             AS cash_in,
  t.non_cash_in::numeric(12,2)                         AS non_cash_in,
  t.expected_cash::numeric(12,2)                       AS expected_cash,
  t.diff::numeric(12,2)                                AS diff,
  t.error_code::text                                   AS error_code,
  t.severity::text                                     AS severity
FROM public.f_diag_drawer_vs_cash_transactions_on(CURRENT_DATE) AS t;

-- =====================================================
-- SECCIÓN 4 · MÓDULO DESCUENTOS + EXCEPCIONES
-- =====================================================

-- 4.1 Resumen diario de descuentos
CREATE OR REPLACE VIEW vw_discounts_daily AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  term.location AS sucursal,
  term.name     AS terminal,
  COUNT(*) AS tickets_con_desc,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2) AS descuento_total,
  ROUND(AVG(COALESCE(t.total_discount,0))::numeric,2) AS descuento_prom_ticket
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid = TRUE AND t.voided = FALSE AND COALESCE(t.total_discount,0) > 0
GROUP BY 1,2,3,4;

-- 4.2 Detalle por línea
CREATE OR REPLACE VIEW vw_discounts_detail_line AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  term.location AS sucursal,
  term.name     AS terminal,
  t.id  AS ticket_id,
  ti.id AS ticket_item_id,
  ti.item_name,
  ROUND(COALESCE(ti.total_price,0)::numeric,2) AS line_total_bruto,
  ROUND(COALESCE(ti.discount,0)::numeric,2)    AS line_descuento,
  ROUND((COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric,2) AS line_neto,
  NULL::text AS discount_name
FROM public.ticket t
JOIN public.terminal term ON term.id=t.terminal_id
JOIN public.ticket_item ti ON ti.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE AND COALESCE(ti.discount,0)>0;

-- 4.3 Excepciones del día
CREATE OR REPLACE VIEW vw_sales_exceptions_today AS
WITH base AS (
  SELECT
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key,
    term.location AS sucursal,
    term.name     AS terminal,
    t.id AS ticket_id,
    ROUND(COALESCE(t.total_price,0)::numeric,2) AS total_bruto,
    ROUND(COALESCE(t.total_discount,0)::numeric,2) AS total_descuento,
    ROUND((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric,2) AS total_neto,
    t.voided,
    (COALESCE(t.total_discount,0) >= COALESCE(t.total_price,0)*0.30) AS descuento_mayor_30
  FROM public.ticket t
  JOIN public.terminal term ON term.id=t.terminal_id
  WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = CURRENT_DATE
)
SELECT
  b.*,
  CASE WHEN b.voided THEN 'VOID_TICKET'
       WHEN b.descuento_mayor_30 THEN 'HIGH_DISCOUNT'
       ELSE 'NORMAL' END AS exception_code,
  CASE WHEN b.voided THEN 'CRITICAL'
       WHEN b.descuento_mayor_30 THEN 'WARN'
       ELSE 'INFO' END AS severity
FROM base b
WHERE b.voided OR b.descuento_mayor_30;

-- =====================================================
-- SECCIÓN 5 · FUNCIONES WRAPPER “ON DATE” + VISTAS TODAY
-- =====================================================

-- 5.1 Mix de pago por fecha + wrapper hoy
DROP FUNCTION IF EXISTS public.f_sales_mix_payment_on(date);
CREATE FUNCTION public.f_sales_mix_payment_on(p_date date)
RETURNS TABLE(
  folio_date date,
  branch_key text,
  normalized_payment text,
  total numeric(12,2)
) LANGUAGE sql AS $$
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) AS normalized_payment,
  ROUND(SUM(CASE
    WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
     AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS total
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
GROUP BY 1,2,3;
$$;

CREATE OR REPLACE VIEW vw_sales_mix_payment_today AS
SELECT * FROM public.f_sales_mix_payment_on(CURRENT_DATE);

-- 5.2 Resumen operativo (parametrizado + wrapper hoy)
DROP FUNCTION IF EXISTS public.f_daily_diagnostics_summary_on(date);
CREATE FUNCTION public.f_daily_diagnostics_summary_on(p_date date)
RETURNS TABLE(source_view text, severity text, rows bigint)
LANGUAGE sql AS $$
SELECT 'vw_diag_neto_vs_cobros'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_neto_vs_cobros
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_discount_header_vs_lines'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_discount_header_vs_lines
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_paid_but_no_payments'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_paid_but_no_payments
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_unnormalized_payments'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_unnormalized_payments
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_service_charge_vs_paid'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_service_charge_vs_paid
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_drawer_vs_cash_transactions'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_drawer_vs_cash_transactions
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tickets'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_orphans_tickets
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tx'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_orphans_tx
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_high_discounts'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_high_discounts
WHERE folio_date = p_date
GROUP BY 1,2;
$$;

CREATE OR REPLACE VIEW vw_daily_diagnostics_summary AS
SELECT * FROM public.f_daily_diagnostics_summary_on(CURRENT_DATE);

-- =====================================================
-- SECCIÓN 6 · KPIs
-- =====================================================
CREATE OR REPLACE VIEW vw_sales_kpis AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  COUNT(DISTINCT t.id) AS total_tickets,
  ROUND((SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)) / NULLIF(COUNT(DISTINCT t.id),0))::numeric,2) AS avg_ticket,
  ROUND((SUM(COALESCE(ti.item_quantity,0)) / NULLIF(COUNT(DISTINCT t.id),0))::numeric,2)   AS items_per_ticket,
  ROUND(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric,2)            AS total_neto,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2)                                      AS total_descuentos,
  ROUND(((SUM(COALESCE(t.total_discount,0)) / NULLIF(SUM(COALESCE(t.total_price,0)),0)) * 100)::numeric,2) AS descuento_percentage
FROM public.ticket t
LEFT JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2;

-- =====================================================
-- SECCIÓN 7 · MATERIALIZED VIEWS (opcional, 9.5 no soporta IF NOT EXISTS)
-- Ejecuta si quieres acelerar reportes frecuentes.
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS mv_sales_by_terminal;
DROP MATERIALIZED VIEW IF EXISTS mv_sales_mix_payment;
DROP MATERIALIZED VIEW IF EXISTS mv_sales_by_hour;

CREATE MATERIALIZED VIEW mv_sales_by_terminal AS
SELECT * FROM vw_sales_by_terminal
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

CREATE MATERIALIZED VIEW mv_sales_mix_payment AS
SELECT * FROM vw_sales_mix_payment
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

CREATE MATERIALIZED VIEW mv_sales_by_hour AS
SELECT * FROM vw_sales_by_hour
WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days';

-- (Opcional) Crear índices *fuera* de transacción:
-- CREATE INDEX CONCURRENTLY idx_mv_sales_by_terminal_folio ON mv_sales_by_terminal (folio_date, branch_key, terminal_id);
-- CREATE INDEX CONCURRENTLY idx_mv_sales_mix_payment     ON mv_sales_mix_payment (folio_date, branch_key, normalized_payment);
-- CREATE INDEX CONCURRENTLY idx_mv_sales_by_hour_folio   ON mv_sales_by_hour (folio_date, branch_key);

-- =====================================================
-- SECCIÓN 8 · QUERIES DE VERIFICACIÓN RÁPIDA
-- =====================================================
-- Listado de vistas creadas
SELECT schemaname, viewname
FROM pg_views
WHERE schemaname='public' AND viewname LIKE 'vw_%'
ORDER BY 2;

-- Firmas de funciones clave
SELECT proname AS function_name, pronargs AS num_arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('public','selemti')
  AND proname IN ('get_daily_stats','fn_daily_reconciliation','fn_reconciliation_detail','fn_correct_drawer_report','fn_normalizar_forma_pago')
ORDER BY 1;

-- Conteo de tablas principales
SELECT 'ticket' AS table_name, COUNT(*) AS total_records,
       COUNT(*) FILTER (WHERE paid=true AND voided=false) AS valid_records
FROM ticket
UNION ALL
SELECT 'transactions', COUNT(*),
       COUNT(*) FILTER (WHERE voided=false)
FROM transactions
UNION ALL
SELECT 'ticket_item', COUNT(*), COUNT(*)
FROM ticket_item;

-- FIN DEL SCRIPT (V8)
