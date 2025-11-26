--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-24 11:02:58

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

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
-- TOC entry 4547 (class 0 OID 0)
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
-- TOC entry 4548 (class 0 OID 0)
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
-- TOC entry 4549 (class 0 OID 0)
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
-- TOC entry 4550 (class 0 OID 0)
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
-- TOC entry 4551 (class 0 OID 0)
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
-- TOC entry 4552 (class 0 OID 0)
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
-- TOC entry 4553 (class 0 OID 0)
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
-- TOC entry 4554 (class 0 OID 0)
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
-- TOC entry 4555 (class 0 OID 0)
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
-- TOC entry 4556 (class 0 OID 0)
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
-- TOC entry 4557 (class 0 OID 0)
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
-- TOC entry 4558 (class 0 OID 0)
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
-- TOC entry 4559 (class 0 OID 0)
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
-- TOC entry 4560 (class 0 OID 0)
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
-- TOC entry 4561 (class 0 OID 0)
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
-- TOC entry 4562 (class 0 OID 0)
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
-- TOC entry 4563 (class 0 OID 0)
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
-- TOC entry 4564 (class 0 OID 0)
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
-- TOC entry 4565 (class 0 OID 0)
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
-- TOC entry 4566 (class 0 OID 0)
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
-- TOC entry 4567 (class 0 OID 0)
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
-- TOC entry 4568 (class 0 OID 0)
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
-- TOC entry 4569 (class 0 OID 0)
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
-- TOC entry 4570 (class 0 OID 0)
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
-- TOC entry 4571 (class 0 OID 0)
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
-- TOC entry 4572 (class 0 OID 0)
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
-- TOC entry 4573 (class 0 OID 0)
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
-- TOC entry 4574 (class 0 OID 0)
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
-- TOC entry 4575 (class 0 OID 0)
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
-- TOC entry 4576 (class 0 OID 0)
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
-- TOC entry 4577 (class 0 OID 0)
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
-- TOC entry 4578 (class 0 OID 0)
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
-- TOC entry 4579 (class 0 OID 0)
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
-- TOC entry 4580 (class 0 OID 0)
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
-- TOC entry 4581 (class 0 OID 0)
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
-- TOC entry 4582 (class 0 OID 0)
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
-- TOC entry 4583 (class 0 OID 0)
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
-- TOC entry 4584 (class 0 OID 0)
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
-- TOC entry 4585 (class 0 OID 0)
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
-- TOC entry 4586 (class 0 OID 0)
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
-- TOC entry 4587 (class 0 OID 0)
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
-- TOC entry 4588 (class 0 OID 0)
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
-- TOC entry 4589 (class 0 OID 0)
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
-- TOC entry 4590 (class 0 OID 0)
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
-- TOC entry 4591 (class 0 OID 0)
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
-- TOC entry 4592 (class 0 OID 0)
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
-- TOC entry 4593 (class 0 OID 0)
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
-- TOC entry 4594 (class 0 OID 0)
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
-- TOC entry 4595 (class 0 OID 0)
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
-- TOC entry 4596 (class 0 OID 0)
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
-- TOC entry 4597 (class 0 OID 0)
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
-- TOC entry 4598 (class 0 OID 0)
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
-- TOC entry 4599 (class 0 OID 0)
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
-- TOC entry 4600 (class 0 OID 0)
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
-- TOC entry 4601 (class 0 OID 0)
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
-- TOC entry 4602 (class 0 OID 0)
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
-- TOC entry 4603 (class 0 OID 0)
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
-- TOC entry 4604 (class 0 OID 0)
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
-- TOC entry 4605 (class 0 OID 0)
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
-- TOC entry 4606 (class 0 OID 0)
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
-- TOC entry 4607 (class 0 OID 0)
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
-- TOC entry 4608 (class 0 OID 0)
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
-- TOC entry 4609 (class 0 OID 0)
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
-- TOC entry 4610 (class 0 OID 0)
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
-- TOC entry 4611 (class 0 OID 0)
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
-- TOC entry 4612 (class 0 OID 0)
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
-- TOC entry 4613 (class 0 OID 0)
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
-- TOC entry 4614 (class 0 OID 0)
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
-- TOC entry 4615 (class 0 OID 0)
-- Dependencies: 390
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE zip_code_vs_delivery_charge_auto_id_seq OWNED BY zip_code_vs_delivery_charge.auto_id;


--
-- TOC entry 3739 (class 2604 OID 348063)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history ALTER COLUMN id SET DEFAULT nextval('action_history_id_seq'::regclass);


--
-- TOC entry 3740 (class 2604 OID 348064)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history ALTER COLUMN id SET DEFAULT nextval('attendence_history_id_seq'::regclass);


--
-- TOC entry 3741 (class 2604 OID 348065)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer ALTER COLUMN id SET DEFAULT nextval('cash_drawer_id_seq'::regclass);


--
-- TOC entry 3742 (class 2604 OID 348066)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass);


--
-- TOC entry 3743 (class 2604 OID 348067)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction ALTER COLUMN id SET DEFAULT nextval('cooking_instruction_id_seq'::regclass);


--
-- TOC entry 3744 (class 2604 OID 348068)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('coupon_and_discount_id_seq'::regclass);


--
-- TOC entry 3745 (class 2604 OID 348069)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency ALTER COLUMN id SET DEFAULT nextval('currency_id_seq'::regclass);


--
-- TOC entry 3746 (class 2604 OID 348070)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance ALTER COLUMN id SET DEFAULT nextval('currency_balance_id_seq'::regclass);


--
-- TOC entry 3747 (class 2604 OID 348071)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment ALTER COLUMN id SET DEFAULT nextval('custom_payment_id_seq'::regclass);


--
-- TOC entry 3748 (class 2604 OID 348072)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer ALTER COLUMN auto_id SET DEFAULT nextval('customer_auto_id_seq'::regclass);


--
-- TOC entry 3750 (class 2604 OID 348073)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info ALTER COLUMN id SET DEFAULT nextval('data_update_info_id_seq'::regclass);


--
-- TOC entry 3751 (class 2604 OID 348074)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address ALTER COLUMN id SET DEFAULT nextval('delivery_address_id_seq'::regclass);


--
-- TOC entry 3752 (class 2604 OID 348075)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge ALTER COLUMN id SET DEFAULT nextval('delivery_charge_id_seq'::regclass);


--
-- TOC entry 3753 (class 2604 OID 348076)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration ALTER COLUMN id SET DEFAULT nextval('delivery_configuration_id_seq'::regclass);


--
-- TOC entry 3754 (class 2604 OID 348077)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction ALTER COLUMN id SET DEFAULT nextval('delivery_instruction_id_seq'::regclass);


--
-- TOC entry 3755 (class 2604 OID 348078)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('drawer_assigned_history_id_seq'::regclass);


--
-- TOC entry 3756 (class 2604 OID 348079)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('drawer_pull_report_id_seq'::regclass);


--
-- TOC entry 3757 (class 2604 OID 348080)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('employee_in_out_history_id_seq'::regclass);


--
-- TOC entry 3758 (class 2604 OID 348081)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config ALTER COLUMN id SET DEFAULT nextval('global_config_id_seq'::regclass);


--
-- TOC entry 3759 (class 2604 OID 348082)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity ALTER COLUMN id SET DEFAULT nextval('gratuity_id_seq'::regclass);


--
-- TOC entry 3760 (class 2604 OID 348083)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print ALTER COLUMN id SET DEFAULT nextval('guest_check_print_id_seq'::regclass);


--
-- TOC entry 3761 (class 2604 OID 348084)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group ALTER COLUMN id SET DEFAULT nextval('inventory_group_id_seq'::regclass);


--
-- TOC entry 3762 (class 2604 OID 348085)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item ALTER COLUMN id SET DEFAULT nextval('inventory_item_id_seq'::regclass);


--
-- TOC entry 3763 (class 2604 OID 348086)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location ALTER COLUMN id SET DEFAULT nextval('inventory_location_id_seq'::regclass);


--
-- TOC entry 3764 (class 2604 OID 348087)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('inventory_meta_code_id_seq'::regclass);


--
-- TOC entry 3765 (class 2604 OID 348088)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction ALTER COLUMN id SET DEFAULT nextval('inventory_transaction_id_seq'::regclass);


--
-- TOC entry 3766 (class 2604 OID 348089)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit ALTER COLUMN id SET DEFAULT nextval('inventory_unit_id_seq'::regclass);


--
-- TOC entry 3767 (class 2604 OID 348090)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor ALTER COLUMN id SET DEFAULT nextval('inventory_vendor_id_seq'::regclass);


--
-- TOC entry 3768 (class 2604 OID 348091)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('inventory_warehouse_id_seq'::regclass);


--
-- TOC entry 3769 (class 2604 OID 348092)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_id_seq'::regclass);


--
-- TOC entry 3773 (class 2604 OID 348093)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_item_id_seq'::regclass);


--
-- TOC entry 3774 (class 2604 OID 348094)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category ALTER COLUMN id SET DEFAULT nextval('menu_category_id_seq'::regclass);


--
-- TOC entry 3775 (class 2604 OID 348095)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group ALTER COLUMN id SET DEFAULT nextval('menu_group_id_seq'::regclass);


--
-- TOC entry 3776 (class 2604 OID 348096)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item ALTER COLUMN id SET DEFAULT nextval('menu_item_id_seq'::regclass);


--
-- TOC entry 3777 (class 2604 OID 348097)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size ALTER COLUMN id SET DEFAULT nextval('menu_item_size_id_seq'::regclass);


--
-- TOC entry 3778 (class 2604 OID 348098)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier ALTER COLUMN id SET DEFAULT nextval('menu_modifier_id_seq'::regclass);


--
-- TOC entry 3779 (class 2604 OID 348099)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('menu_modifier_group_id_seq'::regclass);


--
-- TOC entry 3780 (class 2604 OID 348100)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass);


--
-- TOC entry 3781 (class 2604 OID 348101)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift ALTER COLUMN id SET DEFAULT nextval('menuitem_shift_id_seq'::regclass);


--
-- TOC entry 3782 (class 2604 OID 348102)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('modifier_multiplier_price_id_seq'::regclass);


--
-- TOC entry 3783 (class 2604 OID 348103)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type ALTER COLUMN id SET DEFAULT nextval('order_type_id_seq'::regclass);


--
-- TOC entry 3784 (class 2604 OID 348104)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit ALTER COLUMN id SET DEFAULT nextval('packaging_unit_id_seq'::regclass);


--
-- TOC entry 3785 (class 2604 OID 348105)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons ALTER COLUMN id SET DEFAULT nextval('payout_reasons_id_seq'::regclass);


--
-- TOC entry 3786 (class 2604 OID 348106)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients ALTER COLUMN id SET DEFAULT nextval('payout_recepients_id_seq'::regclass);


--
-- TOC entry 3787 (class 2604 OID 348107)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust ALTER COLUMN id SET DEFAULT nextval('pizza_crust_id_seq'::regclass);


--
-- TOC entry 3788 (class 2604 OID 348108)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('pizza_modifier_price_id_seq'::regclass);


--
-- TOC entry 3789 (class 2604 OID 348109)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price ALTER COLUMN id SET DEFAULT nextval('pizza_price_id_seq'::regclass);


--
-- TOC entry 3790 (class 2604 OID 348110)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group ALTER COLUMN id SET DEFAULT nextval('printer_group_id_seq'::regclass);


--
-- TOC entry 3791 (class 2604 OID 348111)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order ALTER COLUMN id SET DEFAULT nextval('purchase_order_id_seq'::regclass);


--
-- TOC entry 3792 (class 2604 OID 348112)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie ALTER COLUMN id SET DEFAULT nextval('recepie_id_seq'::regclass);


--
-- TOC entry 3793 (class 2604 OID 348113)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item ALTER COLUMN id SET DEFAULT nextval('recepie_item_id_seq'::regclass);


--
-- TOC entry 3794 (class 2604 OID 348114)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift ALTER COLUMN id SET DEFAULT nextval('shift_id_seq'::regclass);


--
-- TOC entry 3795 (class 2604 OID 348115)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor ALTER COLUMN id SET DEFAULT nextval('shop_floor_id_seq'::regclass);


--
-- TOC entry 3796 (class 2604 OID 348116)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template ALTER COLUMN id SET DEFAULT nextval('shop_floor_template_id_seq'::regclass);


--
-- TOC entry 3797 (class 2604 OID 348117)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type ALTER COLUMN id SET DEFAULT nextval('shop_table_type_id_seq'::regclass);


--
-- TOC entry 3798 (class 2604 OID 348118)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info ALTER COLUMN id SET DEFAULT nextval('table_booking_info_id_seq'::regclass);


--
-- TOC entry 3799 (class 2604 OID 348119)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax ALTER COLUMN id SET DEFAULT nextval('tax_id_seq'::regclass);


--
-- TOC entry 3800 (class 2604 OID 348120)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers ALTER COLUMN id SET DEFAULT nextval('terminal_printers_id_seq'::regclass);


--
-- TOC entry 3770 (class 2604 OID 348121)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket ALTER COLUMN id SET DEFAULT nextval('ticket_id_seq'::regclass);


--
-- TOC entry 3801 (class 2604 OID 348122)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount ALTER COLUMN id SET DEFAULT nextval('ticket_discount_id_seq'::regclass);


--
-- TOC entry 3802 (class 2604 OID 348123)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item ALTER COLUMN id SET DEFAULT nextval('ticket_item_id_seq'::regclass);


--
-- TOC entry 3803 (class 2604 OID 348124)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('ticket_item_discount_id_seq'::regclass);


--
-- TOC entry 3804 (class 2604 OID 348125)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifier_id_seq'::regclass);


--
-- TOC entry 3805 (class 2604 OID 348126)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- TOC entry 3806 (class 2604 OID 348127)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type ALTER COLUMN id SET DEFAULT nextval('user_type_id_seq'::regclass);


--
-- TOC entry 3807 (class 2604 OID 348128)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users ALTER COLUMN auto_id SET DEFAULT nextval('users_auto_id_seq'::regclass);


--
-- TOC entry 3808 (class 2604 OID 348129)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer ALTER COLUMN id SET DEFAULT nextval('virtual_printer_id_seq'::regclass);


--
-- TOC entry 3809 (class 2604 OID 348130)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons ALTER COLUMN id SET DEFAULT nextval('void_reasons_id_seq'::regclass);


--
-- TOC entry 3810 (class 2604 OID 348131)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass);


--
-- TOC entry 3812 (class 2606 OID 348263)
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3814 (class 2606 OID 348265)
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3816 (class 2606 OID 348267)
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- TOC entry 3818 (class 2606 OID 348269)
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3820 (class 2606 OID 348271)
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 3822 (class 2606 OID 348273)
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 3824 (class 2606 OID 348275)
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- TOC entry 3828 (class 2606 OID 348277)
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- TOC entry 3826 (class 2606 OID 348279)
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- TOC entry 3830 (class 2606 OID 348281)
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- TOC entry 3832 (class 2606 OID 348283)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 3834 (class 2606 OID 348285)
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3836 (class 2606 OID 348287)
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- TOC entry 3838 (class 2606 OID 348289)
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- TOC entry 3840 (class 2606 OID 348291)
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- TOC entry 3842 (class 2606 OID 348293)
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- TOC entry 3844 (class 2606 OID 348295)
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 3846 (class 2606 OID 348297)
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 3848 (class 2606 OID 348299)
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3852 (class 2606 OID 348301)
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- TOC entry 3855 (class 2606 OID 348303)
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3857 (class 2606 OID 348305)
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- TOC entry 3859 (class 2606 OID 348307)
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- TOC entry 3861 (class 2606 OID 348309)
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- TOC entry 3863 (class 2606 OID 348311)
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- TOC entry 3865 (class 2606 OID 348313)
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3867 (class 2606 OID 348315)
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3869 (class 2606 OID 348317)
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- TOC entry 3871 (class 2606 OID 348319)
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- TOC entry 3873 (class 2606 OID 348321)
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 3875 (class 2606 OID 348323)
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 3877 (class 2606 OID 348325)
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 3879 (class 2606 OID 348327)
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- TOC entry 3903 (class 2606 OID 348329)
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 3906 (class 2606 OID 348331)
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3882 (class 2606 OID 348333)
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 3909 (class 2606 OID 348335)
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- TOC entry 3911 (class 2606 OID 348337)
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3914 (class 2606 OID 348339)
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3916 (class 2606 OID 348341)
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- TOC entry 3918 (class 2606 OID 348343)
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- TOC entry 3923 (class 2606 OID 348345)
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3920 (class 2606 OID 348347)
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 3926 (class 2606 OID 348349)
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- TOC entry 3928 (class 2606 OID 348351)
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- TOC entry 3930 (class 2606 OID 348353)
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- TOC entry 3932 (class 2606 OID 348355)
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3934 (class 2606 OID 348357)
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- TOC entry 3936 (class 2606 OID 348359)
-- Name: online_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY online_order
    ADD CONSTRAINT online_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3938 (class 2606 OID 348361)
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- TOC entry 3940 (class 2606 OID 348363)
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3942 (class 2606 OID 348365)
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- TOC entry 3944 (class 2606 OID 348367)
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 3946 (class 2606 OID 348369)
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 3948 (class 2606 OID 348371)
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- TOC entry 3950 (class 2606 OID 348373)
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- TOC entry 3952 (class 2606 OID 348375)
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3954 (class 2606 OID 348377)
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3956 (class 2606 OID 348379)
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 3958 (class 2606 OID 348381)
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- TOC entry 3960 (class 2606 OID 348383)
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3962 (class 2606 OID 348385)
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3966 (class 2606 OID 348387)
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3964 (class 2606 OID 348389)
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- TOC entry 3968 (class 2606 OID 348391)
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- TOC entry 3970 (class 2606 OID 348393)
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3972 (class 2606 OID 348395)
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- TOC entry 3974 (class 2606 OID 348397)
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- TOC entry 3976 (class 2606 OID 348399)
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- TOC entry 3978 (class 2606 OID 348401)
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- TOC entry 3980 (class 2606 OID 348403)
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3982 (class 2606 OID 348405)
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3984 (class 2606 OID 348407)
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- TOC entry 3986 (class 2606 OID 348409)
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3989 (class 2606 OID 348411)
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- TOC entry 3994 (class 2606 OID 348413)
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3992 (class 2606 OID 348415)
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 3884 (class 2606 OID 348417)
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 3996 (class 2606 OID 348419)
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- TOC entry 3998 (class 2606 OID 348421)
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4000 (class 2606 OID 348423)
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 3892 (class 2606 OID 348425)
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- TOC entry 4005 (class 2606 OID 348427)
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4007 (class 2606 OID 348429)
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- TOC entry 4009 (class 2606 OID 348431)
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4011 (class 2606 OID 348433)
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 4013 (class 2606 OID 348435)
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4003 (class 2606 OID 348437)
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3894 (class 2606 OID 348439)
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4015 (class 2606 OID 348441)
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4017 (class 2606 OID 348443)
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4021 (class 2606 OID 348445)
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- TOC entry 4023 (class 2606 OID 348447)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 4025 (class 2606 OID 348449)
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- TOC entry 4027 (class 2606 OID 348451)
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4029 (class 2606 OID 348453)
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- TOC entry 4031 (class 2606 OID 348455)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 4033 (class 2606 OID 348457)
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- TOC entry 4035 (class 2606 OID 348459)
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- TOC entry 4037 (class 2606 OID 348461)
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- TOC entry 4039 (class 2606 OID 348463)
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- TOC entry 4041 (class 2606 OID 348465)
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4043 (class 2606 OID 348467)
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 3885 (class 1259 OID 348860)
-- Name: creationhour; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX creationhour ON ticket USING btree (creation_hour);


--
-- TOC entry 3886 (class 1259 OID 348861)
-- Name: deliverydate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX deliverydate ON ticket USING btree (deliveery_date);


--
-- TOC entry 3853 (class 1259 OID 348862)
-- Name: drawer_report_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawer_report_time ON drawer_pull_report USING btree (report_time);


--
-- TOC entry 3887 (class 1259 OID 348863)
-- Name: drawerresetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawerresetted ON ticket USING btree (drawer_resetted);


--
-- TOC entry 3907 (class 1259 OID 348864)
-- Name: food_category_visible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX food_category_visible ON menu_category USING btree (visible);


--
-- TOC entry 3987 (class 1259 OID 348865)
-- Name: fromdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX fromdate ON table_booking_info USING btree (from_date);


--
-- TOC entry 3849 (class 1259 OID 348866)
-- Name: idx_dah_user_op_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_dah_user_op_time ON drawer_assigned_history USING btree (a_user, operation, "time" DESC);


--
-- TOC entry 3850 (class 1259 OID 348867)
-- Name: idx_drawer_assigned_history_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_drawer_assigned_history_user_time ON drawer_assigned_history USING btree (a_user, "time");


--
-- TOC entry 3888 (class 1259 OID 348868)
-- Name: idx_ticket_close_term_owner; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_close_term_owner ON ticket USING btree (closing_date, terminal_id, owner_id);


--
-- TOC entry 4018 (class 1259 OID 348869)
-- Name: idx_tx_term_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_tx_term_user_time ON transactions USING btree (terminal_id, user_id, transaction_time);


--
-- TOC entry 3904 (class 1259 OID 348870)
-- Name: ix_kitchen_ticket_item_item_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_item_item_id ON kitchen_ticket_item USING btree (ticket_item_id);


--
-- TOC entry 3880 (class 1259 OID 348871)
-- Name: ix_kitchen_ticket_ticket_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_ticket_id ON kitchen_ticket USING btree (ticket_id);


--
-- TOC entry 3889 (class 1259 OID 348872)
-- Name: ix_ticket_branch_key; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_branch_key ON ticket USING btree (branch_key);


--
-- TOC entry 3890 (class 1259 OID 348873)
-- Name: ix_ticket_folio_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_folio_date ON ticket USING btree (folio_date);


--
-- TOC entry 4001 (class 1259 OID 348874)
-- Name: ix_ticket_item_ticket_pg; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_item_ticket_pg ON ticket_item USING btree (ticket_id, pg_id);


--
-- TOC entry 3912 (class 1259 OID 348875)
-- Name: menugroupvisible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX menugroupvisible ON menu_group USING btree (visible);


--
-- TOC entry 3924 (class 1259 OID 348876)
-- Name: mg_enable; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX mg_enable ON menu_modifier_group USING btree (enabled);


--
-- TOC entry 3921 (class 1259 OID 348877)
-- Name: modifierenabled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX modifierenabled ON menu_modifier USING btree (enable);


--
-- TOC entry 3895 (class 1259 OID 348878)
-- Name: ticketactivedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketactivedate ON ticket USING btree (active_date);


--
-- TOC entry 3896 (class 1259 OID 348879)
-- Name: ticketclosingdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketclosingdate ON ticket USING btree (closing_date);


--
-- TOC entry 3897 (class 1259 OID 348880)
-- Name: ticketcreatedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketcreatedate ON ticket USING btree (create_date);


--
-- TOC entry 3898 (class 1259 OID 348881)
-- Name: ticketpaid; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketpaid ON ticket USING btree (paid);


--
-- TOC entry 3899 (class 1259 OID 348882)
-- Name: ticketsettled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketsettled ON ticket USING btree (settled);


--
-- TOC entry 3900 (class 1259 OID 348883)
-- Name: ticketvoided; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketvoided ON ticket USING btree (voided);


--
-- TOC entry 3990 (class 1259 OID 348884)
-- Name: todate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX todate ON table_booking_info USING btree (to_date);


--
-- TOC entry 4019 (class 1259 OID 348885)
-- Name: tran_drawer_resetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX tran_drawer_resetted ON transactions USING btree (drawer_resetted);


--
-- TOC entry 3901 (class 1259 OID 348886)
-- Name: ux_ticket_dailyfolio; Type: INDEX; Schema: public; Owner: floreant
--

CREATE UNIQUE INDEX ux_ticket_dailyfolio ON ticket USING btree (folio_date, branch_key, daily_folio) WHERE (daily_folio IS NOT NULL);


--
-- TOC entry 4172 (class 2620 OID 349120)
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON ticket FOR EACH ROW EXECUTE PROCEDURE assign_daily_folio();


--
-- TOC entry 4174 (class 2620 OID 349121)
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE OF status ON kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 4175 (class 2620 OID 349122)
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE OF status ON ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 4170 (class 2620 OID 349123)
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();

ALTER TABLE drawer_assigned_history DISABLE TRIGGER trg_selemti_dah_ai;


--
-- TOC entry 4171 (class 2620 OID 349124)
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- TOC entry 4176 (class 2620 OID 349125)
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


--
-- TOC entry 4173 (class 2620 OID 356986)
-- Name: trg_ticket_inventory_consumption; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_ticket_inventory_consumption AFTER UPDATE OF paid, voided ON ticket FOR EACH ROW EXECUTE PROCEDURE selemti.trg_ticket_inventory_consumption();


--
-- TOC entry 4104 (class 2606 OID 349146)
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 4091 (class 2606 OID 349151)
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 4114 (class 2606 OID 349156)
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 4115 (class 2606 OID 349161)
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES pizza_price(id);


--
-- TOC entry 4145 (class 2606 OID 349166)
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 4134 (class 2606 OID 349171)
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 4054 (class 2606 OID 349176)
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 4055 (class 2606 OID 349181)
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES customer(auto_id);


--
-- TOC entry 4050 (class 2606 OID 349186)
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES currency(id);


--
-- TOC entry 4051 (class 2606 OID 349191)
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES cash_drawer(id);


--
-- TOC entry 4052 (class 2606 OID 349196)
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 4164 (class 2606 OID 349201)
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES user_type(id);


--
-- TOC entry 4165 (class 2606 OID 349206)
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES user_permission(name);


--
-- TOC entry 4135 (class 2606 OID 349211)
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4136 (class 2606 OID 349216)
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 4111 (class 2606 OID 349221)
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 4112 (class 2606 OID 349226)
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES menu_item(id);


--
-- TOC entry 4113 (class 2606 OID 349231)
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 4082 (class 2606 OID 349236)
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 4063 (class 2606 OID 349241)
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 4064 (class 2606 OID 349246)
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4065 (class 2606 OID 349251)
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 4151 (class 2606 OID 349256)
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 4152 (class 2606 OID 349261)
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES ticket_item(id);


--
-- TOC entry 4044 (class 2606 OID 349266)
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4093 (class 2606 OID 349271)
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES menu_group(id);


--
-- TOC entry 4094 (class 2606 OID 349276)
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 4095 (class 2606 OID 349281)
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES tax_group(id);


--
-- TOC entry 4096 (class 2606 OID 349286)
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 4097 (class 2606 OID 349291)
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES recepie(id);


--
-- TOC entry 4166 (class 2606 OID 349296)
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 4167 (class 2606 OID 349301)
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES user_type(id);


--
-- TOC entry 4168 (class 2606 OID 349306)
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES terminal(id);


--
-- TOC entry 4092 (class 2606 OID 349311)
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES menu_category(id);


--
-- TOC entry 4105 (class 2606 OID 349316)
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES menu_category(id);


--
-- TOC entry 4106 (class 2606 OID 349321)
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 4090 (class 2606 OID 349326)
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 4118 (class 2606 OID 349331)
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 4119 (class 2606 OID 349336)
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 4074 (class 2606 OID 349341)
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 4101 (class 2606 OID 349346)
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 4102 (class 2606 OID 349351)
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 4103 (class 2606 OID 349356)
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 4056 (class 2606 OID 349361)
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES users(auto_id);


--
-- TOC entry 4154 (class 2606 OID 349366)
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 4155 (class 2606 OID 349371)
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 4048 (class 2606 OID 349376)
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4157 (class 2606 OID 349381)
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 4128 (class 2606 OID 349386)
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES menu_item(id);


--
-- TOC entry 4137 (class 2606 OID 349391)
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES table_booking_info(id);


--
-- TOC entry 4138 (class 2606 OID 349396)
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 4060 (class 2606 OID 349401)
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4061 (class 2606 OID 349406)
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4062 (class 2606 OID 349411)
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 4156 (class 2606 OID 349416)
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES ticket(id);


--
-- TOC entry 4049 (class 2606 OID 349421)
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4069 (class 2606 OID 349426)
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES inventory_group(id);


--
-- TOC entry 4070 (class 2606 OID 349431)
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 4071 (class 2606 OID 349436)
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 4072 (class 2606 OID 349441)
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES inventory_location(id);


--
-- TOC entry 4073 (class 2606 OID 349446)
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 4131 (class 2606 OID 349451)
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES restaurant(id);


--
-- TOC entry 4129 (class 2606 OID 349456)
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES inventory_item(id);


--
-- TOC entry 4130 (class 2606 OID 349461)
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES recepie(id);


--
-- TOC entry 4120 (class 2606 OID 349466)
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES multiplier(name);


--
-- TOC entry 4121 (class 2606 OID 349471)
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 4122 (class 2606 OID 349476)
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 4153 (class 2606 OID 349481)
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 4084 (class 2606 OID 349486)
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES users(auto_id);


--
-- TOC entry 4085 (class 2606 OID 349491)
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4086 (class 2606 OID 349496)
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 4087 (class 2606 OID 349501)
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 4088 (class 2606 OID 349506)
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES gratuity(id);


--
-- TOC entry 4089 (class 2606 OID 349511)
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES users(auto_id);


--
-- TOC entry 4140 (class 2606 OID 349516)
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 4141 (class 2606 OID 349521)
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES shop_table_type(id);


--
-- TOC entry 4144 (class 2606 OID 349526)
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES terminal(id);


--
-- TOC entry 4146 (class 2606 OID 349531)
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 4147 (class 2606 OID 349536)
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 4148 (class 2606 OID 349541)
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 4059 (class 2606 OID 349546)
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 4142 (class 2606 OID 349551)
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4143 (class 2606 OID 349556)
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 4169 (class 2606 OID 349561)
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 4099 (class 2606 OID 349566)
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4100 (class 2606 OID 349571)
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 4149 (class 2606 OID 349576)
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 4150 (class 2606 OID 349581)
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 4057 (class 2606 OID 349586)
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4058 (class 2606 OID 349591)
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4075 (class 2606 OID 349596)
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES purchase_order(id);


--
-- TOC entry 4076 (class 2606 OID 349601)
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES inventory_item(id);


--
-- TOC entry 4077 (class 2606 OID 349606)
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 4078 (class 2606 OID 349611)
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 4079 (class 2606 OID 349616)
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 4132 (class 2606 OID 349621)
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 4127 (class 2606 OID 349626)
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES printer_group(id);


--
-- TOC entry 4139 (class 2606 OID 349631)
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES shop_table_status(id);


--
-- TOC entry 4068 (class 2606 OID 349636)
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4123 (class 2606 OID 349641)
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 4053 (class 2606 OID 349646)
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES customer(auto_id);


--
-- TOC entry 4133 (class 2606 OID 349651)
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES shop_floor_template(id);


--
-- TOC entry 4109 (class 2606 OID 349656)
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 4110 (class 2606 OID 349661)
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 4045 (class 2606 OID 349666)
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4046 (class 2606 OID 349671)
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4047 (class 2606 OID 349676)
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 4116 (class 2606 OID 349681)
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 4117 (class 2606 OID 349686)
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 4080 (class 2606 OID 349691)
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES order_type(id);


--
-- TOC entry 4081 (class 2606 OID 349696)
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 4107 (class 2606 OID 349701)
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES menu_group(id);


--
-- TOC entry 4108 (class 2606 OID 349706)
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 4158 (class 2606 OID 349711)
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES transactions(id);


--
-- TOC entry 4083 (class 2606 OID 349716)
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES users(auto_id);


--
-- TOC entry 4124 (class 2606 OID 349721)
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES pizza_crust(id);


--
-- TOC entry 4125 (class 2606 OID 349726)
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES order_type(id);


--
-- TOC entry 4126 (class 2606 OID 349731)
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 4066 (class 2606 OID 349736)
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES tax(id);


--
-- TOC entry 4067 (class 2606 OID 349741)
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES tax_group(id);


--
-- TOC entry 4098 (class 2606 OID 349746)
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 4159 (class 2606 OID 349751)
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 4160 (class 2606 OID 349756)
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 4161 (class 2606 OID 349761)
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 4162 (class 2606 OID 349766)
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES payout_recepients(id);


--
-- TOC entry 4163 (class 2606 OID 349771)
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES payout_reasons(id);


--
-- TOC entry 4546 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-11-24 11:02:59

--
-- PostgreSQL database dump complete
--

