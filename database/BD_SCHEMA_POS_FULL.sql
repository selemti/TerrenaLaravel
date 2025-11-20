--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-19 10:22:03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6322 (class 1262 OID 345598)
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
-- TOC entry 6 (class 2615 OID 345599)
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

--
-- TOC entry 702 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 6325 (class 0 OID 0)
-- Dependencies: 702
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 704 (class 3079 OID 345600)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 6326 (class 0 OID 0)
-- Dependencies: 704
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 703 (class 3079 OID 345637)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 6327 (class 0 OID 0)
-- Dependencies: 703
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = selemti, pg_catalog;

--
-- TOC entry 1168 (class 1247 OID 345649)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1171 (class 1247 OID 345654)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1174 (class 1247 OID 345662)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1177 (class 1247 OID 345668)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1180 (class 1247 OID 345674)
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
-- TOC entry 1183 (class 1247 OID 345692)
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
-- TOC entry 1186 (class 1247 OID 345702)
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
-- TOC entry 1189 (class 1247 OID 345712)
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
-- TOC entry 763 (class 1255 OID 345719)
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
-- TOC entry 765 (class 1255 OID 345720)
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
-- TOC entry 766 (class 1255 OID 345721)
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
-- TOC entry 767 (class 1255 OID 345722)
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
-- TOC entry 768 (class 1255 OID 345723)
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
-- TOC entry 769 (class 1255 OID 345724)
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
-- TOC entry 771 (class 1255 OID 345725)
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
-- TOC entry 772 (class 1255 OID 345726)
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
-- TOC entry 773 (class 1255 OID 345727)
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
-- TOC entry 774 (class 1255 OID 345728)
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
-- TOC entry 775 (class 1255 OID 345729)
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
-- TOC entry 776 (class 1255 OID 345730)
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
-- TOC entry 777 (class 1255 OID 345731)
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
-- TOC entry 778 (class 1255 OID 345732)
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
-- TOC entry 779 (class 1255 OID 345733)
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
-- TOC entry 780 (class 1255 OID 345734)
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
-- TOC entry 781 (class 1255 OID 345735)
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
-- TOC entry 782 (class 1255 OID 345736)
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
-- TOC entry 783 (class 1255 OID 345737)
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
-- TOC entry 784 (class 1255 OID 345738)
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
-- TOC entry 785 (class 1255 OID 345739)
-- Name: fn_dah_after_insert_safe(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_dah_after_insert_safe() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE 
    v_term RECORD;
BEGIN
    IF NEW.operation = ''ASIGNAR'' THEN
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
                VALUES(NEW.a_user, ''TERMINAL_ASIGNADO_AUTOMATICAMENTE'',
                       jsonb_build_object(''terminal_id'', v_term.id, 
                                        ''dah_id'', NEW.id, 
                                        ''operation'', NEW.operation, 
                                        ''time'', NEW."time"));
            ELSE
                -- No hay terminales disponibles, solo registrar en auditoría
                INSERT INTO selemti.auditoria(quien, que, payload)
                VALUES(NEW.a_user, ''NO_HAY_TERMINAL_DISPONIBLE'',
                       jsonb_build_object(''dah_id'', NEW.id, 
                                        ''operation'', NEW.operation, 
                                        ''time'', NEW."time"));
                RETURN NEW;
            END IF;
        END IF;
        
        -- Insertar en sesión cajón
        INSERT INTO selemti.sesion_cajon(
            terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
            apertura_ts, estatus, opening_float, dah_evento_id
        ) VALUES (
            v_term.id, 
            COALESCE(v_term.name, ''Terminal ''||v_term.id), 
            COALESCE(v_term.location, ''''),
            NEW.a_user, 
            COALESCE(NEW."time", now()), 
            ''ACTIVA'', 
            COALESCE(v_term.current_balance, 0), 
            NEW.id
        ) ON CONFLICT DO NOTHING; -- Evitar duplicados
        
    ELSIF NEW.operation = ''CERRAR'' THEN
        SELECT * INTO v_term FROM public.terminal
        WHERE assigned_user = NEW.a_user
        ORDER BY id LIMIT 1;
        
        IF v_term IS NOT NULL THEN
            UPDATE selemti.sesion_cajon
            SET cierre_ts = COALESCE(NEW."time", now()),
                estatus = ''LISTO_PARA_CORTE'',
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
END ';


ALTER FUNCTION selemti.fn_dah_after_insert_safe() OWNER TO postgres;

--
-- TOC entry 786 (class 1255 OID 345740)
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
-- TOC entry 764 (class 1255 OID 345741)
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
-- TOC entry 770 (class 1255 OID 345742)
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
-- TOC entry 787 (class 1255 OID 345743)
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
-- TOC entry 6328 (class 0 OID 0)
-- Dependencies: 787
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 788 (class 1255 OID 345744)
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
-- TOC entry 789 (class 1255 OID 345745)
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
-- TOC entry 790 (class 1255 OID 345746)
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
-- TOC entry 791 (class 1255 OID 345747)
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
-- TOC entry 6329 (class 0 OID 0)
-- Dependencies: 791
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 792 (class 1255 OID 345748)
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
-- TOC entry 6330 (class 0 OID 0)
-- Dependencies: 792
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 793 (class 1255 OID 345749)
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
-- TOC entry 6331 (class 0 OID 0)
-- Dependencies: 793
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 794 (class 1255 OID 345750)
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
-- TOC entry 795 (class 1255 OID 345751)
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
-- TOC entry 796 (class 1255 OID 345752)
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
-- TOC entry 797 (class 1255 OID 345753)
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
-- TOC entry 798 (class 1255 OID 345754)
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
-- TOC entry 799 (class 1255 OID 345755)
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
-- TOC entry 800 (class 1255 OID 345756)
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
-- TOC entry 801 (class 1255 OID 345757)
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
-- TOC entry 802 (class 1255 OID 345758)
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
-- TOC entry 803 (class 1255 OID 345759)
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
-- TOC entry 804 (class 1255 OID 345760)
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
-- TOC entry 805 (class 1255 OID 345761)
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
-- TOC entry 806 (class 1255 OID 345762)
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
-- TOC entry 807 (class 1255 OID 345763)
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
-- TOC entry 808 (class 1255 OID 345764)
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
-- TOC entry 809 (class 1255 OID 345765)
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
-- TOC entry 810 (class 1255 OID 345766)
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
-- TOC entry 811 (class 1255 OID 345767)
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
-- TOC entry 812 (class 1255 OID 345768)
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
-- TOC entry 813 (class 1255 OID 345769)
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
-- TOC entry 181 (class 1259 OID 345770)
-- Name: action_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE action_history (
    id integer NOT NULL,
    action_time timestamp without time zone,
    action_name character varying(255),
    description character varying(255),
    user_id integer
);


ALTER TABLE action_history OWNER TO floreant;

--
-- TOC entry 182 (class 1259 OID 345776)
-- Name: action_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE action_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE action_history_id_seq OWNER TO floreant;

--
-- TOC entry 6332 (class 0 OID 0)
-- Dependencies: 182
-- Name: action_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE action_history_id_seq OWNED BY action_history.id;


--
-- TOC entry 183 (class 1259 OID 345778)
-- Name: attendence_history; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE attendence_history OWNER TO floreant;

--
-- TOC entry 184 (class 1259 OID 345781)
-- Name: attendence_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE attendence_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE attendence_history_id_seq OWNER TO floreant;

--
-- TOC entry 6333 (class 0 OID 0)
-- Dependencies: 184
-- Name: attendence_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE attendence_history_id_seq OWNED BY attendence_history.id;


--
-- TOC entry 185 (class 1259 OID 345783)
-- Name: cash_drawer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer (
    id integer NOT NULL,
    terminal_id integer
);


ALTER TABLE cash_drawer OWNER TO floreant;

--
-- TOC entry 186 (class 1259 OID 345786)
-- Name: cash_drawer_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE cash_drawer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_drawer_id_seq OWNER TO floreant;

--
-- TOC entry 6334 (class 0 OID 0)
-- Dependencies: 186
-- Name: cash_drawer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_id_seq OWNED BY cash_drawer.id;


--
-- TOC entry 187 (class 1259 OID 345788)
-- Name: cash_drawer_reset_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer_reset_history (
    id integer NOT NULL,
    reset_time timestamp without time zone,
    user_id integer
);


ALTER TABLE cash_drawer_reset_history OWNER TO floreant;

--
-- TOC entry 188 (class 1259 OID 345791)
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE cash_drawer_reset_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cash_drawer_reset_history_id_seq OWNER TO floreant;

--
-- TOC entry 6335 (class 0 OID 0)
-- Dependencies: 188
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_reset_history_id_seq OWNED BY cash_drawer_reset_history.id;


--
-- TOC entry 189 (class 1259 OID 345793)
-- Name: cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cooking_instruction (
    id integer NOT NULL,
    description character varying(60)
);


ALTER TABLE cooking_instruction OWNER TO floreant;

--
-- TOC entry 190 (class 1259 OID 345796)
-- Name: cooking_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE cooking_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cooking_instruction_id_seq OWNER TO floreant;

--
-- TOC entry 6336 (class 0 OID 0)
-- Dependencies: 190
-- Name: cooking_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cooking_instruction_id_seq OWNED BY cooking_instruction.id;


--
-- TOC entry 191 (class 1259 OID 345798)
-- Name: coupon_and_discount; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE coupon_and_discount OWNER TO floreant;

--
-- TOC entry 192 (class 1259 OID 345801)
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE coupon_and_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE coupon_and_discount_id_seq OWNER TO floreant;

--
-- TOC entry 6337 (class 0 OID 0)
-- Dependencies: 192
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE coupon_and_discount_id_seq OWNED BY coupon_and_discount.id;


--
-- TOC entry 193 (class 1259 OID 345803)
-- Name: currency; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE currency OWNER TO floreant;

--
-- TOC entry 194 (class 1259 OID 345806)
-- Name: currency_balance; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE currency_balance (
    id integer NOT NULL,
    balance double precision,
    currency_id integer,
    cash_drawer_id integer,
    dpr_id integer
);


ALTER TABLE currency_balance OWNER TO floreant;

--
-- TOC entry 195 (class 1259 OID 345809)
-- Name: currency_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE currency_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE currency_balance_id_seq OWNER TO floreant;

--
-- TOC entry 6338 (class 0 OID 0)
-- Dependencies: 195
-- Name: currency_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_balance_id_seq OWNED BY currency_balance.id;


--
-- TOC entry 196 (class 1259 OID 345811)
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE currency_id_seq OWNER TO floreant;

--
-- TOC entry 6339 (class 0 OID 0)
-- Dependencies: 196
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_id_seq OWNED BY currency.id;


--
-- TOC entry 197 (class 1259 OID 345813)
-- Name: custom_payment; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE custom_payment (
    id integer NOT NULL,
    name character varying(60),
    required_ref_number boolean,
    ref_number_field_name character varying(60)
);


ALTER TABLE custom_payment OWNER TO floreant;

--
-- TOC entry 198 (class 1259 OID 345816)
-- Name: custom_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE custom_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE custom_payment_id_seq OWNER TO floreant;

--
-- TOC entry 6340 (class 0 OID 0)
-- Dependencies: 198
-- Name: custom_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE custom_payment_id_seq OWNED BY custom_payment.id;


--
-- TOC entry 199 (class 1259 OID 345818)
-- Name: customer; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE customer OWNER TO floreant;

--
-- TOC entry 200 (class 1259 OID 345824)
-- Name: customer_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE customer_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customer_auto_id_seq OWNER TO floreant;

--
-- TOC entry 6341 (class 0 OID 0)
-- Dependencies: 200
-- Name: customer_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE customer_auto_id_seq OWNED BY customer.auto_id;


--
-- TOC entry 201 (class 1259 OID 345826)
-- Name: customer_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE customer_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE customer_properties OWNER TO floreant;

--
-- TOC entry 202 (class 1259 OID 345832)
-- Name: daily_folio_counter; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE daily_folio_counter (
    folio_date date NOT NULL,
    branch_key text NOT NULL,
    last_value integer DEFAULT 0 NOT NULL
);


ALTER TABLE daily_folio_counter OWNER TO floreant;

--
-- TOC entry 203 (class 1259 OID 345839)
-- Name: data_update_info; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE data_update_info (
    id integer NOT NULL,
    last_update_time timestamp without time zone
);


ALTER TABLE data_update_info OWNER TO floreant;

--
-- TOC entry 204 (class 1259 OID 345842)
-- Name: data_update_info_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE data_update_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_update_info_id_seq OWNER TO floreant;

--
-- TOC entry 6342 (class 0 OID 0)
-- Dependencies: 204
-- Name: data_update_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE data_update_info_id_seq OWNED BY data_update_info.id;


--
-- TOC entry 205 (class 1259 OID 345844)
-- Name: delivery_address; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_address (
    id integer NOT NULL,
    address character varying(320),
    phone_extension character varying(10),
    room_no character varying(30),
    distance double precision,
    customer_id integer
);


ALTER TABLE delivery_address OWNER TO floreant;

--
-- TOC entry 206 (class 1259 OID 345847)
-- Name: delivery_address_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE delivery_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_address_id_seq OWNER TO floreant;

--
-- TOC entry 6343 (class 0 OID 0)
-- Dependencies: 206
-- Name: delivery_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_address_id_seq OWNED BY delivery_address.id;


--
-- TOC entry 207 (class 1259 OID 345849)
-- Name: delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_charge (
    id integer NOT NULL,
    name character varying(220),
    zip_code character varying(20),
    start_range double precision,
    end_range double precision,
    charge_amount double precision
);


ALTER TABLE delivery_charge OWNER TO floreant;

--
-- TOC entry 208 (class 1259 OID 345852)
-- Name: delivery_charge_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE delivery_charge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_charge_id_seq OWNER TO floreant;

--
-- TOC entry 6344 (class 0 OID 0)
-- Dependencies: 208
-- Name: delivery_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_charge_id_seq OWNED BY delivery_charge.id;


--
-- TOC entry 209 (class 1259 OID 345854)
-- Name: delivery_configuration; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_configuration (
    id integer NOT NULL,
    unit_name character varying(20),
    unit_symbol character varying(8),
    charge_by_zip_code boolean
);


ALTER TABLE delivery_configuration OWNER TO floreant;

--
-- TOC entry 210 (class 1259 OID 345857)
-- Name: delivery_configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE delivery_configuration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_configuration_id_seq OWNER TO floreant;

--
-- TOC entry 6345 (class 0 OID 0)
-- Dependencies: 210
-- Name: delivery_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_configuration_id_seq OWNED BY delivery_configuration.id;


--
-- TOC entry 211 (class 1259 OID 345859)
-- Name: delivery_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_instruction (
    id integer NOT NULL,
    notes character varying(220),
    customer_no integer
);


ALTER TABLE delivery_instruction OWNER TO floreant;

--
-- TOC entry 212 (class 1259 OID 345862)
-- Name: delivery_instruction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE delivery_instruction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delivery_instruction_id_seq OWNER TO floreant;

--
-- TOC entry 6346 (class 0 OID 0)
-- Dependencies: 212
-- Name: delivery_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_instruction_id_seq OWNED BY delivery_instruction.id;


--
-- TOC entry 213 (class 1259 OID 345864)
-- Name: drawer_assigned_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE drawer_assigned_history (
    id integer NOT NULL,
    "time" timestamp without time zone,
    operation character varying(60),
    a_user integer
);


ALTER TABLE drawer_assigned_history OWNER TO floreant;

--
-- TOC entry 214 (class 1259 OID 345867)
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE drawer_assigned_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE drawer_assigned_history_id_seq OWNER TO floreant;

--
-- TOC entry 6347 (class 0 OID 0)
-- Dependencies: 214
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_assigned_history_id_seq OWNED BY drawer_assigned_history.id;


--
-- TOC entry 215 (class 1259 OID 345869)
-- Name: drawer_pull_report; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE drawer_pull_report OWNER TO floreant;

--
-- TOC entry 216 (class 1259 OID 345872)
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE drawer_pull_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE drawer_pull_report_id_seq OWNER TO floreant;

--
-- TOC entry 6348 (class 0 OID 0)
-- Dependencies: 216
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_pull_report_id_seq OWNED BY drawer_pull_report.id;


--
-- TOC entry 217 (class 1259 OID 345874)
-- Name: drawer_pull_report_voidtickets; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE drawer_pull_report_voidtickets (
    dpreport_id integer NOT NULL,
    code integer,
    reason character varying(255),
    hast character varying(255),
    quantity integer,
    amount double precision
);


ALTER TABLE drawer_pull_report_voidtickets OWNER TO floreant;

--
-- TOC entry 218 (class 1259 OID 345880)
-- Name: employee_in_out_history; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE employee_in_out_history OWNER TO floreant;

--
-- TOC entry 219 (class 1259 OID 345883)
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE employee_in_out_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE employee_in_out_history_id_seq OWNER TO floreant;

--
-- TOC entry 6349 (class 0 OID 0)
-- Dependencies: 219
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE employee_in_out_history_id_seq OWNED BY employee_in_out_history.id;


--
-- TOC entry 220 (class 1259 OID 345885)
-- Name: global_config; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE global_config (
    id integer NOT NULL,
    pos_key character varying(60),
    pos_value character varying(220)
);


ALTER TABLE global_config OWNER TO floreant;

--
-- TOC entry 221 (class 1259 OID 345888)
-- Name: global_config_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE global_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE global_config_id_seq OWNER TO floreant;

--
-- TOC entry 6350 (class 0 OID 0)
-- Dependencies: 221
-- Name: global_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE global_config_id_seq OWNED BY global_config.id;


--
-- TOC entry 222 (class 1259 OID 345890)
-- Name: gratuity; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE gratuity OWNER TO floreant;

--
-- TOC entry 223 (class 1259 OID 345893)
-- Name: gratuity_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE gratuity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE gratuity_id_seq OWNER TO floreant;

--
-- TOC entry 6351 (class 0 OID 0)
-- Dependencies: 223
-- Name: gratuity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE gratuity_id_seq OWNED BY gratuity.id;


--
-- TOC entry 224 (class 1259 OID 345895)
-- Name: group_taxes; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE group_taxes (
    group_id character varying(128) NOT NULL,
    elt integer NOT NULL
);


ALTER TABLE group_taxes OWNER TO floreant;

--
-- TOC entry 225 (class 1259 OID 345898)
-- Name: guest_check_print; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE guest_check_print (
    id integer NOT NULL,
    ticket_id integer,
    table_no character varying(255),
    ticket_total double precision,
    print_time timestamp without time zone,
    user_id integer
);


ALTER TABLE guest_check_print OWNER TO floreant;

--
-- TOC entry 226 (class 1259 OID 345901)
-- Name: guest_check_print_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE guest_check_print_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE guest_check_print_id_seq OWNER TO floreant;

--
-- TOC entry 6352 (class 0 OID 0)
-- Dependencies: 226
-- Name: guest_check_print_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE guest_check_print_id_seq OWNED BY guest_check_print.id;


--
-- TOC entry 227 (class 1259 OID 345903)
-- Name: inventory_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_group OWNER TO floreant;

--
-- TOC entry 228 (class 1259 OID 345906)
-- Name: inventory_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_group_id_seq OWNER TO floreant;

--
-- TOC entry 6353 (class 0 OID 0)
-- Dependencies: 228
-- Name: inventory_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_group_id_seq OWNED BY inventory_group.id;


--
-- TOC entry 229 (class 1259 OID 345908)
-- Name: inventory_item; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE inventory_item OWNER TO floreant;

--
-- TOC entry 230 (class 1259 OID 345911)
-- Name: inventory_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_item_id_seq OWNER TO floreant;

--
-- TOC entry 6354 (class 0 OID 0)
-- Dependencies: 230
-- Name: inventory_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_item_id_seq OWNED BY inventory_item.id;


--
-- TOC entry 231 (class 1259 OID 345913)
-- Name: inventory_location; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_location (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    sort_order integer,
    visible boolean,
    warehouse_id integer
);


ALTER TABLE inventory_location OWNER TO floreant;

--
-- TOC entry 232 (class 1259 OID 345916)
-- Name: inventory_location_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_location_id_seq OWNER TO floreant;

--
-- TOC entry 6355 (class 0 OID 0)
-- Dependencies: 232
-- Name: inventory_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_location_id_seq OWNED BY inventory_location.id;


--
-- TOC entry 233 (class 1259 OID 345918)
-- Name: inventory_meta_code; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_meta_code (
    id integer NOT NULL,
    type character varying(255),
    code_text character varying(255),
    code_no integer,
    description character varying(255)
);


ALTER TABLE inventory_meta_code OWNER TO floreant;

--
-- TOC entry 234 (class 1259 OID 345924)
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_meta_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_meta_code_id_seq OWNER TO floreant;

--
-- TOC entry 6356 (class 0 OID 0)
-- Dependencies: 234
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_meta_code_id_seq OWNED BY inventory_meta_code.id;


--
-- TOC entry 235 (class 1259 OID 345926)
-- Name: inventory_transaction; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE inventory_transaction OWNER TO floreant;

--
-- TOC entry 236 (class 1259 OID 345929)
-- Name: inventory_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_transaction_id_seq OWNER TO floreant;

--
-- TOC entry 6357 (class 0 OID 0)
-- Dependencies: 236
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_transaction_id_seq OWNED BY inventory_transaction.id;


--
-- TOC entry 237 (class 1259 OID 345931)
-- Name: inventory_unit; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE inventory_unit OWNER TO floreant;

--
-- TOC entry 238 (class 1259 OID 345937)
-- Name: inventory_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_unit_id_seq OWNER TO floreant;

--
-- TOC entry 6358 (class 0 OID 0)
-- Dependencies: 238
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_unit_id_seq OWNED BY inventory_unit.id;


--
-- TOC entry 239 (class 1259 OID 345939)
-- Name: inventory_vendor; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE inventory_vendor OWNER TO floreant;

--
-- TOC entry 240 (class 1259 OID 345945)
-- Name: inventory_vendor_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_vendor_id_seq OWNER TO floreant;

--
-- TOC entry 6359 (class 0 OID 0)
-- Dependencies: 240
-- Name: inventory_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_vendor_id_seq OWNED BY inventory_vendor.id;


--
-- TOC entry 241 (class 1259 OID 345947)
-- Name: inventory_warehouse; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_warehouse (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_warehouse OWNER TO floreant;

--
-- TOC entry 242 (class 1259 OID 345950)
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE inventory_warehouse_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inventory_warehouse_id_seq OWNER TO floreant;

--
-- TOC entry 6360 (class 0 OID 0)
-- Dependencies: 242
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_warehouse_id_seq OWNED BY inventory_warehouse.id;


--
-- TOC entry 243 (class 1259 OID 345952)
-- Name: item_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE item_order_type (
    menu_item_id integer NOT NULL,
    order_type_id integer NOT NULL
);


ALTER TABLE item_order_type OWNER TO floreant;

--
-- TOC entry 244 (class 1259 OID 345955)
-- Name: kitchen_ticket; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE kitchen_ticket OWNER TO floreant;

--
-- TOC entry 245 (class 1259 OID 345958)
-- Name: terminal; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE terminal OWNER TO floreant;

--
-- TOC entry 246 (class 1259 OID 345964)
-- Name: ticket; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE ticket OWNER TO floreant;

--
-- TOC entry 247 (class 1259 OID 345971)
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
-- TOC entry 248 (class 1259 OID 345976)
-- Name: kds_ready_log; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kds_ready_log (
    ticket_id integer NOT NULL,
    notified_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE kds_ready_log OWNER TO floreant;

--
-- TOC entry 249 (class 1259 OID 345980)
-- Name: kit_ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kit_ticket_table_num (
    kit_ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE kit_ticket_table_num OWNER TO floreant;

--
-- TOC entry 250 (class 1259 OID 345983)
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE kitchen_ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE kitchen_ticket_id_seq OWNER TO floreant;

--
-- TOC entry 6361 (class 0 OID 0)
-- Dependencies: 250
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_id_seq OWNED BY kitchen_ticket.id;


--
-- TOC entry 251 (class 1259 OID 345985)
-- Name: kitchen_ticket_item; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE kitchen_ticket_item OWNER TO floreant;

--
-- TOC entry 252 (class 1259 OID 345991)
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE kitchen_ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE kitchen_ticket_item_id_seq OWNER TO floreant;

--
-- TOC entry 6362 (class 0 OID 0)
-- Dependencies: 252
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_item_id_seq OWNED BY kitchen_ticket_item.id;


--
-- TOC entry 253 (class 1259 OID 345993)
-- Name: menu_category; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE menu_category OWNER TO floreant;

--
-- TOC entry 254 (class 1259 OID 345996)
-- Name: menu_category_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_category_id_seq OWNER TO floreant;

--
-- TOC entry 6363 (class 0 OID 0)
-- Dependencies: 254
-- Name: menu_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_category_id_seq OWNED BY menu_category.id;


--
-- TOC entry 255 (class 1259 OID 345998)
-- Name: menu_group; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE menu_group OWNER TO floreant;

--
-- TOC entry 256 (class 1259 OID 346001)
-- Name: menu_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_group_id_seq OWNER TO floreant;

--
-- TOC entry 6364 (class 0 OID 0)
-- Dependencies: 256
-- Name: menu_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_group_id_seq OWNED BY menu_group.id;


--
-- TOC entry 257 (class 1259 OID 346003)
-- Name: menu_item; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE menu_item OWNER TO floreant;

--
-- TOC entry 258 (class 1259 OID 346009)
-- Name: menu_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_item_id_seq OWNER TO floreant;

--
-- TOC entry 6365 (class 0 OID 0)
-- Dependencies: 258
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_id_seq OWNED BY menu_item.id;


--
-- TOC entry 259 (class 1259 OID 346011)
-- Name: menu_item_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_properties (
    menu_item_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_item_properties OWNER TO floreant;

--
-- TOC entry 260 (class 1259 OID 346014)
-- Name: menu_item_size; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE menu_item_size OWNER TO floreant;

--
-- TOC entry 261 (class 1259 OID 346017)
-- Name: menu_item_size_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_item_size_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_item_size_id_seq OWNER TO floreant;

--
-- TOC entry 6366 (class 0 OID 0)
-- Dependencies: 261
-- Name: menu_item_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_size_id_seq OWNED BY menu_item_size.id;


--
-- TOC entry 262 (class 1259 OID 346019)
-- Name: menu_item_terminal_ref; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_terminal_ref (
    menu_item_id integer NOT NULL,
    terminal_id integer NOT NULL
);


ALTER TABLE menu_item_terminal_ref OWNER TO floreant;

--
-- TOC entry 263 (class 1259 OID 346022)
-- Name: menu_modifier; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE menu_modifier OWNER TO floreant;

--
-- TOC entry 264 (class 1259 OID 346025)
-- Name: menu_modifier_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_modifier_group (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    enabled boolean,
    exclusived boolean,
    required boolean
);


ALTER TABLE menu_modifier_group OWNER TO floreant;

--
-- TOC entry 265 (class 1259 OID 346028)
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_modifier_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_modifier_group_id_seq OWNER TO floreant;

--
-- TOC entry 6367 (class 0 OID 0)
-- Dependencies: 265
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_group_id_seq OWNED BY menu_modifier_group.id;


--
-- TOC entry 266 (class 1259 OID 346030)
-- Name: menu_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menu_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menu_modifier_id_seq OWNER TO floreant;

--
-- TOC entry 6368 (class 0 OID 0)
-- Dependencies: 266
-- Name: menu_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_id_seq OWNED BY menu_modifier.id;


--
-- TOC entry 267 (class 1259 OID 346032)
-- Name: menu_modifier_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_modifier_properties (
    menu_modifier_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_modifier_properties OWNER TO floreant;

--
-- TOC entry 268 (class 1259 OID 346035)
-- Name: menucategory_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menucategory_discount (
    discount_id integer NOT NULL,
    menucategory_id integer NOT NULL
);


ALTER TABLE menucategory_discount OWNER TO floreant;

--
-- TOC entry 269 (class 1259 OID 346038)
-- Name: menugroup_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menugroup_discount (
    discount_id integer NOT NULL,
    menugroup_id integer NOT NULL
);


ALTER TABLE menugroup_discount OWNER TO floreant;

--
-- TOC entry 270 (class 1259 OID 346041)
-- Name: menuitem_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_discount (
    discount_id integer NOT NULL,
    menuitem_id integer NOT NULL
);


ALTER TABLE menuitem_discount OWNER TO floreant;

--
-- TOC entry 271 (class 1259 OID 346044)
-- Name: menuitem_modifiergroup; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_modifiergroup (
    id integer NOT NULL,
    min_quantity integer,
    max_quantity integer,
    sort_order integer,
    modifier_group integer,
    menuitem_modifiergroup_id integer
);


ALTER TABLE menuitem_modifiergroup OWNER TO floreant;

--
-- TOC entry 272 (class 1259 OID 346047)
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menuitem_modifiergroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menuitem_modifiergroup_id_seq OWNER TO floreant;

--
-- TOC entry 6369 (class 0 OID 0)
-- Dependencies: 272
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_modifiergroup_id_seq OWNED BY menuitem_modifiergroup.id;


--
-- TOC entry 273 (class 1259 OID 346049)
-- Name: menuitem_pizzapirce; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_pizzapirce (
    menu_item_id integer NOT NULL,
    pizza_price_id integer NOT NULL
);


ALTER TABLE menuitem_pizzapirce OWNER TO floreant;

--
-- TOC entry 274 (class 1259 OID 346052)
-- Name: menuitem_shift; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_shift (
    id integer NOT NULL,
    shift_price double precision,
    shift_id integer,
    menuitem_id integer
);


ALTER TABLE menuitem_shift OWNER TO floreant;

--
-- TOC entry 275 (class 1259 OID 346055)
-- Name: menuitem_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE menuitem_shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menuitem_shift_id_seq OWNER TO floreant;

--
-- TOC entry 6370 (class 0 OID 0)
-- Dependencies: 275
-- Name: menuitem_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_shift_id_seq OWNED BY menuitem_shift.id;


--
-- TOC entry 276 (class 1259 OID 346057)
-- Name: menumodifier_pizzamodifierprice; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menumodifier_pizzamodifierprice (
    menumodifier_id integer NOT NULL,
    pizzamodifierprice_id integer NOT NULL
);


ALTER TABLE menumodifier_pizzamodifierprice OWNER TO floreant;

--
-- TOC entry 277 (class 1259 OID 346060)
-- Name: modifier_multiplier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE modifier_multiplier_price (
    id integer NOT NULL,
    price double precision,
    multiplier_id character varying(20),
    menumodifier_id integer,
    pizza_modifier_price_id integer
);


ALTER TABLE modifier_multiplier_price OWNER TO floreant;

--
-- TOC entry 278 (class 1259 OID 346063)
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE modifier_multiplier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modifier_multiplier_price_id_seq OWNER TO floreant;

--
-- TOC entry 6371 (class 0 OID 0)
-- Dependencies: 278
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE modifier_multiplier_price_id_seq OWNED BY modifier_multiplier_price.id;


--
-- TOC entry 279 (class 1259 OID 346065)
-- Name: multiplier; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE multiplier OWNER TO floreant;

--
-- TOC entry 280 (class 1259 OID 346068)
-- Name: online_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE online_order (
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


ALTER TABLE online_order OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 346074)
-- Name: order_type; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE order_type OWNER TO floreant;

--
-- TOC entry 282 (class 1259 OID 346080)
-- Name: order_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE order_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE order_type_id_seq OWNER TO floreant;

--
-- TOC entry 6372 (class 0 OID 0)
-- Dependencies: 282
-- Name: order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE order_type_id_seq OWNED BY order_type.id;


--
-- TOC entry 283 (class 1259 OID 346082)
-- Name: packaging_unit; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE packaging_unit (
    id integer NOT NULL,
    name character varying(30),
    short_name character varying(10),
    factor double precision,
    baseunit boolean,
    dimension character varying(30)
);


ALTER TABLE packaging_unit OWNER TO floreant;

--
-- TOC entry 284 (class 1259 OID 346085)
-- Name: packaging_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE packaging_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE packaging_unit_id_seq OWNER TO floreant;

--
-- TOC entry 6373 (class 0 OID 0)
-- Dependencies: 284
-- Name: packaging_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE packaging_unit_id_seq OWNED BY packaging_unit.id;


--
-- TOC entry 285 (class 1259 OID 346087)
-- Name: payout_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_reasons (
    id integer NOT NULL,
    reason character varying(255)
);


ALTER TABLE payout_reasons OWNER TO floreant;

--
-- TOC entry 286 (class 1259 OID 346090)
-- Name: payout_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE payout_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE payout_reasons_id_seq OWNER TO floreant;

--
-- TOC entry 6374 (class 0 OID 0)
-- Dependencies: 286
-- Name: payout_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_reasons_id_seq OWNED BY payout_reasons.id;


--
-- TOC entry 287 (class 1259 OID 346092)
-- Name: payout_recepients; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_recepients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE payout_recepients OWNER TO floreant;

--
-- TOC entry 288 (class 1259 OID 346095)
-- Name: payout_recepients_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE payout_recepients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE payout_recepients_id_seq OWNER TO floreant;

--
-- TOC entry 6375 (class 0 OID 0)
-- Dependencies: 288
-- Name: payout_recepients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_recepients_id_seq OWNED BY payout_recepients.id;


--
-- TOC entry 289 (class 1259 OID 346097)
-- Name: pizza_crust; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE pizza_crust (
    id integer NOT NULL,
    name character varying(60),
    translated_name character varying(60),
    description character varying(120),
    sort_order integer,
    default_crust boolean
);


ALTER TABLE pizza_crust OWNER TO floreant;

--
-- TOC entry 290 (class 1259 OID 346100)
-- Name: pizza_crust_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE pizza_crust_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_crust_id_seq OWNER TO floreant;

--
-- TOC entry 6376 (class 0 OID 0)
-- Dependencies: 290
-- Name: pizza_crust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_crust_id_seq OWNED BY pizza_crust.id;


--
-- TOC entry 291 (class 1259 OID 346102)
-- Name: pizza_modifier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE pizza_modifier_price (
    id integer NOT NULL,
    item_size integer
);


ALTER TABLE pizza_modifier_price OWNER TO floreant;

--
-- TOC entry 292 (class 1259 OID 346105)
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE pizza_modifier_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_modifier_price_id_seq OWNER TO floreant;

--
-- TOC entry 6377 (class 0 OID 0)
-- Dependencies: 292
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_modifier_price_id_seq OWNED BY pizza_modifier_price.id;


--
-- TOC entry 293 (class 1259 OID 346107)
-- Name: pizza_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE pizza_price (
    id integer NOT NULL,
    price double precision,
    menu_item_size integer,
    crust integer,
    order_type integer
);


ALTER TABLE pizza_price OWNER TO floreant;

--
-- TOC entry 294 (class 1259 OID 346110)
-- Name: pizza_price_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE pizza_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pizza_price_id_seq OWNER TO floreant;

--
-- TOC entry 6378 (class 0 OID 0)
-- Dependencies: 294
-- Name: pizza_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_price_id_seq OWNED BY pizza_price.id;


--
-- TOC entry 295 (class 1259 OID 346112)
-- Name: printer_configuration; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE printer_configuration OWNER TO floreant;

--
-- TOC entry 296 (class 1259 OID 346118)
-- Name: printer_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    is_default boolean
);


ALTER TABLE printer_group OWNER TO floreant;

--
-- TOC entry 297 (class 1259 OID 346121)
-- Name: printer_group_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE printer_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE printer_group_id_seq OWNER TO floreant;

--
-- TOC entry 6379 (class 0 OID 0)
-- Dependencies: 297
-- Name: printer_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE printer_group_id_seq OWNED BY printer_group.id;


--
-- TOC entry 298 (class 1259 OID 346123)
-- Name: printer_group_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group_printers (
    printer_id integer NOT NULL,
    printer_name character varying(255)
);


ALTER TABLE printer_group_printers OWNER TO floreant;

--
-- TOC entry 299 (class 1259 OID 346126)
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE purchase_order (
    id integer NOT NULL,
    order_id character varying(30),
    name character varying(30)
);


ALTER TABLE purchase_order OWNER TO floreant;

--
-- TOC entry 300 (class 1259 OID 346129)
-- Name: purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE purchase_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE purchase_order_id_seq OWNER TO floreant;

--
-- TOC entry 6380 (class 0 OID 0)
-- Dependencies: 300
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE purchase_order_id_seq OWNED BY purchase_order.id;


--
-- TOC entry 301 (class 1259 OID 346131)
-- Name: recepie; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE recepie (
    id integer NOT NULL,
    menu_item integer
);


ALTER TABLE recepie OWNER TO floreant;

--
-- TOC entry 302 (class 1259 OID 346134)
-- Name: recepie_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE recepie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepie_id_seq OWNER TO floreant;

--
-- TOC entry 6381 (class 0 OID 0)
-- Dependencies: 302
-- Name: recepie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_id_seq OWNED BY recepie.id;


--
-- TOC entry 303 (class 1259 OID 346136)
-- Name: recepie_item; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE recepie_item (
    id integer NOT NULL,
    percentage double precision,
    inventory_deductable boolean,
    inventory_item integer,
    recepie_id integer
);


ALTER TABLE recepie_item OWNER TO floreant;

--
-- TOC entry 304 (class 1259 OID 346139)
-- Name: recepie_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE recepie_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE recepie_item_id_seq OWNER TO floreant;

--
-- TOC entry 6382 (class 0 OID 0)
-- Dependencies: 304
-- Name: recepie_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_item_id_seq OWNED BY recepie_item.id;


--
-- TOC entry 305 (class 1259 OID 346141)
-- Name: restaurant; Type: TABLE; Schema: public; Owner: floreant
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
    allow_modifier_max_exceed boolean,
    uuid character varying(128)
);


ALTER TABLE restaurant OWNER TO floreant;

--
-- TOC entry 306 (class 1259 OID 346147)
-- Name: restaurant_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE restaurant_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE restaurant_properties OWNER TO floreant;

--
-- TOC entry 307 (class 1259 OID 346153)
-- Name: shift; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shift (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    shift_len bigint
);


ALTER TABLE shift OWNER TO floreant;

--
-- TOC entry 308 (class 1259 OID 346156)
-- Name: shift_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shift_id_seq OWNER TO floreant;

--
-- TOC entry 6383 (class 0 OID 0)
-- Dependencies: 308
-- Name: shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shift_id_seq OWNED BY shift.id;


--
-- TOC entry 309 (class 1259 OID 346158)
-- Name: shop_floor; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_floor (
    id integer NOT NULL,
    name character varying(60),
    occupied boolean,
    image oid
);


ALTER TABLE shop_floor OWNER TO floreant;

--
-- TOC entry 310 (class 1259 OID 346161)
-- Name: shop_floor_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE shop_floor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_floor_id_seq OWNER TO floreant;

--
-- TOC entry 6384 (class 0 OID 0)
-- Dependencies: 310
-- Name: shop_floor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_id_seq OWNED BY shop_floor.id;


--
-- TOC entry 311 (class 1259 OID 346163)
-- Name: shop_floor_template; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_floor_template (
    id integer NOT NULL,
    name character varying(60),
    default_floor boolean,
    main boolean,
    floor_id integer
);


ALTER TABLE shop_floor_template OWNER TO floreant;

--
-- TOC entry 312 (class 1259 OID 346166)
-- Name: shop_floor_template_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE shop_floor_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_floor_template_id_seq OWNER TO floreant;

--
-- TOC entry 6385 (class 0 OID 0)
-- Dependencies: 312
-- Name: shop_floor_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_template_id_seq OWNED BY shop_floor_template.id;


--
-- TOC entry 313 (class 1259 OID 346168)
-- Name: shop_floor_template_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_floor_template_properties (
    id integer NOT NULL,
    property_value character varying(60),
    property_name character varying(255) NOT NULL
);


ALTER TABLE shop_floor_template_properties OWNER TO floreant;

--
-- TOC entry 314 (class 1259 OID 346171)
-- Name: shop_table; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE shop_table OWNER TO floreant;

--
-- TOC entry 315 (class 1259 OID 346174)
-- Name: shop_table_status; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_status (
    id integer NOT NULL,
    table_status integer
);


ALTER TABLE shop_table_status OWNER TO floreant;

--
-- TOC entry 316 (class 1259 OID 346177)
-- Name: shop_table_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_type (
    id integer NOT NULL,
    description character varying(120),
    name character varying(40)
);


ALTER TABLE shop_table_type OWNER TO floreant;

--
-- TOC entry 317 (class 1259 OID 346180)
-- Name: shop_table_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE shop_table_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE shop_table_type_id_seq OWNER TO floreant;

--
-- TOC entry 6386 (class 0 OID 0)
-- Dependencies: 317
-- Name: shop_table_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_table_type_id_seq OWNED BY shop_table_type.id;


--
-- TOC entry 318 (class 1259 OID 346182)
-- Name: table_booking_info; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE table_booking_info OWNER TO floreant;

--
-- TOC entry 319 (class 1259 OID 346185)
-- Name: table_booking_info_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE table_booking_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE table_booking_info_id_seq OWNER TO floreant;

--
-- TOC entry 6387 (class 0 OID 0)
-- Dependencies: 319
-- Name: table_booking_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE table_booking_info_id_seq OWNED BY table_booking_info.id;


--
-- TOC entry 320 (class 1259 OID 346187)
-- Name: table_booking_mapping; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_booking_mapping (
    booking_id integer NOT NULL,
    table_id integer NOT NULL
);


ALTER TABLE table_booking_mapping OWNER TO floreant;

--
-- TOC entry 321 (class 1259 OID 346190)
-- Name: table_ticket_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_ticket_num (
    shop_table_status_id integer NOT NULL,
    ticket_id integer,
    user_id integer,
    user_name character varying(30)
);


ALTER TABLE table_ticket_num OWNER TO floreant;

--
-- TOC entry 322 (class 1259 OID 346193)
-- Name: table_type_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_type_relation (
    table_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE table_type_relation OWNER TO floreant;

--
-- TOC entry 323 (class 1259 OID 346196)
-- Name: tax; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    rate double precision
);


ALTER TABLE tax OWNER TO floreant;

--
-- TOC entry 324 (class 1259 OID 346199)
-- Name: tax_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax_group (
    id character varying(128) NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE tax_group OWNER TO floreant;

--
-- TOC entry 325 (class 1259 OID 346202)
-- Name: tax_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE tax_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tax_id_seq OWNER TO floreant;

--
-- TOC entry 6388 (class 0 OID 0)
-- Dependencies: 325
-- Name: tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE tax_id_seq OWNED BY tax.id;


--
-- TOC entry 326 (class 1259 OID 346204)
-- Name: terminal_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE terminal_printers (
    id integer NOT NULL,
    terminal_id integer,
    printer_name character varying(60),
    virtual_printer_id integer
);


ALTER TABLE terminal_printers OWNER TO floreant;

--
-- TOC entry 327 (class 1259 OID 346207)
-- Name: terminal_printers_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE terminal_printers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE terminal_printers_id_seq OWNER TO floreant;

--
-- TOC entry 6389 (class 0 OID 0)
-- Dependencies: 327
-- Name: terminal_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE terminal_printers_id_seq OWNED BY terminal_printers.id;


--
-- TOC entry 328 (class 1259 OID 346209)
-- Name: terminal_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE terminal_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE terminal_properties OWNER TO floreant;

--
-- TOC entry 329 (class 1259 OID 346215)
-- Name: ticket_discount; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE ticket_discount OWNER TO floreant;

--
-- TOC entry 330 (class 1259 OID 346218)
-- Name: ticket_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE ticket_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_discount_id_seq OWNER TO floreant;

--
-- TOC entry 6390 (class 0 OID 0)
-- Dependencies: 330
-- Name: ticket_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_discount_id_seq OWNED BY ticket_discount.id;


--
-- TOC entry 331 (class 1259 OID 346220)
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
-- TOC entry 332 (class 1259 OID 346225)
-- Name: ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE ticket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_id_seq OWNER TO floreant;

--
-- TOC entry 6391 (class 0 OID 0)
-- Dependencies: 332
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_id_seq OWNED BY ticket.id;


--
-- TOC entry 333 (class 1259 OID 346227)
-- Name: ticket_item; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE ticket_item OWNER TO floreant;

--
-- TOC entry 334 (class 1259 OID 346233)
-- Name: ticket_item_addon_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_addon_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_addon_relation OWNER TO floreant;

--
-- TOC entry 335 (class 1259 OID 346236)
-- Name: ticket_item_cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_cooking_instruction (
    ticket_item_id integer NOT NULL,
    description character varying(60),
    printedtokitchen boolean,
    item_order integer NOT NULL
);


ALTER TABLE ticket_item_cooking_instruction OWNER TO floreant;

--
-- TOC entry 336 (class 1259 OID 346239)
-- Name: ticket_item_discount; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE ticket_item_discount OWNER TO floreant;

--
-- TOC entry 337 (class 1259 OID 346242)
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE ticket_item_discount_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_discount_id_seq OWNER TO floreant;

--
-- TOC entry 6392 (class 0 OID 0)
-- Dependencies: 337
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_discount_id_seq OWNED BY ticket_item_discount.id;


--
-- TOC entry 338 (class 1259 OID 346244)
-- Name: ticket_item_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE ticket_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_id_seq OWNER TO floreant;

--
-- TOC entry 6393 (class 0 OID 0)
-- Dependencies: 338
-- Name: ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_id_seq OWNED BY ticket_item.id;


--
-- TOC entry 339 (class 1259 OID 346246)
-- Name: ticket_item_modifier; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE ticket_item_modifier OWNER TO floreant;

--
-- TOC entry 340 (class 1259 OID 346249)
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE ticket_item_modifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ticket_item_modifier_id_seq OWNER TO floreant;

--
-- TOC entry 6394 (class 0 OID 0)
-- Dependencies: 340
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_modifier_id_seq OWNED BY ticket_item_modifier.id;


--
-- TOC entry 341 (class 1259 OID 346251)
-- Name: ticket_item_modifier_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_modifier_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_modifier_relation OWNER TO floreant;

--
-- TOC entry 342 (class 1259 OID 346254)
-- Name: ticket_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE ticket_properties OWNER TO floreant;

--
-- TOC entry 343 (class 1259 OID 346260)
-- Name: ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_table_num (
    ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE ticket_table_num OWNER TO floreant;

--
-- TOC entry 344 (class 1259 OID 346263)
-- Name: transaction_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE transaction_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE transaction_properties OWNER TO floreant;

--
-- TOC entry 345 (class 1259 OID 346269)
-- Name: transactions; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE transactions OWNER TO floreant;

--
-- TOC entry 346 (class 1259 OID 346275)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE transactions_id_seq OWNER TO floreant;

--
-- TOC entry 6395 (class 0 OID 0)
-- Dependencies: 346
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- TOC entry 347 (class 1259 OID 346277)
-- Name: user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_permission (
    name character varying(40) NOT NULL
);


ALTER TABLE user_permission OWNER TO floreant;

--
-- TOC entry 348 (class 1259 OID 346280)
-- Name: user_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_type (
    id integer NOT NULL,
    p_name character varying(60)
);


ALTER TABLE user_type OWNER TO floreant;

--
-- TOC entry 349 (class 1259 OID 346283)
-- Name: user_type_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE user_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_type_id_seq OWNER TO floreant;

--
-- TOC entry 6396 (class 0 OID 0)
-- Dependencies: 349
-- Name: user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE user_type_id_seq OWNED BY user_type.id;


--
-- TOC entry 350 (class 1259 OID 346285)
-- Name: user_user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_user_permission (
    permissionid integer NOT NULL,
    elt character varying(40) NOT NULL
);


ALTER TABLE user_user_permission OWNER TO floreant;

--
-- TOC entry 351 (class 1259 OID 346288)
-- Name: users; Type: TABLE; Schema: public; Owner: floreant
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


ALTER TABLE users OWNER TO floreant;

--
-- TOC entry 352 (class 1259 OID 346291)
-- Name: users_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE users_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_auto_id_seq OWNER TO floreant;

--
-- TOC entry 6397 (class 0 OID 0)
-- Dependencies: 352
-- Name: users_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE users_auto_id_seq OWNED BY users.auto_id;


--
-- TOC entry 353 (class 1259 OID 346293)
-- Name: virtual_printer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE virtual_printer (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    type integer,
    priority integer,
    enabled boolean
);


ALTER TABLE virtual_printer OWNER TO floreant;

--
-- TOC entry 354 (class 1259 OID 346296)
-- Name: virtual_printer_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE virtual_printer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE virtual_printer_id_seq OWNER TO floreant;

--
-- TOC entry 6398 (class 0 OID 0)
-- Dependencies: 354
-- Name: virtual_printer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE virtual_printer_id_seq OWNED BY virtual_printer.id;


--
-- TOC entry 355 (class 1259 OID 346298)
-- Name: virtualprinter_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE virtualprinter_order_type (
    printer_id integer NOT NULL,
    order_type character varying(255)
);


ALTER TABLE virtualprinter_order_type OWNER TO floreant;

--
-- TOC entry 356 (class 1259 OID 346301)
-- Name: void_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE void_reasons (
    id integer NOT NULL,
    reason_text character varying(255)
);


ALTER TABLE void_reasons OWNER TO floreant;

--
-- TOC entry 357 (class 1259 OID 346304)
-- Name: void_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE void_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE void_reasons_id_seq OWNER TO floreant;

--
-- TOC entry 6399 (class 0 OID 0)
-- Dependencies: 357
-- Name: void_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE void_reasons_id_seq OWNED BY void_reasons.id;


--
-- TOC entry 358 (class 1259 OID 346306)
-- Name: vw_daily_diagnostics_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_daily_diagnostics_summary AS
 SELECT f_daily_diagnostics_summary_on.source_view,
    f_daily_diagnostics_summary_on.severity,
    f_daily_diagnostics_summary_on.rows
   FROM f_daily_diagnostics_summary_on(('now'::text)::date) f_daily_diagnostics_summary_on(source_view, severity, rows);


ALTER TABLE vw_daily_diagnostics_summary OWNER TO postgres;

--
-- TOC entry 359 (class 1259 OID 346310)
-- Name: vw_diag_discount_header_vs_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_discount_header_vs_lines AS
 WITH line_disc AS (
         SELECT ti.ticket_id,
            round((sum(COALESCE(ti.discount, (0)::double precision)))::numeric, 2) AS sum_line_disc
           FROM ticket_item ti
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
   FROM (ticket t
     LEFT JOIN line_disc ld ON ((ld.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (abs(round((((COALESCE(ld.sum_line_disc, (0)::numeric))::double precision - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2)) > 0.01));


ALTER TABLE vw_diag_discount_header_vs_lines OWNER TO postgres;

--
-- TOC entry 360 (class 1259 OID 346315)
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
-- TOC entry 361 (class 1259 OID 346319)
-- Name: vw_diag_folio_date_inconsistency; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_folio_date_inconsistency AS
 SELECT t.id AS ticket_id,
    t.folio_date,
    (t.closing_date)::date AS closed_date,
    (t.create_date)::date AS created_date,
    'FOLIO_DATE_MISMATCH'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM ticket t
  WHERE ((t.paid = true) AND (t.voided = false) AND (t.folio_date IS DISTINCT FROM (t.closing_date)::date) AND (t.folio_date IS DISTINCT FROM (t.create_date)::date));


ALTER TABLE vw_diag_folio_date_inconsistency OWNER TO postgres;

--
-- TOC entry 362 (class 1259 OID 346323)
-- Name: vw_diag_high_discounts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_high_discounts AS
 SELECT COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    t.id AS ticket_id,
    round((COALESCE(t.total_price, (0)::double precision))::numeric, 2) AS total_bruto,
    round((COALESCE(t.total_discount, (0)::double precision))::numeric, 2) AS total_descuento,
    round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS total_neto,
    'HIGH_DISCOUNT'::text AS error_code,
    'WARN'::text AS severity
   FROM ticket t
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(t.total_discount, (0)::double precision) >= (COALESCE(t.total_price, (0)::double precision) * (0.30)::double precision)));


ALTER TABLE vw_diag_high_discounts OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 346328)
-- Name: vw_diag_neto_vs_cobros; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_neto_vs_cobros AS
 WITH tx AS (
         SELECT transactions.ticket_id,
            round((sum(
                CASE
                    WHEN ((transactions.voided = false) AND (upper((transactions.transaction_type)::text) = 'CREDIT'::text) AND ((transactions.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(transactions.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_sum
           FROM transactions
          GROUP BY transactions.ticket_id
        ), base AS (
         SELECT t.id AS ticket_id,
            COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
            t.branch_key,
            round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS net_ticket,
            COALESCE(tx.paid_sum, (0)::numeric) AS paid_sum,
            round((((COALESCE(tx.paid_sum, (0)::numeric))::double precision - (COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))))::numeric, 2) AS diff
           FROM (ticket t
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


ALTER TABLE vw_diag_neto_vs_cobros OWNER TO postgres;

--
-- TOC entry 364 (class 1259 OID 346333)
-- Name: vw_diag_orphans_tickets; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_orphans_tickets AS
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    'ORPHAN_TICKET'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (ticket t
     LEFT JOIN transactions tx ON (((tx.ticket_id = t.id) AND (tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text))))
  WHERE ((t.paid = true) AND (t.voided = false) AND (tx.ticket_id IS NULL));


ALTER TABLE vw_diag_orphans_tickets OWNER TO postgres;

--
-- TOC entry 365 (class 1259 OID 346338)
-- Name: vw_diag_orphans_tx; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_orphans_tx AS
 SELECT tx.id,
    tx.ticket_id,
    round((COALESCE(tx.amount, (0)::double precision))::numeric, 2) AS amount,
    'ORPHAN_TX'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (transactions tx
     LEFT JOIN ticket t ON ((t.id = tx.ticket_id)))
  WHERE ((t.id IS NULL) AND (tx.voided = false));


ALTER TABLE vw_diag_orphans_tx OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 346343)
-- Name: vw_diag_pagos_egresos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_pagos_egresos AS
 SELECT transactions.terminal_id,
    round((sum(transactions.amount))::numeric, 2) AS egresos,
    'NON_SALES_CASHFLOW'::text AS error_code,
    'WARN'::text AS severity
   FROM transactions
  WHERE (((transactions.payment_type)::text = ANY (ARRAY[('REFUND'::character varying)::text, ('PAY_OUT'::character varying)::text, ('CASH_DROP'::character varying)::text])) AND (transactions.voided = false))
  GROUP BY transactions.terminal_id;


ALTER TABLE vw_diag_pagos_egresos OWNER TO postgres;

--
-- TOC entry 367 (class 1259 OID 346348)
-- Name: vw_diag_paid_but_no_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_paid_but_no_payments AS
 SELECT t.id AS ticket_id,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    round(((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS neto,
    'PAID_WITHOUT_TX'::text AS error_code,
    'CRITICAL'::text AS severity
   FROM (ticket t
     LEFT JOIN transactions tx ON (((tx.ticket_id = t.id) AND (tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text))))
  WHERE ((t.paid = true) AND (t.voided = false) AND (tx.ticket_id IS NULL) AND ((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision)) > (0.01)::double precision));


ALTER TABLE vw_diag_paid_but_no_payments OWNER TO postgres;

--
-- TOC entry 368 (class 1259 OID 346353)
-- Name: vw_diag_service_charge_vs_paid; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_service_charge_vs_paid AS
 WITH svc_tx AS (
         SELECT transactions.ticket_id,
            sum(
                CASE
                    WHEN ((selemti.fn_normalizar_forma_pago((transactions.payment_type)::text, (transactions.transaction_type)::text, (transactions.payment_sub_type)::text, (transactions.custom_payment_name)::text) = 'CARGO_SERVICIO'::text) AND (transactions.voided = false)) THEN COALESCE(transactions.amount, (0)::double precision)
                    ELSE (0)::double precision
                END) AS paid_svc
           FROM transactions
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
   FROM (ticket t
     LEFT JOIN svc_tx s ON ((s.ticket_id = t.id)))
  WHERE (abs((COALESCE(s.paid_svc, (0)::double precision) - COALESCE(t.service_charge, (0)::double precision))) > (0.01)::double precision);


ALTER TABLE vw_diag_service_charge_vs_paid OWNER TO postgres;

--
-- TOC entry 369 (class 1259 OID 346358)
-- Name: vw_diag_unnormalized_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_diag_unnormalized_payments AS
 SELECT DISTINCT (COALESCE(transactions.payment_type, ''::character varying))::text AS payment_type,
    (COALESCE(transactions.transaction_type, ''::character varying))::text AS transaction_type,
    (COALESCE(transactions.payment_sub_type, ''::character varying))::text AS payment_sub_type,
    (COALESCE(transactions.custom_payment_name, ''::character varying))::text AS custom_payment_name,
    'UNNORMALIZED_PAYMENT'::text AS error_code,
    'WARN'::text AS severity
   FROM transactions
  WHERE ((transactions.voided = false) AND (selemti.fn_normalizar_forma_pago((transactions.payment_type)::text, (transactions.transaction_type)::text, (transactions.payment_sub_type)::text, (transactions.custom_payment_name)::text) IS NULL));


ALTER TABLE vw_diag_unnormalized_payments OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 346363)
-- Name: vw_discounts_daily; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_discounts_daily AS
 SELECT t.folio_date,
    t.branch_key,
    term.location AS sucursal,
    term.name AS terminal,
    count(*) AS tickets_con_desc,
    round((sum(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS descuento_total,
    round((avg(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS descuento_prom_ticket
   FROM (ticket t
     JOIN terminal term ON ((term.id = t.terminal_id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(t.total_discount, (0)::double precision) > (0)::double precision))
  GROUP BY t.folio_date, t.branch_key, term.location, term.name;


ALTER TABLE vw_discounts_daily OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 346368)
-- Name: vw_discounts_detail_line; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_discounts_detail_line AS
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
   FROM ((ticket t
     JOIN terminal term ON ((term.id = t.terminal_id)))
     JOIN ticket_item ti ON ((ti.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND (COALESCE(ti.discount, (0)::double precision) > (0)::double precision));


ALTER TABLE vw_discounts_detail_line OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 346373)
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
-- TOC entry 373 (class 1259 OID 346377)
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
-- TOC entry 374 (class 1259 OID 346381)
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
-- TOC entry 375 (class 1259 OID 346385)
-- Name: vw_ticket_base; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_ticket_base AS
 SELECT t.id AS ticket_id,
    t.terminal_id,
    t.branch_key,
    COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    (COALESCE(t.total_price, (0)::double precision))::numeric(12,2) AS total_price,
    (GREATEST((0)::double precision, LEAST(COALESCE(t.total_discount, ( SELECT sum(COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision))) AS sum
           FROM ticket_item ti
          WHERE (ti.ticket_id = t.id)), (0)::double precision), COALESCE(t.total_price, (0)::double precision))))::numeric(12,2) AS total_discount,
    (COALESCE(( SELECT sum(g.amount) AS sum
           FROM gratuity g
          WHERE ((g.ticket_id = t.id) AND (COALESCE(g.refunded, false) = false) AND (COALESCE(g.paid, true) = true))), (0)::double precision))::numeric(12,2) AS tip_amount,
    (COALESCE(t.service_charge, (0)::double precision))::numeric(12,2) AS service_charges
   FROM ticket t
  WHERE ((t.paid = true) AND (t.voided = false));


ALTER TABLE vw_ticket_base OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 346390)
-- Name: vw_report_balance_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_balance_detail AS
 WITH paid AS (
         SELECT t.id AS ticket_id,
            selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text) AS pay_norm,
            round((sum(
                CASE
                    WHEN ((tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_amount
           FROM (ticket t
             LEFT JOIN transactions tx ON ((tx.ticket_id = t.id)))
          GROUP BY t.id, (selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text))
        )
 SELECT b.folio_date,
    b.branch_key,
    p.pay_norm AS payment,
    round(sum(COALESCE(p.paid_amount, (0)::numeric)), 2) AS monto
   FROM (vw_ticket_base b
     LEFT JOIN paid p ON ((p.ticket_id = b.ticket_id)))
  GROUP BY b.folio_date, b.branch_key, p.pay_norm
  ORDER BY b.folio_date, b.branch_key, (round(sum(COALESCE(p.paid_amount, (0)::numeric)), 2)) DESC;


ALTER TABLE vw_report_balance_detail OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 346395)
-- Name: vw_report_journal_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_journal_lines AS
 SELECT b.folio_date,
    b.branch_key,
    b.ticket_id,
    ti.id AS ticket_item_id,
    (ti.item_name)::text AS item_name,
    (COALESCE(ti.item_quantity, (0)::double precision))::numeric(12,2) AS qty,
    (COALESCE(ti.total_price, (0)::double precision))::numeric(12,2) AS line_total,
    (COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision)))::numeric(12,2) AS line_discount
   FROM (vw_ticket_base b
     JOIN ticket_item ti ON ((ti.ticket_id = b.ticket_id)));


ALTER TABLE vw_report_journal_lines OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 346400)
-- Name: vw_report_journal_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_journal_payments AS
 SELECT COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
    t.branch_key,
    t.id AS ticket_id,
    selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text) AS pay_norm,
    round((sum(
        CASE
            WHEN ((tx.voided = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
            ELSE (0)::double precision
        END))::numeric, 2) AS paid_amount
   FROM (ticket t
     LEFT JOIN transactions tx ON ((tx.ticket_id = t.id)))
  GROUP BY COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date), t.branch_key, t.id, (selemti.fn_normalizar_forma_pago((tx.payment_type)::text, (tx.transaction_type)::text, (tx.payment_sub_type)::text, (tx.custom_payment_name)::text));


ALTER TABLE vw_report_journal_payments OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 346405)
-- Name: vw_report_menu_usage; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_menu_usage AS
 SELECT b.folio_date,
    b.branch_key,
    (ti.item_name)::text AS item_name,
    (sum(COALESCE(ti.item_quantity, (0)::double precision)))::numeric(12,2) AS qty,
    round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2) AS neto
   FROM (vw_ticket_base b
     JOIN ticket_item ti ON ((ti.ticket_id = b.ticket_id)))
  GROUP BY b.folio_date, b.branch_key, (ti.item_name)::text;


ALTER TABLE vw_report_menu_usage OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 346410)
-- Name: vw_report_sales_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_sales_detail AS
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
   FROM (vw_ticket_base b
     JOIN ticket_item ti ON ((ti.ticket_id = b.ticket_id)));


ALTER TABLE vw_report_sales_detail OWNER TO postgres;

--
-- TOC entry 381 (class 1259 OID 346415)
-- Name: vw_report_sales_exceptions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_sales_exceptions AS
 WITH base AS (
         SELECT b.folio_date,
            b.branch_key,
            b.ticket_id,
            ((b.total_price - b.total_discount))::numeric(12,2) AS neto
           FROM vw_ticket_base b
        ), paid AS (
         SELECT t.id AS ticket_id,
            round((sum(
                CASE
                    WHEN ((COALESCE(tx.voided, false) = false) AND (upper((tx.transaction_type)::text) = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text]))) THEN COALESCE(tx.amount, (0)::double precision)
                    ELSE (0)::double precision
                END))::numeric, 2) AS paid_amount
           FROM (ticket t
             LEFT JOIN transactions tx ON ((tx.ticket_id = t.id)))
          GROUP BY t.id
        ), tot_disc AS (
         SELECT b.ticket_id,
            b.total_discount
           FROM vw_ticket_base b
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


ALTER TABLE vw_report_sales_exceptions OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 346420)
-- Name: vw_report_sales_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_report_sales_summary AS
 WITH valid AS (
         SELECT b.folio_date,
            COALESCE(upper(btrim(b.branch_key)), 'SIN_SUCURSAL'::text) AS branch_key,
            count(DISTINCT b.ticket_id) AS tickets,
            (sum(b.total_price))::numeric(14,2) AS bruto,
            (sum(b.total_discount))::numeric(14,2) AS descuento,
            (sum(b.tip_amount))::numeric(14,2) AS propina,
            (sum(b.service_charges))::numeric(14,2) AS cargo_servicio
           FROM vw_ticket_base b
          GROUP BY b.folio_date, COALESCE(upper(btrim(b.branch_key)), 'SIN_SUCURSAL'::text)
        ), ticket_all AS (
         SELECT t.id,
            COALESCE(t.folio_date, (t.closing_date)::date, (t.create_date)::date) AS folio_date,
            COALESCE(upper(btrim(t.branch_key)), 'SIN_SUCURSAL'::text) AS branch_key,
            (COALESCE(t.total_price, (0)::double precision))::numeric(14,2) AS total_price,
            (GREATEST((0)::double precision, LEAST(COALESCE(t.total_discount, ( SELECT sum(COALESCE(((NULLIF((to_jsonb(ti.*) ->> 'discount_amount'::text), ''::text))::numeric)::double precision, COALESCE(ti.discount, (0)::double precision))) AS sum
                   FROM ticket_item ti
                  WHERE (ti.ticket_id = t.id)), (0)::double precision), COALESCE(t.total_price, (0)::double precision))))::numeric(14,2) AS total_discount,
            COALESCE(t.paid, false) AS paid,
            COALESCE(t.voided, false) AS voided
           FROM ticket t
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
             LEFT JOIN transactions tx ON ((tx.ticket_id = ta.id)))
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


ALTER TABLE vw_report_sales_summary OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 346425)
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
-- TOC entry 384 (class 1259 OID 346429)
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
-- TOC entry 385 (class 1259 OID 346433)
-- Name: vw_sales_exceptions_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sales_exceptions_today AS
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
           FROM (ticket t
             JOIN terminal term ON ((term.id = t.terminal_id)))
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


ALTER TABLE vw_sales_exceptions_today OWNER TO postgres;

--
-- TOC entry 386 (class 1259 OID 346438)
-- Name: vw_sales_kpis; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sales_kpis AS
 SELECT t.folio_date,
    t.branch_key,
    count(DISTINCT t.id) AS total_tickets,
    round(((sum((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))) / (NULLIF(count(DISTINCT t.id), 0))::double precision))::numeric, 2) AS avg_ticket,
    round(((sum(COALESCE(ti.item_quantity, (0)::double precision)) / (NULLIF(count(DISTINCT t.id), 0))::double precision))::numeric, 2) AS items_per_ticket,
    round((sum((COALESCE(t.total_price, (0)::double precision) - COALESCE(t.total_discount, (0)::double precision))))::numeric, 2) AS total_neto,
    round((sum(COALESCE(t.total_discount, (0)::double precision)))::numeric, 2) AS total_descuentos,
    round((((sum(COALESCE(t.total_discount, (0)::double precision)) / NULLIF(sum(COALESCE(t.total_price, (0)::double precision)), (0)::double precision)) * (100)::double precision))::numeric, 2) AS descuento_percentage
   FROM (ticket t
     LEFT JOIN ticket_item ti ON ((ti.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false))
  GROUP BY t.folio_date, t.branch_key;


ALTER TABLE vw_sales_kpis OWNER TO postgres;

--
-- TOC entry 387 (class 1259 OID 346443)
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
-- TOC entry 388 (class 1259 OID 346447)
-- Name: vw_top_items_today; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_top_items_today AS
 SELECT t.folio_date,
    t.branch_key,
    ti.item_id,
    ti.item_name,
    round((sum(COALESCE(ti.item_quantity, (0)::double precision)))::numeric, 2) AS qty,
    round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2) AS neto
   FROM (ticket_item ti
     JOIN ticket t ON ((t.id = ti.ticket_id)))
  WHERE ((t.folio_date = ('now'::text)::date) AND (t.voided = false))
  GROUP BY t.folio_date, t.branch_key, ti.item_id, ti.item_name
  ORDER BY (round((sum((COALESCE(ti.total_price, (0)::double precision) - COALESCE(ti.discount, (0)::double precision))))::numeric, 2)) DESC;


ALTER TABLE vw_top_items_today OWNER TO postgres;

--
-- TOC entry 389 (class 1259 OID 346452)
-- Name: zip_code_vs_delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE zip_code_vs_delivery_charge (
    auto_id integer NOT NULL,
    zip_code character varying(10) NOT NULL,
    delivery_charge double precision NOT NULL
);


ALTER TABLE zip_code_vs_delivery_charge OWNER TO floreant;

--
-- TOC entry 390 (class 1259 OID 346455)
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: floreant
--

CREATE SEQUENCE zip_code_vs_delivery_charge_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE zip_code_vs_delivery_charge_auto_id_seq OWNER TO floreant;

--
-- TOC entry 6400 (class 0 OID 0)
-- Dependencies: 390
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE zip_code_vs_delivery_charge_auto_id_seq OWNED BY zip_code_vs_delivery_charge.auto_id;


SET search_path = selemti, pg_catalog;

--
-- TOC entry 391 (class 1259 OID 346457)
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
-- TOC entry 392 (class 1259 OID 346466)
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
-- TOC entry 6401 (class 0 OID 0)
-- Dependencies: 392
-- Name: alert_events_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_events_id_seq OWNED BY alert_events.id;


--
-- TOC entry 393 (class 1259 OID 346468)
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
-- TOC entry 394 (class 1259 OID 346477)
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
-- TOC entry 6402 (class 0 OID 0)
-- Dependencies: 394
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_rules_id_seq OWNED BY alert_rules.id;


--
-- TOC entry 395 (class 1259 OID 346479)
-- Name: alertas_cortes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE alertas_cortes (
    id bigint NOT NULL,
    postcorte_id bigint,
    sesion_id bigint,
    tipo character varying(50) NOT NULL,
    destinatario_id integer,
    leida boolean DEFAULT false,
    creada_en timestamp with time zone DEFAULT now(),
    leida_en timestamp with time zone
);


ALTER TABLE alertas_cortes OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 346484)
-- Name: alertas_cortes_id_seq; Type: SEQUENCE; Schema: selemti; Owner: postgres
--

CREATE SEQUENCE alertas_cortes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alertas_cortes_id_seq OWNER TO postgres;

--
-- TOC entry 6403 (class 0 OID 0)
-- Dependencies: 396
-- Name: alertas_cortes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alertas_cortes_id_seq OWNED BY alertas_cortes.id;


--
-- TOC entry 397 (class 1259 OID 346486)
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
-- TOC entry 398 (class 1259 OID 346493)
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
-- TOC entry 399 (class 1259 OID 346500)
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
-- TOC entry 6404 (class 0 OID 0)
-- Dependencies: 399
-- Name: TABLE audit_log_global; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE audit_log_global IS 'Log global de auditorÃ­a - Creada en Phase 5';


--
-- TOC entry 400 (class 1259 OID 346508)
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
-- TOC entry 6405 (class 0 OID 0)
-- Dependencies: 400
-- Name: audit_log_global_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE audit_log_global_id_seq OWNED BY audit_log_global.id;


--
-- TOC entry 401 (class 1259 OID 346510)
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
-- TOC entry 6406 (class 0 OID 0)
-- Dependencies: 401
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;


--
-- TOC entry 402 (class 1259 OID 346512)
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
-- TOC entry 403 (class 1259 OID 346519)
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
-- TOC entry 6407 (class 0 OID 0)
-- Dependencies: 403
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE auditoria_id_seq OWNED BY auditoria.id;


--
-- TOC entry 699 (class 1259 OID 350456)
-- Name: backup_tickets_cierre_masivo_20251112_112653; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE backup_tickets_cierre_masivo_20251112_112653 (
    id integer,
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
    backup_timestamp timestamp with time zone,
    backup_user_id integer,
    backup_user_name character varying(255)
);


ALTER TABLE backup_tickets_cierre_masivo_20251112_112653 OWNER TO postgres;

--
-- TOC entry 700 (class 1259 OID 350462)
-- Name: backup_tickets_cierre_masivo_20251112_121131; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE backup_tickets_cierre_masivo_20251112_121131 (
    id integer,
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
    backup_timestamp timestamp with time zone,
    backup_user_id integer,
    backup_user_name character varying(255)
);


ALTER TABLE backup_tickets_cierre_masivo_20251112_121131 OWNER TO postgres;

--
-- TOC entry 701 (class 1259 OID 350468)
-- Name: backup_tickets_cierre_masivo_20251112_121211; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE backup_tickets_cierre_masivo_20251112_121211 (
    id integer,
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
    backup_timestamp timestamp with time zone,
    backup_user_id integer,
    backup_user_name character varying(255)
);


ALTER TABLE backup_tickets_cierre_masivo_20251112_121211 OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 346521)
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
-- TOC entry 405 (class 1259 OID 346527)
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
-- TOC entry 6408 (class 0 OID 0)
-- Dependencies: 405
-- Name: bodega_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE bodega_id_seq OWNED BY bodega.id;


--
-- TOC entry 406 (class 1259 OID 346529)
-- Name: cache; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 346535)
-- Name: cache_locks; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache_locks OWNER TO postgres;

--
-- TOC entry 408 (class 1259 OID 346541)
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
-- TOC entry 409 (class 1259 OID 346548)
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
-- TOC entry 410 (class 1259 OID 346555)
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
-- TOC entry 6409 (class 0 OID 0)
-- Dependencies: 410
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_adj_id_seq OWNED BY caja_fondo_adj.id;


--
-- TOC entry 411 (class 1259 OID 346557)
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
-- TOC entry 412 (class 1259 OID 346564)
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
-- TOC entry 6410 (class 0 OID 0)
-- Dependencies: 412
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_arqueo_id_seq OWNED BY caja_fondo_arqueo.id;


--
-- TOC entry 413 (class 1259 OID 346566)
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
-- TOC entry 6411 (class 0 OID 0)
-- Dependencies: 413
-- Name: caja_fondo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_id_seq OWNED BY caja_fondo.id;


--
-- TOC entry 414 (class 1259 OID 346568)
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
-- TOC entry 415 (class 1259 OID 346580)
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
-- TOC entry 6412 (class 0 OID 0)
-- Dependencies: 415
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_mov_id_seq OWNED BY caja_fondo_mov.id;


--
-- TOC entry 416 (class 1259 OID 346582)
-- Name: caja_fondo_usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_usuario (
    fondo_id bigint NOT NULL,
    user_id integer NOT NULL,
    rol character varying(16) NOT NULL
);


ALTER TABLE caja_fondo_usuario OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 346585)
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
-- TOC entry 418 (class 1259 OID 346591)
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
-- TOC entry 6413 (class 0 OID 0)
-- Dependencies: 418
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_arqueos_id_seq OWNED BY cash_fund_arqueos.id;


--
-- TOC entry 419 (class 1259 OID 346593)
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
-- TOC entry 420 (class 1259 OID 346600)
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
-- TOC entry 6414 (class 0 OID 0)
-- Dependencies: 420
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movement_audit_log_id_seq OWNED BY cash_fund_movement_audit_log.id;


--
-- TOC entry 421 (class 1259 OID 346602)
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
-- TOC entry 422 (class 1259 OID 346614)
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
-- TOC entry 6415 (class 0 OID 0)
-- Dependencies: 422
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movements_id_seq OWNED BY cash_fund_movements.id;


--
-- TOC entry 423 (class 1259 OID 346616)
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
-- TOC entry 6416 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN cash_funds.descripcion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN cash_funds.descripcion IS 'Descripción o nombre del fondo para identificación rápida';


--
-- TOC entry 424 (class 1259 OID 346625)
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
-- TOC entry 6417 (class 0 OID 0)
-- Dependencies: 424
-- Name: cash_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_funds_id_seq OWNED BY cash_funds.id;


--
-- TOC entry 425 (class 1259 OID 346627)
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
-- TOC entry 6418 (class 0 OID 0)
-- Dependencies: 425
-- Name: TABLE cat_almacenes; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE cat_almacenes IS 'CatÃ¡logo de almacenes - Consolidada en Phase 2.2';


--
-- TOC entry 426 (class 1259 OID 346631)
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
-- TOC entry 6419 (class 0 OID 0)
-- Dependencies: 426
-- Name: cat_almacenes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_almacenes_id_seq OWNED BY cat_almacenes.id;


--
-- TOC entry 427 (class 1259 OID 346633)
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
-- TOC entry 428 (class 1259 OID 346640)
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
-- TOC entry 6420 (class 0 OID 0)
-- Dependencies: 428
-- Name: cat_proveedores_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_proveedores_id_seq OWNED BY cat_proveedores.id;


--
-- TOC entry 429 (class 1259 OID 346642)
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
-- TOC entry 6421 (class 0 OID 0)
-- Dependencies: 429
-- Name: TABLE cat_sucursales; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE cat_sucursales IS 'CatÃ¡logo de sucursales - Consolidada en Phase 2.2';


--
-- TOC entry 430 (class 1259 OID 346646)
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
-- TOC entry 6422 (class 0 OID 0)
-- Dependencies: 430
-- Name: cat_sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_sucursales_id_seq OWNED BY cat_sucursales.id;


--
-- TOC entry 431 (class 1259 OID 346648)
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
-- TOC entry 6423 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN cat_unidades.categoria; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN cat_unidades.categoria IS 'Categoría: BASE, COCINA, COMPRA, PORCION';


--
-- TOC entry 432 (class 1259 OID 346652)
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
-- TOC entry 6424 (class 0 OID 0)
-- Dependencies: 432
-- Name: cat_unidades_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;


--
-- TOC entry 433 (class 1259 OID 346654)
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
-- TOC entry 434 (class 1259 OID 346662)
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
-- TOC entry 6425 (class 0 OID 0)
-- Dependencies: 434
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_uom_conversion_id_seq OWNED BY cat_uom_conversion.id;


--
-- TOC entry 435 (class 1259 OID 346664)
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
-- TOC entry 6426 (class 0 OID 0)
-- Dependencies: 435
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 6427 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 6428 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN conciliacion.conciliado_por; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.conciliado_por IS 'Usuario que realizÃ³ la conciliaciÃ³n (supervisor/gerente).';


--
-- TOC entry 436 (class 1259 OID 346673)
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
-- TOC entry 6429 (class 0 OID 0)
-- Dependencies: 436
-- Name: conciliacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conciliacion_id_seq OWNED BY conciliacion.id;


--
-- TOC entry 437 (class 1259 OID 346675)
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
-- TOC entry 6430 (class 0 OID 0)
-- Dependencies: 437
-- Name: VIEW conversiones_unidad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW conversiones_unidad IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy conversiones_unidad';


--
-- TOC entry 438 (class 1259 OID 346679)
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
-- TOC entry 439 (class 1259 OID 346690)
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
-- TOC entry 6431 (class 0 OID 0)
-- Dependencies: 439
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad_legacy.id;


--
-- TOC entry 440 (class 1259 OID 346692)
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
-- TOC entry 441 (class 1259 OID 346698)
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
-- TOC entry 6432 (class 0 OID 0)
-- Dependencies: 441
-- Name: cost_layer_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cost_layer_id_seq OWNED BY cost_layer.id;


--
-- TOC entry 442 (class 1259 OID 346700)
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
-- TOC entry 443 (class 1259 OID 346707)
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
-- TOC entry 6433 (class 0 OID 0)
-- Dependencies: 443
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


--
-- TOC entry 444 (class 1259 OID 346709)
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
-- TOC entry 445 (class 1259 OID 346718)
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
-- TOC entry 6434 (class 0 OID 0)
-- Dependencies: 445
-- Name: formas_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE formas_pago_id_seq OWNED BY formas_pago.id;


--
-- TOC entry 446 (class 1259 OID 346720)
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
-- TOC entry 447 (class 1259 OID 346731)
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
-- TOC entry 6435 (class 0 OID 0)
-- Dependencies: 447
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_insumo_id_seq OWNED BY hist_cost_insumo.id;


--
-- TOC entry 448 (class 1259 OID 346733)
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
-- TOC entry 449 (class 1259 OID 346742)
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
-- TOC entry 6436 (class 0 OID 0)
-- Dependencies: 449
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_receta_id_seq OWNED BY hist_cost_receta.id;


--
-- TOC entry 450 (class 1259 OID 346744)
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
-- TOC entry 451 (class 1259 OID 346759)
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
-- TOC entry 6437 (class 0 OID 0)
-- Dependencies: 451
-- Name: historial_costos_item_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_item_id_seq OWNED BY historial_costos_item.id;


--
-- TOC entry 452 (class 1259 OID 346761)
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
-- TOC entry 453 (class 1259 OID 346770)
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
-- TOC entry 6438 (class 0 OID 0)
-- Dependencies: 453
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_receta_id_seq OWNED BY historial_costos_receta.id;


--
-- TOC entry 454 (class 1259 OID 346772)
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
-- TOC entry 6439 (class 0 OID 0)
-- Dependencies: 454
-- Name: COLUMN insumo.codigo_alterno; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN insumo.codigo_alterno IS 'Código alternativo para compatibilidad';


--
-- TOC entry 455 (class 1259 OID 346781)
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
-- TOC entry 6440 (class 0 OID 0)
-- Dependencies: 455
-- Name: insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_id_seq OWNED BY insumo.id;


--
-- TOC entry 456 (class 1259 OID 346783)
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
-- TOC entry 457 (class 1259 OID 346791)
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
-- TOC entry 6441 (class 0 OID 0)
-- Dependencies: 457
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


--
-- TOC entry 458 (class 1259 OID 346793)
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
-- TOC entry 459 (class 1259 OID 346805)
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
-- TOC entry 6442 (class 0 OID 0)
-- Dependencies: 459
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_proveedor_presentacion_id_seq OWNED BY insumo_proveedor_presentacion.id;


--
-- TOC entry 460 (class 1259 OID 346807)
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
-- TOC entry 6443 (class 0 OID 0)
-- Dependencies: 460
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- TOC entry 6444 (class 0 OID 0)
-- Dependencies: 460
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- TOC entry 6445 (class 0 OID 0)
-- Dependencies: 460
-- Name: COLUMN inv_consumo_pos.fecha_proceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.fecha_proceso IS 'Momento del procesamiento';


--
-- TOC entry 6446 (class 0 OID 0)
-- Dependencies: 460
-- Name: COLUMN inv_consumo_pos.revertido; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.revertido IS 'Consumo revertido/anulado';


--
-- TOC entry 461 (class 1259 OID 346815)
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
-- TOC entry 462 (class 1259 OID 346822)
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
-- TOC entry 6447 (class 0 OID 0)
-- Dependencies: 462
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_det_id_seq OWNED BY inv_consumo_pos_det.id;


--
-- TOC entry 463 (class 1259 OID 346824)
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
-- TOC entry 6448 (class 0 OID 0)
-- Dependencies: 463
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_id_seq OWNED BY inv_consumo_pos.id;


--
-- TOC entry 464 (class 1259 OID 346826)
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
-- TOC entry 465 (class 1259 OID 346833)
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
-- TOC entry 6449 (class 0 OID 0)
-- Dependencies: 465
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_log_id_seq OWNED BY inv_consumo_pos_log.id;


--
-- TOC entry 466 (class 1259 OID 346835)
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
-- TOC entry 467 (class 1259 OID 346842)
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
-- TOC entry 6450 (class 0 OID 0)
-- Dependencies: 467
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_stock_policy_id_seq OWNED BY inv_stock_policy.id;


--
-- TOC entry 468 (class 1259 OID 346844)
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
-- TOC entry 6451 (class 0 OID 0)
-- Dependencies: 468
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario - Consolidada en Phase 2.3';


--
-- TOC entry 6452 (class 0 OID 0)
-- Dependencies: 468
-- Name: COLUMN inventory_batch.unit_cost; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inventory_batch.unit_cost IS 'Costo unitario del lote para costeo por batch.';


--
-- TOC entry 469 (class 1259 OID 346858)
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
-- TOC entry 6453 (class 0 OID 0)
-- Dependencies: 469
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


--
-- TOC entry 470 (class 1259 OID 346860)
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
-- TOC entry 471 (class 1259 OID 346869)
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
-- TOC entry 6454 (class 0 OID 0)
-- Dependencies: 471
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_count_lines_id_seq OWNED BY inventory_count_lines.id;


--
-- TOC entry 472 (class 1259 OID 346871)
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
-- TOC entry 473 (class 1259 OID 346880)
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
-- TOC entry 6455 (class 0 OID 0)
-- Dependencies: 473
-- Name: inventory_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_counts_id_seq OWNED BY inventory_counts.id;


--
-- TOC entry 474 (class 1259 OID 346882)
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
-- TOC entry 475 (class 1259 OID 346891)
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
-- TOC entry 476 (class 1259 OID 346898)
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
-- TOC entry 6456 (class 0 OID 0)
-- Dependencies: 476
-- Name: inventory_wastes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_wastes_id_seq OWNED BY inventory_wastes.id;


--
-- TOC entry 477 (class 1259 OID 346900)
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
-- TOC entry 478 (class 1259 OID 346907)
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
-- TOC entry 6457 (class 0 OID 0)
-- Dependencies: 478
-- Name: item_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_categories_id_seq OWNED BY item_categories.id;


--
-- TOC entry 479 (class 1259 OID 346909)
-- Name: item_category_counters; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_category_counters (
    category_id bigint NOT NULL,
    last_val bigint DEFAULT 0 NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE item_category_counters OWNER TO postgres;

--
-- TOC entry 480 (class 1259 OID 346913)
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
-- TOC entry 481 (class 1259 OID 346925)
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
-- TOC entry 482 (class 1259 OID 346935)
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
-- TOC entry 6458 (class 0 OID 0)
-- Dependencies: 482
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_vendor_prices_id_seq OWNED BY item_vendor_prices.id;


--
-- TOC entry 483 (class 1259 OID 346937)
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
-- TOC entry 6459 (class 0 OID 0)
-- Dependencies: 483
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'CatÃ¡logo de items/insumos - Consolidada en Phase 2.3';


--
-- TOC entry 6460 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.unidad_medida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_medida_id IS 'Unidad BASE de inventario (KG, L, PZ) - FK a cat_unidades';


--
-- TOC entry 6461 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.factor_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_conversion IS 'Factor adicional de conversión si se requiere (legacy, en desuso)';


--
-- TOC entry 6462 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.unidad_compra_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_compra_id IS 'Unidad de COMPRA del proveedor (CAJA, PAQUETE, COSTAL, etc) - FK a cat_unidades';


--
-- TOC entry 6463 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.factor_compra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_compra IS 'Factor de conversión: 1 unidad_compra = X unidades_base. Ej: 1 CAJA = 12 L';


--
-- TOC entry 6464 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.unidad_salida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_salida_id IS 'Unidad de SALIDA para recetas (ML, TAZA, PORCION, etc) - FK a cat_unidades';


--
-- TOC entry 6465 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- TOC entry 6466 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- TOC entry 6467 (class 0 OID 0)
-- Dependencies: 483
-- Name: COLUMN items.es_empaque_to_go; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_empaque_to_go IS 'Marks items as to-go packaging.';


--
-- TOC entry 484 (class 1259 OID 346960)
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
-- TOC entry 485 (class 1259 OID 346966)
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
-- TOC entry 486 (class 1259 OID 346976)
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
-- TOC entry 6468 (class 0 OID 0)
-- Dependencies: 486
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE job_recalc_queue_id_seq OWNED BY job_recalc_queue.id;


--
-- TOC entry 487 (class 1259 OID 346978)
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
-- TOC entry 488 (class 1259 OID 346984)
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
-- TOC entry 6469 (class 0 OID 0)
-- Dependencies: 488
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- TOC entry 489 (class 1259 OID 346986)
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
-- TOC entry 490 (class 1259 OID 346994)
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
-- TOC entry 6470 (class 0 OID 0)
-- Dependencies: 490
-- Name: labor_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE labor_roles_id_seq OWNED BY labor_roles.id;


--
-- TOC entry 491 (class 1259 OID 346996)
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
-- TOC entry 492 (class 1259 OID 347004)
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
-- TOC entry 6471 (class 0 OID 0)
-- Dependencies: 492
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE lote_id_seq OWNED BY lote.id;


--
-- TOC entry 493 (class 1259 OID 347006)
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
-- TOC entry 494 (class 1259 OID 347020)
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
-- TOC entry 6472 (class 0 OID 0)
-- Dependencies: 494
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_engineering_snapshots_id_seq OWNED BY menu_engineering_snapshots.id;


--
-- TOC entry 495 (class 1259 OID 347022)
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
-- TOC entry 496 (class 1259 OID 347029)
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
-- TOC entry 6473 (class 0 OID 0)
-- Dependencies: 496
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_item_sync_map_id_seq OWNED BY menu_item_sync_map.id;


--
-- TOC entry 497 (class 1259 OID 347031)
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
-- TOC entry 498 (class 1259 OID 347038)
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
-- TOC entry 6474 (class 0 OID 0)
-- Dependencies: 498
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_items_id_seq OWNED BY menu_items.id;


--
-- TOC entry 499 (class 1259 OID 347040)
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
-- TOC entry 500 (class 1259 OID 347049)
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
-- TOC entry 6475 (class 0 OID 0)
-- Dependencies: 500
-- Name: merma_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE merma_id_seq OWNED BY merma.id;


--
-- TOC entry 501 (class 1259 OID 347051)
-- Name: migrations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

--
-- TOC entry 502 (class 1259 OID 347054)
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
-- TOC entry 6476 (class 0 OID 0)
-- Dependencies: 502
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


--
-- TOC entry 503 (class 1259 OID 347056)
-- Name: model_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_permissions OWNER TO postgres;

--
-- TOC entry 504 (class 1259 OID 347059)
-- Name: model_has_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_roles OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 347062)
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
-- TOC entry 506 (class 1259 OID 347068)
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
-- TOC entry 6477 (class 0 OID 0)
-- Dependencies: 506
-- Name: modificadores_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE modificadores_pos_id_seq OWNED BY modificadores_pos.id;


--
-- TOC entry 507 (class 1259 OID 347070)
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
-- TOC entry 6478 (class 0 OID 0)
-- Dependencies: 507
-- Name: TABLE mov_inv; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE mov_inv IS 'Kardex completo de movimientos de inventario.';


--
-- TOC entry 508 (class 1259 OID 347077)
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
-- TOC entry 6479 (class 0 OID 0)
-- Dependencies: 508
-- Name: mov_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE mov_inv_id_seq OWNED BY mov_inv.id;


--
-- TOC entry 509 (class 1259 OID 347079)
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
-- TOC entry 510 (class 1259 OID 347087)
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
-- TOC entry 6480 (class 0 OID 0)
-- Dependencies: 510
-- Name: TABLE receta_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_cab IS 'CatÃ¡logo de recetas - Consolidada en Phase 2.4';


--
-- TOC entry 511 (class 1259 OID 347101)
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
-- TOC entry 6481 (class 0 OID 0)
-- Dependencies: 511
-- Name: TABLE receta_det; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_det IS 'Detalle de ingredientes de recetas - Consolidada en Phase 2.4';


--
-- TOC entry 512 (class 1259 OID 347112)
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
-- TOC entry 6482 (class 0 OID 0)
-- Dependencies: 512
-- Name: TABLE receta_version; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_version IS 'Control de versiones de recetas.';


--
-- TOC entry 513 (class 1259 OID 347121)
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
-- TOC entry 514 (class 1259 OID 347126)
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
-- TOC entry 515 (class 1259 OID 347136)
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
-- TOC entry 6483 (class 0 OID 0)
-- Dependencies: 515
-- Name: op_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_cab_id_seq OWNED BY op_cab.id;


--
-- TOC entry 516 (class 1259 OID 347138)
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
-- TOC entry 517 (class 1259 OID 347146)
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
-- TOC entry 6484 (class 0 OID 0)
-- Dependencies: 517
-- Name: op_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_insumo_id_seq OWNED BY op_insumo.id;


--
-- TOC entry 518 (class 1259 OID 347148)
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
-- TOC entry 6485 (class 0 OID 0)
-- Dependencies: 518
-- Name: TABLE op_produccion_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE op_produccion_cab IS 'Cabecera de Ã³rdenes de producciÃ³n.';


--
-- TOC entry 519 (class 1259 OID 347156)
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
-- TOC entry 6486 (class 0 OID 0)
-- Dependencies: 519
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_produccion_cab_id_seq OWNED BY op_produccion_cab.id;


--
-- TOC entry 520 (class 1259 OID 347158)
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
-- TOC entry 521 (class 1259 OID 347165)
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
-- TOC entry 522 (class 1259 OID 347174)
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
-- TOC entry 6487 (class 0 OID 0)
-- Dependencies: 522
-- Name: overhead_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE overhead_definitions_id_seq OWNED BY overhead_definitions.id;


--
-- TOC entry 523 (class 1259 OID 347176)
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
-- TOC entry 524 (class 1259 OID 347187)
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
-- TOC entry 6488 (class 0 OID 0)
-- Dependencies: 524
-- Name: param_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE param_sucursal_id_seq OWNED BY param_sucursal.id;


--
-- TOC entry 525 (class 1259 OID 347189)
-- Name: password_reset_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE password_reset_tokens OWNER TO postgres;

--
-- TOC entry 526 (class 1259 OID 347195)
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
-- TOC entry 527 (class 1259 OID 347204)
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
-- TOC entry 6489 (class 0 OID 0)
-- Dependencies: 527
-- Name: perdida_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE perdida_log_id_seq OWNED BY perdida_log.id;


--
-- TOC entry 528 (class 1259 OID 347206)
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
-- TOC entry 529 (class 1259 OID 347212)
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
-- TOC entry 6490 (class 0 OID 0)
-- Dependencies: 529
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- TOC entry 530 (class 1259 OID 347214)
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
-- TOC entry 531 (class 1259 OID 347220)
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
-- TOC entry 6491 (class 0 OID 0)
-- Dependencies: 531
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE personal_access_tokens_id_seq OWNED BY personal_access_tokens.id;


--
-- TOC entry 532 (class 1259 OID 347222)
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
-- TOC entry 533 (class 1259 OID 347232)
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
-- TOC entry 6492 (class 0 OID 0)
-- Dependencies: 533
-- Name: TABLE pos_modifiers_map; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_modifiers_map IS 'Mapa de modificadores POS → impacto en receta/costo/consumo.';


--
-- TOC entry 534 (class 1259 OID 347244)
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
-- TOC entry 6493 (class 0 OID 0)
-- Dependencies: 534
-- Name: TABLE pos_reprocess_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reprocess_log IS 'Log de auditoría de reprocesos de consumo POS histórico';


--
-- TOC entry 535 (class 1259 OID 347253)
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
-- TOC entry 6494 (class 0 OID 0)
-- Dependencies: 535
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reprocess_log_id_seq OWNED BY pos_reprocess_log.id;


--
-- TOC entry 536 (class 1259 OID 347255)
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
-- TOC entry 6495 (class 0 OID 0)
-- Dependencies: 536
-- Name: TABLE pos_reverse_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reverse_log IS 'Log de auditoría de reversas de consumo POS';


--
-- TOC entry 537 (class 1259 OID 347264)
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
-- TOC entry 6496 (class 0 OID 0)
-- Dependencies: 537
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reverse_log_id_seq OWNED BY pos_reverse_log.id;


--
-- TOC entry 538 (class 1259 OID 347266)
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
-- TOC entry 539 (class 1259 OID 347276)
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
-- TOC entry 6497 (class 0 OID 0)
-- Dependencies: 539
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_batches_id_seq OWNED BY pos_sync_batches.id;


--
-- TOC entry 540 (class 1259 OID 347278)
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
-- TOC entry 541 (class 1259 OID 347285)
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
-- TOC entry 6498 (class 0 OID 0)
-- Dependencies: 541
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_logs_id_seq OWNED BY pos_sync_logs.id;


--
-- TOC entry 542 (class 1259 OID 347287)
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


ALTER TABLE postcorte OWNER TO floreant;

--
-- TOC entry 6499 (class 0 OID 0)
-- Dependencies: 542
-- Name: COLUMN postcorte.validado; Type: COMMENT; Schema: selemti; Owner: floreant
--

COMMENT ON COLUMN postcorte.validado IS 'TRUE cuando el supervisor valida/cierra el postcorte';


--
-- TOC entry 543 (class 1259 OID 347312)
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
-- TOC entry 6500 (class 0 OID 0)
-- Dependencies: 543
-- Name: postcorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE postcorte_id_seq OWNED BY postcorte.id;


--
-- TOC entry 544 (class 1259 OID 347314)
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
-- TOC entry 545 (class 1259 OID 347325)
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
-- TOC entry 546 (class 1259 OID 347329)
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
-- TOC entry 6501 (class 0 OID 0)
-- Dependencies: 546
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_efectivo_id_seq OWNED BY precorte_efectivo.id;


--
-- TOC entry 547 (class 1259 OID 347331)
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
-- TOC entry 6502 (class 0 OID 0)
-- Dependencies: 547
-- Name: precorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_id_seq OWNED BY precorte.id;


--
-- TOC entry 548 (class 1259 OID 347333)
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
-- TOC entry 549 (class 1259 OID 347341)
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
-- TOC entry 6503 (class 0 OID 0)
-- Dependencies: 549
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_otros_id_seq OWNED BY precorte_otros.id;


--
-- TOC entry 550 (class 1259 OID 347343)
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
-- TOC entry 551 (class 1259 OID 347348)
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
-- TOC entry 6504 (class 0 OID 0)
-- Dependencies: 551
-- Name: prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_cab_id_seq OWNED BY prod_cab.id;


--
-- TOC entry 552 (class 1259 OID 347350)
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
-- TOC entry 553 (class 1259 OID 347354)
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
-- TOC entry 6505 (class 0 OID 0)
-- Dependencies: 553
-- Name: prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_det_id_seq OWNED BY prod_det.id;


--
-- TOC entry 554 (class 1259 OID 347356)
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
-- TOC entry 555 (class 1259 OID 347362)
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
-- TOC entry 6506 (class 0 OID 0)
-- Dependencies: 555
-- Name: production_order_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_inputs_id_seq OWNED BY production_order_inputs.id;


--
-- TOC entry 556 (class 1259 OID 347364)
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
-- TOC entry 557 (class 1259 OID 347370)
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
-- TOC entry 6507 (class 0 OID 0)
-- Dependencies: 557
-- Name: production_order_outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_outputs_id_seq OWNED BY production_order_outputs.id;


--
-- TOC entry 558 (class 1259 OID 347372)
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
-- TOC entry 559 (class 1259 OID 347382)
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
-- TOC entry 6508 (class 0 OID 0)
-- Dependencies: 559
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_orders_id_seq OWNED BY production_orders.id;


--
-- TOC entry 560 (class 1259 OID 347384)
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
-- TOC entry 561 (class 1259 OID 347391)
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
-- TOC entry 562 (class 1259 OID 347397)
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
-- TOC entry 6509 (class 0 OID 0)
-- Dependencies: 562
-- Name: purchase_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_documents_id_seq OWNED BY purchase_documents.id;


--
-- TOC entry 563 (class 1259 OID 347399)
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
-- TOC entry 564 (class 1259 OID 347407)
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
-- TOC entry 6510 (class 0 OID 0)
-- Dependencies: 564
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_order_lines_id_seq OWNED BY purchase_order_lines.id;


--
-- TOC entry 565 (class 1259 OID 347409)
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
-- TOC entry 566 (class 1259 OID 347420)
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
-- TOC entry 6511 (class 0 OID 0)
-- Dependencies: 566
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_orders_id_seq OWNED BY purchase_orders.id;


--
-- TOC entry 567 (class 1259 OID 347422)
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
-- TOC entry 568 (class 1259 OID 347429)
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
-- TOC entry 6512 (class 0 OID 0)
-- Dependencies: 568
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_request_lines_id_seq OWNED BY purchase_request_lines.id;


--
-- TOC entry 569 (class 1259 OID 347431)
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
-- TOC entry 6513 (class 0 OID 0)
-- Dependencies: 569
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.fecha_requerida IS 'Fecha límite operativa';


--
-- TOC entry 6514 (class 0 OID 0)
-- Dependencies: 569
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- TOC entry 6515 (class 0 OID 0)
-- Dependencies: 569
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- TOC entry 6516 (class 0 OID 0)
-- Dependencies: 569
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- TOC entry 6517 (class 0 OID 0)
-- Dependencies: 569
-- Name: COLUMN purchase_requests.origen_suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.origen_suggestion_id IS 'FK a purchase_suggestions - si fue generada automáticamente';


--
-- TOC entry 570 (class 1259 OID 347441)
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
-- TOC entry 6518 (class 0 OID 0)
-- Dependencies: 570
-- Name: purchase_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_requests_id_seq OWNED BY purchase_requests.id;


--
-- TOC entry 571 (class 1259 OID 347443)
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
-- TOC entry 6519 (class 0 OID 0)
-- Dependencies: 571
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- TOC entry 6520 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- TOC entry 6521 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- TOC entry 6522 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- TOC entry 6523 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- TOC entry 6524 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- TOC entry 6525 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- TOC entry 6526 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- TOC entry 6527 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN purchase_suggestion_lines.proveedor_sugerido_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.proveedor_sugerido_id IS 'FK a selemti.cat_proveedores.id';


--
-- TOC entry 572 (class 1259 OID 347453)
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
-- TOC entry 6528 (class 0 OID 0)
-- Dependencies: 572
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestion_lines_id_seq OWNED BY purchase_suggestion_lines.id;


--
-- TOC entry 573 (class 1259 OID 347455)
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
-- TOC entry 6529 (class 0 OID 0)
-- Dependencies: 573
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- TOC entry 6530 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- TOC entry 6531 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- TOC entry 6532 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- TOC entry 6533 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- TOC entry 6534 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6535 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6536 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- TOC entry 6537 (class 0 OID 0)
-- Dependencies: 573
-- Name: COLUMN purchase_suggestions.dias_analisis; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.dias_analisis IS 'Días usados para calcular consumo promedio';


--
-- TOC entry 574 (class 1259 OID 347469)
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
-- TOC entry 6538 (class 0 OID 0)
-- Dependencies: 574
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestions_id_seq OWNED BY purchase_suggestions.id;


--
-- TOC entry 575 (class 1259 OID 347471)
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
-- TOC entry 576 (class 1259 OID 347478)
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
-- TOC entry 6539 (class 0 OID 0)
-- Dependencies: 576
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quote_lines_id_seq OWNED BY purchase_vendor_quote_lines.id;


--
-- TOC entry 577 (class 1259 OID 347480)
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
-- TOC entry 578 (class 1259 OID 347492)
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
-- TOC entry 6540 (class 0 OID 0)
-- Dependencies: 578
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quotes_id_seq OWNED BY purchase_vendor_quotes.id;


--
-- TOC entry 579 (class 1259 OID 347494)
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
-- TOC entry 580 (class 1259 OID 347500)
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
-- TOC entry 6541 (class 0 OID 0)
-- Dependencies: 580
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


--
-- TOC entry 581 (class 1259 OID 347502)
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
-- TOC entry 582 (class 1259 OID 347508)
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
-- TOC entry 6542 (class 0 OID 0)
-- Dependencies: 582
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_adjuntos_id_seq OWNED BY recepcion_adjuntos.id;


--
-- TOC entry 583 (class 1259 OID 347510)
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
-- TOC entry 584 (class 1259 OID 347519)
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
-- TOC entry 6543 (class 0 OID 0)
-- Dependencies: 584
-- Name: recepcion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_cab_id_seq OWNED BY recepcion_cab.id;


--
-- TOC entry 585 (class 1259 OID 347521)
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
-- TOC entry 586 (class 1259 OID 347529)
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
-- TOC entry 6544 (class 0 OID 0)
-- Dependencies: 586
-- Name: recepcion_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_det_id_seq OWNED BY recepcion_det.id;


--
-- TOC entry 587 (class 1259 OID 347531)
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
-- TOC entry 588 (class 1259 OID 347539)
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
-- TOC entry 6545 (class 0 OID 0)
-- Dependencies: 588
-- Name: receta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_det_id_seq OWNED BY receta_det.id;


--
-- TOC entry 589 (class 1259 OID 347541)
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
-- TOC entry 6546 (class 0 OID 0)
-- Dependencies: 589
-- Name: receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_id_seq OWNED BY receta.id;


--
-- TOC entry 590 (class 1259 OID 347543)
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
-- TOC entry 591 (class 1259 OID 347546)
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
-- TOC entry 6547 (class 0 OID 0)
-- Dependencies: 591
-- Name: receta_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_insumo_id_seq OWNED BY receta_insumo.id;


--
-- TOC entry 592 (class 1259 OID 347548)
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
-- TOC entry 593 (class 1259 OID 347561)
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
-- TOC entry 6548 (class 0 OID 0)
-- Dependencies: 593
-- Name: receta_shadow_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_shadow_id_seq OWNED BY receta_shadow.id;


--
-- TOC entry 594 (class 1259 OID 347563)
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
-- TOC entry 6549 (class 0 OID 0)
-- Dependencies: 594
-- Name: receta_version_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_version_id_seq OWNED BY receta_version.id;


--
-- TOC entry 595 (class 1259 OID 347565)
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
-- TOC entry 596 (class 1259 OID 347573)
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
-- TOC entry 6550 (class 0 OID 0)
-- Dependencies: 596
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_history_id_seq OWNED BY recipe_cost_history.id;


--
-- TOC entry 597 (class 1259 OID 347575)
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
-- TOC entry 6551 (class 0 OID 0)
-- Dependencies: 597
-- Name: TABLE recipe_cost_snapshots; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE recipe_cost_snapshots IS 'Snapshots historicos de costos de recetas para auditoria y performance';


--
-- TOC entry 6552 (class 0 OID 0)
-- Dependencies: 597
-- Name: COLUMN recipe_cost_snapshots.cost_breakdown; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN recipe_cost_snapshots.cost_breakdown IS 'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';


--
-- TOC entry 6553 (class 0 OID 0)
-- Dependencies: 597
-- Name: COLUMN recipe_cost_snapshots.reason; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN recipe_cost_snapshots.reason IS 'MANUAL: Creado manualmente por usuario\n     AUTO_THRESHOLD: Creado automaticamente por cambio >2% en costo\n     INGREDIENT_CHANGE: Creado por modificacion de ingredientes\n     SCHEDULED: Creado por job programado (cierre de dia)';


--
-- TOC entry 598 (class 1259 OID 347586)
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
-- TOC entry 6554 (class 0 OID 0)
-- Dependencies: 598
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_snapshots_id_seq OWNED BY recipe_cost_snapshots.id;


--
-- TOC entry 599 (class 1259 OID 347588)
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
-- TOC entry 600 (class 1259 OID 347601)
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
-- TOC entry 6555 (class 0 OID 0)
-- Dependencies: 600
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_extended_cost_history_id_seq OWNED BY recipe_extended_cost_history.id;


--
-- TOC entry 601 (class 1259 OID 347603)
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
-- TOC entry 602 (class 1259 OID 347611)
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
-- TOC entry 6556 (class 0 OID 0)
-- Dependencies: 602
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_labor_steps_id_seq OWNED BY recipe_labor_steps.id;


--
-- TOC entry 603 (class 1259 OID 347613)
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
-- TOC entry 604 (class 1259 OID 347619)
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
-- TOC entry 6557 (class 0 OID 0)
-- Dependencies: 604
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_overhead_allocations_id_seq OWNED BY recipe_overhead_allocations.id;


--
-- TOC entry 605 (class 1259 OID 347621)
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
-- TOC entry 606 (class 1259 OID 347624)
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
-- TOC entry 6558 (class 0 OID 0)
-- Dependencies: 606
-- Name: recipe_version_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_version_items_id_seq OWNED BY recipe_version_items.id;


--
-- TOC entry 607 (class 1259 OID 347626)
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
-- TOC entry 608 (class 1259 OID 347634)
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
-- TOC entry 6559 (class 0 OID 0)
-- Dependencies: 608
-- Name: recipe_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_versions_id_seq OWNED BY recipe_versions.id;


--
-- TOC entry 609 (class 1259 OID 347636)
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
-- TOC entry 6560 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- TOC entry 6561 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- TOC entry 6562 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- TOC entry 6563 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- TOC entry 6564 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.item_id IS 'FK to items.id';


--
-- TOC entry 6565 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- TOC entry 6566 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- TOC entry 6567 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- TOC entry 6568 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- TOC entry 6569 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- TOC entry 6570 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- TOC entry 6571 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- TOC entry 6572 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- TOC entry 6573 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- TOC entry 6574 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- TOC entry 6575 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- TOC entry 6576 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.notas IS 'Notas del usuario';


--
-- TOC entry 6577 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN replenishment_suggestions.meta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.meta IS 'Metadata: proveedor preferido, evento, etc.';


--
-- TOC entry 610 (class 1259 OID 347646)
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
-- TOC entry 6578 (class 0 OID 0)
-- Dependencies: 610
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE replenishment_suggestions_id_seq OWNED BY replenishment_suggestions.id;


--
-- TOC entry 611 (class 1259 OID 347648)
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
-- TOC entry 612 (class 1259 OID 347655)
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
-- TOC entry 6579 (class 0 OID 0)
-- Dependencies: 612
-- Name: report_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_definitions_id_seq OWNED BY report_definitions.id;


--
-- TOC entry 613 (class 1259 OID 347657)
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
-- TOC entry 614 (class 1259 OID 347663)
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
-- TOC entry 6580 (class 0 OID 0)
-- Dependencies: 614
-- Name: report_favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_favorites_id_seq OWNED BY report_favorites.id;


--
-- TOC entry 615 (class 1259 OID 347665)
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
-- TOC entry 616 (class 1259 OID 347672)
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
-- TOC entry 6581 (class 0 OID 0)
-- Dependencies: 616
-- Name: report_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_runs_id_seq OWNED BY report_runs.id;


--
-- TOC entry 617 (class 1259 OID 347674)
-- Name: rol; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE rol (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE rol OWNER TO postgres;

--
-- TOC entry 618 (class 1259 OID 347680)
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
-- TOC entry 6582 (class 0 OID 0)
-- Dependencies: 618
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE rol_id_seq OWNED BY rol.id;


--
-- TOC entry 619 (class 1259 OID 347682)
-- Name: role_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE role_has_permissions OWNER TO postgres;

--
-- TOC entry 620 (class 1259 OID 347685)
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
-- TOC entry 6583 (class 0 OID 0)
-- Dependencies: 620
-- Name: TABLE roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE roles IS 'Tabla de roles (Spatie Permission) - Consolidada en Phase 2.1';


--
-- TOC entry 621 (class 1259 OID 347691)
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
-- TOC entry 6584 (class 0 OID 0)
-- Dependencies: 621
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- TOC entry 622 (class 1259 OID 347693)
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
-- TOC entry 623 (class 1259 OID 347695)
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
    CONSTRAINT sesion_cajon_estatus_check CHECK ((estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'EN_CORTE'::text, 'CERRADA'::text])))
);


ALTER TABLE sesion_cajon OWNER TO floreant;

--
-- TOC entry 624 (class 1259 OID 347706)
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
-- TOC entry 6585 (class 0 OID 0)
-- Dependencies: 624
-- Name: sesion_cajon_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE sesion_cajon_id_seq OWNED BY sesion_cajon.id;


--
-- TOC entry 625 (class 1259 OID 347708)
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
-- TOC entry 626 (class 1259 OID 347714)
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
-- TOC entry 627 (class 1259 OID 347723)
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
-- TOC entry 6586 (class 0 OID 0)
-- Dependencies: 627
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_cab_id_seq OWNED BY sol_prod_cab.id;


--
-- TOC entry 628 (class 1259 OID 347725)
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
-- TOC entry 629 (class 1259 OID 347729)
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
-- TOC entry 6587 (class 0 OID 0)
-- Dependencies: 629
-- Name: sol_prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_det_id_seq OWNED BY sol_prod_det.id;


--
-- TOC entry 630 (class 1259 OID 347731)
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
-- TOC entry 631 (class 1259 OID 347741)
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
-- TOC entry 6588 (class 0 OID 0)
-- Dependencies: 631
-- Name: stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE stock_policy_id_seq OWNED BY stock_policy.id;


--
-- TOC entry 632 (class 1259 OID 347743)
-- Name: sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE sucursal OWNER TO postgres;

--
-- TOC entry 633 (class 1259 OID 347750)
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
-- TOC entry 634 (class 1259 OID 347758)
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
-- TOC entry 6589 (class 0 OID 0)
-- Dependencies: 634
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sucursal_almacen_terminal_id_seq OWNED BY sucursal_almacen_terminal.id;


--
-- TOC entry 635 (class 1259 OID 347760)
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
-- TOC entry 636 (class 1259 OID 347769)
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
-- TOC entry 6590 (class 0 OID 0)
-- Dependencies: 636
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


--
-- TOC entry 637 (class 1259 OID 347771)
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
-- TOC entry 6591 (class 0 OID 0)
-- Dependencies: 637
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- TOC entry 6592 (class 0 OID 0)
-- Dependencies: 637
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- TOC entry 6593 (class 0 OID 0)
-- Dependencies: 637
-- Name: COLUMN ticket_item_modifiers.precio_extra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.precio_extra IS 'Sobrecargo aplicado por el POS.';


--
-- TOC entry 638 (class 1259 OID 347776)
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
-- TOC entry 6594 (class 0 OID 0)
-- Dependencies: 638
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_item_modifiers_id_seq OWNED BY ticket_item_modifiers.id;


--
-- TOC entry 639 (class 1259 OID 347778)
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
-- TOC entry 640 (class 1259 OID 347786)
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
-- TOC entry 6595 (class 0 OID 0)
-- Dependencies: 640
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_cab_id_seq OWNED BY ticket_venta_cab.id;


--
-- TOC entry 641 (class 1259 OID 347788)
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
-- TOC entry 642 (class 1259 OID 347798)
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
-- TOC entry 6596 (class 0 OID 0)
-- Dependencies: 642
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


--
-- TOC entry 643 (class 1259 OID 347800)
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
-- TOC entry 644 (class 1259 OID 347805)
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
-- TOC entry 6597 (class 0 OID 0)
-- Dependencies: 644
-- Name: transfer_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_cab_id_seq OWNED BY transfer_cab.id;


--
-- TOC entry 645 (class 1259 OID 347807)
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
-- TOC entry 646 (class 1259 OID 347811)
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
-- TOC entry 6598 (class 0 OID 0)
-- Dependencies: 646
-- Name: transfer_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_det_id_seq OWNED BY transfer_det.id;


--
-- TOC entry 647 (class 1259 OID 347813)
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
-- TOC entry 648 (class 1259 OID 347822)
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
-- TOC entry 6599 (class 0 OID 0)
-- Dependencies: 648
-- Name: traspaso_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_cab_id_seq OWNED BY traspaso_cab.id;


--
-- TOC entry 649 (class 1259 OID 347824)
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
-- TOC entry 650 (class 1259 OID 347829)
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
-- TOC entry 6600 (class 0 OID 0)
-- Dependencies: 650
-- Name: traspaso_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_det_id_seq OWNED BY traspaso_det.id;


--
-- TOC entry 651 (class 1259 OID 347831)
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
-- TOC entry 6601 (class 0 OID 0)
-- Dependencies: 651
-- Name: VIEW unidad_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidad_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidad_medida';


--
-- TOC entry 652 (class 1259 OID 347836)
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
-- TOC entry 653 (class 1259 OID 347846)
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
-- TOC entry 6602 (class 0 OID 0)
-- Dependencies: 653
-- Name: unidad_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidad_medida_id_seq OWNED BY unidad_medida_legacy.id;


--
-- TOC entry 654 (class 1259 OID 347848)
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
-- TOC entry 6603 (class 0 OID 0)
-- Dependencies: 654
-- Name: VIEW unidades_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidades_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidades_medida con categoria';


--
-- TOC entry 655 (class 1259 OID 347853)
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
-- TOC entry 656 (class 1259 OID 347864)
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
-- TOC entry 6604 (class 0 OID 0)
-- Dependencies: 656
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida_legacy.id;


--
-- TOC entry 657 (class 1259 OID 347866)
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
-- TOC entry 6605 (class 0 OID 0)
-- Dependencies: 657
-- Name: VIEW uom_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW uom_conversion IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy uom_conversion';


--
-- TOC entry 658 (class 1259 OID 347870)
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
-- TOC entry 659 (class 1259 OID 347875)
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
-- TOC entry 6606 (class 0 OID 0)
-- Dependencies: 659
-- Name: uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE uom_conversion_id_seq OWNED BY uom_conversion_legacy.id;


--
-- TOC entry 660 (class 1259 OID 347877)
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
-- TOC entry 6607 (class 0 OID 0)
-- Dependencies: 660
-- Name: TABLE user_roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE user_roles IS 'AsignaciÃ³n de roles a usuarios.';


--
-- TOC entry 661 (class 1259 OID 347882)
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
-- TOC entry 6608 (class 0 OID 0)
-- Dependencies: 661
-- Name: TABLE users; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE users IS 'Tabla canÃ³nica de usuarios del sistema - Consolidada en Phase 2.1';


--
-- TOC entry 662 (class 1259 OID 347898)
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
-- TOC entry 6609 (class 0 OID 0)
-- Dependencies: 662
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 663 (class 1259 OID 347900)
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
-- TOC entry 664 (class 1259 OID 347908)
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
-- TOC entry 6610 (class 0 OID 0)
-- Dependencies: 664
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE usuario_id_seq OWNED BY usuario.id;


--
-- TOC entry 665 (class 1259 OID 347910)
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
-- TOC entry 6611 (class 0 OID 0)
-- Dependencies: 665
-- Name: VIEW v_almacen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_almacen IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy almacen';


--
-- TOC entry 666 (class 1259 OID 347914)
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
-- TOC entry 6612 (class 0 OID 0)
-- Dependencies: 666
-- Name: VIEW v_bodega; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_bodega IS 'Vista de compatibilidad - Mapea cat_almacenes â†’ formato legacy bodega';


--
-- TOC entry 667 (class 1259 OID 347918)
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
-- TOC entry 6613 (class 0 OID 0)
-- Dependencies: 667
-- Name: VIEW v_cat_unidades_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_cat_unidades_compat IS 'Vista de compatibilidad para cat_unidades. Mapea a unidades_medida_legacy (canónica)';


--
-- TOC entry 668 (class 1259 OID 347922)
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
-- TOC entry 669 (class 1259 OID 347927)
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
-- TOC entry 6614 (class 0 OID 0)
-- Dependencies: 669
-- Name: VIEW v_insumo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_insumo IS 'Vista de compatibilidad - Mapea items â†’ formato legacy insumo';


--
-- TOC entry 670 (class 1259 OID 347932)
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
-- TOC entry 671 (class 1259 OID 347937)
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
-- TOC entry 6615 (class 0 OID 0)
-- Dependencies: 671
-- Name: VIEW v_lote; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_lote IS 'Vista de compatibilidad - Mapea inventory_batch â†’ formato legacy lote';


--
-- TOC entry 672 (class 1259 OID 347941)
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
-- TOC entry 673 (class 1259 OID 347946)
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
-- TOC entry 6616 (class 0 OID 0)
-- Dependencies: 673
-- Name: VIEW v_receta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_receta IS 'Vista de compatibilidad - Mapea receta_cab â†’ formato legacy receta';


--
-- TOC entry 674 (class 1259 OID 347950)
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
-- TOC entry 675 (class 1259 OID 347954)
-- Name: v_rol; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_rol AS
 SELECT (roles.id)::integer AS id,
    roles.name AS codigo,
    COALESCE(roles.display_name, roles.name) AS nombre
   FROM roles;


ALTER TABLE v_rol OWNER TO postgres;

--
-- TOC entry 6617 (class 0 OID 0)
-- Dependencies: 675
-- Name: VIEW v_rol; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_rol IS 'Vista de compatibilidad - Mapea roles â†’ formato legacy rol';


--
-- TOC entry 676 (class 1259 OID 347958)
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
-- TOC entry 677 (class 1259 OID 347963)
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
-- TOC entry 678 (class 1259 OID 347968)
-- Name: v_sucursal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW v_sucursal AS
 SELECT cat_sucursales.clave AS id,
    cat_sucursales.nombre,
    cat_sucursales.activo
   FROM cat_sucursales;


ALTER TABLE v_sucursal OWNER TO postgres;

--
-- TOC entry 6618 (class 0 OID 0)
-- Dependencies: 678
-- Name: VIEW v_sucursal; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_sucursal IS 'Vista de compatibilidad - Mapea cat_sucursales â†’ formato legacy';


--
-- TOC entry 679 (class 1259 OID 347972)
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
-- TOC entry 6619 (class 0 OID 0)
-- Dependencies: 679
-- Name: VIEW v_unidad_medida_singular_compat; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_unidad_medida_singular_compat IS 'Vista de compatibilidad para unidad_medida_legacy (singular). Mapea a unidades_medida_legacy (canónica)';


--
-- TOC entry 680 (class 1259 OID 347976)
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
-- TOC entry 6620 (class 0 OID 0)
-- Dependencies: 680
-- Name: VIEW v_usuario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_usuario IS 'Vista de compatibilidad - Mapea users â†’ formato legacy usuario';


--
-- TOC entry 681 (class 1259 OID 347980)
-- Name: vw_dashboard_formas_pago; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_formas_pago AS
 SELECT (t.transaction_time)::date AS fecha,
    COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text) AS sucursal_id,
    COALESCE(fp.codigo, (t.payment_type)::text, 'OTRO'::text) AS codigo_fp,
    (sum(t.amount))::numeric(12,2) AS monto
   FROM ((public.transactions t
     LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text))))
     LEFT JOIN public.terminal term ON ((term.id = t.terminal_id)))
  WHERE (t.transaction_time IS NOT NULL)
  GROUP BY ((t.transaction_time)::date), COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text), COALESCE(fp.codigo, (t.payment_type)::text, 'OTRO'::text);


ALTER TABLE vw_dashboard_formas_pago OWNER TO postgres;

--
-- TOC entry 682 (class 1259 OID 347985)
-- Name: vw_dashboard_ticket_base; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_ticket_base AS
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


ALTER TABLE vw_dashboard_ticket_base OWNER TO postgres;

--
-- TOC entry 683 (class 1259 OID 347990)
-- Name: vw_dashboard_ordenes; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_ordenes AS
 SELECT base.ticket_id,
    base.fecha,
    base.hora,
    base.sucursal_id,
    base.terminal_id,
    base.ticket_ref,
    base.total,
    base.closing_date
   FROM vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false));


ALTER TABLE vw_dashboard_ordenes OWNER TO postgres;

--
-- TOC entry 684 (class 1259 OID 347994)
-- Name: vw_dashboard_resumen_sucursal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_resumen_sucursal AS
 SELECT base.fecha,
    base.sucursal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total,
    sum(base.sub_total) AS sub_total
   FROM vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.sucursal_id;


ALTER TABLE vw_dashboard_resumen_sucursal OWNER TO postgres;

--
-- TOC entry 685 (class 1259 OID 347998)
-- Name: vw_dashboard_resumen_terminal; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_resumen_terminal AS
 SELECT base.fecha,
    base.terminal_id,
    base.sucursal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total,
    sum(base.sub_total) AS sub_total
   FROM vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.terminal_id, base.sucursal_id;


ALTER TABLE vw_dashboard_resumen_terminal OWNER TO postgres;

--
-- TOC entry 686 (class 1259 OID 348002)
-- Name: vw_dashboard_ventas_productos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_ventas_productos AS
 SELECT base.fecha,
    base.sucursal_id,
    base.terminal_id,
    ti.item_id AS plu,
    COALESCE(NULLIF((ti.item_name)::text, ''::text), (mi.name)::text, (ti.item_id)::text) AS descripcion,
    COALESCE(mg.name, 'SIN CATEGORIA'::character varying) AS categoria,
    sum(COALESCE(NULLIF(ti.item_quantity, (0)::double precision), (NULLIF(ti.item_count, 0))::double precision, (0)::double precision)) AS unidades,
    sum(COALESCE(ti.total_price, (0)::double precision)) AS venta_total
   FROM (((vw_dashboard_ticket_base base
     JOIN public.ticket_item ti ON ((ti.ticket_id = base.ticket_id)))
     LEFT JOIN public.menu_item mi ON ((mi.id = ti.item_id)))
     LEFT JOIN public.menu_group mg ON ((mg.id = mi.group_id)))
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, base.sucursal_id, base.terminal_id, ti.item_id, COALESCE(NULLIF((ti.item_name)::text, ''::text), (mi.name)::text, (ti.item_id)::text), COALESCE(mg.name, 'SIN CATEGORIA'::character varying);


ALTER TABLE vw_dashboard_ventas_productos OWNER TO postgres;

--
-- TOC entry 687 (class 1259 OID 348007)
-- Name: vw_dashboard_ventas_categorias; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_ventas_categorias AS
 SELECT vw_dashboard_ventas_productos.fecha,
    vw_dashboard_ventas_productos.sucursal_id,
    vw_dashboard_ventas_productos.categoria,
    sum(vw_dashboard_ventas_productos.unidades) AS unidades,
    sum(vw_dashboard_ventas_productos.venta_total) AS venta_total
   FROM vw_dashboard_ventas_productos
  GROUP BY vw_dashboard_ventas_productos.fecha, vw_dashboard_ventas_productos.sucursal_id, vw_dashboard_ventas_productos.categoria;


ALTER TABLE vw_dashboard_ventas_categorias OWNER TO postgres;

--
-- TOC entry 688 (class 1259 OID 348011)
-- Name: vw_dashboard_ventas_hora; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_ventas_hora AS
 SELECT base.fecha,
    date_trunc('hour'::text, base.hora) AS hora,
    base.sucursal_id,
    base.terminal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total
   FROM vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY base.fecha, (date_trunc('hour'::text, base.hora)), base.sucursal_id, base.terminal_id;


ALTER TABLE vw_dashboard_ventas_hora OWNER TO postgres;

--
-- TOC entry 689 (class 1259 OID 348015)
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
-- TOC entry 690 (class 1259 OID 348020)
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
-- TOC entry 691 (class 1259 OID 348025)
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
-- TOC entry 692 (class 1259 OID 348030)
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
-- TOC entry 693 (class 1259 OID 348035)
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
-- TOC entry 694 (class 1259 OID 348040)
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
-- TOC entry 695 (class 1259 OID 348045)
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
-- TOC entry 696 (class 1259 OID 348050)
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

--
-- TOC entry 697 (class 1259 OID 348054)
-- Name: vw_ticket_promedio_sucursal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_ticket_promedio_sucursal_dia AS
 WITH tbase AS (
         SELECT vw_dashboard_ticket_base.fecha,
            vw_dashboard_ticket_base.sucursal_id,
            vw_dashboard_ticket_base.ticket_id,
            vw_dashboard_ticket_base.total
           FROM vw_dashboard_ticket_base
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


ALTER TABLE vw_ticket_promedio_sucursal_dia OWNER TO postgres;

--
-- TOC entry 698 (class 1259 OID 348059)
-- Name: vw_ventas_por_hora; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_ventas_por_hora AS
 SELECT vw_dashboard_ventas_hora.fecha,
    vw_dashboard_ventas_hora.hora,
    vw_dashboard_ventas_hora.sucursal_id,
    vw_dashboard_ventas_hora.terminal_id,
    vw_dashboard_ventas_hora.tickets,
    vw_dashboard_ventas_hora.venta_total
   FROM vw_dashboard_ventas_hora
  ORDER BY vw_dashboard_ventas_hora.hora DESC;


ALTER TABLE vw_ventas_por_hora OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 3934 (class 2604 OID 348063)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history ALTER COLUMN id SET DEFAULT nextval('action_history_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 348064)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history ALTER COLUMN id SET DEFAULT nextval('attendence_history_id_seq'::regclass);


--
-- TOC entry 3936 (class 2604 OID 348065)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer ALTER COLUMN id SET DEFAULT nextval('cash_drawer_id_seq'::regclass);


--
-- TOC entry 3937 (class 2604 OID 348066)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass);


--
-- TOC entry 3938 (class 2604 OID 348067)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction ALTER COLUMN id SET DEFAULT nextval('cooking_instruction_id_seq'::regclass);


--
-- TOC entry 3939 (class 2604 OID 348068)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('coupon_and_discount_id_seq'::regclass);


--
-- TOC entry 3940 (class 2604 OID 348069)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency ALTER COLUMN id SET DEFAULT nextval('currency_id_seq'::regclass);


--
-- TOC entry 3941 (class 2604 OID 348070)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance ALTER COLUMN id SET DEFAULT nextval('currency_balance_id_seq'::regclass);


--
-- TOC entry 3942 (class 2604 OID 348071)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment ALTER COLUMN id SET DEFAULT nextval('custom_payment_id_seq'::regclass);


--
-- TOC entry 3943 (class 2604 OID 348072)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer ALTER COLUMN auto_id SET DEFAULT nextval('customer_auto_id_seq'::regclass);


--
-- TOC entry 3945 (class 2604 OID 348073)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info ALTER COLUMN id SET DEFAULT nextval('data_update_info_id_seq'::regclass);


--
-- TOC entry 3946 (class 2604 OID 348074)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address ALTER COLUMN id SET DEFAULT nextval('delivery_address_id_seq'::regclass);


--
-- TOC entry 3947 (class 2604 OID 348075)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge ALTER COLUMN id SET DEFAULT nextval('delivery_charge_id_seq'::regclass);


--
-- TOC entry 3948 (class 2604 OID 348076)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration ALTER COLUMN id SET DEFAULT nextval('delivery_configuration_id_seq'::regclass);


--
-- TOC entry 3949 (class 2604 OID 348077)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction ALTER COLUMN id SET DEFAULT nextval('delivery_instruction_id_seq'::regclass);


--
-- TOC entry 3950 (class 2604 OID 348078)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('drawer_assigned_history_id_seq'::regclass);


--
-- TOC entry 3951 (class 2604 OID 348079)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('drawer_pull_report_id_seq'::regclass);


--
-- TOC entry 3952 (class 2604 OID 348080)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('employee_in_out_history_id_seq'::regclass);


--
-- TOC entry 3953 (class 2604 OID 348081)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config ALTER COLUMN id SET DEFAULT nextval('global_config_id_seq'::regclass);


--
-- TOC entry 3954 (class 2604 OID 348082)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity ALTER COLUMN id SET DEFAULT nextval('gratuity_id_seq'::regclass);


--
-- TOC entry 3955 (class 2604 OID 348083)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print ALTER COLUMN id SET DEFAULT nextval('guest_check_print_id_seq'::regclass);


--
-- TOC entry 3956 (class 2604 OID 348084)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group ALTER COLUMN id SET DEFAULT nextval('inventory_group_id_seq'::regclass);


--
-- TOC entry 3957 (class 2604 OID 348085)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item ALTER COLUMN id SET DEFAULT nextval('inventory_item_id_seq'::regclass);


--
-- TOC entry 3958 (class 2604 OID 348086)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location ALTER COLUMN id SET DEFAULT nextval('inventory_location_id_seq'::regclass);


--
-- TOC entry 3959 (class 2604 OID 348087)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('inventory_meta_code_id_seq'::regclass);


--
-- TOC entry 3960 (class 2604 OID 348088)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction ALTER COLUMN id SET DEFAULT nextval('inventory_transaction_id_seq'::regclass);


--
-- TOC entry 3961 (class 2604 OID 348089)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit ALTER COLUMN id SET DEFAULT nextval('inventory_unit_id_seq'::regclass);


--
-- TOC entry 3962 (class 2604 OID 348090)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor ALTER COLUMN id SET DEFAULT nextval('inventory_vendor_id_seq'::regclass);


--
-- TOC entry 3963 (class 2604 OID 348091)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('inventory_warehouse_id_seq'::regclass);


--
-- TOC entry 3964 (class 2604 OID 348092)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_id_seq'::regclass);


--
-- TOC entry 3968 (class 2604 OID 348093)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_item_id_seq'::regclass);


--
-- TOC entry 3969 (class 2604 OID 348094)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category ALTER COLUMN id SET DEFAULT nextval('menu_category_id_seq'::regclass);


--
-- TOC entry 3970 (class 2604 OID 348095)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group ALTER COLUMN id SET DEFAULT nextval('menu_group_id_seq'::regclass);


--
-- TOC entry 3971 (class 2604 OID 348096)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item ALTER COLUMN id SET DEFAULT nextval('menu_item_id_seq'::regclass);


--
-- TOC entry 3972 (class 2604 OID 348097)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size ALTER COLUMN id SET DEFAULT nextval('menu_item_size_id_seq'::regclass);


--
-- TOC entry 3973 (class 2604 OID 348098)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier ALTER COLUMN id SET DEFAULT nextval('menu_modifier_id_seq'::regclass);


--
-- TOC entry 3974 (class 2604 OID 348099)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('menu_modifier_group_id_seq'::regclass);


--
-- TOC entry 3975 (class 2604 OID 348100)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass);


--
-- TOC entry 3976 (class 2604 OID 348101)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift ALTER COLUMN id SET DEFAULT nextval('menuitem_shift_id_seq'::regclass);


--
-- TOC entry 3977 (class 2604 OID 348102)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('modifier_multiplier_price_id_seq'::regclass);


--
-- TOC entry 3978 (class 2604 OID 348103)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type ALTER COLUMN id SET DEFAULT nextval('order_type_id_seq'::regclass);


--
-- TOC entry 3979 (class 2604 OID 348104)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit ALTER COLUMN id SET DEFAULT nextval('packaging_unit_id_seq'::regclass);


--
-- TOC entry 3980 (class 2604 OID 348105)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons ALTER COLUMN id SET DEFAULT nextval('payout_reasons_id_seq'::regclass);


--
-- TOC entry 3981 (class 2604 OID 348106)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients ALTER COLUMN id SET DEFAULT nextval('payout_recepients_id_seq'::regclass);


--
-- TOC entry 3982 (class 2604 OID 348107)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust ALTER COLUMN id SET DEFAULT nextval('pizza_crust_id_seq'::regclass);


--
-- TOC entry 3983 (class 2604 OID 348108)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('pizza_modifier_price_id_seq'::regclass);


--
-- TOC entry 3984 (class 2604 OID 348109)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price ALTER COLUMN id SET DEFAULT nextval('pizza_price_id_seq'::regclass);


--
-- TOC entry 3985 (class 2604 OID 348110)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group ALTER COLUMN id SET DEFAULT nextval('printer_group_id_seq'::regclass);


--
-- TOC entry 3986 (class 2604 OID 348111)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order ALTER COLUMN id SET DEFAULT nextval('purchase_order_id_seq'::regclass);


--
-- TOC entry 3987 (class 2604 OID 348112)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie ALTER COLUMN id SET DEFAULT nextval('recepie_id_seq'::regclass);


--
-- TOC entry 3988 (class 2604 OID 348113)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item ALTER COLUMN id SET DEFAULT nextval('recepie_item_id_seq'::regclass);


--
-- TOC entry 3989 (class 2604 OID 348114)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift ALTER COLUMN id SET DEFAULT nextval('shift_id_seq'::regclass);


--
-- TOC entry 3990 (class 2604 OID 348115)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor ALTER COLUMN id SET DEFAULT nextval('shop_floor_id_seq'::regclass);


--
-- TOC entry 3991 (class 2604 OID 348116)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template ALTER COLUMN id SET DEFAULT nextval('shop_floor_template_id_seq'::regclass);


--
-- TOC entry 3992 (class 2604 OID 348117)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type ALTER COLUMN id SET DEFAULT nextval('shop_table_type_id_seq'::regclass);


--
-- TOC entry 3993 (class 2604 OID 348118)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info ALTER COLUMN id SET DEFAULT nextval('table_booking_info_id_seq'::regclass);


--
-- TOC entry 3994 (class 2604 OID 348119)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax ALTER COLUMN id SET DEFAULT nextval('tax_id_seq'::regclass);


--
-- TOC entry 3995 (class 2604 OID 348120)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers ALTER COLUMN id SET DEFAULT nextval('terminal_printers_id_seq'::regclass);


--
-- TOC entry 3965 (class 2604 OID 348121)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket ALTER COLUMN id SET DEFAULT nextval('ticket_id_seq'::regclass);


--
-- TOC entry 3996 (class 2604 OID 348122)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount ALTER COLUMN id SET DEFAULT nextval('ticket_discount_id_seq'::regclass);


--
-- TOC entry 3997 (class 2604 OID 348123)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item ALTER COLUMN id SET DEFAULT nextval('ticket_item_id_seq'::regclass);


--
-- TOC entry 3998 (class 2604 OID 348124)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('ticket_item_discount_id_seq'::regclass);


--
-- TOC entry 3999 (class 2604 OID 348125)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifier_id_seq'::regclass);


--
-- TOC entry 4000 (class 2604 OID 348126)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- TOC entry 4001 (class 2604 OID 348127)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type ALTER COLUMN id SET DEFAULT nextval('user_type_id_seq'::regclass);


--
-- TOC entry 4002 (class 2604 OID 348128)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users ALTER COLUMN auto_id SET DEFAULT nextval('users_auto_id_seq'::regclass);


--
-- TOC entry 4003 (class 2604 OID 348129)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer ALTER COLUMN id SET DEFAULT nextval('virtual_printer_id_seq'::regclass);


--
-- TOC entry 4004 (class 2604 OID 348130)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons ALTER COLUMN id SET DEFAULT nextval('void_reasons_id_seq'::regclass);


--
-- TOC entry 4005 (class 2604 OID 348131)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4009 (class 2604 OID 350474)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 4013 (class 2604 OID 350475)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 4016 (class 2604 OID 350476)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes ALTER COLUMN id SET DEFAULT nextval('alertas_cortes_id_seq'::regclass);


--
-- TOC entry 4019 (class 2604 OID 350477)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- TOC entry 4021 (class 2604 OID 350478)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global ALTER COLUMN id SET DEFAULT nextval('audit_log_global_id_seq'::regclass);


--
-- TOC entry 4024 (class 2604 OID 350479)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 4025 (class 2604 OID 350480)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 4030 (class 2604 OID 350481)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_id_seq'::regclass);


--
-- TOC entry 4032 (class 2604 OID 350482)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('caja_fondo_adj_id_seq'::regclass);


--
-- TOC entry 4034 (class 2604 OID 350483)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_arqueo_id_seq'::regclass);


--
-- TOC entry 4041 (class 2604 OID 350484)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('caja_fondo_mov_id_seq'::regclass);


--
-- TOC entry 4042 (class 2604 OID 350485)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('cash_fund_arqueos_id_seq'::regclass);


--
-- TOC entry 4044 (class 2604 OID 350486)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('cash_fund_movement_audit_log_id_seq'::regclass);


--
-- TOC entry 4048 (class 2604 OID 350487)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('cash_fund_movements_id_seq'::regclass);


--
-- TOC entry 4054 (class 2604 OID 350488)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds ALTER COLUMN id SET DEFAULT nextval('cash_funds_id_seq'::regclass);


--
-- TOC entry 4057 (class 2604 OID 350489)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 4059 (class 2604 OID 350490)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 4061 (class 2604 OID 350491)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 4063 (class 2604 OID 350492)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 4066 (class 2604 OID 350493)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 4069 (class 2604 OID 350494)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 4074 (class 2604 OID 350495)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 4077 (class 2604 OID 350496)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 4079 (class 2604 OID 350497)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 4083 (class 2604 OID 350498)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 4089 (class 2604 OID 350499)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 4093 (class 2604 OID 350500)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 4100 (class 2604 OID 350501)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 4107 (class 2604 OID 350502)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 4111 (class 2604 OID 350503)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 4117 (class 2604 OID 350504)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 4124 (class 2604 OID 350505)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_proveedor_presentacion_id_seq'::regclass);


--
-- TOC entry 4130 (class 2604 OID 350506)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_id_seq'::regclass);


--
-- TOC entry 4135 (class 2604 OID 350507)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_det_id_seq'::regclass);


--
-- TOC entry 4137 (class 2604 OID 350508)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_log_id_seq'::regclass);


--
-- TOC entry 4142 (class 2604 OID 350509)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 4147 (class 2604 OID 350510)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 4158 (class 2604 OID 350511)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('inventory_count_lines_id_seq'::regclass);


--
-- TOC entry 4162 (class 2604 OID 350512)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts ALTER COLUMN id SET DEFAULT nextval('inventory_counts_id_seq'::regclass);


--
-- TOC entry 4167 (class 2604 OID 350513)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes ALTER COLUMN id SET DEFAULT nextval('inventory_wastes_id_seq'::regclass);


--
-- TOC entry 4169 (class 2604 OID 350514)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 4181 (class 2604 OID 350515)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 4201 (class 2604 OID 350516)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 4204 (class 2604 OID 350517)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 4207 (class 2604 OID 350518)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles ALTER COLUMN id SET DEFAULT nextval('labor_roles_id_seq'::regclass);


--
-- TOC entry 4210 (class 2604 OID 350519)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 4219 (class 2604 OID 350520)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('menu_engineering_snapshots_id_seq'::regclass);


--
-- TOC entry 4221 (class 2604 OID 350521)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('menu_item_sync_map_id_seq'::regclass);


--
-- TOC entry 4223 (class 2604 OID 350522)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- TOC entry 4227 (class 2604 OID 350523)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 4228 (class 2604 OID 350524)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 4231 (class 2604 OID 350525)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 4236 (class 2604 OID 350526)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 4260 (class 2604 OID 350527)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 4263 (class 2604 OID 350528)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 4267 (class 2604 OID 350529)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 4274 (class 2604 OID 350530)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions ALTER COLUMN id SET DEFAULT nextval('overhead_definitions_id_seq'::regclass);


--
-- TOC entry 4280 (class 2604 OID 350531)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 4283 (class 2604 OID 350532)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 4285 (class 2604 OID 350533)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 4286 (class 2604 OID 350534)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4300 (class 2604 OID 350535)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('pos_reprocess_log_id_seq'::regclass);


--
-- TOC entry 4304 (class 2604 OID 350536)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('pos_reverse_log_id_seq'::regclass);


--
-- TOC entry 4309 (class 2604 OID 350537)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('pos_sync_batches_id_seq'::regclass);


--
-- TOC entry 4311 (class 2604 OID 350538)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('pos_sync_logs_id_seq'::regclass);


--
-- TOC entry 4328 (class 2604 OID 350539)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 4336 (class 2604 OID 350540)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 4339 (class 2604 OID 350541)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 4342 (class 2604 OID 350542)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 4345 (class 2604 OID 350543)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab ALTER COLUMN id SET DEFAULT nextval('prod_cab_id_seq'::regclass);


--
-- TOC entry 4347 (class 2604 OID 350544)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det ALTER COLUMN id SET DEFAULT nextval('prod_det_id_seq'::regclass);


--
-- TOC entry 4348 (class 2604 OID 350545)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs ALTER COLUMN id SET DEFAULT nextval('production_order_inputs_id_seq'::regclass);


--
-- TOC entry 4349 (class 2604 OID 350546)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs ALTER COLUMN id SET DEFAULT nextval('production_order_outputs_id_seq'::regclass);


--
-- TOC entry 4354 (class 2604 OID 350547)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders ALTER COLUMN id SET DEFAULT nextval('production_orders_id_seq'::regclass);


--
-- TOC entry 4356 (class 2604 OID 350548)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents ALTER COLUMN id SET DEFAULT nextval('purchase_documents_id_seq'::regclass);


--
-- TOC entry 4359 (class 2604 OID 350549)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('purchase_order_lines_id_seq'::regclass);


--
-- TOC entry 4365 (class 2604 OID 350550)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders ALTER COLUMN id SET DEFAULT nextval('purchase_orders_id_seq'::regclass);


--
-- TOC entry 4367 (class 2604 OID 350551)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('purchase_request_lines_id_seq'::regclass);


--
-- TOC entry 4372 (class 2604 OID 350552)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests ALTER COLUMN id SET DEFAULT nextval('purchase_requests_id_seq'::regclass);


--
-- TOC entry 4377 (class 2604 OID 350553)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('purchase_suggestion_lines_id_seq'::regclass);


--
-- TOC entry 4386 (class 2604 OID 350554)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('purchase_suggestions_id_seq'::regclass);


--
-- TOC entry 4388 (class 2604 OID 350555)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quote_lines_id_seq'::regclass);


--
-- TOC entry 4395 (class 2604 OID 350556)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quotes_id_seq'::regclass);


--
-- TOC entry 4396 (class 2604 OID 350557)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 4397 (class 2604 OID 350558)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('recepcion_adjuntos_id_seq'::regclass);


--
-- TOC entry 4401 (class 2604 OID 350559)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 4404 (class 2604 OID 350560)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 4407 (class 2604 OID 350561)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 4249 (class 2604 OID 350562)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 4408 (class 2604 OID 350563)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 4414 (class 2604 OID 350564)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 4255 (class 2604 OID 350565)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 4419 (class 2604 OID 350566)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 4425 (class 2604 OID 350567)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots ALTER COLUMN id SET DEFAULT nextval('recipe_cost_snapshots_id_seq'::regclass);


--
-- TOC entry 4433 (class 2604 OID 350568)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_extended_cost_history_id_seq'::regclass);


--
-- TOC entry 4436 (class 2604 OID 350569)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('recipe_labor_steps_id_seq'::regclass);


--
-- TOC entry 4437 (class 2604 OID 350570)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('recipe_overhead_allocations_id_seq'::regclass);


--
-- TOC entry 4438 (class 2604 OID 350571)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 4441 (class 2604 OID 350572)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 4446 (class 2604 OID 350573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('replenishment_suggestions_id_seq'::regclass);


--
-- TOC entry 4448 (class 2604 OID 350574)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions ALTER COLUMN id SET DEFAULT nextval('report_definitions_id_seq'::regclass);


--
-- TOC entry 4449 (class 2604 OID 350575)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites ALTER COLUMN id SET DEFAULT nextval('report_favorites_id_seq'::regclass);


--
-- TOC entry 4451 (class 2604 OID 350576)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs ALTER COLUMN id SET DEFAULT nextval('report_runs_id_seq'::regclass);


--
-- TOC entry 4452 (class 2604 OID 350577)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 4453 (class 2604 OID 350578)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 4458 (class 2604 OID 350579)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 4463 (class 2604 OID 350580)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('sol_prod_cab_id_seq'::regclass);


--
-- TOC entry 4465 (class 2604 OID 350581)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det ALTER COLUMN id SET DEFAULT nextval('sol_prod_det_id_seq'::regclass);


--
-- TOC entry 4470 (class 2604 OID 350582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 4474 (class 2604 OID 350583)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 4477 (class 2604 OID 350584)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 4481 (class 2604 OID 350585)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifiers_id_seq'::regclass);


--
-- TOC entry 4486 (class 2604 OID 350586)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 4491 (class 2604 OID 350587)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 4495 (class 2604 OID 350588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab ALTER COLUMN id SET DEFAULT nextval('transfer_cab_id_seq'::regclass);


--
-- TOC entry 4497 (class 2604 OID 350589)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det ALTER COLUMN id SET DEFAULT nextval('transfer_det_id_seq'::regclass);


--
-- TOC entry 4501 (class 2604 OID 350590)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 4504 (class 2604 OID 350591)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 4508 (class 2604 OID 350592)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 4514 (class 2604 OID 350593)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 4519 (class 2604 OID 350594)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 4529 (class 2604 OID 350595)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 4537 (class 2604 OID 350596)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- TOC entry 4539 (class 2606 OID 348263)
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4541 (class 2606 OID 348265)
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4543 (class 2606 OID 348267)
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- TOC entry 4545 (class 2606 OID 348269)
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4547 (class 2606 OID 348271)
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 4549 (class 2606 OID 348273)
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4551 (class 2606 OID 348275)
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- TOC entry 4555 (class 2606 OID 348277)
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- TOC entry 4553 (class 2606 OID 348279)
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- TOC entry 4557 (class 2606 OID 348281)
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- TOC entry 4559 (class 2606 OID 348283)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 4561 (class 2606 OID 348285)
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4563 (class 2606 OID 348287)
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- TOC entry 4565 (class 2606 OID 348289)
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- TOC entry 4567 (class 2606 OID 348291)
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- TOC entry 4569 (class 2606 OID 348293)
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- TOC entry 4571 (class 2606 OID 348295)
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 4573 (class 2606 OID 348297)
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 4575 (class 2606 OID 348299)
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4579 (class 2606 OID 348301)
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- TOC entry 4582 (class 2606 OID 348303)
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4584 (class 2606 OID 348305)
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- TOC entry 4586 (class 2606 OID 348307)
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- TOC entry 4588 (class 2606 OID 348309)
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- TOC entry 4590 (class 2606 OID 348311)
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- TOC entry 4592 (class 2606 OID 348313)
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4594 (class 2606 OID 348315)
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4596 (class 2606 OID 348317)
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- TOC entry 4598 (class 2606 OID 348319)
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- TOC entry 4600 (class 2606 OID 348321)
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 4602 (class 2606 OID 348323)
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 4604 (class 2606 OID 348325)
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 4606 (class 2606 OID 348327)
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- TOC entry 4630 (class 2606 OID 348329)
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 4633 (class 2606 OID 348331)
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4609 (class 2606 OID 348333)
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4636 (class 2606 OID 348335)
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- TOC entry 4638 (class 2606 OID 348337)
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4641 (class 2606 OID 348339)
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4643 (class 2606 OID 348341)
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- TOC entry 4645 (class 2606 OID 348343)
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- TOC entry 4650 (class 2606 OID 348345)
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4647 (class 2606 OID 348347)
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 4653 (class 2606 OID 348349)
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- TOC entry 4655 (class 2606 OID 348351)
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- TOC entry 4657 (class 2606 OID 348353)
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- TOC entry 4659 (class 2606 OID 348355)
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4661 (class 2606 OID 348357)
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- TOC entry 4663 (class 2606 OID 348359)
-- Name: online_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY online_order
    ADD CONSTRAINT online_order_pkey PRIMARY KEY (id);


--
-- TOC entry 4665 (class 2606 OID 348361)
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- TOC entry 4667 (class 2606 OID 348363)
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4669 (class 2606 OID 348365)
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- TOC entry 4671 (class 2606 OID 348367)
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 4673 (class 2606 OID 348369)
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4675 (class 2606 OID 348371)
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- TOC entry 4677 (class 2606 OID 348373)
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- TOC entry 4679 (class 2606 OID 348375)
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4681 (class 2606 OID 348377)
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4683 (class 2606 OID 348379)
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 4685 (class 2606 OID 348381)
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- TOC entry 4687 (class 2606 OID 348383)
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4689 (class 2606 OID 348385)
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 4693 (class 2606 OID 348387)
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4691 (class 2606 OID 348389)
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- TOC entry 4695 (class 2606 OID 348391)
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- TOC entry 4697 (class 2606 OID 348393)
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4699 (class 2606 OID 348395)
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- TOC entry 4701 (class 2606 OID 348397)
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- TOC entry 4703 (class 2606 OID 348399)
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- TOC entry 4705 (class 2606 OID 348401)
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- TOC entry 4707 (class 2606 OID 348403)
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4709 (class 2606 OID 348405)
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- TOC entry 4711 (class 2606 OID 348407)
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4713 (class 2606 OID 348409)
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4716 (class 2606 OID 348411)
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- TOC entry 4721 (class 2606 OID 348413)
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4719 (class 2606 OID 348415)
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 4611 (class 2606 OID 348417)
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4723 (class 2606 OID 348419)
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- TOC entry 4725 (class 2606 OID 348421)
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4727 (class 2606 OID 348423)
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4619 (class 2606 OID 348425)
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- TOC entry 4732 (class 2606 OID 348427)
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4734 (class 2606 OID 348429)
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- TOC entry 4736 (class 2606 OID 348431)
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4738 (class 2606 OID 348433)
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 4740 (class 2606 OID 348435)
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4730 (class 2606 OID 348437)
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4621 (class 2606 OID 348439)
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4742 (class 2606 OID 348441)
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4744 (class 2606 OID 348443)
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4748 (class 2606 OID 348445)
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- TOC entry 4750 (class 2606 OID 348447)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 4752 (class 2606 OID 348449)
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- TOC entry 4754 (class 2606 OID 348451)
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4756 (class 2606 OID 348453)
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- TOC entry 4758 (class 2606 OID 348455)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 4760 (class 2606 OID 348457)
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- TOC entry 4762 (class 2606 OID 348459)
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- TOC entry 4764 (class 2606 OID 348461)
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- TOC entry 4766 (class 2606 OID 348463)
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- TOC entry 4768 (class 2606 OID 348465)
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4770 (class 2606 OID 348467)
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4772 (class 2606 OID 348469)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4775 (class 2606 OID 348471)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4777 (class 2606 OID 348473)
-- Name: alertas_cortes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_pkey PRIMARY KEY (id);


--
-- TOC entry 4781 (class 2606 OID 348475)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 4793 (class 2606 OID 348477)
-- Name: audit_log_global_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_pkey PRIMARY KEY (id);


--
-- TOC entry 4783 (class 2606 OID 348479)
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4799 (class 2606 OID 348481)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4801 (class 2606 OID 348483)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 4803 (class 2606 OID 348485)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 4807 (class 2606 OID 348487)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4805 (class 2606 OID 348489)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 4811 (class 2606 OID 348491)
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- TOC entry 4813 (class 2606 OID 348493)
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- TOC entry 4815 (class 2606 OID 348495)
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- TOC entry 4809 (class 2606 OID 348497)
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- TOC entry 4817 (class 2606 OID 348499)
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- TOC entry 4820 (class 2606 OID 348501)
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- TOC entry 4823 (class 2606 OID 348503)
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- TOC entry 4825 (class 2606 OID 348505)
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4833 (class 2606 OID 348507)
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 4838 (class 2606 OID 348509)
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- TOC entry 4842 (class 2606 OID 348511)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 4844 (class 2606 OID 348513)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4846 (class 2606 OID 348515)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 4848 (class 2606 OID 348517)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 4852 (class 2606 OID 348519)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 4854 (class 2606 OID 348521)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 4857 (class 2606 OID 348523)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 4859 (class 2606 OID 348525)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4864 (class 2606 OID 348527)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4866 (class 2606 OID 348529)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4868 (class 2606 OID 348531)
-- Name: cat_uom_conversion_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4873 (class 2606 OID 348533)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4875 (class 2606 OID 348535)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 4877 (class 2606 OID 348537)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 4879 (class 2606 OID 348539)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 4881 (class 2606 OID 348541)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 4885 (class 2606 OID 348543)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4887 (class 2606 OID 348545)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4889 (class 2606 OID 348547)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 4893 (class 2606 OID 348549)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4897 (class 2606 OID 348551)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4900 (class 2606 OID 348553)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 4902 (class 2606 OID 348555)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4905 (class 2606 OID 348557)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4908 (class 2606 OID 348559)
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- TOC entry 4910 (class 2606 OID 348561)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4914 (class 2606 OID 348563)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4916 (class 2606 OID 348565)
-- Name: insumo_proveedor_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4912 (class 2606 OID 348567)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 4929 (class 2606 OID 348569)
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4934 (class 2606 OID 348571)
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4922 (class 2606 OID 348573)
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4927 (class 2606 OID 348575)
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- TOC entry 4937 (class 2606 OID 348577)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 4939 (class 2606 OID 348579)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4944 (class 2606 OID 348581)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 4950 (class 2606 OID 348583)
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4955 (class 2606 OID 348585)
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- TOC entry 4957 (class 2606 OID 348587)
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- TOC entry 4968 (class 2606 OID 348589)
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- TOC entry 4972 (class 2606 OID 348591)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 4974 (class 2606 OID 348593)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4976 (class 2606 OID 348595)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 4978 (class 2606 OID 348597)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4980 (class 2606 OID 348599)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 4985 (class 2606 OID 348601)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 4997 (class 2606 OID 348603)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 5000 (class 2606 OID 348605)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 5002 (class 2606 OID 348607)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 5004 (class 2606 OID 348609)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 5008 (class 2606 OID 348611)
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- TOC entry 5010 (class 2606 OID 348613)
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 5014 (class 2606 OID 348615)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 5016 (class 2606 OID 348617)
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 5020 (class 2606 OID 348619)
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- TOC entry 5024 (class 2606 OID 348621)
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 5032 (class 2606 OID 348623)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 5034 (class 2606 OID 348625)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 5037 (class 2606 OID 348627)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 5040 (class 2606 OID 348629)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 5042 (class 2606 OID 348631)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 5044 (class 2606 OID 348633)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 5058 (class 2606 OID 348635)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 5079 (class 2606 OID 348637)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5083 (class 2606 OID 348639)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 5085 (class 2606 OID 348641)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5087 (class 2606 OID 348643)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 5090 (class 2606 OID 348645)
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- TOC entry 5092 (class 2606 OID 348647)
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 5095 (class 2606 OID 348649)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 5097 (class 2606 OID 348651)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 5099 (class 2606 OID 348653)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 5102 (class 2606 OID 348655)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5104 (class 2606 OID 348657)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 5106 (class 2606 OID 348659)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 5108 (class 2606 OID 348661)
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 5110 (class 2606 OID 348663)
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 4964 (class 2606 OID 348665)
-- Name: pk_inventory_snapshot; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT pk_inventory_snapshot PRIMARY KEY (snapshot_date, branch_id, item_id);


--
-- TOC entry 5116 (class 2606 OID 348667)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 5119 (class 2606 OID 348669)
-- Name: pos_modifiers_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pkey PRIMARY KEY (id);


--
-- TOC entry 5121 (class 2606 OID 348671)
-- Name: pos_modifiers_map_pos_modifier_code_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pos_modifier_code_key UNIQUE (pos_modifier_code);


--
-- TOC entry 5126 (class 2606 OID 348673)
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5131 (class 2606 OID 348675)
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5133 (class 2606 OID 348677)
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 5135 (class 2606 OID 348679)
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5141 (class 2606 OID 348681)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 5152 (class 2606 OID 348683)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 5156 (class 2606 OID 348685)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 5146 (class 2606 OID 348687)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 5158 (class 2606 OID 348689)
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5160 (class 2606 OID 348691)
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5164 (class 2606 OID 348693)
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 5169 (class 2606 OID 348695)
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- TOC entry 5174 (class 2606 OID 348697)
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 5177 (class 2606 OID 348699)
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 5182 (class 2606 OID 348701)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 5185 (class 2606 OID 348703)
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 5191 (class 2606 OID 348705)
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5194 (class 2606 OID 348707)
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 5196 (class 2606 OID 348709)
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 5200 (class 2606 OID 348711)
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5207 (class 2606 OID 348713)
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- TOC entry 5209 (class 2606 OID 348715)
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 5215 (class 2606 OID 348717)
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5223 (class 2606 OID 348719)
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 5228 (class 2606 OID 348721)
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5233 (class 2606 OID 348723)
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- TOC entry 5236 (class 2606 OID 348725)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5238 (class 2606 OID 348727)
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- TOC entry 5242 (class 2606 OID 348729)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5248 (class 2606 OID 348731)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5065 (class 2606 OID 348733)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 5067 (class 2606 OID 348735)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5250 (class 2606 OID 348737)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 5069 (class 2606 OID 348739)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5258 (class 2606 OID 348741)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 5260 (class 2606 OID 348743)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, item_id);


--
-- TOC entry 5252 (class 2606 OID 348745)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 5262 (class 2606 OID 348747)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 5073 (class 2606 OID 348749)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 5075 (class 2606 OID 348751)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 5265 (class 2606 OID 348753)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5269 (class 2606 OID 348755)
-- Name: recipe_cost_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT recipe_cost_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 5272 (class 2606 OID 348757)
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5275 (class 2606 OID 348759)
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- TOC entry 5279 (class 2606 OID 348761)
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 5281 (class 2606 OID 348763)
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- TOC entry 5284 (class 2606 OID 348765)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 5286 (class 2606 OID 348767)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 5291 (class 2606 OID 348769)
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 5294 (class 2606 OID 348771)
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 5302 (class 2606 OID 348773)
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 5307 (class 2606 OID 348775)
-- Name: report_favorites_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites
    ADD CONSTRAINT report_favorites_pkey PRIMARY KEY (id);


--
-- TOC entry 5311 (class 2606 OID 348777)
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- TOC entry 5313 (class 2606 OID 348779)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 5315 (class 2606 OID 348781)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 5317 (class 2606 OID 348783)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 5319 (class 2606 OID 348785)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 5321 (class 2606 OID 348787)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 5018 (class 2606 OID 348789)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- TOC entry 5022 (class 2606 OID 348791)
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- TOC entry 5026 (class 2606 OID 348793)
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- TOC entry 5225 (class 2606 OID 348795)
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 5304 (class 2606 OID 348797)
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- TOC entry 5326 (class 2606 OID 348799)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 5328 (class 2606 OID 348801)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 5331 (class 2606 OID 348803)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 5334 (class 2606 OID 348805)
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5336 (class 2606 OID 348807)
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5341 (class 2606 OID 348809)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 5346 (class 2606 OID 348811)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 5343 (class 2606 OID 348813)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 5351 (class 2606 OID 348815)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 5353 (class 2606 OID 348817)
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 5358 (class 2606 OID 348819)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 5360 (class 2606 OID 348821)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5362 (class 2606 OID 348823)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5364 (class 2606 OID 348825)
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5366 (class 2606 OID 348827)
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5369 (class 2606 OID 348829)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 5373 (class 2606 OID 348831)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5375 (class 2606 OID 348833)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 5377 (class 2606 OID 348835)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 5379 (class 2606 OID 348837)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 5381 (class 2606 OID 348839)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 5383 (class 2606 OID 348841)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 5385 (class 2606 OID 348843)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 5143 (class 2606 OID 348845)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 5149 (class 2606 OID 348847)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 5217 (class 2606 OID 348849)
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- TOC entry 5387 (class 2606 OID 348851)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 5389 (class 2606 OID 348853)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5391 (class 2606 OID 348855)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 5393 (class 2606 OID 348857)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 5395 (class 2606 OID 348859)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


SET search_path = public, pg_catalog;

--
-- TOC entry 4612 (class 1259 OID 348860)
-- Name: creationhour; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX creationhour ON ticket USING btree (creation_hour);


--
-- TOC entry 4613 (class 1259 OID 348861)
-- Name: deliverydate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX deliverydate ON ticket USING btree (deliveery_date);


--
-- TOC entry 4580 (class 1259 OID 348862)
-- Name: drawer_report_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawer_report_time ON drawer_pull_report USING btree (report_time);


--
-- TOC entry 4614 (class 1259 OID 348863)
-- Name: drawerresetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawerresetted ON ticket USING btree (drawer_resetted);


--
-- TOC entry 4634 (class 1259 OID 348864)
-- Name: food_category_visible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX food_category_visible ON menu_category USING btree (visible);


--
-- TOC entry 4714 (class 1259 OID 348865)
-- Name: fromdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX fromdate ON table_booking_info USING btree (from_date);


--
-- TOC entry 4576 (class 1259 OID 348866)
-- Name: idx_dah_user_op_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_dah_user_op_time ON drawer_assigned_history USING btree (a_user, operation, "time" DESC);


--
-- TOC entry 4577 (class 1259 OID 348867)
-- Name: idx_drawer_assigned_history_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_drawer_assigned_history_user_time ON drawer_assigned_history USING btree (a_user, "time");


--
-- TOC entry 4615 (class 1259 OID 348868)
-- Name: idx_ticket_close_term_owner; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_close_term_owner ON ticket USING btree (closing_date, terminal_id, owner_id);


--
-- TOC entry 4745 (class 1259 OID 348869)
-- Name: idx_tx_term_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_tx_term_user_time ON transactions USING btree (terminal_id, user_id, transaction_time);


--
-- TOC entry 4631 (class 1259 OID 348870)
-- Name: ix_kitchen_ticket_item_item_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_item_item_id ON kitchen_ticket_item USING btree (ticket_item_id);


--
-- TOC entry 4607 (class 1259 OID 348871)
-- Name: ix_kitchen_ticket_ticket_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_ticket_id ON kitchen_ticket USING btree (ticket_id);


--
-- TOC entry 4616 (class 1259 OID 348872)
-- Name: ix_ticket_branch_key; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_branch_key ON ticket USING btree (branch_key);


--
-- TOC entry 4617 (class 1259 OID 348873)
-- Name: ix_ticket_folio_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_folio_date ON ticket USING btree (folio_date);


--
-- TOC entry 4728 (class 1259 OID 348874)
-- Name: ix_ticket_item_ticket_pg; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_item_ticket_pg ON ticket_item USING btree (ticket_id, pg_id);


--
-- TOC entry 4639 (class 1259 OID 348875)
-- Name: menugroupvisible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX menugroupvisible ON menu_group USING btree (visible);


--
-- TOC entry 4651 (class 1259 OID 348876)
-- Name: mg_enable; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX mg_enable ON menu_modifier_group USING btree (enabled);


--
-- TOC entry 4648 (class 1259 OID 348877)
-- Name: modifierenabled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX modifierenabled ON menu_modifier USING btree (enable);


--
-- TOC entry 4622 (class 1259 OID 348878)
-- Name: ticketactivedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketactivedate ON ticket USING btree (active_date);


--
-- TOC entry 4623 (class 1259 OID 348879)
-- Name: ticketclosingdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketclosingdate ON ticket USING btree (closing_date);


--
-- TOC entry 4624 (class 1259 OID 348880)
-- Name: ticketcreatedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketcreatedate ON ticket USING btree (create_date);


--
-- TOC entry 4625 (class 1259 OID 348881)
-- Name: ticketpaid; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketpaid ON ticket USING btree (paid);


--
-- TOC entry 4626 (class 1259 OID 348882)
-- Name: ticketsettled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketsettled ON ticket USING btree (settled);


--
-- TOC entry 4627 (class 1259 OID 348883)
-- Name: ticketvoided; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketvoided ON ticket USING btree (voided);


--
-- TOC entry 4717 (class 1259 OID 348884)
-- Name: todate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX todate ON table_booking_info USING btree (to_date);


--
-- TOC entry 4746 (class 1259 OID 348885)
-- Name: tran_drawer_resetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX tran_drawer_resetted ON transactions USING btree (drawer_resetted);


--
-- TOC entry 4628 (class 1259 OID 348886)
-- Name: ux_ticket_dailyfolio; Type: INDEX; Schema: public; Owner: floreant
--

CREATE UNIQUE INDEX ux_ticket_dailyfolio ON ticket USING btree (folio_date, branch_key, daily_folio) WHERE (daily_folio IS NOT NULL);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4818 (class 1259 OID 348887)
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON cash_fund_arqueos USING btree (cash_fund_id);


--
-- TOC entry 4821 (class 1259 OID 348888)
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON cash_fund_arqueos USING btree (created_by_user_id);


--
-- TOC entry 4829 (class 1259 OID 348889)
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON cash_fund_movements USING btree (cash_fund_id);


--
-- TOC entry 4830 (class 1259 OID 348890)
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON cash_fund_movements USING btree (created_by_user_id);


--
-- TOC entry 4831 (class 1259 OID 348891)
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON cash_fund_movements USING btree (estatus);


--
-- TOC entry 4834 (class 1259 OID 348892)
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON cash_fund_movements USING btree (tipo);


--
-- TOC entry 4835 (class 1259 OID 348893)
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON cash_funds USING btree (estado);


--
-- TOC entry 4836 (class 1259 OID 348894)
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON cash_funds USING btree (fecha);


--
-- TOC entry 4839 (class 1259 OID 348895)
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON cash_funds USING btree (responsable_user_id);


--
-- TOC entry 4840 (class 1259 OID 348896)
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON cash_funds USING btree (sucursal_id);


--
-- TOC entry 4778 (class 1259 OID 348897)
-- Name: idx_alertas_cortes_destinatario; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_destinatario ON alertas_cortes USING btree (destinatario_id, leida);


--
-- TOC entry 4779 (class 1259 OID 348898)
-- Name: idx_alertas_cortes_postcorte; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_postcorte ON alertas_cortes USING btree (postcorte_id);


--
-- TOC entry 4784 (class 1259 OID 348899)
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON audit_log USING btree (accion);


--
-- TOC entry 4785 (class 1259 OID 348900)
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON audit_log USING btree (entidad);


--
-- TOC entry 4786 (class 1259 OID 348901)
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON audit_log USING btree (entidad_id);


--
-- TOC entry 4794 (class 1259 OID 348902)
-- Name: idx_audit_log_global_changed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_changed_at ON audit_log_global USING btree (changed_at);


--
-- TOC entry 4795 (class 1259 OID 348903)
-- Name: idx_audit_log_global_operation; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_operation ON audit_log_global USING btree (operation);


--
-- TOC entry 4796 (class 1259 OID 348904)
-- Name: idx_audit_log_global_table; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_table ON audit_log_global USING btree (table_name);


--
-- TOC entry 4797 (class 1259 OID 348905)
-- Name: idx_audit_log_global_user; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_user ON audit_log_global USING btree (changed_by_user_id);


--
-- TOC entry 4787 (class 1259 OID 348906)
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON audit_log USING btree ("timestamp");


--
-- TOC entry 4788 (class 1259 OID 348907)
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON audit_log USING btree (user_id);


--
-- TOC entry 4855 (class 1259 OID 348908)
-- Name: idx_cat_sucursales_pos_location; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_sucursales_pos_location ON cat_sucursales USING btree (pos_location);


--
-- TOC entry 4860 (class 1259 OID 348909)
-- Name: idx_cat_unidades_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_activo ON cat_unidades USING btree (activo);


--
-- TOC entry 4861 (class 1259 OID 348910)
-- Name: idx_cat_unidades_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_categoria ON cat_unidades USING btree (categoria);


--
-- TOC entry 4862 (class 1259 OID 348911)
-- Name: idx_cat_unidades_clave; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_clave ON cat_unidades USING btree (clave);


--
-- TOC entry 4869 (class 1259 OID 348912)
-- Name: idx_cat_uom_conversion_destino; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_destino ON cat_uom_conversion USING btree (destino_id);


--
-- TOC entry 4870 (class 1259 OID 348913)
-- Name: idx_cat_uom_conversion_origen; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_origen ON cat_uom_conversion USING btree (origen_id);


--
-- TOC entry 4871 (class 1259 OID 348914)
-- Name: idx_cat_uom_conversion_scope; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_scope ON cat_uom_conversion USING btree (scope);


--
-- TOC entry 4903 (class 1259 OID 348915)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4940 (class 1259 OID 348916)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 4941 (class 1259 OID 348917)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 4942 (class 1259 OID 348918)
-- Name: idx_inventory_batch_item_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item_estado ON inventory_batch USING btree (item_id, estado);


--
-- TOC entry 4960 (class 1259 OID 348919)
-- Name: idx_invshot_branch_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_branch_date ON inventory_snapshot USING btree (branch_id, snapshot_date);


--
-- TOC entry 4961 (class 1259 OID 348920)
-- Name: idx_invshot_item_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_item_date ON inventory_snapshot USING btree (item_id, snapshot_date);


--
-- TOC entry 4962 (class 1259 OID 348921)
-- Name: idx_invshot_variance; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_variance ON inventory_snapshot USING btree (snapshot_date, branch_id, variance_qty);


--
-- TOC entry 4989 (class 1259 OID 348922)
-- Name: idx_items_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo ON items USING btree (activo) WHERE (activo = true);


--
-- TOC entry 4990 (class 1259 OID 348923)
-- Name: idx_items_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo_categoria ON items USING btree (activo, categoria_id) WHERE (activo = true);


--
-- TOC entry 4991 (class 1259 OID 348924)
-- Name: idx_items_categoria_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_categoria_id ON items USING btree (categoria_id);


--
-- TOC entry 4992 (class 1259 OID 348925)
-- Name: idx_items_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_nombre_lower ON items USING btree (lower((nombre)::text));


--
-- TOC entry 4993 (class 1259 OID 348926)
-- Name: idx_items_unidad_compra_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_compra_id ON items USING btree (unidad_compra_id) WHERE ((activo = true) AND (unidad_compra_id IS NOT NULL));


--
-- TOC entry 4994 (class 1259 OID 348927)
-- Name: idx_items_unidad_medida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_medida_id ON items USING btree (unidad_medida_id) WHERE (activo = true);


--
-- TOC entry 4995 (class 1259 OID 348928)
-- Name: idx_items_unidad_salida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_salida_id ON items USING btree (unidad_salida_id) WHERE ((activo = true) AND (unidad_salida_id IS NOT NULL));


--
-- TOC entry 5027 (class 1259 OID 348929)
-- Name: idx_merma_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_batch_id ON merma USING btree (batch_id);


--
-- TOC entry 5028 (class 1259 OID 348930)
-- Name: idx_merma_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_deleted_at ON merma USING btree (deleted_at);


--
-- TOC entry 5029 (class 1259 OID 348931)
-- Name: idx_merma_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_item_id ON merma USING btree (item_id);


--
-- TOC entry 5030 (class 1259 OID 348932)
-- Name: idx_merma_usuario_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_usuario_id ON merma USING btree (usuario_id);


--
-- TOC entry 5045 (class 1259 OID 348933)
-- Name: idx_mov_inv_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 5046 (class 1259 OID 348934)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 5047 (class 1259 OID 348935)
-- Name: idx_mov_inv_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 5048 (class 1259 OID 348936)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 5049 (class 1259 OID 348937)
-- Name: idx_mov_inv_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts ON mov_inv USING btree (ts);


--
-- TOC entry 5050 (class 1259 OID 348938)
-- Name: idx_mov_inv_ts_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts_tipo ON mov_inv USING btree (ts, tipo);


--
-- TOC entry 5077 (class 1259 OID 348939)
-- Name: idx_op_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_cab_deleted_at ON op_cab USING btree (deleted_at);


--
-- TOC entry 5080 (class 1259 OID 348940)
-- Name: idx_op_insumo_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_batch_id ON op_insumo USING btree (batch_id);


--
-- TOC entry 5081 (class 1259 OID 348941)
-- Name: idx_op_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_item_id ON op_insumo USING btree (item_id);


--
-- TOC entry 5100 (class 1259 OID 348942)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 5112 (class 1259 OID 348943)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 5122 (class 1259 OID 348944)
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON pos_reprocess_log USING btree (reprocessed_at);


--
-- TOC entry 5123 (class 1259 OID 348945)
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON pos_reprocess_log USING btree (ticket_id);


--
-- TOC entry 5124 (class 1259 OID 348946)
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON pos_reprocess_log USING btree (user_id);


--
-- TOC entry 5127 (class 1259 OID 348947)
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON pos_reverse_log USING btree (reversed_at);


--
-- TOC entry 5128 (class 1259 OID 348948)
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON pos_reverse_log USING btree (ticket_id);


--
-- TOC entry 5129 (class 1259 OID 348949)
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON pos_reverse_log USING btree (user_id);


--
-- TOC entry 5117 (class 1259 OID 348950)
-- Name: idx_posmod_active_valid; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_posmod_active_valid ON pos_modifiers_map USING btree (active, valid_from, (COALESCE(valid_to, '2999-12-31'::date)));


--
-- TOC entry 5138 (class 1259 OID 348951)
-- Name: idx_postcorte_requiere_aprobacion; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_requiere_aprobacion ON postcorte USING btree (requiere_aprobacion) WHERE (requiere_aprobacion = true);


--
-- TOC entry 5139 (class 1259 OID 348952)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 5150 (class 1259 OID 348953)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 5153 (class 1259 OID 348954)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 5144 (class 1259 OID 348955)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 5203 (class 1259 OID 348956)
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON purchase_requests USING btree (fecha_requerida);


--
-- TOC entry 5204 (class 1259 OID 348957)
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON purchase_requests USING btree (urgente);


--
-- TOC entry 4849 (class 1259 OID 348958)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 4850 (class 1259 OID 348959)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 5218 (class 1259 OID 348960)
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON purchase_suggestions USING btree (estado);


--
-- TOC entry 5219 (class 1259 OID 348961)
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON purchase_suggestions USING btree (sugerido_en);


--
-- TOC entry 5220 (class 1259 OID 348962)
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON purchase_suggestions USING btree (prioridad);


--
-- TOC entry 5221 (class 1259 OID 348963)
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON purchase_suggestions USING btree (sucursal_id, estado);


--
-- TOC entry 5212 (class 1259 OID 348964)
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON purchase_suggestion_lines USING btree (item_id);


--
-- TOC entry 5213 (class 1259 OID 348965)
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON purchase_suggestion_lines USING btree (suggestion_id);


--
-- TOC entry 5240 (class 1259 OID 348966)
-- Name: idx_recepcion_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_cab_deleted_at ON recepcion_cab USING btree (deleted_at);


--
-- TOC entry 5244 (class 1259 OID 348967)
-- Name: idx_recepcion_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_batch_id ON recepcion_det USING btree (batch_id);


--
-- TOC entry 5245 (class 1259 OID 348968)
-- Name: idx_recepcion_det_bodega_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_bodega_id ON recepcion_det USING btree (bodega_id);


--
-- TOC entry 5246 (class 1259 OID 348969)
-- Name: idx_recepcion_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_item_id ON recepcion_det USING btree (item_id);


--
-- TOC entry 5060 (class 1259 OID 348970)
-- Name: idx_receta_cab_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo ON receta_cab USING btree (activo) WHERE (activo = true);


--
-- TOC entry 5061 (class 1259 OID 348971)
-- Name: idx_receta_cab_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo_categoria ON receta_cab USING btree (activo, categoria_plato) WHERE (activo = true);


--
-- TOC entry 5062 (class 1259 OID 348972)
-- Name: idx_receta_cab_categoria_plato; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_categoria_plato ON receta_cab USING btree (categoria_plato);


--
-- TOC entry 5063 (class 1259 OID 348973)
-- Name: idx_receta_cab_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_nombre_lower ON receta_cab USING btree (lower((nombre_plato)::text));


--
-- TOC entry 5253 (class 1259 OID 348974)
-- Name: idx_receta_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_item_id ON receta_insumo USING btree (item_id);


--
-- TOC entry 5254 (class 1259 OID 348975)
-- Name: idx_receta_insumo_receta_version_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_receta_version_id ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 5070 (class 1259 OID 348976)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 5266 (class 1259 OID 348977)
-- Name: idx_recipe_cost_snap_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_date ON recipe_cost_snapshots USING btree (snapshot_date DESC);


--
-- TOC entry 5267 (class 1259 OID 348978)
-- Name: idx_recipe_cost_snap_recipe_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_recipe_date ON recipe_cost_snapshots USING btree (recipe_id, snapshot_date DESC);


--
-- TOC entry 5305 (class 1259 OID 348979)
-- Name: idx_report_key; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_key ON report_favorites USING btree (report_key);


--
-- TOC entry 5309 (class 1259 OID 348980)
-- Name: idx_report_runs_report_status; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_runs_report_status ON report_runs USING btree (report_id, status);


--
-- TOC entry 5322 (class 1259 OID 348981)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 5337 (class 1259 OID 348982)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 5338 (class 1259 OID 348983)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 5344 (class 1259 OID 348984)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 5347 (class 1259 OID 348985)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 5348 (class 1259 OID 348986)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 5349 (class 1259 OID 348987)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 5356 (class 1259 OID 348988)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 5367 (class 1259 OID 348989)
-- Name: idx_traspaso_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_cab_deleted_at ON traspaso_cab USING btree (deleted_at);


--
-- TOC entry 5370 (class 1259 OID 348990)
-- Name: idx_traspaso_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_batch_id ON traspaso_det USING btree (batch_id);


--
-- TOC entry 5371 (class 1259 OID 348991)
-- Name: idx_traspaso_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_item_id ON traspaso_det USING btree (item_id);


--
-- TOC entry 4906 (class 1259 OID 348992)
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- TOC entry 4930 (class 1259 OID 348993)
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON inv_consumo_pos_det USING btree (procesado);


--
-- TOC entry 4931 (class 1259 OID 348994)
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- TOC entry 4932 (class 1259 OID 348995)
-- Name: inv_consumo_pos_det_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_revertido_idx ON inv_consumo_pos_det USING btree (revertido);


--
-- TOC entry 4935 (class 1259 OID 348996)
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON inv_consumo_pos_log USING btree (ticket_id);


--
-- TOC entry 4923 (class 1259 OID 348997)
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON inv_consumo_pos USING btree (procesado);


--
-- TOC entry 4924 (class 1259 OID 348998)
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON inv_consumo_pos USING btree (requiere_reproceso);


--
-- TOC entry 4925 (class 1259 OID 348999)
-- Name: inv_consumo_pos_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_revertido_idx ON inv_consumo_pos USING btree (revertido);


--
-- TOC entry 4946 (class 1259 OID 349000)
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON inventory_count_lines USING btree (inventory_batch_id);


--
-- TOC entry 4947 (class 1259 OID 349001)
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON inventory_count_lines USING btree (inventory_count_id);


--
-- TOC entry 4948 (class 1259 OID 349002)
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON inventory_count_lines USING btree (item_id);


--
-- TOC entry 4951 (class 1259 OID 349003)
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON inventory_counts USING btree (almacen_id);


--
-- TOC entry 4952 (class 1259 OID 349004)
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON inventory_counts USING btree (cerrado_en);


--
-- TOC entry 4953 (class 1259 OID 349005)
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON inventory_counts USING btree (estado);


--
-- TOC entry 4958 (class 1259 OID 349006)
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON inventory_counts USING btree (programado_para);


--
-- TOC entry 4959 (class 1259 OID 349007)
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON inventory_counts USING btree (sucursal_id);


--
-- TOC entry 4965 (class 1259 OID 349008)
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON inventory_wastes USING btree (inventory_batch_id);


--
-- TOC entry 4966 (class 1259 OID 349009)
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON inventory_wastes USING btree (item_id);


--
-- TOC entry 4969 (class 1259 OID 349010)
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON inventory_wastes USING btree (production_order_id);


--
-- TOC entry 4970 (class 1259 OID 349011)
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON inventory_wastes USING btree (sucursal_id);


--
-- TOC entry 4917 (class 1259 OID 349012)
-- Name: ipp_activo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_activo_idx ON insumo_proveedor_presentacion USING btree (activo);


--
-- TOC entry 4918 (class 1259 OID 349013)
-- Name: ipp_insumo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_insumo_idx ON insumo_proveedor_presentacion USING btree (item_id);


--
-- TOC entry 4919 (class 1259 OID 349014)
-- Name: ipp_proveedor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_proveedor_idx ON insumo_proveedor_presentacion USING btree (proveedor_id);


--
-- TOC entry 4920 (class 1259 OID 349015)
-- Name: ipp_uni; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ipp_uni ON insumo_proveedor_presentacion USING btree (item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra);


--
-- TOC entry 4773 (class 1259 OID 349016)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 4890 (class 1259 OID 349017)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 4894 (class 1259 OID 349018)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4898 (class 1259 OID 349019)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 4945 (class 1259 OID 349020)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 4981 (class 1259 OID 349021)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 4982 (class 1259 OID 349022)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 4986 (class 1259 OID 349023)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 4987 (class 1259 OID 349024)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 4988 (class 1259 OID 349025)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 4882 (class 1259 OID 349026)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 4883 (class 1259 OID 349027)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 5011 (class 1259 OID 349028)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 5012 (class 1259 OID 349029)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (item_id);


--
-- TOC entry 5051 (class 1259 OID 349030)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 5052 (class 1259 OID 349031)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 5053 (class 1259 OID 349032)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 5054 (class 1259 OID 349033)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 5055 (class 1259 OID 349034)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 5056 (class 1259 OID 349035)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 5113 (class 1259 OID 349036)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 5114 (class 1259 OID 349037)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 5154 (class 1259 OID 349038)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 5263 (class 1259 OID 349039)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 5255 (class 1259 OID 349040)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (item_id);


--
-- TOC entry 5256 (class 1259 OID 349041)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 5071 (class 1259 OID 349042)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 5282 (class 1259 OID 349043)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 5323 (class 1259 OID 349044)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 5324 (class 1259 OID 349045)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 5339 (class 1259 OID 349046)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 5005 (class 1259 OID 349047)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 5006 (class 1259 OID 349048)
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON labor_roles USING btree (activo);


--
-- TOC entry 5035 (class 1259 OID 349049)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 5038 (class 1259 OID 349050)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 5059 (class 1259 OID 349051)
-- Name: mv_inventario_actual_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_inventario_actual_item_id_idx ON mv_inventario_actual USING btree (item_id);


--
-- TOC entry 5076 (class 1259 OID 349052)
-- Name: mv_recetas_costos_receta_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_recetas_costos_receta_id_idx ON mv_recetas_costos USING btree (receta_id);


--
-- TOC entry 5088 (class 1259 OID 349053)
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON overhead_definitions USING btree (activo);


--
-- TOC entry 5093 (class 1259 OID 349054)
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON overhead_definitions USING btree (tipo);


--
-- TOC entry 5111 (class 1259 OID 349055)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 5147 (class 1259 OID 349056)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 5161 (class 1259 OID 349057)
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON production_order_inputs USING btree (inventory_batch_id);


--
-- TOC entry 5162 (class 1259 OID 349058)
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON production_order_inputs USING btree (item_id);


--
-- TOC entry 5165 (class 1259 OID 349059)
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON production_order_inputs USING btree (production_order_id);


--
-- TOC entry 5166 (class 1259 OID 349060)
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON production_order_outputs USING btree (inventory_batch_id);


--
-- TOC entry 5167 (class 1259 OID 349061)
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON production_order_outputs USING btree (item_id);


--
-- TOC entry 5170 (class 1259 OID 349062)
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON production_order_outputs USING btree (production_order_id);


--
-- TOC entry 5171 (class 1259 OID 349063)
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON production_orders USING btree (almacen_id);


--
-- TOC entry 5172 (class 1259 OID 349064)
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON production_orders USING btree (estado);


--
-- TOC entry 5175 (class 1259 OID 349065)
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON production_orders USING btree (item_id);


--
-- TOC entry 5178 (class 1259 OID 349066)
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON production_orders USING btree (programado_para);


--
-- TOC entry 5179 (class 1259 OID 349067)
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON production_orders USING btree (recipe_id);


--
-- TOC entry 5180 (class 1259 OID 349068)
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON production_orders USING btree (sucursal_id);


--
-- TOC entry 5183 (class 1259 OID 349069)
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON purchase_documents USING btree (order_id);


--
-- TOC entry 5186 (class 1259 OID 349070)
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON purchase_documents USING btree (quote_id);


--
-- TOC entry 5187 (class 1259 OID 349071)
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON purchase_documents USING btree (request_id);


--
-- TOC entry 5188 (class 1259 OID 349072)
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON purchase_order_lines USING btree (item_id);


--
-- TOC entry 5189 (class 1259 OID 349073)
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON purchase_order_lines USING btree (order_id);


--
-- TOC entry 5192 (class 1259 OID 349074)
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON purchase_orders USING btree (estado);


--
-- TOC entry 5197 (class 1259 OID 349075)
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON purchase_orders USING btree (vendor_id);


--
-- TOC entry 5198 (class 1259 OID 349076)
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON purchase_request_lines USING btree (item_id);


--
-- TOC entry 5201 (class 1259 OID 349077)
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON purchase_request_lines USING btree (preferred_vendor_id);


--
-- TOC entry 5202 (class 1259 OID 349078)
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON purchase_request_lines USING btree (request_id);


--
-- TOC entry 5205 (class 1259 OID 349079)
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON purchase_requests USING btree (estado);


--
-- TOC entry 5210 (class 1259 OID 349080)
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON purchase_requests USING btree (requested_at);


--
-- TOC entry 5211 (class 1259 OID 349081)
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON purchase_requests USING btree (sucursal_id);


--
-- TOC entry 5226 (class 1259 OID 349082)
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON purchase_vendor_quote_lines USING btree (item_id);


--
-- TOC entry 5229 (class 1259 OID 349083)
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON purchase_vendor_quote_lines USING btree (quote_id);


--
-- TOC entry 5230 (class 1259 OID 349084)
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON purchase_vendor_quote_lines USING btree (request_line_id);


--
-- TOC entry 5231 (class 1259 OID 349085)
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON purchase_vendor_quotes USING btree (estado);


--
-- TOC entry 5234 (class 1259 OID 349086)
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- TOC entry 5239 (class 1259 OID 349087)
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON recepcion_adjuntos USING btree (recepcion_id);


--
-- TOC entry 5270 (class 1259 OID 349088)
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 5273 (class 1259 OID 349089)
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON recipe_labor_steps USING btree (labor_role_id);


--
-- TOC entry 5276 (class 1259 OID 349090)
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON recipe_labor_steps USING btree (recipe_id);


--
-- TOC entry 5277 (class 1259 OID 349091)
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON recipe_overhead_allocations USING btree (overhead_id);


--
-- TOC entry 5288 (class 1259 OID 349092)
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON replenishment_suggestions USING btree (estado);


--
-- TOC entry 5289 (class 1259 OID 349093)
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- TOC entry 5292 (class 1259 OID 349094)
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- TOC entry 5295 (class 1259 OID 349095)
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON replenishment_suggestions USING btree (prioridad);


--
-- TOC entry 5296 (class 1259 OID 349096)
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON replenishment_suggestions USING btree (production_order_id);


--
-- TOC entry 5297 (class 1259 OID 349097)
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON replenishment_suggestions USING btree (purchase_request_id);


--
-- TOC entry 5298 (class 1259 OID 349098)
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON replenishment_suggestions USING btree (revisado_por);


--
-- TOC entry 5299 (class 1259 OID 349099)
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON replenishment_suggestions USING btree (sugerido_en);


--
-- TOC entry 5300 (class 1259 OID 349100)
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON replenishment_suggestions USING btree (tipo);


--
-- TOC entry 5308 (class 1259 OID 349101)
-- Name: report_favorites_user_id_report_key_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX report_favorites_user_id_report_key_unique ON report_favorites USING btree (user_id, report_key);


--
-- TOC entry 4789 (class 1259 OID 349102)
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON audit_log USING btree (entidad, entidad_id);


--
-- TOC entry 4790 (class 1259 OID 349103)
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON audit_log USING btree ("timestamp");


--
-- TOC entry 4791 (class 1259 OID 349104)
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON audit_log USING btree (user_id);


--
-- TOC entry 4826 (class 1259 OID 349105)
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON cash_fund_movement_audit_log USING btree (action);


--
-- TOC entry 4827 (class 1259 OID 349106)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- TOC entry 4828 (class 1259 OID 349107)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON cash_fund_movement_audit_log USING btree (movement_id);


--
-- TOC entry 5136 (class 1259 OID 349108)
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON pos_sync_logs USING btree (batch_id, status);


--
-- TOC entry 5137 (class 1259 OID 349109)
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON pos_sync_logs USING btree (external_id);


--
-- TOC entry 5243 (class 1259 OID 349110)
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON recepcion_cab USING btree (almacen_id);


--
-- TOC entry 5329 (class 1259 OID 349111)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 5332 (class 1259 OID 349112)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 5354 (class 1259 OID 349113)
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON ticket_item_modifiers USING btree (ticket_id);


--
-- TOC entry 5355 (class 1259 OID 349114)
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON ticket_item_modifiers USING btree (ticket_item_id);


--
-- TOC entry 4891 (class 1259 OID 349115)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 4895 (class 1259 OID 349116)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 4983 (class 1259 OID 349117)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 4998 (class 1259 OID 349118)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 5287 (class 1259 OID 349119)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


SET search_path = public, pg_catalog;

--
-- TOC entry 5657 (class 2620 OID 349120)
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON ticket FOR EACH ROW EXECUTE PROCEDURE assign_daily_folio();


--
-- TOC entry 5658 (class 2620 OID 349121)
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE OF status ON kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5659 (class 2620 OID 349122)
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE OF status ON ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5655 (class 2620 OID 349123)
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();

ALTER TABLE drawer_assigned_history DISABLE TRIGGER trg_selemti_dah_ai;


--
-- TOC entry 5656 (class 2620 OID 349124)
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- TOC entry 5660 (class 2620 OID 349125)
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5665 (class 2620 OID 349126)
-- Name: trg_invshot_biur; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_invshot_biur BEFORE INSERT OR UPDATE ON inventory_snapshot FOR EACH ROW EXECUTE PROCEDURE tg_invshot_autofill();


--
-- TOC entry 5663 (class 2620 OID 349127)
-- Name: trg_ipp_set_timestamp; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ipp_set_timestamp BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE set_timestamp_ipp();


--
-- TOC entry 5666 (class 2620 OID 349128)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 5669 (class 2620 OID 349129)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 5667 (class 2620 OID 349130)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 5668 (class 2620 OID 349131)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 5673 (class 2620 OID 349132)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 5674 (class 2620 OID 349133)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 5675 (class 2620 OID 349134)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 5676 (class 2620 OID 349135)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


--
-- TOC entry 5661 (class 2620 OID 349136)
-- Name: update_hist_cost_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_hist_cost_insumo_updated_at BEFORE UPDATE ON hist_cost_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5662 (class 2620 OID 349137)
-- Name: update_insumo_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_presentacion_updated_at BEFORE UPDATE ON insumo_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5664 (class 2620 OID 349138)
-- Name: update_insumo_proveedor_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_proveedor_presentacion_updated_at BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5670 (class 2620 OID 349139)
-- Name: update_merma_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_merma_updated_at BEFORE UPDATE ON merma FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5671 (class 2620 OID 349140)
-- Name: update_op_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_cab_updated_at BEFORE UPDATE ON op_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5672 (class 2620 OID 349141)
-- Name: update_op_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_insumo_updated_at BEFORE UPDATE ON op_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5677 (class 2620 OID 349142)
-- Name: update_recepcion_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_cab_updated_at BEFORE UPDATE ON recepcion_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5678 (class 2620 OID 349143)
-- Name: update_recepcion_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_det_updated_at BEFORE UPDATE ON recepcion_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5679 (class 2620 OID 349144)
-- Name: update_traspaso_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_cab_updated_at BEFORE UPDATE ON traspaso_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5680 (class 2620 OID 349145)
-- Name: update_traspaso_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_det_updated_at BEFORE UPDATE ON traspaso_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


SET search_path = public, pg_catalog;

--
-- TOC entry 5456 (class 2606 OID 349146)
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5443 (class 2606 OID 349151)
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5466 (class 2606 OID 349156)
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5467 (class 2606 OID 349161)
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES pizza_price(id);


--
-- TOC entry 5497 (class 2606 OID 349166)
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5486 (class 2606 OID 349171)
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5406 (class 2606 OID 349176)
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5407 (class 2606 OID 349181)
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES customer(auto_id);


--
-- TOC entry 5402 (class 2606 OID 349186)
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES currency(id);


--
-- TOC entry 5403 (class 2606 OID 349191)
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES cash_drawer(id);


--
-- TOC entry 5404 (class 2606 OID 349196)
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5516 (class 2606 OID 349201)
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES user_type(id);


--
-- TOC entry 5517 (class 2606 OID 349206)
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES user_permission(name);


--
-- TOC entry 5487 (class 2606 OID 349211)
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5488 (class 2606 OID 349216)
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5463 (class 2606 OID 349221)
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5464 (class 2606 OID 349226)
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES menu_item(id);


--
-- TOC entry 5465 (class 2606 OID 349231)
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5434 (class 2606 OID 349236)
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5415 (class 2606 OID 349241)
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5416 (class 2606 OID 349246)
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5417 (class 2606 OID 349251)
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5503 (class 2606 OID 349256)
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5504 (class 2606 OID 349261)
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES ticket_item(id);


--
-- TOC entry 5396 (class 2606 OID 349266)
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5445 (class 2606 OID 349271)
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES menu_group(id);


--
-- TOC entry 5446 (class 2606 OID 349276)
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5447 (class 2606 OID 349281)
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES tax_group(id);


--
-- TOC entry 5448 (class 2606 OID 349286)
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5449 (class 2606 OID 349291)
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES recepie(id);


--
-- TOC entry 5518 (class 2606 OID 349296)
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5519 (class 2606 OID 349301)
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES user_type(id);


--
-- TOC entry 5520 (class 2606 OID 349306)
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES terminal(id);


--
-- TOC entry 5444 (class 2606 OID 349311)
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES menu_category(id);


--
-- TOC entry 5457 (class 2606 OID 349316)
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES menu_category(id);


--
-- TOC entry 5458 (class 2606 OID 349321)
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5442 (class 2606 OID 349326)
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5470 (class 2606 OID 349331)
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5471 (class 2606 OID 349336)
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5426 (class 2606 OID 349341)
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5453 (class 2606 OID 349346)
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5454 (class 2606 OID 349351)
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5455 (class 2606 OID 349356)
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5408 (class 2606 OID 349361)
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES users(auto_id);


--
-- TOC entry 5506 (class 2606 OID 349366)
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5507 (class 2606 OID 349371)
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5400 (class 2606 OID 349376)
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5509 (class 2606 OID 349381)
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5480 (class 2606 OID 349386)
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES menu_item(id);


--
-- TOC entry 5489 (class 2606 OID 349391)
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES table_booking_info(id);


--
-- TOC entry 5490 (class 2606 OID 349396)
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5412 (class 2606 OID 349401)
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5413 (class 2606 OID 349406)
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5414 (class 2606 OID 349411)
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5508 (class 2606 OID 349416)
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES ticket(id);


--
-- TOC entry 5401 (class 2606 OID 349421)
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5421 (class 2606 OID 349426)
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES inventory_group(id);


--
-- TOC entry 5422 (class 2606 OID 349431)
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5423 (class 2606 OID 349436)
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5424 (class 2606 OID 349441)
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES inventory_location(id);


--
-- TOC entry 5425 (class 2606 OID 349446)
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5483 (class 2606 OID 349451)
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES restaurant(id);


--
-- TOC entry 5481 (class 2606 OID 349456)
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES inventory_item(id);


--
-- TOC entry 5482 (class 2606 OID 349461)
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES recepie(id);


--
-- TOC entry 5472 (class 2606 OID 349466)
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES multiplier(name);


--
-- TOC entry 5473 (class 2606 OID 349471)
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5474 (class 2606 OID 349476)
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5505 (class 2606 OID 349481)
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5436 (class 2606 OID 349486)
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES users(auto_id);


--
-- TOC entry 5437 (class 2606 OID 349491)
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5438 (class 2606 OID 349496)
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5439 (class 2606 OID 349501)
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5440 (class 2606 OID 349506)
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES gratuity(id);


--
-- TOC entry 5441 (class 2606 OID 349511)
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES users(auto_id);


--
-- TOC entry 5492 (class 2606 OID 349516)
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5493 (class 2606 OID 349521)
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES shop_table_type(id);


--
-- TOC entry 5496 (class 2606 OID 349526)
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES terminal(id);


--
-- TOC entry 5498 (class 2606 OID 349531)
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5499 (class 2606 OID 349536)
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5500 (class 2606 OID 349541)
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5411 (class 2606 OID 349546)
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5494 (class 2606 OID 349551)
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5495 (class 2606 OID 349556)
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5521 (class 2606 OID 349561)
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5451 (class 2606 OID 349566)
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5452 (class 2606 OID 349571)
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5501 (class 2606 OID 349576)
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5502 (class 2606 OID 349581)
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5409 (class 2606 OID 349586)
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5410 (class 2606 OID 349591)
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5427 (class 2606 OID 349596)
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES purchase_order(id);


--
-- TOC entry 5428 (class 2606 OID 349601)
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES inventory_item(id);


--
-- TOC entry 5429 (class 2606 OID 349606)
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5430 (class 2606 OID 349611)
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5431 (class 2606 OID 349616)
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5484 (class 2606 OID 349621)
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5479 (class 2606 OID 349626)
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES printer_group(id);


--
-- TOC entry 5491 (class 2606 OID 349631)
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES shop_table_status(id);


--
-- TOC entry 5420 (class 2606 OID 349636)
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5475 (class 2606 OID 349641)
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5405 (class 2606 OID 349646)
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES customer(auto_id);


--
-- TOC entry 5485 (class 2606 OID 349651)
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES shop_floor_template(id);


--
-- TOC entry 5461 (class 2606 OID 349656)
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5462 (class 2606 OID 349661)
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5397 (class 2606 OID 349666)
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5398 (class 2606 OID 349671)
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5399 (class 2606 OID 349676)
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5468 (class 2606 OID 349681)
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5469 (class 2606 OID 349686)
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5432 (class 2606 OID 349691)
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES order_type(id);


--
-- TOC entry 5433 (class 2606 OID 349696)
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5459 (class 2606 OID 349701)
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES menu_group(id);


--
-- TOC entry 5460 (class 2606 OID 349706)
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5510 (class 2606 OID 349711)
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES transactions(id);


--
-- TOC entry 5435 (class 2606 OID 349716)
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES users(auto_id);


--
-- TOC entry 5476 (class 2606 OID 349721)
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES pizza_crust(id);


--
-- TOC entry 5477 (class 2606 OID 349726)
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES order_type(id);


--
-- TOC entry 5478 (class 2606 OID 349731)
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5418 (class 2606 OID 349736)
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES tax(id);


--
-- TOC entry 5419 (class 2606 OID 349741)
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES tax_group(id);


--
-- TOC entry 5450 (class 2606 OID 349746)
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5511 (class 2606 OID 349751)
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5512 (class 2606 OID 349756)
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5513 (class 2606 OID 349761)
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5514 (class 2606 OID 349766)
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES payout_recepients(id);


--
-- TOC entry 5515 (class 2606 OID 349771)
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES payout_reasons(id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5522 (class 2606 OID 349776)
-- Name: alertas_cortes_destinatario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_destinatario_id_fkey FOREIGN KEY (destinatario_id) REFERENCES users(id);


--
-- TOC entry 5523 (class 2606 OID 349781)
-- Name: alertas_cortes_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 5524 (class 2606 OID 349786)
-- Name: alertas_cortes_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5525 (class 2606 OID 349791)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5527 (class 2606 OID 349796)
-- Name: audit_log_global_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES users(id);


--
-- TOC entry 5528 (class 2606 OID 349801)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5529 (class 2606 OID 349806)
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES caja_fondo_mov(id) ON DELETE CASCADE;


--
-- TOC entry 5530 (class 2606 OID 349811)
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5531 (class 2606 OID 349816)
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5532 (class 2606 OID 349821)
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5533 (class 2606 OID 349826)
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5534 (class 2606 OID 349831)
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5537 (class 2606 OID 349836)
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5538 (class 2606 OID 349841)
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5539 (class 2606 OID 349846)
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5540 (class 2606 OID 349851)
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5541 (class 2606 OID 349856)
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5542 (class 2606 OID 349861)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5543 (class 2606 OID 349866)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5544 (class 2606 OID 349871)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5545 (class 2606 OID 349876)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 5546 (class 2606 OID 349881)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5547 (class 2606 OID 349886)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5548 (class 2606 OID 349891)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5549 (class 2606 OID 349896)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5565 (class 2606 OID 349901)
-- Name: fk_inventory_snapshot_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT fk_inventory_snapshot_item FOREIGN KEY (item_id) REFERENCES items(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5601 (class 2606 OID 349906)
-- Name: fk_pos_map_receta; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT fk_pos_map_receta FOREIGN KEY (receta_id) REFERENCES receta_cab(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5611 (class 2606 OID 349911)
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5612 (class 2606 OID 349916)
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE SET NULL;


--
-- TOC entry 5616 (class 2606 OID 349921)
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5617 (class 2606 OID 349926)
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES purchase_requests(id) ON DELETE SET NULL;


--
-- TOC entry 5618 (class 2606 OID 349931)
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5619 (class 2606 OID 349936)
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5620 (class 2606 OID 349941)
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5613 (class 2606 OID 349946)
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5614 (class 2606 OID 349951)
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES cat_proveedores(id) ON DELETE SET NULL;


--
-- TOC entry 5615 (class 2606 OID 349956)
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE CASCADE;


--
-- TOC entry 5610 (class 2606 OID 349961)
-- Name: fk_purchase_orders_vendor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT fk_purchase_orders_vendor FOREIGN KEY (vendor_id) REFERENCES cat_proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5631 (class 2606 OID 349966)
-- Name: fk_recipe_cost_snap_recipe; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_recipe FOREIGN KEY (recipe_id) REFERENCES receta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5632 (class 2606 OID 349971)
-- Name: fk_recipe_cost_snap_user; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_user FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5641 (class 2606 OID 349976)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5550 (class 2606 OID 349981)
-- Name: hist_cost_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5551 (class 2606 OID 349986)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5552 (class 2606 OID 349991)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5553 (class 2606 OID 349996)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5555 (class 2606 OID 350001)
-- Name: insumo_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5556 (class 2606 OID 350006)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5557 (class 2606 OID 350011)
-- Name: insumo_proveedor_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5554 (class 2606 OID 350016)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5561 (class 2606 OID 350021)
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES inv_consumo_pos(id) ON DELETE CASCADE;


--
-- TOC entry 5562 (class 2606 OID 350026)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 5563 (class 2606 OID 350031)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 5564 (class 2606 OID 350036)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5558 (class 2606 OID 350041)
-- Name: ipp_proveedor_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_proveedor_fk FOREIGN KEY (proveedor_id) REFERENCES proveedor(id);


--
-- TOC entry 5559 (class 2606 OID 350046)
-- Name: ipp_uom_base_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_base_fk FOREIGN KEY (uom_base_id) REFERENCES cat_unidades(id);


--
-- TOC entry 5560 (class 2606 OID 350051)
-- Name: ipp_uom_compra_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_compra_fk FOREIGN KEY (uom_compra_id) REFERENCES cat_unidades(id);


--
-- TOC entry 5566 (class 2606 OID 350056)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5567 (class 2606 OID 350061)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5568 (class 2606 OID 350066)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5569 (class 2606 OID 350071)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5570 (class 2606 OID 350076)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5571 (class 2606 OID 350081)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5572 (class 2606 OID 350086)
-- Name: lote_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5575 (class 2606 OID 350091)
-- Name: merma_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5576 (class 2606 OID 350096)
-- Name: merma_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5577 (class 2606 OID 350101)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5578 (class 2606 OID 350106)
-- Name: merma_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5579 (class 2606 OID 350111)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5580 (class 2606 OID 350116)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5581 (class 2606 OID 350121)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 5582 (class 2606 OID 350126)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5583 (class 2606 OID 350131)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5587 (class 2606 OID 350136)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5588 (class 2606 OID 350141)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5589 (class 2606 OID 350146)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5590 (class 2606 OID 350151)
-- Name: op_cab_user_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5591 (class 2606 OID 350156)
-- Name: op_cab_user_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5592 (class 2606 OID 350161)
-- Name: op_insumo_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5593 (class 2606 OID 350166)
-- Name: op_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5594 (class 2606 OID 350171)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5595 (class 2606 OID 350176)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5596 (class 2606 OID 350181)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5597 (class 2606 OID 350186)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5598 (class 2606 OID 350191)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5599 (class 2606 OID 350196)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5600 (class 2606 OID 350201)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5603 (class 2606 OID 350206)
-- Name: postcorte_aprobado_por_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_aprobado_por_fkey FOREIGN KEY (aprobado_por) REFERENCES users(id);


--
-- TOC entry 5604 (class 2606 OID 350211)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5606 (class 2606 OID 350216)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5607 (class 2606 OID 350221)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5605 (class 2606 OID 350226)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5608 (class 2606 OID 350231)
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id);


--
-- TOC entry 5609 (class 2606 OID 350236)
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5621 (class 2606 OID 350241)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 5622 (class 2606 OID 350246)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5623 (class 2606 OID 350251)
-- Name: recepcion_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5624 (class 2606 OID 350256)
-- Name: recepcion_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5625 (class 2606 OID 350261)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5626 (class 2606 OID 350266)
-- Name: recepcion_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5627 (class 2606 OID 350271)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5628 (class 2606 OID 350276)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5584 (class 2606 OID 350281)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5585 (class 2606 OID 350286)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5629 (class 2606 OID 350291)
-- Name: receta_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5630 (class 2606 OID 350296)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5586 (class 2606 OID 350301)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 5634 (class 2606 OID 350306)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5635 (class 2606 OID 350311)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5526 (class 2606 OID 350316)
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5535 (class 2606 OID 350321)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5536 (class 2606 OID 350326)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES cash_fund_movements(id) ON DELETE CASCADE;


--
-- TOC entry 5573 (class 2606 OID 350331)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5574 (class 2606 OID 350336)
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5602 (class 2606 OID 350341)
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES pos_sync_batches(id) ON DELETE CASCADE;


--
-- TOC entry 5633 (class 2606 OID 350346)
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE;


--
-- TOC entry 5636 (class 2606 OID 350351)
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5637 (class 2606 OID 350356)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5638 (class 2606 OID 350361)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5639 (class 2606 OID 350366)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5640 (class 2606 OID 350371)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5642 (class 2606 OID 350376)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 5643 (class 2606 OID 350381)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5644 (class 2606 OID 350386)
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES transfer_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5645 (class 2606 OID 350391)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5646 (class 2606 OID 350396)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5647 (class 2606 OID 350401)
-- Name: traspaso_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5648 (class 2606 OID 350406)
-- Name: traspaso_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5649 (class 2606 OID 350411)
-- Name: traspaso_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5650 (class 2606 OID 350416)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5651 (class 2606 OID 350421)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5652 (class 2606 OID 350426)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5653 (class 2606 OID 350431)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5654 (class 2606 OID 350436)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 6162 (class 0 OID 347079)
-- Dependencies: 509 6319
-- Name: mv_inventario_actual; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_inventario_actual;


--
-- TOC entry 6166 (class 0 OID 347121)
-- Dependencies: 513 6319
-- Name: mv_recetas_costos; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_recetas_costos;


--
-- TOC entry 6324 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 6621 (class 0 OID 0)
-- Dependencies: 695
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-11-19 10:22:07

--
-- PostgreSQL database dump complete
--

