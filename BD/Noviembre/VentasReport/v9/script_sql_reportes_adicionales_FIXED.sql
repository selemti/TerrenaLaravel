-- ================================================================
-- script_sql_reportes_adicionales.sql
-- Terrena · Reportes adicionales equivalentes a JasperReports
-- Target: PostgreSQL 9.5+
-- Schemas: public (POS), selemti (ERP utilidades)
-- ================================================================

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- Helper: tickets válidos con folio_date normalizada
DROP VIEW IF EXISTS vw_ticket_base CASCADE;
CREATE VIEW vw_ticket_base AS
SELECT
  t.id              AS ticket_id,
  t.terminal_id,
  t.branch_key,
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  COALESCE(t.total_price,0)::numeric(12,2)    AS total_price,
  GREATEST(
    0,
    LEAST(
      COALESCE(
        t.total_discount,
        (
          SELECT SUM(
            COALESCE(
              NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
              COALESCE(ti.discount, 0)
            )
          )
          FROM public.ticket_item ti
          WHERE ti.ticket_id = t.id
        ),
        0
      ),
      COALESCE(t.total_price, 0)
    )
  )::numeric(12,2) AS total_discount,
  COALESCE((
    SELECT SUM(g.amount)
    FROM public.gratuity g
    WHERE g.ticket_id = t.id AND COALESCE(g.refunded,false)=FALSE AND COALESCE(g.paid,true)=TRUE
  ),0)::numeric(12,2)                          AS tip_amount,
  COALESCE(t.service_charge,0)::numeric(12,2)  AS service_charges
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE;

-- 1) Sales detail
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
  COALESCE(
    NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
    COALESCE(ti.discount, 0)
  )::numeric(12,2) AS line_discount,
  (
    COALESCE(ti.total_price,0)
    - COALESCE(
        NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
        COALESCE(ti.discount, 0)
      )
  )::numeric(12,2) AS line_neto
FROM vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id;

-- 2) Sales summary
DROP VIEW IF EXISTS vw_report_sales_summary CASCADE;
CREATE VIEW vw_report_sales_summary AS
WITH valid AS (
  SELECT
    b.folio_date,
    COALESCE(UPPER(TRIM(b.branch_key)), 'SIN_SUCURSAL') AS branch_key,
    COUNT(DISTINCT b.ticket_id) AS tickets,
    SUM(b.total_price)::numeric(14,2) AS bruto,
    SUM(b.total_discount)::numeric(14,2) AS descuento,
    SUM(b.tip_amount)::numeric(14,2) AS propina,
    SUM(b.service_charges)::numeric(14,2) AS cargo_servicio
  FROM vw_ticket_base b
  GROUP BY 1,2
),
ticket_all AS (
  SELECT
    t.id,
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    COALESCE(UPPER(TRIM(t.branch_key)), 'SIN_SUCURSAL') AS branch_key,
    COALESCE(t.total_price,0)::numeric(14,2) AS total_price,
    GREATEST(
      0,
      LEAST(
        COALESCE(
          t.total_discount,
          (
            SELECT SUM(
              COALESCE(
                NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
                COALESCE(ti.discount, 0)
              )
            )
            FROM public.ticket_item ti
            WHERE ti.ticket_id = t.id
          ),
          0
        ),
        COALESCE(t.total_price, 0)
      )
    )::numeric(14,2) AS total_discount,
    COALESCE(t.paid, FALSE) AS paid,
    COALESCE(t.voided, FALSE) AS voided
  FROM public.ticket t
),
payments AS (
  SELECT
    ta.folio_date,
    ta.branch_key,
    SUM(
      CASE
        WHEN ta.voided = FALSE
         AND COALESCE(tx.voided, FALSE) = FALSE
         AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')
         AND UPPER(COALESCE(tx.payment_type, '')) NOT IN ('REFUND','VOID_TRANS','REFUND_CARD')
        THEN COALESCE(tx.amount,0)
        ELSE 0
      END
    )::numeric(14,2) AS gross_payments,
    SUM(
      CASE
        WHEN ta.voided = FALSE
         AND COALESCE(tx.voided, FALSE) = FALSE
         AND UPPER(COALESCE(tx.transaction_type, '')) IN ('CREDIT','DEBIT')
         AND UPPER(COALESCE(tx.payment_type, '')) IN ('REFUND','VOID_TRANS','REFUND_CARD')
        THEN COALESCE(tx.amount,0)
        ELSE 0
      END
    )::numeric(14,2) AS refund_amount
  FROM ticket_all ta
  LEFT JOIN public.transactions tx ON tx.ticket_id = ta.id
  GROUP BY 1,2
),
voids AS (
  SELECT
    ta.folio_date,
    ta.branch_key,
    SUM(ta.total_price - ta.total_discount)::numeric(14,2) AS void_amount
  FROM ticket_all ta
  WHERE ta.voided = TRUE
  GROUP BY 1,2
),
keys AS (
  SELECT folio_date, branch_key FROM valid
  UNION
  SELECT folio_date, branch_key FROM payments
  UNION
  SELECT folio_date, branch_key FROM voids
)
SELECT
  k.folio_date,
  k.branch_key,
  COALESCE(v.tickets, 0) AS tickets,
  ROUND(COALESCE(v.bruto, 0) + COALESCE(vo.void_amount, 0), 2) AS bruto,
  ROUND(COALESCE(v.descuento, 0), 2) AS descuento,
  ROUND(COALESCE(p.refund_amount, 0) + COALESCE(vo.void_amount, 0), 2) AS anulaciones,
  ROUND(
    COALESCE(v.bruto, 0) + COALESCE(vo.void_amount, 0)
    - COALESCE(v.descuento, 0)
    - (COALESCE(p.refund_amount, 0) + COALESCE(vo.void_amount, 0)),
    2
  ) AS neto,
  ROUND(COALESCE(p.gross_payments, 0) - COALESCE(p.refund_amount, 0), 2) AS pagos_netos,
  ROUND(COALESCE(v.propina, 0), 2) AS propina,
  ROUND(COALESCE(v.cargo_servicio, 0), 2) AS cargo_servicio
FROM keys k
LEFT JOIN valid v
  ON v.folio_date = k.folio_date AND v.branch_key = k.branch_key
LEFT JOIN payments p
  ON p.folio_date = k.folio_date AND p.branch_key = k.branch_key
LEFT JOIN voids vo
  ON vo.folio_date = k.folio_date AND vo.branch_key = k.branch_key;

-- 3) Balance detail (pagos normalizados)
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

-- 4) Exceptions (usa diagnósticos existentes)
DROP VIEW IF EXISTS vw_report_sales_exceptions CASCADE;
CREATE VIEW vw_report_sales_exceptions AS
WITH base AS (
  SELECT
    b.folio_date,
    b.branch_key,
    b.ticket_id,
    (b.total_price - b.total_discount)::numeric(12,2) AS neto
  FROM vw_ticket_base b
),
paid AS (
  SELECT
    t.id AS ticket_id,
    ROUND(SUM(CASE
      WHEN COALESCE(tx.voided, FALSE)=FALSE
       AND UPPER(tx.transaction_type)='CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS paid_amount
  FROM public.ticket t
  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
  GROUP BY t.id
),
tot_disc AS (
  SELECT b.ticket_id, (b.total_discount)::numeric(12,2) AS total_discount
  FROM vw_ticket_base b
)
-- 1) Neto vs cobros (mismatch)
SELECT
  b.folio_date,
  b.branch_key,
  'PAYMENT_VS_NET_MISMATCH'::text AS error_code,
  'WARN'::text AS severity,
  b.ticket_id,
  ROUND((b.neto - COALESCE(p.paid_amount,0))::numeric,2) AS diff
FROM base b
LEFT JOIN paid p ON p.ticket_id = b.ticket_id
WHERE ABS((b.neto - COALESCE(p.paid_amount,0))) > 0.01

UNION ALL

-- 2) Descuentos altos (umbral absoluto o porcentual)
SELECT
  b.folio_date,
  b.branch_key,
  'DISCOUNT_OVER_THRESHOLD'::text AS error_code,
  'INFO'::text AS severity,
  b.ticket_id,
  td.total_discount AS diff
FROM base b
JOIN tot_disc td ON td.ticket_id = b.ticket_id
WHERE td.total_discount > 100
   OR ((b.neto + td.total_discount) > 0 AND td.total_discount / NULLIF((b.neto + td.total_discount),0) > 0.20)

UNION ALL

-- 3) Pagado sin transacciones
SELECT
  b.folio_date,
  b.branch_key,
  'PAID_WITHOUT_TX'::text AS error_code,
  'WARN'::text AS severity,
  b.ticket_id,
  b.neto AS diff
FROM base b
LEFT JOIN paid p ON p.ticket_id = b.ticket_id
WHERE COALESCE(p.paid_amount,0) = 0 AND b.neto > 0;

-- 5) Menu usage
DROP VIEW IF EXISTS vw_report_menu_usage CASCADE;
CREATE VIEW vw_report_menu_usage AS
SELECT
  b.folio_date,
  b.branch_key,
  ti.item_name::text AS item_name,
  SUM(COALESCE(ti.item_quantity,0))::numeric(12,2) AS qty,
  ROUND(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric,2) AS neto
FROM vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id
GROUP BY 1,2,3;

-- 6) Journal
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
  COALESCE(
    NULLIF(to_jsonb(ti)->>'discount_amount', '')::numeric,
    COALESCE(ti.discount, 0)
  )::numeric(12,2) AS line_discount
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
