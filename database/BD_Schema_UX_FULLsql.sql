--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.25
-- Dumped by pg_dump version 9.5.25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE selemti.consumo_policy OWNER TO postgres;

--
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE selemti.lote_estado OWNER TO postgres;

--
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE selemti.merma_clase OWNER TO postgres;

--
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE selemti.merma_tipo OWNER TO postgres;

--
-- Name: mov_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.mov_tipo AS ENUM (
    'RECEPCION',
    'COMPRA',
    'VENTA',
    'CONSUMO_OP',
    'AJUSTE',
    'TRASPASO_IN',
    'TRASPASO_OUT',
    'ANULACION'
);


ALTER TYPE selemti.mov_tipo OWNER TO postgres;

--
-- Name: op_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.op_estado AS ENUM (
    'ABIERTA',
    'EN_PROCESO',
    'CERRADA',
    'ANULADA'
);


ALTER TYPE selemti.op_estado OWNER TO postgres;

--
-- Name: pos_modifier_effect; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.pos_modifier_effect AS ENUM (
    'extra',
    'remove',
    'replace',
    'delta'
);


ALTER TYPE selemti.pos_modifier_effect OWNER TO postgres;

--
-- Name: producto_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE selemti.producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE selemti.producto_tipo OWNER TO postgres;

--
-- Name: _last_assign_window(integer, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._last_assign_window(_terminal_id integer, _user_id integer, _ref_time timestamp with time zone) RETURNS TABLE(from_ts timestamp with time zone, to_ts timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
WITH ev AS (
    SELECT
        dah."time" AS event_time,
        dah.operation AS action,
        LAG(dah."time") OVER (PARTITION BY dah.a_user ORDER BY dah."time") AS prev_event
    FROM public.drawer_assigned_history dah
    WHERE dah.a_user = _user_id
      AND dah."time" <= _ref_time
)
SELECT
    COALESCE(prev_event, _ref_time - INTERVAL '24 hours')::timestamptz AS from_ts,
    event_time::timestamptz AS to_ts
FROM ev
WHERE action IN ('ASIGNAR','ASSIGN','OPEN','CERRAR','CLOSE','LIBERAR','UNASSIGN')
ORDER BY event_time DESC
LIMIT 1;
$$;


ALTER FUNCTION public._last_assign_window(_terminal_id integer, _user_id integer, _ref_time timestamp with time zone) OWNER TO postgres;

--
-- Name: assign_daily_folio(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION public.assign_daily_folio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_branch   TEXT;
    v_date     DATE;
    v_next     INTEGER;
BEGIN
    IF NEW.terminal_id IS NULL THEN
        RAISE EXCEPTION 'No se puede crear ticket sin terminal_id';
    END IF;
    IF NEW.create_date IS NULL THEN
        NEW.create_date := NOW();
    END IF;
    v_date := (NEW.create_date AT TIME ZONE 'America/Mexico_City')::DATE;
    SELECT COALESCE(NULLIF(UPPER(BTRIM(t.location)), ''), '') INTO v_branch
    FROM public.terminal t
    WHERE t.id = NEW.terminal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Terminal % no existe en la base de datos', NEW.terminal_id;
    END IF;
    IF NEW.daily_folio IS NOT NULL AND NEW.folio_date IS NOT NULL AND NEW.branch_key IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.ticket
            WHERE folio_date = NEW.folio_date
            AND branch_key = NEW.branch_key
            AND daily_folio = NEW.daily_folio
            AND id != NEW.id
        ) THEN
            RAISE EXCEPTION 'Folio % ya existe para % en %', NEW.daily_folio, NEW.branch_key, NEW.folio_date;
        END IF;
        RETURN NEW;
    END IF;
    WITH up AS (
        INSERT INTO public.daily_folio_counter (folio_date, branch_key, last_value)
        VALUES (v_date, v_branch, 1)
        ON CONFLICT (folio_date, branch_key)
        DO UPDATE SET last_value = public.daily_folio_counter.last_value + 1
        RETURNING last_value
    )
    SELECT last_value INTO v_next FROM up;
    NEW.folio_date := v_date;
    NEW.branch_key := v_branch;
    NEW.daily_folio := v_next;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.assign_daily_folio() OWNER TO floreant;

--
-- Name: f_daily_diagnostics_summary_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_daily_diagnostics_summary_on(p_date date) RETURNS TABLE(source_view text, severity text, rows bigint)
    LANGUAGE sql STABLE
    AS $$
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


ALTER FUNCTION public.f_daily_diagnostics_summary_on(p_date date) OWNER TO postgres;

--
-- Name: f_diag_drawer_vs_cash_transactions_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_diag_drawer_vs_cash_transactions_on(p_date date) RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric, cash_in numeric, non_cash_in numeric, expected_cash numeric, diff numeric, error_code text, severity text)
    LANGUAGE sql STABLE
    AS $$
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


ALTER FUNCTION public.f_diag_drawer_vs_cash_transactions_on(p_date date) OWNER TO postgres;

--
-- Name: f_item_mods_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_item_mods_on(p_date date) RETURNS TABLE(folio_date date, branch_key text, terminal_id integer, ticket_id integer, ticket_item_id integer, item_name text, modifier_name text, qty_item numeric, mods_count bigint, mods_total_amount numeric)
    LANGUAGE sql STABLE
    AS $$
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


ALTER FUNCTION public.f_item_mods_on(p_date date) OWNER TO postgres;

--
-- Name: f_sales_mix_payment_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_sales_mix_payment_on(p_date date) RETURNS TABLE(folio_date date, branch_key text, normalized_payment text, total numeric)
    LANGUAGE sql STABLE
    AS $$
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


ALTER FUNCTION public.f_sales_mix_payment_on(p_date date) OWNER TO postgres;

--
-- Name: fn_correct_drawer_report(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_correct_drawer_report(report_date date) RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    dr.terminal_id,
    dr.total_revenue::numeric(12,2) AS original_total_revenue,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS corrected_neto_tickets,
    (SUM(t.total_price - t.total_discount) - dr.total_revenue)::numeric(12,2) AS adjustment
  FROM public.drawer_pull_report dr
  JOIN public.ticket t
    ON t.terminal_id = dr.terminal_id
   AND t.closing_date::date = dr.report_time::date
  WHERE dr.report_time::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY dr.terminal_id, dr.total_revenue;
END;
$$;


ALTER FUNCTION public.fn_correct_drawer_report(report_date date) OWNER TO postgres;

--
-- Name: fn_daily_reconciliation(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_daily_reconciliation(report_date date) RETURNS TABLE(terminal_id integer, tickets_count integer, transactions_count integer, ticket_net_total numeric, transactions_total numeric, difference numeric, status text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.terminal_id,
    COUNT(DISTINCT t.id) AS tickets_count,
    COUNT(tx.id) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_type = 'CREDIT'
        AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    ) AS transactions_count,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS ticket_net_total,
    SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount ELSE 0 END
    )::numeric(12,2) AS transactions_total,
    (SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount ELSE 0 END
    ) - SUM(t.total_price - t.total_discount))::numeric(12,2) AS difference,
    CASE
      WHEN SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount ELSE 0 END
      ) = SUM(t.total_price - t.total_discount)
      THEN 'OK'
      ELSE 'DISCREPANCY'
    END AS status
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.terminal_id;
END;
$$;


ALTER FUNCTION public.fn_daily_reconciliation(report_date date) OWNER TO postgres;

--
-- Name: fn_reconciliation_detail(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_reconciliation_detail(report_date date) RETURNS TABLE(ticket_id integer, terminal_id integer, ticket_number integer, ticket_total numeric, ticket_discount numeric, ticket_neto numeric, transactions_sum numeric, discrepancy numeric, discrepancy_type text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.terminal_id,
    t.daily_folio,
    t.total_price::numeric(12,2),
    t.total_discount::numeric(12,2),
    (t.total_price - t.total_discount)::numeric(12,2) AS ticket_neto,
    COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0)::numeric(12,2) AS transactions_sum,
    (COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount))::numeric(12,2) AS discrepancy,
    CASE
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount END
      ), 0) > (t.total_price - t.total_discount) THEN 'OVERSTATED'
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount END
      ), 0) < (t.total_price - t.total_discount) THEN 'UNDERSTATED'
      ELSE 'OK'
    END AS discrepancy_type
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.id, t.terminal_id, t.daily_folio, t.total_price, t.total_discount
  HAVING COALESCE(SUM(
    CASE
      WHEN tx.voided = FALSE
       AND tx.transaction_type = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN tx.amount END
  ), 0) <> (t.total_price - t.total_discount)
  ORDER BY ABS(
    COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount)
  ) DESC;
END;
$$;


ALTER FUNCTION public.fn_reconciliation_detail(report_date date) OWNER TO postgres;

--
-- Name: get_daily_stats(date); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION public.get_daily_stats(p_date date DEFAULT ('now'::text)::date) RETURNS TABLE(sucursal text, total_ordenes integer, total_ventas numeric, primer_orden time without time zone, ultima_orden time without time zone, promedio_por_hora numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        tfc.branch_key,
        COUNT(*)::INTEGER AS total_ordenes,
        SUM(tfc.total_price)::NUMERIC AS total_ventas,
        MIN(tfc.create_date::TIME) AS primer_orden,
        MAX(tfc.create_date::TIME) AS ultima_orden,
        ROUND(
            (COUNT(*)::NUMERIC /
            GREATEST(EXTRACT(EPOCH FROM (MAX(tfc.create_date) - MIN(tfc.create_date))) / 3600.0, 1))::NUMERIC,
            2
        ) AS promedio_por_hora
    FROM public.ticket_folio_complete tfc
    WHERE tfc.folio_date = p_date
    AND tfc.status_simple != 'CANCELADO'
    GROUP BY tfc.branch_key
    ORDER BY tfc.branch_key;
$$;


ALTER FUNCTION public.get_daily_stats(p_date date) OWNER TO floreant;

--
-- Name: get_ticket_folio_info(integer); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION public.get_ticket_folio_info(p_ticket_id integer) RETURNS TABLE(daily_folio integer, folio_date date, branch_key text, folio_date_txt text, folio_display text, sucursal_completa text, terminal_name text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        t.daily_folio,
        t.folio_date,
        t.branch_key,
        TO_CHAR(t.folio_date, 'DD/MM/YYYY') AS folio_date_txt,
        LPAD(t.daily_folio::TEXT, 4, '0') AS folio_display,
        COALESCE(term.location, 'DEFAULT') AS sucursal_completa,
        term.name AS terminal_name
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.id = p_ticket_id;
$$;


ALTER FUNCTION public.get_ticket_folio_info(p_ticket_id integer) OWNER TO floreant;

--
-- Name: kds_notify(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION public.kds_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_ticket_id   INT;
    v_pg_id       INT;
    v_item_id     INT;
    v_status      TEXT;
    v_total       INT;
    v_ready       INT;
    v_done        INT;
    v_type        TEXT;
    v_daily_folio INT;
    v_branch_key  TEXT;
    v_folio_fmt   TEXT;
BEGIN
    IF TG_TABLE_NAME = 'kitchen_ticket_item' THEN
        IF NEW.ticket_item_id IS NULL THEN
            RAISE EXCEPTION 'ticket_item_id no puede ser NULL en kitchen_ticket_item';
        END IF;
        v_item_id := NEW.ticket_item_id;
        SELECT ti.ticket_id, ti.pg_id INTO v_ticket_id, v_pg_id
        FROM ticket_item ti WHERE ti.id = v_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket_item % no existe', v_item_id;
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket % no existe', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, '0');
        v_status := UPPER(COALESCE(NEW.status, ''));
        v_type := CASE WHEN TG_OP = 'INSERT' THEN 'item_upsert' ELSE 'item_status' END;
        PERFORM pg_notify(
            'kds_event',
            json_build_object(
                'type',        v_type,
                'ticket_id',   v_ticket_id,
                'pg',          v_pg_id,
                'item_id',     v_item_id,
                'status',      v_status,
                'daily_folio', v_daily_folio,
                'branch_key',  v_branch_key,
                'folio_fmt',   v_folio_fmt,
                'ts',          NOW()
            )::TEXT
        );
    ELSIF TG_TABLE_NAME = 'ticket_item' THEN
        v_item_id := NEW.id;
        v_ticket_id := NEW.ticket_id;
        v_pg_id := NEW.pg_id;
        IF v_ticket_id IS NULL THEN
            RAISE EXCEPTION 'ticket_id no puede ser NULL en ticket_item';
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket % no existe', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, '0');
        v_status := UPPER(COALESCE(NEW.status, ''));
        v_type := CASE WHEN TG_OP = 'INSERT' THEN 'item_insert' ELSE 'item_status' END;
        PERFORM pg_notify(
            'kds_event',
            json_build_object(
                'type',        v_type,
                'ticket_id',   v_ticket_id,
                'pg',          v_pg_id,
                'item_id',     v_item_id,
                'status',      v_status,
                'daily_folio', v_daily_folio,
                'branch_key',  v_branch_key,
                'folio_fmt',   v_folio_fmt,
                'ts',          NOW()
            )::TEXT
        );
    END IF;
    IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
        WITH s AS (
            SELECT
                ti.id AS item_id,
                UPPER(COALESCE(kti.status, ti.status, '')) AS st
            FROM ticket_item ti
            LEFT JOIN kitchen_ticket_item kti ON kti.ticket_item_id = ti.id
            WHERE ti.ticket_id = v_ticket_id AND ti.pg_id = v_pg_id
            GROUP BY ti.id, st
        )
        SELECT
            COUNT(DISTINCT item_id) AS total,
            COUNT(DISTINCT item_id) FILTER (WHERE st IN ('READY', 'DONE')) AS ready,
            COUNT(DISTINCT item_id) FILTER (WHERE st = 'DONE') AS done
        INTO v_total, v_ready, v_done
        FROM s;
        IF v_total > 0 AND v_total = v_ready THEN
            PERFORM pg_notify(
                'kds_event',
                json_build_object(
                    'type',        'ticket_all_ready',
                    'ticket_id',   v_ticket_id,
                    'pg',          v_pg_id,
                    'daily_folio', v_daily_folio,
                    'branch_key',  v_branch_key,
                    'folio_fmt',   v_folio_fmt,
                    'ts',          NOW()
                )::TEXT
            );
        END IF;
        IF v_total > 0 AND v_total = v_done THEN
            PERFORM pg_notify(
                'kds_event',
                json_build_object(
                    'type',        'ticket_all_done',
                    'ticket_id',   v_ticket_id,
                    'pg',          v_pg_id,
                    'daily_folio', v_daily_folio,
                    'branch_key',  v_branch_key,
                    'folio_fmt',   v_folio_fmt,
                    'ts',          NOW()
                )::TEXT
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.kds_notify() OWNER TO floreant;

--
-- Name: reset_daily_folio_smart(text); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION public.reset_daily_folio_smart(p_branch text DEFAULT NULL::text) RETURNS TABLE(branch_reset text, tickets_affected integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_date DATE := CURRENT_DATE;
    v_branch TEXT;
    v_has_rows BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.daily_folio_counter
        WHERE folio_date = v_current_date
        AND (p_branch IS NULL OR branch_key = UPPER(BTRIM(p_branch)))
    ) INTO v_has_rows;
    IF NOT v_has_rows THEN
        branch_reset := 'none';
        tickets_affected := 0;
        RETURN NEXT;
        RETURN;
    END IF;
    FOR v_branch IN
        SELECT DISTINCT
            CASE
                WHEN p_branch IS NULL THEN dfc.branch_key
                ELSE UPPER(BTRIM(p_branch))
            END
        FROM public.daily_folio_counter dfc
        WHERE dfc.folio_date = v_current_date
        AND (p_branch IS NULL OR dfc.branch_key = UPPER(BTRIM(p_branch)))
    LOOP
        IF EXISTS (
            SELECT 1 FROM public.ticket
            WHERE branch_key = v_branch
            AND folio_date = v_current_date
        ) THEN
            RAISE NOTICE 'ADVERTENCIA: Sucursal % ya tiene % tickets hoy - NO reseteable',
                v_branch,
                (SELECT COUNT(*) FROM public.ticket WHERE branch_key = v_branch AND folio_date = v_current_date);
            CONTINUE;
        END IF;
        DELETE FROM public.daily_folio_counter
        WHERE branch_key = v_branch AND folio_date = v_current_date;
        branch_reset := v_branch;
        tickets_affected := 0;
        RETURN NEXT;
    END LOOP;
    RETURN;
END
$$;


ALTER FUNCTION public.reset_daily_folio_smart(p_branch text) OWNER TO floreant;

--
-- Name: audit_trigger_func(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.audit_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, OLD.id::TEXT, row_to_json(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION selemti.audit_trigger_func() OWNER TO postgres;

--
-- Name: cerrar_lote_preparado(bigint, selemti.merma_clase, text, integer, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.cerrar_lote_preparado(p_lote_id bigint, p_clase selemti.merma_clase, p_motivo text, p_usuario_id integer DEFAULT NULL::integer, p_uom_id integer DEFAULT NULL::integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item_id TEXT;
v_qty_disponible NUMERIC(14,6);
v_mov_id BIGINT;
BEGIN
    SELECT b.item_id, b.cantidad_actual
    INTO v_item_id, v_qty_disponible
    FROM selemti.inventory_batch b
    WHERE b.id = p_lote_id;
IF v_item_id IS NULL THEN
        RAISE EXCEPTION 'Lote % no existe', p_lote_id;
END IF;
IF v_qty_disponible IS NULL OR v_qty_disponible <= 0 THEN
        RETURN 0;
END IF;
RETURN v_mov_id;
END;
$$;


ALTER FUNCTION selemti.cerrar_lote_preparado(p_lote_id bigint, p_clase selemti.merma_clase, p_motivo text, p_usuario_id integer, p_uom_id integer) OWNER TO postgres;

--
-- Name: fn_after_price_insert_alert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_after_price_insert_alert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r_id bigint;
  v_now timestamp := COALESCE(NEW.effective_from, now());
  v_old numeric; v_new numeric; v_delta numeric; v_rule numeric;
BEGIN
  FOR r_id IN SELECT recipe_id FROM selemti.fn_recipes_using_item(NEW.item_id, v_now)
  LOOP
    SELECT portion_cost INTO v_new FROM selemti.fn_recipe_cost_at(r_id, v_now);
    SELECT portion_cost INTO v_old
      FROM selemti.recipe_cost_history
      WHERE recipe_id = r_id AND snapshot_at < v_now
      ORDER BY snapshot_at DESC LIMIT 1;

    PERFORM selemti.sp_snapshot_recipe_cost(r_id, v_now);

    IF v_old IS NOT NULL AND v_new IS NOT NULL AND v_old > 0 THEN
      v_delta := ((v_new - v_old)/v_old) * 100.0;

      SELECT COALESCE((
        SELECT threshold_pct
        FROM selemti.alert_rules
        WHERE active = TRUE
          AND (recipe_id = r_id OR category_id IS NOT NULL)
        ORDER BY recipe_id NULLS LAST
        LIMIT 1
      ), 10.0) INTO v_rule;

      IF v_delta >= v_rule THEN
        INSERT INTO selemti.alert_events(recipe_id, snapshot_at, old_portion_cost, new_portion_cost, delta_pct)
        VALUES (r_id, v_now, v_old, v_new, v_delta);
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END$$;


ALTER FUNCTION selemti.fn_after_price_insert_alert() OWNER TO postgres;

--
-- Name: fn_assign_item_code(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_assign_item_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_prefijo text;
    v_next    bigint;
BEGIN
    IF NEW.category_id IS NULL THEN
        RETURN NEW;
    END IF;
    IF NEW.item_code IS NOT NULL AND NEW.item_code <> '' THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(NULLIF(TRIM(prefijo),''), 'C') INTO v_prefijo
    FROM selemti.item_categories WHERE id=NEW.category_id;

    INSERT INTO selemti.item_category_counters(category_id,last_val,updated_at)
    VALUES (NEW.category_id,1,now())
    ON CONFLICT(category_id) DO UPDATE
        SET last_val = selemti.item_category_counters.last_val + 1,
            updated_at = now()
    RETURNING last_val INTO v_next;

    NEW.item_code := v_prefijo || '-' || lpad(v_next::text,5,'0');
    RETURN NEW;
END$$;


ALTER FUNCTION selemti.fn_assign_item_code() OWNER TO postgres;

--
-- Name: fn_confirmar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'VENTA_TEO',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'PENDIENTE'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'CONFIRMADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'PENDIENTE';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'CONFIRM', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- Name: fn_dah_after_insert(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_dah_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_term RECORD;
BEGIN
  IF NEW.operation = 'ASIGNAR' THEN
    SELECT * INTO v_term FROM public.terminal
    WHERE assigned_user = NEW.a_user
    ORDER BY id LIMIT 1;

    IF v_term IS NULL THEN
      INSERT INTO selemti.auditoria(quien,que,payload)
      VALUES(NEW.a_user,'NO_SE_PUDO_RESOLVER_TERMINAL',
             jsonb_build_object('dah_id',NEW.id,'operation',NEW.operation,'time',NEW."time"));
      RETURN NEW;
    END IF;

    INSERT INTO selemti.sesion_cajon(
      terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
      apertura_ts, estatus, opening_float, dah_evento_id
    ) VALUES (
      v_term.id, COALESCE(v_term.name,'Terminal '||v_term.id), COALESCE(v_term.location,''),
      NEW.a_user, COALESCE(NEW."time", now()), 'ACTIVA', COALESCE(v_term.current_balance,0), NEW.id
    );

  ELSIF NEW.operation = 'CERRAR' THEN
    SELECT * INTO v_term FROM public.terminal
    WHERE assigned_user = NEW.a_user
    ORDER BY id LIMIT 1;

    UPDATE selemti.sesion_cajon
       SET cierre_ts     = COALESCE(NEW."time", now()),
           estatus       = 'LISTO_PARA_CORTE',
           closing_float = COALESCE(v_term.current_balance,0),
           dah_evento_id = COALESCE(dah_evento_id, NEW.id)
     WHERE terminal_id = COALESCE(v_term.id, terminal_id)
       AND cajero_usuario_id = NEW.a_user
       AND cierre_ts IS NULL;
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_dah_after_insert() OWNER TO floreant;

--
-- Name: fn_dah_after_insert_refuerzo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_dah_after_insert_refuerzo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_terminal_id   INTEGER;
v_now_balance   NUMERIC(12,2);
v_op            TEXT := COALESCE(NEW.operation,'');
v_obj_id        BIGINT;
BEGIN
  IF v_op !~* '(release|liber|close|cerrar|unassign|fin|end)' THEN
    RETURN NEW;
END IF;
v_terminal_id := selemti.fn_resolver_terminal_para_usuario(NEW.a_user, NEW."time");
IF v_terminal_id IS NULL THEN
    RETURN NEW;
END IF;
SELECT current_balance::numeric INTO v_now_balance
  FROM public.terminal WHERE id = v_terminal_id;
SELECT s.id INTO v_obj_id
  FROM selemti.sesion_cajon s
  WHERE s.terminal_id = v_terminal_id
    AND s.cajero_usuario_id = NEW.a_user
    AND s.cierre_ts IS NULL
  ORDER BY s.apertura_ts DESC
  LIMIT 1;
IF v_obj_id IS NOT NULL THEN
    UPDATE selemti.sesion_cajon
       SET closing_float = COALESCE(closing_float, NULLIF(v_now_balance,0)),
           cierre_ts     = COALESCE(cierre_ts, NEW."time"),
           estatus       = CASE WHEN estatus='ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
     WHERE id = v_obj_id;
END IF;
RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_dah_after_insert_refuerzo() OWNER TO postgres;

--
-- Name: fn_dah_after_insert_safe(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_dah_after_insert_safe() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    v_term RECORD;
BEGIN
    IF NEW.operation = 'ASIGNAR' THEN
        -- Buscar terminal asignado al usuario
        SELECT * INTO v_term FROM public.terminal
        WHERE assigned_user = NEW.a_user
        ORDER BY id LIMIT 1;
        
        -- Si no hay terminal asignado, buscar uno libre y asignarlo
        IF v_term IS NULL THEN
            SELECT * INTO v_term FROM public.terminal
            WHERE assigned_user IS NULL
            AND has_cash_drawer = true
            ORDER BY id LIMIT 1;
            
            IF v_term IS NOT NULL THEN
                -- Asignar el terminal libre al usuario
                UPDATE public.terminal 
                SET assigned_user = NEW.a_user 
                WHERE id = v_term.id;
                
                -- Log de asignación automática
                INSERT INTO selemti.auditoria(quien, que, payload)
                VALUES(NEW.a_user, 'TERMINAL_ASIGNADO_AUTOMATICAMENTE',
                       jsonb_build_object('terminal_id', v_term.id, 
                                        'dah_id', NEW.id, 
                                        'operation', NEW.operation, 
                                        'time', NEW."time"));
            ELSE
                -- No hay terminales disponibles, solo registrar en auditoría
                INSERT INTO selemti.auditoria(quien, que, payload)
                VALUES(NEW.a_user, 'NO_HAY_TERMINAL_DISPONIBLE',
                       jsonb_build_object('dah_id', NEW.id, 
                                        'operation', NEW.operation, 
                                        'time', NEW."time"));
                RETURN NEW;
            END IF;
        END IF;
        
        -- Insertar en sesión cajón
        INSERT INTO selemti.sesion_cajon(
            terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
            apertura_ts, estatus, opening_float, dah_evento_id
        ) VALUES (
            v_term.id, 
            COALESCE(v_term.name, 'Terminal '||v_term.id), 
            COALESCE(v_term.location, ''),
            NEW.a_user, 
            COALESCE(NEW."time", now()), 
            'ACTIVA', 
            COALESCE(v_term.current_balance, 0), 
            NEW.id
        ) ON CONFLICT DO NOTHING; -- Evitar duplicados
        
    ELSIF NEW.operation = 'CERRAR' THEN
        SELECT * INTO v_term FROM public.terminal
        WHERE assigned_user = NEW.a_user
        ORDER BY id LIMIT 1;
        
        IF v_term IS NOT NULL THEN
            UPDATE selemti.sesion_cajon
            SET cierre_ts = COALESCE(NEW."time", now()),
                estatus = 'LISTO_PARA_CORTE',
                closing_float = COALESCE(v_term.current_balance, 0),
                dah_evento_id = COALESCE(dah_evento_id, NEW.id)
            WHERE terminal_id = v_term.id
              AND cajero_usuario_id = NEW.a_user
              AND cierre_ts IS NULL;
              
            -- Opcionalmente liberar el terminal
            -- UPDATE public.terminal SET assigned_user = NULL WHERE id = v_term.id;
        END IF;
    END IF;
    
    RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_dah_after_insert_safe() OWNER TO postgres;

--
-- Name: fn_expandir_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_expandir_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_consumo_id bigint;
    v_has_recipes boolean := coalesce(to_regclass('selemti.recipe_details') IS NOT NULL, false);
BEGIN
    INSERT INTO selemti.inv_consumo_pos (ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, expandido, created_at)
    SELECT DISTINCT
        ti.ticket_id,
        ti.id,
        t.sucursal_id,
        t.terminal_id,
        'PENDIENTE',
        true,
        now()
    FROM public.ticket_item ti
    JOIN public.ticket t ON t.id = ti.ticket_id
    WHERE ti.ticket_id = _ticket_id
      AND NOT EXISTS (
            SELECT 1
            FROM selemti.inv_consumo_pos c
            WHERE c.ticket_item_id = ti.id
        );

    IF NOT v_has_recipes THEN
        RETURN;
    END IF;

    FOR v_consumo_id IN
        SELECT c.id
        FROM selemti.inv_consumo_pos c
        WHERE c.ticket_id = _ticket_id
    LOOP
        INSERT INTO selemti.inv_consumo_pos_det (consumo_id, item_id, uom, cantidad, factor, origen, meta)
        SELECT
            v_consumo_id,
            rd.item_id,
            rd.required_uom,
            rd.cantidad * ti.item_quantity,
            coalesce(rd.factor, 1),
            'RECETA',
            jsonb_build_object('ticket_item_id', ti.id)
        FROM selemti.recipe_details rd
        JOIN public.ticket_item ti ON ti.item_id = rd.recipe_item_id AND ti.ticket_id = _ticket_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM selemti.inv_consumo_pos_det d
            WHERE d.consumo_id = v_consumo_id
              AND d.item_id = rd.item_id
              AND coalesce(d.meta->>'ticket_item_id', '') = ti.id::text
        );
    END LOOP;

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'EXPAND', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_expandir_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- Name: fn_fondo_actual(integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_fondo_actual(p_terminal_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_balance NUMERIC(12,2);
BEGIN
  SELECT t.current_balance::numeric(12,2)
    INTO v_balance
  FROM public.terminal t
  WHERE t.id = p_terminal_id;

  RETURN COALESCE(v_balance, 0);
END;
$$;


ALTER FUNCTION selemti.fn_fondo_actual(p_terminal_id integer) OWNER TO floreant;

--
-- Name: fn_gen_cat_codigo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_gen_cat_codigo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        NEW.codigo := 'CAT-' || lpad(nextval('selemti.seq_cat_codigo')::text, 4, '0');
    END IF;
    RETURN NEW;
END$$;


ALTER FUNCTION selemti.fn_gen_cat_codigo() OWNER TO postgres;

--
-- Name: fn_generar_postcorte(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_generar_postcorte(p_sesion_id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_postcorte_id BIGINT;
  v_precorte_id BIGINT;
  v_terminal_id INT;
  v_apertura_ts TIMESTAMPTZ;
  v_cierre_ts TIMESTAMPTZ;

  -- Declarados
  v_decl_ef NUMERIC;
  v_decl_cr NUMERIC;
  v_decl_db NUMERIC;
  v_decl_tr NUMERIC;

  -- Sistema
  v_sys_ef NUMERIC;
  v_sys_cr NUMERIC;
  v_sys_db NUMERIC;
  v_sys_tr NUMERIC;

  -- Diferencias
  v_dif_ef NUMERIC;
  v_dif_tj NUMERIC;
  v_dif_tr NUMERIC;
BEGIN
  -- Obtener datos de sesiÃ³n
  SELECT terminal_id, apertura_ts, cierre_ts
  INTO v_terminal_id, v_apertura_ts, v_cierre_ts
  FROM selemti.sesion_cajon
  WHERE id = p_sesion_id;

  -- Obtener precorte_id
  SELECT id INTO v_precorte_id
  FROM selemti.precorte
  WHERE sesion_id = p_sesion_id
  ORDER BY id DESC LIMIT 1;

  -- Calcular declarados (desde precorte)
  SELECT
    COALESCE(SUM(subtotal), 0)
  INTO v_decl_ef
  FROM selemti.precorte_efectivo
  WHERE precorte_id = v_precorte_id;

  SELECT
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('CREDITO') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('DEBITO', 'DÃ‰BITO') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('TRANSFER', 'TRANSFERENCIA') THEN monto ELSE 0 END), 0)
  INTO v_decl_cr, v_decl_db, v_decl_tr
  FROM selemti.precorte_otros
  WHERE precorte_id = v_precorte_id;

  -- Calcular sistema (desde transactions POS)
  SELECT
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CASH' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CREDIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'DEBIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CUSTOM_PAYMENT' AND UPPER(custom_payment_name) LIKE 'TRANSFER%' THEN amount ELSE 0 END), 0)
  INTO v_sys_ef, v_sys_cr, v_sys_db, v_sys_tr
  FROM public.transactions
  WHERE terminal_id = v_terminal_id
    AND transaction_time BETWEEN v_apertura_ts AND COALESCE(v_cierre_ts, now())
    AND UPPER(transaction_type) = 'CREDIT'
    AND voided = false;

  -- Calcular diferencias
  v_dif_ef := v_decl_ef - v_sys_ef;
  v_dif_tj := (v_decl_cr + v_decl_db) - (v_sys_cr + v_sys_db);
  v_dif_tr := v_decl_tr - v_sys_tr;

  -- Insertar postcorte
  INSERT INTO selemti.postcorte (
    sesion_id,
    sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo,
    sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas,
    sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias,
    creado_en, creado_por
  ) VALUES (
    p_sesion_id,
    v_sys_ef, v_decl_ef, v_dif_ef,
    CASE WHEN ABS(v_dif_ef) < 0.01 THEN 'CUADRA' WHEN v_dif_ef > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    v_sys_cr + v_sys_db, v_decl_cr + v_decl_db, v_dif_tj,
    CASE WHEN ABS(v_dif_tj) < 0.01 THEN 'CUADRA' WHEN v_dif_tj > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    v_sys_tr, v_decl_tr, v_dif_tr,
    CASE WHEN ABS(v_dif_tr) < 0.01 THEN 'CUADRA' WHEN v_dif_tr > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    now(), 1
  )
  ON CONFLICT (sesion_id) DO UPDATE SET
    sistema_efectivo_esperado = EXCLUDED.sistema_efectivo_esperado,
    declarado_efectivo = EXCLUDED.declarado_efectivo,
    diferencia_efectivo = EXCLUDED.diferencia_efectivo,
    veredicto_efectivo = EXCLUDED.veredicto_efectivo,
    sistema_tarjetas = EXCLUDED.sistema_tarjetas,
    declarado_tarjetas = EXCLUDED.declarado_tarjetas,
    diferencia_tarjetas = EXCLUDED.diferencia_tarjetas,
    veredicto_tarjetas = EXCLUDED.veredicto_tarjetas,
    sistema_transferencias = EXCLUDED.sistema_transferencias,
    declarado_transferencias = EXCLUDED.declarado_transferencias,
    diferencia_transferencias = EXCLUDED.diferencia_transferencias,
    veredicto_transferencias = EXCLUDED.veredicto_transferencias
  RETURNING id INTO v_postcorte_id;

  RETURN v_postcorte_id;
END;
$$;


ALTER FUNCTION selemti.fn_generar_postcorte(p_sesion_id bigint) OWNER TO postgres;

--
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION selemti.fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- Name: fn_item_unit_cost_at(bigint, timestamp without time zone, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_item_unit_cost_at(p_item_id bigint, p_at timestamp without time zone, p_target_uom text) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_price    numeric;
  v_pack_qty numeric;
  v_pack_uom text;
  v_factor   numeric;
BEGIN
  SELECT price, pack_qty, pack_uom
    INTO v_price, v_pack_qty, v_pack_uom
  FROM selemti.item_vendor_prices
  WHERE item_id = p_item_id
    AND effective_from <= p_at
    AND (effective_to IS NULL OR effective_to > p_at)
  ORDER BY effective_from DESC
  LIMIT 1;

  IF v_price IS NULL THEN
    RETURN NULL;
  END IF;

  v_factor := selemti.fn_uom_factor(v_pack_uom, p_target_uom);
  RETURN (v_price / NULLIF(v_pack_qty,0)) * v_factor;
END$$;


ALTER FUNCTION selemti.fn_item_unit_cost_at(p_item_id bigint, p_at timestamp without time zone, p_target_uom text) OWNER TO postgres;

--
-- Name: fn_ivp_upsert_close_prev(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_ivp_upsert_close_prev() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE selemti.item_vendor_prices
     SET effective_to = NEW.effective_from
   WHERE item_id=NEW.item_id
     AND vendor_id=NEW.vendor_id
     AND effective_to IS NULL
     AND effective_from < NEW.effective_from;
  RETURN NEW;
END$$;


ALTER FUNCTION selemti.fn_ivp_upsert_close_prev() OWNER TO postgres;

--
-- Name: fn_normalizar_forma_pago(text, text, text, text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_normalizar_forma_pago(p_payment_type text, p_transaction_type text, p_payment_sub_type text, p_custom_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE pt TEXT := upper(coalesce(p_payment_type,''));
DECLARE cn TEXT := selemti.fn_slug(p_custom_name);
BEGIN
  IF pt IN ('CASH','CREDIT','DEBIT','TRANSFER') THEN
    RETURN pt;
  ELSIF pt = 'CUSTOM_PAYMENT' THEN
    IF cn IS NOT NULL THEN RETURN 'CUSTOM:'||cn; ELSE RETURN 'CUSTOM'; END IF;
  ELSIF pt IN ('REFUND','PAY_OUT','CASH_DROP') THEN
    RETURN pt; -- egresos/ajustes estandarizados
  ELSE
    RETURN pt;
  END IF;
END $$;


ALTER FUNCTION selemti.fn_normalizar_forma_pago(p_payment_type text, p_transaction_type text, p_payment_sub_type text, p_custom_name text) OWNER TO floreant;

--
-- Name: fn_postcorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_postcorte_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'CERRADA',
      cierre_ts = COALESCE(cierre_ts, now())
  WHERE id = NEW.sesion_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.fn_postcorte_after_insert() OWNER TO postgres;

--
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION selemti.fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- Name: fn_precorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_precorte_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'EN_CORTE'
  WHERE id = NEW.sesion_id
    AND estatus = 'LISTO_PARA_CORTE';
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.fn_precorte_after_insert() OWNER TO postgres;

--
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION selemti.fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- Name: fn_precorte_after_update_aprobado(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_precorte_after_update_aprobado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_postcorte_id BIGINT;
BEGIN
  IF NEW.estatus = 'APROBADO' AND OLD.estatus != 'APROBADO' THEN
    -- Generar postcorte automÃ¡ticamente
    SELECT selemti.fn_generar_postcorte(NEW.sesion_id) INTO v_postcorte_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.fn_precorte_after_update_aprobado() OWNER TO postgres;

--
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION selemti.fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- Name: fn_precorte_efectivo_bi(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_precorte_efectivo_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.subtotal := COALESCE(NEW.denominacion,0) * COALESCE(NEW.cantidad,0);
  RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_precorte_efectivo_bi() OWNER TO floreant;

--
-- Name: fn_recipe_cost_at(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_recipe_cost_at(p_recipe_id bigint, p_at timestamp without time zone) RETURNS TABLE(batch_cost numeric, portion_cost numeric, batch_size numeric, yield_portions numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_rv_id bigint;
  v_bcost numeric := 0;
  v_bs    numeric := 1;
  v_y     numeric := 1;
  r record;
BEGIN
  SELECT id INTO v_rv_id
    FROM selemti.recipe_versions
   WHERE recipe_id = p_recipe_id
     AND valid_from <= p_at
     AND (valid_to IS NULL OR valid_to > p_at)
   ORDER BY valid_from DESC LIMIT 1;

  IF v_rv_id IS NULL THEN RETURN; END IF;

  SELECT COALESCE(r.batch_size,1), COALESCE(r.yield_portions,1)
    INTO v_bs, v_y
    FROM selemti.recipes r WHERE r.id = p_recipe_id;

  FOR r IN
     SELECT item_id, qty, uom_receta
     FROM selemti.recipe_version_items
     WHERE recipe_version_id = v_rv_id
  LOOP
     v_bcost := v_bcost + COALESCE(
       selemti.fn_item_unit_cost_at(r.item_id, p_at, r.uom_receta) * r.qty, 0
     );
  END LOOP;

  batch_cost := v_bcost;
  batch_size := v_bs;
  yield_portions := NULLIF(v_y,0);
  portion_cost := CASE WHEN v_y IS NULL OR v_y=0 THEN NULL ELSE v_bcost / v_y END;
  RETURN NEXT;
END$$;


ALTER FUNCTION selemti.fn_recipe_cost_at(p_recipe_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- Name: fn_recipes_using_item(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_recipes_using_item(p_item_id bigint, p_at timestamp without time zone) RETURNS TABLE(recipe_id bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT rv.recipe_id
    FROM selemti.recipe_versions rv
    JOIN selemti.recipe_version_items rvi ON rvi.recipe_version_id = rv.id
    WHERE rvi.item_id = p_item_id
      AND rv.valid_from <= p_at
      AND (rv.valid_to IS NULL OR rv.valid_to > p_at);
END$$;


ALTER FUNCTION selemti.fn_recipes_using_item(p_item_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- Name: fn_reparar_sesion_apertura(integer, integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_reparar_sesion_apertura(p_terminal_id integer, p_usuario integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE v_term RECORD;
BEGIN
  IF EXISTS (
    SELECT 1 FROM selemti.sesion_cajon
    WHERE terminal_id=p_terminal_id AND cajero_usuario_id=p_usuario AND cierre_ts IS NULL
  ) THEN
    RETURN 'YA_EXISTE_SESION_ABIERTA';
  END IF;

  SELECT * INTO v_term FROM public.terminal WHERE id=p_terminal_id;
  IF v_term IS NULL THEN RETURN 'TERMINAL_NO_ENCONTRADA'; END IF;

  INSERT INTO selemti.sesion_cajon(
    terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
    apertura_ts, estatus, opening_float
  ) VALUES (
    p_terminal_id, COALESCE(v_term.name,'Terminal '||p_terminal_id), COALESCE(v_term.location,''),
    p_usuario, now(), 'ACTIVA', COALESCE(v_term.current_balance,0)
  );
  RETURN 'CREADA';
END $$;


ALTER FUNCTION selemti.fn_reparar_sesion_apertura(p_terminal_id integer, p_usuario integer) OWNER TO floreant;

--
-- Name: fn_reversar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass('selemti.mov_inv') IS NOT NULL, false);
BEGIN
    IF NOT v_has_mov THEN
        RETURN;
    END IF;

    SELECT t.sucursal_id INTO v_sucursal
    FROM public.ticket t
    WHERE t.id = _ticket_id;

    IF v_sucursal IS NULL THEN
        RETURN;
    END IF;

    SELECT a.id INTO v_almacen
    FROM selemti.cat_almacenes a
    WHERE a.sucursal_id = v_sucursal AND COALESCE(a.es_principal, false) = true
    ORDER BY a.id
    LIMIT 1;

    IF v_almacen IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO selemti.mov_inv
        (item_id, inventory_batch_id, tipo, qty, uom, sucursal_id, sucursal_dest, almacen_id, ref_tipo, ref_id, user_id, ts, meta, notas, created_at, updated_at)
    SELECT
        d.item_id,
        NULL,
        'AJUSTE',
        SUM(d.cantidad),
        COALESCE(d.uom, 'UN'),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        'POS_TICKET_REV',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object('ticket_id', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = 'CONFIRMADO'
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = 'ANULADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'CONFIRMADO';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'REVERSE', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- Name: fn_slug(text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_slug(in_text text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE s TEXT := lower(coalesce(in_text,''));
BEGIN
  s := translate(s, 'ÁÉÍÓÚÜÑáéíóúüñ', 'AEIOUUNaeiouun');
  s := regexp_replace(s, '[^a-z0-9]+', '-', 'g');
  s := regexp_replace(s, '(^-|-$)', '', 'g');
  IF s = '' THEN RETURN NULL; END IF;
  RETURN s;
END $_$;


ALTER FUNCTION selemti.fn_slug(in_text text) OWNER TO floreant;

--
-- Name: fn_terminal_bu_snapshot_cierre(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_terminal_bu_snapshot_cierre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_has_old boolean := (OLD.assigned_user IS NOT NULL);
  v_has_new boolean := (NEW.assigned_user IS NOT NULL);
BEGIN
  /* CIERRE: había cajero y ahora ya no */
  IF (v_has_old AND NOT v_has_new) THEN
    UPDATE selemti.sesion_cajon AS sc
       SET cierre_ts      = now(),
           estatus        = 'LISTO_PARA_CORTE',
           closing_float  = COALESCE(OLD.current_balance, 0),
           -- bandera: true si NO hubo precorte para esta sesión
           skipped_precorte = NOT EXISTS (
             SELECT 1
             FROM selemti.precorte p
             WHERE p.sesion_id = sc.id
           )
     WHERE sc.terminal_id       = OLD.id
       AND sc.cajero_usuario_id = OLD.assigned_user
       AND sc.cierre_ts         IS NULL;
  END IF;

  /* APERTURA: no había cajero y ahora sí */
  IF (NOT v_has_old AND v_has_new) THEN
    INSERT INTO selemti.sesion_cajon(
      terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
      apertura_ts, estatus, opening_float, dah_evento_id, skipped_precorte
    )
    VALUES(
      NEW.id,
      COALESCE(NEW.name, 'Terminal '||NEW.id),
      COALESCE(NEW.location, ''),
      NEW.assigned_user,
      now(),
      'ACTIVA',
      COALESCE(NEW.current_balance, 0),
      NULL,
      FALSE  -- por defecto, en apertura no está saltado
    );
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_terminal_bu_snapshot_cierre() OWNER TO floreant;

--
-- Name: fn_tx_after_insert_forma_pago(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION selemti.fn_tx_after_insert_forma_pago() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_codigo TEXT;
BEGIN
  v_codigo := selemti.fn_normalizar_forma_pago(
    NEW.payment_type, NEW.transaction_type, NEW.payment_sub_type, NEW.custom_payment_name
  );
  INSERT INTO selemti.formas_pago(
    codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref
  )
  VALUES (
    v_codigo, NEW.payment_type, NEW.transaction_type, NEW.payment_sub_type, NEW.custom_payment_name, NEW.custom_payment_ref
  )
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_tx_after_insert_forma_pago() OWNER TO floreant;

--
-- Name: fn_uom_factor(text, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.fn_uom_factor(from_uom text, to_uom text) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE v numeric := 1;
BEGIN
  IF from_uom IS NULL OR to_uom IS NULL OR lower(from_uom)=lower(to_uom) THEN
    RETURN 1;
  END IF;
  SELECT factor INTO v
    FROM selemti.cat_uom_conversion
   WHERE lower(from_uom)=lower($1) AND lower(to_uom)=lower($2)
   LIMIT 1;
  IF v IS NULL THEN
    RAISE EXCEPTION 'No hay conversión de % -> %', from_uom, to_uom;
  END IF;
  RETURN v;
END$_$;


ALTER FUNCTION selemti.fn_uom_factor(from_uom text, to_uom text) OWNER TO postgres;

--
-- Name: inferir_recetas_de_ventas(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_recetas_inferidas INTEGER := 0;
v_plato_record RECORD;
BEGIN
    IF p_fecha_hasta IS NULL THEN
        p_fecha_hasta := CURRENT_DATE;
END IF;
FOR v_plato_record IN 
        SELECT DISTINCT td.item_id, COUNT(*) as total_ventas
        FROM selemti.ticket_venta_det td
        JOIN selemti.ticket_venta_cab tc ON td.ticket_id = tc.id
        WHERE tc.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
          AND td.receta_shadow_id IS NULL
        GROUP BY td.item_id
        HAVING COUNT(*) >= 5
    LOOP
        INSERT INTO selemti.receta_shadow (codigo_plato_pos, nombre_plato, total_ventas_analizadas, fecha_primer_venta, fecha_ultima_venta)
        VALUES (v_plato_record.item_id, 'Inferida_' || v_plato_record.item_id, v_plato_record.total_ventas, p_fecha_desde, p_fecha_hasta);
v_recetas_inferidas := v_recetas_inferidas + 1;
END LOOP;
RETURN v_recetas_inferidas;
END;
$$;


ALTER FUNCTION selemti.inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date) OWNER TO postgres;

--
-- Name: ingesta_ticket(bigint, integer, integer, bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM 1;
  RETURN;
END;
$$;


ALTER FUNCTION selemti.ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) OWNER TO postgres;

--
-- Name: recalcular_costos_periodo(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.recalcular_costos_periodo(p_desde date, p_hasta date DEFAULT ('now'::text)::date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_cnt INT := 0; BEGIN
  WITH sub AS (
    SELECT
      COALESCE( (row_to_json(mi)->>'insumo_id')::bigint,
                (row_to_json(mi)->>'item_id')::bigint ) AS k_item,
      (row_to_json(mi)->>'costo_unit')::numeric AS costo_unit,
      COALESCE((row_to_json(mi)->>'qty')::numeric,
               (row_to_json(mi)->>'cantidad')::numeric) AS q,
      (row_to_json(mi)->>'tipo')::text AS tipo,
      mi.ts::date AS d
    FROM selemti.mov_inv mi
    WHERE mi.ts::date BETWEEN p_desde AND p_hasta
  )
  INSERT INTO selemti.hist_cost_insumo (insumo_id, fecha_efectiva, costo_wac, algoritmo_principal)
  SELECT s.k_item, p_desde,
         CASE WHEN SUM(CASE WHEN s.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN','ENTRADA') THEN (s.costo_unit * s.q) ELSE 0 END) <> 0
              THEN SUM(CASE WHEN s.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN','ENTRADA') THEN (s.costo_unit * s.q) ELSE 0 END)
                   / NULLIF(SUM(CASE WHEN s.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN','ENTRADA') THEN s.q ELSE 0 END),0)
              ELSE NULL END,
         'WAC'
  FROM sub s
  WHERE s.k_item IS NOT NULL
  GROUP BY s.k_item
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS v_cnt = ROW_COUNT; RETURN v_cnt; END; $$;


ALTER FUNCTION selemti.recalcular_costos_periodo(p_desde date, p_hasta date) OWNER TO postgres;

--
-- Name: refresh_materialized_views(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.refresh_materialized_views() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_inventario_actual;
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_recetas_costos;
    RAISE NOTICE 'Vistas materializadas actualizadas exitosamente';
END;
$$;


ALTER FUNCTION selemti.refresh_materialized_views() OWNER TO postgres;

--
-- Name: registrar_consumo_porcionado(bigint, bigint, text, numeric, json); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  r JSON;
v_count INT := 0;
BEGIN
  FOR r IN SELECT * FROM json_array_elements(p_distribucion)
  LOOP
    INSERT INTO selemti.ticket_det_consumo(
      ticket_id, ticket_det_id, item_id, lote_id, qty_canonica, ref_tipo, ref_id
    )
    VALUES (
      p_ticket_id, p_ticket_det_id, p_item_id, NULL,
      (r->>'qty_ml')::NUMERIC,
      'PORCION', p_ticket_det_id
    );
v_count := v_count + 1;
END LOOP;
RETURN v_count;

END
$$;


ALTER FUNCTION selemti.registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) OWNER TO postgres;

--
-- Name: reprocesar_costos_historicos(date, date, character varying, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date, p_algoritmo character varying DEFAULT 'WAC'::character varying, p_usuario_id integer DEFAULT 1) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_total_actualizados INTEGER := 0;
  v_item_record RECORD;
BEGIN
  IF p_fecha_hasta IS NULL THEN
    p_fecha_hasta := CURRENT_DATE;
  END IF;

  FOR v_item_record IN
    SELECT DISTINCT item_id
    FROM selemti.mov_inv
    WHERE ts BETWEEN p_fecha_desde AND p_fecha_hasta
  LOOP
    UPDATE selemti.historial_costos_item
    SET costo_wac = (
      SELECT CASE WHEN SUM(cantidad) IS NULL OR SUM(cantidad)=0 THEN NULL
                  ELSE AVG(costo_unit * cantidad) / NULLIF(SUM(cantidad),0) END
      FROM selemti.mov_inv mv
      WHERE mv.item_id = v_item_record.item_id
        AND mv.ts BETWEEN p_fecha_desde AND p_fecha_hasta
        AND mv.tipo IN ('COMPRA','RECEPCION','ENTRADA')
    )
    WHERE item_id = v_item_record.item_id
      AND fecha_efectiva BETWEEN p_fecha_desde AND p_fecha_hasta;

    v_total_actualizados := v_total_actualizados + 1;
  END LOOP;

  RETURN v_total_actualizados;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'reprocesar_costos_historicos fallo: %', SQLERRM;
  RETURN COALESCE(v_total_actualizados, 0);
END;
$$;


ALTER FUNCTION selemti.reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date, p_algoritmo character varying, p_usuario_id integer) OWNER TO postgres;

--
-- Name: set_timestamp_ipp(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.set_timestamp_ipp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.set_timestamp_ipp() OWNER TO postgres;

--
-- Name: sp_snapshot_recipe_cost(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp without time zone) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_batch numeric; v_portion numeric; v_bs numeric; v_y numeric;
  v_rv_id bigint;
BEGIN
  SELECT id INTO v_rv_id
    FROM selemti.recipe_versions
   WHERE recipe_id = p_recipe_id
     AND valid_from <= p_at
     AND (valid_to IS NULL OR valid_to > p_at)
   ORDER BY valid_from DESC LIMIT 1;

  SELECT batch_cost, portion_cost, batch_size, yield_portions
    INTO v_batch, v_portion, v_bs, v_y
    FROM selemti.fn_recipe_cost_at(p_recipe_id, p_at);

  INSERT INTO selemti.recipe_cost_history(recipe_id, recipe_version_id, snapshot_at, batch_cost, portion_cost, batch_size, yield_portions)
  VALUES (p_recipe_id, v_rv_id, p_at, v_batch, v_portion, v_bs, v_y);
END$$;


ALTER FUNCTION selemti.sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- Name: tg_invshot_autofill(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.tg_invshot_autofill() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      NEW.valor_teorico := COALESCE(NEW.teorico_qty,0) * COALESCE(NEW.teorico_cost,0);
      IF NEW.fisico_qty IS NOT NULL THEN
        NEW.variance_qty  := COALESCE(NEW.fisico_qty,0) - COALESCE(NEW.teorico_qty,0);
        NEW.variance_cost := COALESCE(NEW.variance_qty,0) * COALESCE(NEW.teorico_cost,0);
      END IF;
      NEW.updated_at := now();
      RETURN NEW;
    END
    $$;


ALTER FUNCTION selemti.tg_invshot_autofill() OWNER TO postgres;

--
-- Name: trg_ticket_inventory_consumption(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.trg_ticket_inventory_consumption() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.paid = true AND NEW.voided = false THEN
        PERFORM selemti.fn_expandir_consumo_ticket(NEW.id);
        PERFORM selemti.fn_confirmar_consumo_ticket(NEW.id);
    ELSIF NEW.voided = true THEN
        PERFORM selemti.fn_reversar_consumo_ticket(NEW.id);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.trg_ticket_inventory_consumption() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION selemti.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: action_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.action_history (
    id integer NOT NULL,
    action_time timestamp without time zone,
    action_name character varying(255),
    description character varying(255),
    user_id integer
);


ALTER TABLE public.action_history OWNER TO floreant;

--
-- Name: action_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.action_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.action_history_id_seq OWNER TO floreant;

--
-- Name: action_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.action_history_id_seq OWNED BY public.action_history.id;


--
-- Name: attendence_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.attendence_history (
    id integer NOT NULL,
    clock_in_time timestamp without time zone,
    clock_out_time timestamp without time zone,
    clock_in_hour smallint,
    clock_out_hour smallint,
    clocked_out boolean,
    user_id integer,
    shift_id integer,
    terminal_id integer
);


ALTER TABLE public.attendence_history OWNER TO floreant;

--
-- Name: attendence_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.attendence_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendence_history_id_seq OWNER TO floreant;

--
-- Name: attendence_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.attendence_history_id_seq OWNED BY public.attendence_history.id;


--
-- Name: cash_drawer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.cash_drawer (
    id integer NOT NULL,
    terminal_id integer
);


ALTER TABLE public.cash_drawer OWNER TO floreant;

--
-- Name: cash_drawer_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.cash_drawer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cash_drawer_id_seq OWNER TO floreant;

--
-- Name: cash_drawer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.cash_drawer_id_seq OWNED BY public.cash_drawer.id;


--
-- Name: cash_drawer_reset_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.cash_drawer_reset_history (
    id integer NOT NULL,
    reset_time timestamp without time zone,
    user_id integer
);


ALTER TABLE public.cash_drawer_reset_history OWNER TO floreant;

--
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.cash_drawer_reset_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cash_drawer_reset_history_id_seq OWNER TO floreant;

--
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.cash_drawer_reset_history_id_seq OWNED BY public.cash_drawer_reset_history.id;


--
-- Name: cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.cooking_instruction (
    id integer NOT NULL,
    description character varying(60)
);


ALTER TABLE public.cooking_instruction OWNER TO floreant;

--
-- Name: cooking_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.cooking_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cooking_instruction_id_seq OWNER TO floreant;

--
-- Name: cooking_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.cooking_instruction_id_seq OWNED BY public.cooking_instruction.id;


--
-- Name: coupon_and_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.coupon_and_discount (
    id integer NOT NULL,
    name character varying(120),
    type integer,
    barcode character varying(120),
    qualification_type integer,
    apply_to_all boolean,
    minimum_buy integer,
    maximum_off integer,
    value double precision,
    expiry_date timestamp without time zone,
    enabled boolean,
    auto_apply boolean,
    modifiable boolean,
    never_expire boolean,
    uuid character varying(36)
);


ALTER TABLE public.coupon_and_discount OWNER TO floreant;

--
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.coupon_and_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.coupon_and_discount_id_seq OWNER TO floreant;

--
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.coupon_and_discount_id_seq OWNED BY public.coupon_and_discount.id;


--
-- Name: currency; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.currency (
    id integer NOT NULL,
    code character varying(20),
    name character varying(30),
    symbol character varying(10),
    exchange_rate double precision,
    decimal_places integer,
    tolerance double precision,
    buy_price double precision,
    sales_price double precision,
    main boolean
);


ALTER TABLE public.currency OWNER TO floreant;

--
-- Name: currency_balance; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.currency_balance (
    id integer NOT NULL,
    balance double precision,
    currency_id integer,
    cash_drawer_id integer,
    dpr_id integer
);


ALTER TABLE public.currency_balance OWNER TO floreant;

--
-- Name: currency_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.currency_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_balance_id_seq OWNER TO floreant;

--
-- Name: currency_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.currency_balance_id_seq OWNED BY public.currency_balance.id;


--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_id_seq OWNER TO floreant;

--
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.currency_id_seq OWNED BY public.currency.id;


--
-- Name: custom_payment; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.custom_payment (
    id integer NOT NULL,
    name character varying(60),
    required_ref_number boolean,
    ref_number_field_name character varying(60)
);


ALTER TABLE public.custom_payment OWNER TO floreant;

--
-- Name: custom_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.custom_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_payment_id_seq OWNER TO floreant;

--
-- Name: custom_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.custom_payment_id_seq OWNED BY public.custom_payment.id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.customer (
    auto_id integer NOT NULL,
    loyalty_no character varying(30),
    loyalty_point integer,
    social_security_number character varying(60),
    picture bytea,
    homephone_no character varying(30),
    mobile_no character varying(30),
    workphone_no character varying(30),
    email character varying(40),
    salutation character varying(60),
    first_name character varying(60),
    last_name character varying(60),
    name character varying(120),
    dob character varying(16),
    ssn character varying(30),
    address character varying(220),
    city character varying(30),
    state character varying(30),
    zip_code character varying(10),
    country character varying(30),
    vip boolean,
    credit_limit double precision,
    credit_spent double precision,
    credit_card_no character varying(30),
    note character varying(255)
);


ALTER TABLE public.customer OWNER TO floreant;

--
-- Name: customer_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.customer_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_auto_id_seq OWNER TO floreant;

--
-- Name: customer_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.customer_auto_id_seq OWNED BY public.customer.auto_id;


--
-- Name: customer_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.customer_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.customer_properties OWNER TO floreant;

--
-- Name: daily_folio_counter; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.daily_folio_counter (
    folio_date date NOT NULL,
    branch_key text NOT NULL,
    last_value integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.daily_folio_counter OWNER TO floreant;

--
-- Name: data_update_info; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.data_update_info (
    id integer NOT NULL,
    last_update_time timestamp without time zone
);


ALTER TABLE public.data_update_info OWNER TO floreant;

--
-- Name: data_update_info_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.data_update_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_update_info_id_seq OWNER TO floreant;

--
-- Name: data_update_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.data_update_info_id_seq OWNED BY public.data_update_info.id;


--
-- Name: delivery_address; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.delivery_address (
    id integer NOT NULL,
    address character varying(320),
    phone_extension character varying(10),
    room_no character varying(30),
    distance double precision,
    customer_id integer
);


ALTER TABLE public.delivery_address OWNER TO floreant;

--
-- Name: delivery_address_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.delivery_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_address_id_seq OWNER TO floreant;

--
-- Name: delivery_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.delivery_address_id_seq OWNED BY public.delivery_address.id;


--
-- Name: delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.delivery_charge (
    id integer NOT NULL,
    name character varying(220),
    zip_code character varying(20),
    start_range double precision,
    end_range double precision,
    charge_amount double precision
);


ALTER TABLE public.delivery_charge OWNER TO floreant;

--
-- Name: delivery_charge_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.delivery_charge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_charge_id_seq OWNER TO floreant;

--
-- Name: delivery_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.delivery_charge_id_seq OWNED BY public.delivery_charge.id;


--
-- Name: delivery_configuration; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.delivery_configuration (
    id integer NOT NULL,
    unit_name character varying(20),
    unit_symbol character varying(8),
    charge_by_zip_code boolean
);


ALTER TABLE public.delivery_configuration OWNER TO floreant;

--
-- Name: delivery_configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.delivery_configuration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_configuration_id_seq OWNER TO floreant;

--
-- Name: delivery_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.delivery_configuration_id_seq OWNED BY public.delivery_configuration.id;


--
-- Name: delivery_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.delivery_instruction (
    id integer NOT NULL,
    notes character varying(220),
    customer_no integer
);


ALTER TABLE public.delivery_instruction OWNER TO floreant;

--
-- Name: delivery_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.delivery_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_instruction_id_seq OWNER TO floreant;

--
-- Name: delivery_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.delivery_instruction_id_seq OWNED BY public.delivery_instruction.id;


--
-- Name: drawer_assigned_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.drawer_assigned_history (
    id integer NOT NULL,
    "time" timestamp without time zone,
    operation character varying(60),
    a_user integer
);


ALTER TABLE public.drawer_assigned_history OWNER TO floreant;

--
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.drawer_assigned_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.drawer_assigned_history_id_seq OWNER TO floreant;

--
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.drawer_assigned_history_id_seq OWNED BY public.drawer_assigned_history.id;


--
-- Name: drawer_pull_report; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.drawer_pull_report (
    id integer NOT NULL,
    report_time timestamp without time zone,
    reg character varying(15),
    ticket_count integer,
    begin_cash double precision,
    net_sales double precision,
    sales_tax double precision,
    cash_tax double precision,
    total_revenue double precision,
    gross_receipts double precision,
    giftcertreturncount integer,
    giftcertreturnamount double precision,
    giftcertchangeamount double precision,
    cash_receipt_no integer,
    cash_receipt_amount double precision,
    credit_card_receipt_no integer,
    credit_card_receipt_amount double precision,
    debit_card_receipt_no integer,
    debit_card_receipt_amount double precision,
    refund_receipt_count integer,
    refund_amount double precision,
    receipt_differential double precision,
    cash_back double precision,
    cash_tips double precision,
    charged_tips double precision,
    tips_paid double precision,
    tips_differential double precision,
    pay_out_no integer,
    pay_out_amount double precision,
    drawer_bleed_no integer,
    drawer_bleed_amount double precision,
    drawer_accountable double precision,
    cash_to_deposit double precision,
    variance double precision,
    delivery_charge double precision,
    totalvoidwst double precision,
    totalvoid double precision,
    totaldiscountcount integer,
    totaldiscountamount double precision,
    totaldiscountsales double precision,
    totaldiscountguest integer,
    totaldiscountpartysize integer,
    totaldiscountchecksize integer,
    totaldiscountpercentage double precision,
    totaldiscountratio double precision,
    user_id integer,
    terminal_id integer
);


ALTER TABLE public.drawer_pull_report OWNER TO floreant;

--
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.drawer_pull_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.drawer_pull_report_id_seq OWNER TO floreant;

--
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.drawer_pull_report_id_seq OWNED BY public.drawer_pull_report.id;


--
-- Name: drawer_pull_report_voidtickets; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.drawer_pull_report_voidtickets (
    dpreport_id integer NOT NULL,
    code integer,
    reason character varying(255),
    hast character varying(255),
    quantity integer,
    amount double precision
);


ALTER TABLE public.drawer_pull_report_voidtickets OWNER TO floreant;

--
-- Name: employee_in_out_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.employee_in_out_history (
    id integer NOT NULL,
    out_time timestamp without time zone,
    in_time timestamp without time zone,
    out_hour smallint,
    in_hour smallint,
    clock_out boolean,
    user_id integer,
    shift_id integer,
    terminal_id integer
);


ALTER TABLE public.employee_in_out_history OWNER TO floreant;

--
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.employee_in_out_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_in_out_history_id_seq OWNER TO floreant;

--
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.employee_in_out_history_id_seq OWNED BY public.employee_in_out_history.id;


--
-- Name: global_config; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.global_config (
    id integer NOT NULL,
    pos_key character varying(60),
    pos_value character varying(220)
);


ALTER TABLE public.global_config OWNER TO floreant;

--
-- Name: global_config_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.global_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.global_config_id_seq OWNER TO floreant;

--
-- Name: global_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.global_config_id_seq OWNED BY public.global_config.id;


--
-- Name: gratuity; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.gratuity (
    id integer NOT NULL,
    amount double precision,
    paid boolean,
    refunded boolean,
    ticket_id integer,
    owner_id integer,
    terminal_id integer
);


ALTER TABLE public.gratuity OWNER TO floreant;

--
-- Name: gratuity_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.gratuity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gratuity_id_seq OWNER TO floreant;

--
-- Name: gratuity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.gratuity_id_seq OWNED BY public.gratuity.id;


--
-- Name: group_taxes; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.group_taxes (
    group_id character varying(128) NOT NULL,
    elt integer NOT NULL
);


ALTER TABLE public.group_taxes OWNER TO floreant;

--
-- Name: guest_check_print; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.guest_check_print (
    id integer NOT NULL,
    ticket_id integer,
    table_no character varying(255),
    ticket_total double precision,
    print_time timestamp without time zone,
    user_id integer
);


ALTER TABLE public.guest_check_print OWNER TO floreant;

--
-- Name: guest_check_print_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.guest_check_print_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guest_check_print_id_seq OWNER TO floreant;

--
-- Name: guest_check_print_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.guest_check_print_id_seq OWNED BY public.guest_check_print.id;


--
-- Name: inventory_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE public.inventory_group OWNER TO floreant;

--
-- Name: inventory_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_group_id_seq OWNER TO floreant;

--
-- Name: inventory_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_group_id_seq OWNED BY public.inventory_group.id;


--
-- Name: inventory_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_item (
    id integer NOT NULL,
    create_time timestamp without time zone,
    last_update_date timestamp without time zone,
    name character varying(60),
    package_barcode character varying(30),
    unit_barcode character varying(30),
    unit_per_package double precision,
    sort_order integer,
    package_reorder_level integer,
    package_replenish_level integer,
    description character varying(255),
    average_package_price double precision,
    total_unit_packages double precision,
    total_recepie_units double precision,
    unit_purchase_price double precision,
    unit_selling_price double precision,
    visible boolean,
    punit_id integer,
    recipe_unit_id integer,
    item_group_id integer,
    item_location_id integer,
    item_vendor_id integer,
    total_packages integer
);


ALTER TABLE public.inventory_item OWNER TO floreant;

--
-- Name: inventory_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_item_id_seq OWNER TO floreant;

--
-- Name: inventory_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_item_id_seq OWNED BY public.inventory_item.id;


--
-- Name: inventory_location; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_location (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    sort_order integer,
    visible boolean,
    warehouse_id integer
);


ALTER TABLE public.inventory_location OWNER TO floreant;

--
-- Name: inventory_location_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_location_id_seq OWNER TO floreant;

--
-- Name: inventory_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_location_id_seq OWNED BY public.inventory_location.id;


--
-- Name: inventory_meta_code; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_meta_code (
    id integer NOT NULL,
    type character varying(255),
    code_text character varying(255),
    code_no integer,
    description character varying(255)
);


ALTER TABLE public.inventory_meta_code OWNER TO floreant;

--
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_meta_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_meta_code_id_seq OWNER TO floreant;

--
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_meta_code_id_seq OWNED BY public.inventory_meta_code.id;


--
-- Name: inventory_transaction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_transaction (
    id integer NOT NULL,
    transaction_date timestamp without time zone,
    unit_quantity double precision,
    unit_price double precision,
    remark character varying(255),
    tran_type integer,
    reference_id integer,
    item_id integer,
    vendor_id integer,
    from_warehouse_id integer,
    to_warehouse_id integer,
    quantity integer
);


ALTER TABLE public.inventory_transaction OWNER TO floreant;

--
-- Name: inventory_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_transaction_id_seq OWNER TO floreant;

--
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_transaction_id_seq OWNED BY public.inventory_transaction.id;


--
-- Name: inventory_unit; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_unit (
    id integer NOT NULL,
    short_name character varying(255),
    long_name character varying(255),
    alt_name character varying(255),
    conv_factor1 character varying(255),
    conv_factor2 character varying(255),
    conv_factor3 character varying(255)
);


ALTER TABLE public.inventory_unit OWNER TO floreant;

--
-- Name: inventory_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_unit_id_seq OWNER TO floreant;

--
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_unit_id_seq OWNED BY public.inventory_unit.id;


--
-- Name: inventory_vendor; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_vendor (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean,
    address character varying(120) NOT NULL,
    city character varying(60) NOT NULL,
    state character varying(60) NOT NULL,
    zip character varying(60) NOT NULL,
    country character varying(60) NOT NULL,
    email character varying(60) NOT NULL,
    phone character varying(60) NOT NULL,
    fax character varying(60)
);


ALTER TABLE public.inventory_vendor OWNER TO floreant;

--
-- Name: inventory_vendor_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_vendor_id_seq OWNER TO floreant;

--
-- Name: inventory_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_vendor_id_seq OWNED BY public.inventory_vendor.id;


--
-- Name: inventory_warehouse; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.inventory_warehouse (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE public.inventory_warehouse OWNER TO floreant;

--
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.inventory_warehouse_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_warehouse_id_seq OWNER TO floreant;

--
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.inventory_warehouse_id_seq OWNED BY public.inventory_warehouse.id;


--
-- Name: item_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.item_order_type (
    menu_item_id integer NOT NULL,
    order_type_id integer NOT NULL
);


ALTER TABLE public.item_order_type OWNER TO floreant;

--
-- Name: kitchen_ticket; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.kitchen_ticket (
    id integer NOT NULL,
    ticket_id integer,
    create_date timestamp without time zone,
    close_date timestamp without time zone,
    voided boolean,
    sequence_number integer,
    status character varying(30),
    server_name character varying(30),
    ticket_type character varying(20),
    pg_id integer
);


ALTER TABLE public.kitchen_ticket OWNER TO floreant;

--
-- Name: terminal; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.terminal (
    id integer NOT NULL,
    name character varying(60),
    terminal_key character varying(120),
    opening_balance double precision,
    current_balance double precision,
    has_cash_drawer boolean,
    in_use boolean,
    active boolean,
    location character varying(320),
    floor_id integer,
    assigned_user integer
);


ALTER TABLE public.terminal OWNER TO floreant;

--
-- Name: ticket; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket (
    id integer NOT NULL,
    global_id character varying(16),
    create_date timestamp without time zone,
    closing_date timestamp without time zone,
    active_date timestamp without time zone,
    deliveery_date timestamp without time zone,
    creation_hour integer,
    paid boolean,
    voided boolean,
    void_reason character varying(255),
    wasted boolean,
    refunded boolean,
    settled boolean,
    drawer_resetted boolean,
    sub_total double precision,
    total_discount double precision,
    total_tax double precision,
    total_price double precision,
    paid_amount double precision,
    due_amount double precision,
    advance_amount double precision,
    adjustment_amount double precision,
    number_of_guests integer,
    status character varying(30),
    bar_tab boolean,
    is_tax_exempt boolean,
    is_re_opened boolean,
    service_charge double precision,
    delivery_charge double precision,
    customer_id integer,
    delivery_address character varying(120),
    customer_pickeup boolean,
    delivery_extra_info character varying(255),
    ticket_type character varying(20),
    shift_id integer,
    owner_id integer,
    driver_id integer,
    gratuity_id integer,
    void_by_user integer,
    terminal_id integer,
    folio_date date,
    branch_key text,
    daily_folio integer,
    CONSTRAINT ck_ticket_daily_folio_positive CHECK (((daily_folio IS NULL) OR (daily_folio > 0)))
);


ALTER TABLE public.ticket OWNER TO floreant;

--
-- Name: kds_orders_enhanced; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.kds_orders_enhanced AS
 SELECT kt.id AS kitchen_ticket_id,
    kt.ticket_id,
    kt.create_date AS kds_created_at,
    kt.sequence_number,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    lpad((t.daily_folio)::text, 4, '0'::text) AS folio_display,
    t.number_of_guests,
    t.ticket_type,
    term.name AS terminal_name,
        CASE
            WHEN ((t.daily_folio >= 1) AND (t.daily_folio <= 20)) THEN 'PRIORITARIO'::text
            WHEN ((t.daily_folio >= 21) AND (t.daily_folio <= 50)) THEN 'NORMAL'::text
            ELSE 'ALTO_VOLUMEN'::text
        END AS prioridad_voceo
   FROM ((public.kitchen_ticket kt
     JOIN public.ticket t ON ((t.id = kt.ticket_id)))
     LEFT JOIN public.terminal term ON ((t.terminal_id = term.id)));


ALTER TABLE public.kds_orders_enhanced OWNER TO postgres;

--
-- Name: kds_ready_log; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.kds_ready_log (
    ticket_id integer NOT NULL,
    notified_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.kds_ready_log OWNER TO floreant;

--
-- Name: kit_ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.kit_ticket_table_num (
    kit_ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE public.kit_ticket_table_num OWNER TO floreant;

--
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.kitchen_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.kitchen_ticket_id_seq OWNER TO floreant;

--
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.kitchen_ticket_id_seq OWNED BY public.kitchen_ticket.id;


--
-- Name: kitchen_ticket_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.kitchen_ticket_item (
    id integer NOT NULL,
    cookable boolean,
    ticket_item_id integer NOT NULL,
    ticket_item_modifier_id integer,
    menu_item_code character varying(255),
    menu_item_name character varying(120),
    menu_item_group_id integer,
    menu_item_group_name character varying(120),
    quantity integer,
    fractional_quantity double precision,
    fractional_unit boolean,
    unit_name character varying(20),
    sort_order integer,
    voided boolean,
    status character varying(30),
    kithen_ticket_id integer,
    item_order integer
);


ALTER TABLE public.kitchen_ticket_item OWNER TO floreant;

--
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.kitchen_ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.kitchen_ticket_item_id_seq OWNER TO floreant;

--
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.kitchen_ticket_item_id_seq OWNED BY public.kitchen_ticket_item.id;


--
-- Name: menu_category; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_category (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    translated_name character varying(120),
    visible boolean,
    beverage boolean,
    sort_order integer,
    btn_color integer,
    text_color integer
);


ALTER TABLE public.menu_category OWNER TO floreant;

--
-- Name: menu_category_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_category_id_seq OWNER TO floreant;

--
-- Name: menu_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_category_id_seq OWNED BY public.menu_category.id;


--
-- Name: menu_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_group (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    translated_name character varying(120),
    visible boolean,
    sort_order integer,
    btn_color integer,
    text_color integer,
    category_id integer
);


ALTER TABLE public.menu_group OWNER TO floreant;

--
-- Name: menu_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_group_id_seq OWNER TO floreant;

--
-- Name: menu_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_group_id_seq OWNED BY public.menu_group.id;


--
-- Name: menu_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_item (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    description character varying(255),
    unit_name character varying(20),
    translated_name character varying(120),
    barcode character varying(120),
    buy_price double precision NOT NULL,
    stock_amount double precision,
    price double precision NOT NULL,
    discount_rate double precision,
    visible boolean,
    disable_when_stock_amount_is_zero boolean,
    sort_order integer,
    btn_color integer,
    text_color integer,
    image bytea,
    show_image_only boolean,
    fractional_unit boolean,
    pizza_type boolean,
    default_sell_portion integer,
    group_id integer,
    tax_group_id character varying(128),
    recepie integer,
    pg_id integer,
    tax_id integer
);


ALTER TABLE public.menu_item OWNER TO floreant;

--
-- Name: menu_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_id_seq OWNER TO floreant;

--
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_item_id_seq OWNED BY public.menu_item.id;


--
-- Name: menu_item_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_item_properties (
    menu_item_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.menu_item_properties OWNER TO floreant;

--
-- Name: menu_item_size; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_item_size (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    description character varying(120),
    sort_order integer,
    size_in_inch double precision,
    default_size boolean
);


ALTER TABLE public.menu_item_size OWNER TO floreant;

--
-- Name: menu_item_size_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_item_size_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_size_id_seq OWNER TO floreant;

--
-- Name: menu_item_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_item_size_id_seq OWNED BY public.menu_item_size.id;


--
-- Name: menu_item_terminal_ref; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_item_terminal_ref (
    menu_item_id integer NOT NULL,
    terminal_id integer NOT NULL
);


ALTER TABLE public.menu_item_terminal_ref OWNER TO floreant;

--
-- Name: menu_modifier; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_modifier (
    id integer NOT NULL,
    name character varying(120),
    translated_name character varying(120),
    price double precision,
    extra_price double precision,
    sort_order integer,
    btn_color integer,
    text_color integer,
    enable boolean,
    fixed_price boolean,
    print_to_kitchen boolean,
    section_wise_pricing boolean,
    pizza_modifier boolean,
    group_id integer,
    tax_id integer
);


ALTER TABLE public.menu_modifier OWNER TO floreant;

--
-- Name: menu_modifier_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_modifier_group (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    enabled boolean,
    exclusived boolean,
    required boolean
);


ALTER TABLE public.menu_modifier_group OWNER TO floreant;

--
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_modifier_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_modifier_group_id_seq OWNER TO floreant;

--
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_modifier_group_id_seq OWNED BY public.menu_modifier_group.id;


--
-- Name: menu_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menu_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_modifier_id_seq OWNER TO floreant;

--
-- Name: menu_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menu_modifier_id_seq OWNED BY public.menu_modifier.id;


--
-- Name: menu_modifier_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menu_modifier_properties (
    menu_modifier_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.menu_modifier_properties OWNER TO floreant;

--
-- Name: menucategory_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menucategory_discount (
    discount_id integer NOT NULL,
    menucategory_id integer NOT NULL
);


ALTER TABLE public.menucategory_discount OWNER TO floreant;

--
-- Name: menugroup_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menugroup_discount (
    discount_id integer NOT NULL,
    menugroup_id integer NOT NULL
);


ALTER TABLE public.menugroup_discount OWNER TO floreant;

--
-- Name: menuitem_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menuitem_discount (
    discount_id integer NOT NULL,
    menuitem_id integer NOT NULL
);


ALTER TABLE public.menuitem_discount OWNER TO floreant;

--
-- Name: menuitem_modifiergroup; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menuitem_modifiergroup (
    id integer NOT NULL,
    min_quantity integer,
    max_quantity integer,
    sort_order integer,
    modifier_group integer,
    menuitem_modifiergroup_id integer
);


ALTER TABLE public.menuitem_modifiergroup OWNER TO floreant;

--
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menuitem_modifiergroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menuitem_modifiergroup_id_seq OWNER TO floreant;

--
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menuitem_modifiergroup_id_seq OWNED BY public.menuitem_modifiergroup.id;


--
-- Name: menuitem_pizzapirce; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menuitem_pizzapirce (
    menu_item_id integer NOT NULL,
    pizza_price_id integer NOT NULL
);


ALTER TABLE public.menuitem_pizzapirce OWNER TO floreant;

--
-- Name: menuitem_shift; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menuitem_shift (
    id integer NOT NULL,
    shift_price double precision,
    shift_id integer,
    menuitem_id integer
);


ALTER TABLE public.menuitem_shift OWNER TO floreant;

--
-- Name: menuitem_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.menuitem_shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menuitem_shift_id_seq OWNER TO floreant;

--
-- Name: menuitem_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.menuitem_shift_id_seq OWNED BY public.menuitem_shift.id;


--
-- Name: menumodifier_pizzamodifierprice; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.menumodifier_pizzamodifierprice (
    menumodifier_id integer NOT NULL,
    pizzamodifierprice_id integer NOT NULL
);


ALTER TABLE public.menumodifier_pizzamodifierprice OWNER TO floreant;

--
-- Name: modifier_multiplier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.modifier_multiplier_price (
    id integer NOT NULL,
    price double precision,
    multiplier_id character varying(20),
    menumodifier_id integer,
    pizza_modifier_price_id integer
);


ALTER TABLE public.modifier_multiplier_price OWNER TO floreant;

--
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.modifier_multiplier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modifier_multiplier_price_id_seq OWNER TO floreant;

--
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.modifier_multiplier_price_id_seq OWNED BY public.modifier_multiplier_price.id;


--
-- Name: multiplier; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.multiplier (
    name character varying(20) NOT NULL,
    ticket_prefix character varying(20),
    rate double precision,
    sort_order integer,
    default_multiplier boolean,
    main boolean,
    btn_color integer,
    text_color integer
);


ALTER TABLE public.multiplier OWNER TO floreant;

--
-- Name: online_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.online_order (
    id character varying(128) NOT NULL,
    version_no bigint NOT NULL,
    last_update_time timestamp without time zone,
    last_sync_time timestamp without time zone,
    order_date timestamp without time zone,
    cust_id character varying(128),
    store_id character varying(128),
    store_schema character varying(128),
    store_name character varying(128),
    outlet_id character varying(128),
    ticket_id character varying(128),
    order_type character varying(128),
    order_status character varying(128),
    paid boolean,
    settled boolean,
    expiry_date timestamp without time zone,
    source character varying(128),
    ticket_json text,
    properties text
);


ALTER TABLE public.online_order OWNER TO postgres;

--
-- Name: order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.order_type (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    enabled boolean,
    show_table_selection boolean,
    show_guest_selection boolean,
    should_print_to_kitchen boolean,
    prepaid boolean,
    close_on_paid boolean,
    required_customer_data boolean,
    delivery boolean,
    show_item_barcode boolean,
    show_in_login_screen boolean,
    consolidate_tiems_in_receipt boolean,
    allow_seat_based_order boolean,
    hide_item_with_empty_inventory boolean,
    has_forhere_and_togo boolean,
    pre_auth_credit_card boolean,
    bar_tab boolean,
    retail_order boolean,
    show_price_on_button boolean,
    show_stock_count_on_button boolean,
    show_unit_price_in_ticket_grid boolean,
    properties text
);


ALTER TABLE public.order_type OWNER TO floreant;

--
-- Name: order_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.order_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_type_id_seq OWNER TO floreant;

--
-- Name: order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.order_type_id_seq OWNED BY public.order_type.id;


--
-- Name: packaging_unit; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.packaging_unit (
    id integer NOT NULL,
    name character varying(30),
    short_name character varying(10),
    factor double precision,
    baseunit boolean,
    dimension character varying(30)
);


ALTER TABLE public.packaging_unit OWNER TO floreant;

--
-- Name: packaging_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.packaging_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.packaging_unit_id_seq OWNER TO floreant;

--
-- Name: packaging_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.packaging_unit_id_seq OWNED BY public.packaging_unit.id;


--
-- Name: payout_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.payout_reasons (
    id integer NOT NULL,
    reason character varying(255)
);


ALTER TABLE public.payout_reasons OWNER TO floreant;

--
-- Name: payout_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.payout_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payout_reasons_id_seq OWNER TO floreant;

--
-- Name: payout_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.payout_reasons_id_seq OWNED BY public.payout_reasons.id;


--
-- Name: payout_recepients; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.payout_recepients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.payout_recepients OWNER TO floreant;

--
-- Name: payout_recepients_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.payout_recepients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payout_recepients_id_seq OWNER TO floreant;

--
-- Name: payout_recepients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.payout_recepients_id_seq OWNED BY public.payout_recepients.id;


--
-- Name: pizza_crust; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.pizza_crust (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    description character varying(120),
    sort_order integer,
    default_crust boolean
);


ALTER TABLE public.pizza_crust OWNER TO floreant;

--
-- Name: pizza_crust_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.pizza_crust_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pizza_crust_id_seq OWNER TO floreant;

--
-- Name: pizza_crust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.pizza_crust_id_seq OWNED BY public.pizza_crust.id;


--
-- Name: pizza_modifier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.pizza_modifier_price (
    id integer NOT NULL,
    item_size integer
);


ALTER TABLE public.pizza_modifier_price OWNER TO floreant;

--
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.pizza_modifier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pizza_modifier_price_id_seq OWNER TO floreant;

--
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.pizza_modifier_price_id_seq OWNED BY public.pizza_modifier_price.id;


--
-- Name: pizza_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.pizza_price (
    id integer NOT NULL,
    price double precision,
    menu_item_size integer,
    crust integer,
    order_type integer
);


ALTER TABLE public.pizza_price OWNER TO floreant;

--
-- Name: pizza_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.pizza_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pizza_price_id_seq OWNER TO floreant;

--
-- Name: pizza_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.pizza_price_id_seq OWNED BY public.pizza_price.id;


--
-- Name: printer_configuration; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.printer_configuration (
    id integer NOT NULL,
    receipt_printer character varying(255),
    kitchen_printer character varying(255),
    prwts boolean,
    prwtp boolean,
    pkwts boolean,
    pkwtp boolean,
    unpft boolean,
    unpfk boolean
);


ALTER TABLE public.printer_configuration OWNER TO floreant;

--
-- Name: printer_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.printer_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    is_default boolean
);


ALTER TABLE public.printer_group OWNER TO floreant;

--
-- Name: printer_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.printer_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.printer_group_id_seq OWNER TO floreant;

--
-- Name: printer_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.printer_group_id_seq OWNED BY public.printer_group.id;


--
-- Name: printer_group_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.printer_group_printers (
    printer_id integer NOT NULL,
    printer_name character varying(255)
);


ALTER TABLE public.printer_group_printers OWNER TO floreant;

--
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.purchase_order (
    id integer NOT NULL,
    order_id character varying(30),
    name character varying(30)
);


ALTER TABLE public.purchase_order OWNER TO floreant;

--
-- Name: purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.purchase_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_order_id_seq OWNER TO floreant;

--
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.purchase_order_id_seq OWNED BY public.purchase_order.id;


--
-- Name: recepie; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.recepie (
    id integer NOT NULL,
    menu_item integer
);


ALTER TABLE public.recepie OWNER TO floreant;

--
-- Name: recepie_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.recepie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.recepie_id_seq OWNER TO floreant;

--
-- Name: recepie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.recepie_id_seq OWNED BY public.recepie.id;


--
-- Name: recepie_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.recepie_item (
    id integer NOT NULL,
    percentage double precision,
    inventory_deductable boolean,
    inventory_item integer,
    recepie_id integer
);


ALTER TABLE public.recepie_item OWNER TO floreant;

--
-- Name: recepie_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.recepie_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.recepie_item_id_seq OWNER TO floreant;

--
-- Name: recepie_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.recepie_item_id_seq OWNED BY public.recepie_item.id;


--
-- Name: restaurant; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.restaurant (
    id integer NOT NULL,
    unique_id integer,
    name character varying(120),
    address_line1 character varying(60),
    address_line2 character varying(60),
    address_line3 character varying(60),
    zip_code character varying(10),
    telephone character varying(16),
    capacity integer,
    tables integer,
    cname character varying(20),
    csymbol character varying(10),
    sc_percentage double precision,
    gratuity_percentage double precision,
    ticket_footer character varying(60),
    price_includes_tax boolean,
    allow_modifier_max_exceed boolean,
    uuid character varying(128)
);


ALTER TABLE public.restaurant OWNER TO floreant;

--
-- Name: restaurant_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.restaurant_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.restaurant_properties OWNER TO floreant;

--
-- Name: shift; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shift (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    shift_len bigint
);


ALTER TABLE public.shift OWNER TO floreant;

--
-- Name: shift_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_id_seq OWNER TO floreant;

--
-- Name: shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.shift_id_seq OWNED BY public.shift.id;


--
-- Name: shop_floor; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_floor (
    id integer NOT NULL,
    name character varying(60),
    occupied boolean,
    image oid
);


ALTER TABLE public.shop_floor OWNER TO floreant;

--
-- Name: shop_floor_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.shop_floor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_floor_id_seq OWNER TO floreant;

--
-- Name: shop_floor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.shop_floor_id_seq OWNED BY public.shop_floor.id;


--
-- Name: shop_floor_template; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_floor_template (
    id integer NOT NULL,
    name character varying(60),
    default_floor boolean,
    main boolean,
    floor_id integer
);


ALTER TABLE public.shop_floor_template OWNER TO floreant;

--
-- Name: shop_floor_template_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.shop_floor_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_floor_template_id_seq OWNER TO floreant;

--
-- Name: shop_floor_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.shop_floor_template_id_seq OWNED BY public.shop_floor_template.id;


--
-- Name: shop_floor_template_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_floor_template_properties (
    id integer NOT NULL,
    property_value character varying(60),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.shop_floor_template_properties OWNER TO floreant;

--
-- Name: shop_table; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_table (
    id integer NOT NULL,
    name character varying(20),
    description character varying(60),
    capacity integer,
    x integer,
    y integer,
    floor_id integer,
    free boolean,
    serving boolean,
    booked boolean,
    dirty boolean,
    disable boolean
);


ALTER TABLE public.shop_table OWNER TO floreant;

--
-- Name: shop_table_status; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_table_status (
    id integer NOT NULL,
    table_status integer
);


ALTER TABLE public.shop_table_status OWNER TO floreant;

--
-- Name: shop_table_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.shop_table_type (
    id integer NOT NULL,
    description character varying(120),
    name character varying(40)
);


ALTER TABLE public.shop_table_type OWNER TO floreant;

--
-- Name: shop_table_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.shop_table_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_table_type_id_seq OWNER TO floreant;

--
-- Name: shop_table_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.shop_table_type_id_seq OWNED BY public.shop_table_type.id;


--
-- Name: table_booking_info; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.table_booking_info (
    id integer NOT NULL,
    from_date timestamp without time zone,
    to_date timestamp without time zone,
    guest_count integer,
    status character varying(30),
    payment_status character varying(30),
    booking_confirm character varying(30),
    booking_charge double precision,
    remaining_balance double precision,
    paid_amount double precision,
    booking_id character varying(30),
    booking_type character varying(30),
    user_id integer,
    customer_id integer
);


ALTER TABLE public.table_booking_info OWNER TO floreant;

--
-- Name: table_booking_info_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.table_booking_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.table_booking_info_id_seq OWNER TO floreant;

--
-- Name: table_booking_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.table_booking_info_id_seq OWNED BY public.table_booking_info.id;


--
-- Name: table_booking_mapping; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.table_booking_mapping (
    booking_id integer NOT NULL,
    table_id integer NOT NULL
);


ALTER TABLE public.table_booking_mapping OWNER TO floreant;

--
-- Name: table_ticket_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.table_ticket_num (
    shop_table_status_id integer NOT NULL,
    ticket_id integer,
    user_id integer,
    user_name character varying(30)
);


ALTER TABLE public.table_ticket_num OWNER TO floreant;

--
-- Name: table_type_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.table_type_relation (
    table_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE public.table_type_relation OWNER TO floreant;

--
-- Name: tax; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.tax (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    rate double precision
);


ALTER TABLE public.tax OWNER TO floreant;

--
-- Name: tax_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.tax_group (
    id character varying(128) NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE public.tax_group OWNER TO floreant;

--
-- Name: tax_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.tax_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tax_id_seq OWNER TO floreant;

--
-- Name: tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.tax_id_seq OWNED BY public.tax.id;


--
-- Name: terminal_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.terminal_printers (
    id integer NOT NULL,
    terminal_id integer,
    printer_name character varying(60),
    virtual_printer_id integer
);


ALTER TABLE public.terminal_printers OWNER TO floreant;

--
-- Name: terminal_printers_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.terminal_printers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.terminal_printers_id_seq OWNER TO floreant;

--
-- Name: terminal_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.terminal_printers_id_seq OWNED BY public.terminal_printers.id;


--
-- Name: terminal_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.terminal_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.terminal_properties OWNER TO floreant;

--
-- Name: ticket_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_discount (
    id integer NOT NULL,
    discount_id integer,
    name character varying(30),
    type integer,
    auto_apply boolean,
    minimum_amount integer,
    value double precision,
    ticket_id integer
);


ALTER TABLE public.ticket_discount OWNER TO floreant;

--
-- Name: ticket_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.ticket_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ticket_discount_id_seq OWNER TO floreant;

--
-- Name: ticket_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.ticket_discount_id_seq OWNED BY public.ticket_discount.id;


--
-- Name: ticket_folio_complete; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ticket_folio_complete AS
 SELECT t.id,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    t.total_price,
    t.paid_amount,
    t.create_date,
    to_char((t.folio_date)::timestamp with time zone, 'DD/MM/YYYY'::text) AS folio_date_txt,
    lpad((t.daily_folio)::text, 4, '0'::text) AS folio_display,
    COALESCE(term.location, 'DEFAULT'::character varying) AS sucursal_completa,
    term.name AS terminal_name,
    to_char((t.folio_date)::timestamp with time zone, 'YYYY-MM'::text) AS periodo_mes,
    date_part('hour'::text, t.create_date) AS hora_venta,
    date_part('dow'::text, t.folio_date) AS dia_semana,
        CASE
            WHEN t.voided THEN 'CANCELADO'::text
            WHEN (t.paid_amount > (0)::double precision) THEN 'PAGADO'::text
            ELSE 'PENDIENTE'::text
        END AS status_simple
   FROM (public.ticket t
     LEFT JOIN public.terminal term ON ((t.terminal_id = term.id)));


ALTER TABLE public.ticket_folio_complete OWNER TO postgres;

--
-- Name: ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ticket_id_seq OWNER TO floreant;

--
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;


--
-- Name: ticket_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item (
    id integer NOT NULL,
    item_id integer,
    item_count integer,
    item_quantity double precision,
    item_name character varying(120),
    item_unit_name character varying(20),
    group_name character varying(120),
    category_name character varying(120),
    item_price double precision,
    item_tax_rate double precision,
    sub_total double precision,
    sub_total_without_modifiers double precision,
    discount double precision,
    tax_amount double precision,
    tax_amount_without_modifiers double precision,
    total_price double precision,
    total_price_without_modifiers double precision,
    beverage boolean,
    inventory_handled boolean,
    print_to_kitchen boolean,
    treat_as_seat boolean,
    seat_number integer,
    fractional_unit boolean,
    has_modiiers boolean,
    printed_to_kitchen boolean,
    status character varying(255),
    stock_amount_adjusted boolean,
    pizza_type boolean,
    size_modifier_id integer,
    ticket_id integer,
    pg_id integer,
    pizza_section_mode integer
);


ALTER TABLE public.ticket_item OWNER TO floreant;

--
-- Name: ticket_item_addon_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item_addon_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE public.ticket_item_addon_relation OWNER TO floreant;

--
-- Name: ticket_item_cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item_cooking_instruction (
    ticket_item_id integer NOT NULL,
    description character varying(60),
    printedtokitchen boolean,
    item_order integer NOT NULL
);


ALTER TABLE public.ticket_item_cooking_instruction OWNER TO floreant;

--
-- Name: ticket_item_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item_discount (
    id integer NOT NULL,
    discount_id integer,
    name character varying(30),
    type integer,
    auto_apply boolean,
    minimum_quantity integer,
    value double precision,
    amount double precision,
    ticket_itemid integer
);


ALTER TABLE public.ticket_item_discount OWNER TO floreant;

--
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.ticket_item_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ticket_item_discount_id_seq OWNER TO floreant;

--
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.ticket_item_discount_id_seq OWNED BY public.ticket_item_discount.id;


--
-- Name: ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ticket_item_id_seq OWNER TO floreant;

--
-- Name: ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.ticket_item_id_seq OWNED BY public.ticket_item.id;


--
-- Name: ticket_item_modifier; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item_modifier (
    id integer NOT NULL,
    item_id integer,
    group_id integer,
    item_count integer,
    modifier_name character varying(120),
    modifier_price double precision,
    modifier_tax_rate double precision,
    modifier_type integer,
    subtotal_price double precision,
    total_price double precision,
    tax_amount double precision,
    info_only boolean,
    section_name character varying(20),
    multiplier_name character varying(20),
    print_to_kitchen boolean,
    section_wise_pricing boolean,
    status character varying(10),
    printed_to_kitchen boolean,
    ticket_item_id integer
);


ALTER TABLE public.ticket_item_modifier OWNER TO floreant;

--
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.ticket_item_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ticket_item_modifier_id_seq OWNER TO floreant;

--
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.ticket_item_modifier_id_seq OWNED BY public.ticket_item_modifier.id;


--
-- Name: ticket_item_modifier_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_item_modifier_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE public.ticket_item_modifier_relation OWNER TO floreant;

--
-- Name: ticket_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.ticket_properties OWNER TO floreant;

--
-- Name: ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.ticket_table_num (
    ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE public.ticket_table_num OWNER TO floreant;

--
-- Name: transaction_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.transaction_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE public.transaction_properties OWNER TO floreant;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    payment_type character varying(30) NOT NULL,
    global_id character varying(16),
    transaction_time timestamp without time zone,
    amount double precision,
    tips_amount double precision,
    tips_exceed_amount double precision,
    tender_amount double precision,
    transaction_type character varying(30) NOT NULL,
    custom_payment_name character varying(60),
    custom_payment_ref character varying(120),
    custom_payment_field_name character varying(60),
    payment_sub_type character varying(40) NOT NULL,
    captured boolean,
    voided boolean,
    authorizable boolean,
    card_holder_name character varying(60),
    card_number character varying(40),
    card_auth_code character varying(30),
    card_type character varying(20),
    card_transaction_id character varying(255),
    card_merchant_gateway character varying(60),
    card_reader character varying(30),
    card_aid character varying(120),
    card_arqc character varying(120),
    card_ext_data character varying(255),
    gift_cert_number character varying(64),
    gift_cert_face_value double precision,
    gift_cert_paid_amount double precision,
    gift_cert_cash_back_amount double precision,
    drawer_resetted boolean,
    note character varying(255),
    terminal_id integer,
    ticket_id integer,
    user_id integer,
    payout_reason_id integer,
    payout_recepient_id integer
);


ALTER TABLE public.transactions OWNER TO floreant;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_id_seq OWNER TO floreant;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.user_permission (
    name character varying(40) NOT NULL
);


ALTER TABLE public.user_permission OWNER TO floreant;

--
-- Name: user_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.user_type (
    id integer NOT NULL,
    p_name character varying(60)
);


ALTER TABLE public.user_type OWNER TO floreant;

--
-- Name: user_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.user_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_type_id_seq OWNER TO floreant;

--
-- Name: user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.user_type_id_seq OWNED BY public.user_type.id;


--
-- Name: user_user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.user_user_permission (
    permissionid integer NOT NULL,
    elt character varying(40) NOT NULL
);


ALTER TABLE public.user_user_permission OWNER TO floreant;

--
-- Name: users; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.users (
    auto_id integer NOT NULL,
    user_id integer,
    user_pass character varying(16) NOT NULL,
    first_name character varying(30),
    last_name character varying(30),
    ssn character varying(30),
    cost_per_hour double precision,
    clocked_in boolean,
    last_clock_in_time timestamp without time zone,
    last_clock_out_time timestamp without time zone,
    phone_no character varying(20),
    is_driver boolean,
    available_for_delivery boolean,
    active boolean,
    shift_id integer,
    currentterminal integer,
    n_user_type integer
);


ALTER TABLE public.users OWNER TO floreant;

--
-- Name: users_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.users_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_auto_id_seq OWNER TO floreant;

--
-- Name: users_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.users_auto_id_seq OWNED BY public.users.auto_id;


--
-- Name: virtual_printer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.virtual_printer (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    type integer,
    priority integer,
    enabled boolean
);


ALTER TABLE public.virtual_printer OWNER TO floreant;

--
-- Name: virtual_printer_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.virtual_printer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.virtual_printer_id_seq OWNER TO floreant;

--
-- Name: virtual_printer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.virtual_printer_id_seq OWNED BY public.virtual_printer.id;


--
-- Name: virtualprinter_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.virtualprinter_order_type (
    printer_id integer NOT NULL,
    order_type character varying(255)
);


ALTER TABLE public.virtualprinter_order_type OWNER TO floreant;

--
-- Name: void_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.void_reasons (
    id integer NOT NULL,
    reason_text character varying(255)
);


ALTER TABLE public.void_reasons OWNER TO floreant;

--
-- Name: void_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.void_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.void_reasons_id_seq OWNER TO floreant;

--
-- Name: void_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.void_reasons_id_seq OWNED BY public.void_reasons.id;


--
-- Name: vw_daily_diagnostics_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_daily_diagnostics_summary AS
 SELECT f_daily_diagnostics_summary_on.source_view,
    f_daily_diagnostics_summary_on.severity,
    f_daily_diagnostics_summary_on.rows
   FROM public.f_daily_diagnostics_summary_on(('now'::text)::date) f_daily_diagnostics_summary_on(source_view, severity, rows);


ALTER TABLE public.vw_daily_diagnostics_summary OWNER TO postgres;

--
-- Name: vw_diag_discount_header_vs_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_discount_header_vs_lines AS
 WITH line_disc AS (
         SELECT ti.ticket_id,
            round((sum(COALESCE(ti.discount, (0)::double precision)))::numeric, 2) AS sum_line_disc
           FROM public.ticket_item ti
          GROUP BY ti.ticket_id
        )
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    round((COALESCE(t.total_discount, (0)::double precision))::numeric, 2) AS hdr_discount,
    COALESCE(ld.sum_line_disc, (0)::numeric) AS sum_line_disc,
    round((((COALESCE(ld.sum_line_disc, (0)::numeric))::double precision - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS diff,
    'DISCOUNT_MISMATCH'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (public.ticket t
     LEFT JOIN line_disc ld ON ((ld.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (abs(round((((COALESCE(ld.sum_line_disc, (0)::numeric))::double precision - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2)) > 0.01));


ALTER TABLE public.vw_diag_discount_header_vs_lines OWNER TO postgres;

--
-- Name: vw_diag_drawer_vs_cash_transactions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_drawer_vs_cash_transactions AS
 SELECT t.terminal_id,
    (t.original_total_revenue)::numeric(12,2) AS original_total_revenue,
    (t.corrected_neto_tickets)::numeric(12,2) AS corrected_neto_tickets,
    (t.adjustment)::numeric(12,2) AS adjustment,
    (t.cash_in)::numeric(12,2) AS cash_in,
    (t.non_cash_in)::numeric(12,2) AS non_cash_in,
    (t.expected_cash)::numeric(12,2) AS expected_cash,
    (t.diff)::numeric(12,2) AS diff,
    t.error_code,
    t.severity
   FROM public.f_diag_drawer_vs_cash_transactions_on(('now'::text)::date) t(terminal_id, original_total_revenue, corrected_neto_tickets, adjustment, cash_in, non_cash_in, expected_cash, diff, error_code, severity);


ALTER TABLE public.vw_diag_drawer_vs_cash_transactions OWNER TO postgres;

--
-- Name: vw_diag_folio_date_inconsistency; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_folio_date_inconsistency AS
 SELECT t.id AS ticket_id,
    t.folio_date,
    (t.closing_date)::date AS closed_date,
    (t.create_date)::date AS created_date,
    'FOLIO_DATE_MISMATCH'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM public.ticket t
  WHERE ((t.paid = true) AND (t.voided = false) AND (t.folio_date IS DISTINCT FROM (t.closing_date)::date) AND (t.folio_date IS DISTINCT FROM (t.create_date)::date));


ALTER TABLE public.vw_diag_folio_date_inconsistency OWNER TO postgres;

--
-- Name: vw_diag_high_discounts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_high_discounts AS
 SELECT COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    t.id AS ticket_id,
    round((COALESCE(t.total_price, (0)::double precision))::numeric, 2) AS total_bruto,
    round((COALESCE(t.total_discount, (0)::double precision))::numeric, 2) AS total_descuento,
    round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS total_neto,
    'HIGH_DISCOUNT'::text AS error_code,
    'WARN'::text AS severity
   FROM public.ticket t
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(t.total_discount, (0)::double precision) >= (COALESCE(t.total_price, (0)::double precision) * (0.30)::double precision)));


ALTER TABLE public.vw_diag_high_discounts OWNER TO postgres;

--
-- Name: vw_diag_neto_vs_cobros; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_neto_vs_cobros AS
 WITH tx AS (
         SELECT transactions.ticket_id,
            round((sum(
                CASE
                    WHEN ((transactions.voided = false) AND (upper((transactions.transaction_type)::text) = 'CREDIT'::text) AND ((transactions.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(transactions.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_sum
           FROM public.transactions
          GROUP BY transactions.ticket_id
        ), base AS (
         SELECT t.id AS ticket_id,
            COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
            t.branch_key,
            round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS net_ticket,
            COALESCE(tx.paid_sum, (0)::numeric) AS paid_sum,
            round((((COALESCE(tx.paid_sum, (0)::numeric))::double precision - (COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))))::numeric, 2) AS diff
           FROM (public.ticket t
             LEFT JOIN tx ON ((tx.ticket_id = t.id)))
          WHERE ((t.paid = true) AND (t.voided = false))
        )
 SELECT base.ticket_id,
    base.folio_date,
    base.branch_key,
    base.net_ticket,
    base.paid_sum,
    base.diff,
    'PAYMENT_VS_NET_MISMATCH'::text AS error_code,
        CASE
            WHEN (abs(base.diff) > (1)::numeric) THEN 'CRITICAL'::text
            ELSE 'WARN'::text
        END AS severity
   FROM base
  WHERE (abs(base.diff) > 0.01);


ALTER TABLE public.vw_diag_neto_vs_cobros OWNER TO postgres;

--
-- Name: vw_diag_orphans_tickets; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_orphans_tickets AS
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    'ORPHAN_TICKET'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (public.ticket t
     LEFT JOIN public.transactions tx ON (((tx.ticket_id = t.id) AND (tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text))))
  WHERE ((t.paid = true) AND (t.voided = false) AND (tx.ticket_id IS NULL));


ALTER TABLE public.vw_diag_orphans_tickets OWNER TO postgres;

--
-- Name: vw_diag_orphans_tx; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_orphans_tx AS
 SELECT tx.id,
    tx.ticket_id,
    round((COALESCE(tx.amount, (0)::double precision))::numeric, 2) AS amount,
    'ORPHAN_TX'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (public.transactions tx
     LEFT JOIN public.ticket t ON ((t.id = tx.ticket_id)))
  WHERE ((t.id IS NULL) AND (tx.voided = false));


ALTER TABLE public.vw_diag_orphans_tx OWNER TO postgres;

--
-- Name: vw_diag_pagos_egresos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_pagos_egresos AS
 SELECT transactions.terminal_id,
    round((sum(transactions.amount))::numeric, 2) AS egresos,
    'NON_SALES_CASHFLOW'::text AS error_code,
    'WARN'::text AS severity
   FROM public.transactions
  WHERE (((transactions.payment_type)::text = ANY (ARRAY[('REFUND'::character varying)::text, ('PAY_OUT'::character varying)::text, ('CASH_DROP'::character varying)::text])) AND (transactions.voided = false))
  GROUP BY transactions.terminal_id;


ALTER TABLE public.vw_diag_pagos_egresos OWNER TO postgres;

--
-- Name: vw_diag_paid_but_no_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_paid_but_no_payments AS
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS neto,
    'PAID_WITHOUT_TX'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (public.ticket t
     LEFT JOIN public.transactions tx ON (((tx.ticket_id = t.id) AND (tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text))))
  WHERE ((t.paid = true) AND (t.voided = false) AND (tx.ticket_id IS NULL) AND ((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)) > (0.01)::double precision));


ALTER TABLE public.vw_diag_paid_but_no_payments OWNER TO postgres;

--
-- Name: vw_diag_service_charge_vs_paid; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_service_charge_vs_paid AS
 WITH svc_tx AS (
         SELECT transactions.ticket_id,
            sum(
                CASE
                    WHEN ((selemti.fn_normalizar_forma_pago((transactions.payment_type)::text, (transactions.transaction_type)::text, (transactions.payment_sub_type)::text, (transactions.custom_payment_name)::text) = 'CARGO_SERVICIO'::text) AND (transactions.voided = false)) THEN COALESCE(transactions.amount, (0)::double precision)
                    ELSE (0)::double precision
                END) AS paid_svc
           FROM public.transactions
          GROUP BY transactions.ticket_id
        )
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    round((COALESCE(t.service_charge, (0)::double precision))::numeric, 2) AS declared,
    round((COALESCE(s.paid_svc, (0)::double precision))::numeric, 2) AS paid,
    round((abs((COALESCE(s.paid_svc, (0)::double precision) - COALESCE(t.service_charge, (0)::double precision))))::numeric, 2) AS diff,
    'SERVICE_CHARGE_MISMATCH'::text AS error_code,
        CASE
            WHEN (abs((COALESCE(s.paid_svc, (0)::double precision) - COALESCE(t.service_charge, (0)::double precision))) > (1)::double precision) THEN 'CRITICAL'::text
            ELSE 'WARN'::text
        END AS severity
   FROM (public.ticket t
     LEFT JOIN svc_tx s ON ((s.ticket_id = t.id)))
  WHERE (abs((COALESCE(s.paid_svc, (0)::double precision) - COALESCE(t.service_charge, (0)::double precision))) > (0.01)::double precision);


ALTER TABLE public.vw_diag_service_charge_vs_paid OWNER TO postgres;

--
-- Name: vw_diag_unnormalized_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diag_unnormalized_payments AS
 SELECT DISTINCT (COALESCE(transactions.payment_type, ''::character varying))::text AS payment_type,
    (COALESCE(transactions.transaction_type, ''::character varying))::text AS transaction_type,
    (COALESCE(transactions.payment_sub_type, ''::character varying))::text AS payment_sub_type,
    (COALESCE(transactions.custom_payment_name, ''::character varying))::text AS custom_payment_name,
    'UNNORMALIZED_PAYMENT'::text AS error_code,
    'WARN'::text AS severity
   FROM public.transactions
  WHERE ((transactions.voided = false) AND (selemti.fn_normalizar_forma_pago((transactions.payment_type)::text, (transactions.transaction_type)::text, (transactions.payment_sub_type)::text, (transactions.custom_payment_name)::text) IS NULL));


ALTER TABLE public.vw_diag_unnormalized_payments OWNER TO postgres;

--
-- Name: vw_discounts_daily; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_discounts_daily AS
 SELECT t.folio_date,
    t.branch_key,
    term.location AS sucursal,
    term.name AS terminal,
    count(*) AS tickets_con_desc,
    round((sum(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS descuento_total,
    round((avg(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS descuento_prom_ticket
   FROM (public.ticket t
     JOIN public.terminal term ON ((term.id = t.terminal_id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(t.total_discount, (0)::double precision) > (0)::double precision))
  GROUP BY t.folio_date, t.branch_key, term.location, term.name;


ALTER TABLE public.vw_discounts_daily OWNER TO postgres;

--
-- Name: vw_discounts_detail_line; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_discounts_detail_line AS
 SELECT t.folio_date,
    t.branch_key,
    term.location AS sucursal,
    term.name AS terminal,
    t.id AS ticket_id,
    ti.id AS ticket_item_id,
    ti.item_name,
    round((COALESCE(ti.total_price, (0)::double precision))::numeric, 2) AS line_total_bruto,
    round((COALESCE(ti.discount, (0)::double precision))::numeric, 2) AS line_descuento,
    round(((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision)))::numeric, 2) AS line_neto,
    NULL::unknown AS discount_name
   FROM ((public.ticket t
     JOIN public.terminal term ON ((term.id = t.terminal_id)))
     JOIN public.ticket_item ti ON ((ti.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(ti.discount, (0)::double precision) > (0)::double precision));


ALTER TABLE public.vw_discounts_detail_line OWNER TO postgres;

--
-- Name: vw_item_mods_daily_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_item_mods_daily_summary AS
 SELECT f_item_mods_on.folio_date,
    f_item_mods_on.branch_key,
    f_item_mods_on.item_name,
    f_item_mods_on.modifier_name,
    sum(f_item_mods_on.qty_item) AS qty_items,
    (sum(f_item_mods_on.mods_count))::bigint AS times_selected,
    round(sum(f_item_mods_on.mods_total_amount), 2) AS total_mods_amount
   FROM public.f_item_mods_on(('now'::text)::date) f_item_mods_on(folio_date, branch_key, terminal_id, ticket_id, ticket_item_id, item_name, modifier_name, qty_item, mods_count, mods_total_amount)
  GROUP BY f_item_mods_on.folio_date, f_item_mods_on.branch_key, f_item_mods_on.item_name, f_item_mods_on.modifier_name
  ORDER BY f_item_mods_on.branch_key, f_item_mods_on.item_name, f_item_mods_on.modifier_name;


ALTER TABLE public.vw_item_mods_daily_summary OWNER TO postgres;

--
-- Name: vw_item_mods_by_item_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_item_mods_by_item_today AS
 SELECT vw_item_mods_daily_summary.item_name,
    vw_item_mods_daily_summary.modifier_name,
    (sum(vw_item_mods_daily_summary.times_selected))::bigint AS times_selected,
    round(sum(vw_item_mods_daily_summary.total_mods_amount), 2) AS total_mods_amount
   FROM public.vw_item_mods_daily_summary
  GROUP BY vw_item_mods_daily_summary.item_name, vw_item_mods_daily_summary.modifier_name
  ORDER BY vw_item_mods_daily_summary.item_name, ((sum(vw_item_mods_daily_summary.times_selected))::bigint) DESC, vw_item_mods_daily_summary.modifier_name;


ALTER TABLE public.vw_item_mods_by_item_today OWNER TO postgres;

--
-- Name: vw_item_mods_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_item_mods_today AS
 SELECT f_item_mods_on.folio_date,
    f_item_mods_on.branch_key,
    f_item_mods_on.terminal_id,
    f_item_mods_on.ticket_id,
    f_item_mods_on.ticket_item_id,
    f_item_mods_on.item_name,
    f_item_mods_on.modifier_name,
    f_item_mods_on.qty_item,
    f_item_mods_on.mods_count,
    f_item_mods_on.mods_total_amount
   FROM public.f_item_mods_on(('now'::text)::date) f_item_mods_on(folio_date, branch_key, terminal_id, ticket_id, ticket_item_id, item_name, modifier_name, qty_item, mods_count, mods_total_amount);


ALTER TABLE public.vw_item_mods_today OWNER TO postgres;

--
-- Name: vw_ticket_base; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_ticket_base AS
 SELECT t.id AS ticket_id,
    t.terminal_id,
    t.branch_key,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    (COALESCE(t.total_price, (0)::double precision))::numeric(12,2) AS total_price,
    (GREATEST((0)::double precision, LEAST(COALESCE(t.total_discount, ( SELECT sum(COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision))) AS sum
           FROM public.ticket_item ti
          WHERE (ti.ticket_id = t.id)), (0)::double precision), COALESCE(t.total_price, (0)::double precision))))::numeric(12,2) AS total_discount,
    (COALESCE(( SELECT sum(g.amount) AS sum
           FROM public.gratuity g
          WHERE ((g.ticket_id = t.id) AND (COALESCE(g.refunded, false) = false) AND (COALESCE(g.paid, true) = true))), (0)::double precision))::numeric(12,2) AS tip_amount,
    (COALESCE(t.service_charge, (0)::double precision))::numeric(12,2) AS service_charges
   FROM public.ticket t
  WHERE ((t.paid = true) AND (t.voided = false));


ALTER TABLE public.vw_ticket_base OWNER TO postgres;

--
-- Name: vw_report_balance_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_balance_detail AS
 WITH paid AS (
         SELECT t.id AS ticket_id,
            selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text) AS pay_norm,
            round((sum(
                CASE
                    WHEN ((tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_amount
           FROM (public.ticket t
             LEFT JOIN public.transactions tx ON ((tx.ticket_id = t.id)))
          GROUP BY t.id, (selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text))
        )
 SELECT b.folio_date,
    b.branch_key,
    p.pay_norm AS payment,
    round(sum(COALESCE(p.paid_amount, (0)::numeric)), 2) AS monto
   FROM (public.vw_ticket_base b
     LEFT JOIN paid p ON ((p.ticket_id = b.ticket_id)))
  GROUP BY b.folio_date, b.branch_key, p.pay_norm
  ORDER BY b.folio_date, b.branch_key, (round(sum(COALESCE(p.paid_amount, (0)::numeric)), 2)) DESC;


ALTER TABLE public.vw_report_balance_detail OWNER TO postgres;

--
-- Name: vw_report_journal_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_journal_lines AS
 SELECT b.folio_date,
    b.branch_key,
    b.ticket_id,
    ti.id AS ticket_item_id,
    (ti.item_name)::text AS item_name,
    (COALESCE(ti.item_quantity, (0)::double precision))::numeric(12,2) AS qty,
    (COALESCE(ti.total_price, (0)::double precision))::numeric(12,2) AS line_total,
    (COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision)))::numeric(12,2) AS line_discount
   FROM (public.vw_ticket_base b
     JOIN public.ticket_item ti ON ((ti.ticket_id = b.ticket_id)));


ALTER TABLE public.vw_report_journal_lines OWNER TO postgres;

--
-- Name: vw_report_journal_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_journal_payments AS
 SELECT COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    t.id AS ticket_id,
    selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text) AS pay_norm,
    round((sum(
        CASE
            WHEN ((tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
            ELSE (0)::double precision
        END))::numeric, 2) AS paid_amount
   FROM (public.ticket t
     LEFT JOIN public.transactions tx ON ((tx.ticket_id = t.id)))
  GROUP BY COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date), t.branch_key, t.id, (selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text));


ALTER TABLE public.vw_report_journal_payments OWNER TO postgres;

--
-- Name: vw_report_menu_usage; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_menu_usage AS
 SELECT b.folio_date,
    b.branch_key,
    (ti.item_name)::text AS item_name,
    (sum(COALESCE(ti.item_quantity, (0)::double precision)))::numeric(12,2) AS qty,
    round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2) AS neto
   FROM (public.vw_ticket_base b
     JOIN public.ticket_item ti ON ((ti.ticket_id = b.ticket_id)))
  GROUP BY b.folio_date, b.branch_key, (ti.item_name)::text;


ALTER TABLE public.vw_report_menu_usage OWNER TO postgres;

--
-- Name: vw_report_sales_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_sales_detail AS
 SELECT b.folio_date,
    b.branch_key,
    b.terminal_id,
    b.ticket_id,
    ti.id AS ticket_item_id,
    (ti.item_name)::text AS item_name,
    (COALESCE(ti.item_quantity, (0)::double precision))::numeric(12,2) AS qty,
    (COALESCE(ti.item_price, (COALESCE(ti.total_price, (0)::double precision) / NULLIF(ti.item_quantity, (0)::double precision))))::numeric(12,2) AS unit_price,
    (COALESCE(ti.total_price, (0)::double precision))::numeric(12,2) AS line_total,
    (COALESCE(ti.discount, (0)::double precision))::numeric(12,2) AS line_discount,
    ((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision)))::numeric(12,2) AS line_neto
   FROM (public.vw_ticket_base b
     JOIN public.ticket_item ti ON ((ti.ticket_id = b.ticket_id)));


ALTER TABLE public.vw_report_sales_detail OWNER TO postgres;

--
-- Name: vw_report_sales_exceptions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_sales_exceptions AS
 WITH base AS (
         SELECT b.folio_date,
            b.branch_key,
            b.ticket_id,
            ((b.total_price - b.total_discount))::numeric(12,2) AS neto
           FROM public.vw_ticket_base b
        ), paid AS (
         SELECT t.id AS ticket_id,
            round((sum(
                CASE
                    WHEN ((COALESCE(tx.voided, false) = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_amount
           FROM (public.ticket t
             LEFT JOIN public.transactions tx ON ((tx.ticket_id = t.id)))
          GROUP BY t.id
        ), tot_disc AS (
         SELECT b.ticket_id,
            b.total_discount
           FROM public.vw_ticket_base b
        )
 SELECT b.folio_date,
    b.branch_key,
    'PAYMENT_VS_NET_MISMATCH'::text AS error_code,
    'WARN'::text AS severity,
    b.ticket_id,
    round((b.neto - COALESCE(p.paid_amount, (0)::numeric)), 2) AS diff
   FROM (base b
     LEFT JOIN paid p ON ((p.ticket_id = b.ticket_id)))
  WHERE (abs((b.neto - COALESCE(p.paid_amount, (0)::numeric))) > 0.01)
UNION ALL
 SELECT b.folio_date,
    b.branch_key,
    'DISCOUNT_OVER_THRESHOLD'::text AS error_code,
    'INFO'::text AS severity,
    b.ticket_id,
    td.total_discount AS diff
   FROM (base b
     JOIN tot_disc td ON ((td.ticket_id = b.ticket_id)))
  WHERE ((td.total_discount > (100)::numeric) OR (((b.neto + td.total_discount) > (0)::numeric) AND ((td.total_discount / NULLIF((b.neto + td.total_discount), (0)::numeric)) > 0.20)))
UNION ALL
 SELECT b.folio_date,
    b.branch_key,
    'PAID_WITHOUT_TX'::text AS error_code,
    'WARN'::text AS severity,
    b.ticket_id,
    b.neto AS diff
   FROM (base b
     LEFT JOIN paid p ON ((p.ticket_id = b.ticket_id)))
  WHERE ((COALESCE(p.paid_amount, (0)::numeric) = (0)::numeric) AND (b.neto > (0)::numeric));


ALTER TABLE public.vw_report_sales_exceptions OWNER TO postgres;

--
-- Name: vw_report_sales_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_report_sales_summary AS
 WITH valid AS (
         SELECT b.folio_date,
            COALESCE(upper(btrim(b.branch_key)), 'SIN_SUCURSAL'::text) AS branch_key,
            count(DISTINCT b.ticket_id) AS tickets,
            (sum(b.total_price))::numeric(14,2) AS bruto,
            (sum(b.total_discount))::numeric(14,2) AS descuento,
            (sum(b.tip_amount))::numeric(14,2) AS propina,
            (sum(b.service_charges))::numeric(14,2) AS cargo_servicio
           FROM public.vw_ticket_base b
          GROUP BY b.folio_date, COALESCE(upper(btrim(b.branch_key)), 'SIN_SUCURSAL'::text)
        ), ticket_all AS (
         SELECT t.id,
            COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
            COALESCE(upper(btrim(t.branch_key)), 'SIN_SUCURSAL'::text) AS branch_key,
            (COALESCE(t.total_price, (0)::double precision))::numeric(14,2) AS total_price,
            (GREATEST((0)::double precision, LEAST(COALESCE(t.total_discount, ( SELECT sum(COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision))) AS sum
                   FROM public.ticket_item ti
                  WHERE (ti.ticket_id = t.id)), (0)::double precision), COALESCE(t.total_price, (0)::double precision))))::numeric(14,2) AS total_discount,
            COALESCE(t.paid, false) AS paid,
            COALESCE(t.voided, false) AS voided
           FROM public.ticket t
        ), payments AS (
         SELECT ta.folio_date,
            ta.branch_key,
            (sum(
                CASE
                    WHEN ((ta.voided = false) AND (COALESCE(tx.voided, false) = false) AND (upper((COALESCE(tx.transaction_type, ''::character varying))::text) = ANY (ARRAY['CREDIT'::text, 'DEBIT'::text])) AND (upper((COALESCE(tx.payment_type, ''::character varying))::text) <> ALL (ARRAY['REFUND'::text, 'VOID_TRANS'::text, 'REFUND_CARD'::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric(14,2) AS gross_payments,
            (sum(
                CASE
                    WHEN ((ta.voided = false) AND (COALESCE(tx.voided, false) = false) AND (upper((COALESCE(tx.transaction_type, ''::character varying))::text) = ANY (ARRAY['CREDIT'::text, 'DEBIT'::text])) AND (upper((COALESCE(tx.payment_type, ''::character varying))::text) = ANY (ARRAY['REFUND'::text, 'VOID_TRANS'::text, 'REFUND_CARD'::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric(14,2) AS refund_amount
           FROM (ticket_all ta
             LEFT JOIN public.transactions tx ON ((tx.ticket_id = ta.id)))
          GROUP BY ta.folio_date, ta.branch_key
        ), voids AS (
         SELECT ta.folio_date,
            ta.branch_key,
            (sum((ta.total_price - ta.total_discount)))::numeric(14,2) AS void_amount
           FROM ticket_all ta
          WHERE (ta.voided = true)
          GROUP BY ta.folio_date, ta.branch_key
        ), keys AS (
         SELECT valid.folio_date,
            valid.branch_key
           FROM valid
        UNION
         SELECT payments.folio_date,
            payments.branch_key
           FROM payments
        UNION
         SELECT voids.folio_date,
            voids.branch_key
           FROM voids
        )
 SELECT k.folio_date,
    k.branch_key,
    COALESCE(v.tickets, (0)::bigint) AS tickets,
    round((COALESCE(v.bruto, (0)::numeric) + COALESCE(vo.void_amount, (0)::numeric)), 2) AS bruto,
    round(COALESCE(v.descuento, (0)::numeric), 2) AS descuento,
    round((COALESCE(p.refund_amount, (0)::numeric) + COALESCE(vo.void_amount, (0)::numeric)), 2) AS anulaciones,
    round((((COALESCE(v.bruto, (0)::numeric) + COALESCE(vo.void_amount, (0)::numeric)) - COALESCE(v.descuento, (0)::numeric)) - (COALESCE(p.refund_amount, (0)::numeric) + COALESCE(vo.void_amount, (0)::numeric))), 2) AS neto,
    round((COALESCE(p.gross_payments, (0)::numeric) - COALESCE(p.refund_amount, (0)::numeric)), 2) AS pagos_netos,
    round(COALESCE(v.propina, (0)::numeric), 2) AS propina,
    round(COALESCE(v.cargo_servicio, (0)::numeric), 2) AS cargo_servicio
   FROM (((keys k
     LEFT JOIN valid v ON (((v.folio_date = k.folio_date) AND (v.branch_key = k.branch_key))))
     LEFT JOIN payments p ON (((p.folio_date = k.folio_date) AND (p.branch_key = k.branch_key))))
     LEFT JOIN voids vo ON (((vo.folio_date = k.folio_date) AND (vo.branch_key = k.branch_key))));


ALTER TABLE public.vw_report_sales_summary OWNER TO postgres;

--
-- Name: vw_sales_daily_branch; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sales_daily_branch AS
 SELECT get_daily_stats.sucursal,
    get_daily_stats.total_ordenes,
    get_daily_stats.total_ventas,
    get_daily_stats.primer_orden,
    get_daily_stats.ultima_orden,
    get_daily_stats.promedio_por_hora
   FROM public.get_daily_stats(('now'::text)::date) get_daily_stats(sucursal, total_ordenes, total_ventas, primer_orden, ultima_orden, promedio_por_hora);


ALTER TABLE public.vw_sales_daily_branch OWNER TO postgres;

--
-- Name: vw_sales_daily_branch_range; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sales_daily_branch_range AS
 SELECT (c.d)::date AS folio_date,
    x.sucursal,
    x.total_ordenes,
    x.total_ventas,
    x.primer_orden,
    x.ultima_orden,
    x.promedio_por_hora
   FROM (generate_series((('now'::text)::date - '365 days'::interval), (('now'::text)::date)::timestamp without time zone, '1 day'::interval) c(d)
     CROSS JOIN LATERAL public.get_daily_stats((c.d)::date) x(sucursal, total_ordenes, total_ventas, primer_orden, ultima_orden, promedio_por_hora));


ALTER TABLE public.vw_sales_daily_branch_range OWNER TO postgres;

--
-- Name: vw_sales_exceptions_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sales_exceptions_today AS
 WITH base AS (
         SELECT t.folio_date,
            t.branch_key,
            term.location AS sucursal,
            term.name AS terminal,
            t.id AS ticket_id,
            round((COALESCE(t.total_price, (0)::double precision))::numeric, 2) AS total_bruto,
            round((COALESCE(t.total_discount, (0)::double precision))::numeric, 2) AS total_descuento,
            round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS total_neto,
            t.voided,
            (COALESCE(t.total_discount, (0)::double precision) >= (COALESCE(t.total_price, (0)::double precision) * (0.30)::double precision)) AS descuento_mayor_30
           FROM (public.ticket t
             JOIN public.terminal term ON ((term.id = t.terminal_id)))
          WHERE (t.folio_date = ('now'::text)::date)
        )
 SELECT b.folio_date,
    b.branch_key,
    b.sucursal,
    b.terminal,
    b.ticket_id,
    b.total_bruto,
    b.total_descuento,
    b.total_neto,
    b.voided,
    b.descuento_mayor_30,
        CASE
            WHEN b.voided THEN 'VOID_TICKET'::text
            WHEN b.descuento_mayor_30 THEN 'HIGH_DISCOUNT'::text
            ELSE 'NORMAL'::text
        END AS exception_code,
        CASE
            WHEN b.voided THEN 'CRITICAL'::text
            WHEN b.descuento_mayor_30 THEN 'WARN'::text
            ELSE 'INFO'::text
        END AS severity
   FROM base b
  WHERE (b.voided OR b.descuento_mayor_30);


ALTER TABLE public.vw_sales_exceptions_today OWNER TO postgres;

--
-- Name: vw_sales_kpis; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sales_kpis AS
 SELECT t.folio_date,
    t.branch_key,
    count(DISTINCT t.id) AS total_tickets,
    round(((sum((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))) / (NULLIF(count(DISTINCT t.id), 0))::double precision))::numeric, 2) AS avg_ticket,
    round(((sum(COALESCE(ti.item_quantity, (0)::double precision)) / (NULLIF(count(DISTINCT t.id), 0))::double precision))::numeric, 2) AS items_per_ticket,
    round((sum((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))))::numeric, 2) AS total_neto,
    round((sum(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS total_descuentos,
    round((((sum(COALESCE(t.total_discount, (0)::double precision)) / NULLIF(sum(COALESCE(t.total_price, (0)::double precision)), (0)::double precision)) * (100)::double precision))::numeric, 2) AS descuento_percentage
   FROM (public.ticket t
     LEFT JOIN public.ticket_item ti ON ((ti.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false))
  GROUP BY t.folio_date, t.branch_key;


ALTER TABLE public.vw_sales_kpis OWNER TO postgres;

--
-- Name: vw_sales_mix_payment_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sales_mix_payment_today AS
 SELECT f_sales_mix_payment_on.folio_date,
    f_sales_mix_payment_on.branch_key,
    f_sales_mix_payment_on.normalized_payment,
    f_sales_mix_payment_on.total
   FROM public.f_sales_mix_payment_on(('now'::text)::date) f_sales_mix_payment_on(folio_date, branch_key, normalized_payment, total);


ALTER TABLE public.vw_sales_mix_payment_today OWNER TO postgres;

--
-- Name: vw_top_items_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_top_items_today AS
 SELECT t.folio_date,
    t.branch_key,
    ti.item_id,
    ti.item_name,
    round((sum(COALESCE(ti.item_quantity, (0)::double precision)))::numeric, 2) AS qty,
    round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2) AS neto
   FROM (public.ticket_item ti
     JOIN public.ticket t ON ((t.id = ti.ticket_id)))
  WHERE ((t.folio_date = ('now'::text)::date) AND (t.voided = false))
  GROUP BY t.folio_date, t.branch_key, ti.item_id, ti.item_name
  ORDER BY (round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2)) DESC;


ALTER TABLE public.vw_top_items_today OWNER TO postgres;

--
-- Name: zip_code_vs_delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE public.zip_code_vs_delivery_charge (
    auto_id integer NOT NULL,
    zip_code character varying(10) NOT NULL,
    delivery_charge double precision NOT NULL
);


ALTER TABLE public.zip_code_vs_delivery_charge OWNER TO floreant;

--
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE public.zip_code_vs_delivery_charge_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zip_code_vs_delivery_charge_auto_id_seq OWNER TO floreant;

--
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE public.zip_code_vs_delivery_charge_auto_id_seq OWNED BY public.zip_code_vs_delivery_charge.auto_id;


--
-- Name: alert_events; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.alert_events (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    snapshot_at timestamp without time zone NOT NULL,
    old_portion_cost numeric(14,6),
    new_portion_cost numeric(14,6),
    delta_pct numeric(8,4),
    created_at timestamp without time zone DEFAULT now(),
    handled boolean DEFAULT false NOT NULL,
    assigned_to bigint,
    acknowledged_at timestamp(0) with time zone,
    resolution_notes text,
    severity character varying(20) DEFAULT 'medium'::character varying NOT NULL
);


ALTER TABLE selemti.alert_events OWNER TO postgres;

--
-- Name: alert_events_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.alert_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.alert_events_id_seq OWNER TO postgres;

--
-- Name: alert_events_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.alert_events_id_seq OWNED BY selemti.alert_events.id;


--
-- Name: alert_rules; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.alert_rules (
    id bigint NOT NULL,
    recipe_id bigint,
    category_id bigint,
    threshold_pct numeric(6,2) DEFAULT 10.0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    notes text,
    scope character varying(40) DEFAULT 'global'::character varying NOT NULL,
    threshold_numeric numeric(14,4),
    threshold_percent numeric(7,4),
    notification_channels jsonb
);


ALTER TABLE selemti.alert_rules OWNER TO postgres;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.alert_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.alert_rules_id_seq OWNER TO postgres;

--
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.alert_rules_id_seq OWNED BY selemti.alert_rules.id;


--
-- Name: alertas_cortes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.alertas_cortes (
    id bigint NOT NULL,
    postcorte_id bigint,
    sesion_id bigint,
    tipo character varying(50) NOT NULL,
    destinatario_id integer,
    leida boolean DEFAULT false,
    creada_en timestamp with time zone DEFAULT now(),
    leida_en timestamp with time zone
);


ALTER TABLE selemti.alertas_cortes OWNER TO postgres;

--
-- Name: alertas_cortes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.alertas_cortes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.alertas_cortes_id_seq OWNER TO postgres;

--
-- Name: alertas_cortes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.alertas_cortes_id_seq OWNED BY selemti.alertas_cortes.id;


--
-- Name: almacen; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.almacen (
    id text NOT NULL,
    sucursal_id bigint NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE selemti.almacen OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.audit_log (
    id bigint NOT NULL,
    "timestamp" timestamp(0) without time zone DEFAULT now() NOT NULL,
    user_id bigint NOT NULL,
    accion character varying(100) NOT NULL,
    entidad character varying(50) NOT NULL,
    entidad_id bigint NOT NULL,
    motivo text,
    evidencia_url text,
    payload_json jsonb
);


ALTER TABLE selemti.audit_log OWNER TO postgres;

--
-- Name: audit_log_global; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.audit_log_global (
    id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    operation text NOT NULL,
    record_id text,
    old_data jsonb,
    new_data jsonb,
    changed_by_user_id bigint,
    changed_at timestamp without time zone DEFAULT now(),
    ip_address inet,
    user_agent text,
    CONSTRAINT audit_log_global_operation_check CHECK ((operation = ANY (ARRAY['INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


ALTER TABLE selemti.audit_log_global OWNER TO postgres;

--
-- Name: TABLE audit_log_global; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.audit_log_global IS 'Log global de auditorÃ­a - Creada en Phase 5';


--
-- Name: audit_log_global_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.audit_log_global_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.audit_log_global_id_seq OWNER TO postgres;

--
-- Name: audit_log_global_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.audit_log_global_id_seq OWNED BY selemti.audit_log_global.id;


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.audit_log_id_seq OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.audit_log_id_seq OWNED BY selemti.audit_log.id;


--
-- Name: auditoria; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.auditoria (
    id bigint NOT NULL,
    quien integer,
    que text NOT NULL,
    payload jsonb,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.auditoria OWNER TO floreant;

--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.auditoria_id_seq OWNER TO floreant;

--
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.auditoria_id_seq OWNED BY selemti.auditoria.id;


--
-- Name: bodega; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.bodega (
    id integer NOT NULL,
    sucursal_id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE selemti.bodega OWNER TO postgres;

--
-- Name: bodega_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.bodega_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.bodega_id_seq OWNER TO postgres;

--
-- Name: bodega_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.bodega_id_seq OWNED BY selemti.bodega.id;


--
-- Name: cache; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE selemti.cache OWNER TO postgres;

--
-- Name: cache_locks; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE selemti.cache_locks OWNER TO postgres;

--
-- Name: caja_fondo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.caja_fondo (
    id bigint NOT NULL,
    sucursal_id integer NOT NULL,
    fecha date NOT NULL,
    monto_inicial numeric(12,2) NOT NULL,
    moneda character varying(3) DEFAULT 'MXN'::character varying,
    estado character varying(16) DEFAULT 'ABIERTO'::character varying NOT NULL,
    creado_por integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.caja_fondo OWNER TO postgres;

--
-- Name: caja_fondo_adj; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.caja_fondo_adj (
    id bigint NOT NULL,
    mov_id bigint,
    tipo character varying(16) NOT NULL,
    archivo_url text NOT NULL,
    observaciones text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.caja_fondo_adj OWNER TO postgres;

--
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.caja_fondo_adj_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.caja_fondo_adj_id_seq OWNER TO postgres;

--
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.caja_fondo_adj_id_seq OWNED BY selemti.caja_fondo_adj.id;


--
-- Name: caja_fondo_arqueo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.caja_fondo_arqueo (
    id bigint NOT NULL,
    fondo_id bigint,
    fecha_cierre timestamp without time zone DEFAULT now() NOT NULL,
    efectivo_contado numeric(12,2) NOT NULL,
    diferencia numeric(12,2) NOT NULL,
    observaciones text,
    cerrado_por integer NOT NULL
);


ALTER TABLE selemti.caja_fondo_arqueo OWNER TO postgres;

--
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.caja_fondo_arqueo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.caja_fondo_arqueo_id_seq OWNER TO postgres;

--
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.caja_fondo_arqueo_id_seq OWNED BY selemti.caja_fondo_arqueo.id;


--
-- Name: caja_fondo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.caja_fondo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.caja_fondo_id_seq OWNER TO postgres;

--
-- Name: caja_fondo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.caja_fondo_id_seq OWNED BY selemti.caja_fondo.id;


--
-- Name: caja_fondo_mov; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.caja_fondo_mov (
    id bigint NOT NULL,
    fondo_id bigint,
    fecha_hora timestamp without time zone DEFAULT now() NOT NULL,
    tipo character varying(16) NOT NULL,
    concepto text NOT NULL,
    proveedor_id integer,
    monto numeric(12,2) NOT NULL,
    metodo character varying(16) DEFAULT 'EFECTIVO'::character varying NOT NULL,
    requiere_comprobante boolean DEFAULT false,
    estatus character varying(16) DEFAULT 'CAPTURADO'::character varying NOT NULL,
    creado_por integer NOT NULL,
    aprobado_por integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.caja_fondo_mov OWNER TO postgres;

--
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.caja_fondo_mov_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.caja_fondo_mov_id_seq OWNER TO postgres;

--
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.caja_fondo_mov_id_seq OWNED BY selemti.caja_fondo_mov.id;


--
-- Name: caja_fondo_usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.caja_fondo_usuario (
    fondo_id bigint NOT NULL,
    user_id integer NOT NULL,
    rol character varying(16) NOT NULL
);


ALTER TABLE selemti.caja_fondo_usuario OWNER TO postgres;

--
-- Name: cash_fund_arqueos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cash_fund_arqueos (
    id bigint NOT NULL,
    cash_fund_id bigint NOT NULL,
    monto_esperado numeric(10,2) NOT NULL,
    monto_contado numeric(10,2) NOT NULL,
    diferencia numeric(10,2) NOT NULL,
    observaciones text,
    created_by_user_id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.cash_fund_arqueos OWNER TO postgres;

--
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cash_fund_arqueos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cash_fund_arqueos_id_seq OWNER TO postgres;

--
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cash_fund_arqueos_id_seq OWNED BY selemti.cash_fund_arqueos.id;


--
-- Name: cash_fund_movement_audit_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cash_fund_movement_audit_log (
    id bigint NOT NULL,
    movement_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    field_changed character varying(100),
    old_value text,
    new_value text,
    observaciones text,
    changed_by_user_id bigint NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.cash_fund_movement_audit_log OWNER TO postgres;

--
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cash_fund_movement_audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cash_fund_movement_audit_log_id_seq OWNER TO postgres;

--
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cash_fund_movement_audit_log_id_seq OWNED BY selemti.cash_fund_movement_audit_log.id;


--
-- Name: cash_fund_movements; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cash_fund_movements (
    id bigint NOT NULL,
    cash_fund_id bigint NOT NULL,
    tipo character varying(255) NOT NULL,
    concepto text NOT NULL,
    proveedor_id integer,
    monto numeric(10,2) NOT NULL,
    metodo character varying(255) NOT NULL,
    estatus character varying(255) DEFAULT 'APROBADO'::character varying NOT NULL,
    requiere_comprobante boolean DEFAULT false NOT NULL,
    tiene_comprobante boolean DEFAULT false NOT NULL,
    adjunto_path character varying(255),
    created_by_user_id bigint NOT NULL,
    approved_by_user_id bigint,
    approved_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT cash_fund_movements_estatus_check CHECK (((estatus)::text = ANY (ARRAY[('APROBADO'::character varying)::text, ('POR_APROBAR'::character varying)::text, ('RECHAZADO'::character varying)::text]))),
    CONSTRAINT cash_fund_movements_metodo_check CHECK (((metodo)::text = ANY (ARRAY[('EFECTIVO'::character varying)::text, ('TRANSFER'::character varying)::text]))),
    CONSTRAINT cash_fund_movements_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('EGRESO'::character varying)::text, ('REINTEGRO'::character varying)::text, ('DEPOSITO'::character varying)::text])))
);


ALTER TABLE selemti.cash_fund_movements OWNER TO postgres;

--
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cash_fund_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cash_fund_movements_id_seq OWNER TO postgres;

--
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cash_fund_movements_id_seq OWNED BY selemti.cash_fund_movements.id;


--
-- Name: cash_funds; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cash_funds (
    id bigint NOT NULL,
    sucursal_id integer NOT NULL,
    fecha date NOT NULL,
    monto_inicial numeric(10,2) NOT NULL,
    moneda character varying(3) DEFAULT 'MXN'::character varying NOT NULL,
    estado character varying(255) DEFAULT 'ABIERTO'::character varying NOT NULL,
    responsable_user_id bigint NOT NULL,
    created_by_user_id bigint NOT NULL,
    closed_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    descripcion character varying(255),
    CONSTRAINT cash_funds_estado_check CHECK (((estado)::text = ANY (ARRAY[('ABIERTO'::character varying)::text, ('EN_REVISION'::character varying)::text, ('CERRADO'::character varying)::text])))
);


ALTER TABLE selemti.cash_funds OWNER TO postgres;

--
-- Name: COLUMN cash_funds.descripcion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.cash_funds.descripcion IS 'Descripción o nombre del fondo para identificación rápida';


--
-- Name: cash_funds_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cash_funds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cash_funds_id_seq OWNER TO postgres;

--
-- Name: cash_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cash_funds_id_seq OWNED BY selemti.cash_funds.id;


--
-- Name: cat_almacenes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cat_almacenes (
    id bigint NOT NULL,
    clave character varying(16) NOT NULL,
    nombre character varying(80) NOT NULL,
    sucursal_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.cat_almacenes OWNER TO postgres;

--
-- Name: TABLE cat_almacenes; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.cat_almacenes IS 'CatÃ¡logo de almacenes - Consolidada en Phase 2.2';


--
-- Name: cat_almacenes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cat_almacenes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cat_almacenes_id_seq OWNER TO postgres;

--
-- Name: cat_almacenes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cat_almacenes_id_seq OWNED BY selemti.cat_almacenes.id;


--
-- Name: cat_proveedores; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cat_proveedores (
    id bigint NOT NULL,
    rfc character varying(20) NOT NULL,
    nombre character varying(120) NOT NULL,
    telefono character varying(30),
    email character varying(120),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    razon_social character varying(200),
    tipo_comprobante character varying(10),
    uso_cfdi character varying(10),
    metodo_pago character varying(10),
    forma_pago character varying(10),
    regimen_fiscal character varying(10),
    contacto_nombre character varying(150),
    contacto_email character varying(150),
    contacto_telefono character varying(50),
    direccion character varying(255),
    ciudad character varying(120),
    estado character varying(120),
    pais character varying(120),
    cp character varying(12),
    notas text
);


ALTER TABLE selemti.cat_proveedores OWNER TO postgres;

--
-- Name: cat_proveedores_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cat_proveedores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cat_proveedores_id_seq OWNER TO postgres;

--
-- Name: cat_proveedores_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cat_proveedores_id_seq OWNED BY selemti.cat_proveedores.id;


--
-- Name: cat_sucursales; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cat_sucursales (
    id bigint NOT NULL,
    clave character varying(16) NOT NULL,
    nombre character varying(120) NOT NULL,
    ubicacion character varying(160),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    pos_location character varying(64)
);


ALTER TABLE selemti.cat_sucursales OWNER TO postgres;

--
-- Name: TABLE cat_sucursales; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.cat_sucursales IS 'CatÃ¡logo de sucursales - Consolidada en Phase 2.2';


--
-- Name: cat_sucursales_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cat_sucursales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cat_sucursales_id_seq OWNER TO postgres;

--
-- Name: cat_sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cat_sucursales_id_seq OWNED BY selemti.cat_sucursales.id;


--
-- Name: cat_unidades; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    clave character varying(16),
    nombre character varying(64),
    activo boolean DEFAULT true NOT NULL,
    categoria character varying(20)
);


ALTER TABLE selemti.cat_unidades OWNER TO postgres;

--
-- Name: COLUMN cat_unidades.categoria; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.cat_unidades.categoria IS 'Categoría: BASE, COCINA, COMPRA, PORCION';


--
-- Name: cat_unidades_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cat_unidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cat_unidades_id_seq OWNER TO postgres;

--
-- Name: cat_unidades_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cat_unidades_id_seq OWNED BY selemti.cat_unidades.id;


--
-- Name: cat_uom_conversion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cat_uom_conversion (
    id bigint NOT NULL,
    origen_id bigint NOT NULL,
    destino_id bigint NOT NULL,
    factor numeric(18,6) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    is_exact boolean DEFAULT true NOT NULL,
    scope character varying(16) DEFAULT 'global'::character varying NOT NULL,
    notes text
);


ALTER TABLE selemti.cat_uom_conversion OWNER TO postgres;

--
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cat_uom_conversion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cat_uom_conversion_id_seq OWNER TO postgres;

--
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cat_uom_conversion_id_seq OWNED BY selemti.cat_uom_conversion.id;


--
-- Name: conciliacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.conciliacion (
    id bigint NOT NULL,
    postcorte_id bigint NOT NULL,
    conciliado_por integer,
    conciliado_en timestamp with time zone DEFAULT now(),
    estatus text DEFAULT 'EN_REVISION'::text NOT NULL,
    notas text,
    CONSTRAINT conciliacion_estatus_check CHECK ((estatus = ANY (ARRAY['EN_REVISION'::text, 'CONCILIADO'::text, 'OBSERVADA'::text])))
);


ALTER TABLE selemti.conciliacion OWNER TO postgres;

--
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- Name: COLUMN conciliacion.conciliado_por; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.conciliacion.conciliado_por IS 'Usuario que realizÃ³ la conciliaciÃ³n (supervisor/gerente).';


--
-- Name: conciliacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.conciliacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.conciliacion_id_seq OWNER TO postgres;

--
-- Name: conciliacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.conciliacion_id_seq OWNED BY selemti.conciliacion.id;


--
-- Name: conversiones_unidad; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.conversiones_unidad AS
 SELECT (cat_uom_conversion.id)::integer AS id,
    (cat_uom_conversion.origen_id)::integer AS unidad_origen_id,
    (cat_uom_conversion.destino_id)::integer AS unidad_destino_id,
    cat_uom_conversion.factor AS factor_conversion,
    cat_uom_conversion.notes AS formula_directa,
    (
        CASE
            WHEN cat_uom_conversion.is_exact THEN 1.0
            ELSE 0.95
        END)::numeric(5,4) AS precision_estimada,
    true AS activo,
    cat_uom_conversion.created_at
   FROM selemti.cat_uom_conversion;


ALTER TABLE selemti.conversiones_unidad OWNER TO postgres;

--
-- Name: VIEW conversiones_unidad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.conversiones_unidad IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy conversiones_unidad';


--
-- Name: conversiones_unidad_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.conversiones_unidad_legacy (
    id integer NOT NULL,
    unidad_origen_id integer NOT NULL,
    unidad_destino_id integer NOT NULL,
    factor_conversion numeric(12,6) NOT NULL,
    formula_directa text,
    precision_estimada numeric(5,4) DEFAULT 1.0,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT conversiones_unidad_check CHECK ((unidad_origen_id <> unidad_destino_id)),
    CONSTRAINT conversiones_unidad_factor_conversion_check CHECK ((factor_conversion > (0)::numeric))
);


ALTER TABLE selemti.conversiones_unidad_legacy OWNER TO postgres;

--
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.conversiones_unidad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.conversiones_unidad_id_seq OWNER TO postgres;

--
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.conversiones_unidad_id_seq OWNED BY selemti.conversiones_unidad_legacy.id;


--
-- Name: cost_layer; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.cost_layer (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    batch_id bigint,
    ts_in timestamp without time zone NOT NULL,
    qty_in numeric(14,6) NOT NULL,
    qty_left numeric(14,6) NOT NULL,
    unit_cost numeric(14,6) NOT NULL,
    sucursal_id character varying(30),
    source_ref text,
    source_id bigint
);


ALTER TABLE selemti.cost_layer OWNER TO postgres;

--
-- Name: cost_layer_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.cost_layer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.cost_layer_id_seq OWNER TO postgres;

--
-- Name: cost_layer_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.cost_layer_id_seq OWNED BY selemti.cost_layer.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.failed_jobs OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.failed_jobs_id_seq OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.failed_jobs_id_seq OWNED BY selemti.failed_jobs.id;


--
-- Name: formas_pago; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.formas_pago (
    id bigint NOT NULL,
    codigo text NOT NULL,
    payment_type text,
    transaction_type text,
    payment_sub_type text,
    custom_name text,
    custom_ref text,
    activo boolean DEFAULT true NOT NULL,
    prioridad integer DEFAULT 100 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.formas_pago OWNER TO floreant;

--
-- Name: formas_pago_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.formas_pago_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.formas_pago_id_seq OWNER TO floreant;

--
-- Name: formas_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.formas_pago_id_seq OWNED BY selemti.formas_pago.id;


--
-- Name: hist_cost_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.hist_cost_insumo (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    fecha_efectiva date NOT NULL,
    costo_wac numeric(14,6),
    costo_peps numeric(14,6),
    costo_ueps numeric(14,6),
    costo_std numeric(14,6),
    algoritmo_principal text DEFAULT 'WAC'::text,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.hist_cost_insumo OWNER TO postgres;

--
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.hist_cost_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.hist_cost_insumo_id_seq OWNER TO postgres;

--
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.hist_cost_insumo_id_seq OWNED BY selemti.hist_cost_insumo.id;


--
-- Name: hist_cost_receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.hist_cost_receta (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    fecha_calculo date NOT NULL,
    costo_total numeric(14,6),
    costo_porcion numeric(14,6),
    algoritmo_utilizado text DEFAULT 'WAC'::text,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE selemti.hist_cost_receta OWNER TO postgres;

--
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.hist_cost_receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.hist_cost_receta_id_seq OWNER TO postgres;

--
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.hist_cost_receta_id_seq OWNED BY selemti.hist_cost_receta.id;


--
-- Name: historial_costos_item; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.historial_costos_item (
    id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    fecha_efectiva date NOT NULL,
    fecha_registro timestamp without time zone DEFAULT now(),
    costo_anterior numeric(10,2),
    costo_nuevo numeric(10,2),
    tipo_cambio character varying(20),
    referencia_id integer,
    referencia_tipo character varying(20),
    usuario_id integer,
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    costo_wac numeric(12,4),
    costo_peps numeric(12,4),
    costo_ueps numeric(12,4),
    costo_estandar numeric(12,4),
    algoritmo_principal character varying(10) DEFAULT 'WAC'::character varying,
    version_datos integer DEFAULT 1,
    recalculado boolean DEFAULT false,
    fuente_datos character varying(20),
    metadata_calculo json,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT historial_costos_item_algoritmo_principal_check CHECK (((algoritmo_principal)::text = ANY (ARRAY[('WAC'::character varying)::text, ('PEPS'::character varying)::text, ('UEPS'::character varying)::text, ('ESTANDAR'::character varying)::text]))),
    CONSTRAINT historial_costos_item_fuente_datos_check CHECK (((fuente_datos)::text = ANY (ARRAY[('COMPRA'::character varying)::text, ('AJUSTE'::character varying)::text, ('REPROCESO'::character varying)::text, ('IMPORTACION'::character varying)::text]))),
    CONSTRAINT historial_costos_item_tipo_cambio_check CHECK (((tipo_cambio)::text = ANY (ARRAY[('COMPRA'::character varying)::text, ('AJUSTE'::character varying)::text, ('REPROCESO'::character varying)::text])))
);


ALTER TABLE selemti.historial_costos_item OWNER TO postgres;

--
-- Name: historial_costos_item_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.historial_costos_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.historial_costos_item_id_seq OWNER TO postgres;

--
-- Name: historial_costos_item_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.historial_costos_item_id_seq OWNED BY selemti.historial_costos_item.id;


--
-- Name: historial_costos_receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.historial_costos_receta (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    fecha_calculo date NOT NULL,
    costo_total numeric(10,2),
    costo_porcion numeric(10,2),
    algoritmo_utilizado character varying(20),
    version_datos integer DEFAULT 1,
    metadata_calculo json,
    created_at timestamp without time zone DEFAULT now(),
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE selemti.historial_costos_receta OWNER TO postgres;

--
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.historial_costos_receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.historial_costos_receta_id_seq OWNER TO postgres;

--
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.historial_costos_receta_id_seq OWNED BY selemti.historial_costos_receta.id;


--
-- Name: insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.insumo (
    id bigint NOT NULL,
    sku text,
    nombre text NOT NULL,
    um_id integer NOT NULL,
    perecible boolean DEFAULT false NOT NULL,
    merma_pct numeric(6,3) DEFAULT 0.000 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    meta jsonb,
    codigo character varying(20),
    categoria_codigo character varying(4),
    subcategoria_codigo character varying(6),
    consecutivo integer,
    codigo_alterno character varying(50)
);


ALTER TABLE selemti.insumo OWNER TO postgres;

--
-- Name: COLUMN insumo.codigo_alterno; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.insumo.codigo_alterno IS 'Código alternativo para compatibilidad';


--
-- Name: insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.insumo_id_seq OWNER TO postgres;

--
-- Name: insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.insumo_id_seq OWNED BY selemti.insumo.id;


--
-- Name: insumo_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.insumo_presentacion (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    proveedor_id integer,
    um_compra_id integer NOT NULL,
    factor_a_um numeric(14,6) DEFAULT 1.0 NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0.0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.insumo_presentacion OWNER TO postgres;

--
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.insumo_presentacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.insumo_presentacion_id_seq OWNER TO postgres;

--
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.insumo_presentacion_id_seq OWNED BY selemti.insumo_presentacion.id;


--
-- Name: insumo_proveedor_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.insumo_proveedor_presentacion (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    proveedor_id text NOT NULL,
    uom_compra_id integer NOT NULL,
    cantidad_en_uom_compra numeric(14,6) DEFAULT 1 NOT NULL,
    uom_base_id integer NOT NULL,
    factor_a_base numeric(20,10) DEFAULT 1 NOT NULL,
    precio_compra numeric(14,6),
    moneda character(3) DEFAULT 'MXN'::bpchar NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.insumo_proveedor_presentacion OWNER TO postgres;

--
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.insumo_proveedor_presentacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.insumo_proveedor_presentacion_id_seq OWNER TO postgres;

--
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.insumo_proveedor_presentacion_id_seq OWNED BY selemti.insumo_proveedor_presentacion.id;


--
-- Name: inv_consumo_pos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inv_consumo_pos (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    ticket_item_id bigint,
    sucursal_id integer NOT NULL,
    terminal_id integer NOT NULL,
    estado character varying(16) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    requiere_reproceso boolean DEFAULT true NOT NULL,
    procesado boolean DEFAULT false NOT NULL,
    fecha_proceso timestamp(0) without time zone,
    revertido boolean DEFAULT false NOT NULL
);


ALTER TABLE selemti.inv_consumo_pos OWNER TO postgres;

--
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- Name: COLUMN inv_consumo_pos.fecha_proceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.inv_consumo_pos.fecha_proceso IS 'Momento del procesamiento';


--
-- Name: COLUMN inv_consumo_pos.revertido; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.inv_consumo_pos.revertido IS 'Consumo revertido/anulado';


--
-- Name: inv_consumo_pos_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inv_consumo_pos_det (
    id bigint NOT NULL,
    consumo_id bigint,
    mp_id integer NOT NULL,
    uom_id integer,
    cantidad numeric(12,4) NOT NULL,
    factor numeric(12,6) DEFAULT 1 NOT NULL,
    origen character varying(16) NOT NULL,
    requiere_reproceso boolean DEFAULT true NOT NULL,
    procesado boolean DEFAULT false NOT NULL,
    fecha_proceso timestamp(0) without time zone,
    revertido boolean DEFAULT false NOT NULL
);


ALTER TABLE selemti.inv_consumo_pos_det OWNER TO postgres;

--
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inv_consumo_pos_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inv_consumo_pos_det_id_seq OWNER TO postgres;

--
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inv_consumo_pos_det_id_seq OWNED BY selemti.inv_consumo_pos_det.id;


--
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inv_consumo_pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inv_consumo_pos_id_seq OWNER TO postgres;

--
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inv_consumo_pos_id_seq OWNED BY selemti.inv_consumo_pos.id;


--
-- Name: inv_consumo_pos_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inv_consumo_pos_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    accion character varying(20) NOT NULL,
    registrado_en timestamp(0) with time zone DEFAULT now() NOT NULL,
    payload jsonb
);


ALTER TABLE selemti.inv_consumo_pos_log OWNER TO postgres;

--
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inv_consumo_pos_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inv_consumo_pos_log_id_seq OWNER TO postgres;

--
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inv_consumo_pos_log_id_seq OWNED BY selemti.inv_consumo_pos_log.id;


--
-- Name: inv_stock_policy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inv_stock_policy (
    id bigint NOT NULL,
    item_id character varying(64) NOT NULL,
    sucursal_id bigint NOT NULL,
    min_qty numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    max_qty numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    reorder_qty numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.inv_stock_policy OWNER TO postgres;

--
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inv_stock_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inv_stock_policy_id_seq OWNER TO postgres;

--
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inv_stock_policy_id_seq OWNED BY selemti.inv_stock_policy.id;


--
-- Name: inventory_batch; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inventory_batch (
    id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    lote_proveedor character varying(50) NOT NULL,
    fecha_recepcion date NOT NULL,
    fecha_caducidad date NOT NULL,
    temperatura_recepcion numeric(5,2),
    documento_url character varying(255),
    cantidad_original numeric(10,3) NOT NULL,
    cantidad_actual numeric(10,3) NOT NULL,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying,
    ubicacion_id character varying(10) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    unit_cost numeric(12,4) DEFAULT '0'::numeric NOT NULL,
    CONSTRAINT inventory_batch_cantidad_actual_check CHECK ((cantidad_actual >= (0)::numeric)),
    CONSTRAINT inventory_batch_cantidad_original_check CHECK ((cantidad_original > (0)::numeric)),
    CONSTRAINT inventory_batch_check CHECK ((cantidad_actual <= cantidad_original)),
    CONSTRAINT inventory_batch_estado_check CHECK (((estado)::text = ANY (ARRAY[('ACTIVO'::character varying)::text, ('BLOQUEADO'::character varying)::text, ('RECALL'::character varying)::text]))),
    CONSTRAINT inventory_batch_lote_proveedor_check CHECK (((length((lote_proveedor)::text) >= 1) AND (length((lote_proveedor)::text) <= 50))),
    CONSTRAINT inventory_batch_temperatura_recepcion_check CHECK (((temperatura_recepcion >= ('-30'::integer)::numeric) AND (temperatura_recepcion <= (60)::numeric))),
    CONSTRAINT inventory_batch_ubicacion_id_check CHECK (((ubicacion_id)::text ~~ 'UBIC-%'::text))
);


ALTER TABLE selemti.inventory_batch OWNER TO postgres;

--
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.inventory_batch IS 'Lotes de inventario - Consolidada en Phase 2.3';


--
-- Name: COLUMN inventory_batch.unit_cost; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.inventory_batch.unit_cost IS 'Costo unitario del lote para costeo por batch.';


--
-- Name: inventory_batch_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inventory_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inventory_batch_id_seq OWNER TO postgres;

--
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inventory_batch_id_seq OWNED BY selemti.inventory_batch.id;


--
-- Name: inventory_count_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inventory_count_lines (
    id bigint NOT NULL,
    inventory_count_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    inventory_batch_id bigint,
    qty_teorica numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    qty_contada numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    qty_variacion numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    uom character varying(20) NOT NULL,
    motivo character varying(60),
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.inventory_count_lines OWNER TO postgres;

--
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inventory_count_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inventory_count_lines_id_seq OWNER TO postgres;

--
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inventory_count_lines_id_seq OWNED BY selemti.inventory_count_lines.id;


--
-- Name: inventory_counts; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inventory_counts (
    id bigint NOT NULL,
    folio character varying(40),
    sucursal_id character varying(36),
    almacen_id character varying(36),
    programado_para timestamp(0) with time zone,
    iniciado_en timestamp(0) with time zone,
    cerrado_en timestamp(0) with time zone,
    estado character varying(24) DEFAULT 'BORRADOR'::character varying NOT NULL,
    creado_por bigint,
    cerrado_por bigint,
    notas text,
    total_items numeric(14,4) DEFAULT '0'::numeric NOT NULL,
    total_variacion numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.inventory_counts OWNER TO postgres;

--
-- Name: inventory_counts_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inventory_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inventory_counts_id_seq OWNER TO postgres;

--
-- Name: inventory_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inventory_counts_id_seq OWNED BY selemti.inventory_counts.id;


--
-- Name: inventory_snapshot; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inventory_snapshot (
    snapshot_date date NOT NULL,
    branch_id text NOT NULL,
    item_id character varying(20) NOT NULL,
    teorico_qty numeric(18,6) DEFAULT 0 NOT NULL,
    fisico_qty numeric(18,6),
    teorico_cost numeric(14,6),
    valor_teorico numeric(18,6),
    variance_qty numeric(18,6),
    variance_cost numeric(18,6),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.inventory_snapshot OWNER TO postgres;

--
-- Name: inventory_wastes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.inventory_wastes (
    id bigint NOT NULL,
    production_order_id bigint,
    item_id character varying(20) NOT NULL,
    inventory_batch_id bigint,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    motivo character varying(80),
    sucursal_id character varying(36),
    almacen_id character varying(36),
    user_id bigint,
    ref_tipo character varying(40),
    ref_id bigint,
    registrado_en timestamp(0) with time zone DEFAULT now() NOT NULL,
    meta jsonb,
    notas text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.inventory_wastes OWNER TO postgres;

--
-- Name: inventory_wastes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.inventory_wastes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.inventory_wastes_id_seq OWNER TO postgres;

--
-- Name: inventory_wastes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.inventory_wastes_id_seq OWNED BY selemti.inventory_wastes.id;


--
-- Name: item_categories; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.item_categories (
    id bigint NOT NULL,
    nombre character varying(150) NOT NULL,
    slug character varying(160),
    codigo character varying(16),
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    prefijo character varying(10),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.item_categories OWNER TO postgres;

--
-- Name: item_categories_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.item_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.item_categories_id_seq OWNER TO postgres;

--
-- Name: item_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.item_categories_id_seq OWNED BY selemti.item_categories.id;


--
-- Name: item_category_counters; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.item_category_counters (
    category_id bigint NOT NULL,
    last_val bigint DEFAULT 0 NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.item_category_counters OWNER TO postgres;

--
-- Name: item_vendor; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.item_vendor (
    item_id text NOT NULL,
    vendor_id text NOT NULL,
    presentacion text NOT NULL,
    unidad_presentacion_id integer NOT NULL,
    factor_a_canonica numeric(14,6) NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0 NOT NULL,
    moneda text DEFAULT 'MXN'::text NOT NULL,
    lead_time_dias integer,
    codigo_proveedor text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    preferente boolean DEFAULT false,
    vendor_sku character varying(120),
    vendor_descripcion character varying(255),
    currency_code character varying(10),
    lead_time_days integer,
    min_order_qty numeric(14,6),
    pack_qty numeric(14,6),
    pack_uom character varying(20),
    CONSTRAINT item_vendor_factor_a_canonica_check CHECK ((factor_a_canonica > (0)::numeric))
);


ALTER TABLE selemti.item_vendor OWNER TO postgres;

--
-- Name: item_vendor_prices; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.item_vendor_prices (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    price numeric(14,6) NOT NULL,
    currency_code character varying(10) DEFAULT 'MXN'::character varying,
    pack_qty numeric(14,6) DEFAULT 1 NOT NULL,
    pack_uom character varying(20) NOT NULL,
    notes text,
    source character varying(40),
    effective_from timestamp without time zone DEFAULT now() NOT NULL,
    effective_to timestamp without time zone,
    created_by bigint,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.item_vendor_prices OWNER TO postgres;

--
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.item_vendor_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.item_vendor_prices_id_seq OWNER TO postgres;

--
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.item_vendor_prices_id_seq OWNED BY selemti.item_vendor_prices.id;


--
-- Name: items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.items (
    id character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    categoria_id character varying(10) NOT NULL,
    unidad_medida character varying(10) DEFAULT 'PZ'::character varying NOT NULL,
    perishable boolean DEFAULT false,
    temperatura_min integer,
    temperatura_max integer,
    costo_promedio numeric(10,2) DEFAULT 0.00,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    unidad_medida_id integer,
    factor_conversion numeric(12,6) DEFAULT 1.0,
    unidad_compra_id integer,
    factor_compra numeric(12,6) DEFAULT 1.0,
    tipo selemti.producto_tipo,
    unidad_salida_id integer,
    category_id bigint,
    item_code character varying(32),
    es_producible boolean DEFAULT false NOT NULL,
    es_consumible_operativo boolean DEFAULT false NOT NULL,
    es_empaque_to_go boolean DEFAULT false NOT NULL,
    CONSTRAINT items_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric)),
    CONSTRAINT items_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_unidad_medida_check CHECK (((unidad_medida)::text = ANY (ARRAY[('KG'::character varying)::text, ('L'::character varying)::text, ('PZ'::character varying)::text, ('BULTO'::character varying)::text, ('CAJA'::character varying)::text])))
);


ALTER TABLE selemti.items OWNER TO postgres;

--
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.items IS 'CatÃ¡logo de items/insumos - Consolidada en Phase 2.3';


--
-- Name: COLUMN items.unidad_medida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.unidad_medida_id IS 'Unidad BASE de inventario (KG, L, PZ) - FK a cat_unidades';


--
-- Name: COLUMN items.factor_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.factor_conversion IS 'Factor adicional de conversión si se requiere (legacy, en desuso)';


--
-- Name: COLUMN items.unidad_compra_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.unidad_compra_id IS 'Unidad de COMPRA del proveedor (CAJA, PAQUETE, COSTAL, etc) - FK a cat_unidades';


--
-- Name: COLUMN items.factor_compra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.factor_compra IS 'Factor de conversión: 1 unidad_compra = X unidades_base. Ej: 1 CAJA = 12 L';


--
-- Name: COLUMN items.unidad_salida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.unidad_salida_id IS 'Unidad de SALIDA para recetas (ML, TAZA, PORCION, etc) - FK a cat_unidades';


--
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- Name: COLUMN items.es_empaque_to_go; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.items.es_empaque_to_go IS 'Marks items as to-go packaging.';


--
-- Name: job_batches; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE selemti.job_batches OWNER TO postgres;

--
-- Name: job_recalc_queue; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.job_recalc_queue (
    id bigint NOT NULL,
    scope_type text NOT NULL,
    scope_from date,
    scope_to date,
    item_id character varying(20),
    receta_id character varying(20),
    sucursal_id character varying(30),
    reason text,
    created_ts timestamp without time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    result json,
    CONSTRAINT job_recalc_queue_scope_type_check CHECK ((scope_type = ANY (ARRAY['PERIODO'::text, 'ITEM'::text, 'RECETA'::text, 'SUCURSAL'::text]))),
    CONSTRAINT job_recalc_queue_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'RUNNING'::text, 'DONE'::text, 'FAILED'::text])))
);


ALTER TABLE selemti.job_recalc_queue OWNER TO postgres;

--
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.job_recalc_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.job_recalc_queue_id_seq OWNER TO postgres;

--
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.job_recalc_queue_id_seq OWNED BY selemti.job_recalc_queue.id;


--
-- Name: jobs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE selemti.jobs OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.jobs_id_seq OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.jobs_id_seq OWNED BY selemti.jobs.id;


--
-- Name: labor_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.labor_roles (
    id bigint NOT NULL,
    clave character varying(40) NOT NULL,
    nombre character varying(120) NOT NULL,
    rate_per_hour numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    descripcion text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.labor_roles OWNER TO postgres;

--
-- Name: labor_roles_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.labor_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.labor_roles_id_seq OWNER TO postgres;

--
-- Name: labor_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.labor_roles_id_seq OWNED BY selemti.labor_roles.id;


--
-- Name: lote; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.lote (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    proveedor_id integer,
    codigo text,
    caducidad date,
    estado selemti.lote_estado DEFAULT 'ACTIVO'::selemti.lote_estado NOT NULL,
    creado_ts timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.lote OWNER TO postgres;

--
-- Name: lote_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.lote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.lote_id_seq OWNER TO postgres;

--
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.lote_id_seq OWNED BY selemti.lote.id;


--
-- Name: menu_engineering_snapshots; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.menu_engineering_snapshots (
    id bigint NOT NULL,
    menu_item_id bigint NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    units_sold integer DEFAULT 0 NOT NULL,
    net_sales numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    food_cost numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    contribution numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    avg_price numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    avg_cost numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    margin_pct numeric(6,3) DEFAULT '0'::numeric NOT NULL,
    popularity_index numeric(6,3) DEFAULT '0'::numeric NOT NULL,
    classification character varying(20),
    metadata jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.menu_engineering_snapshots OWNER TO postgres;

--
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.menu_engineering_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.menu_engineering_snapshots_id_seq OWNER TO postgres;

--
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.menu_engineering_snapshots_id_seq OWNED BY selemti.menu_engineering_snapshots.id;


--
-- Name: menu_item_sync_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.menu_item_sync_map (
    id bigint NOT NULL,
    menu_item_id bigint NOT NULL,
    pos_identifier character varying(120) NOT NULL,
    channel character varying(40) DEFAULT 'pos'::character varying NOT NULL,
    metadata jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.menu_item_sync_map OWNER TO postgres;

--
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.menu_item_sync_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.menu_item_sync_map_id_seq OWNER TO postgres;

--
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.menu_item_sync_map_id_seq OWNED BY selemti.menu_item_sync_map.id;


--
-- Name: menu_items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.menu_items (
    id bigint NOT NULL,
    recipe_id bigint,
    plu character varying(80) NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(255),
    active boolean DEFAULT true NOT NULL,
    metadata jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.menu_items OWNER TO postgres;

--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.menu_items_id_seq OWNER TO postgres;

--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.menu_items_id_seq OWNED BY selemti.menu_items.id;


--
-- Name: merma; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.merma (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    tipo selemti.merma_tipo NOT NULL,
    item_id character varying(20) NOT NULL,
    batch_id bigint,
    op_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    usuario_id bigint,
    motivo text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.merma OWNER TO postgres;

--
-- Name: merma_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.merma_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.merma_id_seq OWNER TO postgres;

--
-- Name: merma_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.merma_id_seq OWNED BY selemti.merma.id;


--
-- Name: migrations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE selemti.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.migrations_id_seq OWNED BY selemti.migrations.id;


--
-- Name: model_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE selemti.model_has_permissions OWNER TO postgres;

--
-- Name: model_has_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE selemti.model_has_roles OWNER TO postgres;

--
-- Name: modificadores_pos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.modificadores_pos (
    id integer NOT NULL,
    codigo_pos character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(20),
    precio_extra numeric(10,2) DEFAULT 0,
    receta_modificador_id character varying(20),
    activo boolean DEFAULT true,
    CONSTRAINT modificadores_pos_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('AGREGADO'::character varying)::text, ('SUSTITUCION'::character varying)::text, ('ELIMINACION'::character varying)::text])))
);


ALTER TABLE selemti.modificadores_pos OWNER TO postgres;

--
-- Name: modificadores_pos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.modificadores_pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.modificadores_pos_id_seq OWNER TO postgres;

--
-- Name: modificadores_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.modificadores_pos_id_seq OWNED BY selemti.modificadores_pos.id;


--
-- Name: mov_inv; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.mov_inv (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    item_id character varying(20) NOT NULL,
    lote_id integer,
    cantidad numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    costo_unit numeric(14,6) DEFAULT 0,
    tipo character varying(20) NOT NULL,
    ref_tipo character varying(50),
    ref_id bigint,
    sucursal_id character varying(30),
    usuario_id integer,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT mov_inv_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('ENTRADA'::character varying)::text, ('SALIDA'::character varying)::text, ('AJUSTE'::character varying)::text, ('MERMA'::character varying)::text, ('TRASPASO'::character varying)::text])))
);


ALTER TABLE selemti.mov_inv OWNER TO postgres;

--
-- Name: TABLE mov_inv; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.mov_inv IS 'Kardex completo de movimientos de inventario.';


--
-- Name: mov_inv_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.mov_inv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.mov_inv_id_seq OWNER TO postgres;

--
-- Name: mov_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.mov_inv_id_seq OWNED BY selemti.mov_inv.id;


--
-- Name: mv_inventario_actual; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW selemti.mv_inventario_actual AS
 SELECT i.id AS item_id,
    i.nombre AS item_nombre,
    i.categoria_id,
    i.unidad_medida,
    count(DISTINCT ib.id) AS total_lotes,
    COALESCE(sum(ib.cantidad_actual), (0)::numeric) AS cantidad_total,
    COALESCE(avg(ib.unit_cost), (0)::numeric) AS costo_promedio,
    COALESCE(sum((ib.cantidad_actual * ib.unit_cost)), (0)::numeric) AS valor_total,
    max(ib.updated_at) AS ultima_actualizacion
   FROM (selemti.items i
     LEFT JOIN selemti.inventory_batch ib ON (((ib.item_id)::text = (i.id)::text)))
  WHERE ((i.activo = true) AND ((ib.estado IS NULL) OR ((ib.estado)::text = 'DISPONIBLE'::text)))
  GROUP BY i.id, i.nombre, i.categoria_id, i.unidad_medida
  WITH NO DATA;


ALTER TABLE selemti.mv_inventario_actual OWNER TO postgres;

--
-- Name: receta_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta_cab (
    id character varying(20) NOT NULL,
    nombre_plato character varying(100) NOT NULL,
    codigo_plato_pos character varying(20),
    categoria_plato character varying(50),
    porciones_standard integer DEFAULT 1,
    instrucciones_preparacion text,
    tiempo_preparacion_min integer,
    costo_standard_porcion numeric(10,2) DEFAULT 0,
    precio_venta_sugerido numeric(10,2) DEFAULT 0,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_cab_id_check CHECK (((id)::text ~ '^REC-[A-Z0-9\-]+$'::text)),
    CONSTRAINT receta_cab_porciones_standard_check CHECK ((porciones_standard > 0))
);


ALTER TABLE selemti.receta_cab OWNER TO postgres;

--
-- Name: TABLE receta_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.receta_cab IS 'CatÃ¡logo de recetas - Consolidada en Phase 2.4';


--
-- Name: receta_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta_det (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(10,4) NOT NULL,
    unidad_medida character varying(10) NOT NULL,
    merma_porcentaje numeric(5,2) DEFAULT 0,
    instrucciones_especificas text,
    orden integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_det_cantidad_check CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT receta_det_merma_porcentaje_check CHECK (((merma_porcentaje >= (0)::numeric) AND (merma_porcentaje <= (100)::numeric)))
);


ALTER TABLE selemti.receta_det OWNER TO postgres;

--
-- Name: TABLE receta_det; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.receta_det IS 'Detalle de ingredientes de recetas - Consolidada en Phase 2.4';


--
-- Name: receta_version; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta_version (
    id integer NOT NULL,
    receta_id character varying(20) NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    descripcion_cambios text,
    fecha_efectiva date NOT NULL,
    version_publicada boolean DEFAULT false,
    usuario_publicador integer,
    fecha_publicacion timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.receta_version OWNER TO postgres;

--
-- Name: TABLE receta_version; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.receta_version IS 'Control de versiones de recetas.';


--
-- Name: mv_recetas_costos; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW selemti.mv_recetas_costos AS
 SELECT rc.id AS receta_id,
    rc.nombre_plato,
    rc.categoria_plato,
    rc.costo_standard_porcion,
    rc.precio_venta_sugerido,
    count(rd.id) AS total_ingredientes,
    rc.activo,
    rc.updated_at
   FROM (selemti.receta_cab rc
     LEFT JOIN selemti.receta_det rd ON ((rd.receta_version_id = ( SELECT receta_version.id
           FROM selemti.receta_version
          WHERE ((receta_version.receta_id)::text = (rc.id)::text)
         LIMIT 1))))
  GROUP BY rc.id, rc.nombre_plato, rc.categoria_plato, rc.costo_standard_porcion, rc.precio_venta_sugerido, rc.activo, rc.updated_at
  WITH NO DATA;


ALTER TABLE selemti.mv_recetas_costos OWNER TO postgres;

--
-- Name: op_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.op_cab (
    id bigint NOT NULL,
    sucursal_id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    cantidad_objetivo numeric(14,6) NOT NULL,
    um_salida_id integer NOT NULL,
    estado selemti.op_estado DEFAULT 'ABIERTA'::selemti.op_estado NOT NULL,
    ts_apertura timestamp without time zone DEFAULT now() NOT NULL,
    ts_cierre timestamp without time zone,
    usuario_abre bigint,
    usuario_cierra bigint,
    lote_salida_id bigint,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.op_cab OWNER TO postgres;

--
-- Name: op_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.op_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.op_cab_id_seq OWNER TO postgres;

--
-- Name: op_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.op_cab_id_seq OWNED BY selemti.op_cab.id;


--
-- Name: op_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.op_insumo (
    id bigint NOT NULL,
    op_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    qty_teorica numeric(14,6) NOT NULL,
    qty_real numeric(14,6),
    um_id integer NOT NULL,
    batch_id bigint,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.op_insumo OWNER TO postgres;

--
-- Name: op_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.op_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.op_insumo_id_seq OWNER TO postgres;

--
-- Name: op_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.op_insumo_id_seq OWNED BY selemti.op_insumo.id;


--
-- Name: op_produccion_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.op_produccion_cab (
    id integer NOT NULL,
    receta_version_id integer NOT NULL,
    cantidad_planeada numeric(10,3) NOT NULL,
    cantidad_real numeric(10,3),
    fecha_produccion date NOT NULL,
    estado character varying(20) DEFAULT 'PENDIENTE'::character varying,
    lote_resultado character varying(50),
    usuario_responsable integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT op_produccion_cab_cantidad_planeada_check CHECK ((cantidad_planeada > (0)::numeric)),
    CONSTRAINT op_produccion_cab_estado_check CHECK (((estado)::text = ANY (ARRAY[('PENDIENTE'::character varying)::text, ('EN_PROCESO'::character varying)::text, ('COMPLETADA'::character varying)::text, ('CANCELADA'::character varying)::text])))
);


ALTER TABLE selemti.op_produccion_cab OWNER TO postgres;

--
-- Name: TABLE op_produccion_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.op_produccion_cab IS 'Cabecera de Ã³rdenes de producciÃ³n.';


--
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.op_produccion_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.op_produccion_cab_id_seq OWNER TO postgres;

--
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.op_produccion_cab_id_seq OWNED BY selemti.op_produccion_cab.id;


--
-- Name: op_yield; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.op_yield (
    op_id bigint NOT NULL,
    cantidad_real numeric(14,6) NOT NULL,
    merma_real numeric(14,6) DEFAULT 0 NOT NULL,
    evidencia_url text,
    meta jsonb
);


ALTER TABLE selemti.op_yield OWNER TO postgres;

--
-- Name: overhead_definitions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.overhead_definitions (
    id bigint NOT NULL,
    clave character varying(60) NOT NULL,
    nombre character varying(160) NOT NULL,
    tipo character varying(40) DEFAULT 'fixed_per_batch'::character varying NOT NULL,
    tasa numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.overhead_definitions OWNER TO postgres;

--
-- Name: overhead_definitions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.overhead_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.overhead_definitions_id_seq OWNER TO postgres;

--
-- Name: overhead_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.overhead_definitions_id_seq OWNED BY selemti.overhead_definitions.id;


--
-- Name: param_sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.param_sucursal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    consumo selemti.consumo_policy DEFAULT 'FEFO'::selemti.consumo_policy NOT NULL,
    tolerancia_precorte_pct numeric(8,4) DEFAULT 0.02,
    tolerancia_corte_abs numeric(12,4) DEFAULT 50.0,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.param_sucursal OWNER TO postgres;

--
-- Name: param_sucursal_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.param_sucursal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.param_sucursal_id_seq OWNER TO postgres;

--
-- Name: param_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.param_sucursal_id_seq OWNED BY selemti.param_sucursal.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE selemti.password_reset_tokens OWNER TO postgres;

--
-- Name: perdida_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.perdida_log (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    item_id text NOT NULL,
    lote_id bigint,
    sucursal_id text,
    clase selemti.merma_clase NOT NULL,
    motivo text,
    qty_canonica numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    evidencia_url text,
    usuario_id integer,
    ref_tipo text,
    ref_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT perdida_log_qty_canonica_check CHECK ((qty_canonica > (0)::numeric))
);


ALTER TABLE selemti.perdida_log OWNER TO postgres;

--
-- Name: perdida_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.perdida_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.perdida_log_id_seq OWNER TO postgres;

--
-- Name: perdida_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.perdida_log_id_seq OWNED BY selemti.perdida_log.id;


--
-- Name: permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.permissions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.permissions OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.permissions_id_seq OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.permissions_id_seq OWNED BY selemti.permissions.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.personal_access_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.personal_access_tokens_id_seq OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.personal_access_tokens_id_seq OWNED BY selemti.personal_access_tokens.id;


--
-- Name: pos_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_map (
    pos_system text NOT NULL,
    plu text NOT NULL,
    tipo text NOT NULL,
    receta_id text,
    receta_version_id integer,
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    meta json,
    vigente_desde timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone,
    CONSTRAINT pos_map_tipo_check CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text])))
);


ALTER TABLE selemti.pos_map OWNER TO postgres;

--
-- Name: pos_modifiers_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_modifiers_map (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    pos_modifier_code text NOT NULL,
    name text,
    effect selemti.pos_modifier_effect NOT NULL,
    linked_recipe_id uuid,
    linked_recipe_version_id uuid,
    delta_qty_canonical numeric(18,6),
    canonical_uom_id uuid,
    delta_cost numeric(14,4),
    active boolean DEFAULT true NOT NULL,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_posmod_semantics CHECK (
CASE effect
    WHEN 'replace'::selemti.pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL))
    WHEN 'extra'::selemti.pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL) OR (delta_qty_canonical IS NOT NULL))
    WHEN 'remove'::selemti.pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL) OR (delta_qty_canonical IS NOT NULL))
    WHEN 'delta'::selemti.pos_modifier_effect THEN (delta_cost IS NOT NULL)
    ELSE false
END)
);


ALTER TABLE selemti.pos_modifiers_map OWNER TO postgres;

--
-- Name: TABLE pos_modifiers_map; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.pos_modifiers_map IS 'Mapa de modificadores POS → impacto en receta/costo/consumo.';


--
-- Name: pos_reprocess_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_reprocess_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reprocessed_at timestamp without time zone DEFAULT now() NOT NULL,
    motivo text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.pos_reprocess_log OWNER TO postgres;

--
-- Name: TABLE pos_reprocess_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.pos_reprocess_log IS 'Log de auditoría de reprocesos de consumo POS histórico';


--
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.pos_reprocess_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.pos_reprocess_log_id_seq OWNER TO postgres;

--
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.pos_reprocess_log_id_seq OWNED BY selemti.pos_reprocess_log.id;


--
-- Name: pos_reverse_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_reverse_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reversed_at timestamp without time zone DEFAULT now() NOT NULL,
    motivo text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.pos_reverse_log OWNER TO postgres;

--
-- Name: TABLE pos_reverse_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.pos_reverse_log IS 'Log de auditoría de reversas de consumo POS';


--
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.pos_reverse_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.pos_reverse_log_id_seq OWNER TO postgres;

--
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.pos_reverse_log_id_seq OWNED BY selemti.pos_reverse_log.id;


--
-- Name: pos_sync_batches; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_sync_batches (
    id bigint NOT NULL,
    source_system character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    started_at timestamp(0) with time zone,
    finished_at timestamp(0) with time zone,
    rows_processed integer DEFAULT 0 NOT NULL,
    rows_successful integer DEFAULT 0 NOT NULL,
    rows_failed integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    errors jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.pos_sync_batches OWNER TO postgres;

--
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.pos_sync_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.pos_sync_batches_id_seq OWNER TO postgres;

--
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.pos_sync_batches_id_seq OWNED BY selemti.pos_sync_batches.id;


--
-- Name: pos_sync_logs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.pos_sync_logs (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    external_id character varying(120),
    action character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    payload jsonb,
    message text,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.pos_sync_logs OWNER TO postgres;

--
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.pos_sync_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.pos_sync_logs_id_seq OWNER TO postgres;

--
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.pos_sync_logs_id_seq OWNED BY selemti.pos_sync_logs.id;


--
-- Name: postcorte; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.postcorte (
    id bigint NOT NULL,
    sesion_id bigint NOT NULL,
    sistema_efectivo_esperado numeric(12,2) DEFAULT 0 NOT NULL,
    declarado_efectivo numeric(12,2) DEFAULT 0 NOT NULL,
    diferencia_efectivo numeric(12,2) DEFAULT 0 NOT NULL,
    veredicto_efectivo text DEFAULT 'CUADRA'::text NOT NULL,
    sistema_tarjetas numeric(12,2) DEFAULT 0 NOT NULL,
    declarado_tarjetas numeric(12,2) DEFAULT 0 NOT NULL,
    diferencia_tarjetas numeric(12,2) DEFAULT 0 NOT NULL,
    veredicto_tarjetas text DEFAULT 'CUADRA'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    notas text,
    sistema_transferencias numeric(12,2) DEFAULT 0 NOT NULL,
    declarado_transferencias numeric(12,2) DEFAULT 0 NOT NULL,
    diferencia_transferencias numeric(12,2) DEFAULT 0 NOT NULL,
    veredicto_transferencias text DEFAULT 'CUADRA'::text NOT NULL,
    validado boolean DEFAULT false NOT NULL,
    validado_por integer,
    validado_en timestamp with time zone,
    requiere_aprobacion boolean DEFAULT false,
    aprobado_por integer,
    aprobado_en timestamp with time zone,
    motivo_irregular text,
    rechazado boolean DEFAULT false,
    motivo_rechazo text,
    CONSTRAINT postcorte_veredicto_efectivo_check CHECK ((veredicto_efectivo = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_tarjetas_check CHECK ((veredicto_tarjetas = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_transfer_check CHECK ((veredicto_transferencias = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text])))
);


ALTER TABLE selemti.postcorte OWNER TO floreant;

--
-- Name: COLUMN postcorte.validado; Type: COMMENT; Schema: selemti; Owner: floreant
--

COMMENT ON COLUMN selemti.postcorte.validado IS 'TRUE cuando el supervisor valida/cierra el postcorte';


--
-- Name: postcorte_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.postcorte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.postcorte_id_seq OWNER TO floreant;

--
-- Name: postcorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.postcorte_id_seq OWNED BY selemti.postcorte.id;


--
-- Name: precorte; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.precorte (
    id bigint NOT NULL,
    sesion_id bigint NOT NULL,
    declarado_efectivo numeric(12,2) DEFAULT 0 NOT NULL,
    declarado_otros numeric(12,2) DEFAULT 0 NOT NULL,
    estatus text DEFAULT 'PENDIENTE'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    ip_cliente inet,
    notas text,
    CONSTRAINT precorte_estatus_check CHECK ((estatus = ANY (ARRAY['PENDIENTE'::text, 'ENVIADO'::text, 'APROBADO'::text, 'RECHAZADO'::text])))
);


ALTER TABLE selemti.precorte OWNER TO floreant;

--
-- Name: precorte_efectivo; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.precorte_efectivo (
    id bigint NOT NULL,
    precorte_id bigint NOT NULL,
    denominacion numeric(12,2) NOT NULL,
    cantidad integer NOT NULL,
    subtotal numeric(12,2) DEFAULT 0 NOT NULL
);


ALTER TABLE selemti.precorte_efectivo OWNER TO floreant;

--
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.precorte_efectivo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.precorte_efectivo_id_seq OWNER TO floreant;

--
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.precorte_efectivo_id_seq OWNED BY selemti.precorte_efectivo.id;


--
-- Name: precorte_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.precorte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.precorte_id_seq OWNER TO floreant;

--
-- Name: precorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.precorte_id_seq OWNED BY selemti.precorte.id;


--
-- Name: precorte_otros; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.precorte_otros (
    id bigint NOT NULL,
    precorte_id bigint NOT NULL,
    tipo text NOT NULL,
    monto numeric(12,2) DEFAULT 0 NOT NULL,
    referencia text,
    evidencia_url text,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.precorte_otros OWNER TO floreant;

--
-- Name: precorte_otros_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.precorte_otros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.precorte_otros_id_seq OWNER TO floreant;

--
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.precorte_otros_id_seq OWNED BY selemti.precorte_otros.id;


--
-- Name: prod_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.prod_cab (
    id bigint NOT NULL,
    sol_id bigint,
    fecha_programada date NOT NULL,
    estado character varying(16) DEFAULT 'PROGRAMADA'::character varying NOT NULL,
    creada_por integer NOT NULL,
    aprobada_por integer,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.prod_cab OWNER TO postgres;

--
-- Name: prod_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.prod_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.prod_cab_id_seq OWNER TO postgres;

--
-- Name: prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.prod_cab_id_seq OWNED BY selemti.prod_cab.id;


--
-- Name: prod_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.prod_det (
    id bigint NOT NULL,
    prod_id bigint,
    sr_id integer NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    rendimiento numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.prod_det OWNER TO postgres;

--
-- Name: prod_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.prod_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.prod_det_id_seq OWNER TO postgres;

--
-- Name: prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.prod_det_id_seq OWNED BY selemti.prod_det.id;


--
-- Name: production_order_inputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.production_order_inputs (
    id bigint NOT NULL,
    production_order_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    inventory_batch_id bigint,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.production_order_inputs OWNER TO postgres;

--
-- Name: production_order_inputs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.production_order_inputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.production_order_inputs_id_seq OWNER TO postgres;

--
-- Name: production_order_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.production_order_inputs_id_seq OWNED BY selemti.production_order_inputs.id;


--
-- Name: production_order_outputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.production_order_outputs (
    id bigint NOT NULL,
    production_order_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    inventory_batch_id bigint,
    lote_producido character varying(120),
    fecha_caducidad date,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.production_order_outputs OWNER TO postgres;

--
-- Name: production_order_outputs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.production_order_outputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.production_order_outputs_id_seq OWNER TO postgres;

--
-- Name: production_order_outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.production_order_outputs_id_seq OWNED BY selemti.production_order_outputs.id;


--
-- Name: production_orders; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.production_orders (
    id bigint NOT NULL,
    folio character varying(40),
    recipe_id bigint,
    item_id character varying(20),
    qty_programada numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    qty_producida numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    qty_merma numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    uom_base character varying(20),
    sucursal_id character varying(36),
    almacen_id character varying(36),
    programado_para timestamp(0) with time zone,
    iniciado_en timestamp(0) with time zone,
    cerrado_en timestamp(0) with time zone,
    estado character varying(24) DEFAULT 'BORRADOR'::character varying NOT NULL,
    creado_por bigint,
    aprobado_por bigint,
    notas text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.production_orders OWNER TO postgres;

--
-- Name: production_orders_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.production_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.production_orders_id_seq OWNER TO postgres;

--
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.production_orders_id_seq OWNED BY selemti.production_orders.id;


--
-- Name: proveedor; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.proveedor (
    id text NOT NULL,
    nombre text NOT NULL,
    rfc text,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE selemti.proveedor OWNER TO postgres;

--
-- Name: purchase_documents; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_documents (
    id bigint NOT NULL,
    request_id bigint,
    quote_id bigint,
    order_id bigint,
    tipo character varying(30) NOT NULL,
    file_url character varying(255) NOT NULL,
    uploaded_by bigint,
    notas text,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_documents OWNER TO postgres;

--
-- Name: purchase_documents_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_documents_id_seq OWNER TO postgres;

--
-- Name: purchase_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_documents_id_seq OWNED BY selemti.purchase_documents.id;


--
-- Name: purchase_order_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_order_lines (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    request_line_id bigint,
    item_id character varying(20) NOT NULL,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    precio_unitario numeric(18,6) NOT NULL,
    descuento numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    impuestos numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    total numeric(18,6) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_order_lines OWNER TO postgres;

--
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_order_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_order_lines_id_seq OWNER TO postgres;

--
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_order_lines_id_seq OWNED BY selemti.purchase_order_lines.id;


--
-- Name: purchase_orders; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_orders (
    id bigint NOT NULL,
    folio character varying(40),
    quote_id bigint,
    vendor_id bigint NOT NULL,
    sucursal_id character varying(36),
    estado character varying(24) DEFAULT 'BORRADOR'::character varying NOT NULL,
    fecha_promesa date,
    subtotal numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    descuento numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    impuestos numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    total numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    creado_por bigint NOT NULL,
    aprobado_por bigint,
    aprobado_en timestamp(0) with time zone,
    notas text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_orders OWNER TO postgres;

--
-- Name: purchase_orders_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_orders_id_seq OWNER TO postgres;

--
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_orders_id_seq OWNED BY selemti.purchase_orders.id;


--
-- Name: purchase_request_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_request_lines (
    id bigint NOT NULL,
    request_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    fecha_requerida date,
    preferred_vendor_id bigint,
    last_price numeric(18,6),
    estado character varying(24) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_request_lines OWNER TO postgres;

--
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_request_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_request_lines_id_seq OWNER TO postgres;

--
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_request_lines_id_seq OWNED BY selemti.purchase_request_lines.id;


--
-- Name: purchase_requests; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_requests (
    id bigint NOT NULL,
    folio character varying(40),
    sucursal_id character varying(36),
    created_by bigint NOT NULL,
    requested_by bigint,
    requested_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    estado character varying(24) DEFAULT 'BORRADOR'::character varying NOT NULL,
    importe_estimado numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    notas text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    fecha_requerida date,
    almacen_destino_id bigint,
    justificacion text,
    urgente boolean DEFAULT false NOT NULL,
    origen_suggestion_id bigint
);


ALTER TABLE selemti.purchase_requests OWNER TO postgres;

--
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_requests.fecha_requerida IS 'Fecha límite operativa';


--
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- Name: COLUMN purchase_requests.origen_suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_requests.origen_suggestion_id IS 'FK a purchase_suggestions - si fue generada automáticamente';


--
-- Name: purchase_requests_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_requests_id_seq OWNER TO postgres;

--
-- Name: purchase_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_requests_id_seq OWNED BY selemti.purchase_requests.id;


--
-- Name: purchase_suggestion_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_suggestion_lines (
    id bigint NOT NULL,
    suggestion_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    stock_actual numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    stock_min numeric(18,6) NOT NULL,
    stock_max numeric(18,6) NOT NULL,
    reorder_point numeric(18,6),
    consumo_promedio_diario numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    dias_cobertura_actual integer DEFAULT 0 NOT NULL,
    demanda_proyectada numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    qty_sugerida numeric(18,6) NOT NULL,
    qty_ajustada numeric(18,6),
    uom character varying(10) NOT NULL,
    costo_unitario_estimado numeric(18,6),
    costo_total_linea numeric(18,2),
    proveedor_sugerido_id bigint,
    ultimo_precio_compra numeric(18,6),
    fecha_ultima_compra date,
    notas text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.purchase_suggestion_lines OWNER TO postgres;

--
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- Name: COLUMN purchase_suggestion_lines.proveedor_sugerido_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestion_lines.proveedor_sugerido_id IS 'FK a selemti.cat_proveedores.id';


--
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_suggestion_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_suggestion_lines_id_seq OWNER TO postgres;

--
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_suggestion_lines_id_seq OWNED BY selemti.purchase_suggestion_lines.id;


--
-- Name: purchase_suggestions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_suggestions (
    id bigint NOT NULL,
    folio character varying(20) NOT NULL,
    sucursal_id bigint,
    almacen_id bigint,
    estado character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    prioridad character varying(20) DEFAULT 'NORMAL'::character varying NOT NULL,
    origen character varying(20) DEFAULT 'AUTO'::character varying NOT NULL,
    total_items integer DEFAULT 0 NOT NULL,
    total_estimado numeric(18,2) DEFAULT '0'::numeric NOT NULL,
    sugerido_en timestamp(0) without time zone DEFAULT now() NOT NULL,
    sugerido_por_user_id bigint,
    revisado_por_user_id bigint,
    revisado_en timestamp(0) without time zone,
    convertido_a_request_id bigint,
    convertido_en timestamp(0) without time zone,
    dias_analisis integer DEFAULT 7 NOT NULL,
    consumo_promedio_calculado boolean DEFAULT true NOT NULL,
    notas text,
    meta jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.purchase_suggestions OWNER TO postgres;

--
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- Name: COLUMN purchase_suggestions.dias_analisis; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.purchase_suggestions.dias_analisis IS 'Días usados para calcular consumo promedio';


--
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_suggestions_id_seq OWNER TO postgres;

--
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_suggestions_id_seq OWNED BY selemti.purchase_suggestions.id;


--
-- Name: purchase_vendor_quote_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_vendor_quote_lines (
    id bigint NOT NULL,
    quote_id bigint NOT NULL,
    request_line_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    qty_oferta numeric(18,6) NOT NULL,
    uom_oferta character varying(20) NOT NULL,
    precio_unitario numeric(18,6) NOT NULL,
    pack_size numeric(18,6) DEFAULT '1'::numeric NOT NULL,
    pack_uom character varying(20),
    monto_total numeric(18,6) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_vendor_quote_lines OWNER TO postgres;

--
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_vendor_quote_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_vendor_quote_lines_id_seq OWNER TO postgres;

--
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_vendor_quote_lines_id_seq OWNED BY selemti.purchase_vendor_quote_lines.id;


--
-- Name: purchase_vendor_quotes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.purchase_vendor_quotes (
    id bigint NOT NULL,
    request_id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    folio_proveedor character varying(60),
    estado character varying(24) DEFAULT 'RECIBIDA'::character varying NOT NULL,
    enviada_en timestamp(0) with time zone DEFAULT now() NOT NULL,
    recibida_en timestamp(0) with time zone,
    subtotal numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    descuento numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    impuestos numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    total numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    capturada_por bigint,
    aprobada_por bigint,
    aprobada_en timestamp(0) with time zone,
    notas text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.purchase_vendor_quotes OWNER TO postgres;

--
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.purchase_vendor_quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.purchase_vendor_quotes_id_seq OWNER TO postgres;

--
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.purchase_vendor_quotes_id_seq OWNED BY selemti.purchase_vendor_quotes.id;


--
-- Name: recalc_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recalc_log (
    id bigint NOT NULL,
    job_id bigint,
    step text,
    started_ts timestamp without time zone,
    ended_ts timestamp without time zone,
    ok boolean,
    details json
);


ALTER TABLE selemti.recalc_log OWNER TO postgres;

--
-- Name: recalc_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recalc_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recalc_log_id_seq OWNER TO postgres;

--
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recalc_log_id_seq OWNED BY selemti.recalc_log.id;


--
-- Name: recepcion_adjuntos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recepcion_adjuntos (
    id bigint NOT NULL,
    recepcion_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    file_url character varying(255) NOT NULL,
    notas text,
    uploaded_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.recepcion_adjuntos OWNER TO postgres;

--
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recepcion_adjuntos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recepcion_adjuntos_id_seq OWNER TO postgres;

--
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recepcion_adjuntos_id_seq OWNED BY selemti.recepcion_adjuntos.id;


--
-- Name: recepcion_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recepcion_cab (
    id bigint NOT NULL,
    sucursal_id bigint NOT NULL,
    proveedor_id integer,
    oc_ref text,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    usuario_id bigint,
    meta jsonb,
    almacen_id character varying(36),
    numero_recepcion character varying(255),
    fecha_recepcion date,
    estado character varying(255),
    total_presentaciones numeric(15,4),
    total_canonico numeric(15,4),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.recepcion_cab OWNER TO postgres;

--
-- Name: recepcion_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recepcion_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recepcion_cab_id_seq OWNER TO postgres;

--
-- Name: recepcion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recepcion_cab_id_seq OWNED BY selemti.recepcion_cab.id;


--
-- Name: recepcion_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recepcion_det (
    id bigint NOT NULL,
    recepcion_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    bodega_id bigint NOT NULL,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    costo_unit numeric(14,6) NOT NULL,
    batch_id bigint,
    temperatura numeric(6,2),
    doc_url text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.recepcion_det OWNER TO postgres;

--
-- Name: recepcion_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recepcion_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recepcion_det_id_seq OWNER TO postgres;

--
-- Name: recepcion_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recepcion_det_id_seq OWNED BY selemti.recepcion_det.id;


--
-- Name: receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta (
    id bigint NOT NULL,
    codigo text,
    nombre text NOT NULL,
    porciones numeric(12,4) DEFAULT 1.0 NOT NULL,
    pvp_objetivo numeric(12,4),
    activo boolean DEFAULT true NOT NULL,
    meta jsonb
);


ALTER TABLE selemti.receta OWNER TO postgres;

--
-- Name: receta_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.receta_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.receta_det_id_seq OWNER TO postgres;

--
-- Name: receta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.receta_det_id_seq OWNED BY selemti.receta_det.id;


--
-- Name: receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.receta_id_seq OWNER TO postgres;

--
-- Name: receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.receta_id_seq OWNED BY selemti.receta.id;


--
-- Name: receta_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta_insumo (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(14,6) NOT NULL
);


ALTER TABLE selemti.receta_insumo OWNER TO postgres;

--
-- Name: receta_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.receta_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.receta_insumo_id_seq OWNER TO postgres;

--
-- Name: receta_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.receta_insumo_id_seq OWNED BY selemti.receta_insumo.id;


--
-- Name: receta_shadow; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.receta_shadow (
    id integer NOT NULL,
    codigo_plato_pos character varying(20) NOT NULL,
    nombre_plato character varying(100) NOT NULL,
    estado character varying(15) DEFAULT 'INFERIDA'::character varying,
    confianza numeric(5,4) DEFAULT 0.0,
    total_ventas_analizadas integer DEFAULT 0,
    fecha_primer_venta date,
    fecha_ultima_venta date,
    frecuencia_dias numeric(10,2),
    ingredientes_inferidos json,
    usuario_validador integer,
    fecha_validacion timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT receta_shadow_confianza_check CHECK (((confianza >= (0)::numeric) AND (confianza <= (1)::numeric))),
    CONSTRAINT receta_shadow_estado_check CHECK (((estado)::text = ANY (ARRAY[('INFERIDA'::character varying)::text, ('VALIDADA'::character varying)::text, ('DESCARTADA'::character varying)::text])))
);


ALTER TABLE selemti.receta_shadow OWNER TO postgres;

--
-- Name: receta_shadow_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.receta_shadow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.receta_shadow_id_seq OWNER TO postgres;

--
-- Name: receta_shadow_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.receta_shadow_id_seq OWNED BY selemti.receta_shadow.id;


--
-- Name: receta_version_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.receta_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.receta_version_id_seq OWNER TO postgres;

--
-- Name: receta_version_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.receta_version_id_seq OWNED BY selemti.receta_version.id;


--
-- Name: recipe_cost_history; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_cost_history (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    recipe_version_id bigint,
    snapshot_at timestamp without time zone NOT NULL,
    currency_code character varying(10) DEFAULT 'MXN'::character varying,
    batch_cost numeric(14,6),
    portion_cost numeric(14,6),
    batch_size numeric(14,6),
    yield_portions numeric(14,6),
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.recipe_cost_history OWNER TO postgres;

--
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_cost_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_cost_history_id_seq OWNER TO postgres;

--
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_cost_history_id_seq OWNED BY selemti.recipe_cost_history.id;


--
-- Name: recipe_cost_snapshots; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_cost_snapshots (
    id bigint NOT NULL,
    recipe_id character varying(50) NOT NULL,
    snapshot_date timestamp without time zone NOT NULL,
    cost_total numeric(15,4) DEFAULT 0 NOT NULL,
    cost_per_portion numeric(15,4) DEFAULT 0 NOT NULL,
    portions numeric(10,3) DEFAULT 1 NOT NULL,
    cost_breakdown jsonb DEFAULT '[]'::jsonb NOT NULL,
    reason character varying(100) NOT NULL,
    created_by_user_id bigint,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.recipe_cost_snapshots OWNER TO postgres;

--
-- Name: TABLE recipe_cost_snapshots; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.recipe_cost_snapshots IS 'Snapshots historicos de costos de recetas para auditoria y performance';


--
-- Name: COLUMN recipe_cost_snapshots.cost_breakdown; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.recipe_cost_snapshots.cost_breakdown IS 'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';


--
-- Name: COLUMN recipe_cost_snapshots.reason; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.recipe_cost_snapshots.reason IS 'MANUAL: Creado manualmente por usuario\n     AUTO_THRESHOLD: Creado automaticamente por cambio >2% en costo\n     INGREDIENT_CHANGE: Creado por modificacion de ingredientes\n     SCHEDULED: Creado por job programado (cierre de dia)';


--
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_cost_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_cost_snapshots_id_seq OWNER TO postgres;

--
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_cost_snapshots_id_seq OWNED BY selemti.recipe_cost_snapshots.id;


--
-- Name: recipe_extended_cost_history; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_extended_cost_history (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    snapshot_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    mp_batch_cost numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    labor_batch_cost numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    overhead_batch_cost numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    total_batch_cost numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    portion_cost numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    yield_portions numeric(18,6) DEFAULT '0'::numeric NOT NULL,
    breakdown jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.recipe_extended_cost_history OWNER TO postgres;

--
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_extended_cost_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_extended_cost_history_id_seq OWNER TO postgres;

--
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_extended_cost_history_id_seq OWNED BY selemti.recipe_extended_cost_history.id;


--
-- Name: recipe_labor_steps; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_labor_steps (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    labor_role_id bigint,
    nombre character varying(160) NOT NULL,
    duracion_minutos numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    costo_manual numeric(18,6),
    orden integer DEFAULT 0 NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.recipe_labor_steps OWNER TO postgres;

--
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_labor_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_labor_steps_id_seq OWNER TO postgres;

--
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_labor_steps_id_seq OWNED BY selemti.recipe_labor_steps.id;


--
-- Name: recipe_overhead_allocations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_overhead_allocations (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    overhead_id bigint NOT NULL,
    valor numeric(18,6),
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.recipe_overhead_allocations OWNER TO postgres;

--
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_overhead_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_overhead_allocations_id_seq OWNER TO postgres;

--
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_overhead_allocations_id_seq OWNED BY selemti.recipe_overhead_allocations.id;


--
-- Name: recipe_version_items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_version_items (
    id bigint NOT NULL,
    recipe_version_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    qty numeric(14,6) NOT NULL,
    uom_receta character varying(20) NOT NULL
);


ALTER TABLE selemti.recipe_version_items OWNER TO postgres;

--
-- Name: recipe_version_items_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_version_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_version_items_id_seq OWNER TO postgres;

--
-- Name: recipe_version_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_version_items_id_seq OWNED BY selemti.recipe_version_items.id;


--
-- Name: recipe_versions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.recipe_versions (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    version_no integer NOT NULL,
    notes text,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.recipe_versions OWNER TO postgres;

--
-- Name: recipe_versions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.recipe_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.recipe_versions_id_seq OWNER TO postgres;

--
-- Name: recipe_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.recipe_versions_id_seq OWNED BY selemti.recipe_versions.id;


--
-- Name: replenishment_suggestions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.replenishment_suggestions (
    id bigint NOT NULL,
    folio character varying(40),
    tipo character varying(20) NOT NULL,
    prioridad character varying(20) DEFAULT 'NORMAL'::character varying NOT NULL,
    origen character varying(40) DEFAULT 'AUTO'::character varying NOT NULL,
    item_id character varying(20) NOT NULL,
    sucursal_id bigint,
    almacen_id bigint,
    stock_actual numeric(18,6) NOT NULL,
    stock_min numeric(18,6) NOT NULL,
    stock_max numeric(18,6) NOT NULL,
    qty_sugerida numeric(18,6) NOT NULL,
    qty_aprobada numeric(18,6),
    uom character varying(20) NOT NULL,
    consumo_promedio_diario numeric(18,6),
    dias_stock_restante integer,
    fecha_agotamiento_estimada date,
    estado character varying(24) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    purchase_request_id bigint,
    production_order_id bigint,
    sugerido_en timestamp(0) with time zone DEFAULT now() NOT NULL,
    revisado_en timestamp(0) with time zone,
    revisado_por bigint,
    convertido_en timestamp(0) with time zone,
    caduca_en timestamp(0) with time zone,
    motivo text,
    motivo_rechazo text,
    notas text,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.replenishment_suggestions OWNER TO postgres;

--
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.item_id IS 'FK to items.id';


--
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.notas IS 'Notas del usuario';


--
-- Name: COLUMN replenishment_suggestions.meta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.replenishment_suggestions.meta IS 'Metadata: proveedor preferido, evento, etc.';


--
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.replenishment_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.replenishment_suggestions_id_seq OWNER TO postgres;

--
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.replenishment_suggestions_id_seq OWNED BY selemti.replenishment_suggestions.id;


--
-- Name: report_definitions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.report_definitions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    category character varying(255),
    config jsonb NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.report_definitions OWNER TO postgres;

--
-- Name: report_definitions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.report_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.report_definitions_id_seq OWNER TO postgres;

--
-- Name: report_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.report_definitions_id_seq OWNED BY selemti.report_definitions.id;


--
-- Name: report_favorites; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.report_favorites (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    report_key character varying(120) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.report_favorites OWNER TO postgres;

--
-- Name: report_favorites_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.report_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.report_favorites_id_seq OWNER TO postgres;

--
-- Name: report_favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.report_favorites_id_seq OWNED BY selemti.report_favorites.id;


--
-- Name: report_runs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.report_runs (
    id bigint NOT NULL,
    report_id bigint NOT NULL,
    requested_by bigint,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    filters jsonb,
    result_meta jsonb,
    storage_path character varying(255),
    queued_at timestamp(0) with time zone,
    started_at timestamp(0) with time zone,
    finished_at timestamp(0) with time zone,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE selemti.report_runs OWNER TO postgres;

--
-- Name: report_runs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.report_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.report_runs_id_seq OWNER TO postgres;

--
-- Name: report_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.report_runs_id_seq OWNED BY selemti.report_runs.id;


--
-- Name: rol; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.rol (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE selemti.rol OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.rol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.rol_id_seq OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.rol_id_seq OWNED BY selemti.rol.id;


--
-- Name: role_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE selemti.role_has_permissions OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    display_name character varying(255),
    description text,
    color character varying(7)
);


ALTER TABLE selemti.roles OWNER TO postgres;

--
-- Name: TABLE roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.roles IS 'Tabla de roles (Spatie Permission) - Consolidada en Phase 2.1';


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.roles_id_seq OWNED BY selemti.roles.id;


--
-- Name: seq_cat_codigo; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.seq_cat_codigo
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.seq_cat_codigo OWNER TO postgres;

--
-- Name: sesion_cajon; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE selemti.sesion_cajon (
    id bigint NOT NULL,
    sucursal text,
    terminal_id integer NOT NULL,
    terminal_nombre text,
    cajero_usuario_id integer NOT NULL,
    apertura_ts timestamp with time zone DEFAULT now() NOT NULL,
    cierre_ts timestamp with time zone,
    estatus text DEFAULT 'ACTIVA'::text NOT NULL,
    opening_float numeric(12,2) DEFAULT 0 NOT NULL,
    closing_float numeric(12,2),
    dah_evento_id integer,
    skipped_precorte boolean DEFAULT false NOT NULL,
    CONSTRAINT sesion_cajon_estatus_check CHECK ((estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'EN_CORTE'::text, 'CERRADA'::text])))
);


ALTER TABLE selemti.sesion_cajon OWNER TO floreant;

--
-- Name: sesion_cajon_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE selemti.sesion_cajon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.sesion_cajon_id_seq OWNER TO floreant;

--
-- Name: sesion_cajon_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE selemti.sesion_cajon_id_seq OWNED BY selemti.sesion_cajon.id;


--
-- Name: sessions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE selemti.sessions OWNER TO postgres;

--
-- Name: sol_prod_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.sol_prod_cab (
    id bigint NOT NULL,
    sucursal_id integer NOT NULL,
    fecha date DEFAULT ('now'::text)::date NOT NULL,
    estado character varying(16) DEFAULT 'SOLICITADA'::character varying NOT NULL,
    solicitada_por integer NOT NULL,
    autorizada_por integer,
    observaciones text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.sol_prod_cab OWNER TO postgres;

--
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.sol_prod_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.sol_prod_cab_id_seq OWNER TO postgres;

--
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.sol_prod_cab_id_seq OWNED BY selemti.sol_prod_cab.id;


--
-- Name: sol_prod_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.sol_prod_det (
    id bigint NOT NULL,
    sol_id bigint,
    plu integer NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    cantidad_autorizada numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.sol_prod_det OWNER TO postgres;

--
-- Name: sol_prod_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.sol_prod_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.sol_prod_det_id_seq OWNER TO postgres;

--
-- Name: sol_prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.sol_prod_det_id_seq OWNED BY selemti.sol_prod_det.id;


--
-- Name: stock_policy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.stock_policy (
    id bigint NOT NULL,
    item_id text NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text,
    min_qty numeric(14,6) DEFAULT 0 NOT NULL,
    max_qty numeric(14,6) DEFAULT 0 NOT NULL,
    reorder_lote numeric(14,6),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.stock_policy OWNER TO postgres;

--
-- Name: stock_policy_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.stock_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.stock_policy_id_seq OWNER TO postgres;

--
-- Name: stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.stock_policy_id_seq OWNED BY selemti.stock_policy.id;


--
-- Name: sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE selemti.sucursal OWNER TO postgres;

--
-- Name: sucursal_almacen_terminal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.sucursal_almacen_terminal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text NOT NULL,
    terminal_id integer,
    location text,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.sucursal_almacen_terminal OWNER TO postgres;

--
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.sucursal_almacen_terminal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.sucursal_almacen_terminal_id_seq OWNER TO postgres;

--
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.sucursal_almacen_terminal_id_seq OWNED BY selemti.sucursal_almacen_terminal.id;


--
-- Name: ticket_det_consumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.ticket_det_consumo (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    ticket_det_id bigint NOT NULL,
    item_id text NOT NULL,
    lote_id bigint,
    qty_canonica numeric(14,6) NOT NULL,
    qty_original numeric(14,6),
    uom_original_id integer,
    sucursal_id text,
    ref_tipo text,
    ref_id bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone,
    CONSTRAINT ticket_det_consumo_qty_canonica_check CHECK ((qty_canonica > (0)::numeric))
);


ALTER TABLE selemti.ticket_det_consumo OWNER TO postgres;

--
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.ticket_det_consumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.ticket_det_consumo_id_seq OWNER TO postgres;

--
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.ticket_det_consumo_id_seq OWNED BY selemti.ticket_det_consumo.id;


--
-- Name: ticket_item_modifiers; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.ticket_item_modifiers (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    ticket_item_id bigint NOT NULL,
    sucursal_id bigint,
    terminal_id bigint,
    procesado boolean DEFAULT false NOT NULL,
    fecha_proceso timestamp(0) without time zone,
    pos_code character varying(255),
    recipe_version_id bigint,
    precio_extra numeric(12,4) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE selemti.ticket_item_modifiers OWNER TO postgres;

--
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- Name: COLUMN ticket_item_modifiers.precio_extra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN selemti.ticket_item_modifiers.precio_extra IS 'Sobrecargo aplicado por el POS.';


--
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.ticket_item_modifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.ticket_item_modifiers_id_seq OWNER TO postgres;

--
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.ticket_item_modifiers_id_seq OWNED BY selemti.ticket_item_modifiers.id;


--
-- Name: ticket_venta_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.ticket_venta_cab (
    id bigint NOT NULL,
    numero_ticket character varying(50) NOT NULL,
    fecha_venta timestamp without time zone DEFAULT now() NOT NULL,
    sucursal_id character varying(10) NOT NULL,
    terminal_id integer,
    total_venta numeric(12,2) DEFAULT 0,
    estado character varying(20) DEFAULT 'ABIERTO'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT ticket_venta_cab_estado_check CHECK (((estado)::text = ANY (ARRAY[('ABIERTO'::character varying)::text, ('CERRADO'::character varying)::text, ('ANULADO'::character varying)::text])))
);


ALTER TABLE selemti.ticket_venta_cab OWNER TO postgres;

--
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.ticket_venta_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.ticket_venta_cab_id_seq OWNER TO postgres;

--
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.ticket_venta_cab_id_seq OWNED BY selemti.ticket_venta_cab.id;


--
-- Name: ticket_venta_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.ticket_venta_det (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(10,3) NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    receta_version_id integer,
    created_at timestamp without time zone DEFAULT now(),
    receta_shadow_id integer,
    reprocesado boolean DEFAULT false,
    version_reproceso integer DEFAULT 1,
    modificadores_aplicados json,
    CONSTRAINT ticket_venta_det_cantidad_check CHECK ((cantidad > (0)::numeric))
);


ALTER TABLE selemti.ticket_venta_det OWNER TO postgres;

--
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.ticket_venta_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.ticket_venta_det_id_seq OWNER TO postgres;

--
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.ticket_venta_det_id_seq OWNED BY selemti.ticket_venta_det.id;


--
-- Name: transfer_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.transfer_cab (
    id bigint NOT NULL,
    origen_almacen_id integer NOT NULL,
    destino_almacen_id integer NOT NULL,
    estado character varying(16) DEFAULT 'CREADA'::character varying NOT NULL,
    creada_por integer NOT NULL,
    despachada_por integer,
    recibida_por integer,
    guia character varying(64),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.transfer_cab OWNER TO postgres;

--
-- Name: transfer_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.transfer_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.transfer_cab_id_seq OWNER TO postgres;

--
-- Name: transfer_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.transfer_cab_id_seq OWNED BY selemti.transfer_cab.id;


--
-- Name: transfer_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.transfer_det (
    id bigint NOT NULL,
    transfer_id bigint,
    item_id character varying(20) NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    cantidad_despachada numeric(12,3),
    cantidad_recibida numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE selemti.transfer_det OWNER TO postgres;

--
-- Name: transfer_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.transfer_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.transfer_det_id_seq OWNER TO postgres;

--
-- Name: transfer_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.transfer_det_id_seq OWNED BY selemti.transfer_det.id;


--
-- Name: traspaso_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.traspaso_cab (
    id bigint NOT NULL,
    from_bodega_id bigint NOT NULL,
    to_bodega_id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    usuario_id bigint,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.traspaso_cab OWNER TO postgres;

--
-- Name: traspaso_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.traspaso_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.traspaso_cab_id_seq OWNER TO postgres;

--
-- Name: traspaso_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.traspaso_cab_id_seq OWNED BY selemti.traspaso_cab.id;


--
-- Name: traspaso_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.traspaso_det (
    id bigint NOT NULL,
    traspaso_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    batch_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE selemti.traspaso_det OWNER TO postgres;

--
-- Name: traspaso_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.traspaso_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.traspaso_det_id_seq OWNER TO postgres;

--
-- Name: traspaso_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.traspaso_det_id_seq OWNED BY selemti.traspaso_det.id;


--
-- Name: unidad_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.unidad_medida AS
 SELECT (cat_unidades.id)::integer AS id,
    cat_unidades.clave AS codigo,
    cat_unidades.nombre,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('KG'::character varying)::text, ('G'::character varying)::text, ('MG'::character varying)::text, ('LB'::character varying)::text, ('OZ'::character varying)::text])) THEN 'PESO'::text
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('L'::character varying)::text, ('ML'::character varying)::text, ('M3'::character varying)::text, ('FLOZ'::character varying)::text, ('CUP'::character varying)::text, ('TBSP'::character varying)::text, ('TSP'::character varying)::text])) THEN 'VOLUMEN'::text
            WHEN ((cat_unidades.clave)::text = 'PZ'::text) THEN 'UNIDAD'::text
            ELSE 'UNIDAD'::text
        END AS tipo,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('KG'::character varying)::text, ('L'::character varying)::text, ('PZ'::character varying)::text])) THEN true
            ELSE false
        END AS es_base,
    1.0::numeric(14,6) AS factor_a_base,
    2 AS decimales
   FROM selemti.cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE selemti.unidad_medida OWNER TO postgres;

--
-- Name: VIEW unidad_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.unidad_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidad_medida';


--
-- Name: unidad_medida_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.unidad_medida_legacy (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    tipo text NOT NULL,
    es_base boolean DEFAULT false NOT NULL,
    factor_a_base numeric(14,6) DEFAULT 1.0 NOT NULL,
    decimales integer DEFAULT 2 NOT NULL,
    CONSTRAINT unidad_medida_tipo_check CHECK ((tipo = ANY (ARRAY['PESO'::text, 'VOLUMEN'::text, 'UNIDAD'::text, 'TIEMPO'::text])))
);


ALTER TABLE selemti.unidad_medida_legacy OWNER TO postgres;

--
-- Name: unidad_medida_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.unidad_medida_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.unidad_medida_id_seq OWNER TO postgres;

--
-- Name: unidad_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.unidad_medida_id_seq OWNED BY selemti.unidad_medida_legacy.id;


--
-- Name: unidades_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.unidades_medida AS
 SELECT (cat_unidades.id)::integer AS id,
    cat_unidades.clave AS codigo,
    cat_unidades.nombre,
    (
        CASE
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('KG'::character varying)::text, ('G'::character varying)::text, ('MG'::character varying)::text, ('LB'::character varying)::text, ('OZ'::character varying)::text])) THEN 'PESO'::text
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('L'::character varying)::text, ('ML'::character varying)::text, ('M3'::character varying)::text, ('FLOZ'::character varying)::text, ('CUP'::character varying)::text, ('TBSP'::character varying)::text, ('TSP'::character varying)::text])) THEN 'VOLUMEN'::text
            WHEN ((cat_unidades.clave)::text = 'PZ'::text) THEN 'UNIDAD'::text
            ELSE 'UNIDAD'::text
        END)::character varying(10) AS tipo,
    (
        CASE
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('KG'::character varying)::text, ('G'::character varying)::text, ('MG'::character varying)::text, ('L'::character varying)::text, ('ML'::character varying)::text, ('M3'::character varying)::text])) THEN 'METRICO'::text
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('LB'::character varying)::text, ('OZ'::character varying)::text, ('FLOZ'::character varying)::text])) THEN 'IMPERIAL'::text
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('CUP'::character varying)::text, ('TBSP'::character varying)::text, ('TSP'::character varying)::text])) THEN 'CULINARIO'::text
            ELSE 'METRICO'::text
        END)::character varying(20) AS categoria,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY (ARRAY[('KG'::character varying)::text, ('L'::character varying)::text, ('PZ'::character varying)::text])) THEN true
            ELSE false
        END AS es_base,
    1.0::numeric(12,6) AS factor_conversion_base,
    2 AS decimales,
    cat_unidades.created_at
   FROM selemti.cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE selemti.unidades_medida OWNER TO postgres;

--
-- Name: VIEW unidades_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.unidades_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidades_medida con categoria';


--
-- Name: unidades_medida_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.unidades_medida_legacy (
    id integer NOT NULL,
    codigo character varying(10) NOT NULL,
    nombre character varying(50) NOT NULL,
    tipo character varying(10) NOT NULL,
    categoria character varying(20),
    es_base boolean DEFAULT false,
    factor_conversion_base numeric(12,6) DEFAULT 1.0,
    decimales integer DEFAULT 2,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT unidades_medida_categoria_check CHECK (((categoria)::text = ANY (ARRAY[('METRICO'::character varying)::text, ('IMPERIAL'::character varying)::text, ('CULINARIO'::character varying)::text]))),
    CONSTRAINT unidades_medida_codigo_check CHECK (((codigo)::text ~ '^[A-Z]{2,5}$'::text)),
    CONSTRAINT unidades_medida_decimales_check CHECK (((decimales >= 0) AND (decimales <= 6))),
    CONSTRAINT unidades_medida_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('PESO'::character varying)::text, ('VOLUMEN'::character varying)::text, ('UNIDAD'::character varying)::text, ('TIEMPO'::character varying)::text])))
);


ALTER TABLE selemti.unidades_medida_legacy OWNER TO postgres;

--
-- Name: unidades_medida_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.unidades_medida_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.unidades_medida_id_seq OWNER TO postgres;

--
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.unidades_medida_id_seq OWNED BY selemti.unidades_medida_legacy.id;


--
-- Name: uom_conversion; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.uom_conversion AS
 SELECT (cat_uom_conversion.id)::integer AS id,
    (cat_uom_conversion.origen_id)::integer AS origen_id,
    (cat_uom_conversion.destino_id)::integer AS destino_id,
    (cat_uom_conversion.factor)::numeric(14,6) AS factor
   FROM selemti.cat_uom_conversion;


ALTER TABLE selemti.uom_conversion OWNER TO postgres;

--
-- Name: VIEW uom_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.uom_conversion IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy uom_conversion';


--
-- Name: uom_conversion_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.uom_conversion_legacy (
    id integer NOT NULL,
    origen_id integer NOT NULL,
    destino_id integer NOT NULL,
    factor numeric(14,6) NOT NULL,
    CONSTRAINT uom_conversion_check CHECK ((origen_id <> destino_id)),
    CONSTRAINT uom_conversion_factor_check CHECK ((factor > (0)::numeric))
);


ALTER TABLE selemti.uom_conversion_legacy OWNER TO postgres;

--
-- Name: uom_conversion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.uom_conversion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.uom_conversion_id_seq OWNER TO postgres;

--
-- Name: uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.uom_conversion_id_seq OWNED BY selemti.uom_conversion_legacy.id;


--
-- Name: user_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.user_roles (
    user_id integer NOT NULL,
    role_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer,
    CONSTRAINT user_roles_role_id_check CHECK (((role_id)::text = ANY (ARRAY[('GERENTE'::character varying)::text, ('CHEF'::character varying)::text, ('ALMACEN'::character varying)::text, ('CAJERO'::character varying)::text, ('AUDITOR'::character varying)::text, ('SISTEMA'::character varying)::text])))
);


ALTER TABLE selemti.user_roles OWNER TO postgres;

--
-- Name: TABLE user_roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.user_roles IS 'AsignaciÃ³n de roles a usuarios.';


--
-- Name: users; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.users (
    id bigint NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    email character varying(255),
    nombre_completo character varying(100) NOT NULL,
    sucursal_id character varying(10) DEFAULT 'SUR'::character varying,
    activo boolean DEFAULT true,
    fecha_ultimo_login timestamp without time zone,
    intentos_login integer DEFAULT 0,
    bloqueado_hasta timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    remember_token character varying(100),
    CONSTRAINT users_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT users_intentos_login_check CHECK ((intentos_login >= 0)),
    CONSTRAINT users_password_hash_check CHECK ((length((password_hash)::text) = 60)),
    CONSTRAINT users_sucursal_id_check CHECK (((sucursal_id)::text = ANY (ARRAY[('SUR'::character varying)::text, ('NORTE'::character varying)::text, ('CENTRO'::character varying)::text]))),
    CONSTRAINT users_username_check CHECK ((length((username)::text) >= 3))
);


ALTER TABLE selemti.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE selemti.users IS 'Tabla canÃ³nica de usuarios del sistema - Consolidada en Phase 2.1';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.users_id_seq OWNED BY selemti.users.id;


--
-- Name: usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE selemti.usuario (
    id bigint NOT NULL,
    username text NOT NULL,
    nombre text NOT NULL,
    email text,
    rol_id integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    password_hash text,
    floreant_user_id integer,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE selemti.usuario OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE selemti.usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE selemti.usuario_id_seq OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE selemti.usuario_id_seq OWNED BY selemti.usuario.id;


--
-- Name: v_almacen; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_almacen AS
 SELECT cat_almacenes.clave AS id,
    (cat_almacenes.sucursal_id)::text AS sucursal_id,
    cat_almacenes.nombre,
    cat_almacenes.activo
   FROM selemti.cat_almacenes;


ALTER TABLE selemti.v_almacen OWNER TO postgres;

--
-- Name: VIEW v_almacen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_almacen IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy almacen';


--
-- Name: v_bodega; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_bodega AS
 SELECT (cat_almacenes.id)::integer AS id,
    (cat_almacenes.sucursal_id)::text AS sucursal_id,
    cat_almacenes.clave AS codigo,
    cat_almacenes.nombre
   FROM selemti.cat_almacenes
  WHERE ((cat_almacenes.clave)::text ~ '^[0-9]+$'::text);


ALTER TABLE selemti.v_bodega OWNER TO postgres;

--
-- Name: VIEW v_bodega; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_bodega IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy bodega';


--
-- Name: v_cat_unidades_compat; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_cat_unidades_compat AS
 SELECT unidades_medida_legacy.id,
    now() AS created_at,
    now() AS updated_at,
    unidades_medida_legacy.codigo AS clave,
    unidades_medida_legacy.nombre,
    true AS activo
   FROM selemti.unidades_medida_legacy
  WHERE ((unidades_medida_legacy.codigo)::text = ANY (ARRAY[('KG'::character varying)::text, ('L'::character varying)::text, ('LT'::character varying)::text, ('PZ'::character varying)::text, ('EA'::character varying)::text, ('G'::character varying)::text, ('ML'::character varying)::text, ('OZ'::character varying)::text, ('LB'::character varying)::text, ('GAL'::character varying)::text]));


ALTER TABLE selemti.v_cat_unidades_compat OWNER TO postgres;

--
-- Name: VIEW v_cat_unidades_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_cat_unidades_compat IS 'Vista de compatibilidad para cat_unidades. Mapea a unidades_medida_legacy (canónica)';


--
-- Name: v_ingenieria_menu_completa; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_ingenieria_menu_completa AS
 SELECT rc.id AS receta_id,
    rc.nombre_plato,
    rc.codigo_plato_pos,
    rc.precio_venta_sugerido,
    rc.costo_standard_porcion AS costo_actual,
    (rc.precio_venta_sugerido - rc.costo_standard_porcion) AS margen_actual,
        CASE
            WHEN (rc.precio_venta_sugerido > (0)::numeric) THEN (((rc.precio_venta_sugerido - rc.costo_standard_porcion) / rc.precio_venta_sugerido) * (100)::numeric)
            ELSE (0)::numeric
        END AS porcentaje_margen,
    (rc.costo_standard_porcion > (rc.precio_venta_sugerido * 0.4)) AS alerta_costo_alto,
    (( SELECT count(*) AS count
           FROM selemti.ticket_venta_det td
          WHERE ((td.item_id)::text = (rc.id)::text)) = 0) AS alerta_sin_ventas
   FROM selemti.receta_cab rc
  WHERE (rc.activo = true);


ALTER TABLE selemti.v_ingenieria_menu_completa OWNER TO postgres;

--
-- Name: v_insumo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_insumo AS
 SELECT row_number() OVER (ORDER BY items.id) AS id,
    items.id AS codigo,
    items.nombre,
    items.unidad_medida_id AS um_id,
    items.perishable AS perecible,
    0.00 AS merma_pct,
    items.activo,
    NULL::jsonb AS meta,
    items.categoria_id AS categoria_codigo,
    NULL::unknown AS subcategoria_codigo,
    ("substring"((items.id)::text, '[0-9]+$'::text))::integer AS consecutivo,
    items.id AS sku
   FROM selemti.items;


ALTER TABLE selemti.v_insumo OWNER TO postgres;

--
-- Name: VIEW v_insumo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_insumo IS 'Vista de compatibilidad - Mapea items â†’ formato legacy insumo';


--
-- Name: v_items_con_uom; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_items_con_uom AS
 SELECT i.id,
    i.nombre,
    i.descripcion,
    i.categoria_id,
    i.unidad_medida,
    i.perishable,
    i.temperatura_min,
    i.temperatura_max,
    i.costo_promedio,
    i.activo,
    i.created_at,
    i.updated_at,
    i.unidad_medida_id,
    i.factor_conversion,
    i.unidad_compra_id,
    i.factor_compra,
    i.tipo,
    i.unidad_salida_id,
    um.codigo AS uom_codigo,
    um.nombre AS uom_nombre,
    um.tipo AS uom_tipo
   FROM (selemti.items i
     LEFT JOIN selemti.unidades_medida_legacy um ON ((um.id = i.unidad_medida_id)));


ALTER TABLE selemti.v_items_con_uom OWNER TO postgres;

--
-- Name: v_lote; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_lote AS
 SELECT inventory_batch.id,
    inventory_batch.item_id AS insumo_id_codigo,
    inventory_batch.lote_proveedor AS codigo,
    inventory_batch.fecha_recepcion,
    inventory_batch.fecha_caducidad,
    inventory_batch.cantidad_original AS cantidad_inicial,
    inventory_batch.cantidad_actual,
    inventory_batch.unit_cost AS costo_unitario
   FROM selemti.inventory_batch;


ALTER TABLE selemti.v_lote OWNER TO postgres;

--
-- Name: VIEW v_lote; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_lote IS 'Vista de compatibilidad - Mapea inventory_batch â†’ formato legacy lote';


--
-- Name: v_merma_por_item; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_merma_por_item AS
 SELECT m.item_id,
    (date_trunc('week'::text, m.ts))::date AS semana,
    sum(
        CASE
            WHEN ((m.tipo)::text = 'MERMA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END) AS qty_mermada,
    sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END) AS qty_recibida,
    round(((100.0 * NULLIF(sum(
        CASE
            WHEN ((m.tipo)::text = 'MERMA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END), (0)::numeric)) / NULLIF(sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END), (0)::numeric)), 2) AS merma_pct
   FROM selemti.mov_inv m
  GROUP BY m.item_id, ((date_trunc('week'::text, m.ts))::date);


ALTER TABLE selemti.v_merma_por_item OWNER TO postgres;

--
-- Name: v_receta; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_receta AS
 SELECT receta_cab.id,
    receta_cab.nombre_plato AS nombre,
    receta_cab.categoria_plato AS categoria,
    receta_cab.activo,
    receta_cab.costo_standard_porcion AS costo_total,
    (((receta_cab.precio_venta_sugerido - receta_cab.costo_standard_porcion) / NULLIF(receta_cab.costo_standard_porcion, (0)::numeric)) * (100)::numeric) AS margen_sugerido,
    receta_cab.precio_venta_sugerido AS precio_sugerido
   FROM selemti.receta_cab;


ALTER TABLE selemti.v_receta OWNER TO postgres;

--
-- Name: VIEW v_receta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_receta IS 'Vista de compatibilidad - Mapea receta_cab â†’ formato legacy receta';


--
-- Name: v_receta_insumo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_receta_insumo AS
 SELECT receta_det.id,
    receta_det.receta_version_id,
    receta_det.item_id AS insumo_id,
    receta_det.cantidad,
    receta_det.unidad_medida,
    0.00 AS costo_unitario,
    0.00 AS costo_total
   FROM selemti.receta_det;


ALTER TABLE selemti.v_receta_insumo OWNER TO postgres;

--
-- Name: v_rol; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_rol AS
 SELECT (roles.id)::integer AS id,
    roles.name AS codigo,
    COALESCE(roles.display_name, roles.name) AS nombre
   FROM selemti.roles;


ALTER TABLE selemti.v_rol OWNER TO postgres;

--
-- Name: VIEW v_rol; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_rol IS 'Vista de compatibilidad - Mapea roles â†’ formato legacy rol';


--
-- Name: v_stock_actual; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_stock_actual AS
 SELECT i.id AS item_id,
    i.nombre,
    COALESCE(sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            WHEN ((m.tipo)::text = 'SALIDA'::text) THEN (- m.cantidad)
            ELSE (0)::numeric
        END), (0)::numeric) AS stock_actual
   FROM (selemti.items i
     LEFT JOIN selemti.mov_inv m ON (((i.id)::text = (m.item_id)::text)))
  GROUP BY i.id, i.nombre;


ALTER TABLE selemti.v_stock_actual OWNER TO postgres;

--
-- Name: v_stock_brechas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_stock_brechas AS
 SELECT sp.sucursal_id,
    sp.almacen_id,
    sp.item_id,
    sp.min_qty,
    sp.max_qty,
    COALESCE(sa.stock_actual, (0)::numeric) AS stock_actual,
    GREATEST((sp.min_qty - COALESCE(sa.stock_actual, (0)::numeric)), (0)::numeric) AS qty_a_comprar
   FROM (selemti.stock_policy sp
     LEFT JOIN ( SELECT mov_inv.item_id,
            sum(
                CASE
                    WHEN ((mov_inv.tipo)::text = 'ENTRADA'::text) THEN mov_inv.cantidad
                    WHEN ((mov_inv.tipo)::text = ANY (ARRAY[('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO'::character varying)::text])) THEN (- mov_inv.cantidad)
                    ELSE (0)::numeric
                END) AS stock_actual
           FROM selemti.mov_inv
          GROUP BY mov_inv.item_id) sa ON (((sa.item_id)::text = sp.item_id)));


ALTER TABLE selemti.v_stock_brechas OWNER TO postgres;

--
-- Name: v_sucursal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_sucursal AS
 SELECT cat_sucursales.clave AS id,
    cat_sucursales.nombre,
    cat_sucursales.activo
   FROM selemti.cat_sucursales;


ALTER TABLE selemti.v_sucursal OWNER TO postgres;

--
-- Name: VIEW v_sucursal; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_sucursal IS 'Vista de compatibilidad - Mapea cat_sucursales â†’ formato legacy';


--
-- Name: v_unidad_medida_singular_compat; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_unidad_medida_singular_compat AS
 SELECT unidades_medida_legacy.id,
    unidades_medida_legacy.codigo,
    unidades_medida_legacy.nombre,
    unidades_medida_legacy.tipo,
    unidades_medida_legacy.es_base,
    unidades_medida_legacy.factor_conversion_base AS factor_a_base,
    unidades_medida_legacy.decimales
   FROM selemti.unidades_medida_legacy;


ALTER TABLE selemti.v_unidad_medida_singular_compat OWNER TO postgres;

--
-- Name: VIEW v_unidad_medida_singular_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_unidad_medida_singular_compat IS 'Vista de compatibilidad para unidad_medida_legacy (singular). Mapea a unidades_medida_legacy (canónica)';


--
-- Name: v_usuario; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.v_usuario AS
 SELECT users.id,
    users.username,
    users.nombre_completo AS nombre,
    users.email,
    NULL::integer AS rol_id,
    users.activo,
    users.password_hash,
    NULL::integer AS floreant_user_id,
    NULL::jsonb AS meta,
    users.created_at
   FROM selemti.users;


ALTER TABLE selemti.v_usuario OWNER TO postgres;

--
-- Name: VIEW v_usuario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW selemti.v_usuario IS 'Vista de compatibilidad - Mapea users â†’ formato legacy usuario';


--
-- Name: vw_dashboard_formas_pago; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_formas_pago AS
 SELECT (t.transaction_time)::date AS fecha,
    COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text) AS sucursal_id,
    COALESCE(fp.codigo, (t.payment_type)::text, 'OTRO'::text) AS codigo_fp,
    (sum(t.amount))::numeric(12,2) AS monto
   FROM ((public.transactions t
     LEFT JOIN selemti.formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text))))
     LEFT JOIN public.terminal term ON ((term.id = t.terminal_id)))
  WHERE (t.transaction_time IS NOT NULL)
  GROUP BY ((t.transaction_time)::date), COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text), COALESCE(fp.codigo, (t.payment_type)::text, 'OTRO'::text);


ALTER TABLE selemti.vw_dashboard_formas_pago OWNER TO postgres;

--
-- Name: vw_dashboard_ticket_base; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_ticket_base AS
 SELECT t.id AS ticket_id,
    (date_trunc('day'::text, t.closing_date))::date AS fecha,
    date_trunc('hour'::text, t.closing_date) AS hora,
    COALESCE(NULLIF((term.location)::text, ''::text), NULLIF((row_to_json(t.*) ->> 'branch_key'::text), ''::text), 'Sin sucursal'::text) AS sucursal_id,
    t.terminal_id,
    (COALESCE(t.total_price, (0)::double precision))::numeric(12,2) AS total,
    (COALESCE(t.sub_total, (0)::double precision))::numeric(12,2) AS sub_total,
    t.paid,
    t.voided,
    t.closing_date,
    COALESCE(NULLIF((t.daily_folio)::text, ''::text), NULLIF((t.global_id)::text, ''::text), (row_to_json(t.*) ->> 'ticket_number'::text), (t.id)::text) AS ticket_ref
   FROM (public.ticket t
     LEFT JOIN public.terminal term ON ((term.id = t.terminal_id)))
  WHERE (t.closing_date IS NOT NULL);


ALTER TABLE selemti.vw_dashboard_ticket_base OWNER TO postgres;

--
-- Name: vw_dashboard_ordenes; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_ordenes AS
 SELECT base.ticket_id,
    base.fecha,
    base.hora,
    base.sucursal_id,
    base.terminal_id,
    base.ticket_ref,
    base.total,
    base.closing_date
   FROM selemti.vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false));


ALTER TABLE selemti.vw_dashboard_ordenes OWNER TO postgres;

--
-- Name: vw_dashboard_resumen_sucursal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_resumen_sucursal AS
 SELECT base.fecha,
    base.sucursal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total,
    sum(base.sub_total) AS sub_total
   FROM selemti.vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.sucursal_id;


ALTER TABLE selemti.vw_dashboard_resumen_sucursal OWNER TO postgres;

--
-- Name: vw_dashboard_resumen_terminal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_resumen_terminal AS
 SELECT base.fecha,
    base.terminal_id,
    base.sucursal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total,
    sum(base.sub_total) AS sub_total
   FROM selemti.vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.terminal_id, base.sucursal_id;


ALTER TABLE selemti.vw_dashboard_resumen_terminal OWNER TO postgres;

--
-- Name: vw_dashboard_ventas_productos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_ventas_productos AS
 SELECT base.fecha,
    base.sucursal_id,
    base.terminal_id,
    ti.item_id AS plu,
    COALESCE(NULLIF((ti.item_name)::text, ''::text), (mi.name)::text, (ti.item_id)::text) AS descripcion,
    COALESCE(mg.name, 'SIN CATEGORIA'::character varying) AS categoria,
    sum(COALESCE(NULLIF(ti.item_quantity, (0)::double precision), (NULLIF(ti.item_count, 0))::double precision, (0)::double precision)) AS unidades,
    sum(COALESCE(ti.total_price, (0)::double precision)) AS venta_total
   FROM (((selemti.vw_dashboard_ticket_base base
     JOIN public.ticket_item ti ON ((ti.ticket_id = base.ticket_id)))
     LEFT JOIN public.menu_item mi ON ((mi.id = ti.item_id)))
     LEFT JOIN public.menu_group mg ON ((mg.id = mi.group_id)))
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.sucursal_id, base.terminal_id, ti.item_id, COALESCE(NULLIF((ti.item_name)::text, ''::text), (mi.name)::text, (ti.item_id)::text), COALESCE(mg.name, 'SIN CATEGORIA'::character varying);


ALTER TABLE selemti.vw_dashboard_ventas_productos OWNER TO postgres;

--
-- Name: vw_dashboard_ventas_categorias; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_ventas_categorias AS
 SELECT vw_dashboard_ventas_productos.fecha,
    vw_dashboard_ventas_productos.sucursal_id,
    vw_dashboard_ventas_productos.categoria,
    sum(vw_dashboard_ventas_productos.unidades) AS unidades,
    sum(vw_dashboard_ventas_productos.venta_total) AS venta_total
   FROM selemti.vw_dashboard_ventas_productos
  GROUP BY vw_dashboard_ventas_productos.fecha, vw_dashboard_ventas_productos.sucursal_id, vw_dashboard_ventas_productos.categoria;


ALTER TABLE selemti.vw_dashboard_ventas_categorias OWNER TO postgres;

--
-- Name: vw_dashboard_ventas_hora; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_dashboard_ventas_hora AS
 SELECT base.fecha,
    date_trunc('hour'::text, base.hora) AS hora,
    base.sucursal_id,
    base.terminal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total
   FROM selemti.vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, (date_trunc('hour'::text, base.hora)), base.sucursal_id, base.terminal_id;


ALTER TABLE selemti.vw_dashboard_ventas_hora OWNER TO postgres;

--
-- Name: vw_item_last_price; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_item_last_price AS
 WITH last_price AS (
         SELECT (ivp.item_id)::text AS item_id,
            (ivp.vendor_id)::text AS vendor_id,
            ivp.price,
            ivp.pack_qty,
            ivp.pack_uom,
            ivp.effective_from,
            row_number() OVER (PARTITION BY ivp.item_id, ivp.vendor_id ORDER BY ivp.effective_from DESC) AS rn
           FROM selemti.item_vendor_prices ivp
          WHERE (ivp.effective_to IS NULL)
        )
 SELECT lp.item_id,
    lp.vendor_id,
    lp.price,
    lp.pack_qty,
    lp.pack_uom,
    lp.effective_from
   FROM last_price lp
  WHERE (lp.rn = 1);


ALTER TABLE selemti.vw_item_last_price OWNER TO postgres;

--
-- Name: vw_item_last_price_pref; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_item_last_price_pref AS
 SELECT i.id AS item_id,
    pv.vendor_id,
    lp.price,
    lp.pack_qty,
    lp.pack_uom,
    lp.effective_from
   FROM ((selemti.items i
     LEFT JOIN selemti.item_vendor pv ON (((pv.item_id = (i.id)::text) AND (COALESCE(pv.preferente, false) = true))))
     LEFT JOIN selemti.vw_item_last_price lp ON (((lp.item_id = (i.id)::text) AND (lp.vendor_id = pv.vendor_id))));


ALTER TABLE selemti.vw_item_last_price_pref OWNER TO postgres;

--
-- Name: vw_kardex; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_kardex AS
 SELECT mi.id,
    mi.ts,
    COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)) AS item_key,
    mi.lote_id,
    mi.tipo,
    COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric) AS qty,
    mi.costo_unit,
    mi.ref_tipo,
    mi.ref_id,
    mi.sucursal_id,
    mi.usuario_id
   FROM selemti.mov_inv mi
  ORDER BY mi.ts DESC, mi.id DESC;


ALTER TABLE selemti.vw_kardex OWNER TO postgres;

--
-- Name: vw_movimientos_anomalos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_movimientos_anomalos AS
 SELECT k.id,
    k.ts,
    k.item_key,
    k.lote_id,
    k.tipo,
    k.qty,
    k.costo_unit,
    k.ref_tipo,
    k.ref_id,
    k.sucursal_id,
    k.usuario_id,
        CASE
            WHEN (k.qty IS NULL) THEN 'QTY_NULL'::text
            WHEN (k.qty = (0)::numeric) THEN 'QTY_CERO'::text
            WHEN (abs(k.qty) > (1000000)::numeric) THEN 'QTY_EXCESIVA'::text
            WHEN (k.costo_unit < (0)::numeric) THEN 'COSTO_NEGATIVO'::text
            WHEN (k.ts > (now() + '1 day'::interval)) THEN 'FUTURO'::text
            WHEN ((k.item_key IS NULL) OR (k.item_key = ''::text)) THEN 'ITEM_VACIO'::text
            WHEN ((k.tipo)::text <> ALL (ARRAY[('ENTRADA'::character varying)::text, ('RECEPCION'::character varying)::text, ('COMPRA'::character varying)::text, ('TRASPASO_IN'::character varying)::text, ('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO_OUT'::character varying)::text])) THEN 'TIPO_DESCONOCIDO'::text
            ELSE NULL::text
        END AS regla
   FROM selemti.vw_kardex k
  WHERE ((k.qty IS NULL) OR (k.qty = (0)::numeric) OR (abs(k.qty) > (1000000)::numeric) OR (k.costo_unit < (0)::numeric) OR (k.ts > (now() + '1 day'::interval)) OR (k.item_key IS NULL) OR (k.item_key = ''::text) OR ((k.tipo)::text <> ALL (ARRAY[('ENTRADA'::character varying)::text, ('RECEPCION'::character varying)::text, ('COMPRA'::character varying)::text, ('TRASPASO_IN'::character varying)::text, ('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO_OUT'::character varying)::text])));


ALTER TABLE selemti.vw_movimientos_anomalos OWNER TO postgres;

--
-- Name: vw_pos_map_resuelto; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_pos_map_resuelto AS
 SELECT pm.pos_system,
    pm.plu,
    pm.tipo,
    ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint AS receta_version_id,
    ((row_to_json(pm.*) ->> 'insumo_id'::text))::bigint AS insumo_id,
    COALESCE(((row_to_json(pm.*) ->> 'factor_insumo'::text))::numeric, (1)::numeric) AS factor_insumo,
    ((row_to_json(pm.*) ->> 'vigente_desde'::text))::timestamp without time zone AS vigente_desde,
    ((row_to_json(pm.*) ->> 'vigente_hasta'::text))::timestamp without time zone AS vigente_hasta
   FROM selemti.pos_map pm
  WHERE (((row_to_json(pm.*) ->> 'vigente_hasta'::text) IS NULL) OR (((row_to_json(pm.*) ->> 'vigente_hasta'::text))::date >= ('now'::text)::date));


ALTER TABLE selemti.vw_pos_map_resuelto OWNER TO postgres;

--
-- Name: vw_replenishment_dashboard; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_replenishment_dashboard AS
 SELECT rs.id,
    rs.folio,
    rs.tipo,
    rs.prioridad,
    rs.origen,
    rs.item_id,
    rs.sucursal_id,
    rs.almacen_id,
    rs.stock_actual,
    rs.stock_min,
    rs.stock_max,
    rs.qty_sugerida,
    rs.qty_aprobada,
    rs.uom,
    rs.consumo_promedio_diario,
    rs.dias_stock_restante,
    rs.fecha_agotamiento_estimada,
    rs.estado,
    rs.purchase_request_id,
    rs.production_order_id,
    rs.sugerido_en,
    rs.revisado_en,
    rs.revisado_por,
    rs.convertido_en,
    rs.caduca_en,
    rs.motivo,
    rs.motivo_rechazo,
    rs.notas,
    rs.meta,
    rs.created_at,
    rs.updated_at,
    i.item_code AS item_codigo,
    i.nombre AS item_nombre,
    s.nombre AS sucursal_nombre,
        CASE
            WHEN (rs.fecha_agotamiento_estimada <= ('now'::text)::date) THEN 'CRITICO'::text
            WHEN (rs.fecha_agotamiento_estimada <= (('now'::text)::date + '3 days'::interval)) THEN 'URGENTE'::text
            WHEN (rs.fecha_agotamiento_estimada <= (('now'::text)::date + '7 days'::interval)) THEN 'PROXIMO'::text
            ELSE 'NORMAL'::text
        END AS nivel_urgencia,
        CASE
            WHEN (rs.stock_actual <= (0)::numeric) THEN 'SIN_STOCK'::text
            WHEN (rs.stock_actual < rs.stock_min) THEN 'BAJO_MINIMO'::text
            ELSE 'OK'::text
        END AS estado_stock
   FROM ((selemti.replenishment_suggestions rs
     LEFT JOIN selemti.items i ON (((i.id)::text = (rs.item_id)::text)))
     LEFT JOIN selemti.cat_sucursales s ON ((s.id = rs.sucursal_id)));


ALTER TABLE selemti.vw_replenishment_dashboard OWNER TO postgres;

--
-- Name: vw_sesion_dpr; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_sesion_dpr AS
 WITH s AS (
         SELECT sesion_cajon.id,
            sesion_cajon.terminal_id,
            sesion_cajon.cajero_usuario_id,
            sesion_cajon.apertura_ts,
            COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts
           FROM selemti.sesion_cajon
        )
 SELECT s.id AS sesion_id,
    dpr.id,
    dpr.report_time,
    dpr.reg,
    dpr.ticket_count,
    dpr.begin_cash,
    dpr.net_sales,
    dpr.sales_tax,
    dpr.cash_tax,
    dpr.total_revenue,
    dpr.gross_receipts,
    dpr.giftcertreturncount,
    dpr.giftcertreturnamount,
    dpr.giftcertchangeamount,
    dpr.cash_receipt_no,
    dpr.cash_receipt_amount,
    dpr.credit_card_receipt_no,
    dpr.credit_card_receipt_amount,
    dpr.debit_card_receipt_no,
    dpr.debit_card_receipt_amount,
    dpr.refund_receipt_count,
    dpr.refund_amount,
    dpr.receipt_differential,
    dpr.cash_back,
    dpr.cash_tips,
    dpr.charged_tips,
    dpr.tips_paid,
    dpr.tips_differential,
    dpr.pay_out_no,
    dpr.pay_out_amount,
    dpr.drawer_bleed_no,
    dpr.drawer_bleed_amount,
    dpr.drawer_accountable,
    dpr.cash_to_deposit,
    dpr.variance,
    dpr.delivery_charge,
    dpr.totalvoidwst,
    dpr.totalvoid,
    dpr.totaldiscountcount,
    dpr.totaldiscountamount,
    dpr.totaldiscountsales,
    dpr.totaldiscountguest,
    dpr.totaldiscountpartysize,
    dpr.totaldiscountchecksize,
    dpr.totaldiscountpercentage,
    dpr.totaldiscountratio,
    dpr.user_id,
    dpr.terminal_id
   FROM (s
     JOIN public.drawer_pull_report dpr ON (((dpr.terminal_id = s.terminal_id) AND (dpr.report_time >= s.apertura_ts) AND (dpr.report_time < s.fin_ts))));


ALTER TABLE selemti.vw_sesion_dpr OWNER TO postgres;

--
-- Name: vw_stock_por_lote_fefo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_stock_por_lote_fefo AS
 SELECT (ib.item_id)::text AS item_key,
    ib.id AS lote_id,
    ib.ubicacion_id,
    ib.fecha_caducidad,
    ib.cantidad_actual AS stock_lote
   FROM selemti.inventory_batch ib
  WHERE ((ib.estado)::text = 'ACTIVO'::text)
  ORDER BY ib.item_id, ib.fecha_caducidad, ib.id;


ALTER TABLE selemti.vw_stock_por_lote_fefo OWNER TO postgres;

--
-- Name: vw_ticket_promedio_sucursal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_ticket_promedio_sucursal_dia AS
 WITH tbase AS (
         SELECT vw_dashboard_ticket_base.fecha,
            vw_dashboard_ticket_base.sucursal_id,
            vw_dashboard_ticket_base.ticket_id,
            vw_dashboard_ticket_base.total
           FROM selemti.vw_dashboard_ticket_base
          WHERE ((vw_dashboard_ticket_base.paid = true) AND (vw_dashboard_ticket_base.voided = false))
        )
 SELECT tbase.fecha,
    tbase.sucursal_id,
    count(DISTINCT tbase.ticket_id) AS tickets,
    sum(tbase.total) AS venta_total,
        CASE
            WHEN (count(DISTINCT tbase.ticket_id) > 0) THEN (sum(tbase.total) / (count(DISTINCT tbase.ticket_id))::numeric)
            ELSE (0)::numeric
        END AS ticket_promedio
   FROM tbase
  GROUP BY tbase.fecha, tbase.sucursal_id;


ALTER TABLE selemti.vw_ticket_promedio_sucursal_dia OWNER TO postgres;

--
-- Name: vw_ventas_por_hora; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW selemti.vw_ventas_por_hora AS
 SELECT vw_dashboard_ventas_hora.fecha,
    vw_dashboard_ventas_hora.hora,
    vw_dashboard_ventas_hora.sucursal_id,
    vw_dashboard_ventas_hora.terminal_id,
    vw_dashboard_ventas_hora.tickets,
    vw_dashboard_ventas_hora.venta_total
   FROM selemti.vw_dashboard_ventas_hora
  ORDER BY vw_dashboard_ventas_hora.hora DESC;


ALTER TABLE selemti.vw_ventas_por_hora OWNER TO postgres;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.action_history ALTER COLUMN id SET DEFAULT nextval('public.action_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.attendence_history ALTER COLUMN id SET DEFAULT nextval('public.attendence_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer ALTER COLUMN id SET DEFAULT nextval('public.cash_drawer_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('public.cash_drawer_reset_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cooking_instruction ALTER COLUMN id SET DEFAULT nextval('public.cooking_instruction_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('public.coupon_and_discount_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency ALTER COLUMN id SET DEFAULT nextval('public.currency_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency_balance ALTER COLUMN id SET DEFAULT nextval('public.currency_balance_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.custom_payment ALTER COLUMN id SET DEFAULT nextval('public.custom_payment_id_seq'::regclass);


--
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.customer ALTER COLUMN auto_id SET DEFAULT nextval('public.customer_auto_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.data_update_info ALTER COLUMN id SET DEFAULT nextval('public.data_update_info_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_address ALTER COLUMN id SET DEFAULT nextval('public.delivery_address_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_charge ALTER COLUMN id SET DEFAULT nextval('public.delivery_charge_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_configuration ALTER COLUMN id SET DEFAULT nextval('public.delivery_configuration_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_instruction ALTER COLUMN id SET DEFAULT nextval('public.delivery_instruction_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('public.drawer_assigned_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('public.drawer_pull_report_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('public.employee_in_out_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.global_config ALTER COLUMN id SET DEFAULT nextval('public.global_config_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.gratuity ALTER COLUMN id SET DEFAULT nextval('public.gratuity_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.guest_check_print ALTER COLUMN id SET DEFAULT nextval('public.guest_check_print_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_group ALTER COLUMN id SET DEFAULT nextval('public.inventory_group_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item ALTER COLUMN id SET DEFAULT nextval('public.inventory_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_location ALTER COLUMN id SET DEFAULT nextval('public.inventory_location_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('public.inventory_meta_code_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction ALTER COLUMN id SET DEFAULT nextval('public.inventory_transaction_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_unit ALTER COLUMN id SET DEFAULT nextval('public.inventory_unit_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_vendor ALTER COLUMN id SET DEFAULT nextval('public.inventory_vendor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('public.inventory_warehouse_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('public.kitchen_ticket_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('public.kitchen_ticket_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_category ALTER COLUMN id SET DEFAULT nextval('public.menu_category_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_group ALTER COLUMN id SET DEFAULT nextval('public.menu_group_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item ALTER COLUMN id SET DEFAULT nextval('public.menu_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_size ALTER COLUMN id SET DEFAULT nextval('public.menu_item_size_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier ALTER COLUMN id SET DEFAULT nextval('public.menu_modifier_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('public.menu_modifier_group_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('public.menuitem_modifiergroup_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_shift ALTER COLUMN id SET DEFAULT nextval('public.menuitem_shift_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('public.modifier_multiplier_price_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.order_type ALTER COLUMN id SET DEFAULT nextval('public.order_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.packaging_unit ALTER COLUMN id SET DEFAULT nextval('public.packaging_unit_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.payout_reasons ALTER COLUMN id SET DEFAULT nextval('public.payout_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.payout_recepients ALTER COLUMN id SET DEFAULT nextval('public.payout_recepients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_crust ALTER COLUMN id SET DEFAULT nextval('public.pizza_crust_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('public.pizza_modifier_price_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_price ALTER COLUMN id SET DEFAULT nextval('public.pizza_price_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.printer_group ALTER COLUMN id SET DEFAULT nextval('public.printer_group_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.purchase_order ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie ALTER COLUMN id SET DEFAULT nextval('public.recepie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie_item ALTER COLUMN id SET DEFAULT nextval('public.recepie_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shift ALTER COLUMN id SET DEFAULT nextval('public.shift_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor ALTER COLUMN id SET DEFAULT nextval('public.shop_floor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor_template ALTER COLUMN id SET DEFAULT nextval('public.shop_floor_template_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_table_type ALTER COLUMN id SET DEFAULT nextval('public.shop_table_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_info ALTER COLUMN id SET DEFAULT nextval('public.table_booking_info_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.tax ALTER COLUMN id SET DEFAULT nextval('public.tax_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_printers ALTER COLUMN id SET DEFAULT nextval('public.terminal_printers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_discount ALTER COLUMN id SET DEFAULT nextval('public.ticket_discount_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item ALTER COLUMN id SET DEFAULT nextval('public.ticket_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('public.ticket_item_discount_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('public.ticket_item_modifier_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_type ALTER COLUMN id SET DEFAULT nextval('public.user_type_id_seq'::regclass);


--
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users ALTER COLUMN auto_id SET DEFAULT nextval('public.users_auto_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.virtual_printer ALTER COLUMN id SET DEFAULT nextval('public.virtual_printer_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.void_reasons ALTER COLUMN id SET DEFAULT nextval('public.void_reasons_id_seq'::regclass);


--
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('public.zip_code_vs_delivery_charge_auto_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alert_events ALTER COLUMN id SET DEFAULT nextval('selemti.alert_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alert_rules ALTER COLUMN id SET DEFAULT nextval('selemti.alert_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alertas_cortes ALTER COLUMN id SET DEFAULT nextval('selemti.alertas_cortes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log ALTER COLUMN id SET DEFAULT nextval('selemti.audit_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log_global ALTER COLUMN id SET DEFAULT nextval('selemti.audit_log_global_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.auditoria ALTER COLUMN id SET DEFAULT nextval('selemti.auditoria_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.bodega ALTER COLUMN id SET DEFAULT nextval('selemti.bodega_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo ALTER COLUMN id SET DEFAULT nextval('selemti.caja_fondo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('selemti.caja_fondo_adj_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('selemti.caja_fondo_arqueo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('selemti.caja_fondo_mov_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('selemti.cash_fund_arqueos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('selemti.cash_fund_movement_audit_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('selemti.cash_fund_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_funds ALTER COLUMN id SET DEFAULT nextval('selemti.cash_funds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_almacenes ALTER COLUMN id SET DEFAULT nextval('selemti.cat_almacenes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_proveedores ALTER COLUMN id SET DEFAULT nextval('selemti.cat_proveedores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_sucursales ALTER COLUMN id SET DEFAULT nextval('selemti.cat_sucursales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_unidades ALTER COLUMN id SET DEFAULT nextval('selemti.cat_unidades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('selemti.cat_uom_conversion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conciliacion ALTER COLUMN id SET DEFAULT nextval('selemti.conciliacion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conversiones_unidad_legacy ALTER COLUMN id SET DEFAULT nextval('selemti.conversiones_unidad_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cost_layer ALTER COLUMN id SET DEFAULT nextval('selemti.cost_layer_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.failed_jobs ALTER COLUMN id SET DEFAULT nextval('selemti.failed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.formas_pago ALTER COLUMN id SET DEFAULT nextval('selemti.formas_pago_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('selemti.hist_cost_insumo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('selemti.hist_cost_receta_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_item ALTER COLUMN id SET DEFAULT nextval('selemti.historial_costos_item_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('selemti.historial_costos_receta_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo ALTER COLUMN id SET DEFAULT nextval('selemti.insumo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('selemti.insumo_presentacion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion ALTER COLUMN id SET DEFAULT nextval('selemti.insumo_proveedor_presentacion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('selemti.inv_consumo_pos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('selemti.inv_consumo_pos_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('selemti.inv_consumo_pos_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('selemti.inv_stock_policy_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_batch ALTER COLUMN id SET DEFAULT nextval('selemti.inventory_batch_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('selemti.inventory_count_lines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_counts ALTER COLUMN id SET DEFAULT nextval('selemti.inventory_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_wastes ALTER COLUMN id SET DEFAULT nextval('selemti.inventory_wastes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_categories ALTER COLUMN id SET DEFAULT nextval('selemti.item_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('selemti.item_vendor_prices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('selemti.job_recalc_queue_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.jobs ALTER COLUMN id SET DEFAULT nextval('selemti.jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.labor_roles ALTER COLUMN id SET DEFAULT nextval('selemti.labor_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.lote ALTER COLUMN id SET DEFAULT nextval('selemti.lote_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('selemti.menu_engineering_snapshots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('selemti.menu_item_sync_map_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_items ALTER COLUMN id SET DEFAULT nextval('selemti.menu_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma ALTER COLUMN id SET DEFAULT nextval('selemti.merma_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.migrations ALTER COLUMN id SET DEFAULT nextval('selemti.migrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.modificadores_pos ALTER COLUMN id SET DEFAULT nextval('selemti.modificadores_pos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.mov_inv ALTER COLUMN id SET DEFAULT nextval('selemti.mov_inv_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab ALTER COLUMN id SET DEFAULT nextval('selemti.op_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo ALTER COLUMN id SET DEFAULT nextval('selemti.op_insumo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('selemti.op_produccion_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.overhead_definitions ALTER COLUMN id SET DEFAULT nextval('selemti.overhead_definitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.param_sucursal ALTER COLUMN id SET DEFAULT nextval('selemti.param_sucursal_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.perdida_log ALTER COLUMN id SET DEFAULT nextval('selemti.perdida_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.permissions ALTER COLUMN id SET DEFAULT nextval('selemti.permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('selemti.personal_access_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('selemti.pos_reprocess_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('selemti.pos_reverse_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('selemti.pos_sync_batches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('selemti.pos_sync_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.postcorte ALTER COLUMN id SET DEFAULT nextval('selemti.postcorte_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte ALTER COLUMN id SET DEFAULT nextval('selemti.precorte_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('selemti.precorte_efectivo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_otros ALTER COLUMN id SET DEFAULT nextval('selemti.precorte_otros_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_cab ALTER COLUMN id SET DEFAULT nextval('selemti.prod_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_det ALTER COLUMN id SET DEFAULT nextval('selemti.prod_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_order_inputs ALTER COLUMN id SET DEFAULT nextval('selemti.production_order_inputs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_order_outputs ALTER COLUMN id SET DEFAULT nextval('selemti.production_order_outputs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_orders ALTER COLUMN id SET DEFAULT nextval('selemti.production_orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_documents ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_order_lines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_orders ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_request_lines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_requests ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_suggestion_lines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_suggestions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_vendor_quote_lines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('selemti.purchase_vendor_quotes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recalc_log ALTER COLUMN id SET DEFAULT nextval('selemti.recalc_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('selemti.recepcion_adjuntos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_cab ALTER COLUMN id SET DEFAULT nextval('selemti.recepcion_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det ALTER COLUMN id SET DEFAULT nextval('selemti.recepcion_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta ALTER COLUMN id SET DEFAULT nextval('selemti.receta_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_det ALTER COLUMN id SET DEFAULT nextval('selemti.receta_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_insumo ALTER COLUMN id SET DEFAULT nextval('selemti.receta_insumo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_shadow ALTER COLUMN id SET DEFAULT nextval('selemti.receta_shadow_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_version ALTER COLUMN id SET DEFAULT nextval('selemti.receta_version_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_cost_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_snapshots ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_cost_snapshots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_extended_cost_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_labor_steps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_overhead_allocations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_version_items ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_version_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_versions ALTER COLUMN id SET DEFAULT nextval('selemti.recipe_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('selemti.replenishment_suggestions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_definitions ALTER COLUMN id SET DEFAULT nextval('selemti.report_definitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_favorites ALTER COLUMN id SET DEFAULT nextval('selemti.report_favorites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_runs ALTER COLUMN id SET DEFAULT nextval('selemti.report_runs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.rol ALTER COLUMN id SET DEFAULT nextval('selemti.rol_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.roles ALTER COLUMN id SET DEFAULT nextval('selemti.roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.sesion_cajon ALTER COLUMN id SET DEFAULT nextval('selemti.sesion_cajon_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('selemti.sol_prod_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sol_prod_det ALTER COLUMN id SET DEFAULT nextval('selemti.sol_prod_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.stock_policy ALTER COLUMN id SET DEFAULT nextval('selemti.stock_policy_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('selemti.sucursal_almacen_terminal_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('selemti.ticket_det_consumo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('selemti.ticket_item_modifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('selemti.ticket_venta_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('selemti.ticket_venta_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.transfer_cab ALTER COLUMN id SET DEFAULT nextval('selemti.transfer_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.transfer_det ALTER COLUMN id SET DEFAULT nextval('selemti.transfer_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_cab ALTER COLUMN id SET DEFAULT nextval('selemti.traspaso_cab_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det ALTER COLUMN id SET DEFAULT nextval('selemti.traspaso_det_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidad_medida_legacy ALTER COLUMN id SET DEFAULT nextval('selemti.unidad_medida_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidades_medida_legacy ALTER COLUMN id SET DEFAULT nextval('selemti.unidades_medida_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.uom_conversion_legacy ALTER COLUMN id SET DEFAULT nextval('selemti.uom_conversion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.users ALTER COLUMN id SET DEFAULT nextval('selemti.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.usuario ALTER COLUMN id SET DEFAULT nextval('selemti.usuario_id_seq'::regclass);


--
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- Name: online_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.online_order
    ADD CONSTRAINT online_order_pkey PRIMARY KEY (id);


--
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


--
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: alertas_cortes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alertas_cortes
    ADD CONSTRAINT alertas_cortes_pkey PRIMARY KEY (id);


--
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- Name: audit_log_global_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log_global
    ADD CONSTRAINT audit_log_global_pkey PRIMARY KEY (id);


--
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- Name: cat_uom_conversion_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);


--
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- Name: insumo_proveedor_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_pkey PRIMARY KEY (id);


--
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: pk_inventory_snapshot; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_snapshot
    ADD CONSTRAINT pk_inventory_snapshot PRIMARY KEY (snapshot_date, branch_id, item_id);


--
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- Name: pos_modifiers_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pkey PRIMARY KEY (id);


--
-- Name: pos_modifiers_map_pos_modifier_code_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pos_modifier_code_key UNIQUE (pos_modifier_code);


--
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, item_id);


--
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- Name: recipe_cost_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_snapshots
    ADD CONSTRAINT recipe_cost_snapshots_pkey PRIMARY KEY (id);


--
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- Name: report_favorites_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_favorites
    ADD CONSTRAINT report_favorites_pkey PRIMARY KEY (id);


--
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- Name: creationhour; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX creationhour ON public.ticket USING btree (creation_hour);


--
-- Name: deliverydate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX deliverydate ON public.ticket USING btree (deliveery_date);


--
-- Name: drawer_report_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawer_report_time ON public.drawer_pull_report USING btree (report_time);


--
-- Name: drawerresetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawerresetted ON public.ticket USING btree (drawer_resetted);


--
-- Name: food_category_visible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX food_category_visible ON public.menu_category USING btree (visible);


--
-- Name: fromdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX fromdate ON public.table_booking_info USING btree (from_date);


--
-- Name: idx_dah_user_op_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_dah_user_op_time ON public.drawer_assigned_history USING btree (a_user, operation, "time" DESC);


--
-- Name: idx_drawer_assigned_history_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_drawer_assigned_history_user_time ON public.drawer_assigned_history USING btree (a_user, "time");


--
-- Name: idx_ticket_close_term_owner; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_close_term_owner ON public.ticket USING btree (closing_date, terminal_id, owner_id);


--
-- Name: idx_tx_term_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_tx_term_user_time ON public.transactions USING btree (terminal_id, user_id, transaction_time);


--
-- Name: ix_kitchen_ticket_item_item_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_item_item_id ON public.kitchen_ticket_item USING btree (ticket_item_id);


--
-- Name: ix_kitchen_ticket_ticket_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_ticket_id ON public.kitchen_ticket USING btree (ticket_id);


--
-- Name: ix_ticket_branch_key; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_branch_key ON public.ticket USING btree (branch_key);


--
-- Name: ix_ticket_folio_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_folio_date ON public.ticket USING btree (folio_date);


--
-- Name: ix_ticket_item_ticket_pg; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_item_ticket_pg ON public.ticket_item USING btree (ticket_id, pg_id);


--
-- Name: menugroupvisible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX menugroupvisible ON public.menu_group USING btree (visible);


--
-- Name: mg_enable; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX mg_enable ON public.menu_modifier_group USING btree (enabled);


--
-- Name: modifierenabled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX modifierenabled ON public.menu_modifier USING btree (enable);


--
-- Name: ticketactivedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketactivedate ON public.ticket USING btree (active_date);


--
-- Name: ticketclosingdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketclosingdate ON public.ticket USING btree (closing_date);


--
-- Name: ticketcreatedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketcreatedate ON public.ticket USING btree (create_date);


--
-- Name: ticketpaid; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketpaid ON public.ticket USING btree (paid);


--
-- Name: ticketsettled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketsettled ON public.ticket USING btree (settled);


--
-- Name: ticketvoided; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketvoided ON public.ticket USING btree (voided);


--
-- Name: todate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX todate ON public.table_booking_info USING btree (to_date);


--
-- Name: tran_drawer_resetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX tran_drawer_resetted ON public.transactions USING btree (drawer_resetted);


--
-- Name: ux_ticket_dailyfolio; Type: INDEX; Schema: public; Owner: floreant
--

CREATE UNIQUE INDEX ux_ticket_dailyfolio ON public.ticket USING btree (folio_date, branch_key, daily_folio) WHERE (daily_folio IS NOT NULL);


--
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON selemti.cash_fund_arqueos USING btree (cash_fund_id);


--
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON selemti.cash_fund_arqueos USING btree (created_by_user_id);


--
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON selemti.cash_fund_movements USING btree (cash_fund_id);


--
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON selemti.cash_fund_movements USING btree (created_by_user_id);


--
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON selemti.cash_fund_movements USING btree (estatus);


--
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON selemti.cash_fund_movements USING btree (tipo);


--
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON selemti.cash_funds USING btree (estado);


--
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON selemti.cash_funds USING btree (fecha);


--
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON selemti.cash_funds USING btree (responsable_user_id);


--
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON selemti.cash_funds USING btree (sucursal_id);


--
-- Name: idx_alertas_cortes_destinatario; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_destinatario ON selemti.alertas_cortes USING btree (destinatario_id, leida);


--
-- Name: idx_alertas_cortes_postcorte; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_postcorte ON selemti.alertas_cortes USING btree (postcorte_id);


--
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON selemti.audit_log USING btree (accion);


--
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON selemti.audit_log USING btree (entidad);


--
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON selemti.audit_log USING btree (entidad_id);


--
-- Name: idx_audit_log_global_changed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_changed_at ON selemti.audit_log_global USING btree (changed_at);


--
-- Name: idx_audit_log_global_operation; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_operation ON selemti.audit_log_global USING btree (operation);


--
-- Name: idx_audit_log_global_table; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_table ON selemti.audit_log_global USING btree (table_name);


--
-- Name: idx_audit_log_global_user; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_user ON selemti.audit_log_global USING btree (changed_by_user_id);


--
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON selemti.audit_log USING btree ("timestamp");


--
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON selemti.audit_log USING btree (user_id);


--
-- Name: idx_cat_sucursales_pos_location; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_sucursales_pos_location ON selemti.cat_sucursales USING btree (pos_location);


--
-- Name: idx_cat_unidades_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_activo ON selemti.cat_unidades USING btree (activo);


--
-- Name: idx_cat_unidades_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_categoria ON selemti.cat_unidades USING btree (categoria);


--
-- Name: idx_cat_unidades_clave; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_clave ON selemti.cat_unidades USING btree (clave);


--
-- Name: idx_cat_uom_conversion_destino; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_destino ON selemti.cat_uom_conversion USING btree (destino_id);


--
-- Name: idx_cat_uom_conversion_origen; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_origen ON selemti.cat_uom_conversion USING btree (origen_id);


--
-- Name: idx_cat_uom_conversion_scope; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_scope ON selemti.cat_uom_conversion USING btree (scope);


--
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON selemti.historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON selemti.inventory_batch USING btree (fecha_caducidad);


--
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON selemti.inventory_batch USING btree (item_id);


--
-- Name: idx_inventory_batch_item_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item_estado ON selemti.inventory_batch USING btree (item_id, estado);


--
-- Name: idx_invshot_branch_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_branch_date ON selemti.inventory_snapshot USING btree (branch_id, snapshot_date);


--
-- Name: idx_invshot_item_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_item_date ON selemti.inventory_snapshot USING btree (item_id, snapshot_date);


--
-- Name: idx_invshot_variance; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_variance ON selemti.inventory_snapshot USING btree (snapshot_date, branch_id, variance_qty);


--
-- Name: idx_items_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo ON selemti.items USING btree (activo) WHERE (activo = true);


--
-- Name: idx_items_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo_categoria ON selemti.items USING btree (activo, categoria_id) WHERE (activo = true);


--
-- Name: idx_items_categoria_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_categoria_id ON selemti.items USING btree (categoria_id);


--
-- Name: idx_items_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_nombre_lower ON selemti.items USING btree (lower((nombre)::text));


--
-- Name: idx_items_unidad_compra_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_compra_id ON selemti.items USING btree (unidad_compra_id) WHERE ((activo = true) AND (unidad_compra_id IS NOT NULL));


--
-- Name: idx_items_unidad_medida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_medida_id ON selemti.items USING btree (unidad_medida_id) WHERE (activo = true);


--
-- Name: idx_items_unidad_salida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_salida_id ON selemti.items USING btree (unidad_salida_id) WHERE ((activo = true) AND (unidad_salida_id IS NOT NULL));


--
-- Name: idx_merma_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_batch_id ON selemti.merma USING btree (batch_id);


--
-- Name: idx_merma_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_deleted_at ON selemti.merma USING btree (deleted_at);


--
-- Name: idx_merma_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_item_id ON selemti.merma USING btree (item_id);


--
-- Name: idx_merma_usuario_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_usuario_id ON selemti.merma USING btree (usuario_id);


--
-- Name: idx_mov_inv_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_id ON selemti.mov_inv USING btree (item_id);


--
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON selemti.mov_inv USING btree (item_id, ts);


--
-- Name: idx_mov_inv_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo ON selemti.mov_inv USING btree (tipo);


--
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON selemti.mov_inv USING btree (tipo, ts);


--
-- Name: idx_mov_inv_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts ON selemti.mov_inv USING btree (ts);


--
-- Name: idx_mov_inv_ts_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts_tipo ON selemti.mov_inv USING btree (ts, tipo);


--
-- Name: idx_op_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_cab_deleted_at ON selemti.op_cab USING btree (deleted_at);


--
-- Name: idx_op_insumo_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_batch_id ON selemti.op_insumo USING btree (batch_id);


--
-- Name: idx_op_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_item_id ON selemti.op_insumo USING btree (item_id);


--
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON selemti.perdida_log USING btree (item_id, ts DESC);


--
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON selemti.pos_map USING btree (plu);


--
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON selemti.pos_reprocess_log USING btree (reprocessed_at);


--
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON selemti.pos_reprocess_log USING btree (ticket_id);


--
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON selemti.pos_reprocess_log USING btree (user_id);


--
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON selemti.pos_reverse_log USING btree (reversed_at);


--
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON selemti.pos_reverse_log USING btree (ticket_id);


--
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON selemti.pos_reverse_log USING btree (user_id);


--
-- Name: idx_posmod_active_valid; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_posmod_active_valid ON selemti.pos_modifiers_map USING btree (active, valid_from, (COALESCE(valid_to, '2999-12-31'::date)));


--
-- Name: idx_postcorte_requiere_aprobacion; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_requiere_aprobacion ON selemti.postcorte USING btree (requiere_aprobacion) WHERE (requiere_aprobacion = true);


--
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON selemti.postcorte USING btree (sesion_id);


--
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON selemti.precorte_efectivo USING btree (precorte_id);


--
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON selemti.precorte_otros USING btree (precorte_id);


--
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON selemti.precorte USING btree (sesion_id);


--
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON selemti.purchase_requests USING btree (fecha_requerida);


--
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON selemti.purchase_requests USING btree (urgente);


--
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON selemti.cat_proveedores USING btree (razon_social);


--
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON selemti.cat_proveedores USING btree (rfc);


--
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON selemti.purchase_suggestions USING btree (estado);


--
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON selemti.purchase_suggestions USING btree (sugerido_en);


--
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON selemti.purchase_suggestions USING btree (prioridad);


--
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON selemti.purchase_suggestions USING btree (sucursal_id, estado);


--
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON selemti.purchase_suggestion_lines USING btree (item_id);


--
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON selemti.purchase_suggestion_lines USING btree (suggestion_id);


--
-- Name: idx_recepcion_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_cab_deleted_at ON selemti.recepcion_cab USING btree (deleted_at);


--
-- Name: idx_recepcion_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_batch_id ON selemti.recepcion_det USING btree (batch_id);


--
-- Name: idx_recepcion_det_bodega_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_bodega_id ON selemti.recepcion_det USING btree (bodega_id);


--
-- Name: idx_recepcion_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_item_id ON selemti.recepcion_det USING btree (item_id);


--
-- Name: idx_receta_cab_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo ON selemti.receta_cab USING btree (activo) WHERE (activo = true);


--
-- Name: idx_receta_cab_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo_categoria ON selemti.receta_cab USING btree (activo, categoria_plato) WHERE (activo = true);


--
-- Name: idx_receta_cab_categoria_plato; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_categoria_plato ON selemti.receta_cab USING btree (categoria_plato);


--
-- Name: idx_receta_cab_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_nombre_lower ON selemti.receta_cab USING btree (lower((nombre_plato)::text));


--
-- Name: idx_receta_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_item_id ON selemti.receta_insumo USING btree (item_id);


--
-- Name: idx_receta_insumo_receta_version_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_receta_version_id ON selemti.receta_insumo USING btree (receta_version_id);


--
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON selemti.receta_version USING btree (version_publicada);


--
-- Name: idx_recipe_cost_snap_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_date ON selemti.recipe_cost_snapshots USING btree (snapshot_date DESC);


--
-- Name: idx_recipe_cost_snap_recipe_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_recipe_date ON selemti.recipe_cost_snapshots USING btree (recipe_id, snapshot_date DESC);


--
-- Name: idx_report_key; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_key ON selemti.report_favorites USING btree (report_key);


--
-- Name: idx_report_runs_report_status; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_runs_report_status ON selemti.report_runs USING btree (report_id, status);


--
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON selemti.sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON selemti.stock_policy USING btree (item_id, sucursal_id);


--
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON selemti.stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON selemti.sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON selemti.ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON selemti.ticket_det_consumo USING btree (item_id, lote_id);


--
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON selemti.ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON selemti.ticket_venta_cab USING btree (fecha_venta);


--
-- Name: idx_traspaso_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_cab_deleted_at ON selemti.traspaso_cab USING btree (deleted_at);


--
-- Name: idx_traspaso_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_batch_id ON selemti.traspaso_det USING btree (batch_id);


--
-- Name: idx_traspaso_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_item_id ON selemti.traspaso_det USING btree (item_id);


--
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON selemti.insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON selemti.inv_consumo_pos_det USING btree (procesado);


--
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON selemti.inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- Name: inv_consumo_pos_det_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_revertido_idx ON selemti.inv_consumo_pos_det USING btree (revertido);


--
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON selemti.inv_consumo_pos_log USING btree (ticket_id);


--
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON selemti.inv_consumo_pos USING btree (procesado);


--
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON selemti.inv_consumo_pos USING btree (requiere_reproceso);


--
-- Name: inv_consumo_pos_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_revertido_idx ON selemti.inv_consumo_pos USING btree (revertido);


--
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON selemti.inventory_count_lines USING btree (inventory_batch_id);


--
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON selemti.inventory_count_lines USING btree (inventory_count_id);


--
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON selemti.inventory_count_lines USING btree (item_id);


--
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON selemti.inventory_counts USING btree (almacen_id);


--
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON selemti.inventory_counts USING btree (cerrado_en);


--
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON selemti.inventory_counts USING btree (estado);


--
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON selemti.inventory_counts USING btree (programado_para);


--
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON selemti.inventory_counts USING btree (sucursal_id);


--
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON selemti.inventory_wastes USING btree (inventory_batch_id);


--
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON selemti.inventory_wastes USING btree (item_id);


--
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON selemti.inventory_wastes USING btree (production_order_id);


--
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON selemti.inventory_wastes USING btree (sucursal_id);


--
-- Name: ipp_activo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_activo_idx ON selemti.insumo_proveedor_presentacion USING btree (activo);


--
-- Name: ipp_insumo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_insumo_idx ON selemti.insumo_proveedor_presentacion USING btree (item_id);


--
-- Name: ipp_proveedor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_proveedor_idx ON selemti.insumo_proveedor_presentacion USING btree (proveedor_id);


--
-- Name: ipp_uni; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ipp_uni ON selemti.insumo_proveedor_presentacion USING btree (item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra);


--
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON selemti.alert_events USING btree (recipe_id, created_at);


--
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON selemti.formas_pago USING btree (codigo);


--
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON selemti.hist_cost_insumo USING btree (item_id, fecha_efectiva DESC);


--
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON selemti.hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON selemti.inventory_batch USING btree (item_id, fecha_caducidad);


--
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON selemti.item_vendor USING btree (preferente);


--
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON selemti.item_vendor USING btree (vendor_id, vendor_sku);


--
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON selemti.item_vendor_prices USING btree (item_id);


--
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON selemti.item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON selemti.item_vendor_prices USING btree (vendor_id);


--
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON selemti.cost_layer USING btree (item_id, ts_in);


--
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON selemti.cost_layer USING btree (item_id, sucursal_id);


--
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON selemti.lote USING btree (caducidad);


--
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON selemti.lote USING btree (item_id);


--
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON selemti.mov_inv USING btree (item_id);


--
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON selemti.mov_inv USING btree (item_id, ts DESC);


--
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON selemti.mov_inv USING btree (ref_tipo, ref_id);


--
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON selemti.mov_inv USING btree (sucursal_id);


--
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON selemti.mov_inv USING btree (tipo);


--
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON selemti.mov_inv USING btree (ts);


--
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON selemti.pos_map USING btree (plu);


--
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON selemti.pos_map USING btree (pos_system, plu, vigente_desde);


--
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON selemti.precorte_otros USING btree (precorte_id);


--
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON selemti.recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON selemti.receta_insumo USING btree (item_id);


--
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON selemti.receta_insumo USING btree (receta_version_id);


--
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON selemti.receta_version USING btree (id);


--
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON selemti.recipe_version_items USING btree (recipe_version_id);


--
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON selemti.sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON selemti.sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON selemti.stock_policy USING btree (item_id, sucursal_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON selemti.jobs USING btree (queue);


--
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON selemti.labor_roles USING btree (activo);


--
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON selemti.model_has_permissions USING btree (model_id, model_type);


--
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON selemti.model_has_roles USING btree (model_id, model_type);


--
-- Name: mv_inventario_actual_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_inventario_actual_item_id_idx ON selemti.mv_inventario_actual USING btree (item_id);


--
-- Name: mv_recetas_costos_receta_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_recetas_costos_receta_id_idx ON selemti.mv_recetas_costos USING btree (receta_id);


--
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON selemti.overhead_definitions USING btree (activo);


--
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON selemti.overhead_definitions USING btree (tipo);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON selemti.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON selemti.precorte USING btree (sesion_id);


--
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON selemti.production_order_inputs USING btree (inventory_batch_id);


--
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON selemti.production_order_inputs USING btree (item_id);


--
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON selemti.production_order_inputs USING btree (production_order_id);


--
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON selemti.production_order_outputs USING btree (inventory_batch_id);


--
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON selemti.production_order_outputs USING btree (item_id);


--
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON selemti.production_order_outputs USING btree (production_order_id);


--
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON selemti.production_orders USING btree (almacen_id);


--
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON selemti.production_orders USING btree (estado);


--
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON selemti.production_orders USING btree (item_id);


--
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON selemti.production_orders USING btree (programado_para);


--
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON selemti.production_orders USING btree (recipe_id);


--
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON selemti.production_orders USING btree (sucursal_id);


--
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON selemti.purchase_documents USING btree (order_id);


--
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON selemti.purchase_documents USING btree (quote_id);


--
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON selemti.purchase_documents USING btree (request_id);


--
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON selemti.purchase_order_lines USING btree (item_id);


--
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON selemti.purchase_order_lines USING btree (order_id);


--
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON selemti.purchase_orders USING btree (estado);


--
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON selemti.purchase_orders USING btree (vendor_id);


--
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON selemti.purchase_request_lines USING btree (item_id);


--
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON selemti.purchase_request_lines USING btree (preferred_vendor_id);


--
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON selemti.purchase_request_lines USING btree (request_id);


--
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON selemti.purchase_requests USING btree (estado);


--
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON selemti.purchase_requests USING btree (requested_at);


--
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON selemti.purchase_requests USING btree (sucursal_id);


--
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON selemti.purchase_vendor_quote_lines USING btree (item_id);


--
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON selemti.purchase_vendor_quote_lines USING btree (quote_id);


--
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON selemti.purchase_vendor_quote_lines USING btree (request_line_id);


--
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON selemti.purchase_vendor_quotes USING btree (estado);


--
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON selemti.purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON selemti.recepcion_adjuntos USING btree (recepcion_id);


--
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON selemti.recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON selemti.recipe_labor_steps USING btree (labor_role_id);


--
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON selemti.recipe_labor_steps USING btree (recipe_id);


--
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON selemti.recipe_overhead_allocations USING btree (overhead_id);


--
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON selemti.replenishment_suggestions USING btree (estado);


--
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON selemti.replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON selemti.replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON selemti.replenishment_suggestions USING btree (prioridad);


--
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON selemti.replenishment_suggestions USING btree (production_order_id);


--
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON selemti.replenishment_suggestions USING btree (purchase_request_id);


--
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON selemti.replenishment_suggestions USING btree (revisado_por);


--
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON selemti.replenishment_suggestions USING btree (sugerido_en);


--
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON selemti.replenishment_suggestions USING btree (tipo);


--
-- Name: report_favorites_user_id_report_key_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX report_favorites_user_id_report_key_unique ON selemti.report_favorites USING btree (user_id, report_key);


--
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON selemti.audit_log USING btree (entidad, entidad_id);


--
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON selemti.audit_log USING btree ("timestamp");


--
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON selemti.audit_log USING btree (user_id);


--
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON selemti.cash_fund_movement_audit_log USING btree (action);


--
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON selemti.cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON selemti.cash_fund_movement_audit_log USING btree (movement_id);


--
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON selemti.pos_sync_logs USING btree (batch_id, status);


--
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON selemti.pos_sync_logs USING btree (external_id);


--
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON selemti.recepcion_cab USING btree (almacen_id);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON selemti.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON selemti.sessions USING btree (user_id);


--
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON selemti.ticket_item_modifiers USING btree (ticket_id);


--
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON selemti.ticket_item_modifiers USING btree (ticket_item_id);


--
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON selemti.formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON selemti.hist_cost_insumo USING btree (item_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON selemti.item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON selemti.items USING btree (item_code);


--
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON selemti.recipe_versions USING btree (recipe_id, version_no);


--
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON public.ticket FOR EACH ROW EXECUTE PROCEDURE public.assign_daily_folio();


--
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE OF status ON public.kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();


--
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE OF status ON public.ticket_item FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();


--
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON public.drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();

ALTER TABLE public.drawer_assigned_history DISABLE TRIGGER trg_selemti_dah_ai;


--
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON public.terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


--
-- Name: trg_invshot_biur; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_invshot_biur BEFORE INSERT OR UPDATE ON selemti.inventory_snapshot FOR EACH ROW EXECUTE PROCEDURE selemti.tg_invshot_autofill();


--
-- Name: trg_ipp_set_timestamp; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ipp_set_timestamp BEFORE UPDATE ON selemti.insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE selemti.set_timestamp_ipp();


--
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON selemti.item_categories FOR EACH ROW EXECUTE PROCEDURE selemti.fn_gen_cat_codigo();


--
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON selemti.items FOR EACH ROW EXECUTE PROCEDURE selemti.fn_assign_item_code();


--
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON selemti.item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE selemti.fn_after_price_insert_alert();


--
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON selemti.item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE selemti.fn_ivp_upsert_close_prev();


--
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON selemti.postcorte FOR EACH ROW EXECUTE PROCEDURE selemti.fn_postcorte_after_insert();


--
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON selemti.precorte FOR EACH ROW EXECUTE PROCEDURE selemti.fn_precorte_after_insert();


--
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON selemti.precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE selemti.fn_precorte_after_update_aprobado();


--
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON selemti.precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE selemti.fn_precorte_efectivo_bi();


--
-- Name: update_hist_cost_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_hist_cost_insumo_updated_at BEFORE UPDATE ON selemti.hist_cost_insumo FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_insumo_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_presentacion_updated_at BEFORE UPDATE ON selemti.insumo_presentacion FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_insumo_proveedor_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_proveedor_presentacion_updated_at BEFORE UPDATE ON selemti.insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_merma_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_merma_updated_at BEFORE UPDATE ON selemti.merma FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_op_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_cab_updated_at BEFORE UPDATE ON selemti.op_cab FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_op_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_insumo_updated_at BEFORE UPDATE ON selemti.op_insumo FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_recepcion_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_cab_updated_at BEFORE UPDATE ON selemti.recepcion_cab FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_recepcion_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_det_updated_at BEFORE UPDATE ON selemti.recepcion_det FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_traspaso_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_cab_updated_at BEFORE UPDATE ON selemti.traspaso_cab FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: update_traspaso_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_det_updated_at BEFORE UPDATE ON selemti.traspaso_det FOR EACH ROW EXECUTE PROCEDURE selemti.update_updated_at_column();


--
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES public.menu_modifier(id);


--
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES public.kitchen_ticket(id);


--
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES public.menu_item(id);


--
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES public.pizza_price(id);


--
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES public.ticket(id);


--
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES public.shop_floor(id);


--
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES public.customer(auto_id);


--
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES public.customer(auto_id);


--
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES public.cash_drawer(id);


--
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES public.drawer_pull_report(id);


--
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES public.user_type(id);


--
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES public.user_permission(name);


--
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES public.customer(auto_id);


--
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES public.menu_modifier_group(id);


--
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES public.menu_item(id);


--
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES public.menu_modifier_group(id);


--
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES public.printer_group(id);


--
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES public.ticket(id);


--
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES public.users(auto_id);


--
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES public.ticket_item(id);


--
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES public.ticket_item(id);


--
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES public.menu_group(id);


--
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES public.printer_group(id);


--
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES public.tax_group(id);


--
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES public.tax(id);


--
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES public.recepie(id);


--
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES public.shift(id);


--
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES public.user_type(id);


--
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES public.terminal(id);


--
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES public.menu_category(id);


--
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES public.menu_category(id);


--
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES public.coupon_and_discount(id);


--
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES public.kitchen_ticket(id);


--
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES public.pizza_modifier_price(id);


--
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES public.menu_modifier(id);


--
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES public.inventory_warehouse(id);


--
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES public.menu_modifier_group(id);


--
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES public.menu_modifier_group(id);


--
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES public.tax(id);


--
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES public.users(auto_id);


--
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES public.ticket_item_modifier(id);


--
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES public.ticket_item(id);


--
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES public.ticket(id);


--
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES public.menu_item(id);


--
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES public.table_booking_info(id);


--
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES public.shop_table(id);


--
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES public.shift(id);


--
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES public.ticket(id);


--
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES public.inventory_group(id);


--
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES public.packaging_unit(id);


--
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES public.packaging_unit(id);


--
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES public.inventory_location(id);


--
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES public.inventory_vendor(id);


--
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES public.restaurant(id);


--
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES public.inventory_item(id);


--
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES public.recepie(id);


--
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES public.multiplier(name);


--
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES public.pizza_modifier_price(id);


--
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES public.menu_modifier(id);


--
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES public.ticket_item(id);


--
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES public.users(auto_id);


--
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES public.shift(id);


--
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES public.users(auto_id);


--
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES public.gratuity(id);


--
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES public.users(auto_id);


--
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES public.shop_table(id);


--
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES public.shop_table_type(id);


--
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES public.terminal(id);


--
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES public.ticket(id);


--
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES public.ticket_item_modifier(id);


--
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES public.printer_group(id);


--
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES public.drawer_pull_report(id);


--
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES public.virtual_printer(id);


--
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES public.virtual_printer(id);


--
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES public.menu_item(id);


--
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES public.ticket_item_modifier(id);


--
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES public.ticket_item(id);


--
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES public.purchase_order(id);


--
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES public.inventory_item(id);


--
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES public.inventory_vendor(id);


--
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES public.inventory_warehouse(id);


--
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES public.inventory_warehouse(id);


--
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES public.shop_floor(id);


--
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES public.printer_group(id);


--
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES public.shop_table_status(id);


--
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES public.menu_item_size(id);


--
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES public.customer(auto_id);


--
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES public.shop_floor_template(id);


--
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES public.menu_item(id);


--
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES public.coupon_and_discount(id);


--
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES public.shift(id);


--
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES public.menu_item(id);


--
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES public.shift(id);


--
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES public.order_type(id);


--
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES public.menu_item(id);


--
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES public.menu_group(id);


--
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES public.coupon_and_discount(id);


--
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES public.transactions(id);


--
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES public.users(auto_id);


--
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES public.pizza_crust(id);


--
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES public.order_type(id);


--
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES public.menu_item_size(id);


--
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES public.tax(id);


--
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES public.tax_group(id);


--
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES public.menu_item(id);


--
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES public.ticket(id);


--
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES public.terminal(id);


--
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES public.users(auto_id);


--
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES public.payout_recepients(id);


--
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES public.payout_reasons(id);


--
-- Name: alertas_cortes_destinatario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alertas_cortes
    ADD CONSTRAINT alertas_cortes_destinatario_id_fkey FOREIGN KEY (destinatario_id) REFERENCES selemti.users(id);


--
-- Name: alertas_cortes_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alertas_cortes
    ADD CONSTRAINT alertas_cortes_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES selemti.postcorte(id) ON DELETE CASCADE;


--
-- Name: alertas_cortes_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.alertas_cortes
    ADD CONSTRAINT alertas_cortes_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE;


--
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE RESTRICT;


--
-- Name: audit_log_global_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log_global
    ADD CONSTRAINT audit_log_global_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES selemti.users(id);


--
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE RESTRICT;


--
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES selemti.caja_fondo_mov(id) ON DELETE CASCADE;


--
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE;


--
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE;


--
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE;


--
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES selemti.cash_funds(id) ON DELETE CASCADE;


--
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;


--
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES selemti.cash_funds(id) ON DELETE CASCADE;


--
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE SET NULL;


--
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES selemti.cat_unidades(id) ON DELETE CASCADE;


--
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES selemti.cat_unidades(id) ON DELETE CASCADE;


--
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES selemti.postcorte(id) ON DELETE CASCADE;


--
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES selemti.unidades_medida_legacy(id);


--
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES selemti.unidades_medida_legacy(id);


--
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: fk_inventory_snapshot_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_snapshot
    ADD CONSTRAINT fk_inventory_snapshot_item FOREIGN KEY (item_id) REFERENCES selemti.items(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_pos_map_receta; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_map
    ADD CONSTRAINT fk_pos_map_receta FOREIGN KEY (receta_id) REFERENCES selemti.receta_cab(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES selemti.cat_almacenes(id) ON DELETE SET NULL;


--
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES selemti.purchase_suggestions(id) ON DELETE SET NULL;


--
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES selemti.cat_almacenes(id) ON DELETE SET NULL;


--
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES selemti.purchase_requests(id) ON DELETE SET NULL;


--
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE SET NULL;


--
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;


--
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;


--
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES selemti.items(id) ON DELETE RESTRICT;


--
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES selemti.cat_proveedores(id) ON DELETE SET NULL;


--
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES selemti.purchase_suggestions(id) ON DELETE CASCADE;


--
-- Name: fk_purchase_orders_vendor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.purchase_orders
    ADD CONSTRAINT fk_purchase_orders_vendor FOREIGN KEY (vendor_id) REFERENCES selemti.cat_proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_recipe_cost_snap_recipe; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_recipe FOREIGN KEY (recipe_id) REFERENCES selemti.receta_cab(id) ON DELETE CASCADE;


--
-- Name: fk_recipe_cost_snap_user; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_user FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;


--
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES selemti.ticket_venta_cab(id) ON DELETE CASCADE;


--
-- Name: hist_cost_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id) ON DELETE RESTRICT;


--
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: insumo_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id) ON DELETE RESTRICT;


--
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: insumo_proveedor_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES selemti.inv_consumo_pos(id) ON DELETE CASCADE;


--
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES selemti.items(id) ON DELETE CASCADE;


--
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE CASCADE;


--
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: ipp_proveedor_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_proveedor_fk FOREIGN KEY (proveedor_id) REFERENCES selemti.proveedor(id);


--
-- Name: ipp_uom_base_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_base_fk FOREIGN KEY (uom_base_id) REFERENCES selemti.cat_unidades(id);


--
-- Name: ipp_uom_compra_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_compra_fk FOREIGN KEY (uom_compra_id) REFERENCES selemti.cat_unidades(id);


--
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES selemti.unidades_medida_legacy(id);


--
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES selemti.item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES selemti.cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES selemti.cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES selemti.cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: lote_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.lote
    ADD CONSTRAINT lote_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: merma_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma
    ADD CONSTRAINT merma_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: merma_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma
    ADD CONSTRAINT merma_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: merma_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.merma
    ADD CONSTRAINT merma_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES selemti.permissions(id) ON DELETE CASCADE;


--
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES selemti.roles(id) ON DELETE CASCADE;


--
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES selemti.receta_cab(id);


--
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE RESTRICT;


--
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: op_cab_user_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: op_cab_user_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: op_insumo_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo
    ADD CONSTRAINT op_insumo_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: op_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo
    ADD CONSTRAINT op_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES selemti.op_cab(id) ON DELETE CASCADE;


--
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES selemti.op_cab(id) ON DELETE CASCADE;


--
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES selemti.unidades_medida_legacy(id);


--
-- Name: postcorte_aprobado_por_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.postcorte
    ADD CONSTRAINT postcorte_aprobado_por_fkey FOREIGN KEY (aprobado_por) REFERENCES selemti.users(id);


--
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE;


--
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES selemti.precorte(id) ON DELETE CASCADE;


--
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES selemti.precorte(id) ON DELETE CASCADE;


--
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY selemti.precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE;


--
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES selemti.sol_prod_cab(id);


--
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES selemti.prod_cab(id) ON DELETE CASCADE;


--
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES selemti.job_recalc_queue(id);


--
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) ON DELETE RESTRICT;


--
-- Name: recepcion_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: recepcion_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES selemti.cat_almacenes(id) ON DELETE RESTRICT;


--
-- Name: recepcion_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES selemti.recepcion_cab(id) ON DELETE CASCADE;


--
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: receta_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_insumo
    ADD CONSTRAINT receta_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES selemti.receta_cab(id);


--
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES selemti.permissions(id) ON DELETE CASCADE;


--
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES selemti.roles(id) ON DELETE CASCADE;


--
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;


--
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES selemti.cash_fund_movements(id) ON DELETE CASCADE;


--
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES selemti.menu_items(id) ON DELETE CASCADE;


--
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES selemti.menu_items(id) ON DELETE CASCADE;


--
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES selemti.pos_sync_batches(id) ON DELETE CASCADE;


--
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES selemti.report_definitions(id) ON DELETE CASCADE;


--
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES selemti.sol_prod_cab(id) ON DELETE CASCADE;


--
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES selemti.unidades_medida_legacy(id);


--
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES selemti.receta_shadow(id);


--
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES selemti.receta_version(id);


--
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES selemti.transfer_cab(id) ON DELETE CASCADE;


--
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES selemti.cat_almacenes(id) ON DELETE RESTRICT;


--
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES selemti.cat_almacenes(id) ON DELETE RESTRICT;


--
-- Name: traspaso_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;


--
-- Name: traspaso_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det
    ADD CONSTRAINT traspaso_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);


--
-- Name: traspaso_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det
    ADD CONSTRAINT traspaso_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);


--
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES selemti.traspaso_cab(id) ON DELETE CASCADE;


--
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES selemti.unidad_medida_legacy(id);


--
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY selemti.usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES selemti.rol(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: TABLE vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE selemti.vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE selemti.vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE selemti.vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE selemti.vw_sesion_dpr TO floreant;


--
-- PostgreSQL database dump complete
--

