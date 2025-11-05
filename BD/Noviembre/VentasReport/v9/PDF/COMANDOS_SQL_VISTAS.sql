-- SQL rápido para crear vistas faltantes (PG 9.5 compatible)
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- Uso de menú (fix ROUND sobre ::numeric)
DROP VIEW IF EXISTS public.vw_report_menu_usage CASCADE;
CREATE VIEW public.vw_report_menu_usage AS
SELECT
  b.folio_date,
  b.branch_key,
  ti.item_name::text AS item_name,
  SUM(COALESCE(ti.item_quantity, 0))::numeric(12,2) AS qty,
  ROUND(SUM(COALESCE(ti.total_price,0) - COALESCE(ti.discount,0))::numeric, 2) AS neto
FROM public.vw_ticket_base b
JOIN public.ticket_item ti ON ti.ticket_id = b.ticket_id
GROUP BY 1,2,3;

-- Excepciones (autosuficiente, sin vw_diag_*)
DROP VIEW IF EXISTS public.vw_report_sales_exceptions CASCADE;
CREATE VIEW public.vw_report_sales_exceptions AS
WITH base AS (
  SELECT b.folio_date, b.branch_key, b.ticket_id,
         (b.total_price - b.total_discount)::numeric(12,2) AS neto
  FROM public.vw_ticket_base b
),
paid AS (
  SELECT t.id AS ticket_id,
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
  FROM public.vw_ticket_base b
)
SELECT b.folio_date, b.branch_key, 'PAYMENT_VS_NET_MISMATCH'::text AS error_code, 'WARN'::text AS severity,
       b.ticket_id, ROUND((b.neto - COALESCE(p.paid_amount,0))::numeric,2) AS diff
FROM base b LEFT JOIN paid p ON p.ticket_id = b.ticket_id
WHERE ABS((b.neto - COALESCE(p.paid_amount,0))) > 0.01
UNION ALL
SELECT b.folio_date, b.branch_key, 'DISCOUNT_OVER_THRESHOLD', 'INFO', b.ticket_id, td.total_discount
FROM base b JOIN tot_disc td ON td.ticket_id = b.ticket_id
WHERE td.total_discount > 100
   OR ((b.neto + td.total_discount) > 0 AND td.total_discount / NULLIF((b.neto + td.total_discount),0) > 0.20)
UNION ALL
SELECT b.folio_date, b.branch_key, 'PAID_WITHOUT_TX', 'WARN', b.ticket_id, b.neto
FROM base b LEFT JOIN paid p ON p.ticket_id = b.ticket_id
WHERE COALESCE(p.paid_amount,0) = 0 AND b.neto > 0;

-- Verificación
SELECT to_regclass('public.vw_report_menu_usage') AS v_usage,
       to_regclass('public.vw_report_sales_exceptions') AS v_exc;

