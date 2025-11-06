--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-05 23:56:25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6115 (class 1262 OID 151417)
-- Name: pos; Type: DATABASE; Schema: -; Owner: floreant
--

CREATE DATABASE pos WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Mexico.1252' LC_CTYPE = 'Spanish_Mexico.1252';


ALTER DATABASE pos OWNER TO floreant;

\connect pos

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 151418)
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

--
-- TOC entry 670 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 6118 (class 0 OID 0)
-- Dependencies: 670
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 672 (class 3079 OID 151419)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 6119 (class 0 OID 0)
-- Dependencies: 672
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 671 (class 3079 OID 151456)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 6120 (class 0 OID 0)
-- Dependencies: 671
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = selemti, pg_catalog;

--
-- TOC entry 1135 (class 1247 OID 151468)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1138 (class 1247 OID 151474)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1141 (class 1247 OID 151482)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1144 (class 1247 OID 151488)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1147 (class 1247 OID 151494)
-- Name: mov_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE mov_tipo AS ENUM (
    'RECEPCION',
    'COMPRA',
    'VENTA',
    'CONSUMO_OP',
    'AJUSTE',
    'TRASPASO_IN',
    'TRASPASO_OUT',
    'ANULACION'
);


ALTER TYPE mov_tipo OWNER TO postgres;

--
-- TOC entry 1150 (class 1247 OID 151512)
-- Name: op_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE op_estado AS ENUM (
    'ABIERTA',
    'EN_PROCESO',
    'CERRADA',
    'ANULADA'
);


ALTER TYPE op_estado OWNER TO postgres;

--
-- TOC entry 1153 (class 1247 OID 151522)
-- Name: pos_modifier_effect; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE pos_modifier_effect AS ENUM (
    'extra',
    'remove',
    'replace',
    'delta'
);


ALTER TYPE pos_modifier_effect OWNER TO postgres;

--
-- TOC entry 1156 (class 1247 OID 151532)
-- Name: producto_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE producto_tipo OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 731 (class 1255 OID 151539)
-- Name: _last_assign_window(integer, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _last_assign_window(_terminal_id integer, _user_id integer, _ref_time timestamp with time zone) RETURNS TABLE(from_ts timestamp with time zone, to_ts timestamp with time zone)
    LANGUAGE sql STABLE
    AS '
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
    COALESCE(prev_event, _ref_time - INTERVAL ''24 hours'')::timestamptz AS from_ts,
    event_time::timestamptz AS to_ts
FROM ev
WHERE action IN (''ASIGNAR'',''ASSIGN'',''OPEN'',''CERRAR'',''CLOSE'',''LIBERAR'',''UNASSIGN'')
ORDER BY event_time DESC
LIMIT 1;
';


ALTER FUNCTION public._last_assign_window(_terminal_id integer, _user_id integer, _ref_time timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 732 (class 1255 OID 151540)
-- Name: assign_daily_folio(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION assign_daily_folio() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
    v_branch   TEXT;
    v_date     DATE;
    v_next     INTEGER;
BEGIN
    IF NEW.terminal_id IS NULL THEN
        RAISE EXCEPTION ''No se puede crear ticket sin terminal_id'';
    END IF;
    IF NEW.create_date IS NULL THEN
        NEW.create_date := NOW();
    END IF;
    v_date := (NEW.create_date AT TIME ZONE ''America/Mexico_City'')::DATE;
    SELECT COALESCE(NULLIF(UPPER(BTRIM(t.location)), ''''), '''') INTO v_branch
    FROM public.terminal t
    WHERE t.id = NEW.terminal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION ''Terminal % no existe en la base de datos'', NEW.terminal_id;
    END IF;
    IF NEW.daily_folio IS NOT NULL AND NEW.folio_date IS NOT NULL AND NEW.branch_key IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.ticket
            WHERE folio_date = NEW.folio_date
            AND branch_key = NEW.branch_key
            AND daily_folio = NEW.daily_folio
            AND id != NEW.id
        ) THEN
            RAISE EXCEPTION ''Folio % ya existe para % en %'', NEW.daily_folio, NEW.branch_key, NEW.folio_date;
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
';


ALTER FUNCTION public.assign_daily_folio() OWNER TO floreant;

--
-- TOC entry 733 (class 1255 OID 151541)
-- Name: f_daily_diagnostics_summary_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION f_daily_diagnostics_summary_on(p_date date) RETURNS TABLE(source_view text, severity text, rows bigint)
    LANGUAGE sql STABLE
    AS '
SELECT ''vw_diag_neto_vs_cobros''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_neto_vs_cobros
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_discount_header_vs_lines''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_discount_header_vs_lines
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_paid_but_no_payments''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_paid_but_no_payments
WHERE folio_date = p_date
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_unnormalized_payments''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_unnormalized_payments
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_service_charge_vs_paid''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_service_charge_vs_paid
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_drawer_vs_cash_transactions''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_drawer_vs_cash_transactions
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_orphans_tickets''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_orphans_tickets
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_orphans_tx''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_orphans_tx
GROUP BY 1,2
UNION ALL
SELECT ''vw_diag_high_discounts''::text,
       COALESCE(severity,''INFO'')::text,
       COUNT(*)::bigint
FROM vw_diag_high_discounts
WHERE folio_date = p_date
GROUP BY 1,2;
';


ALTER FUNCTION public.f_daily_diagnostics_summary_on(p_date date) OWNER TO postgres;

--
-- TOC entry 734 (class 1255 OID 151542)
-- Name: f_diag_drawer_vs_cash_transactions_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION f_diag_drawer_vs_cash_transactions_on(p_date date) RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric, cash_in numeric, non_cash_in numeric, expected_cash numeric, diff numeric, error_code text, severity text)
    LANGUAGE sql STABLE
    AS '
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
           AND UPPER(tx.transaction_type) = ''CREDIT''
           AND selemti.fn_normalizar_forma_pago(
                 tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
               ) = ''CASH''
          THEN COALESCE(tx.amount,0) ELSE 0 END
    )::numeric(12,2) AS cash_in,
    SUM(CASE
          WHEN tx.voided = FALSE
           AND UPPER(tx.transaction_type) = ''CREDIT''
           AND selemti.fn_normalizar_forma_pago(
                 tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
               ) IS DISTINCT FROM ''CASH''
           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
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
  ''DRAWER_CASH_MISMATCH''::text AS error_code,
  (CASE WHEN ABS(cash_in - expected_cash) > 1 THEN ''CRITICAL'' ELSE ''WARN'' END)::text AS severity
FROM calc
WHERE ABS(cash_in - expected_cash) > 0.01;
';


ALTER FUNCTION public.f_diag_drawer_vs_cash_transactions_on(p_date date) OWNER TO postgres;

--
-- TOC entry 735 (class 1255 OID 151543)
-- Name: f_item_mods_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION f_item_mods_on(p_date date) RETURNS TABLE(folio_date date, branch_key text, terminal_id integer, ticket_id integer, ticket_item_id integer, item_name text, modifier_name text, qty_item numeric, mods_count bigint, mods_total_amount numeric)
    LANGUAGE sql STABLE
    AS '
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
';


ALTER FUNCTION public.f_item_mods_on(p_date date) OWNER TO postgres;

--
-- TOC entry 736 (class 1255 OID 151544)
-- Name: f_sales_mix_payment_on(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION f_sales_mix_payment_on(p_date date) RETURNS TABLE(folio_date date, branch_key text, normalized_payment text, total numeric)
    LANGUAGE sql STABLE
    AS '
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  selemti.fn_normalizar_forma_pago(
    tx.payment_type, tx.transaction_type, tx.payment_sub_type, tx.custom_payment_name
  ) AS normalized_payment,
  ROUND(SUM(CASE
      WHEN tx.voided = FALSE
       AND UPPER(tx.transaction_type) = ''CREDIT''
       AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
      THEN COALESCE(tx.amount,0) ELSE 0 END)::numeric, 2) AS total
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid = TRUE AND t.voided = FALSE
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
GROUP BY 1,2,3;
';


ALTER FUNCTION public.f_sales_mix_payment_on(p_date date) OWNER TO postgres;

--
-- TOC entry 737 (class 1255 OID 151545)
-- Name: fn_correct_drawer_report(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_correct_drawer_report(report_date date) RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric)
    LANGUAGE plpgsql
    AS '
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
';


ALTER FUNCTION public.fn_correct_drawer_report(report_date date) OWNER TO postgres;

--
-- TOC entry 738 (class 1255 OID 151546)
-- Name: fn_daily_reconciliation(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_daily_reconciliation(report_date date) RETURNS TABLE(terminal_id integer, tickets_count integer, transactions_count integer, ticket_net_total numeric, transactions_total numeric, difference numeric, status text)
    LANGUAGE plpgsql
    AS '
BEGIN
  RETURN QUERY
  SELECT
    t.terminal_id,
    COUNT(DISTINCT t.id) AS tickets_count,
    COUNT(tx.id) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_type = ''CREDIT''
        AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
    ) AS transactions_count,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS ticket_net_total,
    SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = ''CREDIT''
         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
        THEN tx.amount ELSE 0 END
    )::numeric(12,2) AS transactions_total,
    (SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = ''CREDIT''
         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
        THEN tx.amount ELSE 0 END
    ) - SUM(t.total_price - t.total_discount))::numeric(12,2) AS difference,
    CASE
      WHEN SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = ''CREDIT''
           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
          THEN tx.amount ELSE 0 END
      ) = SUM(t.total_price - t.total_discount)
      THEN ''OK''
      ELSE ''DISCREPANCY''
    END AS status
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.terminal_id;
END;
';


ALTER FUNCTION public.fn_daily_reconciliation(report_date date) OWNER TO postgres;

--
-- TOC entry 739 (class 1255 OID 151547)
-- Name: fn_reconciliation_detail(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_reconciliation_detail(report_date date) RETURNS TABLE(ticket_id integer, terminal_id integer, ticket_number integer, ticket_total numeric, ticket_discount numeric, ticket_neto numeric, transactions_sum numeric, discrepancy numeric, discrepancy_type text)
    LANGUAGE plpgsql
    AS '
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
         AND tx.transaction_type = ''CREDIT''
         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
        THEN tx.amount END
    ), 0)::numeric(12,2) AS transactions_sum,
    (COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = ''CREDIT''
         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount))::numeric(12,2) AS discrepancy,
    CASE
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = ''CREDIT''
           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
          THEN tx.amount END
      ), 0) > (t.total_price - t.total_discount) THEN ''OVERSTATED''
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = ''CREDIT''
           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
          THEN tx.amount END
      ), 0) < (t.total_price - t.total_discount) THEN ''UNDERSTATED''
      ELSE ''OK''
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
       AND tx.transaction_type = ''CREDIT''
       AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
      THEN tx.amount END
  ), 0) <> (t.total_price - t.total_discount)
  ORDER BY ABS(
    COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = ''CREDIT''
         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount)
  ) DESC;
END;
';


ALTER FUNCTION public.fn_reconciliation_detail(report_date date) OWNER TO postgres;

--
-- TOC entry 740 (class 1255 OID 151548)
-- Name: get_daily_stats(date); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION get_daily_stats(p_date date DEFAULT ('now'::text)::date) RETURNS TABLE(sucursal text, total_ordenes integer, total_ventas numeric, primer_orden time without time zone, ultima_orden time without time zone, promedio_por_hora numeric)
    LANGUAGE sql STABLE
    AS '
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
    AND tfc.status_simple != ''CANCELADO''
    GROUP BY tfc.branch_key
    ORDER BY tfc.branch_key;
';


ALTER FUNCTION public.get_daily_stats(p_date date) OWNER TO floreant;

--
-- TOC entry 741 (class 1255 OID 151549)
-- Name: get_ticket_folio_info(integer); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION get_ticket_folio_info(p_ticket_id integer) RETURNS TABLE(daily_folio integer, folio_date date, branch_key text, folio_date_txt text, folio_display text, sucursal_completa text, terminal_name text)
    LANGUAGE sql STABLE
    AS '
    SELECT
        t.daily_folio,
        t.folio_date,
        t.branch_key,
        TO_CHAR(t.folio_date, ''DD/MM/YYYY'') AS folio_date_txt,
        LPAD(t.daily_folio::TEXT, 4, ''0'') AS folio_display,
        COALESCE(term.location, ''DEFAULT'') AS sucursal_completa,
        term.name AS terminal_name
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.id = p_ticket_id;
';


ALTER FUNCTION public.get_ticket_folio_info(p_ticket_id integer) OWNER TO floreant;

--
-- TOC entry 742 (class 1255 OID 151550)
-- Name: kds_notify(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION kds_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS '
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
    IF TG_TABLE_NAME = ''kitchen_ticket_item'' THEN
        IF NEW.ticket_item_id IS NULL THEN
            RAISE EXCEPTION ''ticket_item_id no puede ser NULL en kitchen_ticket_item'';
        END IF;
        v_item_id := NEW.ticket_item_id;
        SELECT ti.ticket_id, ti.pg_id INTO v_ticket_id, v_pg_id
        FROM ticket_item ti WHERE ti.id = v_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION ''ticket_item % no existe'', v_item_id;
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION ''ticket % no existe'', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, ''0'');
        v_status := UPPER(COALESCE(NEW.status, ''''));
        v_type := CASE WHEN TG_OP = ''INSERT'' THEN ''item_upsert'' ELSE ''item_status'' END;
        PERFORM pg_notify(
            ''kds_event'',
            json_build_object(
                ''type'',        v_type,
                ''ticket_id'',   v_ticket_id,
                ''pg'',          v_pg_id,
                ''item_id'',     v_item_id,
                ''status'',      v_status,
                ''daily_folio'', v_daily_folio,
                ''branch_key'',  v_branch_key,
                ''folio_fmt'',   v_folio_fmt,
                ''ts'',          NOW()
            )::TEXT
        );
    ELSIF TG_TABLE_NAME = ''ticket_item'' THEN
        v_item_id := NEW.id;
        v_ticket_id := NEW.ticket_id;
        v_pg_id := NEW.pg_id;
        IF v_ticket_id IS NULL THEN
            RAISE EXCEPTION ''ticket_id no puede ser NULL en ticket_item'';
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION ''ticket % no existe'', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, ''0'');
        v_status := UPPER(COALESCE(NEW.status, ''''));
        v_type := CASE WHEN TG_OP = ''INSERT'' THEN ''item_insert'' ELSE ''item_status'' END;
        PERFORM pg_notify(
            ''kds_event'',
            json_build_object(
                ''type'',        v_type,
                ''ticket_id'',   v_ticket_id,
                ''pg'',          v_pg_id,
                ''item_id'',     v_item_id,
                ''status'',      v_status,
                ''daily_folio'', v_daily_folio,
                ''branch_key'',  v_branch_key,
                ''folio_fmt'',   v_folio_fmt,
                ''ts'',          NOW()
            )::TEXT
        );
    END IF;
    IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
        WITH s AS (
            SELECT
                ti.id AS item_id,
                UPPER(COALESCE(kti.status, ti.status, '''')) AS st
            FROM ticket_item ti
            LEFT JOIN kitchen_ticket_item kti ON kti.ticket_item_id = ti.id
            WHERE ti.ticket_id = v_ticket_id AND ti.pg_id = v_pg_id
            GROUP BY ti.id, st
        )
        SELECT
            COUNT(DISTINCT item_id) AS total,
            COUNT(DISTINCT item_id) FILTER (WHERE st IN (''READY'', ''DONE'')) AS ready,
            COUNT(DISTINCT item_id) FILTER (WHERE st = ''DONE'') AS done
        INTO v_total, v_ready, v_done
        FROM s;
        IF v_total > 0 AND v_total = v_ready THEN
            PERFORM pg_notify(
                ''kds_event'',
                json_build_object(
                    ''type'',        ''ticket_all_ready'',
                    ''ticket_id'',   v_ticket_id,
                    ''pg'',          v_pg_id,
                    ''daily_folio'', v_daily_folio,
                    ''branch_key'',  v_branch_key,
                    ''folio_fmt'',   v_folio_fmt,
                    ''ts'',          NOW()
                )::TEXT
            );
        END IF;
        IF v_total > 0 AND v_total = v_done THEN
            PERFORM pg_notify(
                ''kds_event'',
                json_build_object(
                    ''type'',        ''ticket_all_done'',
                    ''ticket_id'',   v_ticket_id,
                    ''pg'',          v_pg_id,
                    ''daily_folio'', v_daily_folio,
                    ''branch_key'',  v_branch_key,
                    ''folio_fmt'',   v_folio_fmt,
                    ''ts'',          NOW()
                )::TEXT
            );
        END IF;
    END IF;
    RETURN NEW;
END;
';


ALTER FUNCTION public.kds_notify() OWNER TO floreant;

--
-- TOC entry 743 (class 1255 OID 151551)
-- Name: reset_daily_folio_smart(text); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION reset_daily_folio_smart(p_branch text DEFAULT NULL::text) RETURNS TABLE(branch_reset text, tickets_affected integer)
    LANGUAGE plpgsql
    AS '
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
        branch_reset := ''none'';
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
            RAISE NOTICE ''ADVERTENCIA: Sucursal % ya tiene % tickets hoy - NO reseteable'',
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
';


ALTER FUNCTION public.reset_daily_folio_smart(p_branch text) OWNER TO floreant;

SET search_path = selemti, pg_catalog;

--
-- TOC entry 744 (class 1255 OID 151552)
-- Name: audit_trigger_func(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION audit_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    IF TG_OP = ''DELETE'' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, OLD.id::TEXT, row_to_json(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    ELSIF TG_OP = ''UPDATE'' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, old_data, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = ''INSERT'' THEN
        INSERT INTO selemti.audit_log_global (
            schema_name, table_name, operation, record_id, new_data, changed_at
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NEW.id::TEXT, row_to_json(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    END IF;
END;
';


ALTER FUNCTION selemti.audit_trigger_func() OWNER TO postgres;

--
-- TOC entry 745 (class 1255 OID 151553)
-- Name: cerrar_lote_preparado(bigint, merma_clase, text, integer, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION cerrar_lote_preparado(p_lote_id bigint, p_clase merma_clase, p_motivo text, p_usuario_id integer DEFAULT NULL::integer, p_uom_id integer DEFAULT NULL::integer) RETURNS bigint
    LANGUAGE plpgsql
    AS '
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
        RAISE EXCEPTION ''Lote % no existe'', p_lote_id;
END IF;
IF v_qty_disponible IS NULL OR v_qty_disponible <= 0 THEN
        RETURN 0;
END IF;
RETURN v_mov_id;
END;
';


ALTER FUNCTION selemti.cerrar_lote_preparado(p_lote_id bigint, p_clase merma_clase, p_motivo text, p_usuario_id integer, p_uom_id integer) OWNER TO postgres;

--
-- TOC entry 746 (class 1255 OID 151554)
-- Name: fn_after_price_insert_alert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_after_price_insert_alert() RETURNS trigger
    LANGUAGE plpgsql
    AS '
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
END';


ALTER FUNCTION selemti.fn_after_price_insert_alert() OWNER TO postgres;

--
-- TOC entry 765 (class 1255 OID 151555)
-- Name: fn_assign_item_code(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_assign_item_code() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
    v_prefijo text;
    v_next    bigint;
BEGIN
    IF NEW.category_id IS NULL THEN
        RETURN NEW;
    END IF;
    IF NEW.item_code IS NOT NULL AND NEW.item_code <> '''' THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(NULLIF(TRIM(prefijo),''''), ''C'') INTO v_prefijo
    FROM selemti.item_categories WHERE id=NEW.category_id;

    INSERT INTO selemti.item_category_counters(category_id,last_val,updated_at)
    VALUES (NEW.category_id,1,now())
    ON CONFLICT(category_id) DO UPDATE
        SET last_val = selemti.item_category_counters.last_val + 1,
            updated_at = now()
    RETURNING last_val INTO v_next;

    NEW.item_code := v_prefijo || ''-'' || lpad(v_next::text,5,''0'');
    RETURN NEW;
END';


ALTER FUNCTION selemti.fn_assign_item_code() OWNER TO postgres;

--
-- TOC entry 779 (class 1255 OID 151556)
-- Name: fn_confirmar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_confirmar_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS '
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass(''selemti.mov_inv'') IS NOT NULL, false);
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
        ''VENTA_TEO'',
        SUM(d.cantidad),
        COALESCE(d.uom, ''UN''),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        ''POS_TICKET'',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object(''ticket_id'', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = ''PENDIENTE''
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = ''CONFIRMADO'', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = ''PENDIENTE'';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, ''CONFIRM'', NULL);
END;
';


ALTER FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 747 (class 1255 OID 151557)
-- Name: fn_dah_after_insert(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_dah_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE v_term RECORD;
BEGIN
  IF NEW.operation = ''ASIGNAR'' THEN
    SELECT * INTO v_term FROM public.terminal
    WHERE assigned_user = NEW.a_user
    ORDER BY id LIMIT 1;

    IF v_term IS NULL THEN
      INSERT INTO selemti.auditoria(quien,que,payload)
      VALUES(NEW.a_user,''NO_SE_PUDO_RESOLVER_TERMINAL'',
             jsonb_build_object(''dah_id'',NEW.id,''operation'',NEW.operation,''time'',NEW."time"));
      RETURN NEW;
    END IF;

    INSERT INTO selemti.sesion_cajon(
      terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
      apertura_ts, estatus, opening_float, dah_evento_id
    ) VALUES (
      v_term.id, COALESCE(v_term.name,''Terminal ''||v_term.id), COALESCE(v_term.location,''''),
      NEW.a_user, COALESCE(NEW."time", now()), ''ACTIVA'', COALESCE(v_term.current_balance,0), NEW.id
    );

  ELSIF NEW.operation = ''CERRAR'' THEN
    SELECT * INTO v_term FROM public.terminal
    WHERE assigned_user = NEW.a_user
    ORDER BY id LIMIT 1;

    UPDATE selemti.sesion_cajon
       SET cierre_ts     = COALESCE(NEW."time", now()),
           estatus       = ''LISTO_PARA_CORTE'',
           closing_float = COALESCE(v_term.current_balance,0),
           dah_evento_id = COALESCE(dah_evento_id, NEW.id)
     WHERE terminal_id = COALESCE(v_term.id, terminal_id)
       AND cajero_usuario_id = NEW.a_user
       AND cierre_ts IS NULL;
  END IF;

  RETURN NEW;
END ';


ALTER FUNCTION selemti.fn_dah_after_insert() OWNER TO floreant;

--
-- TOC entry 748 (class 1255 OID 151558)
-- Name: fn_dah_after_insert_refuerzo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_dah_after_insert_refuerzo() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
  v_terminal_id   INTEGER;
v_now_balance   NUMERIC(12,2);
v_op            TEXT := COALESCE(NEW.operation,'''');
v_obj_id        BIGINT;
BEGIN
  IF v_op !~* ''(release|liber|close|cerrar|unassign|fin|end)'' THEN
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
           estatus       = CASE WHEN estatus=''ACTIVA'' THEN ''LISTO_PARA_CORTE'' ELSE estatus END
     WHERE id = v_obj_id;
END IF;
RETURN NEW;
END ';


ALTER FUNCTION selemti.fn_dah_after_insert_refuerzo() OWNER TO postgres;

--
-- TOC entry 778 (class 1255 OID 151559)
-- Name: fn_expandir_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_expandir_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS '
DECLARE
    v_consumo_id bigint;
    v_has_recipes boolean := coalesce(to_regclass(''selemti.recipe_details'') IS NOT NULL, false);
BEGIN
    INSERT INTO selemti.inv_consumo_pos (ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, expandido, created_at)
    SELECT DISTINCT
        ti.ticket_id,
        ti.id,
        t.sucursal_id,
        t.terminal_id,
        ''PENDIENTE'',
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
            ''RECETA'',
            jsonb_build_object(''ticket_item_id'', ti.id)
        FROM selemti.recipe_details rd
        JOIN public.ticket_item ti ON ti.item_id = rd.recipe_item_id AND ti.ticket_id = _ticket_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM selemti.inv_consumo_pos_det d
            WHERE d.consumo_id = v_consumo_id
              AND d.item_id = rd.item_id
              AND coalesce(d.meta->>''ticket_item_id'', '''') = ti.id::text
        );
    END LOOP;

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, ''EXPAND'', NULL);
END;
';


ALTER FUNCTION selemti.fn_expandir_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 749 (class 1255 OID 151560)
-- Name: fn_fondo_actual(integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_fondo_actual(p_terminal_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS '
DECLARE
  v_balance NUMERIC(12,2);
BEGIN
  SELECT t.current_balance::numeric(12,2)
    INTO v_balance
  FROM public.terminal t
  WHERE t.id = p_terminal_id;

  RETURN COALESCE(v_balance, 0);
END;
';


ALTER FUNCTION selemti.fn_fondo_actual(p_terminal_id integer) OWNER TO floreant;

--
-- TOC entry 751 (class 1255 OID 151561)
-- Name: fn_gen_cat_codigo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_gen_cat_codigo() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    IF NEW.codigo IS NULL OR NEW.codigo = '''' THEN
        NEW.codigo := ''CAT-'' || lpad(nextval(''selemti.seq_cat_codigo'')::text, 4, ''0'');
    END IF;
    RETURN NEW;
END';


ALTER FUNCTION selemti.fn_gen_cat_codigo() OWNER TO postgres;

--
-- TOC entry 752 (class 1255 OID 151562)
-- Name: fn_generar_postcorte(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_generar_postcorte(p_sesion_id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS '
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
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN (''CREDITO'') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN (''DEBITO'', ''DÃ‰BITO'') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN (''TRANSFER'', ''TRANSFERENCIA'') THEN monto ELSE 0 END), 0)
  INTO v_decl_cr, v_decl_db, v_decl_tr
  FROM selemti.precorte_otros
  WHERE precorte_id = v_precorte_id;

  -- Calcular sistema (desde transactions POS)
  SELECT
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = ''CASH'' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = ''CREDIT_CARD'' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = ''DEBIT_CARD'' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = ''CUSTOM_PAYMENT'' AND UPPER(custom_payment_name) LIKE ''TRANSFER%'' THEN amount ELSE 0 END), 0)
  INTO v_sys_ef, v_sys_cr, v_sys_db, v_sys_tr
  FROM public.transactions
  WHERE terminal_id = v_terminal_id
    AND transaction_time BETWEEN v_apertura_ts AND COALESCE(v_cierre_ts, now())
    AND UPPER(transaction_type) = ''CREDIT''
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
    CASE WHEN ABS(v_dif_ef) < 0.01 THEN ''CUADRA'' WHEN v_dif_ef > 0 THEN ''A_FAVOR'' ELSE ''EN_CONTRA'' END,
    v_sys_cr + v_sys_db, v_decl_cr + v_decl_db, v_dif_tj,
    CASE WHEN ABS(v_dif_tj) < 0.01 THEN ''CUADRA'' WHEN v_dif_tj > 0 THEN ''A_FAVOR'' ELSE ''EN_CONTRA'' END,
    v_sys_tr, v_decl_tr, v_dif_tr,
    CASE WHEN ABS(v_dif_tr) < 0.01 THEN ''CUADRA'' WHEN v_dif_tr > 0 THEN ''A_FAVOR'' ELSE ''EN_CONTRA'' END,
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
';


ALTER FUNCTION selemti.fn_generar_postcorte(p_sesion_id bigint) OWNER TO postgres;

--
-- TOC entry 6121 (class 0 OID 0)
-- Dependencies: 752
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 759 (class 1255 OID 151563)
-- Name: fn_item_unit_cost_at(bigint, timestamp without time zone, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_item_unit_cost_at(p_item_id bigint, p_at timestamp without time zone, p_target_uom text) RETURNS numeric
    LANGUAGE plpgsql
    AS '
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
END';


ALTER FUNCTION selemti.fn_item_unit_cost_at(p_item_id bigint, p_at timestamp without time zone, p_target_uom text) OWNER TO postgres;

--
-- TOC entry 758 (class 1255 OID 151564)
-- Name: fn_ivp_upsert_close_prev(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_ivp_upsert_close_prev() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
  UPDATE selemti.item_vendor_prices
     SET effective_to = NEW.effective_from
   WHERE item_id=NEW.item_id
     AND vendor_id=NEW.vendor_id
     AND effective_to IS NULL
     AND effective_from < NEW.effective_from;
  RETURN NEW;
END';


ALTER FUNCTION selemti.fn_ivp_upsert_close_prev() OWNER TO postgres;

--
-- TOC entry 753 (class 1255 OID 151565)
-- Name: fn_normalizar_forma_pago(text, text, text, text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_normalizar_forma_pago(p_payment_type text, p_transaction_type text, p_payment_sub_type text, p_custom_name text) RETURNS text
    LANGUAGE plpgsql
    AS '
DECLARE pt TEXT := upper(coalesce(p_payment_type,''''));
DECLARE cn TEXT := selemti.fn_slug(p_custom_name);
BEGIN
  IF pt IN (''CASH'',''CREDIT'',''DEBIT'',''TRANSFER'') THEN
    RETURN pt;
  ELSIF pt = ''CUSTOM_PAYMENT'' THEN
    IF cn IS NOT NULL THEN RETURN ''CUSTOM:''||cn; ELSE RETURN ''CUSTOM''; END IF;
  ELSIF pt IN (''REFUND'',''PAY_OUT'',''CASH_DROP'') THEN
    RETURN pt; -- egresos/ajustes estandarizados
  ELSE
    RETURN pt;
  END IF;
END ';


ALTER FUNCTION selemti.fn_normalizar_forma_pago(p_payment_type text, p_transaction_type text, p_payment_sub_type text, p_custom_name text) OWNER TO floreant;

--
-- TOC entry 754 (class 1255 OID 151566)
-- Name: fn_postcorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_postcorte_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = ''CERRADA'',
      cierre_ts = COALESCE(cierre_ts, now())
  WHERE id = NEW.sesion_id;
  RETURN NEW;
END;
';


ALTER FUNCTION selemti.fn_postcorte_after_insert() OWNER TO postgres;

--
-- TOC entry 6122 (class 0 OID 0)
-- Dependencies: 754
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 755 (class 1255 OID 151567)
-- Name: fn_precorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_precorte_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = ''EN_CORTE''
  WHERE id = NEW.sesion_id
    AND estatus = ''LISTO_PARA_CORTE'';
  RETURN NEW;
END;
';


ALTER FUNCTION selemti.fn_precorte_after_insert() OWNER TO postgres;

--
-- TOC entry 6123 (class 0 OID 0)
-- Dependencies: 755
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 756 (class 1255 OID 151568)
-- Name: fn_precorte_after_update_aprobado(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_precorte_after_update_aprobado() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
  v_postcorte_id BIGINT;
BEGIN
  IF NEW.estatus = ''APROBADO'' AND OLD.estatus != ''APROBADO'' THEN
    -- Generar postcorte automÃ¡ticamente
    SELECT selemti.fn_generar_postcorte(NEW.sesion_id) INTO v_postcorte_id;
  END IF;
  RETURN NEW;
END;
';


ALTER FUNCTION selemti.fn_precorte_after_update_aprobado() OWNER TO postgres;

--
-- TOC entry 6124 (class 0 OID 0)
-- Dependencies: 756
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 757 (class 1255 OID 151569)
-- Name: fn_precorte_efectivo_bi(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_precorte_efectivo_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
  NEW.subtotal := COALESCE(NEW.denominacion,0) * COALESCE(NEW.cantidad,0);
  RETURN NEW;
END ';


ALTER FUNCTION selemti.fn_precorte_efectivo_bi() OWNER TO floreant;

--
-- TOC entry 767 (class 1255 OID 151570)
-- Name: fn_recipe_cost_at(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_recipe_cost_at(p_recipe_id bigint, p_at timestamp without time zone) RETURNS TABLE(batch_cost numeric, portion_cost numeric, batch_size numeric, yield_portions numeric)
    LANGUAGE plpgsql
    AS '
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
END';


ALTER FUNCTION selemti.fn_recipe_cost_at(p_recipe_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 760 (class 1255 OID 151571)
-- Name: fn_recipes_using_item(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_recipes_using_item(p_item_id bigint, p_at timestamp without time zone) RETURNS TABLE(recipe_id bigint)
    LANGUAGE plpgsql
    AS '
BEGIN
  RETURN QUERY
    SELECT DISTINCT rv.recipe_id
    FROM selemti.recipe_versions rv
    JOIN selemti.recipe_version_items rvi ON rvi.recipe_version_id = rv.id
    WHERE rvi.item_id = p_item_id
      AND rv.valid_from <= p_at
      AND (rv.valid_to IS NULL OR rv.valid_to > p_at);
END';


ALTER FUNCTION selemti.fn_recipes_using_item(p_item_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 750 (class 1255 OID 151572)
-- Name: fn_reparar_sesion_apertura(integer, integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_reparar_sesion_apertura(p_terminal_id integer, p_usuario integer) RETURNS text
    LANGUAGE plpgsql
    AS '
DECLARE v_term RECORD;
BEGIN
  IF EXISTS (
    SELECT 1 FROM selemti.sesion_cajon
    WHERE terminal_id=p_terminal_id AND cajero_usuario_id=p_usuario AND cierre_ts IS NULL
  ) THEN
    RETURN ''YA_EXISTE_SESION_ABIERTA'';
  END IF;

  SELECT * INTO v_term FROM public.terminal WHERE id=p_terminal_id;
  IF v_term IS NULL THEN RETURN ''TERMINAL_NO_ENCONTRADA''; END IF;

  INSERT INTO selemti.sesion_cajon(
    terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
    apertura_ts, estatus, opening_float
  ) VALUES (
    p_terminal_id, COALESCE(v_term.name,''Terminal ''||p_terminal_id), COALESCE(v_term.location,''''),
    p_usuario, now(), ''ACTIVA'', COALESCE(v_term.current_balance,0)
  );
  RETURN ''CREADA'';
END ';


ALTER FUNCTION selemti.fn_reparar_sesion_apertura(p_terminal_id integer, p_usuario integer) OWNER TO floreant;

--
-- TOC entry 780 (class 1255 OID 151573)
-- Name: fn_reversar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_reversar_consumo_ticket(_ticket_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS '
DECLARE
    v_sucursal bigint;
    v_almacen bigint;
    v_has_mov boolean := coalesce(to_regclass(''selemti.mov_inv'') IS NOT NULL, false);
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
        ''AJUSTE'',
        SUM(d.cantidad),
        COALESCE(d.uom, ''UN''),
        v_sucursal::text,
        NULL,
        v_almacen::text,
        ''POS_TICKET_REV'',
        _ticket_id,
        NULL,
        now(),
        jsonb_build_object(''ticket_id'', _ticket_id),
        NULL,
        now(),
        now()
    FROM selemti.inv_consumo_pos_det d
    JOIN selemti.inv_consumo_pos c ON c.id = d.consumo_id
    WHERE c.ticket_id = _ticket_id AND c.estado = ''CONFIRMADO''
    GROUP BY d.item_id, d.uom;

    UPDATE selemti.inv_consumo_pos
    SET estado = ''ANULADO'', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = ''CONFIRMADO'';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, ''REVERSE'', NULL);
END;
';


ALTER FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 761 (class 1255 OID 151574)
-- Name: fn_slug(text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_slug(in_text text) RETURNS text
    LANGUAGE plpgsql
    AS '
DECLARE s TEXT := lower(coalesce(in_text,''''));
BEGIN
  s := translate(s, ''ÁÉÍÓÚÜÑáéíóúüñ'', ''AEIOUUNaeiouun'');
  s := regexp_replace(s, ''[^a-z0-9]+'', ''-'', ''g'');
  s := regexp_replace(s, ''(^-|-$)'', '''', ''g'');
  IF s = '''' THEN RETURN NULL; END IF;
  RETURN s;
END ';


ALTER FUNCTION selemti.fn_slug(in_text text) OWNER TO floreant;

--
-- TOC entry 762 (class 1255 OID 151575)
-- Name: fn_terminal_bu_snapshot_cierre(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_terminal_bu_snapshot_cierre() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
  v_has_old boolean := (OLD.assigned_user IS NOT NULL);
  v_has_new boolean := (NEW.assigned_user IS NOT NULL);
BEGIN
  /* CIERRE: había cajero y ahora ya no */
  IF (v_has_old AND NOT v_has_new) THEN
    UPDATE selemti.sesion_cajon AS sc
       SET cierre_ts      = now(),
           estatus        = ''LISTO_PARA_CORTE'',
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
      COALESCE(NEW.name, ''Terminal ''||NEW.id),
      COALESCE(NEW.location, ''''),
      NEW.assigned_user,
      now(),
      ''ACTIVA'',
      COALESCE(NEW.current_balance, 0),
      NULL,
      FALSE  -- por defecto, en apertura no está saltado
    );
  END IF;

  RETURN NEW;
END ';


ALTER FUNCTION selemti.fn_terminal_bu_snapshot_cierre() OWNER TO floreant;

--
-- TOC entry 763 (class 1255 OID 151576)
-- Name: fn_tx_after_insert_forma_pago(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_tx_after_insert_forma_pago() RETURNS trigger
    LANGUAGE plpgsql
    AS '
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
END ';


ALTER FUNCTION selemti.fn_tx_after_insert_forma_pago() OWNER TO floreant;

--
-- TOC entry 766 (class 1255 OID 151577)
-- Name: fn_uom_factor(text, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_uom_factor(from_uom text, to_uom text) RETURNS numeric
    LANGUAGE plpgsql
    AS '
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
    RAISE EXCEPTION ''No hay conversión de % -> %'', from_uom, to_uom;
  END IF;
  RETURN v;
END';


ALTER FUNCTION selemti.fn_uom_factor(from_uom text, to_uom text) OWNER TO postgres;

--
-- TOC entry 769 (class 1255 OID 151578)
-- Name: inferir_recetas_de_ventas(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date) RETURNS integer
    LANGUAGE plpgsql
    AS '
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
        VALUES (v_plato_record.item_id, ''Inferida_'' || v_plato_record.item_id, v_plato_record.total_ventas, p_fecha_desde, p_fecha_hasta);
v_recetas_inferidas := v_recetas_inferidas + 1;
END LOOP;
RETURN v_recetas_inferidas;
END;
';


ALTER FUNCTION selemti.inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date) OWNER TO postgres;

--
-- TOC entry 770 (class 1255 OID 151579)
-- Name: ingesta_ticket(bigint, integer, integer, bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS '
BEGIN
  PERFORM 1;
  RETURN;
END;
';


ALTER FUNCTION selemti.ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) OWNER TO postgres;

--
-- TOC entry 771 (class 1255 OID 151580)
-- Name: recalcular_costos_periodo(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION recalcular_costos_periodo(p_desde date, p_hasta date DEFAULT ('now'::text)::date) RETURNS integer
    LANGUAGE plpgsql
    AS '
DECLARE v_cnt INT := 0; BEGIN
  WITH sub AS (
    SELECT
      COALESCE( (row_to_json(mi)->>''insumo_id'')::bigint,
                (row_to_json(mi)->>''item_id'')::bigint ) AS k_item,
      (row_to_json(mi)->>''costo_unit'')::numeric AS costo_unit,
      COALESCE((row_to_json(mi)->>''qty'')::numeric,
               (row_to_json(mi)->>''cantidad'')::numeric) AS q,
      (row_to_json(mi)->>''tipo'')::text AS tipo,
      mi.ts::date AS d
    FROM selemti.mov_inv mi
    WHERE mi.ts::date BETWEEN p_desde AND p_hasta
  )
  INSERT INTO selemti.hist_cost_insumo (insumo_id, fecha_efectiva, costo_wac, algoritmo_principal)
  SELECT s.k_item, p_desde,
         CASE WHEN SUM(CASE WHEN s.tipo IN (''RECEPCION'',''COMPRA'',''TRASPASO_IN'',''ENTRADA'') THEN (s.costo_unit * s.q) ELSE 0 END) <> 0
              THEN SUM(CASE WHEN s.tipo IN (''RECEPCION'',''COMPRA'',''TRASPASO_IN'',''ENTRADA'') THEN (s.costo_unit * s.q) ELSE 0 END)
                   / NULLIF(SUM(CASE WHEN s.tipo IN (''RECEPCION'',''COMPRA'',''TRASPASO_IN'',''ENTRADA'') THEN s.q ELSE 0 END),0)
              ELSE NULL END,
         ''WAC''
  FROM sub s
  WHERE s.k_item IS NOT NULL
  GROUP BY s.k_item
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS v_cnt = ROW_COUNT; RETURN v_cnt; END; ';


ALTER FUNCTION selemti.recalcular_costos_periodo(p_desde date, p_hasta date) OWNER TO postgres;

--
-- TOC entry 772 (class 1255 OID 151581)
-- Name: refresh_materialized_views(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION refresh_materialized_views() RETURNS void
    LANGUAGE plpgsql
    AS '
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_inventario_actual;
    REFRESH MATERIALIZED VIEW CONCURRENTLY selemti.mv_recetas_costos;
    RAISE NOTICE ''Vistas materializadas actualizadas exitosamente'';
END;
';


ALTER FUNCTION selemti.refresh_materialized_views() OWNER TO postgres;

--
-- TOC entry 773 (class 1255 OID 151582)
-- Name: registrar_consumo_porcionado(bigint, bigint, text, numeric, json); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) RETURNS integer
    LANGUAGE plpgsql
    AS '
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
      (r->>''qty_ml'')::NUMERIC,
      ''PORCION'', p_ticket_det_id
    );
v_count := v_count + 1;
END LOOP;
RETURN v_count;

END
';


ALTER FUNCTION selemti.registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) OWNER TO postgres;

--
-- TOC entry 774 (class 1255 OID 151583)
-- Name: reprocesar_costos_historicos(date, date, character varying, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date, p_algoritmo character varying DEFAULT 'WAC'::character varying, p_usuario_id integer DEFAULT 1) RETURNS integer
    LANGUAGE plpgsql
    AS '
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
        AND mv.tipo IN (''COMPRA'',''RECEPCION'',''ENTRADA'')
    )
    WHERE item_id = v_item_record.item_id
      AND fecha_efectiva BETWEEN p_fecha_desde AND p_fecha_hasta;

    v_total_actualizados := v_total_actualizados + 1;
  END LOOP;

  RETURN v_total_actualizados;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING ''reprocesar_costos_historicos fallo: %'', SQLERRM;
  RETURN COALESCE(v_total_actualizados, 0);
END;
';


ALTER FUNCTION selemti.reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date, p_algoritmo character varying, p_usuario_id integer) OWNER TO postgres;

--
-- TOC entry 775 (class 1255 OID 151584)
-- Name: set_timestamp_ipp(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION set_timestamp_ipp() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
';


ALTER FUNCTION selemti.set_timestamp_ipp() OWNER TO postgres;

--
-- TOC entry 777 (class 1255 OID 151585)
-- Name: sp_snapshot_recipe_cost(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp without time zone) RETURNS void
    LANGUAGE plpgsql
    AS '
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
END';


ALTER FUNCTION selemti.sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 776 (class 1255 OID 151586)
-- Name: tg_invshot_autofill(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION tg_invshot_autofill() RETURNS trigger
    LANGUAGE plpgsql
    AS '
    BEGIN
      NEW.valor_teorico := COALESCE(NEW.teorico_qty,0) * COALESCE(NEW.teorico_cost,0);
      IF NEW.fisico_qty IS NOT NULL THEN
        NEW.variance_qty  := COALESCE(NEW.fisico_qty,0) - COALESCE(NEW.teorico_qty,0);
        NEW.variance_cost := COALESCE(NEW.variance_qty,0) * COALESCE(NEW.teorico_cost,0);
      END IF;
      NEW.updated_at := now();
      RETURN NEW;
    END
    ';


ALTER FUNCTION selemti.tg_invshot_autofill() OWNER TO postgres;

--
-- TOC entry 768 (class 1255 OID 151587)
-- Name: trg_ticket_inventory_consumption(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION trg_ticket_inventory_consumption() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    IF NEW.paid = true AND NEW.voided = false THEN
        PERFORM selemti.fn_expandir_consumo_ticket(NEW.id);
        PERFORM selemti.fn_confirmar_consumo_ticket(NEW.id);
    ELSIF NEW.voided = true THEN
        PERFORM selemti.fn_reversar_consumo_ticket(NEW.id);
    END IF;

    RETURN NEW;
END;
';


ALTER FUNCTION selemti.trg_ticket_inventory_consumption() OWNER TO postgres;

--
-- TOC entry 764 (class 1255 OID 151588)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS '
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
';


ALTER FUNCTION selemti.update_updated_at_column() OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 615 (class 1259 OID 157930)
-- Name: action_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE action_history (
    id integer NOT NULL,
    action_time timestamp without time zone,
    action_name character varying(255),
    description character varying(255),
    user_id integer
);


ALTER TABLE action_history OWNER TO postgres;

--
-- TOC entry 614 (class 1259 OID 157928)
-- Name: action_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE action_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE action_history_id_seq OWNER TO postgres;

--
-- TOC entry 6125 (class 0 OID 0)
-- Dependencies: 614
-- Name: action_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE action_history_id_seq OWNED BY action_history.id;


--
-- TOC entry 629 (class 1259 OID 158125)
-- Name: attendence_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE attendence_history (
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


ALTER TABLE attendence_history OWNER TO postgres;

--
-- TOC entry 613 (class 1259 OID 157926)
-- Name: attendence_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE attendence_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE attendence_history_id_seq OWNER TO postgres;

--
-- TOC entry 6126 (class 0 OID 0)
-- Dependencies: 613
-- Name: attendence_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE attendence_history_id_seq OWNED BY attendence_history.id;


--
-- TOC entry 627 (class 1259 OID 158093)
-- Name: cash_drawer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cash_drawer (
    id integer NOT NULL,
    terminal_id integer
);


ALTER TABLE cash_drawer OWNER TO postgres;

--
-- TOC entry 612 (class 1259 OID 157924)
-- Name: cash_drawer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cash_drawer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_drawer_id_seq OWNER TO postgres;

--
-- TOC entry 6127 (class 0 OID 0)
-- Dependencies: 612
-- Name: cash_drawer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cash_drawer_id_seq OWNED BY cash_drawer.id;


--
-- TOC entry 611 (class 1259 OID 157913)
-- Name: cash_drawer_reset_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cash_drawer_reset_history (
    id integer NOT NULL,
    reset_time timestamp without time zone,
    user_id integer
);


ALTER TABLE cash_drawer_reset_history OWNER TO postgres;

--
-- TOC entry 610 (class 1259 OID 157911)
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cash_drawer_reset_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_drawer_reset_history_id_seq OWNER TO postgres;

--
-- TOC entry 6128 (class 0 OID 0)
-- Dependencies: 610
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cash_drawer_reset_history_id_seq OWNED BY cash_drawer_reset_history.id;


--
-- TOC entry 609 (class 1259 OID 157905)
-- Name: cooking_instruction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cooking_instruction (
    id integer NOT NULL,
    description character varying(60)
);


ALTER TABLE cooking_instruction OWNER TO postgres;

--
-- TOC entry 608 (class 1259 OID 157903)
-- Name: cooking_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cooking_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cooking_instruction_id_seq OWNER TO postgres;

--
-- TOC entry 6129 (class 0 OID 0)
-- Dependencies: 608
-- Name: cooking_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cooking_instruction_id_seq OWNED BY cooking_instruction.id;


--
-- TOC entry 605 (class 1259 OID 157869)
-- Name: coupon_and_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE coupon_and_discount (
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


ALTER TABLE coupon_and_discount OWNER TO postgres;

--
-- TOC entry 604 (class 1259 OID 157867)
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE coupon_and_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE coupon_and_discount_id_seq OWNER TO postgres;

--
-- TOC entry 6130 (class 0 OID 0)
-- Dependencies: 604
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE coupon_and_discount_id_seq OWNED BY coupon_and_discount.id;


--
-- TOC entry 602 (class 1259 OID 157859)
-- Name: currency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE currency (
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


ALTER TABLE currency OWNER TO postgres;

--
-- TOC entry 628 (class 1259 OID 158104)
-- Name: currency_balance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE currency_balance (
    id integer NOT NULL,
    balance double precision,
    currency_id integer,
    cash_drawer_id integer,
    dpr_id integer
);


ALTER TABLE currency_balance OWNER TO postgres;

--
-- TOC entry 603 (class 1259 OID 157865)
-- Name: currency_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE currency_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE currency_balance_id_seq OWNER TO postgres;

--
-- TOC entry 6131 (class 0 OID 0)
-- Dependencies: 603
-- Name: currency_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE currency_balance_id_seq OWNED BY currency_balance.id;


--
-- TOC entry 601 (class 1259 OID 157857)
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE currency_id_seq OWNER TO postgres;

--
-- TOC entry 6132 (class 0 OID 0)
-- Dependencies: 601
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE currency_id_seq OWNED BY currency.id;


--
-- TOC entry 600 (class 1259 OID 157851)
-- Name: custom_payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE custom_payment (
    id integer NOT NULL,
    name character varying(60),
    required_ref_number boolean,
    ref_number_field_name character varying(60)
);


ALTER TABLE custom_payment OWNER TO postgres;

--
-- TOC entry 599 (class 1259 OID 157849)
-- Name: custom_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE custom_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE custom_payment_id_seq OWNER TO postgres;

--
-- TOC entry 6133 (class 0 OID 0)
-- Dependencies: 599
-- Name: custom_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE custom_payment_id_seq OWNED BY custom_payment.id;


--
-- TOC entry 593 (class 1259 OID 157776)
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE customer (
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


ALTER TABLE customer OWNER TO postgres;

--
-- TOC entry 592 (class 1259 OID 157774)
-- Name: customer_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE customer_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customer_auto_id_seq OWNER TO postgres;

--
-- TOC entry 6134 (class 0 OID 0)
-- Dependencies: 592
-- Name: customer_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE customer_auto_id_seq OWNED BY customer.auto_id;


--
-- TOC entry 598 (class 1259 OID 157836)
-- Name: customer_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE customer_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE customer_properties OWNER TO postgres;

--
-- TOC entry 648 (class 1259 OID 158373)
-- Name: daily_folio_counter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE daily_folio_counter (
    folio_date date NOT NULL,
    branch_key text NOT NULL,
    last_value integer DEFAULT 0 NOT NULL
);


ALTER TABLE daily_folio_counter OWNER TO postgres;

--
-- TOC entry 591 (class 1259 OID 157768)
-- Name: data_update_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE data_update_info (
    id integer NOT NULL,
    last_update_time timestamp without time zone
);


ALTER TABLE data_update_info OWNER TO postgres;

--
-- TOC entry 590 (class 1259 OID 157766)
-- Name: data_update_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE data_update_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_update_info_id_seq OWNER TO postgres;

--
-- TOC entry 6135 (class 0 OID 0)
-- Dependencies: 590
-- Name: data_update_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE data_update_info_id_seq OWNED BY data_update_info.id;


--
-- TOC entry 597 (class 1259 OID 157825)
-- Name: delivery_address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE delivery_address (
    id integer NOT NULL,
    address character varying(320),
    phone_extension character varying(10),
    room_no character varying(30),
    distance double precision,
    customer_id integer
);


ALTER TABLE delivery_address OWNER TO postgres;

--
-- TOC entry 589 (class 1259 OID 157764)
-- Name: delivery_address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE delivery_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_address_id_seq OWNER TO postgres;

--
-- TOC entry 6136 (class 0 OID 0)
-- Dependencies: 589
-- Name: delivery_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE delivery_address_id_seq OWNED BY delivery_address.id;


--
-- TOC entry 588 (class 1259 OID 157758)
-- Name: delivery_charge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE delivery_charge (
    id integer NOT NULL,
    name character varying(220),
    zip_code character varying(20),
    start_range double precision,
    end_range double precision,
    charge_amount double precision
);


ALTER TABLE delivery_charge OWNER TO postgres;

--
-- TOC entry 587 (class 1259 OID 157756)
-- Name: delivery_charge_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE delivery_charge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_charge_id_seq OWNER TO postgres;

--
-- TOC entry 6137 (class 0 OID 0)
-- Dependencies: 587
-- Name: delivery_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE delivery_charge_id_seq OWNED BY delivery_charge.id;


--
-- TOC entry 586 (class 1259 OID 157750)
-- Name: delivery_configuration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE delivery_configuration (
    id integer NOT NULL,
    unit_name character varying(20),
    unit_symbol character varying(8),
    charge_by_zip_code boolean
);


ALTER TABLE delivery_configuration OWNER TO postgres;

--
-- TOC entry 585 (class 1259 OID 157748)
-- Name: delivery_configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE delivery_configuration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_configuration_id_seq OWNER TO postgres;

--
-- TOC entry 6138 (class 0 OID 0)
-- Dependencies: 585
-- Name: delivery_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE delivery_configuration_id_seq OWNED BY delivery_configuration.id;


--
-- TOC entry 596 (class 1259 OID 157814)
-- Name: delivery_instruction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE delivery_instruction (
    id integer NOT NULL,
    notes character varying(220),
    customer_no integer
);


ALTER TABLE delivery_instruction OWNER TO postgres;

--
-- TOC entry 584 (class 1259 OID 157746)
-- Name: delivery_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE delivery_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_instruction_id_seq OWNER TO postgres;

--
-- TOC entry 6139 (class 0 OID 0)
-- Dependencies: 584
-- Name: delivery_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE delivery_instruction_id_seq OWNED BY delivery_instruction.id;


--
-- TOC entry 619 (class 1259 OID 157983)
-- Name: drawer_assigned_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE drawer_assigned_history (
    id integer NOT NULL,
    "time" timestamp without time zone,
    operation character varying(60),
    a_user integer
);


ALTER TABLE drawer_assigned_history OWNER TO postgres;

--
-- TOC entry 583 (class 1259 OID 157744)
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE drawer_assigned_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE drawer_assigned_history_id_seq OWNER TO postgres;

--
-- TOC entry 6140 (class 0 OID 0)
-- Dependencies: 583
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE drawer_assigned_history_id_seq OWNED BY drawer_assigned_history.id;


--
-- TOC entry 624 (class 1259 OID 158061)
-- Name: drawer_pull_report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE drawer_pull_report (
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


ALTER TABLE drawer_pull_report OWNER TO postgres;

--
-- TOC entry 582 (class 1259 OID 157742)
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE drawer_pull_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE drawer_pull_report_id_seq OWNER TO postgres;

--
-- TOC entry 6141 (class 0 OID 0)
-- Dependencies: 582
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE drawer_pull_report_id_seq OWNED BY drawer_pull_report.id;


--
-- TOC entry 626 (class 1259 OID 158082)
-- Name: drawer_pull_report_voidtickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE drawer_pull_report_voidtickets (
    dpreport_id integer NOT NULL,
    code integer,
    reason character varying(255),
    hast character varying(255),
    quantity integer,
    amount double precision
);


ALTER TABLE drawer_pull_report_voidtickets OWNER TO postgres;

--
-- TOC entry 623 (class 1259 OID 158040)
-- Name: employee_in_out_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE employee_in_out_history (
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


ALTER TABLE employee_in_out_history OWNER TO postgres;

--
-- TOC entry 581 (class 1259 OID 157740)
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_in_out_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE employee_in_out_history_id_seq OWNER TO postgres;

--
-- TOC entry 6142 (class 0 OID 0)
-- Dependencies: 581
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_in_out_history_id_seq OWNED BY employee_in_out_history.id;


--
-- TOC entry 580 (class 1259 OID 157732)
-- Name: global_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE global_config (
    id integer NOT NULL,
    pos_key character varying(60),
    pos_value character varying(220)
);


ALTER TABLE global_config OWNER TO postgres;

--
-- TOC entry 579 (class 1259 OID 157730)
-- Name: global_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE global_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE global_config_id_seq OWNER TO postgres;

--
-- TOC entry 6143 (class 0 OID 0)
-- Dependencies: 579
-- Name: global_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE global_config_id_seq OWNED BY global_config.id;


--
-- TOC entry 622 (class 1259 OID 158024)
-- Name: gratuity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE gratuity (
    id integer NOT NULL,
    amount double precision,
    paid boolean,
    refunded boolean,
    ticket_id integer,
    owner_id integer,
    terminal_id integer
);


ALTER TABLE gratuity OWNER TO postgres;

--
-- TOC entry 578 (class 1259 OID 157728)
-- Name: gratuity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gratuity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE gratuity_id_seq OWNER TO postgres;

--
-- TOC entry 6144 (class 0 OID 0)
-- Dependencies: 578
-- Name: gratuity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gratuity_id_seq OWNED BY gratuity.id;


--
-- TOC entry 639 (class 1259 OID 158289)
-- Name: group_taxes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE group_taxes (
    group_id character varying(128) NOT NULL,
    elt integer NOT NULL
);


ALTER TABLE group_taxes OWNER TO postgres;

--
-- TOC entry 577 (class 1259 OID 157717)
-- Name: guest_check_print; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE guest_check_print (
    id integer NOT NULL,
    ticket_id integer,
    table_no character varying(255),
    ticket_total double precision,
    print_time timestamp without time zone,
    user_id integer
);


ALTER TABLE guest_check_print OWNER TO postgres;

--
-- TOC entry 576 (class 1259 OID 157715)
-- Name: guest_check_print_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE guest_check_print_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE guest_check_print_id_seq OWNER TO postgres;

--
-- TOC entry 6145 (class 0 OID 0)
-- Dependencies: 576
-- Name: guest_check_print_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE guest_check_print_id_seq OWNED BY guest_check_print.id;


--
-- TOC entry 572 (class 1259 OID 157631)
-- Name: inventory_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_group OWNER TO postgres;

--
-- TOC entry 571 (class 1259 OID 157629)
-- Name: inventory_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_group_id_seq OWNER TO postgres;

--
-- TOC entry 6146 (class 0 OID 0)
-- Dependencies: 571
-- Name: inventory_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_group_id_seq OWNED BY inventory_group.id;


--
-- TOC entry 573 (class 1259 OID 157637)
-- Name: inventory_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_item (
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


ALTER TABLE inventory_item OWNER TO postgres;

--
-- TOC entry 570 (class 1259 OID 157627)
-- Name: inventory_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_item_id_seq OWNER TO postgres;

--
-- TOC entry 6147 (class 0 OID 0)
-- Dependencies: 570
-- Name: inventory_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_item_id_seq OWNED BY inventory_item.id;


--
-- TOC entry 569 (class 1259 OID 157616)
-- Name: inventory_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_location (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    sort_order integer,
    visible boolean,
    warehouse_id integer
);


ALTER TABLE inventory_location OWNER TO postgres;

--
-- TOC entry 568 (class 1259 OID 157614)
-- Name: inventory_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_location_id_seq OWNER TO postgres;

--
-- TOC entry 6148 (class 0 OID 0)
-- Dependencies: 568
-- Name: inventory_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_location_id_seq OWNED BY inventory_location.id;


--
-- TOC entry 567 (class 1259 OID 157605)
-- Name: inventory_meta_code; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_meta_code (
    id integer NOT NULL,
    type character varying(255),
    code_text character varying(255),
    code_no integer,
    description character varying(255)
);


ALTER TABLE inventory_meta_code OWNER TO postgres;

--
-- TOC entry 566 (class 1259 OID 157603)
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_meta_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_meta_code_id_seq OWNER TO postgres;

--
-- TOC entry 6149 (class 0 OID 0)
-- Dependencies: 566
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_meta_code_id_seq OWNED BY inventory_meta_code.id;


--
-- TOC entry 575 (class 1259 OID 157684)
-- Name: inventory_transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_transaction (
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


ALTER TABLE inventory_transaction OWNER TO postgres;

--
-- TOC entry 565 (class 1259 OID 157601)
-- Name: inventory_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_transaction_id_seq OWNER TO postgres;

--
-- TOC entry 6150 (class 0 OID 0)
-- Dependencies: 565
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_transaction_id_seq OWNED BY inventory_transaction.id;


--
-- TOC entry 564 (class 1259 OID 157592)
-- Name: inventory_unit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_unit (
    id integer NOT NULL,
    short_name character varying(255),
    long_name character varying(255),
    alt_name character varying(255),
    conv_factor1 character varying(255),
    conv_factor2 character varying(255),
    conv_factor3 character varying(255)
);


ALTER TABLE inventory_unit OWNER TO postgres;

--
-- TOC entry 563 (class 1259 OID 157590)
-- Name: inventory_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_unit_id_seq OWNER TO postgres;

--
-- TOC entry 6151 (class 0 OID 0)
-- Dependencies: 563
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_unit_id_seq OWNED BY inventory_unit.id;


--
-- TOC entry 562 (class 1259 OID 157581)
-- Name: inventory_vendor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_vendor (
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


ALTER TABLE inventory_vendor OWNER TO postgres;

--
-- TOC entry 561 (class 1259 OID 157579)
-- Name: inventory_vendor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_vendor_id_seq OWNER TO postgres;

--
-- TOC entry 6152 (class 0 OID 0)
-- Dependencies: 561
-- Name: inventory_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_vendor_id_seq OWNED BY inventory_vendor.id;


--
-- TOC entry 560 (class 1259 OID 157573)
-- Name: inventory_warehouse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE inventory_warehouse (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_warehouse OWNER TO postgres;

--
-- TOC entry 559 (class 1259 OID 157571)
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inventory_warehouse_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_warehouse_id_seq OWNER TO postgres;

--
-- TOC entry 6153 (class 0 OID 0)
-- Dependencies: 559
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE inventory_warehouse_id_seq OWNED BY inventory_warehouse.id;


--
-- TOC entry 638 (class 1259 OID 158276)
-- Name: item_order_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE item_order_type (
    menu_item_id integer NOT NULL,
    order_type_id integer NOT NULL
);


ALTER TABLE item_order_type OWNER TO postgres;

--
-- TOC entry 557 (class 1259 OID 157552)
-- Name: kitchen_ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE kitchen_ticket (
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


ALTER TABLE kitchen_ticket OWNER TO postgres;

--
-- TOC entry 618 (class 1259 OID 157964)
-- Name: terminal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE terminal (
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


ALTER TABLE terminal OWNER TO postgres;

--
-- TOC entry 649 (class 1259 OID 158382)
-- Name: ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket (
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


ALTER TABLE ticket OWNER TO postgres;

--
-- TOC entry 658 (class 1259 OID 158535)
-- Name: kds_orders_enhanced; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW kds_orders_enhanced AS
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
   FROM ((kitchen_ticket kt
     JOIN ticket t ON ((t.id = kt.ticket_id)))
     LEFT JOIN terminal term ON ((t.terminal_id = term.id)));


ALTER TABLE kds_orders_enhanced OWNER TO postgres;

--
-- TOC entry 647 (class 1259 OID 158367)
-- Name: kds_ready_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE kds_ready_log (
    ticket_id integer NOT NULL,
    notified_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE kds_ready_log OWNER TO postgres;

--
-- TOC entry 558 (class 1259 OID 157563)
-- Name: kit_ticket_table_num; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE kit_ticket_table_num (
    kit_ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE kit_ticket_table_num OWNER TO postgres;

--
-- TOC entry 556 (class 1259 OID 157550)
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE kitchen_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE kitchen_ticket_id_seq OWNER TO postgres;

--
-- TOC entry 6154 (class 0 OID 0)
-- Dependencies: 556
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE kitchen_ticket_id_seq OWNED BY kitchen_ticket.id;


--
-- TOC entry 655 (class 1259 OID 158511)
-- Name: kitchen_ticket_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE kitchen_ticket_item (
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


ALTER TABLE kitchen_ticket_item OWNER TO postgres;

--
-- TOC entry 555 (class 1259 OID 157548)
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE kitchen_ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE kitchen_ticket_item_id_seq OWNER TO postgres;

--
-- TOC entry 6155 (class 0 OID 0)
-- Dependencies: 555
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE kitchen_ticket_item_id_seq OWNED BY kitchen_ticket_item.id;


--
-- TOC entry 553 (class 1259 OID 157531)
-- Name: menu_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_category (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    translated_name character varying(120),
    visible boolean,
    beverage boolean,
    sort_order integer,
    btn_color integer,
    text_color integer
);


ALTER TABLE menu_category OWNER TO postgres;

--
-- TOC entry 552 (class 1259 OID 157529)
-- Name: menu_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_category_id_seq OWNER TO postgres;

--
-- TOC entry 6156 (class 0 OID 0)
-- Dependencies: 552
-- Name: menu_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_category_id_seq OWNED BY menu_category.id;


--
-- TOC entry 554 (class 1259 OID 157537)
-- Name: menu_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_group (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    translated_name character varying(120),
    visible boolean,
    sort_order integer,
    btn_color integer,
    text_color integer,
    category_id integer
);


ALTER TABLE menu_group OWNER TO postgres;

--
-- TOC entry 551 (class 1259 OID 157527)
-- Name: menu_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_group_id_seq OWNER TO postgres;

--
-- TOC entry 6157 (class 0 OID 0)
-- Dependencies: 551
-- Name: menu_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_group_id_seq OWNED BY menu_group.id;


--
-- TOC entry 631 (class 1259 OID 158151)
-- Name: menu_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_item (
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


ALTER TABLE menu_item OWNER TO postgres;

--
-- TOC entry 550 (class 1259 OID 157525)
-- Name: menu_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_item_id_seq OWNER TO postgres;

--
-- TOC entry 6158 (class 0 OID 0)
-- Dependencies: 550
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_item_id_seq OWNED BY menu_item.id;


--
-- TOC entry 637 (class 1259 OID 158266)
-- Name: menu_item_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_item_properties (
    menu_item_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_item_properties OWNER TO postgres;

--
-- TOC entry 546 (class 1259 OID 157474)
-- Name: menu_item_size; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_item_size (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    description character varying(120),
    sort_order integer,
    size_in_inch double precision,
    default_size boolean
);


ALTER TABLE menu_item_size OWNER TO postgres;

--
-- TOC entry 545 (class 1259 OID 157472)
-- Name: menu_item_size_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_item_size_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_item_size_id_seq OWNER TO postgres;

--
-- TOC entry 6159 (class 0 OID 0)
-- Dependencies: 545
-- Name: menu_item_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_item_size_id_seq OWNED BY menu_item_size.id;


--
-- TOC entry 636 (class 1259 OID 158253)
-- Name: menu_item_terminal_ref; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_item_terminal_ref (
    menu_item_id integer NOT NULL,
    terminal_id integer NOT NULL
);


ALTER TABLE menu_item_terminal_ref OWNER TO postgres;

--
-- TOC entry 543 (class 1259 OID 157441)
-- Name: menu_modifier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_modifier (
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


ALTER TABLE menu_modifier OWNER TO postgres;

--
-- TOC entry 542 (class 1259 OID 157435)
-- Name: menu_modifier_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_modifier_group (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    enabled boolean,
    exclusived boolean,
    required boolean
);


ALTER TABLE menu_modifier_group OWNER TO postgres;

--
-- TOC entry 541 (class 1259 OID 157433)
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_modifier_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_modifier_group_id_seq OWNER TO postgres;

--
-- TOC entry 6160 (class 0 OID 0)
-- Dependencies: 541
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_modifier_group_id_seq OWNED BY menu_modifier_group.id;


--
-- TOC entry 540 (class 1259 OID 157431)
-- Name: menu_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_modifier_id_seq OWNER TO postgres;

--
-- TOC entry 6161 (class 0 OID 0)
-- Dependencies: 540
-- Name: menu_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_modifier_id_seq OWNED BY menu_modifier.id;


--
-- TOC entry 544 (class 1259 OID 157462)
-- Name: menu_modifier_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menu_modifier_properties (
    menu_modifier_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_modifier_properties OWNER TO postgres;

--
-- TOC entry 607 (class 1259 OID 157890)
-- Name: menucategory_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menucategory_discount (
    discount_id integer NOT NULL,
    menucategory_id integer NOT NULL
);


ALTER TABLE menucategory_discount OWNER TO postgres;

--
-- TOC entry 606 (class 1259 OID 157877)
-- Name: menugroup_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menugroup_discount (
    discount_id integer NOT NULL,
    menugroup_id integer NOT NULL
);


ALTER TABLE menugroup_discount OWNER TO postgres;

--
-- TOC entry 635 (class 1259 OID 158240)
-- Name: menuitem_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menuitem_discount (
    discount_id integer NOT NULL,
    menuitem_id integer NOT NULL
);


ALTER TABLE menuitem_discount OWNER TO postgres;

--
-- TOC entry 634 (class 1259 OID 158219)
-- Name: menuitem_modifiergroup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menuitem_modifiergroup (
    id integer NOT NULL,
    min_quantity integer,
    max_quantity integer,
    sort_order integer,
    modifier_group integer,
    menuitem_modifiergroup_id integer
);


ALTER TABLE menuitem_modifiergroup OWNER TO postgres;

--
-- TOC entry 539 (class 1259 OID 157429)
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menuitem_modifiergroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menuitem_modifiergroup_id_seq OWNER TO postgres;

--
-- TOC entry 6162 (class 0 OID 0)
-- Dependencies: 539
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menuitem_modifiergroup_id_seq OWNED BY menuitem_modifiergroup.id;


--
-- TOC entry 633 (class 1259 OID 158206)
-- Name: menuitem_pizzapirce; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menuitem_pizzapirce (
    menu_item_id integer NOT NULL,
    pizza_price_id integer NOT NULL
);


ALTER TABLE menuitem_pizzapirce OWNER TO postgres;

--
-- TOC entry 632 (class 1259 OID 158190)
-- Name: menuitem_shift; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menuitem_shift (
    id integer NOT NULL,
    shift_price double precision,
    shift_id integer,
    menuitem_id integer
);


ALTER TABLE menuitem_shift OWNER TO postgres;

--
-- TOC entry 538 (class 1259 OID 157427)
-- Name: menuitem_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menuitem_shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menuitem_shift_id_seq OWNER TO postgres;

--
-- TOC entry 6163 (class 0 OID 0)
-- Dependencies: 538
-- Name: menuitem_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menuitem_shift_id_seq OWNED BY menuitem_shift.id;


--
-- TOC entry 549 (class 1259 OID 157512)
-- Name: menumodifier_pizzamodifierprice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE menumodifier_pizzamodifierprice (
    menumodifier_id integer NOT NULL,
    pizzamodifierprice_id integer NOT NULL
);


ALTER TABLE menumodifier_pizzamodifierprice OWNER TO postgres;

--
-- TOC entry 646 (class 1259 OID 158346)
-- Name: modifier_multiplier_price; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE modifier_multiplier_price (
    id integer NOT NULL,
    price double precision,
    multiplier_id character varying(20),
    menumodifier_id integer,
    pizza_modifier_price_id integer
);


ALTER TABLE modifier_multiplier_price OWNER TO postgres;

--
-- TOC entry 537 (class 1259 OID 157425)
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE modifier_multiplier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modifier_multiplier_price_id_seq OWNER TO postgres;

--
-- TOC entry 6164 (class 0 OID 0)
-- Dependencies: 537
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE modifier_multiplier_price_id_seq OWNED BY modifier_multiplier_price.id;


--
-- TOC entry 645 (class 1259 OID 158341)
-- Name: multiplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE multiplier (
    name character varying(20) NOT NULL,
    ticket_prefix character varying(20),
    rate double precision,
    sort_order integer,
    default_multiplier boolean,
    main boolean,
    btn_color integer,
    text_color integer
);


ALTER TABLE multiplier OWNER TO postgres;

--
-- TOC entry 536 (class 1259 OID 157414)
-- Name: order_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE order_type (
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


ALTER TABLE order_type OWNER TO postgres;

--
-- TOC entry 535 (class 1259 OID 157412)
-- Name: order_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE order_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE order_type_id_seq OWNER TO postgres;

--
-- TOC entry 6165 (class 0 OID 0)
-- Dependencies: 535
-- Name: order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE order_type_id_seq OWNED BY order_type.id;


--
-- TOC entry 534 (class 1259 OID 157404)
-- Name: packaging_unit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE packaging_unit (
    id integer NOT NULL,
    name character varying(30),
    short_name character varying(10),
    factor double precision,
    baseunit boolean,
    dimension character varying(30)
);


ALTER TABLE packaging_unit OWNER TO postgres;

--
-- TOC entry 533 (class 1259 OID 157402)
-- Name: packaging_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE packaging_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE packaging_unit_id_seq OWNER TO postgres;

--
-- TOC entry 6166 (class 0 OID 0)
-- Dependencies: 533
-- Name: packaging_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE packaging_unit_id_seq OWNED BY packaging_unit.id;


--
-- TOC entry 532 (class 1259 OID 157396)
-- Name: payout_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE payout_reasons (
    id integer NOT NULL,
    reason character varying(255)
);


ALTER TABLE payout_reasons OWNER TO postgres;

--
-- TOC entry 531 (class 1259 OID 157394)
-- Name: payout_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE payout_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE payout_reasons_id_seq OWNER TO postgres;

--
-- TOC entry 6167 (class 0 OID 0)
-- Dependencies: 531
-- Name: payout_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE payout_reasons_id_seq OWNED BY payout_reasons.id;


--
-- TOC entry 530 (class 1259 OID 157388)
-- Name: payout_recepients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE payout_recepients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE payout_recepients OWNER TO postgres;

--
-- TOC entry 529 (class 1259 OID 157386)
-- Name: payout_recepients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE payout_recepients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE payout_recepients_id_seq OWNER TO postgres;

--
-- TOC entry 6168 (class 0 OID 0)
-- Dependencies: 529
-- Name: payout_recepients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE payout_recepients_id_seq OWNED BY payout_recepients.id;


--
-- TOC entry 528 (class 1259 OID 157380)
-- Name: pizza_crust; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pizza_crust (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    description character varying(120),
    sort_order integer,
    default_crust boolean
);


ALTER TABLE pizza_crust OWNER TO postgres;

--
-- TOC entry 527 (class 1259 OID 157378)
-- Name: pizza_crust_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pizza_crust_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_crust_id_seq OWNER TO postgres;

--
-- TOC entry 6169 (class 0 OID 0)
-- Dependencies: 527
-- Name: pizza_crust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pizza_crust_id_seq OWNED BY pizza_crust.id;


--
-- TOC entry 548 (class 1259 OID 157501)
-- Name: pizza_modifier_price; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pizza_modifier_price (
    id integer NOT NULL,
    item_size integer
);


ALTER TABLE pizza_modifier_price OWNER TO postgres;

--
-- TOC entry 526 (class 1259 OID 157376)
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pizza_modifier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_modifier_price_id_seq OWNER TO postgres;

--
-- TOC entry 6170 (class 0 OID 0)
-- Dependencies: 526
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pizza_modifier_price_id_seq OWNED BY pizza_modifier_price.id;


--
-- TOC entry 547 (class 1259 OID 157480)
-- Name: pizza_price; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pizza_price (
    id integer NOT NULL,
    price double precision,
    menu_item_size integer,
    crust integer,
    order_type integer
);


ALTER TABLE pizza_price OWNER TO postgres;

--
-- TOC entry 525 (class 1259 OID 157374)
-- Name: pizza_price_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pizza_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_price_id_seq OWNER TO postgres;

--
-- TOC entry 6171 (class 0 OID 0)
-- Dependencies: 525
-- Name: pizza_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pizza_price_id_seq OWNED BY pizza_price.id;


--
-- TOC entry 644 (class 1259 OID 158333)
-- Name: printer_configuration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE printer_configuration (
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


ALTER TABLE printer_configuration OWNER TO postgres;

--
-- TOC entry 523 (class 1259 OID 157358)
-- Name: printer_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE printer_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    is_default boolean
);


ALTER TABLE printer_group OWNER TO postgres;

--
-- TOC entry 522 (class 1259 OID 157356)
-- Name: printer_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE printer_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE printer_group_id_seq OWNER TO postgres;

--
-- TOC entry 6172 (class 0 OID 0)
-- Dependencies: 522
-- Name: printer_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE printer_group_id_seq OWNED BY printer_group.id;


--
-- TOC entry 524 (class 1259 OID 157366)
-- Name: printer_group_printers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE printer_group_printers (
    printer_id integer NOT NULL,
    printer_name character varying(255)
);


ALTER TABLE printer_group_printers OWNER TO postgres;

--
-- TOC entry 521 (class 1259 OID 157350)
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE purchase_order (
    id integer NOT NULL,
    order_id character varying(30),
    name character varying(30)
);


ALTER TABLE purchase_order OWNER TO postgres;

--
-- TOC entry 520 (class 1259 OID 157348)
-- Name: purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE purchase_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_order_id_seq OWNER TO postgres;

--
-- TOC entry 6173 (class 0 OID 0)
-- Dependencies: 520
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE purchase_order_id_seq OWNED BY purchase_order.id;


--
-- TOC entry 519 (class 1259 OID 157342)
-- Name: recepie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE recepie (
    id integer NOT NULL,
    menu_item integer
);


ALTER TABLE recepie OWNER TO postgres;

--
-- TOC entry 518 (class 1259 OID 157340)
-- Name: recepie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE recepie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepie_id_seq OWNER TO postgres;

--
-- TOC entry 6174 (class 0 OID 0)
-- Dependencies: 518
-- Name: recepie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE recepie_id_seq OWNED BY recepie.id;


--
-- TOC entry 574 (class 1259 OID 157668)
-- Name: recepie_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE recepie_item (
    id integer NOT NULL,
    percentage double precision,
    inventory_deductable boolean,
    inventory_item integer,
    recepie_id integer
);


ALTER TABLE recepie_item OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 157338)
-- Name: recepie_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE recepie_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepie_item_id_seq OWNER TO postgres;

--
-- TOC entry 6175 (class 0 OID 0)
-- Dependencies: 517
-- Name: recepie_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE recepie_item_id_seq OWNED BY recepie_item.id;


--
-- TOC entry 642 (class 1259 OID 158315)
-- Name: restaurant; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE restaurant (
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
    allow_modifier_max_exceed boolean
);


ALTER TABLE restaurant OWNER TO postgres;

--
-- TOC entry 643 (class 1259 OID 158320)
-- Name: restaurant_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE restaurant_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE restaurant_properties OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 157310)
-- Name: shift; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shift (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    shift_len bigint
);


ALTER TABLE shift OWNER TO postgres;

--
-- TOC entry 514 (class 1259 OID 157308)
-- Name: shift_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shift_id_seq OWNER TO postgres;

--
-- TOC entry 6176 (class 0 OID 0)
-- Dependencies: 514
-- Name: shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shift_id_seq OWNED BY shift.id;


--
-- TOC entry 509 (class 1259 OID 157258)
-- Name: shop_floor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_floor (
    id integer NOT NULL,
    name character varying(60),
    occupied boolean,
    image oid
);


ALTER TABLE shop_floor OWNER TO postgres;

--
-- TOC entry 508 (class 1259 OID 157256)
-- Name: shop_floor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shop_floor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_floor_id_seq OWNER TO postgres;

--
-- TOC entry 6177 (class 0 OID 0)
-- Dependencies: 508
-- Name: shop_floor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shop_floor_id_seq OWNED BY shop_floor.id;


--
-- TOC entry 512 (class 1259 OID 157287)
-- Name: shop_floor_template; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_floor_template (
    id integer NOT NULL,
    name character varying(60),
    default_floor boolean,
    main boolean,
    floor_id integer
);


ALTER TABLE shop_floor_template OWNER TO postgres;

--
-- TOC entry 507 (class 1259 OID 157254)
-- Name: shop_floor_template_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shop_floor_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_floor_template_id_seq OWNER TO postgres;

--
-- TOC entry 6178 (class 0 OID 0)
-- Dependencies: 507
-- Name: shop_floor_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shop_floor_template_id_seq OWNED BY shop_floor_template.id;


--
-- TOC entry 513 (class 1259 OID 157298)
-- Name: shop_floor_template_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_floor_template_properties (
    id integer NOT NULL,
    property_value character varying(60),
    property_name character varying(255) NOT NULL
);


ALTER TABLE shop_floor_template_properties OWNER TO postgres;

--
-- TOC entry 510 (class 1259 OID 157264)
-- Name: shop_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_table (
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


ALTER TABLE shop_table OWNER TO postgres;

--
-- TOC entry 640 (class 1259 OID 158302)
-- Name: shop_table_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_table_status (
    id integer NOT NULL,
    table_status integer
);


ALTER TABLE shop_table_status OWNER TO postgres;

--
-- TOC entry 506 (class 1259 OID 157248)
-- Name: shop_table_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE shop_table_type (
    id integer NOT NULL,
    description character varying(120),
    name character varying(40)
);


ALTER TABLE shop_table_type OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 157246)
-- Name: shop_table_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shop_table_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_table_type_id_seq OWNER TO postgres;

--
-- TOC entry 6179 (class 0 OID 0)
-- Dependencies: 505
-- Name: shop_table_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shop_table_type_id_seq OWNED BY shop_table_type.id;


--
-- TOC entry 594 (class 1259 OID 157785)
-- Name: table_booking_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE table_booking_info (
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


ALTER TABLE table_booking_info OWNER TO postgres;

--
-- TOC entry 504 (class 1259 OID 157244)
-- Name: table_booking_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE table_booking_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE table_booking_info_id_seq OWNER TO postgres;

--
-- TOC entry 6180 (class 0 OID 0)
-- Dependencies: 504
-- Name: table_booking_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE table_booking_info_id_seq OWNED BY table_booking_info.id;


--
-- TOC entry 595 (class 1259 OID 157801)
-- Name: table_booking_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE table_booking_mapping (
    booking_id integer NOT NULL,
    table_id integer NOT NULL
);


ALTER TABLE table_booking_mapping OWNER TO postgres;

--
-- TOC entry 641 (class 1259 OID 158307)
-- Name: table_ticket_num; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE table_ticket_num (
    shop_table_status_id integer NOT NULL,
    ticket_id integer,
    user_id integer,
    user_name character varying(30)
);


ALTER TABLE table_ticket_num OWNER TO postgres;

--
-- TOC entry 511 (class 1259 OID 157274)
-- Name: table_type_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE table_type_relation (
    table_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE table_type_relation OWNER TO postgres;

--
-- TOC entry 503 (class 1259 OID 157238)
-- Name: tax; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tax (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    rate double precision
);


ALTER TABLE tax OWNER TO postgres;

--
-- TOC entry 630 (class 1259 OID 158146)
-- Name: tax_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tax_group (
    id character varying(128) NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE tax_group OWNER TO postgres;

--
-- TOC entry 502 (class 1259 OID 157236)
-- Name: tax_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tax_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tax_id_seq OWNER TO postgres;

--
-- TOC entry 6181 (class 0 OID 0)
-- Dependencies: 502
-- Name: tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tax_id_seq OWNED BY tax.id;


--
-- TOC entry 621 (class 1259 OID 158008)
-- Name: terminal_printers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE terminal_printers (
    id integer NOT NULL,
    terminal_id integer,
    printer_name character varying(60),
    virtual_printer_id integer
);


ALTER TABLE terminal_printers OWNER TO postgres;

--
-- TOC entry 501 (class 1259 OID 157234)
-- Name: terminal_printers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE terminal_printers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE terminal_printers_id_seq OWNER TO postgres;

--
-- TOC entry 6182 (class 0 OID 0)
-- Dependencies: 501
-- Name: terminal_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE terminal_printers_id_seq OWNED BY terminal_printers.id;


--
-- TOC entry 620 (class 1259 OID 157995)
-- Name: terminal_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE terminal_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE terminal_properties OWNER TO postgres;

--
-- TOC entry 667 (class 1259 OID 158630)
-- Name: ticket_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_discount (
    id integer NOT NULL,
    discount_id integer,
    name character varying(30),
    type integer,
    auto_apply boolean,
    minimum_amount integer,
    value double precision,
    ticket_id integer
);


ALTER TABLE ticket_discount OWNER TO postgres;

--
-- TOC entry 500 (class 1259 OID 157232)
-- Name: ticket_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ticket_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_discount_id_seq OWNER TO postgres;

--
-- TOC entry 6183 (class 0 OID 0)
-- Dependencies: 500
-- Name: ticket_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ticket_discount_id_seq OWNED BY ticket_discount.id;


--
-- TOC entry 657 (class 1259 OID 158530)
-- Name: ticket_folio_complete; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW ticket_folio_complete AS
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
   FROM (ticket t
     LEFT JOIN terminal term ON ((t.terminal_id = term.id)));


ALTER TABLE ticket_folio_complete OWNER TO postgres;

--
-- TOC entry 499 (class 1259 OID 157230)
-- Name: ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_id_seq OWNER TO postgres;

--
-- TOC entry 6184 (class 0 OID 0)
-- Dependencies: 499
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ticket_id_seq OWNED BY ticket.id;


--
-- TOC entry 650 (class 1259 OID 158430)
-- Name: ticket_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item (
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


ALTER TABLE ticket_item OWNER TO postgres;

--
-- TOC entry 654 (class 1259 OID 158496)
-- Name: ticket_item_addon_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item_addon_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_addon_relation OWNER TO postgres;

--
-- TOC entry 653 (class 1259 OID 158486)
-- Name: ticket_item_cooking_instruction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item_cooking_instruction (
    ticket_item_id integer NOT NULL,
    description character varying(60),
    printedtokitchen boolean,
    item_order integer NOT NULL
);


ALTER TABLE ticket_item_cooking_instruction OWNER TO postgres;

--
-- TOC entry 652 (class 1259 OID 158475)
-- Name: ticket_item_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item_discount (
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


ALTER TABLE ticket_item_discount OWNER TO postgres;

--
-- TOC entry 498 (class 1259 OID 157228)
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ticket_item_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_discount_id_seq OWNER TO postgres;

--
-- TOC entry 6185 (class 0 OID 0)
-- Dependencies: 498
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ticket_item_discount_id_seq OWNED BY ticket_item_discount.id;


--
-- TOC entry 497 (class 1259 OID 157226)
-- Name: ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_id_seq OWNER TO postgres;

--
-- TOC entry 6186 (class 0 OID 0)
-- Dependencies: 497
-- Name: ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ticket_item_id_seq OWNED BY ticket_item.id;


--
-- TOC entry 496 (class 1259 OID 157220)
-- Name: ticket_item_modifier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item_modifier (
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


ALTER TABLE ticket_item_modifier OWNER TO postgres;

--
-- TOC entry 495 (class 1259 OID 157218)
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ticket_item_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_modifier_id_seq OWNER TO postgres;

--
-- TOC entry 6187 (class 0 OID 0)
-- Dependencies: 495
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ticket_item_modifier_id_seq OWNED BY ticket_item_modifier.id;


--
-- TOC entry 651 (class 1259 OID 158460)
-- Name: ticket_item_modifier_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_item_modifier_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_modifier_relation OWNER TO postgres;

--
-- TOC entry 666 (class 1259 OID 158617)
-- Name: ticket_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE ticket_properties OWNER TO postgres;

--
-- TOC entry 665 (class 1259 OID 158609)
-- Name: ticket_table_num; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ticket_table_num (
    ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE ticket_table_num OWNER TO postgres;

--
-- TOC entry 664 (class 1259 OID 158596)
-- Name: transaction_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE transaction_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE transaction_properties OWNER TO postgres;

--
-- TOC entry 659 (class 1259 OID 158540)
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE transactions (
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


ALTER TABLE transactions OWNER TO postgres;

--
-- TOC entry 494 (class 1259 OID 157216)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE transactions_id_seq OWNER TO postgres;

--
-- TOC entry 6188 (class 0 OID 0)
-- Dependencies: 494
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- TOC entry 616 (class 1259 OID 157944)
-- Name: user_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_permission (
    name character varying(40) NOT NULL
);


ALTER TABLE user_permission OWNER TO postgres;

--
-- TOC entry 493 (class 1259 OID 157210)
-- Name: user_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_type (
    id integer NOT NULL,
    p_name character varying(60)
);


ALTER TABLE user_type OWNER TO postgres;

--
-- TOC entry 492 (class 1259 OID 157208)
-- Name: user_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_type_id_seq OWNER TO postgres;

--
-- TOC entry 6189 (class 0 OID 0)
-- Dependencies: 492
-- Name: user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_type_id_seq OWNED BY user_type.id;


--
-- TOC entry 617 (class 1259 OID 157949)
-- Name: user_user_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_user_permission (
    permissionid integer NOT NULL,
    elt character varying(40) NOT NULL
);


ALTER TABLE user_user_permission OWNER TO postgres;

--
-- TOC entry 516 (class 1259 OID 157318)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE users (
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


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 491 (class 1259 OID 157206)
-- Name: users_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE users_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_auto_id_seq OWNER TO postgres;

--
-- TOC entry 6190 (class 0 OID 0)
-- Dependencies: 491
-- Name: users_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE users_auto_id_seq OWNED BY users.auto_id;


--
-- TOC entry 489 (class 1259 OID 157190)
-- Name: virtual_printer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE virtual_printer (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    type integer,
    priority integer,
    enabled boolean
);


ALTER TABLE virtual_printer OWNER TO postgres;

--
-- TOC entry 488 (class 1259 OID 157188)
-- Name: virtual_printer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE virtual_printer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE virtual_printer_id_seq OWNER TO postgres;

--
-- TOC entry 6191 (class 0 OID 0)
-- Dependencies: 488
-- Name: virtual_printer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE virtual_printer_id_seq OWNED BY virtual_printer.id;


--
-- TOC entry 490 (class 1259 OID 157198)
-- Name: virtualprinter_order_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE virtualprinter_order_type (
    printer_id integer NOT NULL,
    order_type character varying(255)
);


ALTER TABLE virtualprinter_order_type OWNER TO postgres;

--
-- TOC entry 487 (class 1259 OID 157182)
-- Name: void_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE void_reasons (
    id integer NOT NULL,
    reason_text character varying(255)
);


ALTER TABLE void_reasons OWNER TO postgres;

--
-- TOC entry 486 (class 1259 OID 157180)
-- Name: void_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE void_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE void_reasons_id_seq OWNER TO postgres;

--
-- TOC entry 6192 (class 0 OID 0)
-- Dependencies: 486
-- Name: void_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE void_reasons_id_seq OWNED BY void_reasons.id;


--
-- TOC entry 181 (class 1259 OID 152152)
-- Name: vw_daily_diagnostics_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_daily_diagnostics_summary AS
 SELECT f_daily_diagnostics_summary_on.source_view,
    f_daily_diagnostics_summary_on.severity,
    f_daily_diagnostics_summary_on.rows
   FROM f_daily_diagnostics_summary_on(('now'::text)::date) f_daily_diagnostics_summary_on(source_view, severity, rows);


ALTER TABLE vw_daily_diagnostics_summary OWNER TO postgres;

--
-- TOC entry 182 (class 1259 OID 152161)
-- Name: vw_diag_drawer_vs_cash_transactions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_drawer_vs_cash_transactions AS
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
   FROM f_diag_drawer_vs_cash_transactions_on(('now'::text)::date) t(terminal_id, original_total_revenue, corrected_neto_tickets, adjustment, cash_in, non_cash_in, expected_cash, diff, error_code, severity);


ALTER TABLE vw_diag_drawer_vs_cash_transactions OWNER TO postgres;

--
-- TOC entry 183 (class 1259 OID 152220)
-- Name: vw_item_mods_daily_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_item_mods_daily_summary AS
 SELECT f_item_mods_on.folio_date,
    f_item_mods_on.branch_key,
    f_item_mods_on.item_name,
    f_item_mods_on.modifier_name,
    sum(f_item_mods_on.qty_item) AS qty_items,
    (sum(f_item_mods_on.mods_count))::bigint AS times_selected,
    round(sum(f_item_mods_on.mods_total_amount), 2) AS total_mods_amount
   FROM f_item_mods_on(('now'::text)::date) f_item_mods_on(folio_date, branch_key, terminal_id, ticket_id, ticket_item_id, item_name, modifier_name, qty_item, mods_count, mods_total_amount)
  GROUP BY f_item_mods_on.folio_date, f_item_mods_on.branch_key, f_item_mods_on.item_name, f_item_mods_on.modifier_name
  ORDER BY f_item_mods_on.branch_key, f_item_mods_on.item_name, f_item_mods_on.modifier_name;


ALTER TABLE vw_item_mods_daily_summary OWNER TO postgres;

--
-- TOC entry 184 (class 1259 OID 152224)
-- Name: vw_item_mods_by_item_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_item_mods_by_item_today AS
 SELECT vw_item_mods_daily_summary.item_name,
    vw_item_mods_daily_summary.modifier_name,
    (sum(vw_item_mods_daily_summary.times_selected))::bigint AS times_selected,
    round(sum(vw_item_mods_daily_summary.total_mods_amount), 2) AS total_mods_amount
   FROM vw_item_mods_daily_summary
  GROUP BY vw_item_mods_daily_summary.item_name, vw_item_mods_daily_summary.modifier_name
  ORDER BY vw_item_mods_daily_summary.item_name, ((sum(vw_item_mods_daily_summary.times_selected))::bigint) DESC, vw_item_mods_daily_summary.modifier_name;


ALTER TABLE vw_item_mods_by_item_today OWNER TO postgres;

--
-- TOC entry 185 (class 1259 OID 152228)
-- Name: vw_item_mods_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_item_mods_today AS
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
   FROM f_item_mods_on(('now'::text)::date) f_item_mods_on(folio_date, branch_key, terminal_id, ticket_id, ticket_item_id, item_name, modifier_name, qty_item, mods_count, mods_total_amount);


ALTER TABLE vw_item_mods_today OWNER TO postgres;

--
-- TOC entry 186 (class 1259 OID 152271)
-- Name: vw_sales_daily_branch; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sales_daily_branch AS
 SELECT get_daily_stats.sucursal,
    get_daily_stats.total_ordenes,
    get_daily_stats.total_ventas,
    get_daily_stats.primer_orden,
    get_daily_stats.ultima_orden,
    get_daily_stats.promedio_por_hora
   FROM get_daily_stats(('now'::text)::date) get_daily_stats(sucursal, total_ordenes, total_ventas, primer_orden, ultima_orden, promedio_por_hora);


ALTER TABLE vw_sales_daily_branch OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 152275)
-- Name: vw_sales_daily_branch_range; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sales_daily_branch_range AS
 SELECT (c.d)::date AS folio_date,
    x.sucursal,
    x.total_ordenes,
    x.total_ventas,
    x.primer_orden,
    x.ultima_orden,
    x.promedio_por_hora
   FROM (generate_series((('now'::text)::date - '365 days'::interval), (('now'::text)::date)::timestamp without time zone, '1 day'::interval) c(d)
     CROSS JOIN LATERAL get_daily_stats((c.d)::date) x(sucursal, total_ordenes, total_ventas, primer_orden, ultima_orden, promedio_por_hora));


ALTER TABLE vw_sales_daily_branch_range OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 152289)
-- Name: vw_sales_mix_payment_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sales_mix_payment_today AS
 SELECT f_sales_mix_payment_on.folio_date,
    f_sales_mix_payment_on.branch_key,
    f_sales_mix_payment_on.normalized_payment,
    f_sales_mix_payment_on.total
   FROM f_sales_mix_payment_on(('now'::text)::date) f_sales_mix_payment_on(folio_date, branch_key, normalized_payment, total);


ALTER TABLE vw_sales_mix_payment_today OWNER TO postgres;

--
-- TOC entry 485 (class 1259 OID 157174)
-- Name: zip_code_vs_delivery_charge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE zip_code_vs_delivery_charge (
    auto_id integer NOT NULL,
    zip_code character varying(10) NOT NULL,
    delivery_charge double precision NOT NULL
);


ALTER TABLE zip_code_vs_delivery_charge OWNER TO postgres;

--
-- TOC entry 484 (class 1259 OID 157172)
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE zip_code_vs_delivery_charge_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE zip_code_vs_delivery_charge_auto_id_seq OWNER TO postgres;

--
-- TOC entry 6193 (class 0 OID 0)
-- Dependencies: 484
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE zip_code_vs_delivery_charge_auto_id_seq OWNED BY zip_code_vs_delivery_charge.auto_id;


SET search_path = selemti, pg_catalog;

--
-- TOC entry 189 (class 1259 OID 152303)
-- Name: alert_events; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE alert_events (
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


ALTER TABLE alert_events OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 152312)
-- Name: alert_events_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE alert_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alert_events_id_seq OWNER TO postgres;

--
-- TOC entry 6194 (class 0 OID 0)
-- Dependencies: 190
-- Name: alert_events_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_events_id_seq OWNED BY alert_events.id;


--
-- TOC entry 191 (class 1259 OID 152314)
-- Name: alert_rules; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE alert_rules (
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


ALTER TABLE alert_rules OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 152323)
-- Name: alert_rules_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE alert_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alert_rules_id_seq OWNER TO postgres;

--
-- TOC entry 6195 (class 0 OID 0)
-- Dependencies: 192
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_rules_id_seq OWNED BY alert_rules.id;


--
-- TOC entry 193 (class 1259 OID 152325)
-- Name: almacen; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE almacen (
    id text NOT NULL,
    sucursal_id bigint NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE almacen OWNER TO postgres;

--
-- TOC entry 194 (class 1259 OID 152332)
-- Name: audit_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE audit_log (
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


ALTER TABLE audit_log OWNER TO postgres;

--
-- TOC entry 195 (class 1259 OID 152339)
-- Name: audit_log_global; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE audit_log_global (
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


ALTER TABLE audit_log_global OWNER TO postgres;

--
-- TOC entry 6196 (class 0 OID 0)
-- Dependencies: 195
-- Name: TABLE audit_log_global; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE audit_log_global IS 'Log global de auditorÃ­a - Creada en Phase 5';


--
-- TOC entry 196 (class 1259 OID 152347)
-- Name: audit_log_global_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE audit_log_global_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE audit_log_global_id_seq OWNER TO postgres;

--
-- TOC entry 6197 (class 0 OID 0)
-- Dependencies: 196
-- Name: audit_log_global_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE audit_log_global_id_seq OWNED BY audit_log_global.id;


--
-- TOC entry 197 (class 1259 OID 152349)
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE audit_log_id_seq OWNER TO postgres;

--
-- TOC entry 6198 (class 0 OID 0)
-- Dependencies: 197
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;


--
-- TOC entry 198 (class 1259 OID 152351)
-- Name: auditoria; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE auditoria (
    id bigint NOT NULL,
    quien integer,
    que text NOT NULL,
    payload jsonb,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE auditoria OWNER TO floreant;

--
-- TOC entry 199 (class 1259 OID 152358)
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auditoria_id_seq OWNER TO floreant;

--
-- TOC entry 6199 (class 0 OID 0)
-- Dependencies: 199
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE auditoria_id_seq OWNED BY auditoria.id;


--
-- TOC entry 200 (class 1259 OID 152360)
-- Name: bodega; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE bodega (
    id integer NOT NULL,
    sucursal_id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE bodega OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 152366)
-- Name: bodega_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE bodega_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE bodega_id_seq OWNER TO postgres;

--
-- TOC entry 6200 (class 0 OID 0)
-- Dependencies: 201
-- Name: bodega_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE bodega_id_seq OWNED BY bodega.id;


--
-- TOC entry 202 (class 1259 OID 152368)
-- Name: cache; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 152374)
-- Name: cache_locks; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache_locks OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 152380)
-- Name: caja_fondo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo (
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


ALTER TABLE caja_fondo OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 152387)
-- Name: caja_fondo_adj; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_adj (
    id bigint NOT NULL,
    mov_id bigint,
    tipo character varying(16) NOT NULL,
    archivo_url text NOT NULL,
    observaciones text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE caja_fondo_adj OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 152394)
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE caja_fondo_adj_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE caja_fondo_adj_id_seq OWNER TO postgres;

--
-- TOC entry 6201 (class 0 OID 0)
-- Dependencies: 206
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_adj_id_seq OWNED BY caja_fondo_adj.id;


--
-- TOC entry 207 (class 1259 OID 152396)
-- Name: caja_fondo_arqueo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_arqueo (
    id bigint NOT NULL,
    fondo_id bigint,
    fecha_cierre timestamp without time zone DEFAULT now() NOT NULL,
    efectivo_contado numeric(12,2) NOT NULL,
    diferencia numeric(12,2) NOT NULL,
    observaciones text,
    cerrado_por integer NOT NULL
);


ALTER TABLE caja_fondo_arqueo OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 152403)
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE caja_fondo_arqueo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE caja_fondo_arqueo_id_seq OWNER TO postgres;

--
-- TOC entry 6202 (class 0 OID 0)
-- Dependencies: 208
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_arqueo_id_seq OWNED BY caja_fondo_arqueo.id;


--
-- TOC entry 209 (class 1259 OID 152405)
-- Name: caja_fondo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE caja_fondo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE caja_fondo_id_seq OWNER TO postgres;

--
-- TOC entry 6203 (class 0 OID 0)
-- Dependencies: 209
-- Name: caja_fondo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_id_seq OWNED BY caja_fondo.id;


--
-- TOC entry 210 (class 1259 OID 152407)
-- Name: caja_fondo_mov; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_mov (
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


ALTER TABLE caja_fondo_mov OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 152419)
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE caja_fondo_mov_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE caja_fondo_mov_id_seq OWNER TO postgres;

--
-- TOC entry 6204 (class 0 OID 0)
-- Dependencies: 211
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_mov_id_seq OWNED BY caja_fondo_mov.id;


--
-- TOC entry 212 (class 1259 OID 152421)
-- Name: caja_fondo_usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_usuario (
    fondo_id bigint NOT NULL,
    user_id integer NOT NULL,
    rol character varying(16) NOT NULL
);


ALTER TABLE caja_fondo_usuario OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 152424)
-- Name: cash_fund_arqueos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cash_fund_arqueos (
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


ALTER TABLE cash_fund_arqueos OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 152430)
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cash_fund_arqueos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_fund_arqueos_id_seq OWNER TO postgres;

--
-- TOC entry 6205 (class 0 OID 0)
-- Dependencies: 214
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_arqueos_id_seq OWNED BY cash_fund_arqueos.id;


--
-- TOC entry 215 (class 1259 OID 152432)
-- Name: cash_fund_movement_audit_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cash_fund_movement_audit_log (
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


ALTER TABLE cash_fund_movement_audit_log OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 152439)
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cash_fund_movement_audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_fund_movement_audit_log_id_seq OWNER TO postgres;

--
-- TOC entry 6206 (class 0 OID 0)
-- Dependencies: 216
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movement_audit_log_id_seq OWNED BY cash_fund_movement_audit_log.id;


--
-- TOC entry 217 (class 1259 OID 152441)
-- Name: cash_fund_movements; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cash_fund_movements (
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


ALTER TABLE cash_fund_movements OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 152453)
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cash_fund_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_fund_movements_id_seq OWNER TO postgres;

--
-- TOC entry 6207 (class 0 OID 0)
-- Dependencies: 218
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movements_id_seq OWNED BY cash_fund_movements.id;


--
-- TOC entry 219 (class 1259 OID 152455)
-- Name: cash_funds; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cash_funds (
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


ALTER TABLE cash_funds OWNER TO postgres;

--
-- TOC entry 6208 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN cash_funds.descripcion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN cash_funds.descripcion IS 'Descripción o nombre del fondo para identificación rápida';


--
-- TOC entry 220 (class 1259 OID 152464)
-- Name: cash_funds_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cash_funds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_funds_id_seq OWNER TO postgres;

--
-- TOC entry 6209 (class 0 OID 0)
-- Dependencies: 220
-- Name: cash_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_funds_id_seq OWNED BY cash_funds.id;


--
-- TOC entry 221 (class 1259 OID 152466)
-- Name: cat_almacenes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_almacenes (
    id bigint NOT NULL,
    clave character varying(16) NOT NULL,
    nombre character varying(80) NOT NULL,
    sucursal_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE cat_almacenes OWNER TO postgres;

--
-- TOC entry 6210 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE cat_almacenes; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE cat_almacenes IS 'CatÃ¡logo de almacenes - Consolidada en Phase 2.2';


--
-- TOC entry 222 (class 1259 OID 152470)
-- Name: cat_almacenes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cat_almacenes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cat_almacenes_id_seq OWNER TO postgres;

--
-- TOC entry 6211 (class 0 OID 0)
-- Dependencies: 222
-- Name: cat_almacenes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_almacenes_id_seq OWNED BY cat_almacenes.id;


--
-- TOC entry 223 (class 1259 OID 152472)
-- Name: cat_proveedores; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_proveedores (
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


ALTER TABLE cat_proveedores OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 152479)
-- Name: cat_proveedores_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cat_proveedores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cat_proveedores_id_seq OWNER TO postgres;

--
-- TOC entry 6212 (class 0 OID 0)
-- Dependencies: 224
-- Name: cat_proveedores_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_proveedores_id_seq OWNED BY cat_proveedores.id;


--
-- TOC entry 225 (class 1259 OID 152481)
-- Name: cat_sucursales; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_sucursales (
    id bigint NOT NULL,
    clave character varying(16) NOT NULL,
    nombre character varying(120) NOT NULL,
    ubicacion character varying(160),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    pos_location character varying(64)
);


ALTER TABLE cat_sucursales OWNER TO postgres;

--
-- TOC entry 6213 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE cat_sucursales; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE cat_sucursales IS 'CatÃ¡logo de sucursales - Consolidada en Phase 2.2';


--
-- TOC entry 226 (class 1259 OID 152485)
-- Name: cat_sucursales_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cat_sucursales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cat_sucursales_id_seq OWNER TO postgres;

--
-- TOC entry 6214 (class 0 OID 0)
-- Dependencies: 226
-- Name: cat_sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_sucursales_id_seq OWNED BY cat_sucursales.id;


--
-- TOC entry 227 (class 1259 OID 152487)
-- Name: cat_unidades; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    clave character varying(16),
    nombre character varying(64),
    activo boolean DEFAULT true NOT NULL,
    categoria character varying(20)
);


ALTER TABLE cat_unidades OWNER TO postgres;

--
-- TOC entry 6215 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN cat_unidades.categoria; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN cat_unidades.categoria IS 'Categoría: BASE, COCINA, COMPRA, PORCION';


--
-- TOC entry 228 (class 1259 OID 152491)
-- Name: cat_unidades_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cat_unidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cat_unidades_id_seq OWNER TO postgres;

--
-- TOC entry 6216 (class 0 OID 0)
-- Dependencies: 228
-- Name: cat_unidades_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;


--
-- TOC entry 229 (class 1259 OID 152493)
-- Name: cat_uom_conversion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_uom_conversion (
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


ALTER TABLE cat_uom_conversion OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 152501)
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cat_uom_conversion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cat_uom_conversion_id_seq OWNER TO postgres;

--
-- TOC entry 6217 (class 0 OID 0)
-- Dependencies: 230
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_uom_conversion_id_seq OWNED BY cat_uom_conversion.id;


--
-- TOC entry 231 (class 1259 OID 152503)
-- Name: conciliacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE conciliacion (
    id bigint NOT NULL,
    postcorte_id bigint NOT NULL,
    conciliado_por integer,
    conciliado_en timestamp with time zone DEFAULT now(),
    estatus text DEFAULT 'EN_REVISION'::text NOT NULL,
    notas text,
    CONSTRAINT conciliacion_estatus_check CHECK ((estatus = ANY (ARRAY['EN_REVISION'::text, 'CONCILIADO'::text, 'OBSERVADA'::text])))
);


ALTER TABLE conciliacion OWNER TO postgres;

--
-- TOC entry 6218 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 6219 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 6220 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN conciliacion.conciliado_por; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.conciliado_por IS 'Usuario que realizÃ³ la conciliaciÃ³n (supervisor/gerente).';


--
-- TOC entry 232 (class 1259 OID 152512)
-- Name: conciliacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE conciliacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE conciliacion_id_seq OWNER TO postgres;

--
-- TOC entry 6221 (class 0 OID 0)
-- Dependencies: 232
-- Name: conciliacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conciliacion_id_seq OWNED BY conciliacion.id;


--
-- TOC entry 233 (class 1259 OID 152514)
-- Name: conversiones_unidad; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW conversiones_unidad AS
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
   FROM cat_uom_conversion;


ALTER TABLE conversiones_unidad OWNER TO postgres;

--
-- TOC entry 6222 (class 0 OID 0)
-- Dependencies: 233
-- Name: VIEW conversiones_unidad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW conversiones_unidad IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy conversiones_unidad';


--
-- TOC entry 234 (class 1259 OID 152518)
-- Name: conversiones_unidad_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE conversiones_unidad_legacy (
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


ALTER TABLE conversiones_unidad_legacy OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 152529)
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE conversiones_unidad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE conversiones_unidad_id_seq OWNER TO postgres;

--
-- TOC entry 6223 (class 0 OID 0)
-- Dependencies: 235
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad_legacy.id;


--
-- TOC entry 236 (class 1259 OID 152531)
-- Name: cost_layer; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cost_layer (
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


ALTER TABLE cost_layer OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 152537)
-- Name: cost_layer_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE cost_layer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cost_layer_id_seq OWNER TO postgres;

--
-- TOC entry 6224 (class 0 OID 0)
-- Dependencies: 237
-- Name: cost_layer_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cost_layer_id_seq OWNED BY cost_layer.id;


--
-- TOC entry 238 (class 1259 OID 152539)
-- Name: failed_jobs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE failed_jobs OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 152546)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE failed_jobs_id_seq OWNER TO postgres;

--
-- TOC entry 6225 (class 0 OID 0)
-- Dependencies: 239
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


--
-- TOC entry 240 (class 1259 OID 152548)
-- Name: formas_pago; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE formas_pago (
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


ALTER TABLE formas_pago OWNER TO floreant;

--
-- TOC entry 241 (class 1259 OID 152557)
-- Name: formas_pago_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE formas_pago_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE formas_pago_id_seq OWNER TO floreant;

--
-- TOC entry 6226 (class 0 OID 0)
-- Dependencies: 241
-- Name: formas_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE formas_pago_id_seq OWNED BY formas_pago.id;


--
-- TOC entry 242 (class 1259 OID 152559)
-- Name: hist_cost_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE hist_cost_insumo (
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


ALTER TABLE hist_cost_insumo OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 152570)
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE hist_cost_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hist_cost_insumo_id_seq OWNER TO postgres;

--
-- TOC entry 6227 (class 0 OID 0)
-- Dependencies: 243
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_insumo_id_seq OWNED BY hist_cost_insumo.id;


--
-- TOC entry 244 (class 1259 OID 152572)
-- Name: hist_cost_receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE hist_cost_receta (
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


ALTER TABLE hist_cost_receta OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 152581)
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE hist_cost_receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hist_cost_receta_id_seq OWNER TO postgres;

--
-- TOC entry 6228 (class 0 OID 0)
-- Dependencies: 245
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_receta_id_seq OWNED BY hist_cost_receta.id;


--
-- TOC entry 246 (class 1259 OID 152583)
-- Name: historial_costos_item; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE historial_costos_item (
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


ALTER TABLE historial_costos_item OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 152598)
-- Name: historial_costos_item_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE historial_costos_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE historial_costos_item_id_seq OWNER TO postgres;

--
-- TOC entry 6229 (class 0 OID 0)
-- Dependencies: 247
-- Name: historial_costos_item_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_item_id_seq OWNED BY historial_costos_item.id;


--
-- TOC entry 248 (class 1259 OID 152600)
-- Name: historial_costos_receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE historial_costos_receta (
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


ALTER TABLE historial_costos_receta OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 152609)
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE historial_costos_receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE historial_costos_receta_id_seq OWNER TO postgres;

--
-- TOC entry 6230 (class 0 OID 0)
-- Dependencies: 249
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_receta_id_seq OWNED BY historial_costos_receta.id;


--
-- TOC entry 250 (class 1259 OID 152611)
-- Name: insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE insumo (
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


ALTER TABLE insumo OWNER TO postgres;

--
-- TOC entry 6231 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN insumo.codigo_alterno; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN insumo.codigo_alterno IS 'Código alternativo para compatibilidad';


--
-- TOC entry 251 (class 1259 OID 152620)
-- Name: insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE insumo_id_seq OWNER TO postgres;

--
-- TOC entry 6232 (class 0 OID 0)
-- Dependencies: 251
-- Name: insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_id_seq OWNED BY insumo.id;


--
-- TOC entry 252 (class 1259 OID 152622)
-- Name: insumo_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE insumo_presentacion (
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


ALTER TABLE insumo_presentacion OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 152630)
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE insumo_presentacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE insumo_presentacion_id_seq OWNER TO postgres;

--
-- TOC entry 6233 (class 0 OID 0)
-- Dependencies: 253
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


--
-- TOC entry 254 (class 1259 OID 152632)
-- Name: insumo_proveedor_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE insumo_proveedor_presentacion (
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


ALTER TABLE insumo_proveedor_presentacion OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 152644)
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE insumo_proveedor_presentacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE insumo_proveedor_presentacion_id_seq OWNER TO postgres;

--
-- TOC entry 6234 (class 0 OID 0)
-- Dependencies: 255
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_proveedor_presentacion_id_seq OWNED BY insumo_proveedor_presentacion.id;


--
-- TOC entry 256 (class 1259 OID 152646)
-- Name: inv_consumo_pos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inv_consumo_pos (
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


ALTER TABLE inv_consumo_pos OWNER TO postgres;

--
-- TOC entry 6235 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- TOC entry 6236 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- TOC entry 6237 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.fecha_proceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.fecha_proceso IS 'Momento del procesamiento';


--
-- TOC entry 6238 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.revertido; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.revertido IS 'Consumo revertido/anulado';


--
-- TOC entry 257 (class 1259 OID 152653)
-- Name: inv_consumo_pos_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inv_consumo_pos_det (
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


ALTER TABLE inv_consumo_pos_det OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 152659)
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inv_consumo_pos_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inv_consumo_pos_det_id_seq OWNER TO postgres;

--
-- TOC entry 6239 (class 0 OID 0)
-- Dependencies: 258
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_det_id_seq OWNED BY inv_consumo_pos_det.id;


--
-- TOC entry 259 (class 1259 OID 152661)
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inv_consumo_pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inv_consumo_pos_id_seq OWNER TO postgres;

--
-- TOC entry 6240 (class 0 OID 0)
-- Dependencies: 259
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_id_seq OWNED BY inv_consumo_pos.id;


--
-- TOC entry 260 (class 1259 OID 152663)
-- Name: inv_consumo_pos_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inv_consumo_pos_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    accion character varying(20) NOT NULL,
    registrado_en timestamp(0) with time zone DEFAULT now() NOT NULL,
    payload jsonb
);


ALTER TABLE inv_consumo_pos_log OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 152670)
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inv_consumo_pos_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inv_consumo_pos_log_id_seq OWNER TO postgres;

--
-- TOC entry 6241 (class 0 OID 0)
-- Dependencies: 261
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_log_id_seq OWNED BY inv_consumo_pos_log.id;


--
-- TOC entry 262 (class 1259 OID 152672)
-- Name: inv_stock_policy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inv_stock_policy (
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


ALTER TABLE inv_stock_policy OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 152679)
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inv_stock_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inv_stock_policy_id_seq OWNER TO postgres;

--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 263
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_stock_policy_id_seq OWNED BY inv_stock_policy.id;


--
-- TOC entry 264 (class 1259 OID 152681)
-- Name: inventory_batch; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_batch (
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


ALTER TABLE inventory_batch OWNER TO postgres;

--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario - Consolidada en Phase 2.3';


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN inventory_batch.unit_cost; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inventory_batch.unit_cost IS 'Costo unitario del lote para costeo por batch.';


--
-- TOC entry 265 (class 1259 OID 152695)
-- Name: inventory_batch_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inventory_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_batch_id_seq OWNER TO postgres;

--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 265
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


--
-- TOC entry 266 (class 1259 OID 152697)
-- Name: inventory_count_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_count_lines (
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


ALTER TABLE inventory_count_lines OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 152706)
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inventory_count_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_count_lines_id_seq OWNER TO postgres;

--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 267
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_count_lines_id_seq OWNED BY inventory_count_lines.id;


--
-- TOC entry 268 (class 1259 OID 152708)
-- Name: inventory_counts; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_counts (
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


ALTER TABLE inventory_counts OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 152717)
-- Name: inventory_counts_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inventory_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_counts_id_seq OWNER TO postgres;

--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 269
-- Name: inventory_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_counts_id_seq OWNED BY inventory_counts.id;


--
-- TOC entry 270 (class 1259 OID 152719)
-- Name: inventory_snapshot; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_snapshot (
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


ALTER TABLE inventory_snapshot OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 152728)
-- Name: inventory_wastes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_wastes (
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


ALTER TABLE inventory_wastes OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 152735)
-- Name: inventory_wastes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE inventory_wastes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_wastes_id_seq OWNER TO postgres;

--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 272
-- Name: inventory_wastes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_wastes_id_seq OWNED BY inventory_wastes.id;


--
-- TOC entry 273 (class 1259 OID 152737)
-- Name: item_categories; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_categories (
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


ALTER TABLE item_categories OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 152744)
-- Name: item_categories_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE item_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_categories_id_seq OWNER TO postgres;

--
-- TOC entry 6249 (class 0 OID 0)
-- Dependencies: 274
-- Name: item_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_categories_id_seq OWNED BY item_categories.id;


--
-- TOC entry 275 (class 1259 OID 152746)
-- Name: item_category_counters; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_category_counters (
    category_id bigint NOT NULL,
    last_val bigint DEFAULT 0 NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE item_category_counters OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 152750)
-- Name: item_vendor; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_vendor (
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


ALTER TABLE item_vendor OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 152762)
-- Name: item_vendor_prices; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_vendor_prices (
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


ALTER TABLE item_vendor_prices OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 152772)
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE item_vendor_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_vendor_prices_id_seq OWNER TO postgres;

--
-- TOC entry 6250 (class 0 OID 0)
-- Dependencies: 278
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_vendor_prices_id_seq OWNED BY item_vendor_prices.id;


--
-- TOC entry 279 (class 1259 OID 152774)
-- Name: items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE items (
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
    tipo producto_tipo,
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


ALTER TABLE items OWNER TO postgres;

--
-- TOC entry 6251 (class 0 OID 0)
-- Dependencies: 279
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'CatÃ¡logo de items/insumos - Consolidada en Phase 2.3';


--
-- TOC entry 6252 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_medida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_medida_id IS 'Unidad BASE de inventario (KG, L, PZ) - FK a cat_unidades';


--
-- TOC entry 6253 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.factor_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_conversion IS 'Factor adicional de conversión si se requiere (legacy, en desuso)';


--
-- TOC entry 6254 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_compra_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_compra_id IS 'Unidad de COMPRA del proveedor (CAJA, PAQUETE, COSTAL, etc) - FK a cat_unidades';


--
-- TOC entry 6255 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.factor_compra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_compra IS 'Factor de conversión: 1 unidad_compra = X unidades_base. Ej: 1 CAJA = 12 L';


--
-- TOC entry 6256 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_salida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_salida_id IS 'Unidad de SALIDA para recetas (ML, TAZA, PORCION, etc) - FK a cat_unidades';


--
-- TOC entry 6257 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- TOC entry 6258 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- TOC entry 6259 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.es_empaque_to_go; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_empaque_to_go IS 'Marks items as to-go packaging.';


--
-- TOC entry 280 (class 1259 OID 152797)
-- Name: job_batches; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE job_batches (
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


ALTER TABLE job_batches OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 152803)
-- Name: job_recalc_queue; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE job_recalc_queue (
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


ALTER TABLE job_recalc_queue OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 152813)
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE job_recalc_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_recalc_queue_id_seq OWNER TO postgres;

--
-- TOC entry 6260 (class 0 OID 0)
-- Dependencies: 282
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE job_recalc_queue_id_seq OWNED BY job_recalc_queue.id;


--
-- TOC entry 283 (class 1259 OID 152815)
-- Name: jobs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE jobs OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 152821)
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE jobs_id_seq OWNER TO postgres;

--
-- TOC entry 6261 (class 0 OID 0)
-- Dependencies: 284
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- TOC entry 285 (class 1259 OID 152823)
-- Name: labor_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE labor_roles (
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


ALTER TABLE labor_roles OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 152831)
-- Name: labor_roles_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE labor_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE labor_roles_id_seq OWNER TO postgres;

--
-- TOC entry 6262 (class 0 OID 0)
-- Dependencies: 286
-- Name: labor_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE labor_roles_id_seq OWNED BY labor_roles.id;


--
-- TOC entry 287 (class 1259 OID 152833)
-- Name: lote; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE lote (
    id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    proveedor_id integer,
    codigo text,
    caducidad date,
    estado lote_estado DEFAULT 'ACTIVO'::lote_estado NOT NULL,
    creado_ts timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE lote OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 152841)
-- Name: lote_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE lote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE lote_id_seq OWNER TO postgres;

--
-- TOC entry 6263 (class 0 OID 0)
-- Dependencies: 288
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE lote_id_seq OWNED BY lote.id;


--
-- TOC entry 289 (class 1259 OID 152843)
-- Name: menu_engineering_snapshots; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE menu_engineering_snapshots (
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


ALTER TABLE menu_engineering_snapshots OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 152857)
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE menu_engineering_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_engineering_snapshots_id_seq OWNER TO postgres;

--
-- TOC entry 6264 (class 0 OID 0)
-- Dependencies: 290
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_engineering_snapshots_id_seq OWNED BY menu_engineering_snapshots.id;


--
-- TOC entry 291 (class 1259 OID 152859)
-- Name: menu_item_sync_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE menu_item_sync_map (
    id bigint NOT NULL,
    menu_item_id bigint NOT NULL,
    pos_identifier character varying(120) NOT NULL,
    channel character varying(40) DEFAULT 'pos'::character varying NOT NULL,
    metadata jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE menu_item_sync_map OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 152866)
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE menu_item_sync_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_item_sync_map_id_seq OWNER TO postgres;

--
-- TOC entry 6265 (class 0 OID 0)
-- Dependencies: 292
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_item_sync_map_id_seq OWNED BY menu_item_sync_map.id;


--
-- TOC entry 293 (class 1259 OID 152868)
-- Name: menu_items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE menu_items (
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


ALTER TABLE menu_items OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 152875)
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_items_id_seq OWNER TO postgres;

--
-- TOC entry 6266 (class 0 OID 0)
-- Dependencies: 294
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_items_id_seq OWNED BY menu_items.id;


--
-- TOC entry 295 (class 1259 OID 152877)
-- Name: merma; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE merma (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    tipo merma_tipo NOT NULL,
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


ALTER TABLE merma OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 152886)
-- Name: merma_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE merma_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE merma_id_seq OWNER TO postgres;

--
-- TOC entry 6267 (class 0 OID 0)
-- Dependencies: 296
-- Name: merma_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE merma_id_seq OWNED BY merma.id;


--
-- TOC entry 297 (class 1259 OID 152888)
-- Name: migrations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 152891)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE migrations_id_seq OWNER TO postgres;

--
-- TOC entry 6268 (class 0 OID 0)
-- Dependencies: 298
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


--
-- TOC entry 299 (class 1259 OID 152893)
-- Name: model_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_permissions OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 152896)
-- Name: model_has_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_roles OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 152899)
-- Name: modificadores_pos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE modificadores_pos (
    id integer NOT NULL,
    codigo_pos character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(20),
    precio_extra numeric(10,2) DEFAULT 0,
    receta_modificador_id character varying(20),
    activo boolean DEFAULT true,
    CONSTRAINT modificadores_pos_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('AGREGADO'::character varying)::text, ('SUSTITUCION'::character varying)::text, ('ELIMINACION'::character varying)::text])))
);


ALTER TABLE modificadores_pos OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 152905)
-- Name: modificadores_pos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE modificadores_pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modificadores_pos_id_seq OWNER TO postgres;

--
-- TOC entry 6269 (class 0 OID 0)
-- Dependencies: 302
-- Name: modificadores_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE modificadores_pos_id_seq OWNED BY modificadores_pos.id;


--
-- TOC entry 303 (class 1259 OID 152907)
-- Name: mov_inv; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE mov_inv (
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


ALTER TABLE mov_inv OWNER TO postgres;

--
-- TOC entry 6270 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE mov_inv; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE mov_inv IS 'Kardex completo de movimientos de inventario.';


--
-- TOC entry 304 (class 1259 OID 152914)
-- Name: mov_inv_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE mov_inv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mov_inv_id_seq OWNER TO postgres;

--
-- TOC entry 6271 (class 0 OID 0)
-- Dependencies: 304
-- Name: mov_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE mov_inv_id_seq OWNED BY mov_inv.id;


--
-- TOC entry 306 (class 1259 OID 152949)
-- Name: mv_inventario_actual; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW mv_inventario_actual AS
 SELECT i.id AS item_id,
    i.nombre AS item_nombre,
    i.categoria_id,
    i.unidad_medida,
    count(DISTINCT ib.id) AS total_lotes,
    COALESCE(sum(ib.cantidad_actual), (0)::numeric) AS cantidad_total,
    COALESCE(avg(ib.unit_cost), (0)::numeric) AS costo_promedio,
    COALESCE(sum((ib.cantidad_actual * ib.unit_cost)), (0)::numeric) AS valor_total,
    max(ib.updated_at) AS ultima_actualizacion
   FROM (items i
     LEFT JOIN inventory_batch ib ON (((ib.item_id)::text = (i.id)::text)))
  WHERE ((i.activo = true) AND ((ib.estado IS NULL) OR ((ib.estado)::text = 'DISPONIBLE'::text)))
  GROUP BY i.id, i.nombre, i.categoria_id, i.unidad_medida
  WITH NO DATA;


ALTER TABLE mv_inventario_actual OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 152957)
-- Name: receta_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_cab (
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


ALTER TABLE receta_cab OWNER TO postgres;

--
-- TOC entry 6272 (class 0 OID 0)
-- Dependencies: 307
-- Name: TABLE receta_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_cab IS 'CatÃ¡logo de recetas - Consolidada en Phase 2.4';


--
-- TOC entry 308 (class 1259 OID 152971)
-- Name: receta_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_det (
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


ALTER TABLE receta_det OWNER TO postgres;

--
-- TOC entry 6273 (class 0 OID 0)
-- Dependencies: 308
-- Name: TABLE receta_det; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_det IS 'Detalle de ingredientes de recetas - Consolidada en Phase 2.4';


--
-- TOC entry 309 (class 1259 OID 152982)
-- Name: receta_version; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_version (
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


ALTER TABLE receta_version OWNER TO postgres;

--
-- TOC entry 6274 (class 0 OID 0)
-- Dependencies: 309
-- Name: TABLE receta_version; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_version IS 'Control de versiones de recetas.';


--
-- TOC entry 310 (class 1259 OID 152991)
-- Name: mv_recetas_costos; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW mv_recetas_costos AS
 SELECT rc.id AS receta_id,
    rc.nombre_plato,
    rc.categoria_plato,
    rc.costo_standard_porcion,
    rc.precio_venta_sugerido,
    count(rd.id) AS total_ingredientes,
    rc.activo,
    rc.updated_at
   FROM (receta_cab rc
     LEFT JOIN receta_det rd ON ((rd.receta_version_id = ( SELECT receta_version.id
           FROM receta_version
          WHERE ((receta_version.receta_id)::text = (rc.id)::text)
         LIMIT 1))))
  GROUP BY rc.id, rc.nombre_plato, rc.categoria_plato, rc.costo_standard_porcion, rc.precio_venta_sugerido, rc.activo, rc.updated_at
  WITH NO DATA;


ALTER TABLE mv_recetas_costos OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 152996)
-- Name: op_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_cab (
    id bigint NOT NULL,
    sucursal_id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    cantidad_objetivo numeric(14,6) NOT NULL,
    um_salida_id integer NOT NULL,
    estado op_estado DEFAULT 'ABIERTA'::op_estado NOT NULL,
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


ALTER TABLE op_cab OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 153006)
-- Name: op_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE op_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE op_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6275 (class 0 OID 0)
-- Dependencies: 312
-- Name: op_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_cab_id_seq OWNED BY op_cab.id;


--
-- TOC entry 313 (class 1259 OID 153008)
-- Name: op_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_insumo (
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


ALTER TABLE op_insumo OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 153016)
-- Name: op_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE op_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE op_insumo_id_seq OWNER TO postgres;

--
-- TOC entry 6276 (class 0 OID 0)
-- Dependencies: 314
-- Name: op_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_insumo_id_seq OWNED BY op_insumo.id;


--
-- TOC entry 315 (class 1259 OID 153018)
-- Name: op_produccion_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_produccion_cab (
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


ALTER TABLE op_produccion_cab OWNER TO postgres;

--
-- TOC entry 6277 (class 0 OID 0)
-- Dependencies: 315
-- Name: TABLE op_produccion_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE op_produccion_cab IS 'Cabecera de Ã³rdenes de producciÃ³n.';


--
-- TOC entry 316 (class 1259 OID 153026)
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE op_produccion_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE op_produccion_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6278 (class 0 OID 0)
-- Dependencies: 316
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_produccion_cab_id_seq OWNED BY op_produccion_cab.id;


--
-- TOC entry 317 (class 1259 OID 153028)
-- Name: op_yield; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_yield (
    op_id bigint NOT NULL,
    cantidad_real numeric(14,6) NOT NULL,
    merma_real numeric(14,6) DEFAULT 0 NOT NULL,
    evidencia_url text,
    meta jsonb
);


ALTER TABLE op_yield OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 153035)
-- Name: overhead_definitions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE overhead_definitions (
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


ALTER TABLE overhead_definitions OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 153044)
-- Name: overhead_definitions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE overhead_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE overhead_definitions_id_seq OWNER TO postgres;

--
-- TOC entry 6279 (class 0 OID 0)
-- Dependencies: 319
-- Name: overhead_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE overhead_definitions_id_seq OWNED BY overhead_definitions.id;


--
-- TOC entry 320 (class 1259 OID 153046)
-- Name: param_sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE param_sucursal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    consumo consumo_policy DEFAULT 'FEFO'::consumo_policy NOT NULL,
    tolerancia_precorte_pct numeric(8,4) DEFAULT 0.02,
    tolerancia_corte_abs numeric(12,4) DEFAULT 50.0,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE param_sucursal OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 153057)
-- Name: param_sucursal_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE param_sucursal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE param_sucursal_id_seq OWNER TO postgres;

--
-- TOC entry 6280 (class 0 OID 0)
-- Dependencies: 321
-- Name: param_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE param_sucursal_id_seq OWNED BY param_sucursal.id;


--
-- TOC entry 322 (class 1259 OID 153059)
-- Name: password_reset_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE password_reset_tokens OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 153065)
-- Name: perdida_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE perdida_log (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    item_id text NOT NULL,
    lote_id bigint,
    sucursal_id text,
    clase merma_clase NOT NULL,
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


ALTER TABLE perdida_log OWNER TO postgres;

--
-- TOC entry 324 (class 1259 OID 153074)
-- Name: perdida_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE perdida_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE perdida_log_id_seq OWNER TO postgres;

--
-- TOC entry 6281 (class 0 OID 0)
-- Dependencies: 324
-- Name: perdida_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE perdida_log_id_seq OWNED BY perdida_log.id;


--
-- TOC entry 325 (class 1259 OID 153076)
-- Name: permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE permissions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE permissions OWNER TO postgres;

--
-- TOC entry 326 (class 1259 OID 153082)
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE permissions_id_seq OWNER TO postgres;

--
-- TOC entry 6282 (class 0 OID 0)
-- Dependencies: 326
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- TOC entry 327 (class 1259 OID 153084)
-- Name: personal_access_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE personal_access_tokens (
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


ALTER TABLE personal_access_tokens OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 153090)
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE personal_access_tokens_id_seq OWNER TO postgres;

--
-- TOC entry 6283 (class 0 OID 0)
-- Dependencies: 328
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE personal_access_tokens_id_seq OWNED BY personal_access_tokens.id;


--
-- TOC entry 329 (class 1259 OID 153092)
-- Name: pos_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_map (
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


ALTER TABLE pos_map OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 153102)
-- Name: pos_modifiers_map; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_modifiers_map (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    pos_modifier_code text NOT NULL,
    name text,
    effect pos_modifier_effect NOT NULL,
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
    WHEN 'replace'::pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL))
    WHEN 'extra'::pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL) OR (delta_qty_canonical IS NOT NULL))
    WHEN 'remove'::pos_modifier_effect THEN ((linked_recipe_id IS NOT NULL) OR (linked_recipe_version_id IS NOT NULL) OR (delta_qty_canonical IS NOT NULL))
    WHEN 'delta'::pos_modifier_effect THEN (delta_cost IS NOT NULL)
    ELSE false
END)
);


ALTER TABLE pos_modifiers_map OWNER TO postgres;

--
-- TOC entry 6284 (class 0 OID 0)
-- Dependencies: 330
-- Name: TABLE pos_modifiers_map; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_modifiers_map IS 'Mapa de modificadores POS → impacto en receta/costo/consumo.';


--
-- TOC entry 331 (class 1259 OID 153114)
-- Name: pos_reprocess_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_reprocess_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reprocessed_at timestamp without time zone DEFAULT now() NOT NULL,
    motivo text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE pos_reprocess_log OWNER TO postgres;

--
-- TOC entry 6285 (class 0 OID 0)
-- Dependencies: 331
-- Name: TABLE pos_reprocess_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reprocess_log IS 'Log de auditoría de reprocesos de consumo POS histórico';


--
-- TOC entry 332 (class 1259 OID 153123)
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE pos_reprocess_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pos_reprocess_log_id_seq OWNER TO postgres;

--
-- TOC entry 6286 (class 0 OID 0)
-- Dependencies: 332
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reprocess_log_id_seq OWNED BY pos_reprocess_log.id;


--
-- TOC entry 333 (class 1259 OID 153125)
-- Name: pos_reverse_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_reverse_log (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reversed_at timestamp without time zone DEFAULT now() NOT NULL,
    motivo text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE pos_reverse_log OWNER TO postgres;

--
-- TOC entry 6287 (class 0 OID 0)
-- Dependencies: 333
-- Name: TABLE pos_reverse_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reverse_log IS 'Log de auditoría de reversas de consumo POS';


--
-- TOC entry 334 (class 1259 OID 153134)
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE pos_reverse_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pos_reverse_log_id_seq OWNER TO postgres;

--
-- TOC entry 6288 (class 0 OID 0)
-- Dependencies: 334
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reverse_log_id_seq OWNED BY pos_reverse_log.id;


--
-- TOC entry 335 (class 1259 OID 153136)
-- Name: pos_sync_batches; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_sync_batches (
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


ALTER TABLE pos_sync_batches OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 153146)
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE pos_sync_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pos_sync_batches_id_seq OWNER TO postgres;

--
-- TOC entry 6289 (class 0 OID 0)
-- Dependencies: 336
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_batches_id_seq OWNED BY pos_sync_batches.id;


--
-- TOC entry 337 (class 1259 OID 153148)
-- Name: pos_sync_logs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE pos_sync_logs (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    external_id character varying(120),
    action character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    payload jsonb,
    message text,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pos_sync_logs OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 153155)
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE pos_sync_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pos_sync_logs_id_seq OWNER TO postgres;

--
-- TOC entry 6290 (class 0 OID 0)
-- Dependencies: 338
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_logs_id_seq OWNED BY pos_sync_logs.id;


--
-- TOC entry 339 (class 1259 OID 153157)
-- Name: postcorte; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE postcorte (
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
    CONSTRAINT postcorte_veredicto_efectivo_check CHECK ((veredicto_efectivo = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_tarjetas_check CHECK ((veredicto_tarjetas = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_transfer_check CHECK ((veredicto_transferencias = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text])))
);


ALTER TABLE postcorte OWNER TO floreant;

--
-- TOC entry 6291 (class 0 OID 0)
-- Dependencies: 339
-- Name: COLUMN postcorte.validado; Type: COMMENT; Schema: selemti; Owner: floreant
--

COMMENT ON COLUMN postcorte.validado IS 'TRUE cuando el supervisor valida/cierra el postcorte';


--
-- TOC entry 340 (class 1259 OID 153180)
-- Name: postcorte_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE postcorte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE postcorte_id_seq OWNER TO floreant;

--
-- TOC entry 6292 (class 0 OID 0)
-- Dependencies: 340
-- Name: postcorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE postcorte_id_seq OWNED BY postcorte.id;


--
-- TOC entry 341 (class 1259 OID 153182)
-- Name: precorte; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE precorte (
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


ALTER TABLE precorte OWNER TO floreant;

--
-- TOC entry 342 (class 1259 OID 153193)
-- Name: precorte_efectivo; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE precorte_efectivo (
    id bigint NOT NULL,
    precorte_id bigint NOT NULL,
    denominacion numeric(12,2) NOT NULL,
    cantidad integer NOT NULL,
    subtotal numeric(12,2) DEFAULT 0 NOT NULL
);


ALTER TABLE precorte_efectivo OWNER TO floreant;

--
-- TOC entry 343 (class 1259 OID 153197)
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE precorte_efectivo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE precorte_efectivo_id_seq OWNER TO floreant;

--
-- TOC entry 6293 (class 0 OID 0)
-- Dependencies: 343
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_efectivo_id_seq OWNED BY precorte_efectivo.id;


--
-- TOC entry 344 (class 1259 OID 153199)
-- Name: precorte_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE precorte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE precorte_id_seq OWNER TO floreant;

--
-- TOC entry 6294 (class 0 OID 0)
-- Dependencies: 344
-- Name: precorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_id_seq OWNED BY precorte.id;


--
-- TOC entry 345 (class 1259 OID 153201)
-- Name: precorte_otros; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE precorte_otros (
    id bigint NOT NULL,
    precorte_id bigint NOT NULL,
    tipo text NOT NULL,
    monto numeric(12,2) DEFAULT 0 NOT NULL,
    referencia text,
    evidencia_url text,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE precorte_otros OWNER TO floreant;

--
-- TOC entry 346 (class 1259 OID 153209)
-- Name: precorte_otros_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE precorte_otros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE precorte_otros_id_seq OWNER TO floreant;

--
-- TOC entry 6295 (class 0 OID 0)
-- Dependencies: 346
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_otros_id_seq OWNED BY precorte_otros.id;


--
-- TOC entry 347 (class 1259 OID 153211)
-- Name: prod_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE prod_cab (
    id bigint NOT NULL,
    sol_id bigint,
    fecha_programada date NOT NULL,
    estado character varying(16) DEFAULT 'PROGRAMADA'::character varying NOT NULL,
    creada_por integer NOT NULL,
    aprobada_por integer,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE prod_cab OWNER TO postgres;

--
-- TOC entry 348 (class 1259 OID 153216)
-- Name: prod_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE prod_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE prod_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6296 (class 0 OID 0)
-- Dependencies: 348
-- Name: prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_cab_id_seq OWNED BY prod_cab.id;


--
-- TOC entry 349 (class 1259 OID 153218)
-- Name: prod_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE prod_det (
    id bigint NOT NULL,
    prod_id bigint,
    sr_id integer NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    rendimiento numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE prod_det OWNER TO postgres;

--
-- TOC entry 350 (class 1259 OID 153222)
-- Name: prod_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE prod_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE prod_det_id_seq OWNER TO postgres;

--
-- TOC entry 6297 (class 0 OID 0)
-- Dependencies: 350
-- Name: prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_det_id_seq OWNED BY prod_det.id;


--
-- TOC entry 351 (class 1259 OID 153224)
-- Name: production_order_inputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_order_inputs (
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


ALTER TABLE production_order_inputs OWNER TO postgres;

--
-- TOC entry 352 (class 1259 OID 153230)
-- Name: production_order_inputs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE production_order_inputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE production_order_inputs_id_seq OWNER TO postgres;

--
-- TOC entry 6298 (class 0 OID 0)
-- Dependencies: 352
-- Name: production_order_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_inputs_id_seq OWNED BY production_order_inputs.id;


--
-- TOC entry 353 (class 1259 OID 153232)
-- Name: production_order_outputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_order_outputs (
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


ALTER TABLE production_order_outputs OWNER TO postgres;

--
-- TOC entry 354 (class 1259 OID 153238)
-- Name: production_order_outputs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE production_order_outputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE production_order_outputs_id_seq OWNER TO postgres;

--
-- TOC entry 6299 (class 0 OID 0)
-- Dependencies: 354
-- Name: production_order_outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_outputs_id_seq OWNED BY production_order_outputs.id;


--
-- TOC entry 355 (class 1259 OID 153240)
-- Name: production_orders; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_orders (
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


ALTER TABLE production_orders OWNER TO postgres;

--
-- TOC entry 356 (class 1259 OID 153250)
-- Name: production_orders_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE production_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE production_orders_id_seq OWNER TO postgres;

--
-- TOC entry 6300 (class 0 OID 0)
-- Dependencies: 356
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_orders_id_seq OWNED BY production_orders.id;


--
-- TOC entry 357 (class 1259 OID 153252)
-- Name: proveedor; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE proveedor (
    id text NOT NULL,
    nombre text NOT NULL,
    rfc text,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE proveedor OWNER TO postgres;

--
-- TOC entry 358 (class 1259 OID 153259)
-- Name: purchase_documents; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_documents (
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


ALTER TABLE purchase_documents OWNER TO postgres;

--
-- TOC entry 359 (class 1259 OID 153265)
-- Name: purchase_documents_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_documents_id_seq OWNER TO postgres;

--
-- TOC entry 6301 (class 0 OID 0)
-- Dependencies: 359
-- Name: purchase_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_documents_id_seq OWNED BY purchase_documents.id;


--
-- TOC entry 360 (class 1259 OID 153267)
-- Name: purchase_order_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_order_lines (
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


ALTER TABLE purchase_order_lines OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 153275)
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_order_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_order_lines_id_seq OWNER TO postgres;

--
-- TOC entry 6302 (class 0 OID 0)
-- Dependencies: 361
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_order_lines_id_seq OWNED BY purchase_order_lines.id;


--
-- TOC entry 362 (class 1259 OID 153277)
-- Name: purchase_orders; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_orders (
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


ALTER TABLE purchase_orders OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 153288)
-- Name: purchase_orders_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_orders_id_seq OWNER TO postgres;

--
-- TOC entry 6303 (class 0 OID 0)
-- Dependencies: 363
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_orders_id_seq OWNED BY purchase_orders.id;


--
-- TOC entry 364 (class 1259 OID 153290)
-- Name: purchase_request_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_request_lines (
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


ALTER TABLE purchase_request_lines OWNER TO postgres;

--
-- TOC entry 365 (class 1259 OID 153297)
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_request_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_request_lines_id_seq OWNER TO postgres;

--
-- TOC entry 6304 (class 0 OID 0)
-- Dependencies: 365
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_request_lines_id_seq OWNED BY purchase_request_lines.id;


--
-- TOC entry 366 (class 1259 OID 153299)
-- Name: purchase_requests; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_requests (
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


ALTER TABLE purchase_requests OWNER TO postgres;

--
-- TOC entry 6305 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.fecha_requerida IS 'Fecha límite operativa';


--
-- TOC entry 6306 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- TOC entry 6307 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- TOC entry 6308 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- TOC entry 6309 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.origen_suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.origen_suggestion_id IS 'FK a purchase_suggestions - si fue generada automáticamente';


--
-- TOC entry 367 (class 1259 OID 153309)
-- Name: purchase_requests_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_requests_id_seq OWNER TO postgres;

--
-- TOC entry 6310 (class 0 OID 0)
-- Dependencies: 367
-- Name: purchase_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_requests_id_seq OWNED BY purchase_requests.id;


--
-- TOC entry 368 (class 1259 OID 153311)
-- Name: purchase_suggestion_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_suggestion_lines (
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


ALTER TABLE purchase_suggestion_lines OWNER TO postgres;

--
-- TOC entry 6311 (class 0 OID 0)
-- Dependencies: 368
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- TOC entry 6312 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- TOC entry 6313 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- TOC entry 6314 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- TOC entry 6315 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- TOC entry 6316 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- TOC entry 6317 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- TOC entry 6318 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- TOC entry 6319 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.proveedor_sugerido_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.proveedor_sugerido_id IS 'FK a selemti.cat_proveedores.id';


--
-- TOC entry 369 (class 1259 OID 153321)
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_suggestion_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_suggestion_lines_id_seq OWNER TO postgres;

--
-- TOC entry 6320 (class 0 OID 0)
-- Dependencies: 369
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestion_lines_id_seq OWNED BY purchase_suggestion_lines.id;


--
-- TOC entry 370 (class 1259 OID 153323)
-- Name: purchase_suggestions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_suggestions (
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


ALTER TABLE purchase_suggestions OWNER TO postgres;

--
-- TOC entry 6321 (class 0 OID 0)
-- Dependencies: 370
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- TOC entry 6322 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- TOC entry 6323 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- TOC entry 6324 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- TOC entry 6325 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- TOC entry 6326 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6327 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6328 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- TOC entry 6329 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.dias_analisis; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.dias_analisis IS 'Días usados para calcular consumo promedio';


--
-- TOC entry 371 (class 1259 OID 153337)
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_suggestions_id_seq OWNER TO postgres;

--
-- TOC entry 6330 (class 0 OID 0)
-- Dependencies: 371
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestions_id_seq OWNED BY purchase_suggestions.id;


--
-- TOC entry 372 (class 1259 OID 153339)
-- Name: purchase_vendor_quote_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_vendor_quote_lines (
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


ALTER TABLE purchase_vendor_quote_lines OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 153346)
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_vendor_quote_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_vendor_quote_lines_id_seq OWNER TO postgres;

--
-- TOC entry 6331 (class 0 OID 0)
-- Dependencies: 373
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quote_lines_id_seq OWNED BY purchase_vendor_quote_lines.id;


--
-- TOC entry 374 (class 1259 OID 153348)
-- Name: purchase_vendor_quotes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_vendor_quotes (
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


ALTER TABLE purchase_vendor_quotes OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 153360)
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE purchase_vendor_quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_vendor_quotes_id_seq OWNER TO postgres;

--
-- TOC entry 6332 (class 0 OID 0)
-- Dependencies: 375
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quotes_id_seq OWNED BY purchase_vendor_quotes.id;


--
-- TOC entry 376 (class 1259 OID 153362)
-- Name: recalc_log; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recalc_log (
    id bigint NOT NULL,
    job_id bigint,
    step text,
    started_ts timestamp without time zone,
    ended_ts timestamp without time zone,
    ok boolean,
    details json
);


ALTER TABLE recalc_log OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 153368)
-- Name: recalc_log_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recalc_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recalc_log_id_seq OWNER TO postgres;

--
-- TOC entry 6333 (class 0 OID 0)
-- Dependencies: 377
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


--
-- TOC entry 378 (class 1259 OID 153370)
-- Name: recepcion_adjuntos; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recepcion_adjuntos (
    id bigint NOT NULL,
    recepcion_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    file_url character varying(255) NOT NULL,
    notas text,
    uploaded_by bigint,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE recepcion_adjuntos OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 153376)
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recepcion_adjuntos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepcion_adjuntos_id_seq OWNER TO postgres;

--
-- TOC entry 6334 (class 0 OID 0)
-- Dependencies: 379
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_adjuntos_id_seq OWNED BY recepcion_adjuntos.id;


--
-- TOC entry 380 (class 1259 OID 153378)
-- Name: recepcion_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recepcion_cab (
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


ALTER TABLE recepcion_cab OWNER TO postgres;

--
-- TOC entry 381 (class 1259 OID 153387)
-- Name: recepcion_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recepcion_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepcion_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6335 (class 0 OID 0)
-- Dependencies: 381
-- Name: recepcion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_cab_id_seq OWNED BY recepcion_cab.id;


--
-- TOC entry 382 (class 1259 OID 153389)
-- Name: recepcion_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recepcion_det (
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


ALTER TABLE recepcion_det OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 153397)
-- Name: recepcion_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recepcion_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepcion_det_id_seq OWNER TO postgres;

--
-- TOC entry 6336 (class 0 OID 0)
-- Dependencies: 383
-- Name: recepcion_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_det_id_seq OWNED BY recepcion_det.id;


--
-- TOC entry 384 (class 1259 OID 153399)
-- Name: receta; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta (
    id bigint NOT NULL,
    codigo text,
    nombre text NOT NULL,
    porciones numeric(12,4) DEFAULT 1.0 NOT NULL,
    pvp_objetivo numeric(12,4),
    activo boolean DEFAULT true NOT NULL,
    meta jsonb
);


ALTER TABLE receta OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 153407)
-- Name: receta_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE receta_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE receta_det_id_seq OWNER TO postgres;

--
-- TOC entry 6337 (class 0 OID 0)
-- Dependencies: 385
-- Name: receta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_det_id_seq OWNED BY receta_det.id;


--
-- TOC entry 386 (class 1259 OID 153409)
-- Name: receta_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE receta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE receta_id_seq OWNER TO postgres;

--
-- TOC entry 6338 (class 0 OID 0)
-- Dependencies: 386
-- Name: receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_id_seq OWNED BY receta.id;


--
-- TOC entry 387 (class 1259 OID 153411)
-- Name: receta_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_insumo (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    cantidad numeric(14,6) NOT NULL
);


ALTER TABLE receta_insumo OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 153414)
-- Name: receta_insumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE receta_insumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE receta_insumo_id_seq OWNER TO postgres;

--
-- TOC entry 6339 (class 0 OID 0)
-- Dependencies: 388
-- Name: receta_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_insumo_id_seq OWNED BY receta_insumo.id;


--
-- TOC entry 389 (class 1259 OID 153416)
-- Name: receta_shadow; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_shadow (
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


ALTER TABLE receta_shadow OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 153429)
-- Name: receta_shadow_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE receta_shadow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE receta_shadow_id_seq OWNER TO postgres;

--
-- TOC entry 6340 (class 0 OID 0)
-- Dependencies: 390
-- Name: receta_shadow_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_shadow_id_seq OWNED BY receta_shadow.id;


--
-- TOC entry 391 (class 1259 OID 153431)
-- Name: receta_version_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE receta_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE receta_version_id_seq OWNER TO postgres;

--
-- TOC entry 6341 (class 0 OID 0)
-- Dependencies: 391
-- Name: receta_version_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_version_id_seq OWNED BY receta_version.id;


--
-- TOC entry 392 (class 1259 OID 153433)
-- Name: recipe_cost_history; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_cost_history (
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


ALTER TABLE recipe_cost_history OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 153441)
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_cost_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_cost_history_id_seq OWNER TO postgres;

--
-- TOC entry 6342 (class 0 OID 0)
-- Dependencies: 393
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_history_id_seq OWNED BY recipe_cost_history.id;


--
-- TOC entry 394 (class 1259 OID 153443)
-- Name: recipe_cost_snapshots; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_cost_snapshots (
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


ALTER TABLE recipe_cost_snapshots OWNER TO postgres;

--
-- TOC entry 6343 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE recipe_cost_snapshots; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE recipe_cost_snapshots IS 'Snapshots historicos de costos de recetas para auditoria y performance';


--
-- TOC entry 6344 (class 0 OID 0)
-- Dependencies: 394
-- Name: COLUMN recipe_cost_snapshots.cost_breakdown; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN recipe_cost_snapshots.cost_breakdown IS 'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';


--
-- TOC entry 6345 (class 0 OID 0)
-- Dependencies: 394
-- Name: COLUMN recipe_cost_snapshots.reason; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN recipe_cost_snapshots.reason IS 'MANUAL: Creado manualmente por usuario\n     AUTO_THRESHOLD: Creado automaticamente por cambio >2% en costo\n     INGREDIENT_CHANGE: Creado por modificacion de ingredientes\n     SCHEDULED: Creado por job programado (cierre de dia)';


--
-- TOC entry 395 (class 1259 OID 153454)
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_cost_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_cost_snapshots_id_seq OWNER TO postgres;

--
-- TOC entry 6346 (class 0 OID 0)
-- Dependencies: 395
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_snapshots_id_seq OWNED BY recipe_cost_snapshots.id;


--
-- TOC entry 396 (class 1259 OID 153456)
-- Name: recipe_extended_cost_history; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_extended_cost_history (
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


ALTER TABLE recipe_extended_cost_history OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 153469)
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_extended_cost_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_extended_cost_history_id_seq OWNER TO postgres;

--
-- TOC entry 6347 (class 0 OID 0)
-- Dependencies: 397
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_extended_cost_history_id_seq OWNED BY recipe_extended_cost_history.id;


--
-- TOC entry 398 (class 1259 OID 153471)
-- Name: recipe_labor_steps; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_labor_steps (
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


ALTER TABLE recipe_labor_steps OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 153479)
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_labor_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_labor_steps_id_seq OWNER TO postgres;

--
-- TOC entry 6348 (class 0 OID 0)
-- Dependencies: 399
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_labor_steps_id_seq OWNED BY recipe_labor_steps.id;


--
-- TOC entry 400 (class 1259 OID 153481)
-- Name: recipe_overhead_allocations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_overhead_allocations (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    overhead_id bigint NOT NULL,
    valor numeric(18,6),
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE recipe_overhead_allocations OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 153487)
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_overhead_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_overhead_allocations_id_seq OWNER TO postgres;

--
-- TOC entry 6349 (class 0 OID 0)
-- Dependencies: 401
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_overhead_allocations_id_seq OWNED BY recipe_overhead_allocations.id;


--
-- TOC entry 402 (class 1259 OID 153489)
-- Name: recipe_version_items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_version_items (
    id bigint NOT NULL,
    recipe_version_id bigint NOT NULL,
    item_id character varying(20) NOT NULL,
    qty numeric(14,6) NOT NULL,
    uom_receta character varying(20) NOT NULL
);


ALTER TABLE recipe_version_items OWNER TO postgres;

--
-- TOC entry 403 (class 1259 OID 153492)
-- Name: recipe_version_items_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_version_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_version_items_id_seq OWNER TO postgres;

--
-- TOC entry 6350 (class 0 OID 0)
-- Dependencies: 403
-- Name: recipe_version_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_version_items_id_seq OWNED BY recipe_version_items.id;


--
-- TOC entry 404 (class 1259 OID 153494)
-- Name: recipe_versions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_versions (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    version_no integer NOT NULL,
    notes text,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE recipe_versions OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 153502)
-- Name: recipe_versions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE recipe_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recipe_versions_id_seq OWNER TO postgres;

--
-- TOC entry 6351 (class 0 OID 0)
-- Dependencies: 405
-- Name: recipe_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_versions_id_seq OWNED BY recipe_versions.id;


--
-- TOC entry 406 (class 1259 OID 153504)
-- Name: replenishment_suggestions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE replenishment_suggestions (
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


ALTER TABLE replenishment_suggestions OWNER TO postgres;

--
-- TOC entry 6352 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- TOC entry 6353 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- TOC entry 6354 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- TOC entry 6355 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- TOC entry 6356 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.item_id IS 'FK to items.id';


--
-- TOC entry 6357 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- TOC entry 6358 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- TOC entry 6359 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- TOC entry 6360 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- TOC entry 6361 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- TOC entry 6362 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- TOC entry 6363 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- TOC entry 6364 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- TOC entry 6365 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- TOC entry 6366 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- TOC entry 6367 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- TOC entry 6368 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.notas IS 'Notas del usuario';


--
-- TOC entry 6369 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.meta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.meta IS 'Metadata: proveedor preferido, evento, etc.';


--
-- TOC entry 407 (class 1259 OID 153514)
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE replenishment_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE replenishment_suggestions_id_seq OWNER TO postgres;

--
-- TOC entry 6370 (class 0 OID 0)
-- Dependencies: 407
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE replenishment_suggestions_id_seq OWNED BY replenishment_suggestions.id;


--
-- TOC entry 481 (class 1259 OID 156906)
-- Name: report_definitions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE report_definitions (
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


ALTER TABLE report_definitions OWNER TO postgres;

--
-- TOC entry 480 (class 1259 OID 156904)
-- Name: report_definitions_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE report_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE report_definitions_id_seq OWNER TO postgres;

--
-- TOC entry 6371 (class 0 OID 0)
-- Dependencies: 480
-- Name: report_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_definitions_id_seq OWNED BY report_definitions.id;


--
-- TOC entry 408 (class 1259 OID 153525)
-- Name: report_favorites; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE report_favorites (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    report_key character varying(120) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE report_favorites OWNER TO postgres;

--
-- TOC entry 409 (class 1259 OID 153531)
-- Name: report_favorites_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE report_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE report_favorites_id_seq OWNER TO postgres;

--
-- TOC entry 6372 (class 0 OID 0)
-- Dependencies: 409
-- Name: report_favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_favorites_id_seq OWNED BY report_favorites.id;


--
-- TOC entry 483 (class 1259 OID 156920)
-- Name: report_runs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE report_runs (
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


ALTER TABLE report_runs OWNER TO postgres;

--
-- TOC entry 482 (class 1259 OID 156918)
-- Name: report_runs_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE report_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE report_runs_id_seq OWNER TO postgres;

--
-- TOC entry 6373 (class 0 OID 0)
-- Dependencies: 482
-- Name: report_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_runs_id_seq OWNED BY report_runs.id;


--
-- TOC entry 410 (class 1259 OID 153542)
-- Name: rol; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE rol (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE rol OWNER TO postgres;

--
-- TOC entry 411 (class 1259 OID 153548)
-- Name: rol_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE rol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rol_id_seq OWNER TO postgres;

--
-- TOC entry 6374 (class 0 OID 0)
-- Dependencies: 411
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE rol_id_seq OWNED BY rol.id;


--
-- TOC entry 412 (class 1259 OID 153550)
-- Name: role_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE role_has_permissions OWNER TO postgres;

--
-- TOC entry 413 (class 1259 OID 153553)
-- Name: roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    display_name character varying(255),
    description text,
    color character varying(7)
);


ALTER TABLE roles OWNER TO postgres;

--
-- TOC entry 6375 (class 0 OID 0)
-- Dependencies: 413
-- Name: TABLE roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE roles IS 'Tabla de roles (Spatie Permission) - Consolidada en Phase 2.1';


--
-- TOC entry 414 (class 1259 OID 153559)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE roles_id_seq OWNER TO postgres;

--
-- TOC entry 6376 (class 0 OID 0)
-- Dependencies: 414
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- TOC entry 415 (class 1259 OID 153561)
-- Name: seq_cat_codigo; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE seq_cat_codigo
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_cat_codigo OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 152916)
-- Name: sesion_cajon; Type: TABLE; Schema: selemti; Owner: floreant
--

CREATE TABLE sesion_cajon (
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
    CONSTRAINT sesion_cajon_estatus_check CHECK ((estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'CERRADA'::text])))
);


ALTER TABLE sesion_cajon OWNER TO floreant;

--
-- TOC entry 416 (class 1259 OID 153563)
-- Name: sesion_cajon_id_seq; Type: SEQUENCE; Schema: selemti; Owner: floreant
--

CREATE SEQUENCE sesion_cajon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sesion_cajon_id_seq OWNER TO floreant;

--
-- TOC entry 6377 (class 0 OID 0)
-- Dependencies: 416
-- Name: sesion_cajon_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE sesion_cajon_id_seq OWNED BY sesion_cajon.id;


--
-- TOC entry 417 (class 1259 OID 153565)
-- Name: sessions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE sessions OWNER TO postgres;

--
-- TOC entry 418 (class 1259 OID 153571)
-- Name: sol_prod_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sol_prod_cab (
    id bigint NOT NULL,
    sucursal_id integer NOT NULL,
    fecha date DEFAULT ('now'::text)::date NOT NULL,
    estado character varying(16) DEFAULT 'SOLICITADA'::character varying NOT NULL,
    solicitada_por integer NOT NULL,
    autorizada_por integer,
    observaciones text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE sol_prod_cab OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 153580)
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE sol_prod_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sol_prod_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6378 (class 0 OID 0)
-- Dependencies: 419
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_cab_id_seq OWNED BY sol_prod_cab.id;


--
-- TOC entry 420 (class 1259 OID 153582)
-- Name: sol_prod_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sol_prod_det (
    id bigint NOT NULL,
    sol_id bigint,
    plu integer NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    cantidad_autorizada numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE sol_prod_det OWNER TO postgres;

--
-- TOC entry 421 (class 1259 OID 153586)
-- Name: sol_prod_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE sol_prod_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sol_prod_det_id_seq OWNER TO postgres;

--
-- TOC entry 6379 (class 0 OID 0)
-- Dependencies: 421
-- Name: sol_prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_det_id_seq OWNED BY sol_prod_det.id;


--
-- TOC entry 422 (class 1259 OID 153588)
-- Name: stock_policy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE stock_policy (
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


ALTER TABLE stock_policy OWNER TO postgres;

--
-- TOC entry 423 (class 1259 OID 153598)
-- Name: stock_policy_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE stock_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stock_policy_id_seq OWNER TO postgres;

--
-- TOC entry 6380 (class 0 OID 0)
-- Dependencies: 423
-- Name: stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE stock_policy_id_seq OWNED BY stock_policy.id;


--
-- TOC entry 424 (class 1259 OID 153600)
-- Name: sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE sucursal OWNER TO postgres;

--
-- TOC entry 425 (class 1259 OID 153607)
-- Name: sucursal_almacen_terminal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sucursal_almacen_terminal (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text NOT NULL,
    terminal_id integer,
    location text,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE sucursal_almacen_terminal OWNER TO postgres;

--
-- TOC entry 426 (class 1259 OID 153615)
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE sucursal_almacen_terminal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sucursal_almacen_terminal_id_seq OWNER TO postgres;

--
-- TOC entry 6381 (class 0 OID 0)
-- Dependencies: 426
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sucursal_almacen_terminal_id_seq OWNED BY sucursal_almacen_terminal.id;


--
-- TOC entry 427 (class 1259 OID 153617)
-- Name: ticket_det_consumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE ticket_det_consumo (
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


ALTER TABLE ticket_det_consumo OWNER TO postgres;

--
-- TOC entry 428 (class 1259 OID 153626)
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE ticket_det_consumo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_det_consumo_id_seq OWNER TO postgres;

--
-- TOC entry 6382 (class 0 OID 0)
-- Dependencies: 428
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


--
-- TOC entry 429 (class 1259 OID 153628)
-- Name: ticket_item_modifiers; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE ticket_item_modifiers (
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


ALTER TABLE ticket_item_modifiers OWNER TO postgres;

--
-- TOC entry 6383 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- TOC entry 6384 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- TOC entry 6385 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN ticket_item_modifiers.precio_extra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.precio_extra IS 'Sobrecargo aplicado por el POS.';


--
-- TOC entry 430 (class 1259 OID 153633)
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE ticket_item_modifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_modifiers_id_seq OWNER TO postgres;

--
-- TOC entry 6386 (class 0 OID 0)
-- Dependencies: 430
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_item_modifiers_id_seq OWNED BY ticket_item_modifiers.id;


--
-- TOC entry 431 (class 1259 OID 153635)
-- Name: ticket_venta_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE ticket_venta_cab (
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


ALTER TABLE ticket_venta_cab OWNER TO postgres;

--
-- TOC entry 432 (class 1259 OID 153643)
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE ticket_venta_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_venta_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6387 (class 0 OID 0)
-- Dependencies: 432
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_cab_id_seq OWNED BY ticket_venta_cab.id;


--
-- TOC entry 433 (class 1259 OID 153645)
-- Name: ticket_venta_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE ticket_venta_det (
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


ALTER TABLE ticket_venta_det OWNER TO postgres;

--
-- TOC entry 434 (class 1259 OID 153655)
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE ticket_venta_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_venta_det_id_seq OWNER TO postgres;

--
-- TOC entry 6388 (class 0 OID 0)
-- Dependencies: 434
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


--
-- TOC entry 435 (class 1259 OID 153657)
-- Name: transfer_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE transfer_cab (
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


ALTER TABLE transfer_cab OWNER TO postgres;

--
-- TOC entry 436 (class 1259 OID 153662)
-- Name: transfer_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE transfer_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE transfer_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6389 (class 0 OID 0)
-- Dependencies: 436
-- Name: transfer_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_cab_id_seq OWNED BY transfer_cab.id;


--
-- TOC entry 437 (class 1259 OID 153664)
-- Name: transfer_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE transfer_det (
    id bigint NOT NULL,
    transfer_id bigint,
    item_id character varying(20) NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    cantidad_despachada numeric(12,3),
    cantidad_recibida numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE transfer_det OWNER TO postgres;

--
-- TOC entry 438 (class 1259 OID 153668)
-- Name: transfer_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE transfer_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE transfer_det_id_seq OWNER TO postgres;

--
-- TOC entry 6390 (class 0 OID 0)
-- Dependencies: 438
-- Name: transfer_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_det_id_seq OWNED BY transfer_det.id;


--
-- TOC entry 439 (class 1259 OID 153670)
-- Name: traspaso_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE traspaso_cab (
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


ALTER TABLE traspaso_cab OWNER TO postgres;

--
-- TOC entry 440 (class 1259 OID 153679)
-- Name: traspaso_cab_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE traspaso_cab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE traspaso_cab_id_seq OWNER TO postgres;

--
-- TOC entry 6391 (class 0 OID 0)
-- Dependencies: 440
-- Name: traspaso_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_cab_id_seq OWNED BY traspaso_cab.id;


--
-- TOC entry 441 (class 1259 OID 153681)
-- Name: traspaso_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE traspaso_det (
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


ALTER TABLE traspaso_det OWNER TO postgres;

--
-- TOC entry 442 (class 1259 OID 153686)
-- Name: traspaso_det_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE traspaso_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE traspaso_det_id_seq OWNER TO postgres;

--
-- TOC entry 6392 (class 0 OID 0)
-- Dependencies: 442
-- Name: traspaso_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_det_id_seq OWNED BY traspaso_det.id;


--
-- TOC entry 443 (class 1259 OID 153688)
-- Name: unidad_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW unidad_medida AS
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
   FROM cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE unidad_medida OWNER TO postgres;

--
-- TOC entry 6393 (class 0 OID 0)
-- Dependencies: 443
-- Name: VIEW unidad_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidad_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidad_medida';


--
-- TOC entry 444 (class 1259 OID 153693)
-- Name: unidad_medida_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE unidad_medida_legacy (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    tipo text NOT NULL,
    es_base boolean DEFAULT false NOT NULL,
    factor_a_base numeric(14,6) DEFAULT 1.0 NOT NULL,
    decimales integer DEFAULT 2 NOT NULL,
    CONSTRAINT unidad_medida_tipo_check CHECK ((tipo = ANY (ARRAY['PESO'::text, 'VOLUMEN'::text, 'UNIDAD'::text, 'TIEMPO'::text])))
);


ALTER TABLE unidad_medida_legacy OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 153703)
-- Name: unidad_medida_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE unidad_medida_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE unidad_medida_id_seq OWNER TO postgres;

--
-- TOC entry 6394 (class 0 OID 0)
-- Dependencies: 445
-- Name: unidad_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidad_medida_id_seq OWNED BY unidad_medida_legacy.id;


--
-- TOC entry 446 (class 1259 OID 153705)
-- Name: unidades_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW unidades_medida AS
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
   FROM cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE unidades_medida OWNER TO postgres;

--
-- TOC entry 6395 (class 0 OID 0)
-- Dependencies: 446
-- Name: VIEW unidades_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidades_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidades_medida con categoria';


--
-- TOC entry 447 (class 1259 OID 153710)
-- Name: unidades_medida_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE unidades_medida_legacy (
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


ALTER TABLE unidades_medida_legacy OWNER TO postgres;

--
-- TOC entry 448 (class 1259 OID 153721)
-- Name: unidades_medida_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE unidades_medida_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE unidades_medida_id_seq OWNER TO postgres;

--
-- TOC entry 6396 (class 0 OID 0)
-- Dependencies: 448
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida_legacy.id;


--
-- TOC entry 449 (class 1259 OID 153723)
-- Name: uom_conversion; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW uom_conversion AS
 SELECT (cat_uom_conversion.id)::integer AS id,
    (cat_uom_conversion.origen_id)::integer AS origen_id,
    (cat_uom_conversion.destino_id)::integer AS destino_id,
    (cat_uom_conversion.factor)::numeric(14,6) AS factor
   FROM cat_uom_conversion;


ALTER TABLE uom_conversion OWNER TO postgres;

--
-- TOC entry 6397 (class 0 OID 0)
-- Dependencies: 449
-- Name: VIEW uom_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW uom_conversion IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy uom_conversion';


--
-- TOC entry 450 (class 1259 OID 153727)
-- Name: uom_conversion_legacy; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE uom_conversion_legacy (
    id integer NOT NULL,
    origen_id integer NOT NULL,
    destino_id integer NOT NULL,
    factor numeric(14,6) NOT NULL,
    CONSTRAINT uom_conversion_check CHECK ((origen_id <> destino_id)),
    CONSTRAINT uom_conversion_factor_check CHECK ((factor > (0)::numeric))
);


ALTER TABLE uom_conversion_legacy OWNER TO postgres;

--
-- TOC entry 451 (class 1259 OID 153732)
-- Name: uom_conversion_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE uom_conversion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uom_conversion_id_seq OWNER TO postgres;

--
-- TOC entry 6398 (class 0 OID 0)
-- Dependencies: 451
-- Name: uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE uom_conversion_id_seq OWNED BY uom_conversion_legacy.id;


--
-- TOC entry 452 (class 1259 OID 153734)
-- Name: user_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE user_roles (
    user_id integer NOT NULL,
    role_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer,
    CONSTRAINT user_roles_role_id_check CHECK (((role_id)::text = ANY (ARRAY[('GERENTE'::character varying)::text, ('CHEF'::character varying)::text, ('ALMACEN'::character varying)::text, ('CAJERO'::character varying)::text, ('AUDITOR'::character varying)::text, ('SISTEMA'::character varying)::text])))
);


ALTER TABLE user_roles OWNER TO postgres;

--
-- TOC entry 6399 (class 0 OID 0)
-- Dependencies: 452
-- Name: TABLE user_roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE user_roles IS 'AsignaciÃ³n de roles a usuarios.';


--
-- TOC entry 453 (class 1259 OID 153739)
-- Name: users; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE users (
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


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 6400 (class 0 OID 0)
-- Dependencies: 453
-- Name: TABLE users; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE users IS 'Tabla canÃ³nica de usuarios del sistema - Consolidada en Phase 2.1';


--
-- TOC entry 454 (class 1259 OID 153755)
-- Name: users_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO postgres;

--
-- TOC entry 6401 (class 0 OID 0)
-- Dependencies: 454
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 455 (class 1259 OID 153757)
-- Name: usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE usuario (
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


ALTER TABLE usuario OWNER TO postgres;

--
-- TOC entry 456 (class 1259 OID 153765)
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usuario_id_seq OWNER TO postgres;

--
-- TOC entry 6402 (class 0 OID 0)
-- Dependencies: 456
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE usuario_id_seq OWNED BY usuario.id;


--
-- TOC entry 457 (class 1259 OID 153767)
-- Name: v_almacen; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_almacen AS
 SELECT cat_almacenes.clave AS id,
    (cat_almacenes.sucursal_id)::text AS sucursal_id,
    cat_almacenes.nombre,
    cat_almacenes.activo
   FROM cat_almacenes;


ALTER TABLE v_almacen OWNER TO postgres;

--
-- TOC entry 6403 (class 0 OID 0)
-- Dependencies: 457
-- Name: VIEW v_almacen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_almacen IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy almacen';


--
-- TOC entry 458 (class 1259 OID 153771)
-- Name: v_bodega; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_bodega AS
 SELECT (cat_almacenes.id)::integer AS id,
    (cat_almacenes.sucursal_id)::text AS sucursal_id,
    cat_almacenes.clave AS codigo,
    cat_almacenes.nombre
   FROM cat_almacenes
  WHERE ((cat_almacenes.clave)::text ~ '^[0-9]+$'::text);


ALTER TABLE v_bodega OWNER TO postgres;

--
-- TOC entry 6404 (class 0 OID 0)
-- Dependencies: 458
-- Name: VIEW v_bodega; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_bodega IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy bodega';


--
-- TOC entry 459 (class 1259 OID 153775)
-- Name: v_cat_unidades_compat; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_cat_unidades_compat AS
 SELECT unidades_medida_legacy.id,
    now() AS created_at,
    now() AS updated_at,
    unidades_medida_legacy.codigo AS clave,
    unidades_medida_legacy.nombre,
    true AS activo
   FROM unidades_medida_legacy
  WHERE ((unidades_medida_legacy.codigo)::text = ANY (ARRAY[('KG'::character varying)::text, ('L'::character varying)::text, ('LT'::character varying)::text, ('PZ'::character varying)::text, ('EA'::character varying)::text, ('G'::character varying)::text, ('ML'::character varying)::text, ('OZ'::character varying)::text, ('LB'::character varying)::text, ('GAL'::character varying)::text]));


ALTER TABLE v_cat_unidades_compat OWNER TO postgres;

--
-- TOC entry 6405 (class 0 OID 0)
-- Dependencies: 459
-- Name: VIEW v_cat_unidades_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_cat_unidades_compat IS 'Vista de compatibilidad para cat_unidades. Mapea a unidades_medida_legacy (canónica)';


--
-- TOC entry 460 (class 1259 OID 153779)
-- Name: v_ingenieria_menu_completa; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_ingenieria_menu_completa AS
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
           FROM ticket_venta_det td
          WHERE ((td.item_id)::text = (rc.id)::text)) = 0) AS alerta_sin_ventas
   FROM receta_cab rc
  WHERE (rc.activo = true);


ALTER TABLE v_ingenieria_menu_completa OWNER TO postgres;

--
-- TOC entry 461 (class 1259 OID 153784)
-- Name: v_insumo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_insumo AS
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
   FROM items;


ALTER TABLE v_insumo OWNER TO postgres;

--
-- TOC entry 6406 (class 0 OID 0)
-- Dependencies: 461
-- Name: VIEW v_insumo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_insumo IS 'Vista de compatibilidad - Mapea items â†’ formato legacy insumo';


--
-- TOC entry 462 (class 1259 OID 153789)
-- Name: v_items_con_uom; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_items_con_uom AS
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
   FROM (items i
     LEFT JOIN unidades_medida_legacy um ON ((um.id = i.unidad_medida_id)));


ALTER TABLE v_items_con_uom OWNER TO postgres;

--
-- TOC entry 463 (class 1259 OID 153794)
-- Name: v_lote; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_lote AS
 SELECT inventory_batch.id,
    inventory_batch.item_id AS insumo_id_codigo,
    inventory_batch.lote_proveedor AS codigo,
    inventory_batch.fecha_recepcion,
    inventory_batch.fecha_caducidad,
    inventory_batch.cantidad_original AS cantidad_inicial,
    inventory_batch.cantidad_actual,
    inventory_batch.unit_cost AS costo_unitario
   FROM inventory_batch;


ALTER TABLE v_lote OWNER TO postgres;

--
-- TOC entry 6407 (class 0 OID 0)
-- Dependencies: 463
-- Name: VIEW v_lote; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_lote IS 'Vista de compatibilidad - Mapea inventory_batch â†’ formato legacy lote';


--
-- TOC entry 464 (class 1259 OID 153798)
-- Name: v_merma_por_item; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_merma_por_item AS
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
   FROM mov_inv m
  GROUP BY m.item_id, ((date_trunc('week'::text, m.ts))::date);


ALTER TABLE v_merma_por_item OWNER TO postgres;

--
-- TOC entry 465 (class 1259 OID 153803)
-- Name: v_receta; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_receta AS
 SELECT receta_cab.id,
    receta_cab.nombre_plato AS nombre,
    receta_cab.categoria_plato AS categoria,
    receta_cab.activo,
    receta_cab.costo_standard_porcion AS costo_total,
    (((receta_cab.precio_venta_sugerido - receta_cab.costo_standard_porcion) / NULLIF(receta_cab.costo_standard_porcion, (0)::numeric)) * (100)::numeric) AS margen_sugerido,
    receta_cab.precio_venta_sugerido AS precio_sugerido
   FROM receta_cab;


ALTER TABLE v_receta OWNER TO postgres;

--
-- TOC entry 6408 (class 0 OID 0)
-- Dependencies: 465
-- Name: VIEW v_receta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_receta IS 'Vista de compatibilidad - Mapea receta_cab â†’ formato legacy receta';


--
-- TOC entry 466 (class 1259 OID 153807)
-- Name: v_receta_insumo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_receta_insumo AS
 SELECT receta_det.id,
    receta_det.receta_version_id,
    receta_det.item_id AS insumo_id,
    receta_det.cantidad,
    receta_det.unidad_medida,
    0.00 AS costo_unitario,
    0.00 AS costo_total
   FROM receta_det;


ALTER TABLE v_receta_insumo OWNER TO postgres;

--
-- TOC entry 467 (class 1259 OID 153811)
-- Name: v_rol; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_rol AS
 SELECT (roles.id)::integer AS id,
    roles.name AS codigo,
    COALESCE(roles.display_name, roles.name) AS nombre
   FROM roles;


ALTER TABLE v_rol OWNER TO postgres;

--
-- TOC entry 6409 (class 0 OID 0)
-- Dependencies: 467
-- Name: VIEW v_rol; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_rol IS 'Vista de compatibilidad - Mapea roles â†’ formato legacy rol';


--
-- TOC entry 468 (class 1259 OID 153815)
-- Name: v_stock_actual; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_stock_actual AS
 SELECT i.id AS item_id,
    i.nombre,
    COALESCE(sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            WHEN ((m.tipo)::text = 'SALIDA'::text) THEN (- m.cantidad)
            ELSE (0)::numeric
        END), (0)::numeric) AS stock_actual
   FROM (items i
     LEFT JOIN mov_inv m ON (((i.id)::text = (m.item_id)::text)))
  GROUP BY i.id, i.nombre;


ALTER TABLE v_stock_actual OWNER TO postgres;

--
-- TOC entry 469 (class 1259 OID 153820)
-- Name: v_stock_brechas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_stock_brechas AS
 SELECT sp.sucursal_id,
    sp.almacen_id,
    sp.item_id,
    sp.min_qty,
    sp.max_qty,
    COALESCE(sa.stock_actual, (0)::numeric) AS stock_actual,
    GREATEST((sp.min_qty - COALESCE(sa.stock_actual, (0)::numeric)), (0)::numeric) AS qty_a_comprar
   FROM (stock_policy sp
     LEFT JOIN ( SELECT mov_inv.item_id,
            sum(
                CASE
                    WHEN ((mov_inv.tipo)::text = 'ENTRADA'::text) THEN mov_inv.cantidad
                    WHEN ((mov_inv.tipo)::text = ANY (ARRAY[('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO'::character varying)::text])) THEN (- mov_inv.cantidad)
                    ELSE (0)::numeric
                END) AS stock_actual
           FROM mov_inv
          GROUP BY mov_inv.item_id) sa ON (((sa.item_id)::text = sp.item_id)));


ALTER TABLE v_stock_brechas OWNER TO postgres;

--
-- TOC entry 470 (class 1259 OID 153825)
-- Name: v_sucursal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_sucursal AS
 SELECT cat_sucursales.clave AS id,
    cat_sucursales.nombre,
    cat_sucursales.activo
   FROM cat_sucursales;


ALTER TABLE v_sucursal OWNER TO postgres;

--
-- TOC entry 6410 (class 0 OID 0)
-- Dependencies: 470
-- Name: VIEW v_sucursal; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_sucursal IS 'Vista de compatibilidad - Mapea cat_sucursales â†’ formato legacy';


--
-- TOC entry 471 (class 1259 OID 153829)
-- Name: v_unidad_medida_singular_compat; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_unidad_medida_singular_compat AS
 SELECT unidades_medida_legacy.id,
    unidades_medida_legacy.codigo,
    unidades_medida_legacy.nombre,
    unidades_medida_legacy.tipo,
    unidades_medida_legacy.es_base,
    unidades_medida_legacy.factor_conversion_base AS factor_a_base,
    unidades_medida_legacy.decimales
   FROM unidades_medida_legacy;


ALTER TABLE v_unidad_medida_singular_compat OWNER TO postgres;

--
-- TOC entry 6411 (class 0 OID 0)
-- Dependencies: 471
-- Name: VIEW v_unidad_medida_singular_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_unidad_medida_singular_compat IS 'Vista de compatibilidad para unidad_medida_legacy (singular). Mapea a unidades_medida_legacy (canónica)';


--
-- TOC entry 472 (class 1259 OID 153833)
-- Name: v_usuario; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_usuario AS
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
   FROM users;


ALTER TABLE v_usuario OWNER TO postgres;

--
-- TOC entry 6412 (class 0 OID 0)
-- Dependencies: 472
-- Name: VIEW v_usuario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_usuario IS 'Vista de compatibilidad - Mapea users â†’ formato legacy usuario';


--
-- TOC entry 668 (class 1259 OID 158641)
-- Name: vw_sesion_descuentos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_descuentos AS
 WITH tk_win AS (
         SELECT s.id AS sesion_id,
            tk.id AS ticket_id
           FROM (sesion_cajon s
             JOIN public.ticket tk ON (((tk.terminal_id = s.terminal_id) AND (tk.owner_id = s.cajero_usuario_id) AND (tk.create_date >= s.apertura_ts) AND (tk.create_date < COALESCE(s.cierre_ts, now())))))
        ), td_agg AS (
         SELECT td.ticket_id,
            (sum(COALESCE(td.value, (0)::double precision)))::numeric AS sum_td
           FROM public.ticket_discount td
          GROUP BY td.ticket_id
        ), tid_agg AS (
         SELECT ti.ticket_id,
            (sum(COALESCE(tid.amount, (0)::double precision)))::numeric AS sum_tid
           FROM (public.ticket_item_discount tid
             JOIN public.ticket_item ti ON ((ti.id = tid.ticket_itemid)))
          GROUP BY ti.ticket_id
        )
 SELECT tw.sesion_id,
    (COALESCE(sum(td_agg.sum_td), (0)::numeric) + COALESCE(sum(tid_agg.sum_tid), (0)::numeric)) AS descuentos
   FROM ((tk_win tw
     LEFT JOIN td_agg ON ((td_agg.ticket_id = tw.ticket_id)))
     LEFT JOIN tid_agg ON ((tid_agg.ticket_id = tw.ticket_id)))
  GROUP BY tw.sesion_id;


ALTER TABLE vw_sesion_descuentos OWNER TO postgres;

--
-- TOC entry 625 (class 1259 OID 158077)
-- Name: vw_sesion_dpr; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_dpr AS
 WITH s AS (
         SELECT sesion_cajon.id,
            sesion_cajon.terminal_id,
            sesion_cajon.cajero_usuario_id,
            sesion_cajon.apertura_ts,
            COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts
           FROM sesion_cajon
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


ALTER TABLE vw_sesion_dpr OWNER TO postgres;

--
-- TOC entry 662 (class 1259 OID 158587)
-- Name: vw_sesion_reembolsos_efectivo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_reembolsos_efectivo AS
 WITH tx AS (
         SELECT s.id AS sesion_id,
            t.payment_sub_type,
            COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp,
            (t.amount)::numeric AS monto
           FROM ((sesion_cajon s
             JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
             LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
        )
 SELECT tx.sesion_id,
    (sum(
        CASE
            WHEN ((tx.codigo_fp = 'REFUND'::text) AND (upper((COALESCE(tx.payment_sub_type, ''::character varying))::text) = 'CASH'::text)) THEN tx.monto
            ELSE (0)::numeric
        END))::numeric(12,2) AS reembolsos_efectivo
   FROM tx
  GROUP BY tx.sesion_id;


ALTER TABLE vw_sesion_reembolsos_efectivo OWNER TO postgres;

--
-- TOC entry 661 (class 1259 OID 158582)
-- Name: vw_sesion_retiros; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_retiros AS
 WITH tx AS (
         SELECT s.id AS sesion_id,
            COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp,
            (t.amount)::numeric AS monto
           FROM ((sesion_cajon s
             JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
             LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
        )
 SELECT tx.sesion_id,
    (sum(
        CASE
            WHEN (tx.codigo_fp = ANY (ARRAY['PAY_OUT'::text, 'CASH_DROP'::text])) THEN tx.monto
            ELSE (0)::numeric
        END))::numeric(12,2) AS retiros
   FROM tx
  GROUP BY tx.sesion_id;


ALTER TABLE vw_sesion_retiros OWNER TO postgres;

--
-- TOC entry 660 (class 1259 OID 158577)
-- Name: vw_sesion_ventas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_ventas AS
 WITH base AS (
         SELECT s.id AS sesion_id,
            (t.amount)::numeric AS monto,
            COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp
           FROM ((sesion_cajon s
             JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id))))
             LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
          WHERE ((COALESCE(t.voided, false) = false) AND ((t.transaction_type)::text = 'CREDIT'::text))
        )
 SELECT base.sesion_id,
    base.codigo_fp,
    (sum(base.monto))::numeric(12,2) AS monto
   FROM base
  GROUP BY base.sesion_id, base.codigo_fp;


ALTER TABLE vw_sesion_ventas OWNER TO postgres;

--
-- TOC entry 669 (class 1259 OID 158646)
-- Name: vw_conciliacion_sesion; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_conciliacion_sesion AS
 WITH sys AS (
         SELECT s.id AS sesion_id,
            s.opening_float,
            (sum(
                CASE
                    WHEN (v.codigo_fp = 'CASH'::text) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_cash,
            (sum(
                CASE
                    WHEN (v.codigo_fp = ANY (ARRAY['CREDIT'::text, 'CREDIT_CARD'::text])) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_credito,
            (sum(
                CASE
                    WHEN (v.codigo_fp = ANY (ARRAY['DEBIT'::text, 'DEBIT_CARD'::text])) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_debito,
            (sum(
                CASE
                    WHEN (v.codigo_fp ~~ 'CUSTOM:%'::text) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_custom,
            (sum(
                CASE
                    WHEN (v.codigo_fp = 'TRANSFER'::text) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_transfer,
            (sum(
                CASE
                    WHEN (v.codigo_fp = 'GIFT_CERT'::text) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_gift
           FROM (sesion_cajon s
             LEFT JOIN vw_sesion_ventas v ON ((v.sesion_id = s.id)))
          GROUP BY s.id, s.opening_float
        ), re AS (
         SELECT vw_sesion_retiros.sesion_id,
            vw_sesion_retiros.retiros
           FROM vw_sesion_retiros
        ), cr AS (
         SELECT vw_sesion_reembolsos_efectivo.sesion_id,
            vw_sesion_reembolsos_efectivo.reembolsos_efectivo
           FROM vw_sesion_reembolsos_efectivo
        ), ds AS (
         SELECT vw_sesion_descuentos.sesion_id,
            vw_sesion_descuentos.descuentos
           FROM vw_sesion_descuentos
        ), decl_cash AS (
         SELECT p.sesion_id,
            (sum(pe.subtotal))::numeric(12,2) AS declarado_efectivo
           FROM (precorte p
             LEFT JOIN precorte_efectivo pe ON ((pe.precorte_id = p.id)))
          GROUP BY p.sesion_id
        ), decl_otros AS (
         SELECT p.sesion_id,
            (sum(
                CASE
                    WHEN (po.tipo = 'CREDITO'::text) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_credito,
            (sum(
                CASE
                    WHEN (po.tipo = 'DEBITO'::text) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_debito,
            (sum(
                CASE
                    WHEN (po.tipo = 'TRANSFER'::text) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_transfer,
            (sum(
                CASE
                    WHEN (po.tipo ~~ 'CUSTOM:%'::text) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_custom,
            (sum(
                CASE
                    WHEN (po.tipo = 'GIFT_CERT'::text) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_gift
           FROM (precorte p
             LEFT JOIN precorte_otros po ON ((po.precorte_id = p.id)))
          GROUP BY p.sesion_id
        ), eff AS (
         SELECT sys_1.sesion_id,
            sys_1.opening_float,
            COALESCE(sys_1.sys_cash, (0)::numeric) AS cash_in,
            COALESCE(re.retiros, (0)::numeric) AS cash_out,
            COALESCE(cr.reembolsos_efectivo, (0)::numeric) AS cash_refund,
            ((((sys_1.opening_float + COALESCE(sys_1.sys_cash, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(cr.reembolsos_efectivo, (0)::numeric)))::numeric(12,2) AS sistema_efectivo_esperado
           FROM ((sys sys_1
             LEFT JOIN re ON ((re.sesion_id = sys_1.sesion_id)))
             LEFT JOIN cr ON ((cr.sesion_id = sys_1.sesion_id)))
        ), tc AS (
         SELECT sys_1.sesion_id,
            (((((COALESCE(sys_1.sys_credito, (0)::numeric) + COALESCE(sys_1.sys_debito, (0)::numeric)) + COALESCE(sys_1.sys_transfer, (0)::numeric)) + COALESCE(sys_1.sys_custom, (0)::numeric)) + COALESCE(sys_1.sys_gift, (0)::numeric)))::numeric(12,2) AS sistema_no_efectivo
           FROM sys sys_1
        )
 SELECT sys.sesion_id,
    eff.sistema_efectivo_esperado,
    (COALESCE(dc.declarado_efectivo, (0)::numeric))::numeric(12,2) AS declarado_efectivo,
    ((COALESCE(dc.declarado_efectivo, (0)::numeric) - eff.sistema_efectivo_esperado))::numeric(12,2) AS diferencia_efectivo,
        CASE
            WHEN (COALESCE(dc.declarado_efectivo, (0)::numeric) = eff.sistema_efectivo_esperado) THEN 'CUADRA'::text
            WHEN (COALESCE(dc.declarado_efectivo, (0)::numeric) > eff.sistema_efectivo_esperado) THEN 'A_FAVOR'::text
            ELSE 'EN_CONTRA'::text
        END AS veredicto_efectivo,
    sys.sys_credito,
    sys.sys_debito,
    sys.sys_transfer,
    sys.sys_custom,
    sys.sys_gift,
    dotros.decl_credito,
    dotros.decl_debito,
    dotros.decl_transfer,
    dotros.decl_custom,
    dotros.decl_gift,
    tc.sistema_no_efectivo,
    ds.descuentos AS total_descuentos,
    dpr.begin_cash,
    dpr.cash_receipt_amount,
    dpr.credit_card_receipt_amount,
    dpr.debit_card_receipt_amount,
    dpr.pay_out_amount,
    dpr.drawer_bleed_amount,
    dpr.refund_amount,
    dpr.totaldiscountamount,
    dpr.totalvoid,
    dpr.drawer_accountable,
    dpr.cash_to_deposit,
    dpr.variance,
    dpr.report_time
   FROM ((((((sys
     LEFT JOIN eff ON ((eff.sesion_id = sys.sesion_id)))
     LEFT JOIN decl_cash dc ON ((dc.sesion_id = sys.sesion_id)))
     LEFT JOIN decl_otros dotros ON ((dotros.sesion_id = sys.sesion_id)))
     LEFT JOIN tc ON ((tc.sesion_id = sys.sesion_id)))
     LEFT JOIN ds ON ((ds.sesion_id = sys.sesion_id)))
     LEFT JOIN vw_sesion_dpr dpr ON ((dpr.sesion_id = sys.sesion_id)))
  ORDER BY sys.sesion_id DESC;


ALTER TABLE vw_conciliacion_sesion OWNER TO postgres;

--
-- TOC entry 656 (class 1259 OID 158526)
-- Name: vw_fast_tickets; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_fast_tickets AS
 SELECT tk.id,
    tk.terminal_id,
    tk.owner_id,
    tk.create_date,
    tk.closing_date,
    tk.status,
    tk.total_discount,
    tk.total_price
   FROM public.ticket tk;


ALTER TABLE vw_fast_tickets OWNER TO postgres;

--
-- TOC entry 663 (class 1259 OID 158592)
-- Name: vw_fast_tx; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_fast_tx AS
 SELECT t.terminal_id,
    t.user_id,
    t.transaction_time,
    t.payment_type,
    t.transaction_type,
    t.payment_sub_type,
    t.custom_payment_name,
    t.custom_payment_ref,
    t.amount,
    t.voided
   FROM public.transactions t;


ALTER TABLE vw_fast_tx OWNER TO postgres;

--
-- TOC entry 473 (class 1259 OID 153915)
-- Name: vw_item_last_price; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_item_last_price AS
 WITH last_price AS (
         SELECT (ivp.item_id)::text AS item_id,
            (ivp.vendor_id)::text AS vendor_id,
            ivp.price,
            ivp.pack_qty,
            ivp.pack_uom,
            ivp.effective_from,
            row_number() OVER (PARTITION BY ivp.item_id, ivp.vendor_id ORDER BY ivp.effective_from DESC) AS rn
           FROM item_vendor_prices ivp
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


ALTER TABLE vw_item_last_price OWNER TO postgres;

--
-- TOC entry 474 (class 1259 OID 153920)
-- Name: vw_item_last_price_pref; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_item_last_price_pref AS
 SELECT i.id AS item_id,
    pv.vendor_id,
    lp.price,
    lp.pack_qty,
    lp.pack_uom,
    lp.effective_from
   FROM ((items i
     LEFT JOIN item_vendor pv ON (((pv.item_id = (i.id)::text) AND (COALESCE(pv.preferente, false) = true))))
     LEFT JOIN vw_item_last_price lp ON (((lp.item_id = (i.id)::text) AND (lp.vendor_id = pv.vendor_id))));


ALTER TABLE vw_item_last_price_pref OWNER TO postgres;

--
-- TOC entry 475 (class 1259 OID 153925)
-- Name: vw_kardex; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_kardex AS
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
   FROM mov_inv mi
  ORDER BY mi.ts DESC, mi.id DESC;


ALTER TABLE vw_kardex OWNER TO postgres;

--
-- TOC entry 476 (class 1259 OID 153930)
-- Name: vw_movimientos_anomalos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_movimientos_anomalos AS
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
   FROM vw_kardex k
  WHERE ((k.qty IS NULL) OR (k.qty = (0)::numeric) OR (abs(k.qty) > (1000000)::numeric) OR (k.costo_unit < (0)::numeric) OR (k.ts > (now() + '1 day'::interval)) OR (k.item_key IS NULL) OR (k.item_key = ''::text) OR ((k.tipo)::text <> ALL (ARRAY[('ENTRADA'::character varying)::text, ('RECEPCION'::character varying)::text, ('COMPRA'::character varying)::text, ('TRASPASO_IN'::character varying)::text, ('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO_OUT'::character varying)::text])));


ALTER TABLE vw_movimientos_anomalos OWNER TO postgres;

--
-- TOC entry 477 (class 1259 OID 153940)
-- Name: vw_pos_map_resuelto; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_pos_map_resuelto AS
 SELECT pm.pos_system,
    pm.plu,
    pm.tipo,
    ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint AS receta_version_id,
    ((row_to_json(pm.*) ->> 'insumo_id'::text))::bigint AS insumo_id,
    COALESCE(((row_to_json(pm.*) ->> 'factor_insumo'::text))::numeric, (1)::numeric) AS factor_insumo,
    ((row_to_json(pm.*) ->> 'vigente_desde'::text))::timestamp without time zone AS vigente_desde,
    ((row_to_json(pm.*) ->> 'vigente_hasta'::text))::timestamp without time zone AS vigente_hasta
   FROM pos_map pm
  WHERE (((row_to_json(pm.*) ->> 'vigente_hasta'::text) IS NULL) OR (((row_to_json(pm.*) ->> 'vigente_hasta'::text))::date >= ('now'::text)::date));


ALTER TABLE vw_pos_map_resuelto OWNER TO postgres;

--
-- TOC entry 478 (class 1259 OID 153945)
-- Name: vw_replenishment_dashboard; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_replenishment_dashboard AS
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
   FROM ((replenishment_suggestions rs
     LEFT JOIN items i ON (((i.id)::text = (rs.item_id)::text)))
     LEFT JOIN cat_sucursales s ON ((s.id = rs.sucursal_id)));


ALTER TABLE vw_replenishment_dashboard OWNER TO postgres;

--
-- TOC entry 479 (class 1259 OID 153960)
-- Name: vw_stock_por_lote_fefo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_stock_por_lote_fefo AS
 SELECT (ib.item_id)::text AS item_key,
    ib.id AS lote_id,
    ib.ubicacion_id,
    ib.fecha_caducidad,
    ib.cantidad_actual AS stock_lote
   FROM inventory_batch ib
  WHERE ((ib.estado)::text = 'ACTIVO'::text)
  ORDER BY ib.item_id, ib.fecha_caducidad, ib.id;


ALTER TABLE vw_stock_por_lote_fefo OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 4379 (class 2604 OID 157933)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY action_history ALTER COLUMN id SET DEFAULT nextval('action_history_id_seq'::regclass);


--
-- TOC entry 4387 (class 2604 OID 158128)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendence_history ALTER COLUMN id SET DEFAULT nextval('attendence_history_id_seq'::regclass);


--
-- TOC entry 4385 (class 2604 OID 158096)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer ALTER COLUMN id SET DEFAULT nextval('cash_drawer_id_seq'::regclass);


--
-- TOC entry 4378 (class 2604 OID 157916)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass);


--
-- TOC entry 4377 (class 2604 OID 157908)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cooking_instruction ALTER COLUMN id SET DEFAULT nextval('cooking_instruction_id_seq'::regclass);


--
-- TOC entry 4376 (class 2604 OID 157872)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('coupon_and_discount_id_seq'::regclass);


--
-- TOC entry 4375 (class 2604 OID 157862)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency ALTER COLUMN id SET DEFAULT nextval('currency_id_seq'::regclass);


--
-- TOC entry 4386 (class 2604 OID 158107)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency_balance ALTER COLUMN id SET DEFAULT nextval('currency_balance_id_seq'::regclass);


--
-- TOC entry 4374 (class 2604 OID 157854)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY custom_payment ALTER COLUMN id SET DEFAULT nextval('custom_payment_id_seq'::regclass);


--
-- TOC entry 4370 (class 2604 OID 157779)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY customer ALTER COLUMN auto_id SET DEFAULT nextval('customer_auto_id_seq'::regclass);


--
-- TOC entry 4369 (class 2604 OID 157771)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY data_update_info ALTER COLUMN id SET DEFAULT nextval('data_update_info_id_seq'::regclass);


--
-- TOC entry 4373 (class 2604 OID 157828)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_address ALTER COLUMN id SET DEFAULT nextval('delivery_address_id_seq'::regclass);


--
-- TOC entry 4368 (class 2604 OID 157761)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_charge ALTER COLUMN id SET DEFAULT nextval('delivery_charge_id_seq'::regclass);


--
-- TOC entry 4367 (class 2604 OID 157753)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_configuration ALTER COLUMN id SET DEFAULT nextval('delivery_configuration_id_seq'::regclass);


--
-- TOC entry 4372 (class 2604 OID 157817)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_instruction ALTER COLUMN id SET DEFAULT nextval('delivery_instruction_id_seq'::regclass);


--
-- TOC entry 4380 (class 2604 OID 157986)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('drawer_assigned_history_id_seq'::regclass);


--
-- TOC entry 4384 (class 2604 OID 158064)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('drawer_pull_report_id_seq'::regclass);


--
-- TOC entry 4383 (class 2604 OID 158043)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('employee_in_out_history_id_seq'::regclass);


--
-- TOC entry 4366 (class 2604 OID 157735)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY global_config ALTER COLUMN id SET DEFAULT nextval('global_config_id_seq'::regclass);


--
-- TOC entry 4382 (class 2604 OID 158027)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gratuity ALTER COLUMN id SET DEFAULT nextval('gratuity_id_seq'::regclass);


--
-- TOC entry 4365 (class 2604 OID 157720)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY guest_check_print ALTER COLUMN id SET DEFAULT nextval('guest_check_print_id_seq'::regclass);


--
-- TOC entry 4361 (class 2604 OID 157634)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_group ALTER COLUMN id SET DEFAULT nextval('inventory_group_id_seq'::regclass);


--
-- TOC entry 4362 (class 2604 OID 157640)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item ALTER COLUMN id SET DEFAULT nextval('inventory_item_id_seq'::regclass);


--
-- TOC entry 4360 (class 2604 OID 157619)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_location ALTER COLUMN id SET DEFAULT nextval('inventory_location_id_seq'::regclass);


--
-- TOC entry 4359 (class 2604 OID 157608)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('inventory_meta_code_id_seq'::regclass);


--
-- TOC entry 4364 (class 2604 OID 157687)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction ALTER COLUMN id SET DEFAULT nextval('inventory_transaction_id_seq'::regclass);


--
-- TOC entry 4358 (class 2604 OID 157595)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_unit ALTER COLUMN id SET DEFAULT nextval('inventory_unit_id_seq'::regclass);


--
-- TOC entry 4357 (class 2604 OID 157584)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_vendor ALTER COLUMN id SET DEFAULT nextval('inventory_vendor_id_seq'::regclass);


--
-- TOC entry 4356 (class 2604 OID 157576)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('inventory_warehouse_id_seq'::regclass);


--
-- TOC entry 4355 (class 2604 OID 157555)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_id_seq'::regclass);


--
-- TOC entry 4398 (class 2604 OID 158514)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_item_id_seq'::regclass);


--
-- TOC entry 4353 (class 2604 OID 157534)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_category ALTER COLUMN id SET DEFAULT nextval('menu_category_id_seq'::regclass);


--
-- TOC entry 4354 (class 2604 OID 157540)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_group ALTER COLUMN id SET DEFAULT nextval('menu_group_id_seq'::regclass);


--
-- TOC entry 4388 (class 2604 OID 158154)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item ALTER COLUMN id SET DEFAULT nextval('menu_item_id_seq'::regclass);


--
-- TOC entry 4350 (class 2604 OID 157477)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_size ALTER COLUMN id SET DEFAULT nextval('menu_item_size_id_seq'::regclass);


--
-- TOC entry 4349 (class 2604 OID 157444)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier ALTER COLUMN id SET DEFAULT nextval('menu_modifier_id_seq'::regclass);


--
-- TOC entry 4348 (class 2604 OID 157438)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('menu_modifier_group_id_seq'::regclass);


--
-- TOC entry 4390 (class 2604 OID 158222)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass);


--
-- TOC entry 4389 (class 2604 OID 158193)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_shift ALTER COLUMN id SET DEFAULT nextval('menuitem_shift_id_seq'::regclass);


--
-- TOC entry 4391 (class 2604 OID 158349)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('modifier_multiplier_price_id_seq'::regclass);


--
-- TOC entry 4347 (class 2604 OID 157417)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY order_type ALTER COLUMN id SET DEFAULT nextval('order_type_id_seq'::regclass);


--
-- TOC entry 4346 (class 2604 OID 157407)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packaging_unit ALTER COLUMN id SET DEFAULT nextval('packaging_unit_id_seq'::regclass);


--
-- TOC entry 4345 (class 2604 OID 157399)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payout_reasons ALTER COLUMN id SET DEFAULT nextval('payout_reasons_id_seq'::regclass);


--
-- TOC entry 4344 (class 2604 OID 157391)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payout_recepients ALTER COLUMN id SET DEFAULT nextval('payout_recepients_id_seq'::regclass);


--
-- TOC entry 4343 (class 2604 OID 157383)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_crust ALTER COLUMN id SET DEFAULT nextval('pizza_crust_id_seq'::regclass);


--
-- TOC entry 4352 (class 2604 OID 157504)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('pizza_modifier_price_id_seq'::regclass);


--
-- TOC entry 4351 (class 2604 OID 157483)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_price ALTER COLUMN id SET DEFAULT nextval('pizza_price_id_seq'::regclass);


--
-- TOC entry 4342 (class 2604 OID 157361)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY printer_group ALTER COLUMN id SET DEFAULT nextval('printer_group_id_seq'::regclass);


--
-- TOC entry 4341 (class 2604 OID 157353)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY purchase_order ALTER COLUMN id SET DEFAULT nextval('purchase_order_id_seq'::regclass);


--
-- TOC entry 4340 (class 2604 OID 157345)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie ALTER COLUMN id SET DEFAULT nextval('recepie_id_seq'::regclass);


--
-- TOC entry 4363 (class 2604 OID 157671)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie_item ALTER COLUMN id SET DEFAULT nextval('recepie_item_id_seq'::regclass);


--
-- TOC entry 4338 (class 2604 OID 157313)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift ALTER COLUMN id SET DEFAULT nextval('shift_id_seq'::regclass);


--
-- TOC entry 4336 (class 2604 OID 157261)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor ALTER COLUMN id SET DEFAULT nextval('shop_floor_id_seq'::regclass);


--
-- TOC entry 4337 (class 2604 OID 157290)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor_template ALTER COLUMN id SET DEFAULT nextval('shop_floor_template_id_seq'::regclass);


--
-- TOC entry 4335 (class 2604 OID 157251)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_table_type ALTER COLUMN id SET DEFAULT nextval('shop_table_type_id_seq'::regclass);


--
-- TOC entry 4371 (class 2604 OID 157788)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_info ALTER COLUMN id SET DEFAULT nextval('table_booking_info_id_seq'::regclass);


--
-- TOC entry 4334 (class 2604 OID 157241)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax ALTER COLUMN id SET DEFAULT nextval('tax_id_seq'::regclass);


--
-- TOC entry 4381 (class 2604 OID 158011)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_printers ALTER COLUMN id SET DEFAULT nextval('terminal_printers_id_seq'::regclass);


--
-- TOC entry 4394 (class 2604 OID 158385)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket ALTER COLUMN id SET DEFAULT nextval('ticket_id_seq'::regclass);


--
-- TOC entry 4400 (class 2604 OID 158633)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_discount ALTER COLUMN id SET DEFAULT nextval('ticket_discount_id_seq'::regclass);


--
-- TOC entry 4396 (class 2604 OID 158433)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item ALTER COLUMN id SET DEFAULT nextval('ticket_item_id_seq'::regclass);


--
-- TOC entry 4397 (class 2604 OID 158478)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('ticket_item_discount_id_seq'::regclass);


--
-- TOC entry 4333 (class 2604 OID 157223)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifier_id_seq'::regclass);


--
-- TOC entry 4399 (class 2604 OID 158543)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- TOC entry 4332 (class 2604 OID 157213)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_type ALTER COLUMN id SET DEFAULT nextval('user_type_id_seq'::regclass);


--
-- TOC entry 4339 (class 2604 OID 157321)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN auto_id SET DEFAULT nextval('users_auto_id_seq'::regclass);


--
-- TOC entry 4331 (class 2604 OID 157193)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY virtual_printer ALTER COLUMN id SET DEFAULT nextval('virtual_printer_id_seq'::regclass);


--
-- TOC entry 4330 (class 2604 OID 157185)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY void_reasons ALTER COLUMN id SET DEFAULT nextval('void_reasons_id_seq'::regclass);


--
-- TOC entry 4329 (class 2604 OID 157177)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3805 (class 2604 OID 154047)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 3809 (class 2604 OID 154048)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 3812 (class 2604 OID 154049)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- TOC entry 3814 (class 2604 OID 154050)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global ALTER COLUMN id SET DEFAULT nextval('audit_log_global_id_seq'::regclass);


--
-- TOC entry 3817 (class 2604 OID 154051)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3818 (class 2604 OID 154052)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 3823 (class 2604 OID 154053)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_id_seq'::regclass);


--
-- TOC entry 3825 (class 2604 OID 154054)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('caja_fondo_adj_id_seq'::regclass);


--
-- TOC entry 3827 (class 2604 OID 154055)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_arqueo_id_seq'::regclass);


--
-- TOC entry 3834 (class 2604 OID 154056)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('caja_fondo_mov_id_seq'::regclass);


--
-- TOC entry 3835 (class 2604 OID 154057)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('cash_fund_arqueos_id_seq'::regclass);


--
-- TOC entry 3837 (class 2604 OID 154058)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('cash_fund_movement_audit_log_id_seq'::regclass);


--
-- TOC entry 3841 (class 2604 OID 154059)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('cash_fund_movements_id_seq'::regclass);


--
-- TOC entry 3847 (class 2604 OID 154060)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds ALTER COLUMN id SET DEFAULT nextval('cash_funds_id_seq'::regclass);


--
-- TOC entry 3850 (class 2604 OID 154061)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 3852 (class 2604 OID 154062)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 3854 (class 2604 OID 154063)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 3856 (class 2604 OID 154064)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 3859 (class 2604 OID 154065)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 3862 (class 2604 OID 154066)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 3867 (class 2604 OID 154067)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3870 (class 2604 OID 154068)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3872 (class 2604 OID 154069)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3876 (class 2604 OID 154070)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3882 (class 2604 OID 154071)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 3886 (class 2604 OID 154072)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 3893 (class 2604 OID 154073)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3900 (class 2604 OID 154074)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3904 (class 2604 OID 154075)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 3910 (class 2604 OID 154076)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 3917 (class 2604 OID 154077)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_proveedor_presentacion_id_seq'::regclass);


--
-- TOC entry 3922 (class 2604 OID 154078)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_id_seq'::regclass);


--
-- TOC entry 3927 (class 2604 OID 154079)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_det_id_seq'::regclass);


--
-- TOC entry 3930 (class 2604 OID 154080)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_log_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 154081)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 3940 (class 2604 OID 154082)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 3951 (class 2604 OID 154083)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('inventory_count_lines_id_seq'::regclass);


--
-- TOC entry 3955 (class 2604 OID 154084)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts ALTER COLUMN id SET DEFAULT nextval('inventory_counts_id_seq'::regclass);


--
-- TOC entry 3960 (class 2604 OID 154085)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes ALTER COLUMN id SET DEFAULT nextval('inventory_wastes_id_seq'::regclass);


--
-- TOC entry 3962 (class 2604 OID 154086)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 3974 (class 2604 OID 154087)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 3994 (class 2604 OID 154088)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3997 (class 2604 OID 154089)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 4000 (class 2604 OID 154090)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles ALTER COLUMN id SET DEFAULT nextval('labor_roles_id_seq'::regclass);


--
-- TOC entry 4003 (class 2604 OID 154091)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 4012 (class 2604 OID 154092)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('menu_engineering_snapshots_id_seq'::regclass);


--
-- TOC entry 4014 (class 2604 OID 154093)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('menu_item_sync_map_id_seq'::regclass);


--
-- TOC entry 4016 (class 2604 OID 154094)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- TOC entry 4020 (class 2604 OID 154095)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 4021 (class 2604 OID 154096)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 4024 (class 2604 OID 154097)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 4029 (class 2604 OID 154098)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 4059 (class 2604 OID 154099)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 4062 (class 2604 OID 154100)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 4066 (class 2604 OID 154101)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 4073 (class 2604 OID 154102)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions ALTER COLUMN id SET DEFAULT nextval('overhead_definitions_id_seq'::regclass);


--
-- TOC entry 4079 (class 2604 OID 154103)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 4082 (class 2604 OID 154104)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 4084 (class 2604 OID 154105)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 4085 (class 2604 OID 154106)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4099 (class 2604 OID 154107)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('pos_reprocess_log_id_seq'::regclass);


--
-- TOC entry 4103 (class 2604 OID 154108)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('pos_reverse_log_id_seq'::regclass);


--
-- TOC entry 4108 (class 2604 OID 154109)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('pos_sync_batches_id_seq'::regclass);


--
-- TOC entry 4110 (class 2604 OID 154110)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('pos_sync_logs_id_seq'::regclass);


--
-- TOC entry 4125 (class 2604 OID 154111)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 4133 (class 2604 OID 154112)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 4136 (class 2604 OID 154113)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 4139 (class 2604 OID 154114)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 4142 (class 2604 OID 154115)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab ALTER COLUMN id SET DEFAULT nextval('prod_cab_id_seq'::regclass);


--
-- TOC entry 4144 (class 2604 OID 154116)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det ALTER COLUMN id SET DEFAULT nextval('prod_det_id_seq'::regclass);


--
-- TOC entry 4145 (class 2604 OID 154117)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs ALTER COLUMN id SET DEFAULT nextval('production_order_inputs_id_seq'::regclass);


--
-- TOC entry 4146 (class 2604 OID 154118)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs ALTER COLUMN id SET DEFAULT nextval('production_order_outputs_id_seq'::regclass);


--
-- TOC entry 4151 (class 2604 OID 154119)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders ALTER COLUMN id SET DEFAULT nextval('production_orders_id_seq'::regclass);


--
-- TOC entry 4153 (class 2604 OID 154120)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents ALTER COLUMN id SET DEFAULT nextval('purchase_documents_id_seq'::regclass);


--
-- TOC entry 4156 (class 2604 OID 154121)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('purchase_order_lines_id_seq'::regclass);


--
-- TOC entry 4162 (class 2604 OID 154122)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders ALTER COLUMN id SET DEFAULT nextval('purchase_orders_id_seq'::regclass);


--
-- TOC entry 4164 (class 2604 OID 154123)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('purchase_request_lines_id_seq'::regclass);


--
-- TOC entry 4169 (class 2604 OID 154124)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests ALTER COLUMN id SET DEFAULT nextval('purchase_requests_id_seq'::regclass);


--
-- TOC entry 4174 (class 2604 OID 154125)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('purchase_suggestion_lines_id_seq'::regclass);


--
-- TOC entry 4183 (class 2604 OID 154126)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('purchase_suggestions_id_seq'::regclass);


--
-- TOC entry 4185 (class 2604 OID 154127)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quote_lines_id_seq'::regclass);


--
-- TOC entry 4192 (class 2604 OID 154128)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quotes_id_seq'::regclass);


--
-- TOC entry 4193 (class 2604 OID 154129)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 4194 (class 2604 OID 154130)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('recepcion_adjuntos_id_seq'::regclass);


--
-- TOC entry 4198 (class 2604 OID 154131)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 4201 (class 2604 OID 154132)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 4204 (class 2604 OID 154133)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 4048 (class 2604 OID 154134)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 4205 (class 2604 OID 154135)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 4211 (class 2604 OID 154136)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 4054 (class 2604 OID 154137)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 4216 (class 2604 OID 154138)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 4222 (class 2604 OID 154139)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots ALTER COLUMN id SET DEFAULT nextval('recipe_cost_snapshots_id_seq'::regclass);


--
-- TOC entry 4230 (class 2604 OID 154140)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_extended_cost_history_id_seq'::regclass);


--
-- TOC entry 4233 (class 2604 OID 154141)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('recipe_labor_steps_id_seq'::regclass);


--
-- TOC entry 4234 (class 2604 OID 154142)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('recipe_overhead_allocations_id_seq'::regclass);


--
-- TOC entry 4235 (class 2604 OID 154143)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 4238 (class 2604 OID 154144)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 4243 (class 2604 OID 154145)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('replenishment_suggestions_id_seq'::regclass);


--
-- TOC entry 4325 (class 2604 OID 156909)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions ALTER COLUMN id SET DEFAULT nextval('report_definitions_id_seq'::regclass);


--
-- TOC entry 4244 (class 2604 OID 154147)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites ALTER COLUMN id SET DEFAULT nextval('report_favorites_id_seq'::regclass);


--
-- TOC entry 4327 (class 2604 OID 156923)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs ALTER COLUMN id SET DEFAULT nextval('report_runs_id_seq'::regclass);


--
-- TOC entry 4245 (class 2604 OID 154149)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 4246 (class 2604 OID 154150)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 4035 (class 2604 OID 154151)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 4250 (class 2604 OID 154152)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('sol_prod_cab_id_seq'::regclass);


--
-- TOC entry 4252 (class 2604 OID 154153)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det ALTER COLUMN id SET DEFAULT nextval('sol_prod_det_id_seq'::regclass);


--
-- TOC entry 4257 (class 2604 OID 154154)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 4261 (class 2604 OID 154155)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 4264 (class 2604 OID 154156)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 4268 (class 2604 OID 154157)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifiers_id_seq'::regclass);


--
-- TOC entry 4273 (class 2604 OID 154158)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 4278 (class 2604 OID 154159)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 4282 (class 2604 OID 154160)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab ALTER COLUMN id SET DEFAULT nextval('transfer_cab_id_seq'::regclass);


--
-- TOC entry 4284 (class 2604 OID 154161)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det ALTER COLUMN id SET DEFAULT nextval('transfer_det_id_seq'::regclass);


--
-- TOC entry 4288 (class 2604 OID 154162)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 4291 (class 2604 OID 154163)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 4295 (class 2604 OID 154164)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 4301 (class 2604 OID 154165)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 4306 (class 2604 OID 154166)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 4316 (class 2604 OID 154167)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 4324 (class 2604 OID 154168)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- TOC entry 6066 (class 0 OID 157930)
-- Dependencies: 615
-- Data for Name: action_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6415 (class 0 OID 0)
-- Dependencies: 614
-- Name: action_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('action_history_id_seq', 1, false);


--
-- TOC entry 6079 (class 0 OID 158125)
-- Dependencies: 629
-- Data for Name: attendence_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6416 (class 0 OID 0)
-- Dependencies: 613
-- Name: attendence_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('attendence_history_id_seq', 1, false);


--
-- TOC entry 6077 (class 0 OID 158093)
-- Dependencies: 627
-- Data for Name: cash_drawer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6417 (class 0 OID 0)
-- Dependencies: 612
-- Name: cash_drawer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cash_drawer_id_seq', 1, false);


--
-- TOC entry 6062 (class 0 OID 157913)
-- Dependencies: 611
-- Data for Name: cash_drawer_reset_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6418 (class 0 OID 0)
-- Dependencies: 610
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cash_drawer_reset_history_id_seq', 1, false);


--
-- TOC entry 6060 (class 0 OID 157905)
-- Dependencies: 609
-- Data for Name: cooking_instruction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6419 (class 0 OID 0)
-- Dependencies: 608
-- Name: cooking_instruction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cooking_instruction_id_seq', 1, false);


--
-- TOC entry 6056 (class 0 OID 157869)
-- Dependencies: 605
-- Data for Name: coupon_and_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6420 (class 0 OID 0)
-- Dependencies: 604
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('coupon_and_discount_id_seq', 1, false);


--
-- TOC entry 6053 (class 0 OID 157859)
-- Dependencies: 602
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6078 (class 0 OID 158104)
-- Dependencies: 628
-- Data for Name: currency_balance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6421 (class 0 OID 0)
-- Dependencies: 603
-- Name: currency_balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('currency_balance_id_seq', 1, false);


--
-- TOC entry 6422 (class 0 OID 0)
-- Dependencies: 601
-- Name: currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('currency_id_seq', 1, false);


--
-- TOC entry 6051 (class 0 OID 157851)
-- Dependencies: 600
-- Data for Name: custom_payment; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6423 (class 0 OID 0)
-- Dependencies: 599
-- Name: custom_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('custom_payment_id_seq', 1, false);


--
-- TOC entry 6044 (class 0 OID 157776)
-- Dependencies: 593
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6424 (class 0 OID 0)
-- Dependencies: 592
-- Name: customer_auto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('customer_auto_id_seq', 1, false);


--
-- TOC entry 6049 (class 0 OID 157836)
-- Dependencies: 598
-- Data for Name: customer_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6098 (class 0 OID 158373)
-- Dependencies: 648
-- Data for Name: daily_folio_counter; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6042 (class 0 OID 157768)
-- Dependencies: 591
-- Data for Name: data_update_info; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6425 (class 0 OID 0)
-- Dependencies: 590
-- Name: data_update_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('data_update_info_id_seq', 1, false);


--
-- TOC entry 6048 (class 0 OID 157825)
-- Dependencies: 597
-- Data for Name: delivery_address; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6426 (class 0 OID 0)
-- Dependencies: 589
-- Name: delivery_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('delivery_address_id_seq', 1, false);


--
-- TOC entry 6039 (class 0 OID 157758)
-- Dependencies: 588
-- Data for Name: delivery_charge; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6427 (class 0 OID 0)
-- Dependencies: 587
-- Name: delivery_charge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('delivery_charge_id_seq', 1, false);


--
-- TOC entry 6037 (class 0 OID 157750)
-- Dependencies: 586
-- Data for Name: delivery_configuration; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6428 (class 0 OID 0)
-- Dependencies: 585
-- Name: delivery_configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('delivery_configuration_id_seq', 1, false);


--
-- TOC entry 6047 (class 0 OID 157814)
-- Dependencies: 596
-- Data for Name: delivery_instruction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6429 (class 0 OID 0)
-- Dependencies: 584
-- Name: delivery_instruction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('delivery_instruction_id_seq', 1, false);


--
-- TOC entry 6070 (class 0 OID 157983)
-- Dependencies: 619
-- Data for Name: drawer_assigned_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6430 (class 0 OID 0)
-- Dependencies: 583
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('drawer_assigned_history_id_seq', 1, false);


--
-- TOC entry 6075 (class 0 OID 158061)
-- Dependencies: 624
-- Data for Name: drawer_pull_report; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6431 (class 0 OID 0)
-- Dependencies: 582
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('drawer_pull_report_id_seq', 1, false);


--
-- TOC entry 6076 (class 0 OID 158082)
-- Dependencies: 626
-- Data for Name: drawer_pull_report_voidtickets; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6074 (class 0 OID 158040)
-- Dependencies: 623
-- Data for Name: employee_in_out_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6432 (class 0 OID 0)
-- Dependencies: 581
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_in_out_history_id_seq', 1, false);


--
-- TOC entry 6031 (class 0 OID 157732)
-- Dependencies: 580
-- Data for Name: global_config; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6433 (class 0 OID 0)
-- Dependencies: 579
-- Name: global_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('global_config_id_seq', 1, false);


--
-- TOC entry 6073 (class 0 OID 158024)
-- Dependencies: 622
-- Data for Name: gratuity; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6434 (class 0 OID 0)
-- Dependencies: 578
-- Name: gratuity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gratuity_id_seq', 1, false);


--
-- TOC entry 6089 (class 0 OID 158289)
-- Dependencies: 639
-- Data for Name: group_taxes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6028 (class 0 OID 157717)
-- Dependencies: 577
-- Data for Name: guest_check_print; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6435 (class 0 OID 0)
-- Dependencies: 576
-- Name: guest_check_print_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('guest_check_print_id_seq', 1, false);


--
-- TOC entry 6023 (class 0 OID 157631)
-- Dependencies: 572
-- Data for Name: inventory_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6436 (class 0 OID 0)
-- Dependencies: 571
-- Name: inventory_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_group_id_seq', 1, false);


--
-- TOC entry 6024 (class 0 OID 157637)
-- Dependencies: 573
-- Data for Name: inventory_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6437 (class 0 OID 0)
-- Dependencies: 570
-- Name: inventory_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_item_id_seq', 1, false);


--
-- TOC entry 6020 (class 0 OID 157616)
-- Dependencies: 569
-- Data for Name: inventory_location; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6438 (class 0 OID 0)
-- Dependencies: 568
-- Name: inventory_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_location_id_seq', 1, false);


--
-- TOC entry 6018 (class 0 OID 157605)
-- Dependencies: 567
-- Data for Name: inventory_meta_code; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6439 (class 0 OID 0)
-- Dependencies: 566
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_meta_code_id_seq', 1, false);


--
-- TOC entry 6026 (class 0 OID 157684)
-- Dependencies: 575
-- Data for Name: inventory_transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6440 (class 0 OID 0)
-- Dependencies: 565
-- Name: inventory_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_transaction_id_seq', 1, false);


--
-- TOC entry 6015 (class 0 OID 157592)
-- Dependencies: 564
-- Data for Name: inventory_unit; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6441 (class 0 OID 0)
-- Dependencies: 563
-- Name: inventory_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_unit_id_seq', 1, false);


--
-- TOC entry 6013 (class 0 OID 157581)
-- Dependencies: 562
-- Data for Name: inventory_vendor; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6442 (class 0 OID 0)
-- Dependencies: 561
-- Name: inventory_vendor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_vendor_id_seq', 1, false);


--
-- TOC entry 6011 (class 0 OID 157573)
-- Dependencies: 560
-- Data for Name: inventory_warehouse; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6443 (class 0 OID 0)
-- Dependencies: 559
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inventory_warehouse_id_seq', 1, false);


--
-- TOC entry 6088 (class 0 OID 158276)
-- Dependencies: 638
-- Data for Name: item_order_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6097 (class 0 OID 158367)
-- Dependencies: 647
-- Data for Name: kds_ready_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6009 (class 0 OID 157563)
-- Dependencies: 558
-- Data for Name: kit_ticket_table_num; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6008 (class 0 OID 157552)
-- Dependencies: 557
-- Data for Name: kitchen_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6444 (class 0 OID 0)
-- Dependencies: 556
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('kitchen_ticket_id_seq', 1, false);


--
-- TOC entry 6105 (class 0 OID 158511)
-- Dependencies: 655
-- Data for Name: kitchen_ticket_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6445 (class 0 OID 0)
-- Dependencies: 555
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('kitchen_ticket_item_id_seq', 1, false);


--
-- TOC entry 6004 (class 0 OID 157531)
-- Dependencies: 553
-- Data for Name: menu_category; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6446 (class 0 OID 0)
-- Dependencies: 552
-- Name: menu_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_category_id_seq', 1, false);


--
-- TOC entry 6005 (class 0 OID 157537)
-- Dependencies: 554
-- Data for Name: menu_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6447 (class 0 OID 0)
-- Dependencies: 551
-- Name: menu_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_group_id_seq', 1, false);


--
-- TOC entry 6081 (class 0 OID 158151)
-- Dependencies: 631
-- Data for Name: menu_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6448 (class 0 OID 0)
-- Dependencies: 550
-- Name: menu_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_item_id_seq', 1, false);


--
-- TOC entry 6087 (class 0 OID 158266)
-- Dependencies: 637
-- Data for Name: menu_item_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5997 (class 0 OID 157474)
-- Dependencies: 546
-- Data for Name: menu_item_size; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6449 (class 0 OID 0)
-- Dependencies: 545
-- Name: menu_item_size_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_item_size_id_seq', 1, false);


--
-- TOC entry 6086 (class 0 OID 158253)
-- Dependencies: 636
-- Data for Name: menu_item_terminal_ref; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5994 (class 0 OID 157441)
-- Dependencies: 543
-- Data for Name: menu_modifier; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5993 (class 0 OID 157435)
-- Dependencies: 542
-- Data for Name: menu_modifier_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6450 (class 0 OID 0)
-- Dependencies: 541
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_modifier_group_id_seq', 1, false);


--
-- TOC entry 6451 (class 0 OID 0)
-- Dependencies: 540
-- Name: menu_modifier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_modifier_id_seq', 1, false);


--
-- TOC entry 5995 (class 0 OID 157462)
-- Dependencies: 544
-- Data for Name: menu_modifier_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6058 (class 0 OID 157890)
-- Dependencies: 607
-- Data for Name: menucategory_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6057 (class 0 OID 157877)
-- Dependencies: 606
-- Data for Name: menugroup_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6085 (class 0 OID 158240)
-- Dependencies: 635
-- Data for Name: menuitem_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6084 (class 0 OID 158219)
-- Dependencies: 634
-- Data for Name: menuitem_modifiergroup; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6452 (class 0 OID 0)
-- Dependencies: 539
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menuitem_modifiergroup_id_seq', 1, false);


--
-- TOC entry 6083 (class 0 OID 158206)
-- Dependencies: 633
-- Data for Name: menuitem_pizzapirce; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6082 (class 0 OID 158190)
-- Dependencies: 632
-- Data for Name: menuitem_shift; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6453 (class 0 OID 0)
-- Dependencies: 538
-- Name: menuitem_shift_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menuitem_shift_id_seq', 1, false);


--
-- TOC entry 6000 (class 0 OID 157512)
-- Dependencies: 549
-- Data for Name: menumodifier_pizzamodifierprice; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6096 (class 0 OID 158346)
-- Dependencies: 646
-- Data for Name: modifier_multiplier_price; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6454 (class 0 OID 0)
-- Dependencies: 537
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('modifier_multiplier_price_id_seq', 1, false);


--
-- TOC entry 6095 (class 0 OID 158341)
-- Dependencies: 645
-- Data for Name: multiplier; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5987 (class 0 OID 157414)
-- Dependencies: 536
-- Data for Name: order_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6455 (class 0 OID 0)
-- Dependencies: 535
-- Name: order_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('order_type_id_seq', 1, false);


--
-- TOC entry 5985 (class 0 OID 157404)
-- Dependencies: 534
-- Data for Name: packaging_unit; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6456 (class 0 OID 0)
-- Dependencies: 533
-- Name: packaging_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('packaging_unit_id_seq', 1, false);


--
-- TOC entry 5983 (class 0 OID 157396)
-- Dependencies: 532
-- Data for Name: payout_reasons; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6457 (class 0 OID 0)
-- Dependencies: 531
-- Name: payout_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('payout_reasons_id_seq', 1, false);


--
-- TOC entry 5981 (class 0 OID 157388)
-- Dependencies: 530
-- Data for Name: payout_recepients; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6458 (class 0 OID 0)
-- Dependencies: 529
-- Name: payout_recepients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('payout_recepients_id_seq', 1, false);


--
-- TOC entry 5979 (class 0 OID 157380)
-- Dependencies: 528
-- Data for Name: pizza_crust; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6459 (class 0 OID 0)
-- Dependencies: 527
-- Name: pizza_crust_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pizza_crust_id_seq', 1, false);


--
-- TOC entry 5999 (class 0 OID 157501)
-- Dependencies: 548
-- Data for Name: pizza_modifier_price; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6460 (class 0 OID 0)
-- Dependencies: 526
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pizza_modifier_price_id_seq', 1, false);


--
-- TOC entry 5998 (class 0 OID 157480)
-- Dependencies: 547
-- Data for Name: pizza_price; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6461 (class 0 OID 0)
-- Dependencies: 525
-- Name: pizza_price_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pizza_price_id_seq', 1, false);


--
-- TOC entry 6094 (class 0 OID 158333)
-- Dependencies: 644
-- Data for Name: printer_configuration; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5974 (class 0 OID 157358)
-- Dependencies: 523
-- Data for Name: printer_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6462 (class 0 OID 0)
-- Dependencies: 522
-- Name: printer_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('printer_group_id_seq', 1, false);


--
-- TOC entry 5975 (class 0 OID 157366)
-- Dependencies: 524
-- Data for Name: printer_group_printers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5972 (class 0 OID 157350)
-- Dependencies: 521
-- Data for Name: purchase_order; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6463 (class 0 OID 0)
-- Dependencies: 520
-- Name: purchase_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('purchase_order_id_seq', 1, false);


--
-- TOC entry 5970 (class 0 OID 157342)
-- Dependencies: 519
-- Data for Name: recepie; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6464 (class 0 OID 0)
-- Dependencies: 518
-- Name: recepie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('recepie_id_seq', 1, false);


--
-- TOC entry 6025 (class 0 OID 157668)
-- Dependencies: 574
-- Data for Name: recepie_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6465 (class 0 OID 0)
-- Dependencies: 517
-- Name: recepie_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('recepie_item_id_seq', 1, false);


--
-- TOC entry 6092 (class 0 OID 158315)
-- Dependencies: 642
-- Data for Name: restaurant; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6093 (class 0 OID 158320)
-- Dependencies: 643
-- Data for Name: restaurant_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5966 (class 0 OID 157310)
-- Dependencies: 515
-- Data for Name: shift; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6466 (class 0 OID 0)
-- Dependencies: 514
-- Name: shift_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shift_id_seq', 1, false);


--
-- TOC entry 5960 (class 0 OID 157258)
-- Dependencies: 509
-- Data for Name: shop_floor; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6467 (class 0 OID 0)
-- Dependencies: 508
-- Name: shop_floor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shop_floor_id_seq', 1, false);


--
-- TOC entry 5963 (class 0 OID 157287)
-- Dependencies: 512
-- Data for Name: shop_floor_template; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6468 (class 0 OID 0)
-- Dependencies: 507
-- Name: shop_floor_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shop_floor_template_id_seq', 1, false);


--
-- TOC entry 5964 (class 0 OID 157298)
-- Dependencies: 513
-- Data for Name: shop_floor_template_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5961 (class 0 OID 157264)
-- Dependencies: 510
-- Data for Name: shop_table; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6090 (class 0 OID 158302)
-- Dependencies: 640
-- Data for Name: shop_table_status; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5957 (class 0 OID 157248)
-- Dependencies: 506
-- Data for Name: shop_table_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6469 (class 0 OID 0)
-- Dependencies: 505
-- Name: shop_table_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shop_table_type_id_seq', 1, false);


--
-- TOC entry 6045 (class 0 OID 157785)
-- Dependencies: 594
-- Data for Name: table_booking_info; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6470 (class 0 OID 0)
-- Dependencies: 504
-- Name: table_booking_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('table_booking_info_id_seq', 1, false);


--
-- TOC entry 6046 (class 0 OID 157801)
-- Dependencies: 595
-- Data for Name: table_booking_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6091 (class 0 OID 158307)
-- Dependencies: 641
-- Data for Name: table_ticket_num; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5962 (class 0 OID 157274)
-- Dependencies: 511
-- Data for Name: table_type_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5954 (class 0 OID 157238)
-- Dependencies: 503
-- Data for Name: tax; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6080 (class 0 OID 158146)
-- Dependencies: 630
-- Data for Name: tax_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6471 (class 0 OID 0)
-- Dependencies: 502
-- Name: tax_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tax_id_seq', 1, false);


--
-- TOC entry 6069 (class 0 OID 157964)
-- Dependencies: 618
-- Data for Name: terminal; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6072 (class 0 OID 158008)
-- Dependencies: 621
-- Data for Name: terminal_printers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6472 (class 0 OID 0)
-- Dependencies: 501
-- Name: terminal_printers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('terminal_printers_id_seq', 1, false);


--
-- TOC entry 6071 (class 0 OID 157995)
-- Dependencies: 620
-- Data for Name: terminal_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6099 (class 0 OID 158382)
-- Dependencies: 649
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6110 (class 0 OID 158630)
-- Dependencies: 667
-- Data for Name: ticket_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6473 (class 0 OID 0)
-- Dependencies: 500
-- Name: ticket_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ticket_discount_id_seq', 1, false);


--
-- TOC entry 6474 (class 0 OID 0)
-- Dependencies: 499
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ticket_id_seq', 1, false);


--
-- TOC entry 6100 (class 0 OID 158430)
-- Dependencies: 650
-- Data for Name: ticket_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6104 (class 0 OID 158496)
-- Dependencies: 654
-- Data for Name: ticket_item_addon_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6103 (class 0 OID 158486)
-- Dependencies: 653
-- Data for Name: ticket_item_cooking_instruction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6102 (class 0 OID 158475)
-- Dependencies: 652
-- Data for Name: ticket_item_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6475 (class 0 OID 0)
-- Dependencies: 498
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_discount_id_seq', 1, false);


--
-- TOC entry 6476 (class 0 OID 0)
-- Dependencies: 497
-- Name: ticket_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_id_seq', 1, false);


--
-- TOC entry 5947 (class 0 OID 157220)
-- Dependencies: 496
-- Data for Name: ticket_item_modifier; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6477 (class 0 OID 0)
-- Dependencies: 495
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_modifier_id_seq', 1, false);


--
-- TOC entry 6101 (class 0 OID 158460)
-- Dependencies: 651
-- Data for Name: ticket_item_modifier_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6109 (class 0 OID 158617)
-- Dependencies: 666
-- Data for Name: ticket_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6108 (class 0 OID 158609)
-- Dependencies: 665
-- Data for Name: ticket_table_num; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6107 (class 0 OID 158596)
-- Dependencies: 664
-- Data for Name: transaction_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6106 (class 0 OID 158540)
-- Dependencies: 659
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6478 (class 0 OID 0)
-- Dependencies: 494
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('transactions_id_seq', 1, false);


--
-- TOC entry 6067 (class 0 OID 157944)
-- Dependencies: 616
-- Data for Name: user_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5944 (class 0 OID 157210)
-- Dependencies: 493
-- Data for Name: user_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6479 (class 0 OID 0)
-- Dependencies: 492
-- Name: user_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_type_id_seq', 1, false);


--
-- TOC entry 6068 (class 0 OID 157949)
-- Dependencies: 617
-- Data for Name: user_user_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5967 (class 0 OID 157318)
-- Dependencies: 516
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6480 (class 0 OID 0)
-- Dependencies: 491
-- Name: users_auto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('users_auto_id_seq', 1, false);


--
-- TOC entry 5940 (class 0 OID 157190)
-- Dependencies: 489
-- Data for Name: virtual_printer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6481 (class 0 OID 0)
-- Dependencies: 488
-- Name: virtual_printer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('virtual_printer_id_seq', 1, false);


--
-- TOC entry 5941 (class 0 OID 157198)
-- Dependencies: 490
-- Data for Name: virtualprinter_order_type; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5938 (class 0 OID 157182)
-- Dependencies: 487
-- Data for Name: void_reasons; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6482 (class 0 OID 0)
-- Dependencies: 486
-- Name: void_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('void_reasons_id_seq', 1, false);


--
-- TOC entry 5936 (class 0 OID 157174)
-- Dependencies: 485
-- Data for Name: zip_code_vs_delivery_charge; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6483 (class 0 OID 0)
-- Dependencies: 484
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('zip_code_vs_delivery_charge_auto_id_seq', 1, false);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5667 (class 0 OID 152303)
-- Dependencies: 189
-- Data for Name: alert_events; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6484 (class 0 OID 0)
-- Dependencies: 190
-- Name: alert_events_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_events_id_seq', 1, false);


--
-- TOC entry 5669 (class 0 OID 152314)
-- Dependencies: 191
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6485 (class 0 OID 0)
-- Dependencies: 192
-- Name: alert_rules_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_rules_id_seq', 1, false);


--
-- TOC entry 5671 (class 0 OID 152325)
-- Dependencies: 193
-- Data for Name: almacen; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5672 (class 0 OID 152332)
-- Dependencies: 194
-- Data for Name: audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5673 (class 0 OID 152339)
-- Dependencies: 195
-- Data for Name: audit_log_global; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6486 (class 0 OID 0)
-- Dependencies: 196
-- Name: audit_log_global_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_global_id_seq', 1, false);


--
-- TOC entry 6487 (class 0 OID 0)
-- Dependencies: 197
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_id_seq', 1, false);


--
-- TOC entry 5676 (class 0 OID 152351)
-- Dependencies: 198
-- Data for Name: auditoria; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (1, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-17T09:06:03.217", "dah_id": 126, "operation": "ASIGNAR"}', '2025-09-17 09:06:04.081128-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (2, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-17T09:22:58.68", "dah_id": 127, "operation": "ASIGNAR"}', '2025-09-17 09:22:58.686625-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (3, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-18T08:55:08.491", "dah_id": 130, "operation": "ASIGNAR"}', '2025-09-18 08:55:08.545545-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (4, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-18T09:38:33.973", "dah_id": 131, "operation": "ASIGNAR"}', '2025-09-18 09:38:34.748483-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (5, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-19T08:34:20.654", "dah_id": 134, "operation": "ASIGNAR"}', '2025-09-19 08:34:21.424031-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (6, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-19T09:05:06.502", "dah_id": 135, "operation": "ASIGNAR"}', '2025-09-19 09:05:06.546538-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (7, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-20T09:01:59.5", "dah_id": 138, "operation": "ASIGNAR"}', '2025-09-20 09:02:00.219905-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (8, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-20T09:06:11.135", "dah_id": 139, "operation": "ASIGNAR"}', '2025-09-20 09:06:12.507865-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (9, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-22T08:23:37.943", "dah_id": 142, "operation": "ASIGNAR"}', '2025-09-22 08:23:40.164587-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (10, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-22T08:42:23.967", "dah_id": 143, "operation": "ASIGNAR"}', '2025-09-22 08:42:24.379279-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (11, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-22T08:54:42.608", "dah_id": 146, "operation": "ASIGNAR"}', '2025-09-22 08:54:43.01876-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (12, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-22T08:55:26.437", "dah_id": 147, "operation": "ASIGNAR"}', '2025-09-22 08:55:26.463681-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (13, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-22T15:58:41.388", "dah_id": 148, "operation": "ASIGNAR"}', '2025-09-22 15:58:44.147496-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (14, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-23T09:05:49.234", "dah_id": 151, "operation": "ASIGNAR"}', '2025-09-23 09:05:50.31703-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (15, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-23T09:12:22.319", "dah_id": 152, "operation": "ASIGNAR"}', '2025-09-23 09:12:22.383953-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (16, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-24T08:55:07.788", "dah_id": 155, "operation": "ASIGNAR"}', '2025-09-24 08:55:07.848467-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (17, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-24T09:36:29.527", "dah_id": 156, "operation": "ASIGNAR"}', '2025-09-24 09:36:30.21109-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (18, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-25T09:02:41.923", "dah_id": 159, "operation": "ASIGNAR"}', '2025-09-25 09:02:42.676315-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (19, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-25T09:34:12.819", "dah_id": 160, "operation": "ASIGNAR"}', '2025-09-25 09:34:14.59031-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (20, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-26T08:46:01.273", "dah_id": 163, "operation": "ASIGNAR"}', '2025-09-26 08:46:01.310139-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (21, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-26T08:51:34.061", "dah_id": 164, "operation": "ASIGNAR"}', '2025-09-26 08:51:34.273578-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (22, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-27T08:34:04.289", "dah_id": 167, "operation": "ASIGNAR"}', '2025-09-27 08:34:05.109531-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (23, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-27T09:06:22.867", "dah_id": 168, "operation": "ASIGNAR"}', '2025-09-27 09:06:24.105709-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (24, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-29T09:01:23.765", "dah_id": 171, "operation": "ASIGNAR"}', '2025-09-29 09:01:23.827279-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (25, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-29T09:13:41.633", "dah_id": 172, "operation": "ASIGNAR"}', '2025-09-29 09:13:42.556641-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (26, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-30T07:34:22.236", "dah_id": 177, "operation": "ASIGNAR"}', '2025-09-30 07:34:22.295356-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (27, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-09-30T09:02:39.518", "dah_id": 178, "operation": "ASIGNAR"}', '2025-09-30 09:02:39.594419-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (28, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-01T07:32:59.659", "dah_id": 184, "operation": "ASIGNAR"}', '2025-10-01 07:32:59.763091-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (29, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-01T07:55:41.608", "dah_id": 185, "operation": "ASIGNAR"}', '2025-10-01 07:55:42.45592-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (30, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-01T09:16:09.183", "dah_id": 186, "operation": "ASIGNAR"}', '2025-10-01 09:16:10.61867-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (31, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-02T07:53:37.516", "dah_id": 189, "operation": "ASIGNAR"}', '2025-10-02 07:53:37.537881-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (32, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-02T08:40:27.388", "dah_id": 190, "operation": "ASIGNAR"}', '2025-10-02 08:40:27.395912-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (33, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-02T08:45:53.634", "dah_id": 192, "operation": "ASIGNAR"}', '2025-10-02 08:45:54.688896-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (34, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-03T07:22:54.163", "dah_id": 196, "operation": "ASIGNAR"}', '2025-10-03 07:22:54.235856-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (35, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-03T08:54:37.023", "dah_id": 197, "operation": "ASIGNAR"}', '2025-10-03 08:54:37.094581-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (36, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-03T09:30:34.68", "dah_id": 198, "operation": "ASIGNAR"}', '2025-10-03 09:30:35.753797-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (37, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-04T08:37:46.98", "dah_id": 202, "operation": "ASIGNAR"}', '2025-10-04 08:37:48.614896-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (38, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-04T08:39:49.896", "dah_id": 203, "operation": "ASIGNAR"}', '2025-10-04 08:39:50.938951-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (39, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-06T07:58:10.641", "dah_id": 206, "operation": "ASIGNAR"}', '2025-10-06 07:58:10.890961-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (40, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-06T08:19:02.596", "dah_id": 207, "operation": "ASIGNAR"}', '2025-10-06 08:19:03.292037-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (41, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-07T07:29:05.145", "dah_id": 212, "operation": "ASIGNAR"}', '2025-10-07 07:29:05.297092-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (42, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-07T08:50:28.769", "dah_id": 214, "operation": "ASIGNAR"}', '2025-10-07 08:50:28.797539-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (43, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-08T08:34:05.623", "dah_id": 218, "operation": "ASIGNAR"}', '2025-10-08 08:34:06.872535-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (44, 13, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-08T09:58:21.955", "dah_id": 219, "operation": "ASIGNAR"}', '2025-10-08 09:58:23.297741-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (45, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-09T08:35:26.563", "dah_id": 222, "operation": "ASIGNAR"}', '2025-10-09 08:35:27.204894-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (46, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-09T09:28:19.78", "dah_id": 223, "operation": "ASIGNAR"}', '2025-10-09 09:28:21.068893-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (47, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-10T07:26:30.415", "dah_id": 228, "operation": "ASIGNAR"}', '2025-10-10 07:26:30.557316-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (48, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-10T08:42:13.371", "dah_id": 229, "operation": "ASIGNAR"}', '2025-10-10 08:42:15.822091-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (49, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-11T08:27:08.465", "dah_id": 234, "operation": "ASIGNAR"}', '2025-10-11 08:27:10.31438-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (50, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-11T08:28:34.703", "dah_id": 235, "operation": "ASIGNAR"}', '2025-10-11 08:28:37.111777-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (51, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-13T07:19:16.121", "dah_id": 238, "operation": "ASIGNAR"}', '2025-10-13 07:19:16.258862-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (52, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-13T08:55:19.487", "dah_id": 239, "operation": "ASIGNAR"}', '2025-10-13 08:55:19.518505-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (53, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-14T07:14:29.338", "dah_id": 244, "operation": "ASIGNAR"}', '2025-10-14 07:14:29.514346-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (54, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-14T08:27:04.537", "dah_id": 245, "operation": "ASIGNAR"}', '2025-10-14 08:27:05.84751-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (55, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-15T07:36:32.551", "dah_id": 250, "operation": "ASIGNAR"}', '2025-10-15 07:36:32.674744-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (56, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-15T08:17:38.126", "dah_id": 252, "operation": "ASIGNAR"}', '2025-10-15 08:17:38.405685-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (57, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-16T07:06:23.065", "dah_id": 256, "operation": "ASIGNAR"}', '2025-10-16 07:06:23.103373-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (58, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-16T07:07:00.96", "dah_id": 258, "operation": "ASIGNAR"}', '2025-10-16 07:07:00.991373-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (59, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-16T09:03:55.529", "dah_id": 260, "operation": "ASIGNAR"}', '2025-10-16 09:03:55.646781-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (60, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-17T08:47:04.893", "dah_id": 263, "operation": "ASIGNAR"}', '2025-10-17 08:47:06.451915-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (61, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-18T07:57:40.291", "dah_id": 268, "operation": "ASIGNAR"}', '2025-10-18 07:57:40.121727-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (62, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T08:50:42.114", "dah_id": 271, "operation": "ASIGNAR"}', '2025-10-20 08:50:42.262013-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (63, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-21T08:03:32.316", "dah_id": 275, "operation": "ASIGNAR"}', '2025-10-21 09:03:33.225142-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (64, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-22T08:07:17.347", "dah_id": 280, "operation": "ASIGNAR"}', '2025-10-22 08:07:18.357403-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (65, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-23T08:46:48.664", "dah_id": 283, "operation": "ASIGNAR"}', '2025-10-23 08:46:49.545493-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (66, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-24T07:46:29.323", "dah_id": 287, "operation": "ASIGNAR"}', '2025-10-24 08:46:29.34105-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (67, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-25T08:19:50.827", "dah_id": 292, "operation": "ASIGNAR"}', '2025-10-25 08:19:51.524247-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (68, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-27T08:05:39.203", "dah_id": 295, "operation": "ASIGNAR"}', '2025-10-27 08:05:39.785984-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (69, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-28T08:02:53.052", "dah_id": 300, "operation": "ASIGNAR"}', '2025-10-28 08:02:53.095579-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (70, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-29T07:35:07.677", "dah_id": 304, "operation": "ASIGNAR"}', '2025-10-29 07:35:07.38462-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (71, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-30T07:28:49.2", "dah_id": 307, "operation": "ASIGNAR"}', '2025-10-30 07:28:49.364087-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (72, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-31T08:34:39.643", "dah_id": 311, "operation": "ASIGNAR"}', '2025-10-31 08:34:40.271255-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (73, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-11-03T08:01:00.232", "dah_id": 315, "operation": "ASIGNAR"}', '2025-11-03 08:01:00.23551-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (74, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-11-04T06:56:16.696", "dah_id": 322, "operation": "ASIGNAR"}', '2025-11-04 06:56:16.768307-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (75, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-11-04T07:34:25.306", "dah_id": 323, "operation": "ASIGNAR"}', '2025-11-04 07:34:25.707977-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (76, 6, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-11-05T07:49:53.526", "dah_id": 328, "operation": "ASIGNAR"}', '2025-11-05 07:49:54.14574-06');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (77, 8, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-11-05T08:18:56.19", "dah_id": 329, "operation": "ASIGNAR"}', '2025-11-05 08:18:56.240872-06');


--
-- TOC entry 6488 (class 0 OID 0)
-- Dependencies: 199
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('auditoria_id_seq', 77, true);


--
-- TOC entry 5678 (class 0 OID 152360)
-- Dependencies: 200
-- Data for Name: bodega; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6489 (class 0 OID 0)
-- Dependencies: 201
-- Name: bodega_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('bodega_id_seq', 1, false);


--
-- TOC entry 5680 (class 0 OID 152368)
-- Dependencies: 202
-- Data for Name: cache; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5681 (class 0 OID 152374)
-- Dependencies: 203
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5682 (class 0 OID 152380)
-- Dependencies: 204
-- Data for Name: caja_fondo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5683 (class 0 OID 152387)
-- Dependencies: 205
-- Data for Name: caja_fondo_adj; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6490 (class 0 OID 0)
-- Dependencies: 206
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_adj_id_seq', 1, false);


--
-- TOC entry 5685 (class 0 OID 152396)
-- Dependencies: 207
-- Data for Name: caja_fondo_arqueo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6491 (class 0 OID 0)
-- Dependencies: 208
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_arqueo_id_seq', 1, false);


--
-- TOC entry 6492 (class 0 OID 0)
-- Dependencies: 209
-- Name: caja_fondo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_id_seq', 1, false);


--
-- TOC entry 5688 (class 0 OID 152407)
-- Dependencies: 210
-- Data for Name: caja_fondo_mov; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6493 (class 0 OID 0)
-- Dependencies: 211
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_mov_id_seq', 1, false);


--
-- TOC entry 5690 (class 0 OID 152421)
-- Dependencies: 212
-- Data for Name: caja_fondo_usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5691 (class 0 OID 152424)
-- Dependencies: 213
-- Data for Name: cash_fund_arqueos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6494 (class 0 OID 0)
-- Dependencies: 214
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_arqueos_id_seq', 1, false);


--
-- TOC entry 5693 (class 0 OID 152432)
-- Dependencies: 215
-- Data for Name: cash_fund_movement_audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6495 (class 0 OID 0)
-- Dependencies: 216
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movement_audit_log_id_seq', 1, false);


--
-- TOC entry 5695 (class 0 OID 152441)
-- Dependencies: 217
-- Data for Name: cash_fund_movements; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6496 (class 0 OID 0)
-- Dependencies: 218
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movements_id_seq', 1, false);


--
-- TOC entry 5697 (class 0 OID 152455)
-- Dependencies: 219
-- Data for Name: cash_funds; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6497 (class 0 OID 0)
-- Dependencies: 220
-- Name: cash_funds_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_funds_id_seq', 1, false);


--
-- TOC entry 5699 (class 0 OID 152466)
-- Dependencies: 221
-- Data for Name: cat_almacenes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (1, 'COC', 'COCINA PRINCIPAL', 1, true, '2025-11-02 20:20:49', '2025-11-02 20:20:49');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (2, 'GENERAL', 'GENERAL', NULL, true, '2025-11-02 20:21:05', '2025-11-02 20:21:05');


--
-- TOC entry 6498 (class 0 OID 0)
-- Dependencies: 222
-- Name: cat_almacenes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_almacenes_id_seq', 2, true);


--
-- TOC entry 5701 (class 0 OID 152472)
-- Dependencies: 223
-- Data for Name: cat_proveedores; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (1, 'XAXX010101000-U1', 'URBANO CASTILLO CENTRAL DE ABASTOS', NULL, NULL, true, '2025-11-02 20:23:53', '2025-11-02 20:23:53', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (2, 'AFA8807024B1', 'Abarrotes Fasti S.A. de C.V.', NULL, NULL, true, '2025-11-02 20:24:42', '2025-11-02 20:24:42', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (3, 'NWM9709244W4', 'Sam''''s Club México.', NULL, NULL, true, '2025-11-02 20:24:55', '2025-11-02 20:24:55', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (4, 'CCA8805089W1', 'Costco de México', NULL, NULL, true, '2025-11-02 20:25:06', '2025-11-02 20:25:06', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (5, 'CCO670202HB7', 'Coca-Cola Femsa Veracruz', NULL, NULL, true, '2025-11-02 20:25:17', '2025-11-02 20:25:17', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (6, 'DCO100916H51', 'Distribuidora Comercial Oriental', NULL, NULL, true, '2025-11-02 20:25:37', '2025-11-02 20:25:37', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (7, 'BIM4601016X8', 'Grupo Bimbo', NULL, NULL, true, '2025-11-02 20:25:47', '2025-11-02 20:25:47', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (8, 'CHE8507029B1', 'Chedraui Veracruz filial', NULL, NULL, true, '2025-11-02 20:25:59', '2025-11-02 20:25:59', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (9, 'LJO9201012B1', 'Quesos La Joya Liz S.A. de C.V.', NULL, NULL, true, '2025-11-02 20:26:08', '2025-11-02 20:26:08', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (10, 'XAXX010101000-MP', 'MATERIAS PRIMAS LA AZTECA', NULL, NULL, true, '2025-11-02 20:26:21', '2025-11-02 20:26:21', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (11, 'XAXX010101000-CP', 'COAPEXPAN CARNES FRIAS', NULL, NULL, true, '2025-11-02 20:26:34', '2025-11-02 20:26:34', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (12, 'OFS000526912', 'EL BODEGON DE SEMILLAS, S.A. DE C.V.', NULL, NULL, true, '2025-11-02 20:26:45', '2025-11-02 20:26:45', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (13, 'XAXX010101000-FC', 'FERCAS', NULL, NULL, true, '2025-11-02 20:26:59', '2025-11-02 20:26:59', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (14, 'XAXX010101000-FR', 'FRUTA', NULL, NULL, true, '2025-11-02 20:27:10', '2025-11-02 20:27:10', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (15, 'XAXX010101000-PK', 'PANADERIA KAREN', NULL, NULL, true, '2025-11-02 20:27:22', '2025-11-02 20:27:22', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (16, 'XAXX010101000-GN', 'GENERICO', NULL, NULL, true, '2025-11-02 20:27:41', '2025-11-02 20:27:41', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (17, 'XAXX010101000-SL', 'SAN LUIS', NULL, NULL, true, '2025-11-02 20:27:54', '2025-11-02 20:27:54', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (18, 'XAXX010101000-PE', 'POLLERIA EL DORADO', NULL, NULL, true, '2025-11-02 20:28:10', '2025-11-02 20:28:10', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (19, 'XAXX010101000-QV', 'QUESOS Y ABARROTES VERONICA', NULL, NULL, true, '2025-11-02 20:28:22', '2025-11-02 20:28:22', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (20, 'XAXX010101000-VD', 'VERDURAS', NULL, NULL, true, '2025-11-02 20:28:32', '2025-11-02 20:28:32', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 6499 (class 0 OID 0)
-- Dependencies: 224
-- Name: cat_proveedores_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_proveedores_id_seq', 20, true);


--
-- TOC entry 5703 (class 0 OID 152481)
-- Dependencies: 225
-- Data for Name: cat_sucursales; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) VALUES (1, 'PRINCIPAL', 'Sucursal Principal', 'Ubicacion Principal', true, '2025-11-02 12:35:41', '2025-11-02 12:35:41', 'PRINCIPAL');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) VALUES (2, 'NB', 'Sucursal NB', 'Ubicacion NB', true, '2025-11-02 12:35:41', '2025-11-02 12:35:41', 'NB');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) VALUES (3, 'TORRE', 'Sucursal Torre', 'Ubicacion Torre', true, '2025-11-02 12:35:41', '2025-11-02 12:35:41', 'TORRE');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) VALUES (4, 'SUCURS', 'Sucursal Entrada', NULL, true, '2025-11-02 20:19:40', '2025-11-02 20:19:40', 'ENTRADA');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) VALUES (5, 'SUCURS1', 'Sucursal Selemti', 'Pruebas', true, '2025-11-02 20:19:57', '2025-11-02 20:19:57', 'SelemTI');


--
-- TOC entry 6500 (class 0 OID 0)
-- Dependencies: 226
-- Name: cat_sucursales_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_sucursales_id_seq', 5, true);


--
-- TOC entry 5705 (class 0 OID 152487)
-- Dependencies: 227
-- Data for Name: cat_unidades; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (1, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'KG', 'Kilogramo', true, 'BASE');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (2, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'L', 'Litro', true, 'BASE');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (3, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'PZ', 'Pieza', true, 'BASE');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (4, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'G', 'Gramo', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (5, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'MG', 'Miligramo', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (6, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'ML', 'Mililitro', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (7, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'TAZA', 'Taza', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (8, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'CUCH', 'Cucharada', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (9, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'CUCHT', 'Cucharadita', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (10, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'PIZCA', 'Pizca', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (11, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'VASO', 'Vaso', true, 'COCINA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (12, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'CAJA', 'Caja', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (13, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'COSTAL', 'Costal', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (14, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'BOTELLA', 'Botella', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (15, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'GARRAFA', 'Garrafón', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (16, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'PAQUETE', 'Paquete', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (17, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'CHAROLA', 'Charola', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (18, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'BOLSA', 'Bolsa', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (19, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'BOTE', 'Bote', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (20, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'LATA', 'Lata', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (21, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'FRASCO', 'Frasco', true, 'COMPRA');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (22, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'PORCION', 'Porción', true, 'PORCION');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (23, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'RACION', 'Ración', true, 'PORCION');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (24, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'REBANADA', 'Rebanada', true, 'PORCION');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (25, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'PLATO', 'Plato', true, 'PORCION');
INSERT INTO cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) VALUES (26, '2025-11-02 20:38:36', '2025-11-02 20:38:36', 'ORDEN', 'Orden', true, 'PORCION');


--
-- TOC entry 6501 (class 0 OID 0)
-- Dependencies: 228
-- Name: cat_unidades_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_unidades_id_seq', 26, true);


--
-- TOC entry 5707 (class 0 OID 152493)
-- Dependencies: 229
-- Data for Name: cat_uom_conversion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (1, 4, 1, 0.001000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Conversión estándar: 1 gramo = 0.001 kg');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (2, 5, 1, 0.000001, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Conversión estándar: 1 miligramo = 0.000001 kg');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (3, 10, 1, 0.000500, '2025-11-02 20:53:00', '2025-11-02 20:53:00', false, 'global', 'Aproximado: 1 pizca ≈ 0.5 gramos (0.0005 kg)');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (4, 6, 2, 0.001000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Conversión estándar: 1 mililitro = 0.001 litros');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (5, 7, 2, 0.240000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Taza estándar: 1 taza = 240 ml = 0.240 litros');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (6, 8, 2, 0.015000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Cucharada estándar: 1 cucharada = 15 ml = 0.015 litros');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (7, 9, 2, 0.005000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Cucharadita estándar: 1 cucharadita = 5 ml = 0.005 litros');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (8, 11, 2, 0.250000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Vaso estándar: 1 vaso = 250 ml = 0.250 litros');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (9, 1, 4, 1000.000000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Conversión inversa: 1 kg = 1000 gramos');
INSERT INTO cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) VALUES (10, 2, 6, 1000.000000, '2025-11-02 20:53:00', '2025-11-02 20:53:00', true, 'global', 'Conversión inversa: 1 litro = 1000 mililitros');


--
-- TOC entry 6502 (class 0 OID 0)
-- Dependencies: 230
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_uom_conversion_id_seq', 10, true);


--
-- TOC entry 5709 (class 0 OID 152503)
-- Dependencies: 231
-- Data for Name: conciliacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6503 (class 0 OID 0)
-- Dependencies: 232
-- Name: conciliacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conciliacion_id_seq', 1, false);


--
-- TOC entry 6504 (class 0 OID 0)
-- Dependencies: 235
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conversiones_unidad_id_seq', 1, false);


--
-- TOC entry 5711 (class 0 OID 152518)
-- Dependencies: 234
-- Data for Name: conversiones_unidad_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5713 (class 0 OID 152531)
-- Dependencies: 236
-- Data for Name: cost_layer; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6505 (class 0 OID 0)
-- Dependencies: 237
-- Name: cost_layer_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cost_layer_id_seq', 1, false);


--
-- TOC entry 5715 (class 0 OID 152539)
-- Dependencies: 238
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6506 (class 0 OID 0)
-- Dependencies: 239
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('failed_jobs_id_seq', 1, false);


--
-- TOC entry 5717 (class 0 OID 152548)
-- Dependencies: 240
-- Data for Name: formas_pago; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (1, 'CASH', 'CASH', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (2, 'CREDIT', 'CREDIT', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (3, 'DEBIT', 'DEBIT', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (4, 'TRANSFER', 'TRANSFER', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (5, 'REFUND', 'REFUND', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (6, 'PAY_OUT', 'PAY_OUT', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (7, 'CASH_DROP', 'CASH_DROP', NULL, NULL, NULL, NULL, true, 100, '2025-09-17 08:40:57.876762-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (8, 'CREDIT_CARD', 'CREDIT_CARD', 'CREDIT', 'VISA', NULL, NULL, true, 100, '2025-09-17 09:06:09.509102-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (9, 'CASH', 'CASH', 'CREDIT', 'CASH', NULL, NULL, true, 100, '2025-09-17 09:10:09.104336-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (343, 'DEBIT_CARD', 'DEBIT_CARD', 'CREDIT', 'MASTER CARD', NULL, NULL, true, 100, '2025-09-17 15:35:19.713525-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (1117, 'CREDIT_CARD', 'CREDIT_CARD', 'CREDIT', 'MASTER CARD', NULL, NULL, true, 100, '2025-09-19 11:43:16.717348-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (1591, 'REFUND', 'REFUND', 'DEBIT', 'CASH', NULL, NULL, true, 100, '2025-09-20 16:43:46.046399-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (1592, 'VOID_TRANS', 'VOID_TRANS', 'DEBIT', 'CASH', NULL, NULL, true, 100, '2025-09-20 16:43:46.046399-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (1675, 'DEBIT_CARD', 'DEBIT_CARD', 'CREDIT', 'VISA', NULL, NULL, true, 100, '2025-09-22 10:04:31.673494-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (12351, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', '1', true, 100, '2025-10-20 11:37:17.050812-05');


--
-- TOC entry 6507 (class 0 OID 0)
-- Dependencies: 241
-- Name: formas_pago_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('formas_pago_id_seq', 17077, true);


--
-- TOC entry 5719 (class 0 OID 152559)
-- Dependencies: 242
-- Data for Name: hist_cost_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6508 (class 0 OID 0)
-- Dependencies: 243
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_insumo_id_seq', 1, false);


--
-- TOC entry 5721 (class 0 OID 152572)
-- Dependencies: 244
-- Data for Name: hist_cost_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6509 (class 0 OID 0)
-- Dependencies: 245
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_receta_id_seq', 1, false);


--
-- TOC entry 5723 (class 0 OID 152583)
-- Dependencies: 246
-- Data for Name: historial_costos_item; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6510 (class 0 OID 0)
-- Dependencies: 247
-- Name: historial_costos_item_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_item_id_seq', 1, false);


--
-- TOC entry 5725 (class 0 OID 152600)
-- Dependencies: 248
-- Data for Name: historial_costos_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6511 (class 0 OID 0)
-- Dependencies: 249
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_receta_id_seq', 1, false);


--
-- TOC entry 5727 (class 0 OID 152611)
-- Dependencies: 250
-- Data for Name: insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6512 (class 0 OID 0)
-- Dependencies: 251
-- Name: insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_id_seq', 1, false);


--
-- TOC entry 5729 (class 0 OID 152622)
-- Dependencies: 252
-- Data for Name: insumo_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6513 (class 0 OID 0)
-- Dependencies: 253
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_presentacion_id_seq', 1, false);


--
-- TOC entry 5731 (class 0 OID 152632)
-- Dependencies: 254
-- Data for Name: insumo_proveedor_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6514 (class 0 OID 0)
-- Dependencies: 255
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_proveedor_presentacion_id_seq', 1, false);


--
-- TOC entry 5733 (class 0 OID 152646)
-- Dependencies: 256
-- Data for Name: inv_consumo_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5734 (class 0 OID 152653)
-- Dependencies: 257
-- Data for Name: inv_consumo_pos_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6515 (class 0 OID 0)
-- Dependencies: 258
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_det_id_seq', 1, false);


--
-- TOC entry 6516 (class 0 OID 0)
-- Dependencies: 259
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_id_seq', 1, false);


--
-- TOC entry 5737 (class 0 OID 152663)
-- Dependencies: 260
-- Data for Name: inv_consumo_pos_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6517 (class 0 OID 0)
-- Dependencies: 261
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_log_id_seq', 1, false);


--
-- TOC entry 5739 (class 0 OID 152672)
-- Dependencies: 262
-- Data for Name: inv_stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6518 (class 0 OID 0)
-- Dependencies: 263
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_stock_policy_id_seq', 1, false);


--
-- TOC entry 5741 (class 0 OID 152681)
-- Dependencies: 264
-- Data for Name: inventory_batch; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6519 (class 0 OID 0)
-- Dependencies: 265
-- Name: inventory_batch_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_batch_id_seq', 1, false);


--
-- TOC entry 5743 (class 0 OID 152697)
-- Dependencies: 266
-- Data for Name: inventory_count_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6520 (class 0 OID 0)
-- Dependencies: 267
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_count_lines_id_seq', 1, false);


--
-- TOC entry 5745 (class 0 OID 152708)
-- Dependencies: 268
-- Data for Name: inventory_counts; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6521 (class 0 OID 0)
-- Dependencies: 269
-- Name: inventory_counts_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_counts_id_seq', 1, false);


--
-- TOC entry 5747 (class 0 OID 152719)
-- Dependencies: 270
-- Data for Name: inventory_snapshot; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5748 (class 0 OID 152728)
-- Dependencies: 271
-- Data for Name: inventory_wastes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6522 (class 0 OID 0)
-- Dependencies: 272
-- Name: inventory_wastes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_wastes_id_seq', 1, false);


--
-- TOC entry 5750 (class 0 OID 152737)
-- Dependencies: 273
-- Data for Name: item_categories; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (7, 'Abarrotes', NULL, 'CAT-0007', 'Productos de abarrotes y despensa', true, NULL, '2025-11-03 10:45:00', '2025-11-03 10:45:00');
INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (8, 'Lácteos', NULL, 'CAT-0008', 'Productos lácteos y derivados', true, NULL, '2025-11-03 10:45:00', '2025-11-03 10:45:00');
INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (9, 'Abarrotes', NULL, 'CAT-0009', 'Productos de abarrotes y despensa', true, NULL, '2025-11-03 10:48:23', '2025-11-03 10:48:23');
INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (10, 'Lácteos', NULL, 'CAT-0010', 'Productos lácteos y derivados', true, NULL, '2025-11-03 10:48:23', '2025-11-03 10:48:23');
INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (11, 'CAT-ABARR', 'cat-abarr', 'CAT-ABARR', NULL, true, NULL, '2025-11-05 03:29:35', '2025-11-05 03:29:35');
INSERT INTO item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) VALUES (12, 'CAT-LACT', 'cat-lact', 'CAT-LACT', NULL, true, NULL, '2025-11-05 03:29:35', '2025-11-05 03:29:35');


--
-- TOC entry 6523 (class 0 OID 0)
-- Dependencies: 274
-- Name: item_categories_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_categories_id_seq', 12, true);


--
-- TOC entry 5752 (class 0 OID 152746)
-- Dependencies: 275
-- Data for Name: item_category_counters; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO item_category_counters (category_id, last_val, updated_at) VALUES (12, 4, '2025-11-05 03:29:35');
INSERT INTO item_category_counters (category_id, last_val, updated_at) VALUES (11, 2, '2025-11-05 03:29:35');


--
-- TOC entry 5753 (class 0 OID 152750)
-- Dependencies: 276
-- Data for Name: item_vendor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5754 (class 0 OID 152762)
-- Dependencies: 277
-- Data for Name: item_vendor_prices; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6524 (class 0 OID 0)
-- Dependencies: 278
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_vendor_prices_id_seq', 1, false);


--
-- TOC entry 5756 (class 0 OID 152774)
-- Dependencies: 279
-- Data for Name: items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('LECHE-MEMBERS-01', 'Leche Deslactosada Member''s Mark', 'Leche deslactosada reducida en lactosa', 'CAT-LACT', 'L', true, 2, 8, 220.00, true, '2025-11-03 10:48:23.476701', '2025-11-03 14:26:39', 2, 1.000000, 12, 12.000000, 'MATERIA_PRIMA', NULL, 12, NULL, false, false, false);
INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('LECHE-MEM-01', 'Leche Deslactosada Member''s Mark', 'Leche deslactosada reducida en lactosa', 'CAT-LACT', 'L', true, 2, 8, 220.00, true, '2025-11-03 10:44:59.528047', '2025-11-03 14:26:39', 2, 1.000000, NULL, 1.000000, 'MATERIA_PRIMA', NULL, 12, NULL, false, false, false);
INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('LECHE-NUTRI-01', 'Producto Lácteo Nutri Deslactosada', 'Producto lácteo deslactosado sabor natural', 'CAT-LACT', 'L', true, 2, 8, 280.00, true, '2025-11-03 10:48:23.476701', '2025-11-03 14:26:39', 2, 1.000000, 12, 18.000000, 'MATERIA_PRIMA', NULL, 12, NULL, false, false, false);
INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('ACEITE-NUTRIOLI-01', 'Aceite de Soya Nutrioli', 'Aceite vegetal de soya 100% puro', 'CAT-ABARR', 'L', false, NULL, NULL, 150.00, true, '2025-11-03 10:48:23.476701', '2025-11-03 14:26:39', 2, 1.000000, 16, 2.838000, 'MATERIA_PRIMA', NULL, 11, NULL, false, false, false);
INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('ACEITE-NUT-01', 'Aceite de Soya Nutrioli', 'Aceite vegetal de soya 100% puro', 'CAT-ABARR', 'L', false, NULL, NULL, 150.00, true, '2025-11-03 10:44:59.528047', '2025-11-03 14:26:39', 2, 1.000000, NULL, 1.000000, 'MATERIA_PRIMA', NULL, 11, NULL, false, false, false);
INSERT INTO items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) VALUES ('LECHE-NUT-01', 'Producto Lácteo Nutri Deslactosada', 'Producto lácteo deslactosado sabor natural', 'CAT-LACT', 'L', true, 2, 8, 280.00, true, '2025-11-03 10:44:59.528047', '2025-11-03 14:26:39', 2, 1.000000, NULL, 1.000000, 'MATERIA_PRIMA', NULL, 12, NULL, false, false, false);


--
-- TOC entry 5757 (class 0 OID 152797)
-- Dependencies: 280
-- Data for Name: job_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5758 (class 0 OID 152803)
-- Dependencies: 281
-- Data for Name: job_recalc_queue; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6525 (class 0 OID 0)
-- Dependencies: 282
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('job_recalc_queue_id_seq', 1, false);


--
-- TOC entry 5760 (class 0 OID 152815)
-- Dependencies: 283
-- Data for Name: jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6526 (class 0 OID 0)
-- Dependencies: 284
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('jobs_id_seq', 1, false);


--
-- TOC entry 5762 (class 0 OID 152823)
-- Dependencies: 285
-- Data for Name: labor_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6527 (class 0 OID 0)
-- Dependencies: 286
-- Name: labor_roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('labor_roles_id_seq', 1, false);


--
-- TOC entry 5764 (class 0 OID 152833)
-- Dependencies: 287
-- Data for Name: lote; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6528 (class 0 OID 0)
-- Dependencies: 288
-- Name: lote_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('lote_id_seq', 1, false);


--
-- TOC entry 5766 (class 0 OID 152843)
-- Dependencies: 289
-- Data for Name: menu_engineering_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6529 (class 0 OID 0)
-- Dependencies: 290
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_engineering_snapshots_id_seq', 1, false);


--
-- TOC entry 5768 (class 0 OID 152859)
-- Dependencies: 291
-- Data for Name: menu_item_sync_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6530 (class 0 OID 0)
-- Dependencies: 292
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_item_sync_map_id_seq', 1, false);


--
-- TOC entry 5770 (class 0 OID 152868)
-- Dependencies: 293
-- Data for Name: menu_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6531 (class 0 OID 0)
-- Dependencies: 294
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_items_id_seq', 1, false);


--
-- TOC entry 5772 (class 0 OID 152877)
-- Dependencies: 295
-- Data for Name: merma; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6532 (class 0 OID 0)
-- Dependencies: 296
-- Name: merma_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('merma_id_seq', 1, false);


--
-- TOC entry 5774 (class 0 OID 152888)
-- Dependencies: 297
-- Data for Name: migrations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO migrations (id, migration, batch) VALUES (1, '2025_11_01_132623_add_pos_location_to_cat_sucursales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (2, '2025_11_03_194200_fix_items_inconsistencies', 2);
INSERT INTO migrations (id, migration, batch) VALUES (4, '2025_11_03_194400_fix_all_item_id_types', 3);
INSERT INTO migrations (id, migration, batch) VALUES (5, '2025_11_03_202400_clean_item_descriptions', 4);
INSERT INTO migrations (id, migration, batch) VALUES (6, '0001_01_01_000000_create_users_table', 5);
INSERT INTO migrations (id, migration, batch) VALUES (7, '0001_01_01_000001_create_cache_table', 5);
INSERT INTO migrations (id, migration, batch) VALUES (8, '0001_01_01_000002_create_jobs_table', 5);
INSERT INTO migrations (id, migration, batch) VALUES (9, '2025_01_12_000000_add_preferente_to_selemti_item_vendor', 5);
INSERT INTO migrations (id, migration, batch) VALUES (10, '2025_12_01_120000_create_report_favorites_table', 6);
INSERT INTO migrations (id, migration, batch) VALUES (11, '2025_01_23_100000_create_cash_funds_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (12, '2025_01_23_100001_create_cash_fund_movements_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (13, '2025_01_23_100002_create_cash_fund_arqueos_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (14, '2025_01_23_110000_create_cash_fund_movement_audit_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (15, '2025_09_26_090415_create_cat_unidades_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (16, '2025_09_26_090657_create_cat_unidades_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (17, '2025_09_26_205955_create_permission_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (18, '2025_10_18_000001_create_cat_sucursales_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (19, '2025_10_18_000002_create_cat_almacenes_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (20, '2025_10_18_000003_create_cat_proveedores_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (21, '2025_10_18_000004_create_cat_uom_conversion_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (22, '2025_10_18_000005_create_inv_stock_policy_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (23, '2025_10_19_000001_update_cat_unidades_structure', 7);
INSERT INTO migrations (id, migration, batch) VALUES (24, '2025_10_21_100100_alter_cat_proveedores_add_fields', 7);
INSERT INTO migrations (id, migration, batch) VALUES (25, '2025_10_21_100200_alter_item_vendor_add_vendor_sku', 7);
INSERT INTO migrations (id, migration, batch) VALUES (26, '2025_10_21_123344_add_preferente_to_selemti_item_vendor', 7);
INSERT INTO migrations (id, migration, batch) VALUES (27, '2025_10_21_180000_create_item_categories', 7);
INSERT INTO migrations (id, migration, batch) VALUES (28, '2025_10_21_180100_backfill_item_categories', 7);
INSERT INTO migrations (id, migration, batch) VALUES (29, '2025_10_21_180200_ensure_items_id_autoincrement', 7);
INSERT INTO migrations (id, migration, batch) VALUES (30, '2025_10_21_190100_alter_items_add_item_code', 7);
INSERT INTO migrations (id, migration, batch) VALUES (31, '2025_10_21_190200_item_code_trigger_and_counter', 7);
INSERT INTO migrations (id, migration, batch) VALUES (32, '2025_10_21_190300_backfill_item_codes', 7);
INSERT INTO migrations (id, migration, batch) VALUES (33, '2025_10_21_200000_create_item_vendor_prices', 7);
INSERT INTO migrations (id, migration, batch) VALUES (34, '2025_10_21_200100_fn_item_cost_at', 7);
INSERT INTO migrations (id, migration, batch) VALUES (35, '2025_10_21_200200_recipe_versioning_and_history', 7);
INSERT INTO migrations (id, migration, batch) VALUES (36, '2025_10_21_200300_fn_recipe_cost_at', 7);
INSERT INTO migrations (id, migration, batch) VALUES (37, '2025_10_21_200400_sp_snapshot_recipe_cost', 7);
INSERT INTO migrations (id, migration, batch) VALUES (38, '2025_10_21_200500_alert_rules_and_events', 7);
INSERT INTO migrations (id, migration, batch) VALUES (39, '2025_10_21_200500_create_item_last_price_views', 7);
INSERT INTO migrations (id, migration, batch) VALUES (40, '2025_10_21_200600_trg_on_price_change_alerts', 7);
INSERT INTO migrations (id, migration, batch) VALUES (41, '2025_10_23_154901_add_descripcion_to_cash_funds_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (42, '2025_10_24_000000_add_almacen_id_to_recepcion_cab', 7);
INSERT INTO migrations (id, migration, batch) VALUES (43, '2025_10_24_014612_add_numero_recepcion_to_recepcion_cab_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (44, '2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (45, '2025_10_24_020818_add_missing_inventory_fields_to_recepcion_cab_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (46, '2025_10_24_100000_create_replenishment_suggestions_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (47, '2025_10_24_120000_create_purchase_suggestions_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (48, '2025_10_24_120101_create_purchase_suggestion_lines_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (49, '2025_10_24_120102_alter_purchase_requests_add_fields', 7);
INSERT INTO migrations (id, migration, batch) VALUES (50, '2025_10_26_000002_add_operational_flags_to_items', 7);
INSERT INTO migrations (id, migration, batch) VALUES (51, '2025_10_26_000004_add_unit_cost_to_inventory_batch', 7);
INSERT INTO migrations (id, migration, batch) VALUES (52, '2025_10_26_000005_create_pos_map_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (53, '2025_10_26_000006_create_ticket_item_modifiers_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (54, '2025_10_27_100239_create_pos_reverse_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (55, '2025_10_27_100252_create_pos_reprocess_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (56, '2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det', 7);
INSERT INTO migrations (id, migration, batch) VALUES (57, '2025_10_27_153528_create_personal_access_tokens_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (58, '2025_10_28_000001_update_inv_consumo_flags', 7);
INSERT INTO migrations (id, migration, batch) VALUES (59, '2025_10_28_000002_drop_public_ticket_trigger', 7);
INSERT INTO migrations (id, migration, batch) VALUES (60, '2025_10_28_000003_add_display_fields_to_roles_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (61, '2025_10_28_000010_create_audit_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (62, '2025_10_28_200000_add_indexes_to_audit_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (63, '2025_10_28_200001_add_foreign_key_to_audit_log_table', 7);
INSERT INTO migrations (id, migration, batch) VALUES (64, '2025_10_30_000000_add_remember_token_to_selemti_users', 7);
INSERT INTO migrations (id, migration, batch) VALUES (65, '2025_10_30_120000_add_code_columns_to_insumo', 7);
INSERT INTO migrations (id, migration, batch) VALUES (66, '2025_11_03_194300_fix_item_id_data_types', 7);
INSERT INTO migrations (id, migration, batch) VALUES (67, '2025_11_04_000900_create_additional_sales_report_views', 7);
INSERT INTO migrations (id, migration, batch) VALUES (68, '2025_11_06_120000_refresh_sales_report_views', 7);
INSERT INTO migrations (id, migration, batch) VALUES (69, '2025_11_15_000000_create_inventory_receiving_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (70, '2025_11_15_010000_create_inventory_counts_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (71, '2025_11_15_020000_create_production_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (72, '2025_11_15_030000_create_pos_consumption_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (73, '2025_11_15_050000_create_purchasing_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (74, '2025_11_15_060000_create_costing_extension_tables', 7);
INSERT INTO migrations (id, migration, batch) VALUES (75, '2025_11_15_070000_create_pos_sync_tables', 8);
INSERT INTO migrations (id, migration, batch) VALUES (76, '2025_11_15_080000_create_menu_engineering_tables', 8);
INSERT INTO migrations (id, migration, batch) VALUES (77, '2025_11_15_090000_extend_alert_tables', 8);
INSERT INTO migrations (id, migration, batch) VALUES (79, '2025_11_15_100000_create_reporting_tables', 9);


--
-- TOC entry 6533 (class 0 OID 0)
-- Dependencies: 298
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('migrations_id_seq', 79, true);


--
-- TOC entry 5776 (class 0 OID 152893)
-- Dependencies: 299
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5777 (class 0 OID 152896)
-- Dependencies: 300
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO model_has_roles (role_id, model_type, model_id) VALUES (1, 'App\Models\User', 3);


--
-- TOC entry 5778 (class 0 OID 152899)
-- Dependencies: 301
-- Data for Name: modificadores_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6534 (class 0 OID 0)
-- Dependencies: 302
-- Name: modificadores_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('modificadores_pos_id_seq', 1, false);


--
-- TOC entry 5780 (class 0 OID 152907)
-- Dependencies: 303
-- Data for Name: mov_inv; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6535 (class 0 OID 0)
-- Dependencies: 304
-- Name: mov_inv_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('mov_inv_id_seq', 1, false);


--
-- TOC entry 5788 (class 0 OID 152996)
-- Dependencies: 311
-- Data for Name: op_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6536 (class 0 OID 0)
-- Dependencies: 312
-- Name: op_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_cab_id_seq', 1, false);


--
-- TOC entry 5790 (class 0 OID 153008)
-- Dependencies: 313
-- Data for Name: op_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6537 (class 0 OID 0)
-- Dependencies: 314
-- Name: op_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_insumo_id_seq', 1, false);


--
-- TOC entry 5792 (class 0 OID 153018)
-- Dependencies: 315
-- Data for Name: op_produccion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6538 (class 0 OID 0)
-- Dependencies: 316
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_produccion_cab_id_seq', 1, false);


--
-- TOC entry 5794 (class 0 OID 153028)
-- Dependencies: 317
-- Data for Name: op_yield; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5795 (class 0 OID 153035)
-- Dependencies: 318
-- Data for Name: overhead_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6539 (class 0 OID 0)
-- Dependencies: 319
-- Name: overhead_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('overhead_definitions_id_seq', 1, false);


--
-- TOC entry 5797 (class 0 OID 153046)
-- Dependencies: 320
-- Data for Name: param_sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6540 (class 0 OID 0)
-- Dependencies: 321
-- Name: param_sucursal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('param_sucursal_id_seq', 1, false);


--
-- TOC entry 5799 (class 0 OID 153059)
-- Dependencies: 322
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5800 (class 0 OID 153065)
-- Dependencies: 323
-- Data for Name: perdida_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6541 (class 0 OID 0)
-- Dependencies: 324
-- Name: perdida_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('perdida_log_id_seq', 1, false);


--
-- TOC entry 5802 (class 0 OID 153076)
-- Dependencies: 325
-- Data for Name: permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (1, 'inventory.view', 'web', '2025-11-02 12:31:12', '2025-11-02 12:31:12');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (2, 'inventory.items.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (3, 'inventory.prices.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (4, 'inventory.receivings.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (5, 'inventory.receptions.validate', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (6, 'inventory.receptions.override_tolerance', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (7, 'inventory.receptions.post', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (8, 'inventory.counts.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (9, 'inventory.moves.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (10, 'inventory.lots.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (11, 'inventory.transfers.approve', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (12, 'inventory.transfers.ship', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (13, 'inventory.transfers.receive', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (14, 'inventory.transfers.post', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (15, 'recipes.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (16, 'recipes.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (17, 'recipes.costs.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (18, 'recipes.production.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (19, 'production.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (20, 'purchasing.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (21, 'purchasing.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (22, 'menu.engineering.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (23, 'menu.engineering.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (24, 'reports.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (25, 'reports.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (26, 'alerts.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (27, 'alerts.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (28, 'alerts.assign', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (29, 'audit.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (30, 'vendors.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (31, 'vendors.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (32, 'pos.sync.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (33, 'cashfund.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (34, 'cashfund.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (35, 'people.view', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (36, 'people.users.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (37, 'people.roles.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (38, 'people.permissions.manage', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (39, 'admin.access', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (40, 'can_view_recipe_dashboard', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (41, 'can_reprocess_sales', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (42, 'can_edit_production_order', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (43, 'can_manage_purchasing', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (44, 'can_modify_recipe', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');
INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES (45, 'kitchen.view_kds', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13');


--
-- TOC entry 6542 (class 0 OID 0)
-- Dependencies: 326
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('permissions_id_seq', 45, true);


--
-- TOC entry 5804 (class 0 OID 153084)
-- Dependencies: 327
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) VALUES (79, 'App\Models\User', 3, 'browser-dashboard', 'ee4f77ddf449e14801eac121ca3653aea174daa136cd6284ee82e841183abd19', '["*"]', '2025-11-05 22:55:29', NULL, '2025-11-05 22:55:28', '2025-11-05 22:55:29');


--
-- TOC entry 6543 (class 0 OID 0)
-- Dependencies: 328
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('personal_access_tokens_id_seq', 79, true);


--
-- TOC entry 5806 (class 0 OID 153092)
-- Dependencies: 329
-- Data for Name: pos_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5807 (class 0 OID 153102)
-- Dependencies: 330
-- Data for Name: pos_modifiers_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5808 (class 0 OID 153114)
-- Dependencies: 331
-- Data for Name: pos_reprocess_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6544 (class 0 OID 0)
-- Dependencies: 332
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reprocess_log_id_seq', 1, false);


--
-- TOC entry 5810 (class 0 OID 153125)
-- Dependencies: 333
-- Data for Name: pos_reverse_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6545 (class 0 OID 0)
-- Dependencies: 334
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reverse_log_id_seq', 1, false);


--
-- TOC entry 5812 (class 0 OID 153136)
-- Dependencies: 335
-- Data for Name: pos_sync_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6546 (class 0 OID 0)
-- Dependencies: 336
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_batches_id_seq', 1, false);


--
-- TOC entry 5814 (class 0 OID 153148)
-- Dependencies: 337
-- Data for Name: pos_sync_logs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6547 (class 0 OID 0)
-- Dependencies: 338
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_logs_id_seq', 1, false);


--
-- TOC entry 5816 (class 0 OID 153157)
-- Dependencies: 339
-- Data for Name: postcorte; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (1, 5, 2390.80, 2440.00, 49.20, 'EN_CONTRA', 3676.00, 3676.00, 0.00, 'CUADRA', '2025-09-19 18:40:17.932454-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-19 18:40:36.381355-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (2, 6, 5146.80, 7662.00, 2515.20, 'A_FAVOR', 6477.00, 6517.00, 40.00, 'A_FAVOR', '2025-09-19 18:42:11.002586-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL);
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (4, 8, 5170.80, 7208.00, 2037.20, 'EN_CONTRA', 2581.00, 2581.00, 0.00, 'CUADRA', '2025-09-20 17:20:42.259148-05', 1, 'Parte del faltante estaba en caja 101 $282, con $180.00 faltante en efectivo', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-20 17:49:37.436832-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (5, 7, 8132.80, 10915.00, 2782.20, 'A_FAVOR', 6063.00, 6105.00, 42.00, 'A_FAVOR', '2025-09-20 17:36:02.768915-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-20 17:54:42.308064-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (7, 12, 10312.40, 8463.00, -1849.40, 'EN_CONTRA', 7311.00, 7247.00, -64.00, 'EN_CONTRA', '2025-09-22 19:13:37.154518-05', 1, 'SE TOMARON $4,552 Hay una diferencia de $372.6', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-22 19:15:15.987446-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (8, 14, 4209.00, 6012.00, 1803.00, 'EN_CONTRA', 3021.00, 3085.00, 64.00, 'A_FAVOR', '2025-09-23 19:21:40.19596-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-23 19:22:11.906841-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (9, 15, 8149.00, 11819.00, 3670.00, 'A_FAVOR', 8138.80, 8138.80, 0.00, 'CUADRA', '2025-09-23 19:22:23.718303-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-23 19:22:27.722591-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (10, 18, 8631.00, 8672.00, 41.00, 'EN_CONTRA', 9706.00, 9826.00, 120.00, 'A_FAVOR', '2025-09-25 18:48:06.736863-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-25 18:48:13.046387-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (11, 19, 4266.60, 6911.50, 2644.90, 'A_FAVOR', 3913.00, 3888.00, -25.00, 'EN_CONTRA', '2025-09-25 19:07:18.831377-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-25 19:07:22.038903-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (12, 21, 3345.00, 6053.00, 2708.00, 'A_FAVOR', 2536.00, 2448.00, -88.00, 'EN_CONTRA', '2025-09-26 19:19:22.954022-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-26 19:19:30.14417-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (13, 20, 6701.80, 9258.00, 2556.20, 'A_FAVOR', 7110.80, 7065.80, -45.00, 'EN_CONTRA', '2025-09-26 19:31:26.738896-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-26 19:31:31.758857-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (14, 22, 12107.00, 14768.00, 2661.00, 'A_FAVOR', 7408.00, 7408.00, 0.00, 'CUADRA', '2025-09-27 17:02:41.578846-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-27 17:03:18.130218-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (15, 23, 8141.00, 10541.00, 2400.00, 'EN_CONTRA', 5523.20, 5523.20, 0.00, 'CUADRA', '2025-09-27 17:21:00.177925-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-27 17:21:40.921717-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (16, 24, 8911.00, 8661.00, -250.00, 'EN_CONTRA', 8077.00, 8019.00, -58.00, 'EN_CONTRA', '2025-09-29 18:43:33.16515-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-29 18:43:37.798515-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (17, 28, 8937.80, 12232.00, 3294.20, 'A_FAVOR', 9262.00, 9232.00, -30.00, 'EN_CONTRA', '2025-09-30 18:34:47.438661-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-09-30 18:34:50.462961-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (18, 32, 6755.00, 5912.00, -843.00, 'EN_CONTRA', 9230.00, 9182.00, -48.00, 'EN_CONTRA', '2025-10-01 19:24:37.116734-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-01 19:24:39.948505-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (19, 36, 3481.00, 5913.00, 2432.00, 'EN_CONTRA', 3406.00, 3474.00, 68.00, 'A_FAVOR', '2025-10-02 19:17:19.725233-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-02 19:17:25.740326-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (20, 35, 10325.80, 12508.00, 2182.20, 'EN_CONTRA', 11662.00, 11408.00, -254.00, 'EN_CONTRA', '2025-10-02 19:34:33.257465-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-02 19:36:15.801037-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (22, 39, 2350.00, 4697.00, 2347.00, 'EN_CONTRA', 1904.00, 3436.00, 1532.00, 'A_FAVOR', '2025-10-03 18:56:23.112019-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-03 18:56:39.158723-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (23, 38, 6087.00, 5371.00, -716.00, 'EN_CONTRA', 9312.20, 9093.00, -219.20, 'EN_CONTRA', '2025-10-03 19:13:48.415782-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-03 19:13:50.761456-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (24, 43, 8775.00, 11448.00, 2673.00, 'A_FAVOR', 10732.80, 10728.80, -4.00, 'EN_CONTRA', '2025-10-06 19:12:48.777878-05', 1, '', 0.00, 0.00, 0.00, 'CUADRA', true, 1, '2025-10-06 19:15:01.575493-05');


--
-- TOC entry 6548 (class 0 OID 0)
-- Dependencies: 340
-- Name: postcorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('postcorte_id_seq', 25, true);


--
-- TOC entry 5818 (class 0 OID 153182)
-- Dependencies: 341
-- Data for Name: precorte; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (2, 6, 7662.00, 6517.00, 'ENVIADO', '2025-09-19 18:18:47.744592-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (1, 5, 2440.00, 3676.00, 'ENVIADO', '2025-09-19 17:09:32.076298-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (4, 8, 7208.00, 2581.00, 'ENVIADO', '2025-09-20 17:01:22.84404-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (3, 7, 10915.00, 6105.00, 'ENVIADO', '2025-09-20 16:56:57.42353-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (5, 12, 8463.00, 7247.00, 'ENVIADO', '2025-09-22 19:03:03.666758-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (6, 15, 11819.00, 8138.80, 'ENVIADO', '2025-09-23 18:56:42.176694-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (7, 14, 6012.00, 3085.00, 'ENVIADO', '2025-09-23 19:13:35.737952-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (8, 18, 8672.00, 9826.00, 'ENVIADO', '2025-09-25 18:46:08.310003-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (9, 19, 6911.50, 3888.00, 'ENVIADO', '2025-09-25 19:03:21.011982-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (10, 20, 9258.00, 7065.80, 'ENVIADO', '2025-09-26 17:59:23.355418-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (11, 21, 6053.00, 2448.00, 'ENVIADO', '2025-09-26 18:52:24.021418-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (12, 22, 14768.00, 7408.00, 'ENVIADO', '2025-09-27 16:57:35.438419-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (13, 23, 10541.00, 5523.20, 'ENVIADO', '2025-09-27 17:09:01.378508-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (14, 24, 8661.00, 8019.00, 'ENVIADO', '2025-09-29 18:30:31.600467-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (15, 25, 0.00, 0.00, 'PENDIENTE', '2025-09-29 19:05:23.590335-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (16, 28, 12232.00, 9232.00, 'ENVIADO', '2025-09-30 18:24:35.214393-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (17, 30, 5095.00, 4214.00, 'ENVIADO', '2025-09-30 18:41:11.855713-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (19, 33, 0.00, 0.00, 'PENDIENTE', '2025-10-01 18:49:58.881504-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (18, 32, 5912.00, 9182.00, 'ENVIADO', '2025-10-01 18:45:43.373671-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (21, 36, 5913.00, 3474.00, 'ENVIADO', '2025-10-02 19:07:04.667897-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (20, 35, 12508.00, 11408.00, 'ENVIADO', '2025-10-02 18:39:44.010517-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (23, 38, 5371.00, 9093.00, 'ENVIADO', '2025-10-03 18:47:41.401247-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (22, 39, 4697.00, 3436.00, 'ENVIADO', '2025-10-03 17:56:35.072466-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (24, 43, 11448.00, 10728.80, 'ENVIADO', '2025-10-06 18:57:13.844652-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (25, 45, 5959.00, 2676.20, 'ENVIADO', '2025-10-06 19:14:51.334894-05', NULL, NULL, NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (26, 51, 0.00, 0.00, 'PENDIENTE', '2025-10-08 18:51:01.556257-05', NULL, NULL, NULL);


--
-- TOC entry 5819 (class 0 OID 153193)
-- Dependencies: 342
-- Data for Name: precorte_efectivo; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (1, 2, 1000.00, 7, 7000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (2, 2, 100.00, 6, 600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (3, 2, 50.00, 1, 50.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (4, 2, 10.00, 1, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (5, 2, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (6, 1, 200.00, 8, 1600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (7, 1, 100.00, 8, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (8, 1, 20.00, 2, 40.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (9, 4, 500.00, 6, 3000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (10, 4, 200.00, 4, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (11, 4, 100.00, 20, 2000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (12, 4, 50.00, 10, 500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (13, 4, 20.00, 16, 320.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (14, 4, 5.00, 73, 365.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (15, 4, 10.00, 8, 80.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (16, 4, 1.00, 2, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (17, 4, 0.50, 2, 1.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (18, 4, 2.00, 70, 140.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (19, 3, 200.00, 22, 4400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (20, 3, 100.00, 36, 3600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (21, 3, 50.00, 6, 300.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (22, 3, 20.00, 3, 60.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (23, 3, 10.00, 104, 1040.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (24, 3, 5.00, 235, 1175.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (25, 3, 2.00, 85, 170.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (26, 3, 1.00, 170, 170.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (27, 5, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (28, 5, 200.00, 4, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (29, 5, 100.00, 32, 3200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (30, 5, 50.00, 7, 350.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (31, 5, 10.00, 128, 1280.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (32, 5, 5.00, 202, 1010.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (33, 5, 2.00, 230, 460.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (34, 5, 1.00, 363, 363.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (35, 6, 1000.00, 4, 4000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (36, 6, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (37, 6, 200.00, 9, 1800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (38, 6, 100.00, 30, 3000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (39, 6, 50.00, 26, 1300.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (40, 6, 20.00, 7, 140.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (41, 6, 10.00, 14, 140.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (42, 6, 5.00, 74, 370.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (43, 6, 2.00, 17, 34.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (44, 6, 1.00, 32, 32.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (45, 6, 0.50, 6, 3.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (46, 7, 500.00, 4, 2000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (47, 7, 200.00, 6, 1200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (48, 7, 100.00, 11, 1100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (49, 7, 50.00, 22, 1100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (50, 7, 20.00, 3, 60.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (51, 7, 10.00, 7, 70.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (52, 7, 5.00, 84, 420.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (53, 7, 2.00, 19, 38.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (54, 7, 1.00, 24, 24.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (55, 8, 1000.00, 8, 8000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (56, 8, 500.00, 1, 500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (57, 8, 100.00, 1, 100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (58, 8, 20.00, 1, 20.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (59, 8, 50.00, 1, 50.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (60, 8, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (61, 9, 500.00, 1, 500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (62, 9, 200.00, 10, 2000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (63, 9, 100.00, 17, 1700.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (64, 9, 50.00, 49, 2450.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (65, 9, 5.00, 12, 60.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (66, 9, 10.00, 9, 90.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (67, 9, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (68, 9, 1.00, 105, 105.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (69, 9, 0.50, 9, 4.50);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (70, 10, 500.00, 3, 1500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (71, 10, 200.00, 2, 400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (72, 10, 100.00, 28, 2800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (73, 10, 50.00, 56, 2800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (74, 10, 20.00, 4, 80.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (75, 10, 5.00, 137, 685.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (76, 10, 2.00, 146, 292.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (77, 10, 1.00, 101, 101.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (78, 10, 10.00, 60, 600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (79, 11, 1000.00, 1, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (80, 11, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (81, 11, 200.00, 5, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (82, 11, 100.00, 4, 400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (83, 11, 50.00, 36, 1800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (84, 11, 20.00, 3, 60.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (85, 11, 2.00, 35, 70.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (86, 11, 10.00, 13, 130.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (87, 11, 1.00, 63, 63.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (88, 11, 5.00, 106, 530.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (89, 12, 1000.00, 2, 2000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (90, 12, 500.00, 19, 9500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (91, 12, 200.00, 11, 2200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (92, 12, 100.00, 10, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (93, 12, 50.00, 1, 50.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (94, 12, 1.00, 3, 3.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (95, 12, 5.00, 1, 5.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (96, 12, 10.00, 1, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (97, 13, 500.00, 4, 2000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (98, 13, 200.00, 18, 3600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (99, 13, 100.00, 23, 2300.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (100, 13, 50.00, 52, 2600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (101, 13, 5.00, 2, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (102, 13, 1.00, 31, 31.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (103, 14, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (104, 14, 200.00, 16, 3200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (105, 14, 100.00, 25, 2500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (106, 14, 50.00, 12, 600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (107, 14, 20.00, 5, 100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (108, 14, 10.00, 34, 340.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (109, 14, 5.00, 106, 530.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (110, 14, 1.00, 205, 205.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (111, 14, 2.00, 93, 186.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (112, 16, 500.00, 1, 500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (113, 16, 5.00, 119, 595.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (114, 16, 10.00, 5, 50.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (115, 16, 2.00, 100, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (116, 16, 1.00, 387, 387.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (117, 16, 200.00, 25, 5000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (118, 16, 100.00, 37, 3700.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (119, 16, 50.00, 32, 1600.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (120, 16, 20.00, 10, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (121, 17, 200.00, 11, 2200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (122, 17, 100.00, 10, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (123, 17, 50.00, 25, 1250.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (124, 17, 20.00, 1, 20.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (125, 17, 10.00, 1, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (126, 17, 1.00, 8, 8.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (127, 17, 5.00, 121, 605.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (128, 17, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (129, 18, 500.00, 3, 1500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (130, 18, 200.00, 4, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (131, 18, 100.00, 9, 900.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (132, 18, 50.00, 24, 1200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (133, 18, 20.00, 8, 160.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (134, 18, 1.00, 284, 284.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (135, 18, 2.00, 124, 248.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (136, 18, 10.00, 34, 340.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (137, 18, 5.00, 96, 480.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (138, 21, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (139, 21, 200.00, 1, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (140, 21, 100.00, 21, 2100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (141, 21, 50.00, 46, 2300.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (142, 21, 5.00, 46, 230.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (143, 21, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (144, 21, 1.00, 71, 71.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (145, 21, 10.00, 1, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (146, 20, 500.00, 9, 4500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (147, 20, 200.00, 7, 1400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (148, 20, 100.00, 38, 3800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (149, 20, 50.00, 37, 1850.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (150, 20, 20.00, 27, 540.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (151, 20, 2.00, 53, 106.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (152, 20, 5.00, 53, 265.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (153, 20, 1.00, 47, 47.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (154, 23, 500.00, 1, 500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (155, 23, 200.00, 2, 400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (156, 23, 100.00, 2, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (157, 23, 50.00, 55, 2750.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (158, 23, 20.00, 28, 560.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (159, 23, 1.00, 344, 344.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (160, 23, 2.00, 131, 262.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (161, 23, 5.00, 19, 95.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (162, 23, 10.00, 26, 260.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (163, 22, 500.00, 2, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (164, 22, 200.00, 1, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (165, 22, 100.00, 8, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (166, 22, 50.00, 48, 2400.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (167, 22, 20.00, 2, 40.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (168, 22, 10.00, 5, 50.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (169, 22, 5.00, 9, 45.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (170, 22, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (171, 22, 1.00, 160, 160.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (172, 24, 500.00, 5, 2500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (173, 24, 200.00, 14, 2800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (174, 24, 100.00, 3, 300.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (175, 24, 50.00, 3, 150.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (176, 24, 1000.00, 5, 5000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (177, 24, 20.00, 2, 40.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (178, 24, 2.00, 123, 246.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (179, 24, 10.00, 3, 30.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (180, 24, 5.00, 44, 220.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (181, 24, 1.00, 162, 162.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (182, 25, 1000.00, 1, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (183, 25, 500.00, 5, 2500.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (184, 25, 200.00, 4, 800.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (185, 25, 100.00, 7, 700.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (186, 25, 50.00, 3, 150.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (187, 25, 20.00, 4, 80.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (188, 25, 10.00, 31, 310.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (189, 25, 5.00, 61, 305.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (190, 25, 2.00, 1, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (191, 25, 1.00, 112, 112.00);


--
-- TOC entry 6549 (class 0 OID 0)
-- Dependencies: 343
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_efectivo_id_seq', 191, true);


--
-- TOC entry 6550 (class 0 OID 0)
-- Dependencies: 344
-- Name: precorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_id_seq', 26, true);


--
-- TOC entry 5822 (class 0 OID 153201)
-- Dependencies: 345
-- Data for Name: precorte_otros; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (1, 2, 'CREDITO', 5711.00, NULL, NULL, '', '2025-09-19 18:21:55.001189-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (2, 2, 'DEBITO', 806.00, NULL, NULL, '', '2025-09-19 18:21:55.001189-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (3, 1, 'CREDITO', 3416.00, NULL, NULL, '', '2025-09-19 18:40:11.568475-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (4, 1, 'DEBITO', 260.00, NULL, NULL, '', '2025-09-19 18:40:11.568475-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (5, 4, 'CREDITO', 1077.00, NULL, NULL, '', '2025-09-20 17:08:21.380278-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (6, 4, 'DEBITO', 1504.00, NULL, NULL, '', '2025-09-20 17:08:21.380278-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (7, 3, 'CREDITO', 1550.00, NULL, NULL, '', '2025-09-20 17:28:07.566137-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (8, 3, 'DEBITO', 4555.00, NULL, NULL, '', '2025-09-20 17:28:07.566137-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (9, 5, 'CREDITO', 1891.00, NULL, NULL, '', '2025-09-22 19:12:34.803104-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (10, 5, 'DEBITO', 5356.00, NULL, NULL, '', '2025-09-22 19:12:34.803104-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (11, 6, 'CREDITO', 1956.00, NULL, NULL, '', '2025-09-23 19:06:12.730547-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (12, 6, 'DEBITO', 6182.80, NULL, NULL, '', '2025-09-23 19:06:12.730547-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (13, 7, 'CREDITO', 701.00, NULL, NULL, '', '2025-09-23 19:20:10.001467-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (14, 7, 'DEBITO', 2384.00, NULL, NULL, '', '2025-09-23 19:20:10.001467-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (15, 8, 'CREDITO', 2316.00, NULL, NULL, '', '2025-09-25 18:47:55.732764-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (16, 8, 'DEBITO', 7510.00, NULL, NULL, '', '2025-09-25 18:47:55.732764-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (17, 9, 'CREDITO', 1151.00, NULL, NULL, '', '2025-09-25 19:06:21.200563-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (18, 9, 'DEBITO', 2737.00, NULL, NULL, '', '2025-09-25 19:06:21.200563-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (19, 10, 'CREDITO', 1336.00, NULL, NULL, '', '2025-09-26 18:49:04.176735-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (20, 10, 'DEBITO', 5729.80, NULL, NULL, '', '2025-09-26 18:49:04.176735-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (21, 11, 'CREDITO', 1048.00, NULL, NULL, '', '2025-09-26 19:11:52.023796-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (22, 11, 'DEBITO', 1400.00, NULL, NULL, '', '2025-09-26 19:11:52.023796-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (23, 12, 'CREDITO', 2247.00, NULL, NULL, '', '2025-09-27 17:01:16.834449-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (24, 12, 'DEBITO', 5161.00, NULL, NULL, '', '2025-09-27 17:01:16.834449-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (25, 13, 'CREDITO', 1748.00, NULL, NULL, '', '2025-09-27 17:20:14.495049-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (26, 13, 'DEBITO', 3775.20, NULL, NULL, '', '2025-09-27 17:20:14.495049-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (27, 14, 'CREDITO', 1987.00, NULL, NULL, '', '2025-09-29 18:42:35.006548-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (28, 14, 'DEBITO', 6032.00, NULL, NULL, '', '2025-09-29 18:42:35.006548-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (29, 16, 'CREDITO', 2644.00, NULL, NULL, '', '2025-09-30 18:34:12.321052-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (30, 16, 'DEBITO', 6588.00, NULL, NULL, '', '2025-09-30 18:34:12.321052-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (31, 17, 'CREDITO', 763.00, NULL, NULL, '', '2025-09-30 18:44:42.935005-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (32, 17, 'DEBITO', 3451.00, NULL, NULL, '', '2025-09-30 18:44:42.935005-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (33, 18, 'CREDITO', 2622.00, NULL, NULL, '', '2025-10-01 18:53:11.127489-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (34, 18, 'DEBITO', 6560.00, NULL, NULL, '', '2025-10-01 18:53:11.127489-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (35, 21, 'CREDITO', 3474.00, NULL, NULL, '', '2025-10-02 19:17:02.202864-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (36, 20, 'CREDITO', 2792.00, NULL, NULL, '', '2025-10-02 19:34:03.277333-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (37, 20, 'DEBITO', 8616.00, NULL, NULL, '', '2025-10-02 19:34:03.277333-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (38, 23, 'CREDITO', 2307.00, NULL, NULL, '', '2025-10-03 18:54:08.653655-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (39, 23, 'DEBITO', 6786.00, NULL, NULL, '', '2025-10-03 18:54:08.653655-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (40, 22, 'CREDITO', 1892.00, NULL, NULL, '', '2025-10-03 18:54:26.741336-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (41, 22, 'DEBITO', 1544.00, NULL, NULL, '', '2025-10-03 18:54:26.741336-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (42, 24, 'CREDITO', 2879.00, NULL, NULL, '', '2025-10-06 19:11:37.018112-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (43, 24, 'DEBITO', 7849.80, NULL, NULL, '', '2025-10-06 19:11:37.018112-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (44, 25, 'CREDITO', 457.00, NULL, NULL, '', '2025-10-06 19:23:10.218978-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (45, 25, 'DEBITO', 2219.20, NULL, NULL, '', '2025-10-06 19:23:10.218978-05');


--
-- TOC entry 6551 (class 0 OID 0)
-- Dependencies: 346
-- Name: precorte_otros_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_otros_id_seq', 45, true);


--
-- TOC entry 5824 (class 0 OID 153211)
-- Dependencies: 347
-- Data for Name: prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6552 (class 0 OID 0)
-- Dependencies: 348
-- Name: prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_cab_id_seq', 1, false);


--
-- TOC entry 5826 (class 0 OID 153218)
-- Dependencies: 349
-- Data for Name: prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6553 (class 0 OID 0)
-- Dependencies: 350
-- Name: prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_det_id_seq', 1, false);


--
-- TOC entry 5828 (class 0 OID 153224)
-- Dependencies: 351
-- Data for Name: production_order_inputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6554 (class 0 OID 0)
-- Dependencies: 352
-- Name: production_order_inputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_inputs_id_seq', 1, false);


--
-- TOC entry 5830 (class 0 OID 153232)
-- Dependencies: 353
-- Data for Name: production_order_outputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6555 (class 0 OID 0)
-- Dependencies: 354
-- Name: production_order_outputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_outputs_id_seq', 1, false);


--
-- TOC entry 5832 (class 0 OID 153240)
-- Dependencies: 355
-- Data for Name: production_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6556 (class 0 OID 0)
-- Dependencies: 356
-- Name: production_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_orders_id_seq', 1, false);


--
-- TOC entry 5834 (class 0 OID 153252)
-- Dependencies: 357
-- Data for Name: proveedor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5835 (class 0 OID 153259)
-- Dependencies: 358
-- Data for Name: purchase_documents; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6557 (class 0 OID 0)
-- Dependencies: 359
-- Name: purchase_documents_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_documents_id_seq', 1, false);


--
-- TOC entry 5837 (class 0 OID 153267)
-- Dependencies: 360
-- Data for Name: purchase_order_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6558 (class 0 OID 0)
-- Dependencies: 361
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_order_lines_id_seq', 1, false);


--
-- TOC entry 5839 (class 0 OID 153277)
-- Dependencies: 362
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6559 (class 0 OID 0)
-- Dependencies: 363
-- Name: purchase_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_orders_id_seq', 1, false);


--
-- TOC entry 5841 (class 0 OID 153290)
-- Dependencies: 364
-- Data for Name: purchase_request_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6560 (class 0 OID 0)
-- Dependencies: 365
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_request_lines_id_seq', 1, false);


--
-- TOC entry 5843 (class 0 OID 153299)
-- Dependencies: 366
-- Data for Name: purchase_requests; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6561 (class 0 OID 0)
-- Dependencies: 367
-- Name: purchase_requests_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_requests_id_seq', 1, false);


--
-- TOC entry 5845 (class 0 OID 153311)
-- Dependencies: 368
-- Data for Name: purchase_suggestion_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6562 (class 0 OID 0)
-- Dependencies: 369
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestion_lines_id_seq', 1, false);


--
-- TOC entry 5847 (class 0 OID 153323)
-- Dependencies: 370
-- Data for Name: purchase_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6563 (class 0 OID 0)
-- Dependencies: 371
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestions_id_seq', 1, false);


--
-- TOC entry 5849 (class 0 OID 153339)
-- Dependencies: 372
-- Data for Name: purchase_vendor_quote_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6564 (class 0 OID 0)
-- Dependencies: 373
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quote_lines_id_seq', 1, false);


--
-- TOC entry 5851 (class 0 OID 153348)
-- Dependencies: 374
-- Data for Name: purchase_vendor_quotes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6565 (class 0 OID 0)
-- Dependencies: 375
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quotes_id_seq', 1, false);


--
-- TOC entry 5853 (class 0 OID 153362)
-- Dependencies: 376
-- Data for Name: recalc_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6566 (class 0 OID 0)
-- Dependencies: 377
-- Name: recalc_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recalc_log_id_seq', 1, false);


--
-- TOC entry 5855 (class 0 OID 153370)
-- Dependencies: 378
-- Data for Name: recepcion_adjuntos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6567 (class 0 OID 0)
-- Dependencies: 379
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_adjuntos_id_seq', 1, false);


--
-- TOC entry 5857 (class 0 OID 153378)
-- Dependencies: 380
-- Data for Name: recepcion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6568 (class 0 OID 0)
-- Dependencies: 381
-- Name: recepcion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_cab_id_seq', 1, false);


--
-- TOC entry 5859 (class 0 OID 153389)
-- Dependencies: 382
-- Data for Name: recepcion_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6569 (class 0 OID 0)
-- Dependencies: 383
-- Name: recepcion_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_det_id_seq', 1, false);


--
-- TOC entry 5861 (class 0 OID 153399)
-- Dependencies: 384
-- Data for Name: receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5784 (class 0 OID 152957)
-- Dependencies: 307
-- Data for Name: receta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5785 (class 0 OID 152971)
-- Dependencies: 308
-- Data for Name: receta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6570 (class 0 OID 0)
-- Dependencies: 385
-- Name: receta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_det_id_seq', 1, false);


--
-- TOC entry 6571 (class 0 OID 0)
-- Dependencies: 386
-- Name: receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_id_seq', 1, false);


--
-- TOC entry 5864 (class 0 OID 153411)
-- Dependencies: 387
-- Data for Name: receta_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6572 (class 0 OID 0)
-- Dependencies: 388
-- Name: receta_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_insumo_id_seq', 1, false);


--
-- TOC entry 5866 (class 0 OID 153416)
-- Dependencies: 389
-- Data for Name: receta_shadow; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6573 (class 0 OID 0)
-- Dependencies: 390
-- Name: receta_shadow_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_shadow_id_seq', 1, false);


--
-- TOC entry 5786 (class 0 OID 152982)
-- Dependencies: 309
-- Data for Name: receta_version; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6574 (class 0 OID 0)
-- Dependencies: 391
-- Name: receta_version_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_version_id_seq', 1, false);


--
-- TOC entry 5869 (class 0 OID 153433)
-- Dependencies: 392
-- Data for Name: recipe_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6575 (class 0 OID 0)
-- Dependencies: 393
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_history_id_seq', 1, false);


--
-- TOC entry 5871 (class 0 OID 153443)
-- Dependencies: 394
-- Data for Name: recipe_cost_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6576 (class 0 OID 0)
-- Dependencies: 395
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_snapshots_id_seq', 1, false);


--
-- TOC entry 5873 (class 0 OID 153456)
-- Dependencies: 396
-- Data for Name: recipe_extended_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6577 (class 0 OID 0)
-- Dependencies: 397
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_extended_cost_history_id_seq', 1, false);


--
-- TOC entry 5875 (class 0 OID 153471)
-- Dependencies: 398
-- Data for Name: recipe_labor_steps; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6578 (class 0 OID 0)
-- Dependencies: 399
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_labor_steps_id_seq', 1, false);


--
-- TOC entry 5877 (class 0 OID 153481)
-- Dependencies: 400
-- Data for Name: recipe_overhead_allocations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6579 (class 0 OID 0)
-- Dependencies: 401
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_overhead_allocations_id_seq', 1, false);


--
-- TOC entry 5879 (class 0 OID 153489)
-- Dependencies: 402
-- Data for Name: recipe_version_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6580 (class 0 OID 0)
-- Dependencies: 403
-- Name: recipe_version_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_version_items_id_seq', 1, false);


--
-- TOC entry 5881 (class 0 OID 153494)
-- Dependencies: 404
-- Data for Name: recipe_versions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6581 (class 0 OID 0)
-- Dependencies: 405
-- Name: recipe_versions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_versions_id_seq', 1, false);


--
-- TOC entry 5883 (class 0 OID 153504)
-- Dependencies: 406
-- Data for Name: replenishment_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6582 (class 0 OID 0)
-- Dependencies: 407
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('replenishment_suggestions_id_seq', 1, false);


--
-- TOC entry 5932 (class 0 OID 156906)
-- Dependencies: 481
-- Data for Name: report_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6583 (class 0 OID 0)
-- Dependencies: 480
-- Name: report_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_definitions_id_seq', 1, false);


--
-- TOC entry 5885 (class 0 OID 153525)
-- Dependencies: 408
-- Data for Name: report_favorites; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO report_favorites (id, user_id, report_key, meta, created_at, updated_at) VALUES (9, 3, 'merma_promedio', '{"range": "custom", "title": "Merma Promedio"}', '2025-11-04 20:43:07-06', '2025-11-04 20:43:07-06');


--
-- TOC entry 6584 (class 0 OID 0)
-- Dependencies: 409
-- Name: report_favorites_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_favorites_id_seq', 9, true);


--
-- TOC entry 5934 (class 0 OID 156920)
-- Dependencies: 483
-- Data for Name: report_runs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6585 (class 0 OID 0)
-- Dependencies: 482
-- Name: report_runs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_runs_id_seq', 1, false);


--
-- TOC entry 5887 (class 0 OID 153542)
-- Dependencies: 410
-- Data for Name: rol; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6586 (class 0 OID 0)
-- Dependencies: 411
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('rol_id_seq', 1, false);


--
-- TOC entry 5889 (class 0 OID 153550)
-- Dependencies: 412
-- Data for Name: role_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (2, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (3, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (4, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (5, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (6, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (7, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (8, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (9, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (11, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (12, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (13, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (14, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (15, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (16, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (17, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (18, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (19, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (20, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (21, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (22, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (23, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (24, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (25, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (26, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (27, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (28, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (29, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (30, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (31, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (32, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (33, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (34, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (36, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (37, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (38, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (39, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (40, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (41, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (42, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (43, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (44, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (45, 1);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (2, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (3, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (4, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (8, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (9, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (15, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (16, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (17, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (18, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (19, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (20, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (21, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (22, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (23, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (24, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (25, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (26, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (27, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (28, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (30, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (31, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (32, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (33, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (34, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (36, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (37, 2);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (2, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (3, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (4, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (8, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (9, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (15, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (17, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (18, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (19, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (24, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (26, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (27, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (30, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 3);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (4, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (3, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (20, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (21, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (30, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (31, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 4);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (15, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (16, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (17, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (18, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (19, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (26, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 5);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 6);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 6);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (24, 6);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (33, 6);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 6);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (1, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (10, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (15, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (24, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (26, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (30, 7);
INSERT INTO role_has_permissions (permission_id, role_id) VALUES (35, 7);


--
-- TOC entry 5890 (class 0 OID 153553)
-- Dependencies: 413
-- Data for Name: roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (1, 'Super Admin', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (2, 'Ops Manager', 'web', '2025-11-02 12:31:13', '2025-11-02 12:31:13', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (3, 'inventario.manager', 'web', '2025-11-02 12:31:14', '2025-11-02 12:31:14', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (4, 'purchasing', 'web', '2025-11-02 12:31:14', '2025-11-02 12:31:14', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (5, 'kitchen', 'web', '2025-11-02 12:31:14', '2025-11-02 12:31:14', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (6, 'cashier', 'web', '2025-11-02 12:31:14', '2025-11-02 12:31:14', NULL, NULL, NULL);
INSERT INTO roles (id, name, guard_name, created_at, updated_at, display_name, description, color) VALUES (7, 'viewer', 'web', '2025-11-02 12:31:14', '2025-11-02 12:31:14', NULL, NULL, NULL);


--
-- TOC entry 6587 (class 0 OID 0)
-- Dependencies: 414
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('roles_id_seq', 7, true);


--
-- TOC entry 6588 (class 0 OID 0)
-- Dependencies: 415
-- Name: seq_cat_codigo; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('seq_cat_codigo', 10, true);


--
-- TOC entry 5782 (class 0 OID 152916)
-- Dependencies: 305
-- Data for Name: sesion_cajon; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (1, 'PRINCIPAL', 101, '101', 6, '2025-09-17 09:06:04.081128-05', '2025-09-17 19:40:36.846-05', 'LISTO_PARA_CORTE', 2500.00, 11978.40, 128, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (2, 'PRINCIPAL', 102, '102', 13, '2025-09-17 09:22:58.686625-05', '2025-09-17 19:58:35.293-05', 'LISTO_PARA_CORTE', 2500.00, 6855.60, 129, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (3, 'PRINCIPAL', 101, '101', 6, '2025-09-18 08:55:08.545545-05', '2025-09-18 20:04:31.893-05', 'LISTO_PARA_CORTE', 2500.00, 12431.80, 132, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (4, 'PRINCIPAL', 102, '102', 13, '2025-09-18 09:38:34.748483-05', '2025-09-18 20:25:14.389-05', 'LISTO_PARA_CORTE', 2500.00, 6562.20, 133, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (24, 'PRINCIPAL', 101, '101', 6, '2025-09-29 09:01:23.827279-05', '2025-09-29 19:43:17.06-05', 'CERRADA', 2500.00, 11353.00, 174, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (6, 'PRINCIPAL', 101, '101', 6, '2025-09-19 09:05:06.546538-05', '2025-09-19 18:32:08.086-05', 'LISTO_PARA_CORTE', 2500.00, 7646.80, 136, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (25, 'PRINCIPAL', 102, '102', 13, '2025-09-29 09:13:42.556641-05', '2025-09-29 20:06:29.323-05', 'LISTO_PARA_CORTE', 2500.00, 7317.00, 175, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (26, 'ENTRADA', 401, 'Terminal 401', 8, '2025-09-29 14:50:03.517437-05', '2025-09-30 08:34:02.682-05', 'LISTO_PARA_CORTE', 0.00, 85.00, 176, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (5, 'PRINCIPAL', 102, '102', 8, '2025-09-19 08:34:21.424031-05', '2025-09-19 19:23:02.095-05', 'CERRADA', 2500.00, 4890.80, 137, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (8, 'PRINCIPAL', 102, '102', 8, '2025-09-20 09:06:12.507865-05', '2025-09-20 18:09:08.011-05', 'CERRADA', 2500.00, 7670.80, 140, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (7, 'PRINCIPAL', 101, '101', 6, '2025-09-20 09:02:00.219905-05', '2025-09-20 18:28:32.719-05', 'CERRADA', 2500.00, 10567.80, 141, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (10, 'PRINCIPAL', 102, '102', 13, '2025-09-22 08:42:24.379279-05', '2025-09-22 09:44:43.447-05', 'LISTO_PARA_CORTE', 2500.00, 2500.00, 144, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (9, 'PRINCIPAL', 101, '101', 6, '2025-09-22 08:23:40.164587-05', '2025-09-22 09:45:33.192-05', 'LISTO_PARA_CORTE', 2500.00, 2500.00, 145, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (38, 'PRINCIPAL', 101, '101', 6, '2025-10-03 08:54:37.094581-05', '2025-10-03 19:54:35.126-05', 'CERRADA', 2500.00, 8444.00, 200, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (27, 'ENTRADA', 401, 'Terminal 401', 8, '2025-09-30 07:34:22.295356-05', '2025-09-30 12:29:54.720725-05', 'LISTO_PARA_CORTE', 1000.00, 1121.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (12, 'PRINCIPAL', 101, '101', 6, '2025-09-22 08:55:26.463681-05', '2025-09-22 20:17:27.465-05', 'LISTO_PARA_CORTE', 2500.00, 12812.40, 149, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (11, 'PRINCIPAL', 102, '102', 13, '2025-09-22 08:54:43.01876-05', '2025-09-22 20:32:00.981-05', 'LISTO_PARA_CORTE', 2500.00, 6630.00, 150, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (29, 'ENTRADA', 401, 'Terminal 401', 8, '2025-09-30 10:31:01.736-05', '2025-09-30 12:29:54.720725-05', 'LISTO_PARA_CORTE', 1001.00, 1121.00, 179, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (28, 'PRINCIPAL', 101, '101', 6, '2025-09-30 09:02:39.594419-05', '2025-09-30 19:34:37.968-05', 'CERRADA', 2500.00, 11307.80, 181, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (14, 'PRINCIPAL', 102, '102', 8, '2025-09-23 09:05:50.31703-05', '2025-09-23 20:20:21.37-05', 'CERRADA', 2500.00, 6634.00, 154, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (15, 'PRINCIPAL', 101, '101', 6, '2025-09-23 09:12:22.383953-05', '2025-09-23 20:06:39.067-05', 'CERRADA', 2500.00, 10491.00, 153, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (16, 'PRINCIPAL', 101, '101', 6, '2025-09-24 08:55:07.848467-05', '2025-09-24 19:18:57.576-05', 'LISTO_PARA_CORTE', 2500.00, 10189.00, 157, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (17, 'PRINCIPAL', 102, '102', 8, '2025-09-24 09:36:30.21109-05', '2025-09-24 19:53:59.454-05', 'LISTO_PARA_CORTE', 2500.00, 6477.40, 158, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (30, 'PRINCIPAL', 102, '102', 8, '2025-09-30 09:31:02.987154-05', '2025-09-30 13:29:54.681-05', 'LISTO_PARA_CORTE', 2500.00, 4078.00, 180, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (18, 'PRINCIPAL', 101, '101', 6, '2025-09-25 09:02:42.676315-05', '2025-09-25 19:17:49.372-05', 'CERRADA', 2500.00, 11131.00, 161, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (19, 'PRINCIPAL', 102, '102', 13, '2025-09-25 09:34:14.59031-05', '2025-09-25 20:06:31.864-05', 'CERRADA', 2500.00, 6766.60, 162, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (40, 'PRINCIPAL', 101, '101', 6, '2025-10-04 08:37:48.614896-05', '2025-10-04 17:00:10.487-05', 'LISTO_PARA_CORTE', 2500.00, 16045.00, 204, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (41, 'PRINCIPAL', 102, '102', 8, '2025-10-04 08:39:50.938951-05', '2025-10-04 17:07:54.937-05', 'LISTO_PARA_CORTE', 2500.00, 11230.20, 205, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (32, 'PRINCIPAL', 101, '101', 6, '2025-10-01 07:55:42.45592-05', '2025-10-01 19:53:33.939-05', 'CERRADA', 2500.00, 9239.00, 187, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (31, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-01 07:32:59.763091-05', '2025-10-02 08:50:54.355-05', 'LISTO_PARA_CORTE', 1000.00, 1000.00, 188, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (21, 'PRINCIPAL', 102, '102', 13, '2025-09-26 08:51:34.273578-05', '2025-09-26 20:12:01.605-05', 'CERRADA', 2500.00, 5845.00, 166, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (20, 'PRINCIPAL', 101, '101', 6, '2025-09-26 08:46:01.310139-05', '2025-09-26 19:49:26.925-05', 'CERRADA', 2500.00, 9153.80, 165, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (22, 'PRINCIPAL', 101, '101', 6, '2025-09-27 08:34:05.109531-05', '2025-09-27 18:01:50.172-05', 'CERRADA', 2500.00, 14607.00, 169, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (33, 'PRINCIPAL', 102, '102', 13, '2025-10-01 09:16:10.61867-05', '2025-10-02 09:45:35.013-05', 'LISTO_PARA_CORTE', 2500.00, 5084.00, 191, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (23, 'PRINCIPAL', 102, '102', 8, '2025-09-27 09:06:24.105709-05', '2025-09-27 18:20:26.501-05', 'CERRADA', 2500.00, 10576.00, 170, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (34, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-02 07:53:37.537881-05', '2025-10-02 13:23:35.95-05', 'LISTO_PARA_CORTE', 1000.00, 1150.00, 193, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (50, 'PRINCIPAL', 101, '101', 6, '2025-10-08 08:34:06.872535-05', '2025-10-08 19:53:09.901-05', 'LISTO_PARA_CORTE', 2500.00, 3714.20, 220, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (42, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-06 07:58:10.890961-05', '2025-10-06 12:17:26.862837-05', 'LISTO_PARA_CORTE', 1000.00, 1070.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (36, 'PRINCIPAL', 102, '102', 13, '2025-10-02 08:45:54.688896-05', '2025-10-02 20:35:23.257-05', 'LISTO_PARA_CORTE', 2500.00, 5981.00, 195, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (35, 'PRINCIPAL', 101, '101', 6, '2025-10-02 08:40:27.395912-05', '2025-10-02 20:34:28.113-05', 'CERRADA', 2500.00, 12735.80, 194, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (37, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-03 07:22:54.235856-05', '2025-10-03 13:21:38.593-05', 'LISTO_PARA_CORTE', 1000.00, 1300.00, 199, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (44, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-06 09:26:44.277-05', '2025-10-06 12:17:26.862837-05', 'LISTO_PARA_CORTE', 1070.00, 1070.00, 208, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (51, 'PRINCIPAL', 102, '102', 13, '2025-10-08 09:58:23.297741-05', '2025-10-08 19:56:04.039-05', 'LISTO_PARA_CORTE', 2500.00, 2650.00, 221, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (39, 'PRINCIPAL', 102, '102', 13, '2025-10-03 09:30:35.753797-05', '2025-10-03 19:54:52.529-05', 'CERRADA', 2500.00, 4735.00, 201, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (43, 'PRINCIPAL', 101, '101', 6, '2025-10-06 08:19:03.292037-05', '2025-10-06 20:11:58.854-05', 'CERRADA', 2500.00, 11255.00, 210, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (45, 'PRINCIPAL', 102, '102', 8, '2025-10-06 08:26:45.279096-05', '2025-10-06 13:17:26.712-05', 'LISTO_PARA_CORTE', 2500.00, 4443.40, 209, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (48, 'PRINCIPAL', 102, '102', 8, '2025-10-07 08:50:03.753591-05', '2025-10-07 13:23:48.722-05', 'LISTO_PARA_CORTE', 2500.00, 4397.00, 215, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (46, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-07 07:29:05.297092-05', '2025-10-07 12:23:48.96552-05', 'LISTO_PARA_CORTE', 1000.00, 1270.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (47, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-07 09:50:02.803-05', '2025-10-07 12:23:48.96552-05', 'LISTO_PARA_CORTE', 1055.00, 1270.00, 213, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (49, 'PRINCIPAL', 101, '101', 6, '2025-10-07 08:50:28.797539-05', '2025-10-07 19:35:06.164-05', 'LISTO_PARA_CORTE', 2500.00, 10537.60, 216, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (53, 'PRINCIPAL', 102, '102', 8, '2025-10-09 09:28:21.068893-05', '2025-10-09 13:26:12.523-05', 'LISTO_PARA_CORTE', 2500.00, 3642.00, 225, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (54, 'PRINCIPAL', 102, '102', 8, '2025-10-09 12:17:14.532-05', '2025-10-09 13:26:12.523-05', 'LISTO_PARA_CORTE', 3642.00, 3642.00, 224, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (55, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-09 11:17:14.748923-05', '2025-10-09 12:26:12.654384-05', 'LISTO_PARA_CORTE', 1000.00, 1004.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (52, 'PRINCIPAL', 101, '101', 6, '2025-10-09 08:35:27.204894-05', '2025-10-09 19:40:51.165-05', 'LISTO_PARA_CORTE', 2500.00, 12017.00, 226, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (59, 'PRINCIPAL', 102, '102', 8, '2025-10-10 09:32:40.331227-05', '2025-10-10 11:53:05.497-05', 'LISTO_PARA_CORTE', 2500.00, 3785.00, 231, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (56, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-10 07:26:30.557316-05', '2025-10-10 10:53:05.651058-05', 'LISTO_PARA_CORTE', 1000.00, 1168.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (58, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-10 10:32:39.661-05', '2025-10-10 10:53:05.651058-05', 'LISTO_PARA_CORTE', 1168.00, 1168.00, 230, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (57, 'PRINCIPAL', 101, '101', 6, '2025-10-10 08:42:15.822091-05', '2025-10-10 18:46:02.907-05', 'LISTO_PARA_CORTE', 2500.00, 8551.20, 232, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (60, 'PRINCIPAL', 102, '102', 8, '2025-10-11 08:27:10.31438-05', '2025-10-11 17:20:46.121-05', 'LISTO_PARA_CORTE', 2500.00, 16128.00, 236, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (61, 'PRINCIPAL', 101, '101', 6, '2025-10-11 08:28:37.111777-05', '2025-10-11 17:31:39.055-05', 'LISTO_PARA_CORTE', 2500.00, 14646.00, 237, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (65, 'PRINCIPAL', 102, '102', 8, '2025-10-13 09:06:33.330098-05', '2025-10-13 13:20:17.589-05', 'LISTO_PARA_CORTE', 2500.00, 5847.00, 241, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (62, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-13 07:19:16.258862-05', '2025-10-13 12:20:17.739527-05', 'LISTO_PARA_CORTE', 1000.00, 1187.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (64, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-13 10:06:33.203-05', '2025-10-13 12:20:17.739527-05', 'LISTO_PARA_CORTE', 1083.00, 1187.00, 240, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (63, 'PRINCIPAL', 101, '101', 6, '2025-10-13 08:55:19.518505-05', '2025-10-13 19:45:36.27-05', 'LISTO_PARA_CORTE', 2500.00, 8064.20, 243, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (69, 'PRINCIPAL', 101, '101', 6, '2025-10-14 08:59:01.739723-05', '2025-10-14 19:47:54.514-05', 'LISTO_PARA_CORTE', 2500.00, 7946.80, 248, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (67, 'PRINCIPAL', 102, '102', 6, '2025-10-14 08:27:05.84751-05', '2025-10-14 19:54:21.56-05', 'LISTO_PARA_CORTE', 2500.00, 8240.00, 249, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (66, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-14 07:14:29.514346-05', '2025-10-14 13:29:58.618-05', 'LISTO_PARA_CORTE', 1000.00, 1220.60, 247, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (68, 'PRINCIPAL', 102, '102', 6, '2025-10-14 09:59:01.679-05', '2025-10-14 19:54:21.56-05', 'LISTO_PARA_CORTE', 2500.00, 8240.00, 246, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (72, 'PRINCIPAL', 101, '101', 8, '2025-10-15 08:16:53.811492-05', '2025-10-15 13:19:45.211-05', 'LISTO_PARA_CORTE', 2500.00, 5400.40, 253, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (70, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-15 07:36:32.674744-05', '2025-10-15 12:19:45.385882-05', 'LISTO_PARA_CORTE', 1000.00, 1271.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (71, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-15 09:16:52.894-05', '2025-10-15 12:19:45.385882-05', 'LISTO_PARA_CORTE', 1020.00, 1271.00, 251, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (73, 'PRINCIPAL', 102, '102', 6, '2025-10-15 08:17:38.405685-05', '2025-10-15 19:22:18.748-05', 'LISTO_PARA_CORTE', 2500.00, 7751.00, 254, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (74, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-16 07:06:23.103373-05', '2025-10-16 08:06:27.364-05', 'LISTO_PARA_CORTE', 500.00, 500.00, 257, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (78, 'PRINCIPAL', 101, '101', 6, '2025-10-16 09:03:55.646781-05', '2025-10-16 19:42:31.452-05', 'LISTO_PARA_CORTE', 2500.00, 7140.80, 261, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (77, 'PRINCIPAL', 102, '102', 8, '2025-10-16 09:02:43.794352-05', '2025-10-16 20:02:46.819-05', 'LISTO_PARA_CORTE', 2500.00, 8295.00, 262, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (81, 'PRINCIPAL', 101, '101', 6, '2025-10-17 09:09:49.931669-05', '2025-10-17 18:55:33.029-05', 'LISTO_PARA_CORTE', 2500.00, 4823.20, 265, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (79, 'PRINCIPAL', 102, '102', 6, '2025-10-17 08:47:06.451915-05', '2025-10-17 17:55:32.974294-05', 'LISTO_PARA_CORTE', 2500.00, 8582.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (80, 'PRINCIPAL', 102, '102', 6, '2025-10-17 10:09:49.867-05', '2025-10-17 17:55:32.974294-05', 'LISTO_PARA_CORTE', 2564.00, 8582.00, 264, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (84, 'PRINCIPAL', 102, '102', 6, '2025-10-18 07:57:40.121727-05', '2025-10-18 17:09:18.045-05', 'LISTO_PARA_CORTE', 2500.00, 10786.00, 269, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (83, 'PRINCIPAL', 101, '101', 8, '2025-10-18 07:55:35.815537-05', '2025-10-18 17:09:26.857-05', 'LISTO_PARA_CORTE', 2500.00, 10858.40, 270, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (87, 'PRINCIPAL', 101, '101', 6, '2025-10-20 09:05:20.47362-05', '2025-10-20 19:32:10.853-05', 'LISTO_PARA_CORTE', 2500.00, 7058.00, 273, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (85, 'PRINCIPAL', 102, '102', 6, '2025-10-20 08:50:42.262013-05', '2025-10-20 19:54:04.541-05', 'LISTO_PARA_CORTE', 2500.00, 7739.00, 274, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (86, 'PRINCIPAL', 102, '102', 6, '2025-10-20 10:05:20.415-05', '2025-10-20 19:54:04.541-05', 'LISTO_PARA_CORTE', 2500.00, 7739.00, 272, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (88, 'PRINCIPAL', 101, '101', 6, '2025-10-21 09:03:33.225142-05', '2025-10-21 18:18:47.237-05', 'LISTO_PARA_CORTE', 2500.00, 5927.60, 277, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (90, 'PRINCIPAL', 102, '102', 8, '2025-10-21 09:08:11.225768-05', '2025-10-21 19:46:50.73-05', 'LISTO_PARA_CORTE', 2500.00, 8040.00, 278, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (92, 'PRINCIPAL', 101, '101', 8, '2025-10-22 08:03:35.377218-05', '2025-10-22 18:00:43.27-05', 'LISTO_PARA_CORTE', 2500.00, 6199.00, 281, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (93, 'PRINCIPAL', 102, '102', 6, '2025-10-22 08:07:18.357403-05', '2025-10-22 19:40:02.655-05', 'LISTO_PARA_CORTE', 2500.00, 7817.00, 282, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (96, 'PRINCIPAL', 101, '101', 6, '2025-10-23 09:11:08.580936-05', '2025-10-23 19:08:19.57-05', 'LISTO_PARA_CORTE', 2500.00, 6237.00, 285, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (94, 'PRINCIPAL', 102, '102', 6, '2025-10-23 08:46:49.545493-05', '2025-10-23 20:14:01.32-05', 'LISTO_PARA_CORTE', 2500.00, 7874.00, 286, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (95, 'PRINCIPAL', 102, '102', 6, '2025-10-23 09:11:07.696-05', '2025-10-23 20:14:01.32-05', 'LISTO_PARA_CORTE', 2500.00, 7874.00, 284, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (97, 'PRINCIPAL', 101, '101', 6, '2025-10-24 08:46:29.34105-05', '2025-10-24 17:12:42.358-05', 'LISTO_PARA_CORTE', 2500.00, 5911.00, 289, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (99, 'PRINCIPAL', 102, '102', 8, '2025-10-24 09:09:42.411768-05', '2025-10-24 18:31:34.441-05', 'LISTO_PARA_CORTE', 2500.00, 7602.00, 290, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (101, 'PRINCIPAL', 101, '101', 8, '2025-10-25 08:18:03.623768-05', '2025-10-25 17:15:22.281-05', 'LISTO_PARA_CORTE', 2500.00, 6254.00, 293, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (102, 'PRINCIPAL', 102, '102', 6, '2025-10-25 08:19:51.524247-05', '2025-10-25 18:20:46.98-05', 'LISTO_PARA_CORTE', 2500.00, 10285.00, 294, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (103, 'PRINCIPAL', 101, '101', 6, '2025-10-27 08:05:39.785984-06', '2025-10-27 17:54:32.954-06', 'LISTO_PARA_CORTE', 2500.00, 7665.00, 297, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (104, 'PRINCIPAL', 101, '101', 6, '2025-10-27 08:26:04.685-06', '2025-10-27 17:54:32.954-06', 'LISTO_PARA_CORTE', 2565.00, 7665.00, 296, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (105, 'PRINCIPAL', 102, '102', 6, '2025-10-27 08:26:04.680608-06', '2025-10-27 17:55:49.552-06', 'LISTO_PARA_CORTE', 2500.00, 7814.00, 298, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (107, 'PRINCIPAL', 102, '102', 8, '2025-10-28 07:53:05.598979-06', '2025-10-28 17:15:52.249-06', 'LISTO_PARA_CORTE', 2500.00, 6889.00, 301, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (108, 'PRINCIPAL', 101, '101', 6, '2025-10-28 08:02:53.095579-06', '2025-10-28 17:42:08.403-06', 'LISTO_PARA_CORTE', 2500.00, 4811.00, 302, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (110, 'PRINCIPAL', 101, '101', 8, '2025-10-29 07:29:41.830574-06', '2025-10-29 17:56:48.243-06', 'LISTO_PARA_CORTE', 2500.00, 6105.00, 305, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (111, 'PRINCIPAL', 102, '102', 6, '2025-10-29 07:35:07.38462-06', '2025-10-29 17:59:59.173-06', 'LISTO_PARA_CORTE', 2500.00, 7442.00, 306, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (114, 'PRINCIPAL', 101, '101', 8, '2025-10-30 07:31:06.875328-06', '2025-10-30 16:54:59.993-06', 'LISTO_PARA_CORTE', 2500.00, 3413.00, 309, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (112, 'PRINCIPAL', 102, '102', 6, '2025-10-30 07:28:49.364087-06', '2025-10-30 17:40:10.786-06', 'LISTO_PARA_CORTE', 2500.00, 10769.00, 310, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (117, 'PRINCIPAL', 101, '101', 8, '2025-10-31 08:57:00.330315-06', '2025-10-31 15:19:29.884-06', 'LISTO_PARA_CORTE', 2500.00, 3407.00, 313, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (115, 'PRINCIPAL', 102, '102', 6, '2025-10-31 08:34:40.271255-06', '2025-10-31 15:31:19.368-06', 'LISTO_PARA_CORTE', 2500.00, 2996.00, 314, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (13, '', 9939, '9939', 1, '2025-09-22 15:58:44.147496-05', NULL, 'ACTIVA', 0.00, NULL, NULL, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (75, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-16 07:07:00.991373-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1000.00, 1233.00, 321, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (76, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-16 10:02:43.681-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1210.00, 1233.00, 259, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (82, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-18 08:55:35.428-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 267, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (89, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-21 10:08:10.002-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 276, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (91, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-22 08:03:35.378-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 279, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (98, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-24 10:09:40.99-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 288, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (100, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-25 08:18:02.074-05', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 291, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (106, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-28 07:53:05.069-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 299, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (109, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-29 07:29:41.836-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 303, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (113, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-30 07:31:05.995-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 308, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (116, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-31 08:57:00.221-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 312, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (118, 'PRINCIPAL', 102, '102', 6, '2025-11-03 08:01:00.23551-06', '2025-11-03 18:01:56.164-06', 'LISTO_PARA_CORTE', 2500.00, 12119.00, 320, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (119, 'ENTRADA', 401, 'Terminal 401', 8, '2025-11-03 08:09:31.024-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 316, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (120, 'PRINCIPAL', 101, '101', 8, '2025-11-03 08:09:31.61643-06', '2025-11-03 10:52:17.079-06', 'LISTO_PARA_CORTE', 2500.00, 2751.00, 317, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (121, 'ENTRADA', 401, 'Terminal 401', 8, '2025-11-03 11:01:13.351-06', '2025-11-04 06:56:00.835-06', 'LISTO_PARA_CORTE', 1223.00, 1233.00, 318, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (122, 'PRINCIPAL', 101, '101', 8, '2025-11-03 11:01:14.137814-06', '2025-11-03 17:44:08.151-06', 'LISTO_PARA_CORTE', 2500.00, 5349.00, 319, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (125, 'ENTRADA', 401, 'Terminal 401', 8, '2025-11-04 08:22:36.49-06', '2025-11-04 11:27:33.139638-06', 'LISTO_PARA_CORTE', 1053.00, 1153.00, 324, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (126, 'PRINCIPAL', 101, '101', 8, '2025-11-04 08:22:37.071416-06', '2025-11-04 11:27:33.078-06', 'LISTO_PARA_CORTE', 2500.00, 3577.00, 325, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (123, 'ENTRADA', 401, 'Terminal 401', 8, '2025-11-04 06:56:16.768307-06', '2025-11-04 11:27:33.139638-06', 'LISTO_PARA_CORTE', 1000.00, 1153.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (124, 'PRINCIPAL', 102, '102', 6, '2025-11-04 07:34:25.707977-06', '2025-11-04 17:41:20.479-06', 'LISTO_PARA_CORTE', 2500.00, 8895.00, 327, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (128, 'PRINCIPAL', 101, '101', 8, '2025-11-05 08:18:56.240872-06', '2025-11-05 17:30:49.352-06', 'LISTO_PARA_CORTE', 2500.00, 6051.00, 330, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (127, 'PRINCIPAL', 102, '102', 6, '2025-11-05 07:49:54.14574-06', '2025-11-05 18:01:10.727-06', 'LISTO_PARA_CORTE', 2500.00, 8831.00, 331, false);


--
-- TOC entry 6589 (class 0 OID 0)
-- Dependencies: 416
-- Name: sesion_cajon_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('sesion_cajon_id_seq', 128, true);


--
-- TOC entry 5894 (class 0 OID 153565)
-- Dependencies: 417
-- Data for Name: sessions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('ZAubE24VNe2wBMXigZYUA055EoJnL4ryfCArBkCz', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoib3RoalBmbkhGdmRaTDB6Z0gyQUhRQk9CWk15aE9paWdHRmxnZDBWRiI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo0MToiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9kYXNoYm9hcmQiO31zOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czo0MToiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1762404161);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('yv28n9lmL7xyiNGJX8tctKOWi7iz4TbVfEjaM2le', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiMFkyNnRNWEtJa0VsUmFzVEhQa1pwRzRhREpEZVI4UlNVN284dWw3SiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwiO3M6NToicm91dGUiO3M6NDoiaG9tZSI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1762404161);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('l7jdCZiMMYHtI6RfYvI7SAQsqizKfGJg3eOtrqmB', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiaXNLckRiODJ2U01FNkh4RWo3aGRLcFRjSjg2cTl1dnU3QzZJQWgyMCI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo0MToiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9kYXNoYm9hcmQiO31zOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czo0MToiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1762404161);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('RqBFYJZmICYzP2EjnsVo96nllVktRCW6gyX6K2Cw', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiamEzNnAza1pjNFd3Y3g0UHBOeXlrcWNkVVI1THl4eW44ZVl6WlhvRCI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjk1OiJodHRwOi8vbG9jYWxob3N0L1RlcnJlbmFMYXJhdmVsL3JlcG9ydHMvc2FsZXMvc3VtbWFyeT9lbmRfZGF0ZT0yMDI1LTEwLTI2JnN0YXJ0X2RhdGU9MjAyNS0wOS0wMSI7czo1OiJyb3V0ZSI7czoyMToicmVwb3J0cy5zYWxlcy5zdW1tYXJ5Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6Mzt9', 1762345046);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('f2hDYRLOl9rY65P9gObQkMA4MxT0WJg4Jb121i6f', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiZDhaSzlMRzYyWWpaVlRLM3NJZjZTY21qVnBBVEZPY25PbHNTc01pdiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6ODQ6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvcmVwb3J0cy9zYWxlcy9kZXRhaWw/ZW5kPTIwMjUtMTEtMDUmc3RhcnQ9MjAyNS0xMC0wMSI7czo1OiJyb3V0ZSI7czoyMDoicmVwb3J0cy5zYWxlcy5kZXRhaWwiO31zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTozO30=', 1762406611);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('KiHaB4zLs1XDI1qeFh3jmBBKsG5BFe5EEM0hjvmY', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiY1JneDlJZWtsM0c3VUEwS2pVVk9ZZ0I3aGVEbWNnWE1rdURsMXhyNSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo5MToiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9yZXBvcnRzL3NhbGVzL21peD9lbmRfZGF0ZT0yMDI1LTExLTA1JnN0YXJ0X2RhdGU9MjAyNS0xMC0wMSI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjkxOiJodHRwOi8vbG9jYWxob3N0L1RlcnJlbmFMYXJhdmVsL3JlcG9ydHMvc2FsZXMvbWl4P2VuZF9kYXRlPTIwMjUtMTEtMDUmc3RhcnRfZGF0ZT0yMDI1LTEwLTAxIjtzOjU6InJvdXRlIjtzOjE3OiJyZXBvcnRzLnNhbGVzLm1peCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1762404161);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('kzlc433fC4WA8pWYWUFnHzwFy5ku4wzsaZQHxPRi', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiN2xpVjZEVVRBRUlHMUwwRFVHdnhFRGNOaGFTb1pmZFNJUnVvdnBxUSI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjg0OiJodHRwOi8vbG9jYWxob3N0L1RlcnJlbmFMYXJhdmVsL3JlcG9ydHMvc2FsZXMvZGV0YWlsP2VuZD0yMDI1LTExLTA1JnN0YXJ0PTIwMjUtMTAtMDEiO3M6NToicm91dGUiO3M6MjA6InJlcG9ydHMuc2FsZXMuZGV0YWlsIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6Mzt9', 1762388457);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('IRz1noWw0BgYhjvMiACe6EYptI5Rp6mxqLPhi96e', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoid3J6T2xsMmZyRnNIMmRVNkJCckJYeVBESGttN1lMbVBXSmg2YUMwYyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzc6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTozO30=', 1762404170);


--
-- TOC entry 5895 (class 0 OID 153571)
-- Dependencies: 418
-- Data for Name: sol_prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6590 (class 0 OID 0)
-- Dependencies: 419
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_cab_id_seq', 1, false);


--
-- TOC entry 5897 (class 0 OID 153582)
-- Dependencies: 420
-- Data for Name: sol_prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6591 (class 0 OID 0)
-- Dependencies: 421
-- Name: sol_prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_det_id_seq', 1, false);


--
-- TOC entry 5899 (class 0 OID 153588)
-- Dependencies: 422
-- Data for Name: stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6592 (class 0 OID 0)
-- Dependencies: 423
-- Name: stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('stock_policy_id_seq', 1, false);


--
-- TOC entry 5901 (class 0 OID 153600)
-- Dependencies: 424
-- Data for Name: sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5902 (class 0 OID 153607)
-- Dependencies: 425
-- Data for Name: sucursal_almacen_terminal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6593 (class 0 OID 0)
-- Dependencies: 426
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sucursal_almacen_terminal_id_seq', 1, false);


--
-- TOC entry 5904 (class 0 OID 153617)
-- Dependencies: 427
-- Data for Name: ticket_det_consumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6594 (class 0 OID 0)
-- Dependencies: 428
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_det_consumo_id_seq', 1, false);


--
-- TOC entry 5906 (class 0 OID 153628)
-- Dependencies: 429
-- Data for Name: ticket_item_modifiers; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6595 (class 0 OID 0)
-- Dependencies: 430
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_modifiers_id_seq', 1, false);


--
-- TOC entry 5908 (class 0 OID 153635)
-- Dependencies: 431
-- Data for Name: ticket_venta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6596 (class 0 OID 0)
-- Dependencies: 432
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_cab_id_seq', 1, false);


--
-- TOC entry 5910 (class 0 OID 153645)
-- Dependencies: 433
-- Data for Name: ticket_venta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6597 (class 0 OID 0)
-- Dependencies: 434
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_det_id_seq', 1, false);


--
-- TOC entry 5912 (class 0 OID 153657)
-- Dependencies: 435
-- Data for Name: transfer_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6598 (class 0 OID 0)
-- Dependencies: 436
-- Name: transfer_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_cab_id_seq', 1, false);


--
-- TOC entry 5914 (class 0 OID 153664)
-- Dependencies: 437
-- Data for Name: transfer_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6599 (class 0 OID 0)
-- Dependencies: 438
-- Name: transfer_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_det_id_seq', 1, false);


--
-- TOC entry 5916 (class 0 OID 153670)
-- Dependencies: 439
-- Data for Name: traspaso_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6600 (class 0 OID 0)
-- Dependencies: 440
-- Name: traspaso_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_cab_id_seq', 1, false);


--
-- TOC entry 5918 (class 0 OID 153681)
-- Dependencies: 441
-- Data for Name: traspaso_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6601 (class 0 OID 0)
-- Dependencies: 442
-- Name: traspaso_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_det_id_seq', 1, false);


--
-- TOC entry 6602 (class 0 OID 0)
-- Dependencies: 445
-- Name: unidad_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidad_medida_id_seq', 1, false);


--
-- TOC entry 5920 (class 0 OID 153693)
-- Dependencies: 444
-- Data for Name: unidad_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6603 (class 0 OID 0)
-- Dependencies: 448
-- Name: unidades_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidades_medida_id_seq', 1, false);


--
-- TOC entry 5922 (class 0 OID 153710)
-- Dependencies: 447
-- Data for Name: unidades_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6604 (class 0 OID 0)
-- Dependencies: 451
-- Name: uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('uom_conversion_id_seq', 1, false);


--
-- TOC entry 5924 (class 0 OID 153727)
-- Dependencies: 450
-- Data for Name: uom_conversion_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5926 (class 0 OID 153734)
-- Dependencies: 452
-- Data for Name: user_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 5927 (class 0 OID 153739)
-- Dependencies: 453
-- Data for Name: users; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO users (id, username, password_hash, email, nombre_completo, sucursal_id, activo, fecha_ultimo_login, intentos_login, bloqueado_hasta, created_at, updated_at, remember_token) VALUES (3, 'soporte', '$2y$12$ooLJw7RQYdTPJmuISfour.jHXJVXbSsMJqkXHA//UbHRK3FSXsaF6', 'soporte@terrena.com', 'Usuario Soporte', 'SUR', true, NULL, 0, NULL, '2025-11-02 12:34:50.954274', '2025-11-02 20:03:09', NULL);


--
-- TOC entry 6605 (class 0 OID 0)
-- Dependencies: 454
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 3, true);


--
-- TOC entry 5929 (class 0 OID 153757)
-- Dependencies: 455
-- Data for Name: usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 6606 (class 0 OID 0)
-- Dependencies: 456
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('usuario_id_seq', 1, false);


SET search_path = public, pg_catalog;

--
-- TOC entry 5148 (class 2606 OID 157938)
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5172 (class 2606 OID 158130)
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5168 (class 2606 OID 158098)
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- TOC entry 5146 (class 2606 OID 157918)
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5144 (class 2606 OID 157910)
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 5140 (class 2606 OID 157874)
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 5142 (class 2606 OID 157876)
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- TOC entry 5170 (class 2606 OID 158109)
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- TOC entry 5138 (class 2606 OID 157864)
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- TOC entry 5136 (class 2606 OID 157856)
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- TOC entry 5126 (class 2606 OID 157784)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 5134 (class 2606 OID 157843)
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5198 (class 2606 OID 158381)
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- TOC entry 5124 (class 2606 OID 157773)
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- TOC entry 5132 (class 2606 OID 157830)
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- TOC entry 5122 (class 2606 OID 157763)
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- TOC entry 5120 (class 2606 OID 157755)
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 5130 (class 2606 OID 157819)
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 5156 (class 2606 OID 157988)
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5166 (class 2606 OID 158066)
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- TOC entry 5164 (class 2606 OID 158045)
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5116 (class 2606 OID 157737)
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- TOC entry 5118 (class 2606 OID 157739)
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- TOC entry 5162 (class 2606 OID 158029)
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- TOC entry 5114 (class 2606 OID 157722)
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- TOC entry 5106 (class 2606 OID 157636)
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- TOC entry 5108 (class 2606 OID 157642)
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- TOC entry 5104 (class 2606 OID 157621)
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- TOC entry 5102 (class 2606 OID 157613)
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- TOC entry 5112 (class 2606 OID 157689)
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 5100 (class 2606 OID 157600)
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 5098 (class 2606 OID 157589)
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 5096 (class 2606 OID 157578)
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- TOC entry 5196 (class 2606 OID 158372)
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 5214 (class 2606 OID 158519)
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 5094 (class 2606 OID 157557)
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 5090 (class 2606 OID 157536)
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- TOC entry 5092 (class 2606 OID 157542)
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- TOC entry 5176 (class 2606 OID 158159)
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 5182 (class 2606 OID 158270)
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- TOC entry 5084 (class 2606 OID 157479)
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- TOC entry 5078 (class 2606 OID 157440)
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- TOC entry 5080 (class 2606 OID 157446)
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 5082 (class 2606 OID 157466)
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- TOC entry 5180 (class 2606 OID 158224)
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- TOC entry 5178 (class 2606 OID 158195)
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- TOC entry 5194 (class 2606 OID 158351)
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 5192 (class 2606 OID 158345)
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- TOC entry 5074 (class 2606 OID 157424)
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- TOC entry 5076 (class 2606 OID 157422)
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- TOC entry 5070 (class 2606 OID 157411)
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- TOC entry 5072 (class 2606 OID 157409)
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 5068 (class 2606 OID 157401)
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 5066 (class 2606 OID 157393)
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- TOC entry 5064 (class 2606 OID 157385)
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- TOC entry 5088 (class 2606 OID 157506)
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 5086 (class 2606 OID 157485)
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- TOC entry 5190 (class 2606 OID 158340)
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 5060 (class 2606 OID 157365)
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- TOC entry 5062 (class 2606 OID 157363)
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- TOC entry 5058 (class 2606 OID 157355)
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 5110 (class 2606 OID 157673)
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- TOC entry 5056 (class 2606 OID 157347)
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- TOC entry 5186 (class 2606 OID 158319)
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- TOC entry 5188 (class 2606 OID 158327)
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5046 (class 2606 OID 157317)
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- TOC entry 5048 (class 2606 OID 157315)
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- TOC entry 5038 (class 2606 OID 157263)
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- TOC entry 5042 (class 2606 OID 157292)
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- TOC entry 5044 (class 2606 OID 157302)
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5040 (class 2606 OID 157268)
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- TOC entry 5184 (class 2606 OID 158306)
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- TOC entry 5036 (class 2606 OID 157253)
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- TOC entry 5128 (class 2606 OID 157790)
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- TOC entry 5174 (class 2606 OID 158150)
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- TOC entry 5034 (class 2606 OID 157243)
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 5154 (class 2606 OID 157971)
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 5160 (class 2606 OID 158013)
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- TOC entry 5158 (class 2606 OID 158002)
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5224 (class 2606 OID 158635)
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 5200 (class 2606 OID 158393)
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- TOC entry 5212 (class 2606 OID 158500)
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 5210 (class 2606 OID 158490)
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- TOC entry 5208 (class 2606 OID 158480)
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 5032 (class 2606 OID 157225)
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 5206 (class 2606 OID 158464)
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 5204 (class 2606 OID 158438)
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 5202 (class 2606 OID 158390)
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 5222 (class 2606 OID 158624)
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5220 (class 2606 OID 158603)
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 5216 (class 2606 OID 158550)
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- TOC entry 5218 (class 2606 OID 158548)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 5150 (class 2606 OID 157948)
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- TOC entry 5030 (class 2606 OID 157215)
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- TOC entry 5152 (class 2606 OID 157953)
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- TOC entry 5050 (class 2606 OID 157323)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 5052 (class 2606 OID 157325)
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- TOC entry 5054 (class 2606 OID 157327)
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- TOC entry 5026 (class 2606 OID 157197)
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- TOC entry 5028 (class 2606 OID 157195)
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- TOC entry 5024 (class 2606 OID 157187)
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 5022 (class 2606 OID 157179)
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4402 (class 2606 OID 154380)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4405 (class 2606 OID 154382)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4407 (class 2606 OID 154384)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 4419 (class 2606 OID 154386)
-- Name: audit_log_global_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_pkey PRIMARY KEY (id);


--
-- TOC entry 4409 (class 2606 OID 154388)
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4425 (class 2606 OID 154390)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4427 (class 2606 OID 154392)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 4429 (class 2606 OID 154394)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 4433 (class 2606 OID 154396)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4431 (class 2606 OID 154398)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 4437 (class 2606 OID 154400)
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- TOC entry 4439 (class 2606 OID 154402)
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- TOC entry 4441 (class 2606 OID 154404)
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- TOC entry 4435 (class 2606 OID 154406)
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- TOC entry 4443 (class 2606 OID 154408)
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- TOC entry 4446 (class 2606 OID 154410)
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- TOC entry 4449 (class 2606 OID 154412)
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- TOC entry 4451 (class 2606 OID 154414)
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4459 (class 2606 OID 154416)
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 4464 (class 2606 OID 154418)
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- TOC entry 4468 (class 2606 OID 154420)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 4470 (class 2606 OID 154422)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4472 (class 2606 OID 154424)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 4474 (class 2606 OID 154426)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 4478 (class 2606 OID 154428)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 4480 (class 2606 OID 154430)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 4483 (class 2606 OID 154432)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 4485 (class 2606 OID 154434)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4490 (class 2606 OID 154436)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4492 (class 2606 OID 154438)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4494 (class 2606 OID 154440)
-- Name: cat_uom_conversion_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4499 (class 2606 OID 154442)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4501 (class 2606 OID 154444)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 4503 (class 2606 OID 154446)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 4505 (class 2606 OID 154448)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 4507 (class 2606 OID 154450)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 4511 (class 2606 OID 154452)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4513 (class 2606 OID 154454)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4515 (class 2606 OID 154456)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 4519 (class 2606 OID 154458)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4523 (class 2606 OID 154460)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4526 (class 2606 OID 154462)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 4528 (class 2606 OID 154464)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4531 (class 2606 OID 154466)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4534 (class 2606 OID 156389)
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- TOC entry 4536 (class 2606 OID 154470)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4540 (class 2606 OID 154472)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4542 (class 2606 OID 154474)
-- Name: insumo_proveedor_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4538 (class 2606 OID 154476)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 4555 (class 2606 OID 154478)
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4560 (class 2606 OID 154480)
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4548 (class 2606 OID 154482)
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4553 (class 2606 OID 154484)
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- TOC entry 4563 (class 2606 OID 154486)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 4565 (class 2606 OID 154488)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4570 (class 2606 OID 154490)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 4576 (class 2606 OID 154492)
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4581 (class 2606 OID 154494)
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- TOC entry 4583 (class 2606 OID 154496)
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- TOC entry 4594 (class 2606 OID 154498)
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- TOC entry 4598 (class 2606 OID 154500)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 4600 (class 2606 OID 154502)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4602 (class 2606 OID 154504)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 4604 (class 2606 OID 154506)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4606 (class 2606 OID 154508)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 4611 (class 2606 OID 154510)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 4623 (class 2606 OID 154512)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 4626 (class 2606 OID 154514)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4628 (class 2606 OID 154516)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 4630 (class 2606 OID 154518)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4634 (class 2606 OID 154520)
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- TOC entry 4636 (class 2606 OID 154522)
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4640 (class 2606 OID 154524)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 4642 (class 2606 OID 154526)
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4646 (class 2606 OID 154528)
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4650 (class 2606 OID 154530)
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4658 (class 2606 OID 154532)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 4660 (class 2606 OID 154534)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4663 (class 2606 OID 154536)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 4666 (class 2606 OID 154538)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 4668 (class 2606 OID 154540)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 4670 (class 2606 OID 154542)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4684 (class 2606 OID 154544)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 4712 (class 2606 OID 154546)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4716 (class 2606 OID 154548)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4718 (class 2606 OID 154550)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4720 (class 2606 OID 154552)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 4723 (class 2606 OID 154554)
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- TOC entry 4725 (class 2606 OID 154556)
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4728 (class 2606 OID 154558)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4730 (class 2606 OID 154560)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 4732 (class 2606 OID 154562)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 4735 (class 2606 OID 154564)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4737 (class 2606 OID 154566)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4739 (class 2606 OID 154568)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4741 (class 2606 OID 154570)
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4743 (class 2606 OID 154572)
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 4590 (class 2606 OID 154574)
-- Name: pk_inventory_snapshot; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT pk_inventory_snapshot PRIMARY KEY (snapshot_date, branch_id, item_id);


--
-- TOC entry 4749 (class 2606 OID 154576)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 4752 (class 2606 OID 154578)
-- Name: pos_modifiers_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4754 (class 2606 OID 154580)
-- Name: pos_modifiers_map_pos_modifier_code_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pos_modifier_code_key UNIQUE (pos_modifier_code);


--
-- TOC entry 4759 (class 2606 OID 154582)
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4764 (class 2606 OID 154584)
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4766 (class 2606 OID 154586)
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4768 (class 2606 OID 154588)
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4773 (class 2606 OID 154590)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4784 (class 2606 OID 154592)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 4788 (class 2606 OID 154594)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 4778 (class 2606 OID 154596)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4790 (class 2606 OID 154598)
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 154600)
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4796 (class 2606 OID 154602)
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4801 (class 2606 OID 154604)
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4806 (class 2606 OID 154606)
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4809 (class 2606 OID 154608)
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4814 (class 2606 OID 154610)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4817 (class 2606 OID 154612)
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 4823 (class 2606 OID 154614)
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4826 (class 2606 OID 154616)
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4828 (class 2606 OID 154618)
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4832 (class 2606 OID 154620)
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4839 (class 2606 OID 154622)
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- TOC entry 4841 (class 2606 OID 154624)
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 4847 (class 2606 OID 154626)
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4855 (class 2606 OID 154628)
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4860 (class 2606 OID 154630)
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4865 (class 2606 OID 154632)
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- TOC entry 4868 (class 2606 OID 154634)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4870 (class 2606 OID 154636)
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- TOC entry 4874 (class 2606 OID 154638)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4880 (class 2606 OID 154640)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4698 (class 2606 OID 154642)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 4700 (class 2606 OID 154644)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4882 (class 2606 OID 154646)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 4702 (class 2606 OID 154648)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4890 (class 2606 OID 154650)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4892 (class 2606 OID 154652)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, item_id);


--
-- TOC entry 4884 (class 2606 OID 154654)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 154656)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 4706 (class 2606 OID 154658)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 4708 (class 2606 OID 154660)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 4897 (class 2606 OID 154662)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4901 (class 2606 OID 154664)
-- Name: recipe_cost_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT recipe_cost_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4904 (class 2606 OID 154666)
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4907 (class 2606 OID 154668)
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- TOC entry 4911 (class 2606 OID 154670)
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 4913 (class 2606 OID 154672)
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- TOC entry 4916 (class 2606 OID 154674)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4918 (class 2606 OID 154676)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4923 (class 2606 OID 154678)
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4926 (class 2606 OID 154680)
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 5015 (class 2606 OID 156915)
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4935 (class 2606 OID 154684)
-- Name: report_favorites_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites
    ADD CONSTRAINT report_favorites_pkey PRIMARY KEY (id);


--
-- TOC entry 5020 (class 2606 OID 156929)
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- TOC entry 4938 (class 2606 OID 154688)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 4940 (class 2606 OID 154690)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 4942 (class 2606 OID 154692)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 4944 (class 2606 OID 154694)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4946 (class 2606 OID 154696)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4644 (class 2606 OID 154698)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- TOC entry 4648 (class 2606 OID 154700)
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- TOC entry 4652 (class 2606 OID 154702)
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- TOC entry 4857 (class 2606 OID 154704)
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 5017 (class 2606 OID 156917)
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- TOC entry 4689 (class 2606 OID 154708)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 4691 (class 2606 OID 154710)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 4949 (class 2606 OID 154712)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 4952 (class 2606 OID 154714)
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4954 (class 2606 OID 154716)
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4959 (class 2606 OID 154718)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4964 (class 2606 OID 154720)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4961 (class 2606 OID 154722)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4969 (class 2606 OID 154724)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4971 (class 2606 OID 154726)
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 4976 (class 2606 OID 154728)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 4978 (class 2606 OID 154730)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4980 (class 2606 OID 154732)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4982 (class 2606 OID 154734)
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4984 (class 2606 OID 154736)
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4987 (class 2606 OID 154738)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4991 (class 2606 OID 154740)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4993 (class 2606 OID 154742)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4995 (class 2606 OID 154744)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4997 (class 2606 OID 154746)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4999 (class 2606 OID 154748)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 5001 (class 2606 OID 154750)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 5003 (class 2606 OID 154752)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4775 (class 2606 OID 154754)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4781 (class 2606 OID 154756)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4849 (class 2606 OID 154758)
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- TOC entry 5005 (class 2606 OID 154760)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 5007 (class 2606 OID 154762)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5009 (class 2606 OID 154764)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 5011 (class 2606 OID 154766)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 5013 (class 2606 OID 154768)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 4444 (class 1259 OID 154799)
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON cash_fund_arqueos USING btree (cash_fund_id);


--
-- TOC entry 4447 (class 1259 OID 154800)
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON cash_fund_arqueos USING btree (created_by_user_id);


--
-- TOC entry 4455 (class 1259 OID 154801)
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON cash_fund_movements USING btree (cash_fund_id);


--
-- TOC entry 4456 (class 1259 OID 154802)
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON cash_fund_movements USING btree (created_by_user_id);


--
-- TOC entry 4457 (class 1259 OID 154803)
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON cash_fund_movements USING btree (estatus);


--
-- TOC entry 4460 (class 1259 OID 154804)
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON cash_fund_movements USING btree (tipo);


--
-- TOC entry 4461 (class 1259 OID 154805)
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON cash_funds USING btree (estado);


--
-- TOC entry 4462 (class 1259 OID 154806)
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON cash_funds USING btree (fecha);


--
-- TOC entry 4465 (class 1259 OID 154807)
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON cash_funds USING btree (responsable_user_id);


--
-- TOC entry 4466 (class 1259 OID 154808)
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON cash_funds USING btree (sucursal_id);


--
-- TOC entry 4410 (class 1259 OID 154809)
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON audit_log USING btree (accion);


--
-- TOC entry 4411 (class 1259 OID 154810)
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON audit_log USING btree (entidad);


--
-- TOC entry 4412 (class 1259 OID 154811)
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON audit_log USING btree (entidad_id);


--
-- TOC entry 4420 (class 1259 OID 154812)
-- Name: idx_audit_log_global_changed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_changed_at ON audit_log_global USING btree (changed_at);


--
-- TOC entry 4421 (class 1259 OID 154813)
-- Name: idx_audit_log_global_operation; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_operation ON audit_log_global USING btree (operation);


--
-- TOC entry 4422 (class 1259 OID 154814)
-- Name: idx_audit_log_global_table; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_table ON audit_log_global USING btree (table_name);


--
-- TOC entry 4423 (class 1259 OID 154815)
-- Name: idx_audit_log_global_user; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_user ON audit_log_global USING btree (changed_by_user_id);


--
-- TOC entry 4413 (class 1259 OID 154816)
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON audit_log USING btree ("timestamp");


--
-- TOC entry 4414 (class 1259 OID 154817)
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON audit_log USING btree (user_id);


--
-- TOC entry 4481 (class 1259 OID 154818)
-- Name: idx_cat_sucursales_pos_location; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_sucursales_pos_location ON cat_sucursales USING btree (pos_location);


--
-- TOC entry 4486 (class 1259 OID 154819)
-- Name: idx_cat_unidades_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_activo ON cat_unidades USING btree (activo);


--
-- TOC entry 4487 (class 1259 OID 154820)
-- Name: idx_cat_unidades_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_categoria ON cat_unidades USING btree (categoria);


--
-- TOC entry 4488 (class 1259 OID 154821)
-- Name: idx_cat_unidades_clave; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_clave ON cat_unidades USING btree (clave);


--
-- TOC entry 4495 (class 1259 OID 154822)
-- Name: idx_cat_uom_conversion_destino; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_destino ON cat_uom_conversion USING btree (destino_id);


--
-- TOC entry 4496 (class 1259 OID 154823)
-- Name: idx_cat_uom_conversion_origen; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_origen ON cat_uom_conversion USING btree (origen_id);


--
-- TOC entry 4497 (class 1259 OID 154824)
-- Name: idx_cat_uom_conversion_scope; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_scope ON cat_uom_conversion USING btree (scope);


--
-- TOC entry 4529 (class 1259 OID 154825)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4566 (class 1259 OID 154826)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 4567 (class 1259 OID 154827)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 4568 (class 1259 OID 154828)
-- Name: idx_inventory_batch_item_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item_estado ON inventory_batch USING btree (item_id, estado);


--
-- TOC entry 4586 (class 1259 OID 154829)
-- Name: idx_invshot_branch_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_branch_date ON inventory_snapshot USING btree (branch_id, snapshot_date);


--
-- TOC entry 4587 (class 1259 OID 154830)
-- Name: idx_invshot_item_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_item_date ON inventory_snapshot USING btree (item_id, snapshot_date);


--
-- TOC entry 4588 (class 1259 OID 154831)
-- Name: idx_invshot_variance; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_variance ON inventory_snapshot USING btree (snapshot_date, branch_id, variance_qty);


--
-- TOC entry 4615 (class 1259 OID 154832)
-- Name: idx_items_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo ON items USING btree (activo) WHERE (activo = true);


--
-- TOC entry 4616 (class 1259 OID 154833)
-- Name: idx_items_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo_categoria ON items USING btree (activo, categoria_id) WHERE (activo = true);


--
-- TOC entry 4617 (class 1259 OID 154834)
-- Name: idx_items_categoria_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_categoria_id ON items USING btree (categoria_id);


--
-- TOC entry 4618 (class 1259 OID 154835)
-- Name: idx_items_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_nombre_lower ON items USING btree (lower((nombre)::text));


--
-- TOC entry 4619 (class 1259 OID 154836)
-- Name: idx_items_unidad_compra_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_compra_id ON items USING btree (unidad_compra_id) WHERE ((activo = true) AND (unidad_compra_id IS NOT NULL));


--
-- TOC entry 4620 (class 1259 OID 154837)
-- Name: idx_items_unidad_medida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_medida_id ON items USING btree (unidad_medida_id) WHERE (activo = true);


--
-- TOC entry 4621 (class 1259 OID 154838)
-- Name: idx_items_unidad_salida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_salida_id ON items USING btree (unidad_salida_id) WHERE ((activo = true) AND (unidad_salida_id IS NOT NULL));


--
-- TOC entry 4653 (class 1259 OID 154839)
-- Name: idx_merma_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_batch_id ON merma USING btree (batch_id);


--
-- TOC entry 4654 (class 1259 OID 154840)
-- Name: idx_merma_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_deleted_at ON merma USING btree (deleted_at);


--
-- TOC entry 4655 (class 1259 OID 154841)
-- Name: idx_merma_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_item_id ON merma USING btree (item_id);


--
-- TOC entry 4656 (class 1259 OID 154842)
-- Name: idx_merma_usuario_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_usuario_id ON merma USING btree (usuario_id);


--
-- TOC entry 4671 (class 1259 OID 154843)
-- Name: idx_mov_inv_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4672 (class 1259 OID 154844)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 4673 (class 1259 OID 154845)
-- Name: idx_mov_inv_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4674 (class 1259 OID 154846)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 4675 (class 1259 OID 154847)
-- Name: idx_mov_inv_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4676 (class 1259 OID 154848)
-- Name: idx_mov_inv_ts_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts_tipo ON mov_inv USING btree (ts, tipo);


--
-- TOC entry 4710 (class 1259 OID 154850)
-- Name: idx_op_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_cab_deleted_at ON op_cab USING btree (deleted_at);


--
-- TOC entry 4713 (class 1259 OID 154851)
-- Name: idx_op_insumo_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_batch_id ON op_insumo USING btree (batch_id);


--
-- TOC entry 4714 (class 1259 OID 154852)
-- Name: idx_op_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_item_id ON op_insumo USING btree (item_id);


--
-- TOC entry 4733 (class 1259 OID 154853)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 4745 (class 1259 OID 154854)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 4755 (class 1259 OID 154855)
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON pos_reprocess_log USING btree (reprocessed_at);


--
-- TOC entry 4756 (class 1259 OID 154856)
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON pos_reprocess_log USING btree (ticket_id);


--
-- TOC entry 4757 (class 1259 OID 154857)
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON pos_reprocess_log USING btree (user_id);


--
-- TOC entry 4760 (class 1259 OID 154858)
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON pos_reverse_log USING btree (reversed_at);


--
-- TOC entry 4761 (class 1259 OID 154859)
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON pos_reverse_log USING btree (ticket_id);


--
-- TOC entry 4762 (class 1259 OID 154860)
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON pos_reverse_log USING btree (user_id);


--
-- TOC entry 4750 (class 1259 OID 154861)
-- Name: idx_posmod_active_valid; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_posmod_active_valid ON pos_modifiers_map USING btree (active, valid_from, (COALESCE(valid_to, '2999-12-31'::date)));


--
-- TOC entry 4771 (class 1259 OID 154862)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 4782 (class 1259 OID 154863)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 4785 (class 1259 OID 154864)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4776 (class 1259 OID 154865)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 4835 (class 1259 OID 154866)
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON purchase_requests USING btree (fecha_requerida);


--
-- TOC entry 4836 (class 1259 OID 154867)
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON purchase_requests USING btree (urgente);


--
-- TOC entry 4475 (class 1259 OID 154868)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 4476 (class 1259 OID 154869)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 4850 (class 1259 OID 154870)
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON purchase_suggestions USING btree (estado);


--
-- TOC entry 4851 (class 1259 OID 154871)
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON purchase_suggestions USING btree (sugerido_en);


--
-- TOC entry 4852 (class 1259 OID 154872)
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON purchase_suggestions USING btree (prioridad);


--
-- TOC entry 4853 (class 1259 OID 154873)
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON purchase_suggestions USING btree (sucursal_id, estado);


--
-- TOC entry 4844 (class 1259 OID 154874)
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON purchase_suggestion_lines USING btree (item_id);


--
-- TOC entry 4845 (class 1259 OID 154875)
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON purchase_suggestion_lines USING btree (suggestion_id);


--
-- TOC entry 4872 (class 1259 OID 154876)
-- Name: idx_recepcion_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_cab_deleted_at ON recepcion_cab USING btree (deleted_at);


--
-- TOC entry 4876 (class 1259 OID 154877)
-- Name: idx_recepcion_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_batch_id ON recepcion_det USING btree (batch_id);


--
-- TOC entry 4877 (class 1259 OID 154878)
-- Name: idx_recepcion_det_bodega_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_bodega_id ON recepcion_det USING btree (bodega_id);


--
-- TOC entry 4878 (class 1259 OID 154879)
-- Name: idx_recepcion_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_item_id ON recepcion_det USING btree (item_id);


--
-- TOC entry 4693 (class 1259 OID 154880)
-- Name: idx_receta_cab_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo ON receta_cab USING btree (activo) WHERE (activo = true);


--
-- TOC entry 4694 (class 1259 OID 154881)
-- Name: idx_receta_cab_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo_categoria ON receta_cab USING btree (activo, categoria_plato) WHERE (activo = true);


--
-- TOC entry 4695 (class 1259 OID 154882)
-- Name: idx_receta_cab_categoria_plato; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_categoria_plato ON receta_cab USING btree (categoria_plato);


--
-- TOC entry 4696 (class 1259 OID 154883)
-- Name: idx_receta_cab_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_nombre_lower ON receta_cab USING btree (lower((nombre_plato)::text));


--
-- TOC entry 4885 (class 1259 OID 154884)
-- Name: idx_receta_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_item_id ON receta_insumo USING btree (item_id);


--
-- TOC entry 4886 (class 1259 OID 154885)
-- Name: idx_receta_insumo_receta_version_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_receta_version_id ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4703 (class 1259 OID 154886)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 4898 (class 1259 OID 154887)
-- Name: idx_recipe_cost_snap_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_date ON recipe_cost_snapshots USING btree (snapshot_date DESC);


--
-- TOC entry 4899 (class 1259 OID 154888)
-- Name: idx_recipe_cost_snap_recipe_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_recipe_date ON recipe_cost_snapshots USING btree (recipe_id, snapshot_date DESC);


--
-- TOC entry 4933 (class 1259 OID 154889)
-- Name: idx_report_key; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_key ON report_favorites USING btree (report_key);


--
-- TOC entry 5018 (class 1259 OID 156935)
-- Name: idx_report_runs_report_status; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_runs_report_status ON report_runs USING btree (report_id, status);


--
-- TOC entry 4685 (class 1259 OID 154890)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4955 (class 1259 OID 154891)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4956 (class 1259 OID 154892)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 4962 (class 1259 OID 154893)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 4965 (class 1259 OID 154894)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 4966 (class 1259 OID 154895)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 4967 (class 1259 OID 154896)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 4974 (class 1259 OID 154897)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 4985 (class 1259 OID 154898)
-- Name: idx_traspaso_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_cab_deleted_at ON traspaso_cab USING btree (deleted_at);


--
-- TOC entry 4988 (class 1259 OID 154899)
-- Name: idx_traspaso_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_batch_id ON traspaso_det USING btree (batch_id);


--
-- TOC entry 4989 (class 1259 OID 154900)
-- Name: idx_traspaso_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_item_id ON traspaso_det USING btree (item_id);


--
-- TOC entry 4532 (class 1259 OID 156390)
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- TOC entry 4556 (class 1259 OID 154902)
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON inv_consumo_pos_det USING btree (procesado);


--
-- TOC entry 4557 (class 1259 OID 154903)
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- TOC entry 4558 (class 1259 OID 156387)
-- Name: inv_consumo_pos_det_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_revertido_idx ON inv_consumo_pos_det USING btree (revertido);


--
-- TOC entry 4561 (class 1259 OID 154904)
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON inv_consumo_pos_log USING btree (ticket_id);


--
-- TOC entry 4549 (class 1259 OID 154905)
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON inv_consumo_pos USING btree (procesado);


--
-- TOC entry 4550 (class 1259 OID 154906)
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON inv_consumo_pos USING btree (requiere_reproceso);


--
-- TOC entry 4551 (class 1259 OID 156379)
-- Name: inv_consumo_pos_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_revertido_idx ON inv_consumo_pos USING btree (revertido);


--
-- TOC entry 4572 (class 1259 OID 154907)
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON inventory_count_lines USING btree (inventory_batch_id);


--
-- TOC entry 4573 (class 1259 OID 154908)
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON inventory_count_lines USING btree (inventory_count_id);


--
-- TOC entry 4574 (class 1259 OID 156391)
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON inventory_count_lines USING btree (item_id);


--
-- TOC entry 4577 (class 1259 OID 154910)
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON inventory_counts USING btree (almacen_id);


--
-- TOC entry 4578 (class 1259 OID 154911)
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON inventory_counts USING btree (cerrado_en);


--
-- TOC entry 4579 (class 1259 OID 154912)
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON inventory_counts USING btree (estado);


--
-- TOC entry 4584 (class 1259 OID 154913)
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON inventory_counts USING btree (programado_para);


--
-- TOC entry 4585 (class 1259 OID 154914)
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON inventory_counts USING btree (sucursal_id);


--
-- TOC entry 4591 (class 1259 OID 154915)
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON inventory_wastes USING btree (inventory_batch_id);


--
-- TOC entry 4592 (class 1259 OID 154916)
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON inventory_wastes USING btree (item_id);


--
-- TOC entry 4595 (class 1259 OID 154917)
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON inventory_wastes USING btree (production_order_id);


--
-- TOC entry 4596 (class 1259 OID 154918)
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON inventory_wastes USING btree (sucursal_id);


--
-- TOC entry 4543 (class 1259 OID 154919)
-- Name: ipp_activo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_activo_idx ON insumo_proveedor_presentacion USING btree (activo);


--
-- TOC entry 4544 (class 1259 OID 154920)
-- Name: ipp_insumo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_insumo_idx ON insumo_proveedor_presentacion USING btree (item_id);


--
-- TOC entry 4545 (class 1259 OID 154921)
-- Name: ipp_proveedor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_proveedor_idx ON insumo_proveedor_presentacion USING btree (proveedor_id);


--
-- TOC entry 4546 (class 1259 OID 154922)
-- Name: ipp_uni; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ipp_uni ON insumo_proveedor_presentacion USING btree (item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra);


--
-- TOC entry 4403 (class 1259 OID 154923)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 4516 (class 1259 OID 154924)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 4520 (class 1259 OID 154925)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4524 (class 1259 OID 154926)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 4571 (class 1259 OID 154927)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 4607 (class 1259 OID 154928)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 4608 (class 1259 OID 154929)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 4612 (class 1259 OID 154930)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 4613 (class 1259 OID 154931)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 4614 (class 1259 OID 154932)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 4508 (class 1259 OID 154933)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 4509 (class 1259 OID 154934)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 4637 (class 1259 OID 154935)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 4638 (class 1259 OID 154936)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (item_id);


--
-- TOC entry 4677 (class 1259 OID 154937)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4678 (class 1259 OID 154938)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 4679 (class 1259 OID 154939)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 4680 (class 1259 OID 154940)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 4681 (class 1259 OID 154941)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4682 (class 1259 OID 154942)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4746 (class 1259 OID 154943)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 4747 (class 1259 OID 154944)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 4786 (class 1259 OID 154945)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4895 (class 1259 OID 154946)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4887 (class 1259 OID 154947)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (item_id);


--
-- TOC entry 4888 (class 1259 OID 154948)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4704 (class 1259 OID 154949)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 4914 (class 1259 OID 154950)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 4686 (class 1259 OID 154951)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 4687 (class 1259 OID 154952)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4957 (class 1259 OID 154953)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4631 (class 1259 OID 154954)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 4632 (class 1259 OID 154955)
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON labor_roles USING btree (activo);


--
-- TOC entry 4661 (class 1259 OID 154956)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 4664 (class 1259 OID 154957)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 4692 (class 1259 OID 154958)
-- Name: mv_inventario_actual_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_inventario_actual_item_id_idx ON mv_inventario_actual USING btree (item_id);


--
-- TOC entry 4709 (class 1259 OID 154959)
-- Name: mv_recetas_costos_receta_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_recetas_costos_receta_id_idx ON mv_recetas_costos USING btree (receta_id);


--
-- TOC entry 4721 (class 1259 OID 154960)
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON overhead_definitions USING btree (activo);


--
-- TOC entry 4726 (class 1259 OID 154961)
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON overhead_definitions USING btree (tipo);


--
-- TOC entry 4744 (class 1259 OID 154962)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 4779 (class 1259 OID 154963)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 4793 (class 1259 OID 154964)
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON production_order_inputs USING btree (inventory_batch_id);


--
-- TOC entry 4794 (class 1259 OID 154965)
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON production_order_inputs USING btree (item_id);


--
-- TOC entry 4797 (class 1259 OID 154966)
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON production_order_inputs USING btree (production_order_id);


--
-- TOC entry 4798 (class 1259 OID 154967)
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON production_order_outputs USING btree (inventory_batch_id);


--
-- TOC entry 4799 (class 1259 OID 154968)
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON production_order_outputs USING btree (item_id);


--
-- TOC entry 4802 (class 1259 OID 154969)
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON production_order_outputs USING btree (production_order_id);


--
-- TOC entry 4803 (class 1259 OID 154970)
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON production_orders USING btree (almacen_id);


--
-- TOC entry 4804 (class 1259 OID 154971)
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON production_orders USING btree (estado);


--
-- TOC entry 4807 (class 1259 OID 154972)
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON production_orders USING btree (item_id);


--
-- TOC entry 4810 (class 1259 OID 154973)
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON production_orders USING btree (programado_para);


--
-- TOC entry 4811 (class 1259 OID 154974)
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON production_orders USING btree (recipe_id);


--
-- TOC entry 4812 (class 1259 OID 154975)
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON production_orders USING btree (sucursal_id);


--
-- TOC entry 4815 (class 1259 OID 154976)
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON purchase_documents USING btree (order_id);


--
-- TOC entry 4818 (class 1259 OID 154977)
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON purchase_documents USING btree (quote_id);


--
-- TOC entry 4819 (class 1259 OID 154978)
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON purchase_documents USING btree (request_id);


--
-- TOC entry 4820 (class 1259 OID 154979)
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON purchase_order_lines USING btree (item_id);


--
-- TOC entry 4821 (class 1259 OID 154980)
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON purchase_order_lines USING btree (order_id);


--
-- TOC entry 4824 (class 1259 OID 154981)
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON purchase_orders USING btree (estado);


--
-- TOC entry 4829 (class 1259 OID 154982)
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON purchase_orders USING btree (vendor_id);


--
-- TOC entry 4830 (class 1259 OID 154983)
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON purchase_request_lines USING btree (item_id);


--
-- TOC entry 4833 (class 1259 OID 154984)
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON purchase_request_lines USING btree (preferred_vendor_id);


--
-- TOC entry 4834 (class 1259 OID 154985)
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON purchase_request_lines USING btree (request_id);


--
-- TOC entry 4837 (class 1259 OID 154986)
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON purchase_requests USING btree (estado);


--
-- TOC entry 4842 (class 1259 OID 154987)
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON purchase_requests USING btree (requested_at);


--
-- TOC entry 4843 (class 1259 OID 154988)
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON purchase_requests USING btree (sucursal_id);


--
-- TOC entry 4858 (class 1259 OID 154989)
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON purchase_vendor_quote_lines USING btree (item_id);


--
-- TOC entry 4861 (class 1259 OID 154990)
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON purchase_vendor_quote_lines USING btree (quote_id);


--
-- TOC entry 4862 (class 1259 OID 154991)
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON purchase_vendor_quote_lines USING btree (request_line_id);


--
-- TOC entry 4863 (class 1259 OID 154992)
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON purchase_vendor_quotes USING btree (estado);


--
-- TOC entry 4866 (class 1259 OID 154993)
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- TOC entry 4871 (class 1259 OID 154994)
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON recepcion_adjuntos USING btree (recepcion_id);


--
-- TOC entry 4902 (class 1259 OID 154995)
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4905 (class 1259 OID 154996)
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON recipe_labor_steps USING btree (labor_role_id);


--
-- TOC entry 4908 (class 1259 OID 154997)
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON recipe_labor_steps USING btree (recipe_id);


--
-- TOC entry 4909 (class 1259 OID 154998)
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON recipe_overhead_allocations USING btree (overhead_id);


--
-- TOC entry 4920 (class 1259 OID 154999)
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON replenishment_suggestions USING btree (estado);


--
-- TOC entry 4921 (class 1259 OID 155000)
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- TOC entry 4924 (class 1259 OID 155001)
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- TOC entry 4927 (class 1259 OID 155002)
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON replenishment_suggestions USING btree (prioridad);


--
-- TOC entry 4928 (class 1259 OID 155003)
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON replenishment_suggestions USING btree (production_order_id);


--
-- TOC entry 4929 (class 1259 OID 155004)
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON replenishment_suggestions USING btree (purchase_request_id);


--
-- TOC entry 4930 (class 1259 OID 155005)
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON replenishment_suggestions USING btree (revisado_por);


--
-- TOC entry 4931 (class 1259 OID 155006)
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON replenishment_suggestions USING btree (sugerido_en);


--
-- TOC entry 4932 (class 1259 OID 155007)
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON replenishment_suggestions USING btree (tipo);


--
-- TOC entry 4936 (class 1259 OID 155008)
-- Name: report_favorites_user_id_report_key_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX report_favorites_user_id_report_key_unique ON report_favorites USING btree (user_id, report_key);


--
-- TOC entry 4415 (class 1259 OID 155009)
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON audit_log USING btree (entidad, entidad_id);


--
-- TOC entry 4416 (class 1259 OID 155010)
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON audit_log USING btree ("timestamp");


--
-- TOC entry 4417 (class 1259 OID 155011)
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON audit_log USING btree (user_id);


--
-- TOC entry 4452 (class 1259 OID 155012)
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON cash_fund_movement_audit_log USING btree (action);


--
-- TOC entry 4453 (class 1259 OID 155013)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- TOC entry 4454 (class 1259 OID 155014)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON cash_fund_movement_audit_log USING btree (movement_id);


--
-- TOC entry 4769 (class 1259 OID 155015)
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON pos_sync_logs USING btree (batch_id, status);


--
-- TOC entry 4770 (class 1259 OID 155016)
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON pos_sync_logs USING btree (external_id);


--
-- TOC entry 4875 (class 1259 OID 155017)
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON recepcion_cab USING btree (almacen_id);


--
-- TOC entry 4947 (class 1259 OID 155019)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 4950 (class 1259 OID 155020)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 4972 (class 1259 OID 155021)
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON ticket_item_modifiers USING btree (ticket_id);


--
-- TOC entry 4973 (class 1259 OID 155022)
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON ticket_item_modifiers USING btree (ticket_item_id);


--
-- TOC entry 4517 (class 1259 OID 155023)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 4521 (class 1259 OID 155024)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 4609 (class 1259 OID 155025)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 4624 (class 1259 OID 155026)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 4919 (class 1259 OID 155027)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


SET search_path = public, pg_catalog;

--
-- TOC entry 5502 (class 2620 OID 158394)
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON ticket FOR EACH ROW EXECUTE PROCEDURE assign_daily_folio();


--
-- TOC entry 5504 (class 2620 OID 158520)
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE OF status ON kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5503 (class 2620 OID 158439)
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE OF status ON ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5501 (class 2620 OID 157989)
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();


--
-- TOC entry 5500 (class 2620 OID 157972)
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- TOC entry 5505 (class 2620 OID 158551)
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5484 (class 2620 OID 155034)
-- Name: trg_invshot_biur; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_invshot_biur BEFORE INSERT OR UPDATE ON inventory_snapshot FOR EACH ROW EXECUTE PROCEDURE tg_invshot_autofill();


--
-- TOC entry 5482 (class 2620 OID 155035)
-- Name: trg_ipp_set_timestamp; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ipp_set_timestamp BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE set_timestamp_ipp();


--
-- TOC entry 5485 (class 2620 OID 155036)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 5488 (class 2620 OID 155037)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 5486 (class 2620 OID 155038)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 5487 (class 2620 OID 155039)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 5492 (class 2620 OID 155040)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 5493 (class 2620 OID 155041)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 5494 (class 2620 OID 155042)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 5495 (class 2620 OID 155043)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


--
-- TOC entry 5480 (class 2620 OID 155044)
-- Name: update_hist_cost_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_hist_cost_insumo_updated_at BEFORE UPDATE ON hist_cost_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5481 (class 2620 OID 155045)
-- Name: update_insumo_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_presentacion_updated_at BEFORE UPDATE ON insumo_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5483 (class 2620 OID 155046)
-- Name: update_insumo_proveedor_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_proveedor_presentacion_updated_at BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5489 (class 2620 OID 155047)
-- Name: update_merma_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_merma_updated_at BEFORE UPDATE ON merma FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5490 (class 2620 OID 155048)
-- Name: update_op_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_cab_updated_at BEFORE UPDATE ON op_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5491 (class 2620 OID 155049)
-- Name: update_op_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_insumo_updated_at BEFORE UPDATE ON op_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5496 (class 2620 OID 155050)
-- Name: update_recepcion_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_cab_updated_at BEFORE UPDATE ON recepcion_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5497 (class 2620 OID 155051)
-- Name: update_recepcion_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_det_updated_at BEFORE UPDATE ON recepcion_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5498 (class 2620 OID 155052)
-- Name: update_traspaso_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_cab_updated_at BEFORE UPDATE ON traspaso_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5499 (class 2620 OID 155053)
-- Name: update_traspaso_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_det_updated_at BEFORE UPDATE ON traspaso_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


SET search_path = public, pg_catalog;

--
-- TOC entry 5369 (class 2606 OID 157467)
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5470 (class 2606 OID 158521)
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5436 (class 2606 OID 158209)
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5437 (class 2606 OID 158214)
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES pizza_price(id);


--
-- TOC entry 5479 (class 2606 OID 158636)
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5356 (class 2606 OID 157269)
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5398 (class 2606 OID 157831)
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5397 (class 2606 OID 157820)
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES customer(auto_id);


--
-- TOC entry 5423 (class 2606 OID 158110)
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES currency(id);


--
-- TOC entry 5424 (class 2606 OID 158115)
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES cash_drawer(id);


--
-- TOC entry 5425 (class 2606 OID 158120)
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5406 (class 2606 OID 157954)
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES user_type(id);


--
-- TOC entry 5407 (class 2606 OID 157959)
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES user_permission(name);


--
-- TOC entry 5393 (class 2606 OID 157791)
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5394 (class 2606 OID 157796)
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5438 (class 2606 OID 158225)
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5439 (class 2606 OID 158230)
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES menu_item(id);


--
-- TOC entry 5440 (class 2606 OID 158235)
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5377 (class 2606 OID 157558)
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5415 (class 2606 OID 158425)
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5413 (class 2606 OID 158030)
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5414 (class 2606 OID 158035)
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5467 (class 2606 OID 158491)
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5466 (class 2606 OID 158481)
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES ticket_item(id);


--
-- TOC entry 5405 (class 2606 OID 157939)
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5429 (class 2606 OID 158160)
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES menu_group(id);


--
-- TOC entry 5430 (class 2606 OID 158165)
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5431 (class 2606 OID 158170)
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES tax_group(id);


--
-- TOC entry 5432 (class 2606 OID 158175)
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5433 (class 2606 OID 158180)
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES recepie(id);


--
-- TOC entry 5361 (class 2606 OID 157328)
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5362 (class 2606 OID 157333)
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES user_type(id);


--
-- TOC entry 5363 (class 2606 OID 157978)
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES terminal(id);


--
-- TOC entry 5376 (class 2606 OID 157543)
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES menu_category(id);


--
-- TOC entry 5402 (class 2606 OID 157893)
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES menu_category(id);


--
-- TOC entry 5403 (class 2606 OID 157898)
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5378 (class 2606 OID 157566)
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5374 (class 2606 OID 157515)
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5375 (class 2606 OID 157520)
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5379 (class 2606 OID 157622)
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5366 (class 2606 OID 157447)
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5367 (class 2606 OID 157452)
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5368 (class 2606 OID 157457)
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5409 (class 2606 OID 157990)
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES users(auto_id);


--
-- TOC entry 5464 (class 2606 OID 158465)
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5465 (class 2606 OID 158470)
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5422 (class 2606 OID 158099)
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5477 (class 2606 OID 158612)
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5364 (class 2606 OID 158185)
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES menu_item(id);


--
-- TOC entry 5395 (class 2606 OID 157804)
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES table_booking_info(id);


--
-- TOC entry 5396 (class 2606 OID 157809)
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5416 (class 2606 OID 158046)
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5417 (class 2606 OID 158051)
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5418 (class 2606 OID 158056)
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5478 (class 2606 OID 158625)
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES ticket(id);


--
-- TOC entry 5404 (class 2606 OID 157919)
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5380 (class 2606 OID 157643)
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES inventory_group(id);


--
-- TOC entry 5381 (class 2606 OID 157648)
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5382 (class 2606 OID 157653)
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5383 (class 2606 OID 157658)
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES inventory_location(id);


--
-- TOC entry 5384 (class 2606 OID 157663)
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5451 (class 2606 OID 158328)
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES restaurant(id);


--
-- TOC entry 5385 (class 2606 OID 157674)
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES inventory_item(id);


--
-- TOC entry 5386 (class 2606 OID 157679)
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES recepie(id);


--
-- TOC entry 5452 (class 2606 OID 158352)
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES multiplier(name);


--
-- TOC entry 5453 (class 2606 OID 158357)
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5454 (class 2606 OID 158362)
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5355 (class 2606 OID 158455)
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5455 (class 2606 OID 158395)
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES users(auto_id);


--
-- TOC entry 5456 (class 2606 OID 158400)
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5457 (class 2606 OID 158405)
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5458 (class 2606 OID 158410)
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5459 (class 2606 OID 158415)
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES gratuity(id);


--
-- TOC entry 5460 (class 2606 OID 158420)
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES users(auto_id);


--
-- TOC entry 5357 (class 2606 OID 157277)
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5358 (class 2606 OID 157282)
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES shop_table_type(id);


--
-- TOC entry 5410 (class 2606 OID 158003)
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES terminal(id);


--
-- TOC entry 5461 (class 2606 OID 158440)
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5462 (class 2606 OID 158445)
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5463 (class 2606 OID 158450)
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5421 (class 2606 OID 158088)
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5411 (class 2606 OID 158014)
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5412 (class 2606 OID 158019)
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5354 (class 2606 OID 157201)
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5443 (class 2606 OID 158256)
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5444 (class 2606 OID 158261)
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5468 (class 2606 OID 158501)
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5469 (class 2606 OID 158506)
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5419 (class 2606 OID 158067)
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5420 (class 2606 OID 158072)
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5387 (class 2606 OID 157690)
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES purchase_order(id);


--
-- TOC entry 5388 (class 2606 OID 157695)
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES inventory_item(id);


--
-- TOC entry 5389 (class 2606 OID 157700)
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5390 (class 2606 OID 157705)
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5391 (class 2606 OID 157710)
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5359 (class 2606 OID 157293)
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5365 (class 2606 OID 157369)
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES printer_group(id);


--
-- TOC entry 5450 (class 2606 OID 158310)
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES shop_table_status(id);


--
-- TOC entry 5392 (class 2606 OID 157723)
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5373 (class 2606 OID 157507)
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5399 (class 2606 OID 157844)
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES customer(auto_id);


--
-- TOC entry 5360 (class 2606 OID 157303)
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES shop_floor_template(id);


--
-- TOC entry 5441 (class 2606 OID 158243)
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5442 (class 2606 OID 158248)
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5426 (class 2606 OID 158131)
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5427 (class 2606 OID 158136)
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5428 (class 2606 OID 158141)
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5434 (class 2606 OID 158196)
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5435 (class 2606 OID 158201)
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5446 (class 2606 OID 158279)
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES order_type(id);


--
-- TOC entry 5447 (class 2606 OID 158284)
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5400 (class 2606 OID 157880)
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES menu_group(id);


--
-- TOC entry 5401 (class 2606 OID 157885)
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5476 (class 2606 OID 158604)
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES transactions(id);


--
-- TOC entry 5408 (class 2606 OID 157973)
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES users(auto_id);


--
-- TOC entry 5370 (class 2606 OID 157486)
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES pizza_crust(id);


--
-- TOC entry 5371 (class 2606 OID 157491)
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES order_type(id);


--
-- TOC entry 5372 (class 2606 OID 157496)
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5448 (class 2606 OID 158292)
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES tax(id);


--
-- TOC entry 5449 (class 2606 OID 158297)
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES tax_group(id);


--
-- TOC entry 5445 (class 2606 OID 158271)
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5471 (class 2606 OID 158552)
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5472 (class 2606 OID 158557)
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5473 (class 2606 OID 158562)
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5474 (class 2606 OID 158567)
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES payout_recepients(id);


--
-- TOC entry 5475 (class 2606 OID 158572)
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES payout_reasons(id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5225 (class 2606 OID 155684)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5227 (class 2606 OID 155689)
-- Name: audit_log_global_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES users(id);


--
-- TOC entry 5228 (class 2606 OID 155694)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5229 (class 2606 OID 155699)
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES caja_fondo_mov(id) ON DELETE CASCADE;


--
-- TOC entry 5230 (class 2606 OID 155704)
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5231 (class 2606 OID 155709)
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5232 (class 2606 OID 155714)
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5233 (class 2606 OID 155719)
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5234 (class 2606 OID 155724)
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5237 (class 2606 OID 155729)
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5238 (class 2606 OID 155734)
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5239 (class 2606 OID 155739)
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5240 (class 2606 OID 155744)
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5241 (class 2606 OID 155749)
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5242 (class 2606 OID 155754)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5243 (class 2606 OID 155759)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5244 (class 2606 OID 155764)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5245 (class 2606 OID 155769)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 5246 (class 2606 OID 155774)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5247 (class 2606 OID 155779)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5248 (class 2606 OID 155784)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5249 (class 2606 OID 155789)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5265 (class 2606 OID 155794)
-- Name: fk_inventory_snapshot_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT fk_inventory_snapshot_item FOREIGN KEY (item_id) REFERENCES items(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5301 (class 2606 OID 155799)
-- Name: fk_pos_map_receta; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT fk_pos_map_receta FOREIGN KEY (receta_id) REFERENCES receta_cab(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5310 (class 2606 OID 155804)
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5311 (class 2606 OID 155809)
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE SET NULL;


--
-- TOC entry 5315 (class 2606 OID 155814)
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5316 (class 2606 OID 155819)
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES purchase_requests(id) ON DELETE SET NULL;


--
-- TOC entry 5317 (class 2606 OID 155824)
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5318 (class 2606 OID 155829)
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5319 (class 2606 OID 155834)
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5312 (class 2606 OID 155839)
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5313 (class 2606 OID 155844)
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES cat_proveedores(id) ON DELETE SET NULL;


--
-- TOC entry 5314 (class 2606 OID 155849)
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE CASCADE;


--
-- TOC entry 5309 (class 2606 OID 155854)
-- Name: fk_purchase_orders_vendor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT fk_purchase_orders_vendor FOREIGN KEY (vendor_id) REFERENCES cat_proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5330 (class 2606 OID 155859)
-- Name: fk_recipe_cost_snap_recipe; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_recipe FOREIGN KEY (recipe_id) REFERENCES receta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5331 (class 2606 OID 155864)
-- Name: fk_recipe_cost_snap_user; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_user FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5339 (class 2606 OID 155869)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5250 (class 2606 OID 155874)
-- Name: hist_cost_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5251 (class 2606 OID 155879)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5252 (class 2606 OID 155884)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5253 (class 2606 OID 155889)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5255 (class 2606 OID 155894)
-- Name: insumo_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5256 (class 2606 OID 155899)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5257 (class 2606 OID 155904)
-- Name: insumo_proveedor_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5254 (class 2606 OID 155909)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5261 (class 2606 OID 155914)
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES inv_consumo_pos(id) ON DELETE CASCADE;


--
-- TOC entry 5262 (class 2606 OID 155919)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 5263 (class 2606 OID 155924)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 5264 (class 2606 OID 155929)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5258 (class 2606 OID 155934)
-- Name: ipp_proveedor_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_proveedor_fk FOREIGN KEY (proveedor_id) REFERENCES proveedor(id);


--
-- TOC entry 5259 (class 2606 OID 155939)
-- Name: ipp_uom_base_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_base_fk FOREIGN KEY (uom_base_id) REFERENCES cat_unidades(id);


--
-- TOC entry 5260 (class 2606 OID 155944)
-- Name: ipp_uom_compra_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_compra_fk FOREIGN KEY (uom_compra_id) REFERENCES cat_unidades(id);


--
-- TOC entry 5266 (class 2606 OID 155949)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5267 (class 2606 OID 155954)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5268 (class 2606 OID 155959)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5269 (class 2606 OID 155964)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5270 (class 2606 OID 155969)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5271 (class 2606 OID 155974)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5272 (class 2606 OID 155979)
-- Name: lote_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5275 (class 2606 OID 155984)
-- Name: merma_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5276 (class 2606 OID 155989)
-- Name: merma_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5277 (class 2606 OID 155994)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5278 (class 2606 OID 155999)
-- Name: merma_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5279 (class 2606 OID 156004)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5280 (class 2606 OID 156009)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5281 (class 2606 OID 156014)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 5282 (class 2606 OID 156019)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5283 (class 2606 OID 156024)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5287 (class 2606 OID 156029)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5288 (class 2606 OID 156034)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5289 (class 2606 OID 156039)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5290 (class 2606 OID 156044)
-- Name: op_cab_user_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5291 (class 2606 OID 156049)
-- Name: op_cab_user_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5292 (class 2606 OID 156054)
-- Name: op_insumo_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5293 (class 2606 OID 156059)
-- Name: op_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5294 (class 2606 OID 156064)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5295 (class 2606 OID 156069)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5296 (class 2606 OID 156074)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5297 (class 2606 OID 156079)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5298 (class 2606 OID 156084)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5299 (class 2606 OID 156089)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5300 (class 2606 OID 156094)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5303 (class 2606 OID 157151)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5305 (class 2606 OID 156104)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5306 (class 2606 OID 156109)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5304 (class 2606 OID 157156)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5307 (class 2606 OID 156119)
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id);


--
-- TOC entry 5308 (class 2606 OID 156124)
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5320 (class 2606 OID 156129)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 5321 (class 2606 OID 156134)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5322 (class 2606 OID 156139)
-- Name: recepcion_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5323 (class 2606 OID 156144)
-- Name: recepcion_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5324 (class 2606 OID 156149)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5325 (class 2606 OID 156154)
-- Name: recepcion_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5326 (class 2606 OID 156159)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5327 (class 2606 OID 156164)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5284 (class 2606 OID 156169)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5285 (class 2606 OID 156174)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5328 (class 2606 OID 156179)
-- Name: receta_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5329 (class 2606 OID 156184)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5286 (class 2606 OID 156189)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 5332 (class 2606 OID 156194)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5333 (class 2606 OID 156199)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5226 (class 2606 OID 156204)
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5235 (class 2606 OID 156209)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5236 (class 2606 OID 156214)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES cash_fund_movements(id) ON DELETE CASCADE;


--
-- TOC entry 5273 (class 2606 OID 156219)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5274 (class 2606 OID 156224)
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5302 (class 2606 OID 156229)
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES pos_sync_batches(id) ON DELETE CASCADE;


--
-- TOC entry 5353 (class 2606 OID 156930)
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE;


--
-- TOC entry 5334 (class 2606 OID 156239)
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5335 (class 2606 OID 156244)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5336 (class 2606 OID 156249)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5337 (class 2606 OID 156254)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5338 (class 2606 OID 156259)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5340 (class 2606 OID 156264)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 5341 (class 2606 OID 156269)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5342 (class 2606 OID 156274)
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES transfer_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5343 (class 2606 OID 156279)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5344 (class 2606 OID 156284)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5345 (class 2606 OID 156289)
-- Name: traspaso_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5346 (class 2606 OID 156294)
-- Name: traspaso_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5347 (class 2606 OID 156299)
-- Name: traspaso_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5348 (class 2606 OID 156304)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5349 (class 2606 OID 156309)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5350 (class 2606 OID 156314)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5351 (class 2606 OID 156319)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5352 (class 2606 OID 156324)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 5783 (class 0 OID 152949)
-- Dependencies: 306 6112
-- Name: mv_inventario_actual; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_inventario_actual;


--
-- TOC entry 5787 (class 0 OID 152991)
-- Dependencies: 310 6112
-- Name: mv_recetas_costos; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_recetas_costos;


--
-- TOC entry 6117 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 6413 (class 0 OID 0)
-- Dependencies: 625
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


--
-- TOC entry 6414 (class 0 OID 0)
-- Dependencies: 660
-- Name: vw_sesion_ventas; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_ventas FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_ventas FROM postgres;
GRANT ALL ON TABLE vw_sesion_ventas TO postgres;
GRANT SELECT ON TABLE vw_sesion_ventas TO floreant;


-- Completed on 2025-11-05 23:56:27

--
-- PostgreSQL database dump complete
--

