-- script_sql_corregido_v8.sql
-- Compat: PostgreSQL 9.5 | Schemas: public, selemti
-- Recomendado: SET TZ + search_path en sesión que ejecute este script
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

------------------------------------------------------------
-- CORE: Wrappers a funciones existentes
------------------------------------------------------------

-- 3.1 Daily (función existente)
CREATE OR REPLACE VIEW vw_sales_daily_branch AS
SELECT * FROM public.get_daily_stats(CURRENT_DATE);

-- 3.2 Rango multi-día (ajuste PG 9.5: castear a date)
CREATE OR REPLACE VIEW vw_sales_daily_branch_range AS
SELECT c.d::date AS folio_date, x.*
FROM generate_series(CURRENT_DATE - INTERVAL '365 days', CURRENT_DATE, INTERVAL '1 day') AS c(d)
CROSS JOIN LATERAL public.get_daily_stats(c.d::date) AS x;

------------------------------------------------------------
-- CORE: Vistas de ventas
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_sales_by_terminal AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  term.id        AS terminal_id,
  term.name      AS terminal_name,
  term.location  AS sucursal,
  COUNT(*)       AS tickets,
  ROUND(SUM(COALESCE(t.total_price,0))::numeric,2)                        AS bruto,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2)                     AS descuento,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric),2) AS neto
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3,4,5;

-- Por hora (usar create_date en tu BD)
CREATE OR REPLACE VIEW vw_sales_by_hour AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  EXTRACT(HOUR FROM (t.create_date AT TIME ZONE 'America/Mexico_City'))::int AS hour_local,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric),2) AS neto
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;

-- Top ítems (sin depender de item_quantity)
CREATE OR REPLACE VIEW vw_top_items_today AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ti.item_id,
  ti.item_name,
  COUNT(*) AS lines,
  ROUND(SUM((COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric),2) AS neto
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = CURRENT_DATE
GROUP BY 1,2,3,4
ORDER BY neto DESC;

------------------------------------------------------------
-- DIAGNÓSTICOS CORE
------------------------------------------------------------

-- Neto vs Cobros
CREATE OR REPLACE VIEW vw_diag_neto_vs_cobros AS
WITH tx AS (
  SELECT
    ticket_id,
    ROUND(SUM(
      CASE
        WHEN voided = FALSE
         AND UPPER(transaction_type) = 'CREDIT'
         AND payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN COALESCE(amount, 0)
        ELSE 0
      END
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
    ROUND((
      COALESCE(tx.paid_sum,0) - (COALESCE(t.total_price,0) - COALESCE(t.total_discount,0))
    )::numeric, 2) AS diff
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

-- Descuento header vs líneas
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

-- Egresos no-venta
CREATE OR REPLACE VIEW vw_diag_pagos_egresos AS
SELECT
  terminal_id,
  ROUND(SUM(amount)::numeric, 2) AS egresos,
  'NON_SALES_CASHFLOW'::text AS error_code,
  'WARN'::text AS severity
FROM public.transactions
WHERE payment_type IN ('REFUND','PAY_OUT','CASH_DROP')
  AND voided = FALSE
GROUP BY terminal_id;

-- Paid sin cobros
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

-- FOLIO vs closing/create
CREATE OR REPLACE VIEW vw_diag_folio_date_inconsistency AS
SELECT
  t.id AS ticket_id,
  t.folio_date,
  t.closing_date::date AS closed_date,
  t.create_date::date  AS created_date,
  'FOLIO_DATE_MISMATCH'::text AS error_code,
  'CRITICAL'::text AS severity
FROM public.ticket t
WHERE t.paid = TRUE
  AND t.voided = FALSE
  AND (t.folio_date IS DISTINCT FROM t.closing_date::date)
  AND (t.folio_date IS DISTINCT FROM t.create_date::date);

-- Normalización de pagos
CREATE OR REPLACE VIEW vw_diag_unnormalized_payments AS
SELECT
  DISTINCT
  COALESCE(payment_type,'')::text        AS payment_type,
  COALESCE(transaction_type,'')::text    AS transaction_type,
  COALESCE(payment_sub_type,'')::text    AS payment_sub_type,
  COALESCE(custom_payment_name,'')::text AS custom_payment_name,
  'UNNORMALIZED_PAYMENT'::text           AS error_code,
  'WARN'::text                           AS severity
FROM public.transactions
WHERE voided = FALSE
  AND selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name) IS NULL;

-- Service charge vs pagado
CREATE OR REPLACE VIEW vw_diag_service_charge_vs_paid AS
WITH svc_tx AS (
  SELECT
    ticket_id,
    SUM(CASE
          WHEN selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name) = 'CARGO_SERVICIO'
           AND voided = FALSE
          THEN COALESCE(amount,0) ELSE 0
        END) AS paid_svc
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

------------------------------------------------------------
-- DESCUENTOS y EXCEPCIONES
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_discounts_daily AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key, term.location AS sucursal, term.name AS terminal,
  COUNT(*) AS tickets_con_desc,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2) AS descuento_total,
  ROUND(AVG(COALESCE(t.total_discount,0))::numeric,2) AS descuento_prom_ticket
FROM public.ticket t
JOIN public.terminal term ON term.id=t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3,4;

CREATE OR REPLACE VIEW vw_discounts_detail_line AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key, term.location AS sucursal, term.name AS terminal,
  t.id AS ticket_id, ti.id AS ticket_item_id, ti.item_name,
  ROUND(COALESCE(ti.total_price,0)::numeric,2) AS line_total_bruto,
  ROUND(COALESCE(ti.discount,0)::numeric,2)    AS line_descuento,
  ROUND((COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric,2) AS line_neto
FROM public.ticket t
JOIN public.terminal term ON term.id=t.terminal_id
JOIN public.ticket_item ti ON ti.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE AND COALESCE(ti.discount,0)>0;

CREATE OR REPLACE VIEW vw_sales_exceptions_today AS
WITH base AS (
  SELECT
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key, term.location AS sucursal, term.name AS terminal,
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
SELECT b.*,
       CASE WHEN b.voided THEN 'VOID_TICKET'
            WHEN b.descuento_mayor_30 THEN 'HIGH_DISCOUNT'
            ELSE 'NORMAL' END::text AS exception_code,
       CASE WHEN b.voided THEN 'CRITICAL'
            WHEN b.descuento_mayor_30 THEN 'WARN'
            ELSE 'INFO' END::text AS severity
FROM base b
WHERE b.voided OR b.descuento_mayor_30;

------------------------------------------------------------
-- FUNCIONES PARAMETRIZADAS  (fecha)
------------------------------------------------------------

-- Mix de pago por fecha
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
      THEN COALESCE(tx.amount,0)
      ELSE 0 END)::numeric, 2) AS total
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
GROUP BY 1,2,3;
$$;

-- Drawer vs efectivo (por fecha)
DROP FUNCTION IF EXISTS public.f_diag_drawer_vs_cash_transactions_on(date);
CREATE FUNCTION public.f_diag_drawer_vs_cash_transactions_on(p_date date)
RETURNS TABLE(
  terminal_id               integer,
  original_total_revenue    numeric(12,2),
  corrected_neto_tickets    numeric(12,2),
  adjustment                numeric(12,2),
  cash_in                   numeric(12,2),
  non_cash_in               numeric(12,2),
  expected_cash             numeric(12,2),
  diff                      numeric(12,2),
  error_code                text,
  severity                  text
) LANGUAGE sql AS $$
WITH drawer AS (
  SELECT
    terminal_id,
    COALESCE(original_total_revenue, 0)::numeric(12,2) AS original_total_revenue,
    COALESCE(corrected_neto_tickets, 0)::numeric(12,2) AS corrected_neto_tickets,
    COALESCE(adjustment, 0)::numeric(12,2)             AS adjustment
  FROM public.fn_correct_drawer_report(p_date)
),
tx AS (
  SELECT
    t.terminal_id,
    SUM(
      CASE
        WHEN tx.voided = FALSE
         AND UPPER(tx.transaction_type) = 'CREDIT'
         AND selemti.fn_normalizar_forma_pago(
              tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
            ) = 'CASH'
        THEN COALESCE(tx.amount,0)
        ELSE 0
      END
    )::numeric(12,2) AS cash_in,
    SUM(
      CASE
        WHEN tx.voided = FALSE
         AND UPPER(tx.transaction_type) = 'CREDIT'
         AND selemti.fn_normalizar_forma_pago(
               tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
             ) IS DISTINCT FROM 'CASH'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN COALESCE(tx.amount,0)
        ELSE 0
      END
    )::numeric(12,2) AS non_cash_in
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
  terminal_id, original_total_revenue, corrected_neto_tickets, adjustment,
  cash_in, non_cash_in, expected_cash,
  ROUND((cash_in - expected_cash)::numeric, 2) AS diff,
  'DRAWER_CASH_MISMATCH'::text AS error_code,
  (CASE WHEN ABS(cash_in - expected_cash) > 1 THEN 'CRITICAL' ELSE 'WARN' END)::text AS severity
FROM calc
WHERE ABS(cash_in - expected_cash) > 0.01;
$$;

-- Resumen de diagnósticos por fecha
DROP FUNCTION IF EXISTS public.f_daily_diagnostics_summary_on(date);
CREATE FUNCTION public.f_daily_diagnostics_summary_on(p_date date)
RETURNS TABLE(source_view text, severity text, rows bigint)
LANGUAGE sql AS $$
SELECT 'vw_diag_neto_vs_cobros'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_neto_vs_cobros
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_discount_header_vs_lines'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_discount_header_vs_lines
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_paid_but_no_payments'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_paid_but_no_payments
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_unnormalized_payments'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_unnormalized_payments
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_service_charge_vs_paid'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_service_charge_vs_paid
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_drawer_vs_cash_transactions'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_drawer_vs_cash_transactions
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tickets'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_orphans_tickets
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tx'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_orphans_tx
GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_high_discounts'::text,
       COALESCE(severity,'INFO')::text,
       COUNT(*)::bigint
FROM vw_diag_high_discounts
WHERE folio_date = p_date
GROUP BY 1,2;
$$;

------------------------------------------------------------
-- WRAPPERS “hoy”
------------------------------------------------------------

CREATE OR REPLACE VIEW vw_sales_mix_payment_today AS
SELECT * FROM public.f_sales_mix_payment_on(CURRENT_DATE);

CREATE OR REPLACE VIEW vw_diag_drawer_vs_cash_transactions AS
SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on(CURRENT_DATE);

CREATE OR REPLACE VIEW vw_daily_diagnostics_summary AS
SELECT * FROM public.f_daily_diagnostics_summary_on(CURRENT_DATE);

------------------------------------------------------------
-- GOBERNANZA: TRIGGERS / CDC (COMENTADO)
------------------------------------------------------------

-- A1) Trigger de protección de folio_date (habilitar solo si puedes escribir)
/*
CREATE OR REPLACE FUNCTION prevent_folio_date_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.settled_at IS NOT NULL AND NEW.folio_date <> OLD.folio_date THEN
    RAISE EXCEPTION 'folio_date es inmutable tras cierre (settled_at)';
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trg_protect_folio_date
--   BEFORE UPDATE ON public.ticket
--   FOR EACH ROW EXECUTE FUNCTION prevent_folio_date_change();
*/

-- A2) CDC ejemplo (tabla + triggers) — AJUSTAR a tus políticas y habilitar cuando decidas
/*
CREATE SCHEMA IF NOT EXISTS audit;
CREATE TABLE IF NOT EXISTS audit.ticket_changes(
  id bigserial primary key,
  changed_at timestamp without time zone default now(),
  user_name text,
  table_name text,
  ticket_id bigint,
  field_name text,
  old_value text,
  new_value text
);
*/