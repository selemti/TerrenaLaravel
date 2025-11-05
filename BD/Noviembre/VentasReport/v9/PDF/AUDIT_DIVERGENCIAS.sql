-- AUDIT_DIVERGENCIAS.sql — Terrena × FloreantPOS (PG 9.5)
-- Objetivo: detectar y cuantificar diferencias entre las vistas implementadas
--           y los cálculos de referencia a partir de tablas base.
-- Uso: reemplaza {{START}} y {{END}} por fechas (YYYY-MM-DD) y ejecuta.

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

\echo '=== Parámetros ==='
\echo 'Rango: {{START}} — {{END}}'

-- 1) Bases de referencia
WITH base_ticket AS (
  SELECT * FROM public.vw_ticket_base
  WHERE folio_date BETWEEN '{{START}}'::date AND '{{END}}'::date
),
payments_norm AS (
  SELECT
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key,
    selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name) AS method,
    ROUND(SUM(CASE
      WHEN COALESCE(tx.voided, FALSE) = FALSE
       AND UPPER(tx.transaction_type) = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS amount
  FROM public.ticket t
  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
  WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
        BETWEEN '{{START}}'::date AND '{{END}}'::date
  GROUP BY 1,2,3
),
summary_ref AS (
  SELECT
    b.folio_date,
    b.branch_key,
    COUNT(DISTINCT b.ticket_id) AS tickets,
    ROUND(SUM(b.total_price),2) AS bruto,
    ROUND(SUM(b.total_discount),2) AS descuento,
    ROUND(SUM(b.total_price - b.total_discount),2) AS neto,
    ROUND(SUM(b.tip_amount),2) AS propina,
    ROUND(SUM(b.service_charges),2) AS cargo_servicio
  FROM base_ticket b
  GROUP BY 1,2
),
balance_ref AS (
  SELECT folio_date, branch_key, method AS payment, amount AS monto
  FROM payments_norm
),
menu_usage_ref AS (
  SELECT
    b.folio_date,
    b.branch_key,
    ti.item_name::text AS item_name,
    SUM(COALESCE(ti.item_quantity,0))::numeric(12,2) AS qty,
    (SUM(COALESCE(ti.total_price,0) - COALESCE(ti.discount,0)))::numeric(12,2) AS neto
  FROM base_ticket b
  JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id
  GROUP BY 1,2,3
)

-- 2) Comparación: Resumen
SELECT 'SUMMARY' AS section,
       r.folio_date, r.branch_key,
       r.tickets   AS ref_tickets,   COALESCE(v.tickets,0)   AS view_tickets,   (COALESCE(v.tickets,0) - r.tickets)     AS d_tickets,
       r.bruto     AS ref_bruto,     COALESCE(v.bruto,0)     AS view_bruto,     (COALESCE(v.bruto,0) - r.bruto)         AS d_bruto,
       r.descuento AS ref_descuento, COALESCE(v.descuento,0) AS view_descuento, (COALESCE(v.descuento,0) - r.descuento) AS d_descuento,
       r.neto      AS ref_neto,      COALESCE(v.neto,0)      AS view_neto,      (COALESCE(v.neto,0) - r.neto)          AS d_neto
FROM summary_ref r
LEFT JOIN public.vw_report_sales_summary v
  ON v.folio_date = r.folio_date AND v.branch_key = r.branch_key
WHERE ABS(COALESCE(v.neto,0) - r.neto) > 0.01
ORDER BY r.folio_date, r.branch_key;

-- 3) Comparación: Balance (sumas por día/sucursal)
WITH view_sum AS (
  SELECT folio_date, branch_key, ROUND(SUM(monto)::numeric,2) AS monto
  FROM public.vw_report_balance_detail
  WHERE folio_date BETWEEN '{{START}}'::date AND '{{END}}'::date
  GROUP BY 1,2
),
ref_sum AS (
  SELECT folio_date, branch_key, ROUND(SUM(monto)::numeric,2) AS monto
  FROM balance_ref
  GROUP BY 1,2
)
SELECT 'BALANCE' AS section,
       r.folio_date, r.branch_key,
       r.monto AS ref_total, COALESCE(v.monto,0) AS view_total,
       (COALESCE(v.monto,0) - r.monto) AS d_total
FROM ref_sum r
LEFT JOIN view_sum v ON v.folio_date=r.folio_date AND v.branch_key=r.branch_key
WHERE ABS(COALESCE(v.monto,0) - r.monto) > 0.01
ORDER BY r.folio_date, r.branch_key;

-- 4) Comparación: Mix por método (detalle de diferencias por método)
SELECT 'BALANCE_METHOD' AS section,
       r.folio_date, r.branch_key, r.payment,
       r.monto AS ref_monto, COALESCE(v.monto,0) AS view_monto,
       (COALESCE(v.monto,0) - r.monto) AS d_monto
FROM balance_ref r
LEFT JOIN public.vw_report_balance_detail v
  ON v.folio_date=r.folio_date AND v.branch_key=r.branch_key AND v.payment=r.payment
WHERE ABS(COALESCE(v.monto,0) - r.monto) > 0.01
ORDER BY r.folio_date, r.branch_key, r.payment;

-- 5) Comparación: Uso de menú (TOP 50 diferencias por item)
SELECT 'MENU_USAGE' AS section,
       r.folio_date, r.branch_key, r.item_name,
       r.neto AS ref_neto, COALESCE(v.neto,0) AS view_neto,
       (COALESCE(v.neto,0) - r.neto) AS d_neto
FROM menu_usage_ref r
LEFT JOIN public.vw_report_menu_usage v
  ON v.folio_date=r.folio_date AND v.branch_key=r.branch_key AND v.item_name=r.item_name
WHERE ABS(COALESCE(v.neto,0) - r.neto) > 0.01
ORDER BY ABS(COALESCE(v.neto,0) - r.neto) DESC
LIMIT 50;

-- 6) Causas comunes: REFUND/VOID_TRANS en rango
SELECT 'REFUNDS_IN_RANGE' AS section,
       COUNT(*) AS tx_count, ROUND(SUM(COALESCE(tx.amount,0))::numeric,2) AS amount
FROM public.transactions tx
JOIN public.ticket t ON t.id = tx.ticket_id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
      BETWEEN '{{START}}'::date AND '{{END}}'::date
  AND (UPPER(tx.payment_type) IN ('REFUND','VOID_TRANS'));

-- 7) Causas comunes: tickets anulados/pagados
SELECT 'TICKETS_FLAGS' AS section,
       SUM(CASE WHEN paid=TRUE AND voided=FALSE THEN 1 ELSE 0 END) AS valid,
       SUM(CASE WHEN voided=TRUE THEN 1 ELSE 0 END) AS voided
FROM public.ticket
WHERE COALESCE(folio_date, closing_date::date, create_date::date)
      BETWEEN '{{START}}'::date AND '{{END}}'::date;

-- 8) Timezone/fecha base: create_date vs folio_date
SELECT 'DATE_MISMATCH' AS section,
       COUNT(*) AS rows
FROM public.ticket t
WHERE (COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) <> t.create_date::date)
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)
      BETWEEN '{{START}}'::date AND '{{END}}'::date;

