-- ============================================================================
-- ERP REPORTS V9 - Terrena (FloreantPOS + Laravel + PostgreSQL 9.5+)
-- Fecha: 2025-11-04
-- Autor: ChatGPT (GPT-5 Thinking)
--
-- NOTAS CLAVE
-- - NO inventa esquemas. Usa tablas reales del POS:
--   public.ticket, public.ticket_item, public.transactions,
--   public.ticket_item_modifier, public.ticket_item_modifier_relation.
-- - search_path: public, selemti
-- - Zona horaria MX para consistencia de “hoy”
-- - Todas las vistas devuelven dinero con ROUND(...,2)
-- ============================================================================

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- ============================================================================
-- 1) MIX DE PAGO (función parametrizada + wrapper a hoy)
-- ============================================================================
DROP FUNCTION IF EXISTS public.f_sales_mix_payment_on(date) CASCADE;

CREATE FUNCTION public.f_sales_mix_payment_on(p_date date)
RETURNS TABLE(
  folio_date date,
  branch_key text,
  normalized_payment text,
  total numeric(12,2)
) LANGUAGE sql STABLE AS
$$
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(
    tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
  ) AS normalized_payment,
  ROUND(SUM(CASE
      WHEN tx.voided = FALSE
       AND UPPER(tx.transaction_type) = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS total
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid = TRUE AND t.voided = FALSE
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
GROUP BY 1,2,3;
$$;

DROP VIEW IF EXISTS public.vw_sales_mix_payment_today CASCADE;
CREATE VIEW public.vw_sales_mix_payment_today AS
SELECT * FROM public.f_sales_mix_payment_on(CURRENT_DATE);

-- ============================================================================
-- 2) CAJÓN vs EFECTIVO (función parametrizada + wrapper a hoy)
-- ============================================================================
DROP FUNCTION IF EXISTS public.f_diag_drawer_vs_cash_transactions_on(date) CASCADE;

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
) LANGUAGE sql STABLE AS
$$
WITH drawer AS (
  SELECT
    terminal_id,
    COALESCE(original_total_revenue, 0)::numeric(12,2)  AS original_total_revenue,
    COALESCE(corrected_neto_tickets, 0)::numeric(12,2)  AS corrected_neto_tickets,
    COALESCE(adjustment, 0)::numeric(12,2)              AS adjustment
  FROM public.fn_correct_drawer_report(p_date)
),
tx AS (
  SELECT
    t.terminal_id,
    SUM(CASE
          WHEN tx.voided = FALSE
           AND UPPER(tx.transaction_type) = 'CREDIT'
           AND selemti.fn_normalizar_forma_pago(
                 tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
               ) = 'CASH'
          THEN COALESCE(tx.amount,0) ELSE 0 END
    )::numeric(12,2) AS cash_in,
    SUM(CASE
          WHEN tx.voided = FALSE
           AND UPPER(tx.transaction_type) = 'CREDIT'
           AND selemti.fn_normalizar_forma_pago(
                 tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
               ) IS DISTINCT FROM 'CASH'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN COALESCE(tx.amount,0) ELSE 0 END
    )::numeric(12,2) AS non_cash_in
  FROM public.transactions tx
  JOIN public.ticket t ON t.id = tx.ticket_id
  WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
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

DROP VIEW IF EXISTS public.vw_diag_drawer_vs_cash_transactions CASCADE;
CREATE VIEW public.vw_diag_drawer_vs_cash_transactions AS
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

-- ============================================================================
-- 3) RESUMEN DIARIO DE DIAGNÓSTICOS (función parametrizada + wrapper a hoy)
-- ============================================================================
DROP FUNCTION IF EXISTS public.f_daily_diagnostics_summary_on(date) CASCADE;

CREATE FUNCTION public.f_daily_diagnostics_summary_on(p_date date)
RETURNS TABLE(source_view text, severity text, rows bigint)
LANGUAGE sql STABLE AS
$$
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

DROP VIEW IF EXISTS public.vw_daily_diagnostics_summary CASCADE;
CREATE VIEW public.vw_daily_diagnostics_summary AS
SELECT * FROM public.f_daily_diagnostics_summary_on(CURRENT_DATE);

-- ============================================================================
-- 4) ÍTEMS + MODIFICADORES (detallado por ticket_item)
--     Tablas confirmadas:
--       ticket_item (id, ticket_id, item_name, item_quantity)
--       ticket_item_modifier_relation (ticket_item_id, modifier_id)
--       ticket_item_modifier (id, modifier_name, total_price)
-- ============================================================================
DROP FUNCTION IF EXISTS public.f_item_mods_on(date) CASCADE;

CREATE FUNCTION public.f_item_mods_on(p_date date)
RETURNS TABLE(
  folio_date date,
  branch_key text,
  terminal_id integer,
  ticket_id integer,
  ticket_item_id integer,
  item_name text,
  modifier_name text,
  qty_item numeric(12,2),
  mods_count bigint,
  mods_total_amount numeric(12,2)
) LANGUAGE sql STABLE AS
$$
WITH ti_base AS (
  SELECT
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key,
    t.terminal_id,
    t.id         AS ticket_id,
    ti.id        AS ticket_item_id,
    ti.item_name AS item_name,
    COALESCE(ti.item_quantity,0)::numeric(12,2) AS qty_item
  FROM public.ticket t
  JOIN public.ticket_item ti ON ti.ticket_id = t.id
  WHERE t.paid = TRUE
    AND t.voided = FALSE
    AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
),
rel_mods AS (
  SELECT
    b.folio_date, b.branch_key, b.terminal_id, b.ticket_id, b.ticket_item_id,
    b.item_name,
    tim.modifier_name::text AS modifier_name,
    b.qty_item,
    1::bigint               AS mods_count,
    COALESCE(tim.total_price,0)::numeric(12,2) AS mods_total_amount
  FROM ti_base b
  JOIN public.ticket_item_modifier_relation r ON r.ticket_item_id = b.ticket_item_id
  JOIN public.ticket_item_modifier tim       ON tim.id = r.modifier_id
),
direct_mods AS (
  SELECT
    b.folio_date, b.branch_key, b.terminal_id, b.ticket_id, b.ticket_item_id,
    b.item_name,
    tim.modifier_name::text AS modifier_name,
    b.qty_item,
    1::bigint               AS mods_count,
    COALESCE(tim.total_price,0)::numeric(12,2) AS mods_total_amount
  FROM ti_base b
  JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = b.ticket_item_id
  WHERE NOT EXISTS (
    SELECT 1 FROM public.ticket_item_modifier_relation r WHERE r.ticket_item_id = b.ticket_item_id
  )
),
all_rows AS (
  SELECT * FROM rel_mods
  UNION ALL
  SELECT * FROM direct_mods
)
SELECT
  folio_date, branch_key, terminal_id, ticket_id, ticket_item_id,
  item_name, modifier_name,
  MAX(qty_item)                             AS qty_item,
  COUNT(*)::bigint                          AS mods_count,
  ROUND(SUM(mods_total_amount)::numeric,2)  AS mods_total_amount
FROM all_rows
GROUP BY 1,2,3,4,5,6,7
ORDER BY item_name, modifier_name;
$$;

-- Wrapper: hoy (detalle)
DROP VIEW IF EXISTS public.vw_item_mods_today CASCADE;
CREATE VIEW public.vw_item_mods_today AS
SELECT * FROM public.f_item_mods_on(CURRENT_DATE);

-- Resumen diario por sucursal / ítem / modificador
DROP VIEW IF EXISTS public.vw_item_mods_daily_summary CASCADE;
CREATE VIEW public.vw_item_mods_daily_summary AS
SELECT
  folio_date,
  branch_key,
  item_name,
  modifier_name,
  SUM(qty_item)                        AS qty_items,
  SUM(mods_count)::bigint             AS times_selected,
  ROUND(SUM(mods_total_amount), 2)    AS total_mods_amount
FROM public.f_item_mods_on(CURRENT_DATE)
GROUP BY 1,2,3,4
ORDER BY branch_key, item_name, modifier_name;

-- Top modificadores por ítem (hoy)
DROP VIEW IF EXISTS public.vw_item_mods_by_item_today CASCADE;
CREATE VIEW public.vw_item_mods_by_item_today AS
SELECT
  item_name,
  modifier_name,
  SUM(times_selected)::bigint          AS times_selected,
  ROUND(SUM(total_mods_amount), 2)     AS total_mods_amount
FROM public.vw_item_mods_daily_summary
GROUP BY 1,2
ORDER BY item_name, times_selected DESC, modifier_name;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
