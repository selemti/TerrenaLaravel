
-- ================================================================
-- script_sql_reportes_adicionales.sql
-- Terrena · Reportes adicionales equivalentes a JasperReports
-- Target: PostgreSQL 9.5+
-- Schemas: public (POS), selemti (ERP utilidades)
-- Autor: ChatGPT (GPT-5 Thinking)
-- ================================================================

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- ===================================================================
-- Notas base usadas por todos los reportes
--  - Ticket válido: paid=TRUE AND voided=FALSE
--  - folio_date inmutable: COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
--  - Normalización de pagos: selemti.fn_normalizar_forma_pago(...)
--  - Campos frecuentes:
--      ticket(id, terminal_id, branch_key, folio_date, closing_date, create_date,
--             total_price, total_discount, tip_amount, service_charges, paid, voided)
--      transactions(id, ticket_id, amount, voided, transaction_type, payment_type,
--                   payment_sub_type, custom_payment_name, transaction_time)
--      ticket_item(id, ticket_id, item_name, item_quantity, unit_price, total_price, discount_amount)
--      ticket_item_modifier, ticket_item_modifier_relation (para modificadores)
--      menu_item(id, name, price, group_id, tax_id, ...), menu_modifier, menu_modifier_group
-- ===================================================================

-- ---------------------------------------------------------------
-- Helper: vista base de tickets válidos con folio_date normalizada
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_ticket_base CASCADE;
CREATE VIEW vw_ticket_base AS
SELECT
  t.id              AS ticket_id,
  t.terminal_id,
  t.branch_key,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  COALESCE(t.total_price,0)::numeric(12,2)    AS total_price,
  COALESCE(t.total_discount,0)::numeric(12,2) AS total_discount,
  COALESCE(t.tip_amount,0)::numeric(12,2)     AS tip_amount,
  COALESCE(t.service_charges,0)::numeric(12,2) AS service_charges
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE;

-- ---------------------------------------------------------------
-- 1) Sales Report (detalle por ticket / item)  [Jasper: sales_report_*]
--    Filtros: fecha, branch, terminal
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_sales_detail CASCADE;
CREATE VIEW vw_report_sales_detail AS
SELECT
  b.folio_date,
  b.branch_key,
  b.terminal_id,
  b.ticket_id,
  ti.id              AS ticket_item_id,
  ti.item_name::text AS item_name,
  COALESCE(ti.item_quantity,0)::numeric(12,2) AS qty,
  COALESCE(ti.unit_price, COALESCE(ti.total_price,0)/NULLIF(ti.item_quantity,0))::numeric(12,2) AS unit_price,
  COALESCE(ti.total_price,0)::numeric(12,2)   AS line_total,
  COALESCE(ti.discount_amount,0)::numeric(12,2) AS line_discount,
  (COALESCE(ti.total_price,0)-COALESCE(ti.discount_amount,0))::numeric(12,2) AS line_neto
FROM vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id;

-- ---------------------------------------------------------------
-- 2) Sales Summary (resumen por día / sucursal) [Jasper: sales_summary_report]
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_sales_summary CASCADE;
CREATE VIEW vw_report_sales_summary AS
SELECT
  b.folio_date,
  b.branch_key,
  COUNT(DISTINCT b.ticket_id)                                AS tickets,
  ROUND(SUM(b.total_price),2)                                AS bruto,
  ROUND(SUM(b.total_discount),2)                             AS descuento,
  ROUND(SUM(b.total_price - b.total_discount),2)             AS neto,
  ROUND(SUM(b.tip_amount),2)                                 AS propina,
  ROUND(SUM(b.service_charges),2)                            AS cargo_servicio
FROM vw_ticket_base b
GROUP BY 1,2;

-- ---------------------------------------------------------------
-- 3) Sales Summary - Balance Detail [Jasper: sales_summary_balance_detail]
--    Neto vs cobros por forma de pago normalizada
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_balance_detail CASCADE;
CREATE VIEW vw_report_balance_detail AS
WITH paid AS (
  SELECT
    t.id AS ticket_id,
    selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) AS pay_norm,
    ROUND(SUM(CASE
      WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric,2) AS paid_amount
  FROM public.ticket t
  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
  GROUP BY 1,2
)
SELECT
  b.folio_date,
  b.branch_key,
  p.pay_norm                         AS payment,
  ROUND(SUM(COALESCE(p.paid_amount,0)),2) AS monto
FROM vw_ticket_base b
LEFT JOIN paid p ON p.ticket_id = b.ticket_id
GROUP BY 1,2,3
ORDER BY 1,2,4 DESC;

-- ---------------------------------------------------------------
-- 4) Sales Summary - Exceptions [Jasper: sales_summary_exception]
--    Usa diagnósticos existentes y produce un set consolidado
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_sales_exceptions CASCADE;
CREATE VIEW vw_report_sales_exceptions AS
SELECT folio_date, branch_key, 'PAYMENT_VS_NET_MISMATCH' AS error_code, severity, ticket_id, diff::numeric(12,2) AS diff
FROM vw_diag_neto_vs_cobros
UNION ALL
SELECT folio_date, branch_key, 'DISCOUNT_OVER_THRESHOLD', severity, ticket_id, total_discount
FROM vw_diag_high_discounts
UNION ALL
SELECT folio_date, branch_key, 'PAID_WITHOUT_TX', severity, ticket_id, neto
FROM vw_diag_paid_but_no_payments;

-- ---------------------------------------------------------------
-- 5) Menu Usage Report [Jasper: menu_usage_report]
--    Conteo de uso por ítem y modificadores
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_menu_usage CASCADE;
CREATE VIEW vw_report_menu_usage AS
SELECT
  b.folio_date,
  b.branch_key,
  ti.item_name::text AS item_name,
  SUM(COALESCE(ti.item_quantity,0))::numeric(12,2) AS qty,
  ROUND(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount_amount,0)),2) AS neto
FROM vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id
GROUP BY 1,2,3;

-- ---------------------------------------------------------------
-- 6) Journal Report [Jasper: journal_report]
--    Libro por ticket con líneas y pagos
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS vw_report_journal_lines CASCADE;
CREATE VIEW vw_report_journal_lines AS
SELECT
  b.folio_date,
  b.branch_key,
  b.ticket_id,
  ti.id AS ticket_item_id,
  ti.item_name::text AS item_name,
  COALESCE(ti.item_quantity,0)::numeric(12,2) AS qty,
  COALESCE(ti.total_price,0)::numeric(12,2) AS line_total,
  COALESCE(ti.discount_amount,0)::numeric(12,2) AS line_discount
FROM vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id;

DROP VIEW IF EXISTS vw_report_journal_payments CASCADE;
CREATE VIEW vw_report_journal_payments AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  t.id AS ticket_id,
  selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) AS pay_norm,
  ROUND(SUM(CASE
    WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric,2) AS paid_amount
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
GROUP BY 1,2,3,4;

-- ================================================================
-- FIN DEL SCRIPT
-- ================================================================
