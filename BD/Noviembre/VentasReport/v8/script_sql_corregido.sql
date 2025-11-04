
-- ============================================================================
-- Terrena · Reportes de Ventas / Auditoría / Modificadores (PG 9.5+)
-- Consolidado seguro para re-ejecución (DROP/CREATE idempotente)
-- Zona horaria y search_path
-- ============================================================================
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- --------------------------------------------------------------------------
-- 0) Utilidades/Reglas (no destructivas)
-- --------------------------------------------------------------------------
-- Nota: Se asume que existe selemti.fn_normalizar_forma_pago(...)
--       y public.fn_correct_drawer_report(date) (ya las tienes).

-- --------------------------------------------------------------------------
-- 1) Funciones de diagnóstico parametrizadas por fecha
-- --------------------------------------------------------------------------
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
)
LANGUAGE sql STABLE AS
$$
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
    SUM(CASE WHEN tx.voided = FALSE
              AND UPPER(tx.transaction_type)='CREDIT'
              AND selemti.fn_normalizar_forma_pago(
                    tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
                  ) = 'CASH'
             THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric(12,2) AS cash_in,
    SUM(CASE WHEN tx.voided = FALSE
              AND UPPER(tx.transaction_type)='CREDIT'
              AND selemti.fn_normalizar_forma_pago(
                    tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
                  ) IS DISTINCT FROM 'CASH'
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

DROP FUNCTION IF EXISTS public.f_daily_diagnostics_summary_on(date);
CREATE FUNCTION public.f_daily_diagnostics_summary_on(p_date date)
RETURNS TABLE(source_view text, severity text, rows bigint)
LANGUAGE sql STABLE AS
$$
SELECT 'vw_diag_neto_vs_cobros'::text, COALESCE(severity,'INFO')::text, COUNT(*)::bigint
FROM vw_diag_neto_vs_cobros
WHERE folio_date = p_date GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_discount_header_vs_lines', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_discount_header_vs_lines
WHERE folio_date = p_date GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_paid_but_no_payments', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_paid_but_no_payments
WHERE folio_date = p_date GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_unnormalized_payments', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_unnormalized_payments GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_service_charge_vs_paid', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_service_charge_vs_paid GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_drawer_vs_cash_transactions', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_drawer_vs_cash_transactions GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tickets', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_orphans_tickets GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_orphans_tx', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_orphans_tx GROUP BY 1,2
UNION ALL
SELECT 'vw_diag_high_discounts', COALESCE(severity,'INFO'), COUNT(*)::bigint
FROM vw_diag_high_discounts
WHERE folio_date = p_date GROUP BY 1,2;
$$;

-- --------------------------------------------------------------------------
-- 2) Wrappers “hoy”
-- --------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_diag_drawer_vs_cash_transactions;
CREATE VIEW vw_diag_drawer_vs_cash_transactions AS
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

DROP VIEW IF EXISTS vw_daily_diagnostics_summary;
CREATE VIEW vw_daily_diagnostics_summary AS
SELECT * FROM public.f_daily_diagnostics_summary_on(CURRENT_DATE);

-- --------------------------------------------------------------------------
-- 3) Ventas: vistas CORE
-- --------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_sales_by_terminal;
CREATE VIEW vw_sales_by_terminal AS
SELECT
  t.folio_date,
  t.branch_key,
  term.id        AS terminal_id,
  term.name      AS terminal_name,
  term.location  AS sucursal,
  COUNT(*)       AS tickets,
  ROUND(SUM(COALESCE(t.total_price,0)),2)                   AS bruto,
  ROUND(SUM(COALESCE(t.total_discount,0)),2)                AS descuento,
  ROUND(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)),2) AS neto
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3,4,5;

DROP VIEW IF EXISTS vw_sales_mix_payment;
CREATE VIEW vw_sales_mix_payment AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name)
    AS normalized_payment,
  ROUND(SUM(
    CASE WHEN tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
          AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(tx.amount,0) ELSE 0 END
  ),2) AS total
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;

DROP VIEW IF EXISTS vw_sales_by_hour;
CREATE VIEW vw_sales_by_hour AS
SELECT
  t.folio_date,
  t.branch_key,
  EXTRACT(HOUR FROM (t.created_at AT TIME ZONE 'America/Mexico_City'))::int AS hour_local,
  ROUND(SUM(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)),2) AS neto
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;

DROP VIEW IF EXISTS vw_top_items_today;
CREATE VIEW vw_top_items_today AS
SELECT
  t.folio_date,
  t.branch_key,
  ti.item_id,
  ti.item_name,
  ROUND(SUM(COALESCE(ti.quantity,0)),2) AS qty,
  ROUND(SUM(COALESCE(ti.item_total,0)-COALESCE(ti.discount_amount,0)),2) AS neto
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.folio_date = CURRENT_DATE
  AND (ti.voided IS NULL OR ti.voided=FALSE)
GROUP BY 1,2,3,4
ORDER BY neto DESC;

-- --------------------------------------------------------------------------
-- 4) Diagnósticos CORE
-- --------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_diag_neto_vs_cobros;
CREATE VIEW vw_diag_neto_vs_cobros AS
WITH tx AS (
  SELECT ticket_id, ROUND(SUM(
    CASE WHEN voided=FALSE AND UPPER(transaction_type)='CREDIT'
         AND payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(amount,0) ELSE 0 END
  ),2) AS paid_sum
  FROM public.transactions GROUP BY ticket_id
),
base AS (
  SELECT t.id AS ticket_id, t.folio_date, t.branch_key,
         ROUND(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0),2) AS net_ticket,
         COALESCE(tx.paid_sum,0) AS paid_sum,
         ROUND(COALESCE(tx.paid_sum,0)-(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0)),2) AS diff
  FROM public.ticket t
  LEFT JOIN tx ON tx.ticket_id=t.id
  WHERE t.paid=TRUE AND t.voided=FALSE
)
SELECT *,
  'PAYMENT_VS_NET_MISMATCH' AS error_code,
  CASE WHEN ABS(diff) > 1 THEN 'CRITICAL' ELSE 'WARN' END AS severity
FROM base
WHERE ABS(diff) > 0.01;

DROP VIEW IF EXISTS vw_diag_discount_header_vs_lines;
CREATE VIEW vw_diag_discount_header_vs_lines AS
WITH line_disc AS (
  SELECT ti.ticket_id, ROUND(SUM(COALESCE(ti.discount_amount,0)),2) AS sum_line_disc
  FROM public.ticket_item ti GROUP BY ti.ticket_id
)
SELECT
  t.id AS ticket_id, t.folio_date, t.branch_key,
  ROUND(COALESCE(t.total_discount,0),2) AS hdr_discount,
  COALESCE(ld.sum_line_disc,0) AS sum_line_disc,
  ROUND(COALESCE(ld.sum_line_disc,0)-COALESCE(t.total_discount,0),2) AS diff,
  'DISCOUNT_MISMATCH' AS error_code,
  'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN line_disc ld ON ld.ticket_id=t.id
WHERE t.paid=TRUE AND t.voided=FALSE
  AND ABS(ROUND(COALESCE(ld.sum_line_disc,0)-COALESCE(t.total_discount,0),2))>0.01;

DROP VIEW IF EXISTS vw_diag_orphans_tx;
CREATE VIEW vw_diag_orphans_tx AS
SELECT tx.id, tx.ticket_id, tx.amount, 'ORPHAN_TX' AS error_code, 'CRITICAL' AS severity
FROM public.transactions tx
LEFT JOIN public.ticket t ON t.id = tx.ticket_id
WHERE t.id IS NULL AND tx.voided=FALSE;

DROP VIEW IF EXISTS vw_diag_orphans_tickets;
CREATE VIEW vw_diag_orphans_tickets AS
SELECT t.id AS ticket_id, t.folio_date, t.branch_key, 'ORPHAN_TICKET' AS error_code, 'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id=t.id AND tx.voided=FALSE
WHERE t.paid=TRUE AND t.voided=FALSE AND tx.ticket_id IS NULL;

DROP VIEW IF EXISTS vw_diag_pagos_egresos;
CREATE VIEW vw_diag_pagos_egresos AS
SELECT terminal_id, ROUND(SUM(amount),2) AS egresos,
       'NON_SALES_CASHFLOW' AS error_code, 'WARN' AS severity
FROM public.transactions
WHERE payment_type IN ('REFUND','PAY_OUT','CASH_DROP') AND voided=FALSE
GROUP BY terminal_id;

DROP VIEW IF EXISTS vw_diag_paid_but_no_payments;
CREATE VIEW vw_diag_paid_but_no_payments AS
SELECT t.id AS ticket_id, t.folio_date, t.branch_key,
       ROUND(COALESCE(t.total_price,0)-COALESCE(t.total_discount,0),2) AS neto,
       'PAID_WITHOUT_TX' AS error_code, 'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id=t.id AND tx.voided=FALSE AND UPPER(tx.transaction_type)='CREDIT'
WHERE t.paid=TRUE AND t.voided=FALSE
  AND tx.ticket_id IS NULL
  AND (COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))>0.01;

DROP VIEW IF EXISTS vw_diag_unnormalized_payments;
CREATE VIEW vw_diag_unnormalized_payments AS
SELECT DISTINCT payment_type, transaction_type, payment_sub_type, custom_payment_name,
       'UNNORMALIZED_PAYMENT' AS error_code, 'WARN' AS severity
FROM public.transactions
WHERE selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name) IS NULL
  AND voided=FALSE;

DROP VIEW IF EXISTS vw_diag_service_charge_vs_paid;
CREATE VIEW vw_diag_service_charge_vs_paid AS
WITH svc_tx AS (
  SELECT ticket_id, ROUND(SUM(CASE
    WHEN selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)='CARGO_SERVICIO'
         AND voided=FALSE
    THEN COALESCE(amount,0) ELSE 0 END),2) AS paid_svc
  FROM public.transactions GROUP BY ticket_id
)
SELECT t.id AS ticket_id, t.folio_date,
       COALESCE(t.service_charges,0) AS declared, COALESCE(s.paid_svc,0) AS paid,
       ROUND(ABS(COALESCE(t.service_charges,0)-COALESCE(s.paid_svc,0)),2) AS diff,
       'SERVICE_CHARGE_MISMATCH' AS error_code, 'CRITICAL' AS severity
FROM public.ticket t
LEFT JOIN svc_tx s ON s.ticket_id = t.id
WHERE ABS(COALESCE(t.service_charges,0)-COALESCE(s.paid_svc,0)) > 0.01;

DROP VIEW IF EXISTS vw_diag_tip_declared_vs_paid;
CREATE VIEW vw_diag_tip_declared_vs_paid AS
WITH paid AS (
  SELECT tx.ticket_id,
         ROUND(SUM(CASE
           WHEN selemti.fn_normalizar_forma_pago(tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name)='PROPINA'
                AND tx.voided=FALSE
           THEN COALESCE(tx.amount,0) ELSE 0 END),2) AS tip_paid
  FROM public.transactions tx GROUP BY tx.ticket_id
)
SELECT t.id AS ticket_id, t.folio_date,
       COALESCE(t.tip_amount,0) AS tip_declared,
       COALESCE(p.tip_paid,0)   AS tip_paid,
       ROUND(COALESCE(t.tip_amount,0) - COALESCE(p.tip_paid,0),2) AS diff,
       'TIP_DECLARED_VS_PAID' AS error_code,
       CASE WHEN ABS(COALESCE(t.tip_amount,0)-COALESCE(p.tip_paid,0))>1 THEN 'CRITICAL' ELSE 'WARN' END AS severity
FROM public.ticket t
LEFT JOIN paid p ON p.ticket_id=t.id
WHERE COALESCE(t.tip_amount,0) > 0
  AND ABS(COALESCE(t.tip_amount,0)-COALESCE(p.tip_paid,0)) > 0.01;

DROP VIEW IF EXISTS vw_diag_folio_date_inconsistency;
CREATE VIEW vw_diag_folio_date_inconsistency AS
SELECT t.id, t.folio_date, t.paid_at, t.settled_at, t.closed_at,
       'FOLIO_DATE_MISMATCH' AS error_code, 'CRITICAL' AS severity
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
  AND ( (t.paid_at IS NOT NULL AND t.folio_date <> t.paid_at::date)
     OR (t.settled_at IS NOT NULL AND t.folio_date <> t.settled_at::date) );

-- --------------------------------------------------------------------------
-- 5) Ítems + Modificadores (detalle y agregados)
-- --------------------------------------------------------------------------
DROP VIEW IF EXISTS public.vw_item_mods_today;
DROP VIEW IF EXISTS public.vw_item_mods_daily_summary CASCADE;
DROP VIEW IF EXISTS public.vw_item_mods_by_item_today;
DROP FUNCTION IF EXISTS public.f_item_mods_on(date);
DROP FUNCTION IF EXISTS public.f_item_mods_detailed_on(date);

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
  JOIN public.ticket_item_modifier tim        ON tim.id = r.modifier_id
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
  MAX(qty_item) AS qty_item,
  COUNT(*)::bigint AS mods_count,
  ROUND(SUM(mods_total_amount)::numeric, 2) AS mods_total_amount
FROM all_rows
GROUP BY 1,2,3,4,5,6,7
ORDER BY item_name, modifier_name;
$$;

CREATE VIEW vw_item_mods_today AS
SELECT * FROM public.f_item_mods_on(CURRENT_DATE);

CREATE FUNCTION public.f_item_mods_detailed_on(p_date date)
RETURNS TABLE(
  folio_date         date,
  branch_key         text,
  terminal_id        integer,
  ticket_id          integer,
  ticket_item_id     integer,
  item_name          text,
  modifier_name      text,
  qty_item           numeric(12,2),
  base_price         numeric(12,2),
  modifier_extra     numeric(12,2),
  total_unit_price   numeric(12,2),
  total_line_amount  numeric(12,2)
) LANGUAGE sql STABLE AS
$$
WITH ti_base AS (
  SELECT
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    t.branch_key,
    t.terminal_id,
    t.id  AS ticket_id,
    ti.id AS ticket_item_id,
    ti.item_name::text AS item_name,
    COALESCE(ti.item_quantity,0)::numeric(12,2) AS qty_item,
    COALESCE(
      (to_jsonb(ti)->>'unit_price')::numeric,
      (to_jsonb(ti)->>'price')::numeric,
      (to_jsonb(ti)->>'item_price')::numeric,
      NULLIF(
        COALESCE((to_jsonb(ti)->>'total_price')::numeric,
                 (to_jsonb(ti)->>'item_total')::numeric,
                 (to_jsonb(ti)->>'amount')::numeric,
                 (to_jsonb(ti)->>'line_total')::numeric,
                 (to_jsonb(ti)->>'price_total')::numeric,
                 0),
        0
      ) / NULLIF(
        COALESCE((to_jsonb(ti)->>'item_quantity')::numeric,
                 (to_jsonb(ti)->>'quantity')::numeric,
                 (to_jsonb(ti)->>'qty')::numeric,
                 0),
        0
      ),
      0
    )::numeric(12,2) AS base_unit_price
  FROM public.ticket t
  JOIN public.ticket_item ti ON ti.ticket_id = t.id
  WHERE t.paid=TRUE
    AND t.voided=FALSE
    AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
),
rel_mods AS (
  SELECT
    b.folio_date, b.branch_key, b.terminal_id, b.ticket_id, b.ticket_item_id,
    b.item_name,
    COALESCE(to_jsonb(tim)->>'modifier_name',
             to_jsonb(tim)->>'name',
             to_jsonb(tim)->>'display_name',
             to_jsonb(tim)->>'label')::text AS modifier_name,
    b.qty_item,
    b.base_unit_price,
    COALESCE(
      (to_jsonb(tim)->>'total_price')::numeric,
      (to_jsonb(tim)->>'modifier_price')::numeric,
      (to_jsonb(tim)->>'extra_price')::numeric,
      (to_jsonb(tim)->>'price')::numeric,
      (to_jsonb(tim)->>'unit_price')::numeric,
      (to_jsonb(tim)->>'amount')::numeric,
      0
    )::numeric(12,2) AS modifier_extra
  FROM ti_base b
  JOIN public.ticket_item_modifier_relation r ON r.ticket_item_id = b.ticket_item_id
  JOIN public.ticket_item_modifier tim        ON tim.id = r.modifier_id
),
direct_mods AS (
  SELECT
    b.folio_date, b.branch_key, b.terminal_id, b.ticket_id, b.ticket_item_id,
    b.item_name,
    COALESCE(to_jsonb(tim)->>'modifier_name',
             to_jsonb(tim)->>'name',
             to_jsonb(tim)->>'display_name',
             to_jsonb(tim)->>'label')::text AS modifier_name,
    b.qty_item,
    b.base_unit_price,
    COALESCE(
      (to_jsonb(tim)->>'total_price')::numeric,
      (to_jsonb(tim)->>'modifier_price')::numeric,
      (to_jsonb(tim)->>'extra_price')::numeric,
      (to_jsonb(tim)->>'price')::numeric,
      (to_jsonb(tim)->>'unit_price')::numeric,
      (to_jsonb(tim)->>'amount')::numeric,
      0
    )::numeric(12,2) AS modifier_extra
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
  folio_date,
  branch_key,
  terminal_id,
  ticket_id,
  ticket_item_id,
  item_name,
  modifier_name,
  qty_item,
  base_unit_price AS base_price,
  modifier_extra,
  (base_unit_price + modifier_extra)::numeric(12,2) AS total_unit_price,
  (qty_item * (base_unit_price + modifier_extra))::numeric(12,2) AS total_line_amount
FROM all_rows
WHERE modifier_name IS NOT NULL
ORDER BY item_name, modifier_name;
$$;

CREATE VIEW public.vw_item_mods_detailed_today AS
SELECT * FROM public.f_item_mods_detailed_on(CURRENT_DATE);

DROP VIEW IF EXISTS public.vw_item_mods_daily_summary CASCADE;
CREATE VIEW public.vw_item_mods_daily_summary AS
SELECT
  folio_date,
  branch_key,
  item_name,
  modifier_name,
  SUM(qty_item)                                AS qty_items,
  COUNT(*)::bigint                              AS times_selected,
  ROUND(SUM(modifier_extra * qty_item), 2)     AS total_mods_amount,
  ROUND(SUM(total_line_amount), 2)             AS total_line_amount
FROM public.vw_item_mods_detailed_today
GROUP BY 1,2,3,4
ORDER BY branch_key, item_name, modifier_name;

DROP VIEW IF EXISTS public.vw_item_mods_by_item_today;
CREATE VIEW public.vw_item_mods_by_item_today AS
SELECT
  item_name,
  modifier_name,
  SUM(times_selected)::bigint              AS times_selected,
  ROUND(SUM(total_mods_amount), 2)         AS total_mods_amount
FROM public.vw_item_mods_daily_summary
GROUP BY 1,2
ORDER BY item_name, times_selected DESC, modifier_name;

-- --------------------------------------------------------------------------
-- 6) Mix de pago por fecha + wrapper a hoy
-- --------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.f_sales_mix_payment_on(date);
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

DROP VIEW IF EXISTS public.vw_sales_mix_payment_today;
CREATE VIEW public.vw_sales_mix_payment_today AS
SELECT * FROM public.f_sales_mix_payment_on(CURRENT_DATE);

-- ============================================================================
-- FIN
-- ============================================================================
