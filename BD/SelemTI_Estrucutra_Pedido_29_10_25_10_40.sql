--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-10-29 18:51:50

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE pos;
--
-- TOC entry 5915 (class 1262 OID 89724)
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
-- TOC entry 7 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 6 (class 2615 OID 89725)
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

--
-- TOC entry 665 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 5918 (class 0 OID 0)
-- Dependencies: 665
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = selemti, pg_catalog;

--
-- TOC entry 1552 (class 1247 OID 91389)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1555 (class 1247 OID 91394)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1558 (class 1247 OID 91402)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1561 (class 1247 OID 91408)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1564 (class 1247 OID 91414)
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
-- TOC entry 1567 (class 1247 OID 91432)
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
-- TOC entry 1570 (class 1247 OID 91442)
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
-- TOC entry 667 (class 1255 OID 89726)
-- Name: _last_assign_window(integer, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _last_assign_window(_terminal_id integer, _user_id integer, _ref_time timestamp with time zone) RETURNS TABLE(from_ts timestamp with time zone, to_ts timestamp with time zone)
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
-- TOC entry 682 (class 1255 OID 89727)
-- Name: assign_daily_folio(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION assign_daily_folio() RETURNS trigger
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
-- TOC entry 705 (class 1255 OID 93904)
-- Name: fn_correct_drawer_report(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_correct_drawer_report(report_date date) RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric)
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
-- TOC entry 708 (class 1255 OID 93905)
-- Name: fn_daily_reconciliation(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_daily_reconciliation(report_date date) RETURNS TABLE(terminal_id integer, tickets_count integer, transactions_count integer, ticket_net_total numeric, transactions_total numeric, difference numeric, status text)
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
-- TOC entry 709 (class 1255 OID 93906)
-- Name: fn_reconciliation_detail(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_reconciliation_detail(report_date date) RETURNS TABLE(ticket_id integer, terminal_id integer, ticket_number integer, ticket_total numeric, ticket_discount numeric, ticket_neto numeric, transactions_sum numeric, discrepancy numeric, discrepancy_type text)
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
-- TOC entry 683 (class 1255 OID 89728)
-- Name: get_daily_stats(date); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION get_daily_stats(p_date date DEFAULT ('now'::text)::date) RETURNS TABLE(sucursal text, total_ordenes integer, total_ventas numeric, primer_orden time without time zone, ultima_orden time without time zone, promedio_por_hora numeric)
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
-- TOC entry 684 (class 1255 OID 89729)
-- Name: get_ticket_folio_info(integer); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION get_ticket_folio_info(p_ticket_id integer) RETURNS TABLE(daily_folio integer, folio_date date, branch_key text, folio_date_txt text, folio_display text, sucursal_completa text, terminal_name text)
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
-- TOC entry 685 (class 1255 OID 89730)
-- Name: kds_notify(); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION kds_notify() RETURNS trigger
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
-- TOC entry 686 (class 1255 OID 89731)
-- Name: reset_daily_folio_smart(text); Type: FUNCTION; Schema: public; Owner: floreant
--

CREATE FUNCTION reset_daily_folio_smart(p_branch text DEFAULT NULL::text) RETURNS TABLE(branch_reset text, tickets_affected integer)
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

SET search_path = selemti, pg_catalog;

--
-- TOC entry 693 (class 1255 OID 93223)
-- Name: cerrar_lote_preparado(bigint, merma_clase, text, integer, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION cerrar_lote_preparado(p_lote_id bigint, p_clase merma_clase, p_motivo text, p_usuario_id integer DEFAULT NULL::integer, p_uom_id integer DEFAULT NULL::integer) RETURNS bigint
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


ALTER FUNCTION selemti.cerrar_lote_preparado(p_lote_id bigint, p_clase merma_clase, p_motivo text, p_usuario_id integer, p_uom_id integer) OWNER TO postgres;

--
-- TOC entry 706 (class 1255 OID 94403)
-- Name: fn_after_price_insert_alert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_after_price_insert_alert() RETURNS trigger
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
-- TOC entry 710 (class 1255 OID 94315)
-- Name: fn_assign_item_code(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_assign_item_code() RETURNS trigger
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
-- TOC entry 718 (class 1255 OID 94871)
-- Name: fn_confirmar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_confirmar_consumo_ticket(_ticket_id bigint) RETURNS void
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
    SET estado = 'CONFIRMADO',
        requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'PENDIENTE';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'CONFIRM', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 687 (class 1255 OID 89732)
-- Name: fn_dah_after_insert(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_dah_after_insert() RETURNS trigger
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
-- TOC entry 695 (class 1255 OID 93225)
-- Name: fn_dah_after_insert_refuerzo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_dah_after_insert_refuerzo() RETURNS trigger
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
-- TOC entry 716 (class 1255 OID 94870)
-- Name: fn_expandir_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_expandir_consumo_ticket(_ticket_id bigint) RETURNS void
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
-- TOC entry 694 (class 1255 OID 93224)
-- Name: fn_fondo_actual(integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_fondo_actual(p_terminal_id integer) RETURNS numeric
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
-- TOC entry 666 (class 1255 OID 94297)
-- Name: fn_gen_cat_codigo(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_gen_cat_codigo() RETURNS trigger
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
-- TOC entry 696 (class 1255 OID 93226)
-- Name: fn_generar_postcorte(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_generar_postcorte(p_sesion_id bigint) RETURNS bigint
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
-- TOC entry 5919 (class 0 OID 0)
-- Dependencies: 696
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 713 (class 1255 OID 94338)
-- Name: fn_item_unit_cost_at(bigint, timestamp without time zone, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_item_unit_cost_at(p_item_id bigint, p_at timestamp without time zone, p_target_uom text) RETURNS numeric
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
-- TOC entry 711 (class 1255 OID 94335)
-- Name: fn_ivp_upsert_close_prev(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_ivp_upsert_close_prev() RETURNS trigger
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
-- TOC entry 688 (class 1255 OID 89733)
-- Name: fn_normalizar_forma_pago(text, text, text, text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_normalizar_forma_pago(p_payment_type text, p_transaction_type text, p_payment_sub_type text, p_custom_name text) RETURNS text
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
-- TOC entry 697 (class 1255 OID 93227)
-- Name: fn_postcorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_postcorte_after_insert() RETURNS trigger
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
-- TOC entry 5920 (class 0 OID 0)
-- Dependencies: 697
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 698 (class 1255 OID 93228)
-- Name: fn_precorte_after_insert(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_precorte_after_insert() RETURNS trigger
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
-- TOC entry 5921 (class 0 OID 0)
-- Dependencies: 698
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 699 (class 1255 OID 93229)
-- Name: fn_precorte_after_update_aprobado(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_precorte_after_update_aprobado() RETURNS trigger
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
-- TOC entry 5922 (class 0 OID 0)
-- Dependencies: 699
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 681 (class 1255 OID 89734)
-- Name: fn_precorte_efectivo_bi(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_precorte_efectivo_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.subtotal := COALESCE(NEW.denominacion,0) * COALESCE(NEW.cantidad,0);
  RETURN NEW;
END $$;


ALTER FUNCTION selemti.fn_precorte_efectivo_bi() OWNER TO floreant;

--
-- TOC entry 714 (class 1255 OID 94376)
-- Name: fn_recipe_cost_at(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_recipe_cost_at(p_recipe_id bigint, p_at timestamp without time zone) RETURNS TABLE(batch_cost numeric, portion_cost numeric, batch_size numeric, yield_portions numeric)
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
-- TOC entry 668 (class 1255 OID 94402)
-- Name: fn_recipes_using_item(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_recipes_using_item(p_item_id bigint, p_at timestamp without time zone) RETURNS TABLE(recipe_id bigint)
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
-- TOC entry 689 (class 1255 OID 89735)
-- Name: fn_reparar_sesion_apertura(integer, integer); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_reparar_sesion_apertura(p_terminal_id integer, p_usuario integer) RETURNS text
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
-- TOC entry 707 (class 1255 OID 94872)
-- Name: fn_reversar_consumo_ticket(bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_reversar_consumo_ticket(_ticket_id bigint) RETURNS void
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
    SET estado = 'ANULADO',
        requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'CONFIRMADO';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'REVERSE', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 690 (class 1255 OID 89736)
-- Name: fn_slug(text); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_slug(in_text text) RETURNS text
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
-- TOC entry 691 (class 1255 OID 89737)
-- Name: fn_terminal_bu_snapshot_cierre(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_terminal_bu_snapshot_cierre() RETURNS trigger
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
-- TOC entry 692 (class 1255 OID 89738)
-- Name: fn_tx_after_insert_forma_pago(); Type: FUNCTION; Schema: selemti; Owner: floreant
--

CREATE FUNCTION fn_tx_after_insert_forma_pago() RETURNS trigger
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
-- TOC entry 712 (class 1255 OID 94337)
-- Name: fn_uom_factor(text, text); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION fn_uom_factor(from_uom text, to_uom text) RETURNS numeric
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
-- TOC entry 700 (class 1255 OID 93230)
-- Name: inferir_recetas_de_ventas(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date) RETURNS integer
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
-- TOC entry 701 (class 1255 OID 93231)
-- Name: ingesta_ticket(bigint, integer, integer, bigint); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM 1;
  RETURN;
END;
$$;


ALTER FUNCTION selemti.ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) OWNER TO postgres;

--
-- TOC entry 702 (class 1255 OID 93232)
-- Name: recalcular_costos_periodo(date, date); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION recalcular_costos_periodo(p_desde date, p_hasta date DEFAULT ('now'::text)::date) RETURNS integer
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
-- TOC entry 703 (class 1255 OID 93233)
-- Name: registrar_consumo_porcionado(bigint, bigint, text, numeric, json); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) RETURNS integer
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
-- TOC entry 704 (class 1255 OID 93234)
-- Name: reprocesar_costos_historicos(date, date, character varying, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date, p_algoritmo character varying DEFAULT 'WAC'::character varying, p_usuario_id integer DEFAULT 1) RETURNS integer
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
-- TOC entry 715 (class 1255 OID 94377)
-- Name: sp_snapshot_recipe_cost(bigint, timestamp without time zone); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp without time zone) RETURNS void
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
-- TOC entry 717 (class 1255 OID 94873)
-- Name: trg_ticket_inventory_consumption(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION trg_ticket_inventory_consumption() RETURNS trigger
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

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 181 (class 1259 OID 89739)
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
-- TOC entry 182 (class 1259 OID 89745)
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
-- TOC entry 5923 (class 0 OID 0)
-- Dependencies: 182
-- Name: action_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE action_history_id_seq OWNED BY action_history.id;


--
-- TOC entry 183 (class 1259 OID 89747)
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
-- TOC entry 184 (class 1259 OID 89750)
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
-- TOC entry 5924 (class 0 OID 0)
-- Dependencies: 184
-- Name: attendence_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE attendence_history_id_seq OWNED BY attendence_history.id;


--
-- TOC entry 185 (class 1259 OID 89752)
-- Name: cash_drawer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer (
    id integer NOT NULL,
    terminal_id integer
);


ALTER TABLE cash_drawer OWNER TO floreant;

--
-- TOC entry 186 (class 1259 OID 89755)
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
-- TOC entry 5925 (class 0 OID 0)
-- Dependencies: 186
-- Name: cash_drawer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_id_seq OWNED BY cash_drawer.id;


--
-- TOC entry 187 (class 1259 OID 89757)
-- Name: cash_drawer_reset_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer_reset_history (
    id integer NOT NULL,
    reset_time timestamp without time zone,
    user_id integer
);


ALTER TABLE cash_drawer_reset_history OWNER TO floreant;

--
-- TOC entry 188 (class 1259 OID 89760)
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
-- TOC entry 5926 (class 0 OID 0)
-- Dependencies: 188
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_reset_history_id_seq OWNED BY cash_drawer_reset_history.id;


--
-- TOC entry 189 (class 1259 OID 89762)
-- Name: cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cooking_instruction (
    id integer NOT NULL,
    description character varying(60)
);


ALTER TABLE cooking_instruction OWNER TO floreant;

--
-- TOC entry 190 (class 1259 OID 89765)
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
-- TOC entry 5927 (class 0 OID 0)
-- Dependencies: 190
-- Name: cooking_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cooking_instruction_id_seq OWNED BY cooking_instruction.id;


--
-- TOC entry 191 (class 1259 OID 89767)
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
-- TOC entry 192 (class 1259 OID 89770)
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
-- TOC entry 5928 (class 0 OID 0)
-- Dependencies: 192
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE coupon_and_discount_id_seq OWNED BY coupon_and_discount.id;


--
-- TOC entry 193 (class 1259 OID 89772)
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
-- TOC entry 194 (class 1259 OID 89775)
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
-- TOC entry 195 (class 1259 OID 89778)
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
-- TOC entry 5929 (class 0 OID 0)
-- Dependencies: 195
-- Name: currency_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_balance_id_seq OWNED BY currency_balance.id;


--
-- TOC entry 196 (class 1259 OID 89780)
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
-- TOC entry 5930 (class 0 OID 0)
-- Dependencies: 196
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_id_seq OWNED BY currency.id;


--
-- TOC entry 197 (class 1259 OID 89782)
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
-- TOC entry 198 (class 1259 OID 89785)
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
-- TOC entry 5931 (class 0 OID 0)
-- Dependencies: 198
-- Name: custom_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE custom_payment_id_seq OWNED BY custom_payment.id;


--
-- TOC entry 199 (class 1259 OID 89787)
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
-- TOC entry 200 (class 1259 OID 89793)
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
-- TOC entry 5932 (class 0 OID 0)
-- Dependencies: 200
-- Name: customer_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE customer_auto_id_seq OWNED BY customer.auto_id;


--
-- TOC entry 201 (class 1259 OID 89795)
-- Name: customer_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE customer_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE customer_properties OWNER TO floreant;

--
-- TOC entry 202 (class 1259 OID 89801)
-- Name: daily_folio_counter; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE daily_folio_counter (
    folio_date date NOT NULL,
    branch_key text NOT NULL,
    last_value integer DEFAULT 0 NOT NULL
);


ALTER TABLE daily_folio_counter OWNER TO floreant;

--
-- TOC entry 203 (class 1259 OID 89808)
-- Name: data_update_info; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE data_update_info (
    id integer NOT NULL,
    last_update_time timestamp without time zone
);


ALTER TABLE data_update_info OWNER TO floreant;

--
-- TOC entry 204 (class 1259 OID 89811)
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
-- TOC entry 5933 (class 0 OID 0)
-- Dependencies: 204
-- Name: data_update_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE data_update_info_id_seq OWNED BY data_update_info.id;


--
-- TOC entry 205 (class 1259 OID 89813)
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
-- TOC entry 206 (class 1259 OID 89816)
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
-- TOC entry 5934 (class 0 OID 0)
-- Dependencies: 206
-- Name: delivery_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_address_id_seq OWNED BY delivery_address.id;


--
-- TOC entry 207 (class 1259 OID 89818)
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
-- TOC entry 208 (class 1259 OID 89821)
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
-- TOC entry 5935 (class 0 OID 0)
-- Dependencies: 208
-- Name: delivery_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_charge_id_seq OWNED BY delivery_charge.id;


--
-- TOC entry 209 (class 1259 OID 89823)
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
-- TOC entry 210 (class 1259 OID 89826)
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
-- TOC entry 5936 (class 0 OID 0)
-- Dependencies: 210
-- Name: delivery_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_configuration_id_seq OWNED BY delivery_configuration.id;


--
-- TOC entry 211 (class 1259 OID 89828)
-- Name: delivery_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_instruction (
    id integer NOT NULL,
    notes character varying(220),
    customer_no integer
);


ALTER TABLE delivery_instruction OWNER TO floreant;

--
-- TOC entry 212 (class 1259 OID 89831)
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
-- TOC entry 5937 (class 0 OID 0)
-- Dependencies: 212
-- Name: delivery_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_instruction_id_seq OWNED BY delivery_instruction.id;


--
-- TOC entry 213 (class 1259 OID 89833)
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
-- TOC entry 214 (class 1259 OID 89836)
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
-- TOC entry 5938 (class 0 OID 0)
-- Dependencies: 214
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_assigned_history_id_seq OWNED BY drawer_assigned_history.id;


--
-- TOC entry 215 (class 1259 OID 89838)
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
-- TOC entry 216 (class 1259 OID 89841)
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
-- TOC entry 5939 (class 0 OID 0)
-- Dependencies: 216
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_pull_report_id_seq OWNED BY drawer_pull_report.id;


--
-- TOC entry 217 (class 1259 OID 89843)
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
-- TOC entry 218 (class 1259 OID 89849)
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
-- TOC entry 219 (class 1259 OID 89852)
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
-- TOC entry 5940 (class 0 OID 0)
-- Dependencies: 219
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE employee_in_out_history_id_seq OWNED BY employee_in_out_history.id;


--
-- TOC entry 220 (class 1259 OID 89854)
-- Name: global_config; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE global_config (
    id integer NOT NULL,
    pos_key character varying(60),
    pos_value character varying(220)
);


ALTER TABLE global_config OWNER TO floreant;

--
-- TOC entry 221 (class 1259 OID 89857)
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
-- TOC entry 5941 (class 0 OID 0)
-- Dependencies: 221
-- Name: global_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE global_config_id_seq OWNED BY global_config.id;


--
-- TOC entry 222 (class 1259 OID 89859)
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
-- TOC entry 223 (class 1259 OID 89862)
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
-- TOC entry 5942 (class 0 OID 0)
-- Dependencies: 223
-- Name: gratuity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE gratuity_id_seq OWNED BY gratuity.id;


--
-- TOC entry 224 (class 1259 OID 89864)
-- Name: group_taxes; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE group_taxes (
    group_id character varying(128) NOT NULL,
    elt integer NOT NULL
);


ALTER TABLE group_taxes OWNER TO floreant;

--
-- TOC entry 225 (class 1259 OID 89867)
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
-- TOC entry 226 (class 1259 OID 89870)
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
-- TOC entry 5943 (class 0 OID 0)
-- Dependencies: 226
-- Name: guest_check_print_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE guest_check_print_id_seq OWNED BY guest_check_print.id;


--
-- TOC entry 227 (class 1259 OID 89872)
-- Name: inventory_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_group OWNER TO floreant;

--
-- TOC entry 228 (class 1259 OID 89875)
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
-- TOC entry 5944 (class 0 OID 0)
-- Dependencies: 228
-- Name: inventory_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_group_id_seq OWNED BY inventory_group.id;


--
-- TOC entry 229 (class 1259 OID 89877)
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
-- TOC entry 230 (class 1259 OID 89880)
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
-- TOC entry 5945 (class 0 OID 0)
-- Dependencies: 230
-- Name: inventory_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_item_id_seq OWNED BY inventory_item.id;


--
-- TOC entry 231 (class 1259 OID 89882)
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
-- TOC entry 232 (class 1259 OID 89885)
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
-- TOC entry 5946 (class 0 OID 0)
-- Dependencies: 232
-- Name: inventory_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_location_id_seq OWNED BY inventory_location.id;


--
-- TOC entry 233 (class 1259 OID 89887)
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
-- TOC entry 234 (class 1259 OID 89893)
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
-- TOC entry 5947 (class 0 OID 0)
-- Dependencies: 234
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_meta_code_id_seq OWNED BY inventory_meta_code.id;


--
-- TOC entry 235 (class 1259 OID 89895)
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
-- TOC entry 236 (class 1259 OID 89898)
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
-- TOC entry 5948 (class 0 OID 0)
-- Dependencies: 236
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_transaction_id_seq OWNED BY inventory_transaction.id;


--
-- TOC entry 237 (class 1259 OID 89900)
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
-- TOC entry 238 (class 1259 OID 89906)
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
-- TOC entry 5949 (class 0 OID 0)
-- Dependencies: 238
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_unit_id_seq OWNED BY inventory_unit.id;


--
-- TOC entry 239 (class 1259 OID 89908)
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
-- TOC entry 240 (class 1259 OID 89914)
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
-- TOC entry 5950 (class 0 OID 0)
-- Dependencies: 240
-- Name: inventory_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_vendor_id_seq OWNED BY inventory_vendor.id;


--
-- TOC entry 241 (class 1259 OID 89916)
-- Name: inventory_warehouse; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_warehouse (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_warehouse OWNER TO floreant;

--
-- TOC entry 242 (class 1259 OID 89919)
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
-- TOC entry 5951 (class 0 OID 0)
-- Dependencies: 242
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_warehouse_id_seq OWNED BY inventory_warehouse.id;


--
-- TOC entry 243 (class 1259 OID 89921)
-- Name: item_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE item_order_type (
    menu_item_id integer NOT NULL,
    order_type_id integer NOT NULL
);


ALTER TABLE item_order_type OWNER TO floreant;

--
-- TOC entry 244 (class 1259 OID 89924)
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
-- TOC entry 245 (class 1259 OID 89927)
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
-- TOC entry 246 (class 1259 OID 89933)
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
-- TOC entry 247 (class 1259 OID 89940)
-- Name: kds_orders_enhanced; Type: VIEW; Schema: public; Owner: floreant
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


ALTER TABLE kds_orders_enhanced OWNER TO floreant;

--
-- TOC entry 248 (class 1259 OID 89945)
-- Name: kds_ready_log; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kds_ready_log (
    ticket_id integer NOT NULL,
    notified_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE kds_ready_log OWNER TO floreant;

--
-- TOC entry 249 (class 1259 OID 89949)
-- Name: kit_ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kit_ticket_table_num (
    kit_ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE kit_ticket_table_num OWNER TO floreant;

--
-- TOC entry 250 (class 1259 OID 89952)
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
-- TOC entry 5952 (class 0 OID 0)
-- Dependencies: 250
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_id_seq OWNED BY kitchen_ticket.id;


--
-- TOC entry 251 (class 1259 OID 89954)
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
-- TOC entry 252 (class 1259 OID 89960)
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
-- TOC entry 5953 (class 0 OID 0)
-- Dependencies: 252
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_item_id_seq OWNED BY kitchen_ticket_item.id;


--
-- TOC entry 253 (class 1259 OID 89962)
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
-- TOC entry 254 (class 1259 OID 89965)
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
-- TOC entry 5954 (class 0 OID 0)
-- Dependencies: 254
-- Name: menu_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_category_id_seq OWNED BY menu_category.id;


--
-- TOC entry 255 (class 1259 OID 89967)
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
-- TOC entry 256 (class 1259 OID 89970)
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
-- TOC entry 5955 (class 0 OID 0)
-- Dependencies: 256
-- Name: menu_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_group_id_seq OWNED BY menu_group.id;


--
-- TOC entry 257 (class 1259 OID 89972)
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
-- TOC entry 258 (class 1259 OID 89978)
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
-- TOC entry 5956 (class 0 OID 0)
-- Dependencies: 258
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_id_seq OWNED BY menu_item.id;


--
-- TOC entry 259 (class 1259 OID 89980)
-- Name: menu_item_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_properties (
    menu_item_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_item_properties OWNER TO floreant;

--
-- TOC entry 260 (class 1259 OID 89983)
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
-- TOC entry 261 (class 1259 OID 89986)
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
-- TOC entry 5957 (class 0 OID 0)
-- Dependencies: 261
-- Name: menu_item_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_size_id_seq OWNED BY menu_item_size.id;


--
-- TOC entry 262 (class 1259 OID 89988)
-- Name: menu_item_terminal_ref; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_terminal_ref (
    menu_item_id integer NOT NULL,
    terminal_id integer NOT NULL
);


ALTER TABLE menu_item_terminal_ref OWNER TO floreant;

--
-- TOC entry 263 (class 1259 OID 89991)
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
-- TOC entry 264 (class 1259 OID 89994)
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
-- TOC entry 265 (class 1259 OID 89997)
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
-- TOC entry 5958 (class 0 OID 0)
-- Dependencies: 265
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_group_id_seq OWNED BY menu_modifier_group.id;


--
-- TOC entry 266 (class 1259 OID 89999)
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
-- TOC entry 5959 (class 0 OID 0)
-- Dependencies: 266
-- Name: menu_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_id_seq OWNED BY menu_modifier.id;


--
-- TOC entry 267 (class 1259 OID 90001)
-- Name: menu_modifier_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_modifier_properties (
    menu_modifier_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_modifier_properties OWNER TO floreant;

--
-- TOC entry 268 (class 1259 OID 90004)
-- Name: menucategory_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menucategory_discount (
    discount_id integer NOT NULL,
    menucategory_id integer NOT NULL
);


ALTER TABLE menucategory_discount OWNER TO floreant;

--
-- TOC entry 269 (class 1259 OID 90007)
-- Name: menugroup_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menugroup_discount (
    discount_id integer NOT NULL,
    menugroup_id integer NOT NULL
);


ALTER TABLE menugroup_discount OWNER TO floreant;

--
-- TOC entry 270 (class 1259 OID 90010)
-- Name: menuitem_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_discount (
    discount_id integer NOT NULL,
    menuitem_id integer NOT NULL
);


ALTER TABLE menuitem_discount OWNER TO floreant;

--
-- TOC entry 271 (class 1259 OID 90013)
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
-- TOC entry 272 (class 1259 OID 90016)
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
-- TOC entry 5960 (class 0 OID 0)
-- Dependencies: 272
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_modifiergroup_id_seq OWNED BY menuitem_modifiergroup.id;


--
-- TOC entry 273 (class 1259 OID 90018)
-- Name: menuitem_pizzapirce; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_pizzapirce (
    menu_item_id integer NOT NULL,
    pizza_price_id integer NOT NULL
);


ALTER TABLE menuitem_pizzapirce OWNER TO floreant;

--
-- TOC entry 274 (class 1259 OID 90021)
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
-- TOC entry 275 (class 1259 OID 90024)
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
-- TOC entry 5961 (class 0 OID 0)
-- Dependencies: 275
-- Name: menuitem_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_shift_id_seq OWNED BY menuitem_shift.id;


--
-- TOC entry 276 (class 1259 OID 90026)
-- Name: menumodifier_pizzamodifierprice; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menumodifier_pizzamodifierprice (
    menumodifier_id integer NOT NULL,
    pizzamodifierprice_id integer NOT NULL
);


ALTER TABLE menumodifier_pizzamodifierprice OWNER TO floreant;

--
-- TOC entry 277 (class 1259 OID 90029)
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
-- TOC entry 278 (class 1259 OID 90032)
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
-- TOC entry 5962 (class 0 OID 0)
-- Dependencies: 278
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE modifier_multiplier_price_id_seq OWNED BY modifier_multiplier_price.id;


--
-- TOC entry 279 (class 1259 OID 90034)
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
-- TOC entry 280 (class 1259 OID 90037)
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
-- TOC entry 281 (class 1259 OID 90043)
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
-- TOC entry 5963 (class 0 OID 0)
-- Dependencies: 281
-- Name: order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE order_type_id_seq OWNED BY order_type.id;


--
-- TOC entry 282 (class 1259 OID 90045)
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
-- TOC entry 283 (class 1259 OID 90048)
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
-- TOC entry 5964 (class 0 OID 0)
-- Dependencies: 283
-- Name: packaging_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE packaging_unit_id_seq OWNED BY packaging_unit.id;


--
-- TOC entry 284 (class 1259 OID 90050)
-- Name: payout_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_reasons (
    id integer NOT NULL,
    reason character varying(255)
);


ALTER TABLE payout_reasons OWNER TO floreant;

--
-- TOC entry 285 (class 1259 OID 90053)
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
-- TOC entry 5965 (class 0 OID 0)
-- Dependencies: 285
-- Name: payout_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_reasons_id_seq OWNED BY payout_reasons.id;


--
-- TOC entry 286 (class 1259 OID 90055)
-- Name: payout_recepients; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_recepients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE payout_recepients OWNER TO floreant;

--
-- TOC entry 287 (class 1259 OID 90058)
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
-- TOC entry 5966 (class 0 OID 0)
-- Dependencies: 287
-- Name: payout_recepients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_recepients_id_seq OWNED BY payout_recepients.id;


--
-- TOC entry 288 (class 1259 OID 90060)
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
-- TOC entry 289 (class 1259 OID 90063)
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
-- TOC entry 5967 (class 0 OID 0)
-- Dependencies: 289
-- Name: pizza_crust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_crust_id_seq OWNED BY pizza_crust.id;


--
-- TOC entry 290 (class 1259 OID 90065)
-- Name: pizza_modifier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE pizza_modifier_price (
    id integer NOT NULL,
    item_size integer
);


ALTER TABLE pizza_modifier_price OWNER TO floreant;

--
-- TOC entry 291 (class 1259 OID 90068)
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
-- TOC entry 5968 (class 0 OID 0)
-- Dependencies: 291
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_modifier_price_id_seq OWNED BY pizza_modifier_price.id;


--
-- TOC entry 292 (class 1259 OID 90070)
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
-- TOC entry 293 (class 1259 OID 90073)
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
-- TOC entry 5969 (class 0 OID 0)
-- Dependencies: 293
-- Name: pizza_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_price_id_seq OWNED BY pizza_price.id;


--
-- TOC entry 294 (class 1259 OID 90075)
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
-- TOC entry 295 (class 1259 OID 90081)
-- Name: printer_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    is_default boolean
);


ALTER TABLE printer_group OWNER TO floreant;

--
-- TOC entry 296 (class 1259 OID 90084)
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
-- TOC entry 5970 (class 0 OID 0)
-- Dependencies: 296
-- Name: printer_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE printer_group_id_seq OWNED BY printer_group.id;


--
-- TOC entry 297 (class 1259 OID 90086)
-- Name: printer_group_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group_printers (
    printer_id integer NOT NULL,
    printer_name character varying(255)
);


ALTER TABLE printer_group_printers OWNER TO floreant;

--
-- TOC entry 298 (class 1259 OID 90089)
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE purchase_order (
    id integer NOT NULL,
    order_id character varying(30),
    name character varying(30)
);


ALTER TABLE purchase_order OWNER TO floreant;

--
-- TOC entry 299 (class 1259 OID 90092)
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
-- TOC entry 5971 (class 0 OID 0)
-- Dependencies: 299
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE purchase_order_id_seq OWNED BY purchase_order.id;


--
-- TOC entry 300 (class 1259 OID 90094)
-- Name: recepie; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE recepie (
    id integer NOT NULL,
    menu_item integer
);


ALTER TABLE recepie OWNER TO floreant;

--
-- TOC entry 301 (class 1259 OID 90097)
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
-- TOC entry 5972 (class 0 OID 0)
-- Dependencies: 301
-- Name: recepie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_id_seq OWNED BY recepie.id;


--
-- TOC entry 302 (class 1259 OID 90099)
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
-- TOC entry 303 (class 1259 OID 90102)
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
-- TOC entry 5973 (class 0 OID 0)
-- Dependencies: 303
-- Name: recepie_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_item_id_seq OWNED BY recepie_item.id;


--
-- TOC entry 304 (class 1259 OID 90104)
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
    allow_modifier_max_exceed boolean
);


ALTER TABLE restaurant OWNER TO floreant;

--
-- TOC entry 305 (class 1259 OID 90107)
-- Name: restaurant_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE restaurant_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE restaurant_properties OWNER TO floreant;

--
-- TOC entry 306 (class 1259 OID 90113)
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
-- TOC entry 307 (class 1259 OID 90116)
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
-- TOC entry 5974 (class 0 OID 0)
-- Dependencies: 307
-- Name: shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shift_id_seq OWNED BY shift.id;


--
-- TOC entry 308 (class 1259 OID 90118)
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
-- TOC entry 309 (class 1259 OID 90121)
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
-- TOC entry 5975 (class 0 OID 0)
-- Dependencies: 309
-- Name: shop_floor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_id_seq OWNED BY shop_floor.id;


--
-- TOC entry 310 (class 1259 OID 90123)
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
-- TOC entry 311 (class 1259 OID 90126)
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
-- TOC entry 5976 (class 0 OID 0)
-- Dependencies: 311
-- Name: shop_floor_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_template_id_seq OWNED BY shop_floor_template.id;


--
-- TOC entry 312 (class 1259 OID 90128)
-- Name: shop_floor_template_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_floor_template_properties (
    id integer NOT NULL,
    property_value character varying(60),
    property_name character varying(255) NOT NULL
);


ALTER TABLE shop_floor_template_properties OWNER TO floreant;

--
-- TOC entry 313 (class 1259 OID 90131)
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
-- TOC entry 314 (class 1259 OID 90134)
-- Name: shop_table_status; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_status (
    id integer NOT NULL,
    table_status integer
);


ALTER TABLE shop_table_status OWNER TO floreant;

--
-- TOC entry 315 (class 1259 OID 90137)
-- Name: shop_table_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_type (
    id integer NOT NULL,
    description character varying(120),
    name character varying(40)
);


ALTER TABLE shop_table_type OWNER TO floreant;

--
-- TOC entry 316 (class 1259 OID 90140)
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
-- TOC entry 5977 (class 0 OID 0)
-- Dependencies: 316
-- Name: shop_table_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_table_type_id_seq OWNED BY shop_table_type.id;


--
-- TOC entry 317 (class 1259 OID 90142)
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
-- TOC entry 318 (class 1259 OID 90145)
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
-- TOC entry 5978 (class 0 OID 0)
-- Dependencies: 318
-- Name: table_booking_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE table_booking_info_id_seq OWNED BY table_booking_info.id;


--
-- TOC entry 319 (class 1259 OID 90147)
-- Name: table_booking_mapping; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_booking_mapping (
    booking_id integer NOT NULL,
    table_id integer NOT NULL
);


ALTER TABLE table_booking_mapping OWNER TO floreant;

--
-- TOC entry 320 (class 1259 OID 90150)
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
-- TOC entry 321 (class 1259 OID 90153)
-- Name: table_type_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_type_relation (
    table_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE table_type_relation OWNER TO floreant;

--
-- TOC entry 322 (class 1259 OID 90156)
-- Name: tax; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    rate double precision
);


ALTER TABLE tax OWNER TO floreant;

--
-- TOC entry 323 (class 1259 OID 90159)
-- Name: tax_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax_group (
    id character varying(128) NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE tax_group OWNER TO floreant;

--
-- TOC entry 324 (class 1259 OID 90162)
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
-- TOC entry 5979 (class 0 OID 0)
-- Dependencies: 324
-- Name: tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE tax_id_seq OWNED BY tax.id;


--
-- TOC entry 325 (class 1259 OID 90164)
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
-- TOC entry 326 (class 1259 OID 90167)
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
-- TOC entry 5980 (class 0 OID 0)
-- Dependencies: 326
-- Name: terminal_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE terminal_printers_id_seq OWNED BY terminal_printers.id;


--
-- TOC entry 327 (class 1259 OID 90169)
-- Name: terminal_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE terminal_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE terminal_properties OWNER TO floreant;

--
-- TOC entry 328 (class 1259 OID 90175)
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
-- TOC entry 329 (class 1259 OID 90178)
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
-- TOC entry 5981 (class 0 OID 0)
-- Dependencies: 329
-- Name: ticket_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_discount_id_seq OWNED BY ticket_discount.id;


--
-- TOC entry 330 (class 1259 OID 90180)
-- Name: ticket_folio_complete; Type: VIEW; Schema: public; Owner: floreant
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


ALTER TABLE ticket_folio_complete OWNER TO floreant;

--
-- TOC entry 331 (class 1259 OID 90185)
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
-- TOC entry 5982 (class 0 OID 0)
-- Dependencies: 331
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_id_seq OWNED BY ticket.id;


--
-- TOC entry 332 (class 1259 OID 90187)
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
-- TOC entry 333 (class 1259 OID 90193)
-- Name: ticket_item_addon_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_addon_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_addon_relation OWNER TO floreant;

--
-- TOC entry 334 (class 1259 OID 90196)
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
-- TOC entry 335 (class 1259 OID 90199)
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
-- TOC entry 336 (class 1259 OID 90202)
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
-- TOC entry 5983 (class 0 OID 0)
-- Dependencies: 336
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_discount_id_seq OWNED BY ticket_item_discount.id;


--
-- TOC entry 337 (class 1259 OID 90204)
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
-- TOC entry 5984 (class 0 OID 0)
-- Dependencies: 337
-- Name: ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_id_seq OWNED BY ticket_item.id;


--
-- TOC entry 338 (class 1259 OID 90206)
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
-- TOC entry 339 (class 1259 OID 90209)
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
-- TOC entry 5985 (class 0 OID 0)
-- Dependencies: 339
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_modifier_id_seq OWNED BY ticket_item_modifier.id;


--
-- TOC entry 340 (class 1259 OID 90211)
-- Name: ticket_item_modifier_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_modifier_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_modifier_relation OWNER TO floreant;

--
-- TOC entry 341 (class 1259 OID 90214)
-- Name: ticket_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE ticket_properties OWNER TO floreant;

--
-- TOC entry 342 (class 1259 OID 90220)
-- Name: ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_table_num (
    ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE ticket_table_num OWNER TO floreant;

--
-- TOC entry 343 (class 1259 OID 90223)
-- Name: transaction_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE transaction_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE transaction_properties OWNER TO floreant;

--
-- TOC entry 344 (class 1259 OID 90229)
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
-- TOC entry 345 (class 1259 OID 90235)
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
-- TOC entry 5986 (class 0 OID 0)
-- Dependencies: 345
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- TOC entry 346 (class 1259 OID 90237)
-- Name: user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_permission (
    name character varying(40) NOT NULL
);


ALTER TABLE user_permission OWNER TO floreant;

--
-- TOC entry 347 (class 1259 OID 90240)
-- Name: user_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_type (
    id integer NOT NULL,
    p_name character varying(60)
);


ALTER TABLE user_type OWNER TO floreant;

--
-- TOC entry 348 (class 1259 OID 90243)
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
-- TOC entry 5987 (class 0 OID 0)
-- Dependencies: 348
-- Name: user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE user_type_id_seq OWNED BY user_type.id;


--
-- TOC entry 349 (class 1259 OID 90245)
-- Name: user_user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_user_permission (
    permissionid integer NOT NULL,
    elt character varying(40) NOT NULL
);


ALTER TABLE user_user_permission OWNER TO floreant;

--
-- TOC entry 350 (class 1259 OID 90248)
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
-- TOC entry 351 (class 1259 OID 90251)
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
-- TOC entry 5988 (class 0 OID 0)
-- Dependencies: 351
-- Name: users_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE users_auto_id_seq OWNED BY users.auto_id;


--
-- TOC entry 352 (class 1259 OID 90253)
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
-- TOC entry 353 (class 1259 OID 90256)
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
-- TOC entry 5989 (class 0 OID 0)
-- Dependencies: 353
-- Name: virtual_printer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE virtual_printer_id_seq OWNED BY virtual_printer.id;


--
-- TOC entry 354 (class 1259 OID 90258)
-- Name: virtualprinter_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE virtualprinter_order_type (
    printer_id integer NOT NULL,
    order_type character varying(255)
);


ALTER TABLE virtualprinter_order_type OWNER TO floreant;

--
-- TOC entry 355 (class 1259 OID 90261)
-- Name: void_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE void_reasons (
    id integer NOT NULL,
    reason_text character varying(255)
);


ALTER TABLE void_reasons OWNER TO floreant;

--
-- TOC entry 356 (class 1259 OID 90264)
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
-- TOC entry 5990 (class 0 OID 0)
-- Dependencies: 356
-- Name: void_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE void_reasons_id_seq OWNED BY void_reasons.id;


--
-- TOC entry 357 (class 1259 OID 90266)
-- Name: zip_code_vs_delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE zip_code_vs_delivery_charge (
    auto_id integer NOT NULL,
    zip_code character varying(10) NOT NULL,
    delivery_charge double precision NOT NULL
);


ALTER TABLE zip_code_vs_delivery_charge OWNER TO floreant;

--
-- TOC entry 358 (class 1259 OID 90269)
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
-- TOC entry 5991 (class 0 OID 0)
-- Dependencies: 358
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE zip_code_vs_delivery_charge_auto_id_seq OWNED BY zip_code_vs_delivery_charge.auto_id;


SET search_path = selemti, pg_catalog;

--
-- TOC entry 558 (class 1259 OID 94393)
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
-- TOC entry 557 (class 1259 OID 94391)
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
-- TOC entry 5992 (class 0 OID 0)
-- Dependencies: 557
-- Name: alert_events_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_events_id_seq OWNED BY alert_events.id;


--
-- TOC entry 556 (class 1259 OID 94380)
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
-- TOC entry 555 (class 1259 OID 94378)
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
-- TOC entry 5993 (class 0 OID 0)
-- Dependencies: 555
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_rules_id_seq OWNED BY alert_rules.id;


--
-- TOC entry 421 (class 1259 OID 92059)
-- Name: almacen; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE almacen (
    id text NOT NULL,
    sucursal_id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE almacen OWNER TO postgres;

--
-- TOC entry 664 (class 1259 OID 102630)
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
-- TOC entry 663 (class 1259 OID 102628)
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
-- TOC entry 5994 (class 0 OID 0)
-- Dependencies: 663
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;


--
-- TOC entry 359 (class 1259 OID 90271)
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
-- TOC entry 360 (class 1259 OID 90278)
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
-- TOC entry 5995 (class 0 OID 0)
-- Dependencies: 360
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE auditoria_id_seq OWNED BY auditoria.id;


--
-- TOC entry 422 (class 1259 OID 92066)
-- Name: bodega; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE bodega (
    id integer NOT NULL,
    sucursal_id text NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE bodega OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 91963)
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
-- TOC entry 5996 (class 0 OID 0)
-- Dependencies: 373
-- Name: bodega_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE bodega_id_seq OWNED BY bodega.id;


--
-- TOC entry 423 (class 1259 OID 92072)
-- Name: cache; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 92078)
-- Name: cache_locks; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache_locks OWNER TO postgres;

--
-- TOC entry 562 (class 1259 OID 94438)
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
-- TOC entry 567 (class 1259 OID 94482)
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
-- TOC entry 566 (class 1259 OID 94480)
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
-- TOC entry 5997 (class 0 OID 0)
-- Dependencies: 566
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_adj_id_seq OWNED BY caja_fondo_adj.id;


--
-- TOC entry 569 (class 1259 OID 94499)
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
-- TOC entry 568 (class 1259 OID 94497)
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
-- TOC entry 5998 (class 0 OID 0)
-- Dependencies: 568
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_arqueo_id_seq OWNED BY caja_fondo_arqueo.id;


--
-- TOC entry 561 (class 1259 OID 94436)
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
-- TOC entry 5999 (class 0 OID 0)
-- Dependencies: 561
-- Name: caja_fondo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_id_seq OWNED BY caja_fondo.id;


--
-- TOC entry 565 (class 1259 OID 94460)
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
-- TOC entry 564 (class 1259 OID 94458)
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
-- TOC entry 6000 (class 0 OID 0)
-- Dependencies: 564
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE caja_fondo_mov_id_seq OWNED BY caja_fondo_mov.id;


--
-- TOC entry 563 (class 1259 OID 94448)
-- Name: caja_fondo_usuario; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE caja_fondo_usuario (
    fondo_id bigint NOT NULL,
    user_id integer NOT NULL,
    rol character varying(16) NOT NULL
);


ALTER TABLE caja_fondo_usuario OWNER TO postgres;

--
-- TOC entry 605 (class 1259 OID 94802)
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
-- TOC entry 604 (class 1259 OID 94800)
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
-- TOC entry 6001 (class 0 OID 0)
-- Dependencies: 604
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_arqueos_id_seq OWNED BY cash_fund_arqueos.id;


--
-- TOC entry 607 (class 1259 OID 94830)
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
    changed_by_user_id integer NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE cash_fund_movement_audit_log OWNER TO postgres;

--
-- TOC entry 606 (class 1259 OID 94828)
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
-- TOC entry 6002 (class 0 OID 0)
-- Dependencies: 606
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movement_audit_log_id_seq OWNED BY cash_fund_movement_audit_log.id;


--
-- TOC entry 603 (class 1259 OID 94766)
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
    CONSTRAINT cash_fund_movements_estatus_check CHECK (((estatus)::text = ANY ((ARRAY['APROBADO'::character varying, 'POR_APROBAR'::character varying, 'RECHAZADO'::character varying])::text[]))),
    CONSTRAINT cash_fund_movements_metodo_check CHECK (((metodo)::text = ANY ((ARRAY['EFECTIVO'::character varying, 'TRANSFER'::character varying])::text[]))),
    CONSTRAINT cash_fund_movements_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['EGRESO'::character varying, 'REINTEGRO'::character varying, 'DEPOSITO'::character varying])::text[])))
);


ALTER TABLE cash_fund_movements OWNER TO postgres;

--
-- TOC entry 602 (class 1259 OID 94764)
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
-- TOC entry 6003 (class 0 OID 0)
-- Dependencies: 602
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_fund_movements_id_seq OWNED BY cash_fund_movements.id;


--
-- TOC entry 601 (class 1259 OID 94741)
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
    CONSTRAINT cash_funds_estado_check CHECK (((estado)::text = ANY ((ARRAY['ABIERTO'::character varying, 'EN_REVISION'::character varying, 'CERRADO'::character varying])::text[])))
);


ALTER TABLE cash_funds OWNER TO postgres;

--
-- TOC entry 6004 (class 0 OID 0)
-- Dependencies: 601
-- Name: COLUMN cash_funds.descripcion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN cash_funds.descripcion IS 'Descripción o nombre del fondo para identificación rápida';


--
-- TOC entry 600 (class 1259 OID 94739)
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
-- TOC entry 6005 (class 0 OID 0)
-- Dependencies: 600
-- Name: cash_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cash_funds_id_seq OWNED BY cash_funds.id;


--
-- TOC entry 526 (class 1259 OID 93934)
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
-- TOC entry 525 (class 1259 OID 93932)
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
-- TOC entry 6006 (class 0 OID 0)
-- Dependencies: 525
-- Name: cat_almacenes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_almacenes_id_seq OWNED BY cat_almacenes.id;


--
-- TOC entry 528 (class 1259 OID 93950)
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
-- TOC entry 527 (class 1259 OID 93948)
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
-- TOC entry 6007 (class 0 OID 0)
-- Dependencies: 527
-- Name: cat_proveedores_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_proveedores_id_seq OWNED BY cat_proveedores.id;


--
-- TOC entry 524 (class 1259 OID 93923)
-- Name: cat_sucursales; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_sucursales (
    id bigint NOT NULL,
    clave character varying(16) NOT NULL,
    nombre character varying(120) NOT NULL,
    ubicacion character varying(160),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE cat_sucursales OWNER TO postgres;

--
-- TOC entry 523 (class 1259 OID 93921)
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
-- TOC entry 6008 (class 0 OID 0)
-- Dependencies: 523
-- Name: cat_sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_sucursales_id_seq OWNED BY cat_sucursales.id;


--
-- TOC entry 425 (class 1259 OID 92084)
-- Name: cat_unidades; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    clave character varying(16),
    nombre character varying(64),
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE cat_unidades OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 91965)
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
-- TOC entry 6009 (class 0 OID 0)
-- Dependencies: 374
-- Name: cat_unidades_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;


--
-- TOC entry 530 (class 1259 OID 93961)
-- Name: cat_uom_conversion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_uom_conversion (
    id bigint NOT NULL,
    origen_id bigint NOT NULL,
    destino_id bigint NOT NULL,
    factor numeric(18,6) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE cat_uom_conversion OWNER TO postgres;

--
-- TOC entry 529 (class 1259 OID 93959)
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
-- TOC entry 6010 (class 0 OID 0)
-- Dependencies: 529
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_uom_conversion_id_seq OWNED BY cat_uom_conversion.id;


--
-- TOC entry 426 (class 1259 OID 92087)
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
-- TOC entry 6011 (class 0 OID 0)
-- Dependencies: 426
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 6012 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 6013 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN conciliacion.conciliado_por; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.conciliado_por IS 'Usuario que realizÃ³ la conciliaciÃ³n (supervisor/gerente).';


--
-- TOC entry 375 (class 1259 OID 91967)
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
-- TOC entry 6014 (class 0 OID 0)
-- Dependencies: 375
-- Name: conciliacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conciliacion_id_seq OWNED BY conciliacion.id;


--
-- TOC entry 427 (class 1259 OID 92096)
-- Name: conversiones_unidad; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE conversiones_unidad (
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


ALTER TABLE conversiones_unidad OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 91969)
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
-- TOC entry 6015 (class 0 OID 0)
-- Dependencies: 376
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad.id;


--
-- TOC entry 428 (class 1259 OID 92107)
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
-- TOC entry 377 (class 1259 OID 91971)
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
-- TOC entry 6016 (class 0 OID 0)
-- Dependencies: 377
-- Name: cost_layer_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cost_layer_id_seq OWNED BY cost_layer.id;


--
-- TOC entry 429 (class 1259 OID 92113)
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
-- TOC entry 378 (class 1259 OID 91973)
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
-- TOC entry 6017 (class 0 OID 0)
-- Dependencies: 378
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


--
-- TOC entry 361 (class 1259 OID 90280)
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
-- TOC entry 362 (class 1259 OID 90289)
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
-- TOC entry 6018 (class 0 OID 0)
-- Dependencies: 362
-- Name: formas_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE formas_pago_id_seq OWNED BY formas_pago.id;


--
-- TOC entry 430 (class 1259 OID 92120)
-- Name: hist_cost_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE hist_cost_insumo (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    fecha_efectiva date NOT NULL,
    costo_wac numeric(14,6),
    costo_peps numeric(14,6),
    costo_ueps numeric(14,6),
    costo_std numeric(14,6),
    algoritmo_principal text DEFAULT 'WAC'::text,
    valid_from date DEFAULT ('now'::text)::date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone
);


ALTER TABLE hist_cost_insumo OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 91975)
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
-- TOC entry 6019 (class 0 OID 0)
-- Dependencies: 379
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_insumo_id_seq OWNED BY hist_cost_insumo.id;


--
-- TOC entry 431 (class 1259 OID 92129)
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
-- TOC entry 380 (class 1259 OID 91977)
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
-- TOC entry 6020 (class 0 OID 0)
-- Dependencies: 380
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE hist_cost_receta_id_seq OWNED BY hist_cost_receta.id;


--
-- TOC entry 432 (class 1259 OID 92138)
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
-- TOC entry 381 (class 1259 OID 91979)
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
-- TOC entry 6021 (class 0 OID 0)
-- Dependencies: 381
-- Name: historial_costos_item_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_item_id_seq OWNED BY historial_costos_item.id;


--
-- TOC entry 433 (class 1259 OID 92153)
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
-- TOC entry 382 (class 1259 OID 91981)
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
-- TOC entry 6022 (class 0 OID 0)
-- Dependencies: 382
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_receta_id_seq OWNED BY historial_costos_receta.id;


--
-- TOC entry 434 (class 1259 OID 92162)
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
    consecutivo integer
);


ALTER TABLE insumo OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 91983)
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
-- TOC entry 6023 (class 0 OID 0)
-- Dependencies: 383
-- Name: insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_id_seq OWNED BY insumo.id;


--
-- TOC entry 435 (class 1259 OID 92171)
-- Name: insumo_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE insumo_presentacion (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    proveedor_id integer,
    um_compra_id integer NOT NULL,
    factor_a_um numeric(14,6) DEFAULT 1.0 NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0.0 NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE insumo_presentacion OWNER TO postgres;

--
-- TOC entry 384 (class 1259 OID 91985)
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
-- TOC entry 6024 (class 0 OID 0)
-- Dependencies: 384
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


--
-- TOC entry 571 (class 1259 OID 94516)
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
    fecha_proceso timestamp(0) without time zone
);


ALTER TABLE inv_consumo_pos OWNER TO postgres;

--
-- TOC entry 6025 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- TOC entry 6026 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- TOC entry 6027 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN inv_consumo_pos.fecha_proceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.fecha_proceso IS 'Momento del procesamiento';


--
-- TOC entry 573 (class 1259 OID 94528)
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
    fecha_proceso timestamp(0) without time zone
);


ALTER TABLE inv_consumo_pos_det OWNER TO postgres;

--
-- TOC entry 572 (class 1259 OID 94526)
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
-- TOC entry 6028 (class 0 OID 0)
-- Dependencies: 572
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_det_id_seq OWNED BY inv_consumo_pos_det.id;


--
-- TOC entry 570 (class 1259 OID 94514)
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
-- TOC entry 6029 (class 0 OID 0)
-- Dependencies: 570
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_id_seq OWNED BY inv_consumo_pos.id;


--
-- TOC entry 609 (class 1259 OID 94859)
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
-- TOC entry 608 (class 1259 OID 94857)
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
-- TOC entry 6030 (class 0 OID 0)
-- Dependencies: 608
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_consumo_pos_log_id_seq OWNED BY inv_consumo_pos_log.id;


--
-- TOC entry 532 (class 1259 OID 93981)
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
-- TOC entry 531 (class 1259 OID 93979)
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
-- TOC entry 6031 (class 0 OID 0)
-- Dependencies: 531
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inv_stock_policy_id_seq OWNED BY inv_stock_policy.id;


--
-- TOC entry 436 (class 1259 OID 92177)
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
-- TOC entry 6032 (class 0 OID 0)
-- Dependencies: 436
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario con trazabilidad completa.';


--
-- TOC entry 6033 (class 0 OID 0)
-- Dependencies: 436
-- Name: COLUMN inventory_batch.unit_cost; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inventory_batch.unit_cost IS 'Costo unitario del lote para costeo por batch.';


--
-- TOC entry 385 (class 1259 OID 91987)
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
-- TOC entry 6034 (class 0 OID 0)
-- Dependencies: 385
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


--
-- TOC entry 591 (class 1259 OID 94656)
-- Name: inventory_count_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_count_lines (
    id bigint NOT NULL,
    inventory_count_id bigint NOT NULL,
    item_id bigint NOT NULL,
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
-- TOC entry 590 (class 1259 OID 94654)
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
-- TOC entry 6035 (class 0 OID 0)
-- Dependencies: 590
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_count_lines_id_seq OWNED BY inventory_count_lines.id;


--
-- TOC entry 589 (class 1259 OID 94635)
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
-- TOC entry 588 (class 1259 OID 94633)
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
-- TOC entry 6036 (class 0 OID 0)
-- Dependencies: 588
-- Name: inventory_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_counts_id_seq OWNED BY inventory_counts.id;


--
-- TOC entry 599 (class 1259 OID 94724)
-- Name: inventory_wastes; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_wastes (
    id bigint NOT NULL,
    production_order_id bigint,
    item_id bigint NOT NULL,
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
-- TOC entry 598 (class 1259 OID 94722)
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
-- TOC entry 6037 (class 0 OID 0)
-- Dependencies: 598
-- Name: inventory_wastes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_wastes_id_seq OWNED BY inventory_wastes.id;


--
-- TOC entry 544 (class 1259 OID 94281)
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
-- TOC entry 543 (class 1259 OID 94279)
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
-- TOC entry 6038 (class 0 OID 0)
-- Dependencies: 543
-- Name: item_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_categories_id_seq OWNED BY item_categories.id;


--
-- TOC entry 546 (class 1259 OID 94309)
-- Name: item_category_counters; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE item_category_counters (
    category_id bigint NOT NULL,
    last_val bigint DEFAULT 0 NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE item_category_counters OWNER TO postgres;

--
-- TOC entry 437 (class 1259 OID 92190)
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
-- TOC entry 548 (class 1259 OID 94319)
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
-- TOC entry 547 (class 1259 OID 94317)
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
-- TOC entry 6039 (class 0 OID 0)
-- Dependencies: 547
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE item_vendor_prices_id_seq OWNED BY item_vendor_prices.id;


--
-- TOC entry 438 (class 1259 OID 92201)
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
    CONSTRAINT items_unidad_medida_check CHECK (((unidad_medida)::text = ANY (ARRAY[('KG'::character varying)::text, ('LT'::character varying)::text, ('PZ'::character varying)::text, ('BULTO'::character varying)::text, ('CAJA'::character varying)::text])))
);


ALTER TABLE items OWNER TO postgres;

--
-- TOC entry 6040 (class 0 OID 0)
-- Dependencies: 438
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'Maestro de todos los productos/insumos del sistema.';


--
-- TOC entry 6041 (class 0 OID 0)
-- Dependencies: 438
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- TOC entry 6042 (class 0 OID 0)
-- Dependencies: 438
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- TOC entry 6043 (class 0 OID 0)
-- Dependencies: 438
-- Name: COLUMN items.es_empaque_to_go; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_empaque_to_go IS 'Marks items as to-go packaging.';


--
-- TOC entry 439 (class 1259 OID 92221)
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
-- TOC entry 440 (class 1259 OID 92227)
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
-- TOC entry 386 (class 1259 OID 91989)
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
-- TOC entry 6044 (class 0 OID 0)
-- Dependencies: 386
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE job_recalc_queue_id_seq OWNED BY job_recalc_queue.id;


--
-- TOC entry 441 (class 1259 OID 92237)
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
-- TOC entry 387 (class 1259 OID 91991)
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
-- TOC entry 6045 (class 0 OID 0)
-- Dependencies: 387
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- TOC entry 625 (class 1259 OID 94994)
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
-- TOC entry 624 (class 1259 OID 94992)
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
-- TOC entry 6046 (class 0 OID 0)
-- Dependencies: 624
-- Name: labor_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE labor_roles_id_seq OWNED BY labor_roles.id;


--
-- TOC entry 442 (class 1259 OID 92243)
-- Name: lote; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE lote (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    proveedor_id integer,
    codigo text,
    caducidad date,
    estado lote_estado DEFAULT 'ACTIVO'::lote_estado NOT NULL,
    creado_ts timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE lote OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 91993)
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
-- TOC entry 6047 (class 0 OID 0)
-- Dependencies: 388
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE lote_id_seq OWNED BY lote.id;


--
-- TOC entry 643 (class 1259 OID 95143)
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
-- TOC entry 642 (class 1259 OID 95141)
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
-- TOC entry 6048 (class 0 OID 0)
-- Dependencies: 642
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_engineering_snapshots_id_seq OWNED BY menu_engineering_snapshots.id;


--
-- TOC entry 641 (class 1259 OID 95124)
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
-- TOC entry 640 (class 1259 OID 95122)
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
-- TOC entry 6049 (class 0 OID 0)
-- Dependencies: 640
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_item_sync_map_id_seq OWNED BY menu_item_sync_map.id;


--
-- TOC entry 639 (class 1259 OID 95110)
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
-- TOC entry 638 (class 1259 OID 95108)
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
-- TOC entry 6050 (class 0 OID 0)
-- Dependencies: 638
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE menu_items_id_seq OWNED BY menu_items.id;


--
-- TOC entry 443 (class 1259 OID 92251)
-- Name: merma; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE merma (
    id bigint NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    tipo merma_tipo NOT NULL,
    insumo_id bigint NOT NULL,
    lote_id bigint,
    op_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    usuario_id bigint,
    motivo text,
    meta jsonb
);


ALTER TABLE merma OWNER TO postgres;

--
-- TOC entry 389 (class 1259 OID 91995)
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
-- TOC entry 6051 (class 0 OID 0)
-- Dependencies: 389
-- Name: merma_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE merma_id_seq OWNED BY merma.id;


--
-- TOC entry 444 (class 1259 OID 92258)
-- Name: migrations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 91997)
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
-- TOC entry 6052 (class 0 OID 0)
-- Dependencies: 390
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


--
-- TOC entry 445 (class 1259 OID 92261)
-- Name: model_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_permissions OWNER TO postgres;

--
-- TOC entry 446 (class 1259 OID 92264)
-- Name: model_has_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_roles OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 92267)
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
-- TOC entry 391 (class 1259 OID 91999)
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
-- TOC entry 6053 (class 0 OID 0)
-- Dependencies: 391
-- Name: modificadores_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE modificadores_pos_id_seq OWNED BY modificadores_pos.id;


--
-- TOC entry 448 (class 1259 OID 92273)
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
-- TOC entry 6054 (class 0 OID 0)
-- Dependencies: 448
-- Name: TABLE mov_inv; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE mov_inv IS 'Kardex completo de movimientos de inventario.';


--
-- TOC entry 392 (class 1259 OID 92001)
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
-- TOC entry 6055 (class 0 OID 0)
-- Dependencies: 392
-- Name: mov_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE mov_inv_id_seq OWNED BY mov_inv.id;


--
-- TOC entry 371 (class 1259 OID 90345)
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
-- TOC entry 497 (class 1259 OID 93705)
-- Name: vw_sesion_ventas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_ventas AS
 WITH base AS (
         SELECT s.id AS sesion_id,
            (t.amount)::numeric AS monto,
            COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp,
            (t.transaction_time)::date AS fecha
           FROM ((sesion_cajon s
             JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
             LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
          WHERE ((COALESCE(t.voided, false) = false) AND ((t.transaction_type)::text = 'CREDIT'::text))
        )
 SELECT base.sesion_id,
    base.codigo_fp,
    (sum(base.monto))::numeric(12,2) AS monto,
    base.fecha
   FROM base
  GROUP BY base.sesion_id, base.codigo_fp, base.fecha;


ALTER TABLE vw_sesion_ventas OWNER TO postgres;

--
-- TOC entry 499 (class 1259 OID 93715)
-- Name: vw_ventas_por_item; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_ventas_por_item AS
 SELECT (date_trunc('day'::text, t.closing_date))::date AS fecha,
    t.terminal_id,
    COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text) AS sucursal_id,
    (row_to_json(ti.*) ->> 'plu'::text) AS plu,
    sum(COALESCE(((row_to_json(ti.*) ->> 'qty'::text))::numeric, ((row_to_json(ti.*) ->> 'quantity'::text))::numeric, (0)::numeric)) AS unidades,
    sum((COALESCE(((row_to_json(ti.*) ->> 'precio'::text))::numeric, ((row_to_json(ti.*) ->> 'price'::text))::numeric, (0)::numeric) * COALESCE(((row_to_json(ti.*) ->> 'qty'::text))::numeric, ((row_to_json(ti.*) ->> 'quantity'::text))::numeric, (0)::numeric))) AS venta_total
   FROM (public.ticket_item ti
     JOIN public.ticket t ON (((t.id = ((row_to_json(ti.*) ->> 'ticket_id'::text))::bigint) OR (t.id = ti.ticket_id))))
  GROUP BY ((date_trunc('day'::text, t.closing_date))::date), t.terminal_id, COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text), (row_to_json(ti.*) ->> 'plu'::text);


ALTER TABLE vw_ventas_por_item OWNER TO postgres;

--
-- TOC entry 507 (class 1259 OID 93751)
-- Name: vw_terminal_sucursal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_terminal_sucursal_dia AS
 SELECT vw_ventas_por_item.fecha,
    vw_ventas_por_item.terminal_id,
    vw_ventas_por_item.sucursal_id
   FROM vw_ventas_por_item
  GROUP BY vw_ventas_por_item.fecha, vw_ventas_por_item.terminal_id, vw_ventas_por_item.sucursal_id;


ALTER TABLE vw_terminal_sucursal_dia OWNER TO postgres;

--
-- TOC entry 533 (class 1259 OID 94058)
-- Name: mv_dashboard_formas_pago; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW mv_dashboard_formas_pago AS
 WITH sesiones AS (
         SELECT sc.id AS sesion_id,
            (date_trunc('day'::text, sc.apertura_ts))::date AS fecha,
            COALESCE(tsd.sucursal_id, ''::text) AS sucursal_id
           FROM (sesion_cajon sc
             LEFT JOIN vw_terminal_sucursal_dia tsd ON (((tsd.fecha = (date_trunc('day'::text, sc.apertura_ts))::date) AND (tsd.terminal_id = sc.terminal_id))))
        )
 SELECT s.fecha,
    s.sucursal_id,
    v.codigo_fp,
    (sum(v.monto))::numeric(14,2) AS monto
   FROM (vw_sesion_ventas v
     JOIN sesiones s ON ((s.sesion_id = v.sesion_id)))
  GROUP BY s.fecha, s.sucursal_id, v.codigo_fp
  WITH NO DATA;


ALTER TABLE mv_dashboard_formas_pago OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 90291)
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
-- TOC entry 6056 (class 0 OID 0)
-- Dependencies: 363
-- Name: COLUMN postcorte.validado; Type: COMMENT; Schema: selemti; Owner: floreant
--

COMMENT ON COLUMN postcorte.validado IS 'TRUE cuando el supervisor valida/cierra el postcorte';


--
-- TOC entry 365 (class 1259 OID 90316)
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
-- TOC entry 493 (class 1259 OID 93686)
-- Name: vw_sesion_anulaciones; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_anulaciones AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((tk.status)::text = ANY (ARRAY[('VOID'::character varying)::text, ('REFUND'::character varying)::text])) THEN tk.total_price
            ELSE (0)::double precision
        END), (0)::double precision))::numeric AS total_anulado
   FROM (sesion_cajon s
     LEFT JOIN public.ticket tk ON (((tk.closing_date >= s.apertura_ts) AND (tk.closing_date < COALESCE(s.cierre_ts, now())) AND (tk.terminal_id = s.terminal_id) AND (tk.owner_id = s.cajero_usuario_id))))
  GROUP BY s.id;


ALTER TABLE vw_sesion_anulaciones OWNER TO postgres;

--
-- TOC entry 494 (class 1259 OID 93691)
-- Name: vw_sesion_descuentos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_descuentos AS
 SELECT s.id AS sesion_id,
    (0)::numeric AS descuentos
   FROM sesion_cajon s;


ALTER TABLE vw_sesion_descuentos OWNER TO postgres;

--
-- TOC entry 495 (class 1259 OID 93695)
-- Name: vw_sesion_reembolsos_efectivo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_reembolsos_efectivo AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((((t.transaction_type)::text = ANY (ARRAY[('REFUND'::character varying)::text, ('RETURN'::character varying)::text])) OR (COALESCE(t.voided, false) = true)) AND (((t.payment_type)::text = 'CASH'::text) OR ((t.transaction_type)::text = 'CASH'::text))) THEN (t.amount)::numeric
            ELSE (0)::numeric
        END), (0)::numeric))::numeric(12,2) AS reembolsos_efectivo
   FROM (sesion_cajon s
     JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
  GROUP BY s.id;


ALTER TABLE vw_sesion_reembolsos_efectivo OWNER TO postgres;

--
-- TOC entry 496 (class 1259 OID 93700)
-- Name: vw_sesion_retiros; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_sesion_retiros AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((t.transaction_type)::text = ANY (ARRAY[('PAYOUT'::character varying)::text, ('EXPENSE'::character varying)::text])) THEN (t.amount)::numeric
            ELSE (0)::numeric
        END), (0)::numeric))::numeric(12,2) AS retiros
   FROM (sesion_cajon s
     JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
  GROUP BY s.id;


ALTER TABLE vw_sesion_retiros OWNER TO postgres;

--
-- TOC entry 498 (class 1259 OID 93710)
-- Name: vw_conciliacion_sesion; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_conciliacion_sesion AS
 WITH ventas AS (
         SELECT vw_sesion_ventas.sesion_id,
            sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = 'CASH'::text) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END) AS ventas_efectivo,
            sum(
                CASE
                    WHEN ((vw_sesion_ventas.codigo_fp = ANY (ARRAY['CREDIT'::text, 'DEBIT'::text, 'TRANSFER'::text])) OR (vw_sesion_ventas.codigo_fp ~~ 'CUSTOM:%'::text)) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END) AS ventas_no_efectivo
           FROM vw_sesion_ventas
          GROUP BY vw_sesion_ventas.sesion_id
        ), decl AS (
         SELECT s_1.id AS sesion_id,
            COALESCE(max(p.declarado_efectivo), (0)::numeric) AS precorte_efectivo,
            COALESCE(max(pc.declarado_efectivo), (0)::numeric) AS post_efectivo,
            COALESCE(max(pc.declarado_tarjetas), (0)::numeric) AS post_tarjetas
           FROM ((sesion_cajon s_1
             LEFT JOIN precorte p ON ((p.sesion_id = s_1.id)))
             LEFT JOIN postcorte pc ON ((pc.sesion_id = s_1.id)))
          GROUP BY s_1.id
        )
 SELECT s.id AS sesion_id,
    s.terminal_id,
    s.cajero_usuario_id,
    s.apertura_ts,
    s.cierre_ts,
    s.estatus,
    s.opening_float,
    COALESCE(v.ventas_efectivo, (0)::numeric) AS sistema_efectivo,
    COALESCE(v.ventas_no_efectivo, (0)::numeric) AS sistema_no_efectivo,
    COALESCE(dsc.descuentos, (0)::numeric) AS sistema_descuentos,
    COALESCE(an.total_anulado, (0)::numeric) AS sistema_anulaciones,
    COALESCE(re.retiros, (0)::numeric) AS sistema_retiros,
    COALESCE(rc.reembolsos_efectivo, (0)::numeric) AS sistema_reembolsos_efectivo,
    (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric)) AS sistema_efectivo_esperado,
    COALESCE(dl.precorte_efectivo, (0)::numeric) AS declarado_precorte_efectivo,
    COALESCE(dl.post_efectivo, (0)::numeric) AS declarado_post_efectivo,
    COALESCE(dl.post_tarjetas, (0)::numeric) AS declarado_post_tarjetas,
    (COALESCE(dl.post_efectivo, (0)::numeric) - (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric))) AS diferencia_efectivo,
    (COALESCE(dl.post_tarjetas, (0)::numeric) - COALESCE(v.ventas_no_efectivo, (0)::numeric)) AS diferencia_no_efectivo,
    s.closing_float AS cierre_pos_snapshot,
    COALESCE(s.closing_float, (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric))) AS cierre_pos_efectivo_final
   FROM ((((((sesion_cajon s
     LEFT JOIN ventas v ON ((v.sesion_id = s.id)))
     LEFT JOIN vw_sesion_descuentos dsc ON ((dsc.sesion_id = s.id)))
     LEFT JOIN vw_sesion_anulaciones an ON ((an.sesion_id = s.id)))
     LEFT JOIN vw_sesion_retiros re ON ((re.sesion_id = s.id)))
     LEFT JOIN vw_sesion_reembolsos_efectivo rc ON ((rc.sesion_id = s.id)))
     LEFT JOIN decl dl ON ((dl.sesion_id = s.id)));


ALTER TABLE vw_conciliacion_sesion OWNER TO postgres;

--
-- TOC entry 534 (class 1259 OID 94067)
-- Name: mv_dashboard_resumen; Type: MATERIALIZED VIEW; Schema: selemti; Owner: postgres
--

CREATE MATERIALIZED VIEW mv_dashboard_resumen AS
 WITH conciliado AS (
         SELECT (date_trunc('day'::text, cs.apertura_ts))::date AS fecha,
            COALESCE(tsd.sucursal_id, ''::text) AS sucursal_id,
            cs.sesion_id,
            cs.sistema_efectivo,
            cs.sistema_no_efectivo,
            cs.sistema_descuentos,
            cs.sistema_anulaciones,
            cs.sistema_reembolsos_efectivo,
            cs.sistema_retiros
           FROM (vw_conciliacion_sesion cs
             LEFT JOIN vw_terminal_sucursal_dia tsd ON (((tsd.fecha = (date_trunc('day'::text, cs.apertura_ts))::date) AND (tsd.terminal_id = cs.terminal_id))))
        ), resumen_por_sucursal AS (
         SELECT conciliado.fecha,
            conciliado.sucursal_id,
            sum(conciliado.sistema_efectivo) AS sistema_efectivo,
            sum(conciliado.sistema_no_efectivo) AS sistema_no_efectivo,
            sum(conciliado.sistema_descuentos) AS sistema_descuentos,
            sum(conciliado.sistema_anulaciones) AS sistema_anulaciones,
            sum(conciliado.sistema_reembolsos_efectivo) AS sistema_reembolsos_efectivo,
            sum(conciliado.sistema_retiros) AS sistema_retiros
           FROM conciliado
          GROUP BY conciliado.fecha, conciliado.sucursal_id
        ), pagos AS (
         SELECT mv_dashboard_formas_pago.fecha,
            mv_dashboard_formas_pago.sucursal_id,
            sum(
                CASE
                    WHEN (mv_dashboard_formas_pago.codigo_fp = 'CASH'::text) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_efectivo,
            sum(
                CASE
                    WHEN (mv_dashboard_formas_pago.codigo_fp = ANY (ARRAY['CREDIT'::text, 'CREDIT_CARD'::text])) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_tarjeta_credito,
            sum(
                CASE
                    WHEN (mv_dashboard_formas_pago.codigo_fp = ANY (ARRAY['DEBIT'::text, 'DEBIT_CARD'::text])) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_tarjeta_debito,
            sum(
                CASE
                    WHEN (mv_dashboard_formas_pago.codigo_fp = ANY (ARRAY['TRANSFER'::text, 'TRANSFERENCIA'::text])) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_transferencia,
            sum(
                CASE
                    WHEN (mv_dashboard_formas_pago.codigo_fp ~~ 'CUSTOM:%'::text) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_personalizadas,
            sum(
                CASE
                    WHEN ((mv_dashboard_formas_pago.codigo_fp <> ALL (ARRAY['CASH'::text, 'CREDIT'::text, 'CREDIT_CARD'::text, 'DEBIT'::text, 'DEBIT_CARD'::text, 'TRANSFER'::text, 'TRANSFERENCIA'::text])) AND (mv_dashboard_formas_pago.codigo_fp !~~ 'CUSTOM:%'::text)) THEN mv_dashboard_formas_pago.monto
                    ELSE (0)::numeric
                END) AS ventas_otras
           FROM mv_dashboard_formas_pago
          GROUP BY mv_dashboard_formas_pago.fecha, mv_dashboard_formas_pago.sucursal_id
        )
 SELECT r.fecha,
    r.sucursal_id,
    r.sistema_efectivo,
    r.sistema_no_efectivo,
    r.sistema_descuentos,
    r.sistema_anulaciones,
    r.sistema_reembolsos_efectivo,
    r.sistema_retiros,
    (COALESCE(p.ventas_efectivo, (0)::numeric))::numeric(14,2) AS ventas_efectivo,
    (COALESCE(p.ventas_tarjeta_credito, (0)::numeric))::numeric(14,2) AS ventas_tarjeta_credito,
    (COALESCE(p.ventas_tarjeta_debito, (0)::numeric))::numeric(14,2) AS ventas_tarjeta_debito,
    (COALESCE(p.ventas_transferencia, (0)::numeric))::numeric(14,2) AS ventas_transferencia,
    (COALESCE(p.ventas_personalizadas, (0)::numeric))::numeric(14,2) AS ventas_personalizadas,
    (COALESCE(p.ventas_otras, (0)::numeric))::numeric(14,2) AS ventas_otras
   FROM (resumen_por_sucursal r
     LEFT JOIN pagos p ON (((p.fecha = r.fecha) AND (p.sucursal_id = r.sucursal_id))))
  WITH NO DATA;


ALTER TABLE mv_dashboard_resumen OWNER TO postgres;

--
-- TOC entry 449 (class 1259 OID 92280)
-- Name: op_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_cab (
    id bigint NOT NULL,
    sucursal_id text NOT NULL,
    receta_version_id bigint NOT NULL,
    cantidad_objetivo numeric(14,6) NOT NULL,
    um_salida_id integer NOT NULL,
    estado op_estado DEFAULT 'ABIERTA'::op_estado NOT NULL,
    ts_apertura timestamp without time zone DEFAULT now() NOT NULL,
    ts_cierre timestamp without time zone,
    usuario_abre bigint,
    usuario_cierra bigint,
    lote_salida_id bigint,
    meta jsonb
);


ALTER TABLE op_cab OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 92003)
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
-- TOC entry 6057 (class 0 OID 0)
-- Dependencies: 393
-- Name: op_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_cab_id_seq OWNED BY op_cab.id;


--
-- TOC entry 450 (class 1259 OID 92288)
-- Name: op_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE op_insumo (
    id bigint NOT NULL,
    op_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    qty_teorica numeric(14,6) NOT NULL,
    qty_real numeric(14,6),
    um_id integer NOT NULL,
    lote_id bigint,
    meta jsonb
);


ALTER TABLE op_insumo OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 92005)
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
-- TOC entry 6058 (class 0 OID 0)
-- Dependencies: 394
-- Name: op_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_insumo_id_seq OWNED BY op_insumo.id;


--
-- TOC entry 451 (class 1259 OID 92294)
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
-- TOC entry 6059 (class 0 OID 0)
-- Dependencies: 451
-- Name: TABLE op_produccion_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE op_produccion_cab IS 'Cabecera de Ã³rdenes de producciÃ³n.';


--
-- TOC entry 395 (class 1259 OID 92007)
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
-- TOC entry 6060 (class 0 OID 0)
-- Dependencies: 395
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_produccion_cab_id_seq OWNED BY op_produccion_cab.id;


--
-- TOC entry 452 (class 1259 OID 92302)
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
-- TOC entry 629 (class 1259 OID 95025)
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
-- TOC entry 628 (class 1259 OID 95023)
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
-- TOC entry 6061 (class 0 OID 0)
-- Dependencies: 628
-- Name: overhead_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE overhead_definitions_id_seq OWNED BY overhead_definitions.id;


--
-- TOC entry 453 (class 1259 OID 92309)
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
-- TOC entry 396 (class 1259 OID 92009)
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
-- TOC entry 6062 (class 0 OID 0)
-- Dependencies: 396
-- Name: param_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE param_sucursal_id_seq OWNED BY param_sucursal.id;


--
-- TOC entry 454 (class 1259 OID 92320)
-- Name: password_reset_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE password_reset_tokens OWNER TO postgres;

--
-- TOC entry 455 (class 1259 OID 92326)
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
-- TOC entry 397 (class 1259 OID 92011)
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
-- TOC entry 6063 (class 0 OID 0)
-- Dependencies: 397
-- Name: perdida_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE perdida_log_id_seq OWNED BY perdida_log.id;


--
-- TOC entry 456 (class 1259 OID 92335)
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
-- TOC entry 398 (class 1259 OID 92013)
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
-- TOC entry 6064 (class 0 OID 0)
-- Dependencies: 398
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- TOC entry 662 (class 1259 OID 95579)
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
-- TOC entry 661 (class 1259 OID 95577)
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
-- TOC entry 6065 (class 0 OID 0)
-- Dependencies: 661
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE personal_access_tokens_id_seq OWNED BY personal_access_tokens.id;


--
-- TOC entry 457 (class 1259 OID 92341)
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
    CONSTRAINT pos_map_tipo_check CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text])))
);


ALTER TABLE pos_map OWNER TO postgres;

--
-- TOC entry 660 (class 1259 OID 95536)
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
-- TOC entry 6066 (class 0 OID 0)
-- Dependencies: 660
-- Name: TABLE pos_reprocess_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reprocess_log IS 'Log de auditoría de reprocesos de consumo POS histórico';


--
-- TOC entry 659 (class 1259 OID 95534)
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
-- TOC entry 6067 (class 0 OID 0)
-- Dependencies: 659
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reprocess_log_id_seq OWNED BY pos_reprocess_log.id;


--
-- TOC entry 658 (class 1259 OID 95519)
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
-- TOC entry 6068 (class 0 OID 0)
-- Dependencies: 658
-- Name: TABLE pos_reverse_log; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_reverse_log IS 'Log de auditoría de reversas de consumo POS';


--
-- TOC entry 657 (class 1259 OID 95517)
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
-- TOC entry 6069 (class 0 OID 0)
-- Dependencies: 657
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_reverse_log_id_seq OWNED BY pos_reverse_log.id;


--
-- TOC entry 635 (class 1259 OID 95076)
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
-- TOC entry 634 (class 1259 OID 95074)
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
-- TOC entry 6070 (class 0 OID 0)
-- Dependencies: 634
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_batches_id_seq OWNED BY pos_sync_batches.id;


--
-- TOC entry 637 (class 1259 OID 95091)
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
-- TOC entry 636 (class 1259 OID 95089)
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
-- TOC entry 6071 (class 0 OID 0)
-- Dependencies: 636
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE pos_sync_logs_id_seq OWNED BY pos_sync_logs.id;


--
-- TOC entry 364 (class 1259 OID 90314)
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
-- TOC entry 6072 (class 0 OID 0)
-- Dependencies: 364
-- Name: postcorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE postcorte_id_seq OWNED BY postcorte.id;


--
-- TOC entry 366 (class 1259 OID 90327)
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
-- TOC entry 367 (class 1259 OID 90331)
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
-- TOC entry 6073 (class 0 OID 0)
-- Dependencies: 367
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_efectivo_id_seq OWNED BY precorte_efectivo.id;


--
-- TOC entry 368 (class 1259 OID 90333)
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
-- TOC entry 6074 (class 0 OID 0)
-- Dependencies: 368
-- Name: precorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_id_seq OWNED BY precorte.id;


--
-- TOC entry 369 (class 1259 OID 90335)
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
-- TOC entry 370 (class 1259 OID 90343)
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
-- TOC entry 6075 (class 0 OID 0)
-- Dependencies: 370
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_otros_id_seq OWNED BY precorte_otros.id;


--
-- TOC entry 579 (class 1259 OID 94570)
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
-- TOC entry 578 (class 1259 OID 94568)
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
-- TOC entry 6076 (class 0 OID 0)
-- Dependencies: 578
-- Name: prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_cab_id_seq OWNED BY prod_cab.id;


--
-- TOC entry 581 (class 1259 OID 94585)
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
-- TOC entry 580 (class 1259 OID 94583)
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
-- TOC entry 6077 (class 0 OID 0)
-- Dependencies: 580
-- Name: prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE prod_det_id_seq OWNED BY prod_det.id;


--
-- TOC entry 595 (class 1259 OID 94696)
-- Name: production_order_inputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_order_inputs (
    id bigint NOT NULL,
    production_order_id bigint NOT NULL,
    item_id bigint NOT NULL,
    inventory_batch_id bigint,
    qty numeric(18,6) NOT NULL,
    uom character varying(20) NOT NULL,
    meta jsonb,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE production_order_inputs OWNER TO postgres;

--
-- TOC entry 594 (class 1259 OID 94694)
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
-- TOC entry 6078 (class 0 OID 0)
-- Dependencies: 594
-- Name: production_order_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_inputs_id_seq OWNED BY production_order_inputs.id;


--
-- TOC entry 597 (class 1259 OID 94710)
-- Name: production_order_outputs; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_order_outputs (
    id bigint NOT NULL,
    production_order_id bigint NOT NULL,
    item_id bigint NOT NULL,
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
-- TOC entry 596 (class 1259 OID 94708)
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
-- TOC entry 6079 (class 0 OID 0)
-- Dependencies: 596
-- Name: production_order_outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_order_outputs_id_seq OWNED BY production_order_outputs.id;


--
-- TOC entry 593 (class 1259 OID 94673)
-- Name: production_orders; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE production_orders (
    id bigint NOT NULL,
    folio character varying(40),
    recipe_id bigint,
    item_id bigint,
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
-- TOC entry 592 (class 1259 OID 94671)
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
-- TOC entry 6080 (class 0 OID 0)
-- Dependencies: 592
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE production_orders_id_seq OWNED BY production_orders.id;


--
-- TOC entry 458 (class 1259 OID 92349)
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
-- TOC entry 623 (class 1259 OID 94980)
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
-- TOC entry 622 (class 1259 OID 94978)
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
-- TOC entry 6081 (class 0 OID 0)
-- Dependencies: 622
-- Name: purchase_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_documents_id_seq OWNED BY purchase_documents.id;


--
-- TOC entry 621 (class 1259 OID 94965)
-- Name: purchase_order_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_order_lines (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    request_line_id bigint,
    item_id bigint NOT NULL,
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
-- TOC entry 620 (class 1259 OID 94963)
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
-- TOC entry 6082 (class 0 OID 0)
-- Dependencies: 620
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_order_lines_id_seq OWNED BY purchase_order_lines.id;


--
-- TOC entry 619 (class 1259 OID 94945)
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
-- TOC entry 618 (class 1259 OID 94943)
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
-- TOC entry 6083 (class 0 OID 0)
-- Dependencies: 618
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_orders_id_seq OWNED BY purchase_orders.id;


--
-- TOC entry 613 (class 1259 OID 94896)
-- Name: purchase_request_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_request_lines (
    id bigint NOT NULL,
    request_id bigint NOT NULL,
    item_id bigint NOT NULL,
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
-- TOC entry 612 (class 1259 OID 94894)
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
-- TOC entry 6084 (class 0 OID 0)
-- Dependencies: 612
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_request_lines_id_seq OWNED BY purchase_request_lines.id;


--
-- TOC entry 611 (class 1259 OID 94877)
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
-- TOC entry 6085 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.fecha_requerida IS 'Fecha
  límite operativa';


--
-- TOC entry 6086 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- TOC entry 6087 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- TOC entry 6088 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- TOC entry 6089 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.origen_suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.origen_suggestion_id IS 'FK a purchase_suggestions - si fue generada automáticamente';


--
-- TOC entry 610 (class 1259 OID 94875)
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
-- TOC entry 6090 (class 0 OID 0)
-- Dependencies: 610
-- Name: purchase_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_requests_id_seq OWNED BY purchase_requests.id;


--
-- TOC entry 654 (class 1259 OID 95414)
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
-- TOC entry 6091 (class 0 OID 0)
-- Dependencies: 654
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- TOC entry 6092 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- TOC entry 6093 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- TOC entry 6094 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- TOC entry 6095 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- TOC entry 6096 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- TOC entry 6097 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- TOC entry 6098 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- TOC entry 6099 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.proveedor_sugerido_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.proveedor_sugerido_id IS 'FK a selemti.cat_proveedores.id';


--
-- TOC entry 653 (class 1259 OID 95412)
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
-- TOC entry 6100 (class 0 OID 0)
-- Dependencies: 653
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestion_lines_id_seq OWNED BY purchase_suggestion_lines.id;


--
-- TOC entry 652 (class 1259 OID 95364)
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
    sugerido_por_user_id integer,
    revisado_por_user_id integer,
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
-- TOC entry 6101 (class 0 OID 0)
-- Dependencies: 652
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- TOC entry 6102 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- TOC entry 6103 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- TOC entry 6104 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- TOC entry 6105 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- TOC entry 6106 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6107 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 6108 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- TOC entry 6109 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.dias_analisis; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.dias_analisis IS 'Días usados para calcular consumo promedio';


--
-- TOC entry 651 (class 1259 OID 95362)
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
-- TOC entry 6110 (class 0 OID 0)
-- Dependencies: 651
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_suggestions_id_seq OWNED BY purchase_suggestions.id;


--
-- TOC entry 617 (class 1259 OID 94930)
-- Name: purchase_vendor_quote_lines; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE purchase_vendor_quote_lines (
    id bigint NOT NULL,
    quote_id bigint NOT NULL,
    request_line_id bigint NOT NULL,
    item_id bigint NOT NULL,
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
-- TOC entry 616 (class 1259 OID 94928)
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
-- TOC entry 6111 (class 0 OID 0)
-- Dependencies: 616
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quote_lines_id_seq OWNED BY purchase_vendor_quote_lines.id;


--
-- TOC entry 615 (class 1259 OID 94911)
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
-- TOC entry 614 (class 1259 OID 94909)
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
-- TOC entry 6112 (class 0 OID 0)
-- Dependencies: 614
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE purchase_vendor_quotes_id_seq OWNED BY purchase_vendor_quotes.id;


--
-- TOC entry 459 (class 1259 OID 92356)
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
-- TOC entry 399 (class 1259 OID 92015)
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
-- TOC entry 6113 (class 0 OID 0)
-- Dependencies: 399
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


--
-- TOC entry 587 (class 1259 OID 94623)
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
-- TOC entry 586 (class 1259 OID 94621)
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
-- TOC entry 6114 (class 0 OID 0)
-- Dependencies: 586
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_adjuntos_id_seq OWNED BY recepcion_adjuntos.id;


--
-- TOC entry 460 (class 1259 OID 92362)
-- Name: recepcion_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recepcion_cab (
    id bigint NOT NULL,
    sucursal_id text NOT NULL,
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
    total_canonico numeric(15,4)
);


ALTER TABLE recepcion_cab OWNER TO postgres;

--
-- TOC entry 400 (class 1259 OID 92017)
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
-- TOC entry 6115 (class 0 OID 0)
-- Dependencies: 400
-- Name: recepcion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_cab_id_seq OWNED BY recepcion_cab.id;


--
-- TOC entry 461 (class 1259 OID 92369)
-- Name: recepcion_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recepcion_det (
    id bigint NOT NULL,
    recepcion_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    bodega_id integer NOT NULL,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL,
    costo_unit numeric(14,6) NOT NULL,
    lote_id bigint,
    temperatura numeric(6,2),
    doc_url text,
    meta jsonb
);


ALTER TABLE recepcion_det OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 92019)
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
-- TOC entry 6116 (class 0 OID 0)
-- Dependencies: 401
-- Name: recepcion_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recepcion_det_id_seq OWNED BY recepcion_det.id;


--
-- TOC entry 462 (class 1259 OID 92375)
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
-- TOC entry 463 (class 1259 OID 92383)
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
-- TOC entry 6117 (class 0 OID 0)
-- Dependencies: 463
-- Name: TABLE receta_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_cab IS 'Cabecera de recetas y platos del menÃº.';


--
-- TOC entry 464 (class 1259 OID 92397)
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
-- TOC entry 6118 (class 0 OID 0)
-- Dependencies: 464
-- Name: TABLE receta_det; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_det IS 'Detalle de ingredientes por versiÃ³n de receta.';


--
-- TOC entry 402 (class 1259 OID 92021)
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
-- TOC entry 6119 (class 0 OID 0)
-- Dependencies: 402
-- Name: receta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_det_id_seq OWNED BY receta_det.id;


--
-- TOC entry 403 (class 1259 OID 92023)
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
-- TOC entry 6120 (class 0 OID 0)
-- Dependencies: 403
-- Name: receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_id_seq OWNED BY receta.id;


--
-- TOC entry 465 (class 1259 OID 92408)
-- Name: receta_insumo; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE receta_insumo (
    id bigint NOT NULL,
    receta_version_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    cantidad numeric(14,6) NOT NULL
);


ALTER TABLE receta_insumo OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 92025)
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
-- TOC entry 6121 (class 0 OID 0)
-- Dependencies: 404
-- Name: receta_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_insumo_id_seq OWNED BY receta_insumo.id;


--
-- TOC entry 466 (class 1259 OID 92411)
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
-- TOC entry 405 (class 1259 OID 92027)
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
-- TOC entry 6122 (class 0 OID 0)
-- Dependencies: 405
-- Name: receta_shadow_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_shadow_id_seq OWNED BY receta_shadow.id;


--
-- TOC entry 467 (class 1259 OID 92424)
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
-- TOC entry 6123 (class 0 OID 0)
-- Dependencies: 467
-- Name: TABLE receta_version; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_version IS 'Control de versiones de recetas.';


--
-- TOC entry 406 (class 1259 OID 92029)
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
-- TOC entry 6124 (class 0 OID 0)
-- Dependencies: 406
-- Name: receta_version_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_version_id_seq OWNED BY receta_version.id;


--
-- TOC entry 554 (class 1259 OID 94364)
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
-- TOC entry 553 (class 1259 OID 94362)
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
-- TOC entry 6125 (class 0 OID 0)
-- Dependencies: 553
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_history_id_seq OWNED BY recipe_cost_history.id;


--
-- TOC entry 633 (class 1259 OID 95057)
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
-- TOC entry 632 (class 1259 OID 95055)
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
-- TOC entry 6126 (class 0 OID 0)
-- Dependencies: 632
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_extended_cost_history_id_seq OWNED BY recipe_extended_cost_history.id;


--
-- TOC entry 627 (class 1259 OID 95010)
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
-- TOC entry 626 (class 1259 OID 95008)
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
-- TOC entry 6127 (class 0 OID 0)
-- Dependencies: 626
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_labor_steps_id_seq OWNED BY recipe_labor_steps.id;


--
-- TOC entry 631 (class 1259 OID 95043)
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
-- TOC entry 630 (class 1259 OID 95041)
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
-- TOC entry 6128 (class 0 OID 0)
-- Dependencies: 630
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_overhead_allocations_id_seq OWNED BY recipe_overhead_allocations.id;


--
-- TOC entry 552 (class 1259 OID 94355)
-- Name: recipe_version_items; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE recipe_version_items (
    id bigint NOT NULL,
    recipe_version_id bigint NOT NULL,
    item_id bigint NOT NULL,
    qty numeric(14,6) NOT NULL,
    uom_receta character varying(20) NOT NULL
);


ALTER TABLE recipe_version_items OWNER TO postgres;

--
-- TOC entry 551 (class 1259 OID 94353)
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
-- TOC entry 6129 (class 0 OID 0)
-- Dependencies: 551
-- Name: recipe_version_items_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_version_items_id_seq OWNED BY recipe_version_items.id;


--
-- TOC entry 550 (class 1259 OID 94341)
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
-- TOC entry 549 (class 1259 OID 94339)
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
-- TOC entry 6130 (class 0 OID 0)
-- Dependencies: 549
-- Name: recipe_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_versions_id_seq OWNED BY recipe_versions.id;


--
-- TOC entry 649 (class 1259 OID 95332)
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
-- TOC entry 6131 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- TOC entry 6132 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- TOC entry 6133 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- TOC entry 6134 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- TOC entry 6135 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.item_id IS 'FK to items.id';


--
-- TOC entry 6136 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- TOC entry 6137 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- TOC entry 6138 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- TOC entry 6139 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- TOC entry 6140 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- TOC entry 6141 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- TOC entry 6142 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- TOC entry 6143 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- TOC entry 6144 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- TOC entry 6145 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- TOC entry 6146 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- TOC entry 6147 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.notas IS 'Notas del usuario';


--
-- TOC entry 6148 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.meta; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.meta IS 'Metadata: proveedor preferido, evento, etc.';


--
-- TOC entry 648 (class 1259 OID 95330)
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
-- TOC entry 6149 (class 0 OID 0)
-- Dependencies: 648
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE replenishment_suggestions_id_seq OWNED BY replenishment_suggestions.id;


--
-- TOC entry 645 (class 1259 OID 95189)
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
-- TOC entry 644 (class 1259 OID 95187)
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
-- TOC entry 6150 (class 0 OID 0)
-- Dependencies: 644
-- Name: report_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_definitions_id_seq OWNED BY report_definitions.id;


--
-- TOC entry 647 (class 1259 OID 95203)
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
-- TOC entry 646 (class 1259 OID 95201)
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
-- TOC entry 6151 (class 0 OID 0)
-- Dependencies: 646
-- Name: report_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE report_runs_id_seq OWNED BY report_runs.id;


--
-- TOC entry 468 (class 1259 OID 92433)
-- Name: rol; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE rol (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


ALTER TABLE rol OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 92031)
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
-- TOC entry 6152 (class 0 OID 0)
-- Dependencies: 407
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE rol_id_seq OWNED BY rol.id;


--
-- TOC entry 469 (class 1259 OID 92439)
-- Name: role_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE role_has_permissions OWNER TO postgres;

--
-- TOC entry 470 (class 1259 OID 92442)
-- Name: roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    display_name character varying(255),
    description text
);


ALTER TABLE roles OWNER TO postgres;

--
-- TOC entry 408 (class 1259 OID 92033)
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
-- TOC entry 6153 (class 0 OID 0)
-- Dependencies: 408
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- TOC entry 545 (class 1259 OID 94295)
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
-- TOC entry 372 (class 1259 OID 90356)
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
-- TOC entry 6154 (class 0 OID 0)
-- Dependencies: 372
-- Name: sesion_cajon_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE sesion_cajon_id_seq OWNED BY sesion_cajon.id;


--
-- TOC entry 471 (class 1259 OID 92448)
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
-- TOC entry 575 (class 1259 OID 94542)
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
-- TOC entry 574 (class 1259 OID 94540)
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
-- TOC entry 6155 (class 0 OID 0)
-- Dependencies: 574
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_cab_id_seq OWNED BY sol_prod_cab.id;


--
-- TOC entry 577 (class 1259 OID 94556)
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
-- TOC entry 576 (class 1259 OID 94554)
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
-- TOC entry 6156 (class 0 OID 0)
-- Dependencies: 576
-- Name: sol_prod_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sol_prod_det_id_seq OWNED BY sol_prod_det.id;


--
-- TOC entry 472 (class 1259 OID 92454)
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
-- TOC entry 409 (class 1259 OID 92035)
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
-- TOC entry 6157 (class 0 OID 0)
-- Dependencies: 409
-- Name: stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE stock_policy_id_seq OWNED BY stock_policy.id;


--
-- TOC entry 473 (class 1259 OID 92464)
-- Name: sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE sucursal OWNER TO postgres;

--
-- TOC entry 474 (class 1259 OID 92471)
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
-- TOC entry 410 (class 1259 OID 92037)
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
-- TOC entry 6158 (class 0 OID 0)
-- Dependencies: 410
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sucursal_almacen_terminal_id_seq OWNED BY sucursal_almacen_terminal.id;


--
-- TOC entry 475 (class 1259 OID 92479)
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
    CONSTRAINT ticket_det_consumo_qty_canonica_check CHECK ((qty_canonica > (0)::numeric))
);


ALTER TABLE ticket_det_consumo OWNER TO postgres;

--
-- TOC entry 411 (class 1259 OID 92039)
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
-- TOC entry 6159 (class 0 OID 0)
-- Dependencies: 411
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


--
-- TOC entry 656 (class 1259 OID 95507)
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
-- TOC entry 6160 (class 0 OID 0)
-- Dependencies: 656
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- TOC entry 6161 (class 0 OID 0)
-- Dependencies: 656
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- TOC entry 6162 (class 0 OID 0)
-- Dependencies: 656
-- Name: COLUMN ticket_item_modifiers.precio_extra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.precio_extra IS 'Sobrecargo aplicado por el POS.';


--
-- TOC entry 655 (class 1259 OID 95505)
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
-- TOC entry 6163 (class 0 OID 0)
-- Dependencies: 655
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_item_modifiers_id_seq OWNED BY ticket_item_modifiers.id;


--
-- TOC entry 476 (class 1259 OID 92487)
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
-- TOC entry 412 (class 1259 OID 92041)
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
-- TOC entry 6164 (class 0 OID 0)
-- Dependencies: 412
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_cab_id_seq OWNED BY ticket_venta_cab.id;


--
-- TOC entry 477 (class 1259 OID 92495)
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
-- TOC entry 413 (class 1259 OID 92043)
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
-- TOC entry 6165 (class 0 OID 0)
-- Dependencies: 413
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


--
-- TOC entry 583 (class 1259 OID 94599)
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
-- TOC entry 582 (class 1259 OID 94597)
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
-- TOC entry 6166 (class 0 OID 0)
-- Dependencies: 582
-- Name: transfer_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_cab_id_seq OWNED BY transfer_cab.id;


--
-- TOC entry 585 (class 1259 OID 94609)
-- Name: transfer_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE transfer_det (
    id bigint NOT NULL,
    transfer_id bigint,
    item_id integer NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    cantidad_despachada numeric(12,3),
    cantidad_recibida numeric(12,3),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE transfer_det OWNER TO postgres;

--
-- TOC entry 584 (class 1259 OID 94607)
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
-- TOC entry 6167 (class 0 OID 0)
-- Dependencies: 584
-- Name: transfer_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE transfer_det_id_seq OWNED BY transfer_det.id;


--
-- TOC entry 478 (class 1259 OID 92505)
-- Name: traspaso_cab; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE traspaso_cab (
    id bigint NOT NULL,
    from_bodega_id integer NOT NULL,
    to_bodega_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    usuario_id bigint,
    meta jsonb
);


ALTER TABLE traspaso_cab OWNER TO postgres;

--
-- TOC entry 414 (class 1259 OID 92045)
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
-- TOC entry 6168 (class 0 OID 0)
-- Dependencies: 414
-- Name: traspaso_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_cab_id_seq OWNED BY traspaso_cab.id;


--
-- TOC entry 479 (class 1259 OID 92512)
-- Name: traspaso_det; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE traspaso_det (
    id bigint NOT NULL,
    traspaso_id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    lote_id bigint,
    qty numeric(14,6) NOT NULL,
    um_id integer NOT NULL
);


ALTER TABLE traspaso_det OWNER TO postgres;

--
-- TOC entry 415 (class 1259 OID 92047)
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
-- TOC entry 6169 (class 0 OID 0)
-- Dependencies: 415
-- Name: traspaso_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_det_id_seq OWNED BY traspaso_det.id;


--
-- TOC entry 480 (class 1259 OID 92515)
-- Name: unidad_medida; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE unidad_medida (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    tipo text NOT NULL,
    es_base boolean DEFAULT false NOT NULL,
    factor_a_base numeric(14,6) DEFAULT 1.0 NOT NULL,
    decimales integer DEFAULT 2 NOT NULL,
    CONSTRAINT unidad_medida_tipo_check CHECK ((tipo = ANY (ARRAY['PESO'::text, 'VOLUMEN'::text, 'UNIDAD'::text, 'TIEMPO'::text])))
);


ALTER TABLE unidad_medida OWNER TO postgres;

--
-- TOC entry 416 (class 1259 OID 92049)
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
-- TOC entry 6170 (class 0 OID 0)
-- Dependencies: 416
-- Name: unidad_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidad_medida_id_seq OWNED BY unidad_medida.id;


--
-- TOC entry 481 (class 1259 OID 92525)
-- Name: unidades_medida; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE unidades_medida (
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


ALTER TABLE unidades_medida OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 92051)
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
-- TOC entry 6171 (class 0 OID 0)
-- Dependencies: 417
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida.id;


--
-- TOC entry 482 (class 1259 OID 92536)
-- Name: uom_conversion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE uom_conversion (
    id integer NOT NULL,
    origen_id integer NOT NULL,
    destino_id integer NOT NULL,
    factor numeric(14,6) NOT NULL,
    CONSTRAINT uom_conversion_check CHECK ((origen_id <> destino_id)),
    CONSTRAINT uom_conversion_factor_check CHECK ((factor > (0)::numeric))
);


ALTER TABLE uom_conversion OWNER TO postgres;

--
-- TOC entry 418 (class 1259 OID 92053)
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
-- TOC entry 6172 (class 0 OID 0)
-- Dependencies: 418
-- Name: uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE uom_conversion_id_seq OWNED BY uom_conversion.id;


--
-- TOC entry 483 (class 1259 OID 92541)
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
-- TOC entry 6173 (class 0 OID 0)
-- Dependencies: 483
-- Name: TABLE user_roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE user_roles IS 'AsignaciÃ³n de roles a usuarios.';


--
-- TOC entry 484 (class 1259 OID 92546)
-- Name: users; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE users (
    id integer NOT NULL,
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
-- TOC entry 6174 (class 0 OID 0)
-- Dependencies: 484
-- Name: TABLE users; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE users IS 'Usuarios del sistema con sus credenciales y estado.';


--
-- TOC entry 419 (class 1259 OID 92055)
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
-- TOC entry 6175 (class 0 OID 0)
-- Dependencies: 419
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 485 (class 1259 OID 92562)
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
-- TOC entry 420 (class 1259 OID 92057)
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
-- TOC entry 6176 (class 0 OID 0)
-- Dependencies: 420
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE usuario_id_seq OWNED BY usuario.id;


--
-- TOC entry 486 (class 1259 OID 93651)
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
-- TOC entry 487 (class 1259 OID 93656)
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
     LEFT JOIN unidades_medida um ON ((um.id = i.unidad_medida_id)));


ALTER TABLE v_items_con_uom OWNER TO postgres;

--
-- TOC entry 488 (class 1259 OID 93661)
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
-- TOC entry 489 (class 1259 OID 93666)
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
-- TOC entry 490 (class 1259 OID 93671)
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
-- TOC entry 491 (class 1259 OID 93676)
-- Name: vw_anulaciones_por_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_anulaciones_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tx.transaction_time) AS fecha,
    (sum(
        CASE
            WHEN ((tx.payment_type)::text = ANY (ARRAY[('REFUND'::character varying)::text, ('VOID_TRANS'::character varying)::text])) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS anulaciones_total
   FROM (public.transactions tx
     JOIN public.ticket tk ON ((tk.id = tx.ticket_id)))
  GROUP BY tk.terminal_id, (date(tx.transaction_time));


ALTER TABLE vw_anulaciones_por_terminal_dia OWNER TO postgres;

--
-- TOC entry 492 (class 1259 OID 93681)
-- Name: vw_bom_menu_item; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_bom_menu_item AS
 SELECT pm.pos_system,
    pm.plu,
    pm.tipo,
    ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint AS receta_version_id,
    rins.insumo_id,
    (rins.cantidad * COALESCE(((row_to_json(pm.*) ->> 'factor_insumo'::text))::numeric, (1)::numeric)) AS cantidad_por_menu
   FROM ((pos_map pm
     LEFT JOIN receta_version rv ON ((rv.id = ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint)))
     LEFT JOIN receta_insumo rins ON ((rins.receta_version_id = rv.id)))
  WHERE (pm.tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text]));


ALTER TABLE vw_bom_menu_item OWNER TO postgres;

--
-- TOC entry 500 (class 1259 OID 93720)
-- Name: vw_consumo_teorico; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_consumo_teorico AS
 SELECT v.fecha,
    v.sucursal_id,
    bmi.insumo_id,
    sum((v.unidades * COALESCE(bmi.cantidad_por_menu, (0)::numeric))) AS consumo_teorico
   FROM (vw_ventas_por_item v
     JOIN vw_bom_menu_item bmi ON ((bmi.plu = v.plu)))
  GROUP BY v.fecha, v.sucursal_id, bmi.insumo_id;


ALTER TABLE vw_consumo_teorico OWNER TO postgres;

--
-- TOC entry 501 (class 1259 OID 93724)
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
-- TOC entry 502 (class 1259 OID 93729)
-- Name: vw_consumo_vs_movimientos; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_consumo_vs_movimientos AS
 WITH "real" AS (
         SELECT (date_trunc('day'::text, k.ts))::date AS fecha,
            (k.sucursal_id)::text AS sucursal_id,
            (NULLIF(k.item_key, ''::text))::bigint AS insumo_id,
            sum(
                CASE
                    WHEN ((k.tipo)::text = ANY (ARRAY[('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text])) THEN k.qty
                    ELSE (0)::numeric
                END) AS consumo_real
           FROM vw_kardex k
          GROUP BY ((date_trunc('day'::text, k.ts))::date), (k.sucursal_id)::text, (NULLIF(k.item_key, ''::text))::bigint
        )
 SELECT COALESCE(t.fecha, r.fecha) AS fecha,
    COALESCE(t.sucursal_id, r.sucursal_id) AS sucursal_id,
    COALESCE(t.insumo_id, r.insumo_id) AS insumo_id,
    COALESCE(t.consumo_teorico, (0)::numeric) AS consumo_teorico,
    COALESCE(r.consumo_real, (0)::numeric) AS consumo_real,
    (COALESCE(r.consumo_real, (0)::numeric) - COALESCE(t.consumo_teorico, (0)::numeric)) AS diferencia
   FROM (vw_consumo_teorico t
     FULL JOIN "real" r ON (((r.fecha = t.fecha) AND (r.sucursal_id = t.sucursal_id) AND (r.insumo_id = t.insumo_id))));


ALTER TABLE vw_consumo_vs_movimientos OWNER TO postgres;

--
-- TOC entry 503 (class 1259 OID 93734)
-- Name: vw_costos_insumo_actual; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_costos_insumo_actual AS
 SELECT DISTINCT ON (h.insumo_id) h.insumo_id,
    h.fecha_efectiva,
    h.costo_wac,
    h.algoritmo_principal
   FROM hist_cost_insumo h
  ORDER BY h.insumo_id, h.fecha_efectiva DESC;


ALTER TABLE vw_costos_insumo_actual OWNER TO postgres;

--
-- TOC entry 541 (class 1259 OID 94194)
-- Name: vw_dashboard_formas_pago; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_dashboard_formas_pago AS
 SELECT (t.transaction_time)::date AS fecha,
    COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text) AS sucursal_id,
    COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp,
    (sum(t.amount))::numeric(12,2) AS monto
   FROM (((public.transactions t
     LEFT JOIN sesion_cajon s ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
     LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
     LEFT JOIN public.terminal term ON ((term.id = t.terminal_id)))
  WHERE (t.transaction_time IS NOT NULL)
  GROUP BY ((t.transaction_time)::date), COALESCE(NULLIF((term.location)::text, ''::text), 'Sin sucursal'::text), COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text));


ALTER TABLE vw_dashboard_formas_pago OWNER TO postgres;

--
-- TOC entry 535 (class 1259 OID 94168)
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
-- TOC entry 542 (class 1259 OID 94199)
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
-- TOC entry 536 (class 1259 OID 94173)
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
-- TOC entry 537 (class 1259 OID 94177)
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
-- TOC entry 539 (class 1259 OID 94185)
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
-- TOC entry 540 (class 1259 OID 94190)
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
-- TOC entry 538 (class 1259 OID 94181)
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
-- TOC entry 504 (class 1259 OID 93738)
-- Name: vw_descuentos_por_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_descuentos_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tk.closing_date) AS fecha,
    (sum(COALESCE(td.value, (0)::double precision)))::numeric(12,2) AS descuentos_ticket,
    (sum(COALESCE(tid.amount, (0)::double precision)))::numeric(12,2) AS descuentos_items,
    (sum(
        CASE
            WHEN (COALESCE(tk.total_price, (0)::double precision) <= COALESCE(tk.total_discount, (0)::double precision)) THEN LEAST(tk.total_discount, tk.total_price)
            ELSE (0)::double precision
        END))::numeric(12,2) AS descuentos_100,
    (GREATEST(((sum(COALESCE(td.value, (0)::double precision)) + sum(COALESCE(tid.amount, (0)::double precision))) - sum(
        CASE
            WHEN (COALESCE(tk.total_price, (0)::double precision) <= COALESCE(tk.total_discount, (0)::double precision)) THEN LEAST(tk.total_discount, tk.total_price)
            ELSE (0)::double precision
        END)), (0)::double precision))::numeric(12,2) AS descuentos_parciales,
    ((sum(COALESCE(td.value, (0)::double precision)) + sum(COALESCE(tid.amount, (0)::double precision))))::numeric(12,2) AS total_descuentos
   FROM (((public.ticket tk
     LEFT JOIN public.ticket_discount td ON ((td.ticket_id = tk.id)))
     LEFT JOIN public.ticket_item ti ON ((ti.ticket_id = tk.id)))
     LEFT JOIN public.ticket_item_discount tid ON ((tid.ticket_itemid = ti.id)))
  WHERE ((tk.paid = true) AND (tk.voided = false))
  GROUP BY tk.terminal_id, (date(tk.closing_date));


ALTER TABLE vw_descuentos_por_terminal_dia OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 93743)
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
-- TOC entry 506 (class 1259 OID 93747)
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
-- TOC entry 559 (class 1259 OID 94426)
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
-- TOC entry 560 (class 1259 OID 94431)
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
-- TOC entry 508 (class 1259 OID 93755)
-- Name: vw_kpis_sucursal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_kpis_sucursal_dia AS
 WITH k AS (
         SELECT (date_trunc('day'::text, c.apertura_ts))::date AS fecha,
            c.terminal_id,
            count(*) AS sesiones,
            sum(c.sistema_efectivo) AS sistema_efectivo,
            sum(c.sistema_no_efectivo) AS sistema_no_efectivo,
            sum(c.sistema_descuentos) AS descuentos,
            sum(c.sistema_anulaciones) AS anulaciones,
            sum(c.sistema_retiros) AS retiros,
            sum(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
            sum(c.sistema_efectivo_esperado) AS efectivo_esperado,
            sum(c.declarado_precorte_efectivo) AS declarado_precorte,
            sum(c.declarado_post_efectivo) AS declarado_post_efectivo,
            sum(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
            sum(c.diferencia_efectivo) AS diferencia_efectivo,
            sum(c.diferencia_no_efectivo) AS diferencia_no_efectivo
           FROM vw_conciliacion_sesion c
          GROUP BY ((date_trunc('day'::text, c.apertura_ts))::date), c.terminal_id
        )
 SELECT k.fecha,
    COALESCE(m.sucursal_id, ''::text) AS sucursal_id,
    sum(k.sesiones) AS sesiones,
    sum(k.sistema_efectivo) AS sistema_efectivo,
    sum(k.sistema_no_efectivo) AS sistema_no_efectivo,
    sum(k.descuentos) AS descuentos,
    sum(k.anulaciones) AS anulaciones,
    sum(k.retiros) AS retiros,
    sum(k.reembolsos_efectivo) AS reembolsos_efectivo,
    sum(k.efectivo_esperado) AS efectivo_esperado,
    sum(k.declarado_precorte) AS declarado_precorte,
    sum(k.declarado_post_efectivo) AS declarado_post_efectivo,
    sum(k.declarado_post_tarjetas) AS declarado_post_tarjetas,
    sum(k.diferencia_efectivo) AS diferencia_efectivo,
    sum(k.diferencia_no_efectivo) AS diferencia_no_efectivo
   FROM (k
     LEFT JOIN vw_terminal_sucursal_dia m ON (((m.fecha = k.fecha) AND (m.terminal_id = k.terminal_id))))
  GROUP BY k.fecha, COALESCE(m.sucursal_id, ''::text);


ALTER TABLE vw_kpis_sucursal_dia OWNER TO postgres;

--
-- TOC entry 509 (class 1259 OID 93760)
-- Name: vw_kpis_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_kpis_terminal_dia AS
 SELECT (date_trunc('day'::text, c.apertura_ts))::date AS fecha,
    c.terminal_id,
    count(*) AS sesiones,
    sum(c.sistema_efectivo) AS sistema_efectivo,
    sum(c.sistema_no_efectivo) AS sistema_no_efectivo,
    sum(c.sistema_descuentos) AS descuentos,
    sum(c.sistema_anulaciones) AS anulaciones,
    sum(c.sistema_retiros) AS retiros,
    sum(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
    sum(c.sistema_efectivo_esperado) AS efectivo_esperado,
    sum(c.declarado_precorte_efectivo) AS declarado_precorte,
    sum(c.declarado_post_efectivo) AS declarado_post_efectivo,
    sum(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
    sum(c.diferencia_efectivo) AS diferencia_efectivo,
    sum(c.diferencia_no_efectivo) AS diferencia_no_efectivo
   FROM vw_conciliacion_sesion c
  GROUP BY ((date_trunc('day'::text, c.apertura_ts))::date), c.terminal_id;


ALTER TABLE vw_kpis_terminal_dia OWNER TO postgres;

--
-- TOC entry 510 (class 1259 OID 93765)
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
-- TOC entry 511 (class 1259 OID 93770)
-- Name: vw_pagos_por_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_pagos_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tx.transaction_time) AS fecha,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CASH'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS efectivo,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CREDIT_CARD'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS credito,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'DEBIT_CARD'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS debito,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) = 'TRANSFER'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS transfer,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) = 'GIFT_CERT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS gift,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) <> ALL (ARRAY['TRANSFER'::text, 'GIFT_CERT'::text]))) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS custom,
    ((sum(
        CASE
            WHEN (((tx.payment_type)::text = ANY (ARRAY[('CREDIT_CARD'::character varying)::text, ('DEBIT_CARD'::character varying)::text])) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END) + sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END)))::numeric(12,2) AS total_tarjetas
   FROM (public.transactions tx
     JOIN public.ticket tk ON ((tk.id = tx.ticket_id)))
  GROUP BY tk.terminal_id, (date(tx.transaction_time));


ALTER TABLE vw_pagos_por_terminal_dia OWNER TO postgres;

--
-- TOC entry 512 (class 1259 OID 93775)
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
-- TOC entry 513 (class 1259 OID 93780)
-- Name: vw_receta_completa; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_receta_completa AS
 SELECT rv.id AS receta_version_id,
    rv.receta_id,
    rv.version,
    rins.insumo_id,
    rins.cantidad
   FROM (receta_version rv
     JOIN receta_insumo rins ON ((rins.receta_version_id = rv.id)));


ALTER TABLE vw_receta_completa OWNER TO postgres;

--
-- TOC entry 650 (class 1259 OID 95356)
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
-- TOC entry 514 (class 1259 OID 93784)
-- Name: vw_resumen_conciliacion_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_resumen_conciliacion_terminal_dia AS
 WITH ventas AS (
         SELECT ticket.terminal_id,
            date(ticket.closing_date) AS fecha,
            (sum((ticket.total_price - ticket.total_discount)))::numeric(12,2) AS ventas_netas
           FROM public.ticket
          WHERE ((ticket.paid = true) AND (ticket.voided = false))
          GROUP BY ticket.terminal_id, (date(ticket.closing_date))
        ), pagos AS (
         SELECT vw_pagos_por_terminal_dia.terminal_id,
            vw_pagos_por_terminal_dia.fecha,
            (sum(vw_pagos_por_terminal_dia.efectivo))::numeric(12,2) AS efectivo,
            (sum(vw_pagos_por_terminal_dia.credito))::numeric(12,2) AS credito,
            (sum(vw_pagos_por_terminal_dia.debito))::numeric(12,2) AS debito,
            (sum(vw_pagos_por_terminal_dia.transfer))::numeric(12,2) AS transfer,
            (sum(vw_pagos_por_terminal_dia.custom))::numeric(12,2) AS custom,
            (sum(vw_pagos_por_terminal_dia.gift))::numeric(12,2) AS gift,
            (sum(vw_pagos_por_terminal_dia.total_tarjetas))::numeric(12,2) AS total_tarjetas
           FROM vw_pagos_por_terminal_dia
          GROUP BY vw_pagos_por_terminal_dia.terminal_id, vw_pagos_por_terminal_dia.fecha
        ), descuentos AS (
         SELECT vw_descuentos_por_terminal_dia.terminal_id,
            vw_descuentos_por_terminal_dia.fecha,
            vw_descuentos_por_terminal_dia.descuentos_ticket,
            vw_descuentos_por_terminal_dia.descuentos_items,
            vw_descuentos_por_terminal_dia.descuentos_100,
            vw_descuentos_por_terminal_dia.descuentos_parciales,
            vw_descuentos_por_terminal_dia.total_descuentos
           FROM vw_descuentos_por_terminal_dia
        ), anu AS (
         SELECT vw_anulaciones_por_terminal_dia.terminal_id,
            vw_anulaciones_por_terminal_dia.fecha,
            vw_anulaciones_por_terminal_dia.anulaciones_total
           FROM vw_anulaciones_por_terminal_dia
        )
 SELECT v.terminal_id,
    v.fecha,
    v.ventas_netas,
    p.efectivo,
    p.credito,
    p.debito,
    p.transfer,
    p.custom,
    p.gift,
    p.total_tarjetas,
    d.descuentos_ticket,
    d.descuentos_items,
    d.descuentos_100,
    d.descuentos_parciales,
    d.total_descuentos,
    a.anulaciones_total
   FROM (((ventas v
     LEFT JOIN pagos p USING (terminal_id, fecha))
     LEFT JOIN descuentos d USING (terminal_id, fecha))
     LEFT JOIN anu a USING (terminal_id, fecha));


ALTER TABLE vw_resumen_conciliacion_terminal_dia OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 93789)
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
-- TOC entry 516 (class 1259 OID 93794)
-- Name: vw_stock_actual; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_stock_actual AS
 SELECT COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)) AS item_key,
    (mi.sucursal_id)::text AS sucursal_id,
    sum(
        CASE
            WHEN ((mi.tipo)::text = ANY (ARRAY[('ENTRADA'::character varying)::text, ('RECEPCION'::character varying)::text, ('COMPRA'::character varying)::text, ('TRASPASO_IN'::character varying)::text])) THEN COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric)
            WHEN ((mi.tipo)::text = ANY (ARRAY[('SALIDA'::character varying)::text, ('MERMA'::character varying)::text, ('AJUSTE'::character varying)::text, ('TRASPASO_OUT'::character varying)::text])) THEN (- COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric))
            ELSE (0)::numeric
        END) AS stock
   FROM mov_inv mi
  GROUP BY COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)), (mi.sucursal_id)::text;


ALTER TABLE vw_stock_actual OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 93799)
-- Name: vw_stock_brechas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_stock_brechas AS
 SELECT sp.sucursal_id,
    sp.item_id,
    sp.min_qty,
    sp.max_qty,
    COALESCE(sa.stock, (0)::numeric) AS stock_actual,
    GREATEST((sp.min_qty - COALESCE(sa.stock, (0)::numeric)), (0)::numeric) AS faltante,
    GREATEST((COALESCE(sa.stock, (0)::numeric) - sp.max_qty), (0)::numeric) AS excedente
   FROM (stock_policy sp
     LEFT JOIN ( SELECT vw_stock_actual.item_key,
            vw_stock_actual.sucursal_id,
            sum(vw_stock_actual.stock) AS stock
           FROM vw_stock_actual
          GROUP BY vw_stock_actual.item_key, vw_stock_actual.sucursal_id) sa ON (((sa.item_key = sp.item_id) AND (sa.sucursal_id = sp.sucursal_id))));


ALTER TABLE vw_stock_brechas OWNER TO postgres;

--
-- TOC entry 518 (class 1259 OID 93804)
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
-- TOC entry 519 (class 1259 OID 93808)
-- Name: vw_stock_valorizado; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_stock_valorizado AS
 SELECT sa.item_key,
    sa.sucursal_id,
    sa.stock,
    ca.costo_wac,
    (sa.stock * COALESCE(ca.costo_wac, (0)::numeric)) AS valor
   FROM (vw_stock_actual sa
     LEFT JOIN vw_costos_insumo_actual ca ON ((ca.insumo_id = (NULLIF(sa.item_key, ''::text))::bigint)));


ALTER TABLE vw_stock_valorizado OWNER TO postgres;

--
-- TOC entry 520 (class 1259 OID 93812)
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
-- TOC entry 521 (class 1259 OID 93817)
-- Name: vw_ventas_por_familia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_ventas_por_familia AS
 SELECT v.fecha,
    v.sucursal_id,
    COALESCE(pm.tipo, 'DESCONOCIDO'::text) AS familia,
    sum(v.unidades) AS unidades,
    sum(v.venta_total) AS venta_total
   FROM (vw_ventas_por_item v
     LEFT JOIN pos_map pm ON ((pm.plu = v.plu)))
  GROUP BY v.fecha, v.sucursal_id, COALESCE(pm.tipo, 'DESCONOCIDO'::text);


ALTER TABLE vw_ventas_por_familia OWNER TO postgres;

--
-- TOC entry 522 (class 1259 OID 93821)
-- Name: vw_ventas_por_hora; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_ventas_por_hora AS
 SELECT date_trunc('hour'::text, base.hora) AS hora,
    base.sucursal_id,
    base.terminal_id,
    count(DISTINCT base.ticket_id) AS tickets,
    sum(base.total) AS venta_total
   FROM vw_dashboard_ticket_base base
  WHERE ((base.paid = true) AND (base.voided = false))
  GROUP BY (date_trunc('hour'::text, base.hora)), base.sucursal_id, base.terminal_id
  ORDER BY (date_trunc('hour'::text, base.hora)) DESC;


ALTER TABLE vw_ventas_por_hora OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 3724 (class 2604 OID 90396)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history ALTER COLUMN id SET DEFAULT nextval('action_history_id_seq'::regclass);


--
-- TOC entry 3725 (class 2604 OID 90397)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history ALTER COLUMN id SET DEFAULT nextval('attendence_history_id_seq'::regclass);


--
-- TOC entry 3726 (class 2604 OID 90398)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer ALTER COLUMN id SET DEFAULT nextval('cash_drawer_id_seq'::regclass);


--
-- TOC entry 3727 (class 2604 OID 90399)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass);


--
-- TOC entry 3728 (class 2604 OID 90400)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction ALTER COLUMN id SET DEFAULT nextval('cooking_instruction_id_seq'::regclass);


--
-- TOC entry 3729 (class 2604 OID 90401)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('coupon_and_discount_id_seq'::regclass);


--
-- TOC entry 3730 (class 2604 OID 90402)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency ALTER COLUMN id SET DEFAULT nextval('currency_id_seq'::regclass);


--
-- TOC entry 3731 (class 2604 OID 90403)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance ALTER COLUMN id SET DEFAULT nextval('currency_balance_id_seq'::regclass);


--
-- TOC entry 3732 (class 2604 OID 90404)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment ALTER COLUMN id SET DEFAULT nextval('custom_payment_id_seq'::regclass);


--
-- TOC entry 3733 (class 2604 OID 90405)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer ALTER COLUMN auto_id SET DEFAULT nextval('customer_auto_id_seq'::regclass);


--
-- TOC entry 3735 (class 2604 OID 90406)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info ALTER COLUMN id SET DEFAULT nextval('data_update_info_id_seq'::regclass);


--
-- TOC entry 3736 (class 2604 OID 90407)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address ALTER COLUMN id SET DEFAULT nextval('delivery_address_id_seq'::regclass);


--
-- TOC entry 3737 (class 2604 OID 90408)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge ALTER COLUMN id SET DEFAULT nextval('delivery_charge_id_seq'::regclass);


--
-- TOC entry 3738 (class 2604 OID 90409)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration ALTER COLUMN id SET DEFAULT nextval('delivery_configuration_id_seq'::regclass);


--
-- TOC entry 3739 (class 2604 OID 90410)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction ALTER COLUMN id SET DEFAULT nextval('delivery_instruction_id_seq'::regclass);


--
-- TOC entry 3740 (class 2604 OID 90411)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('drawer_assigned_history_id_seq'::regclass);


--
-- TOC entry 3741 (class 2604 OID 90412)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('drawer_pull_report_id_seq'::regclass);


--
-- TOC entry 3742 (class 2604 OID 90413)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('employee_in_out_history_id_seq'::regclass);


--
-- TOC entry 3743 (class 2604 OID 90414)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config ALTER COLUMN id SET DEFAULT nextval('global_config_id_seq'::regclass);


--
-- TOC entry 3744 (class 2604 OID 90415)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity ALTER COLUMN id SET DEFAULT nextval('gratuity_id_seq'::regclass);


--
-- TOC entry 3745 (class 2604 OID 90416)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print ALTER COLUMN id SET DEFAULT nextval('guest_check_print_id_seq'::regclass);


--
-- TOC entry 3746 (class 2604 OID 90417)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group ALTER COLUMN id SET DEFAULT nextval('inventory_group_id_seq'::regclass);


--
-- TOC entry 3747 (class 2604 OID 90418)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item ALTER COLUMN id SET DEFAULT nextval('inventory_item_id_seq'::regclass);


--
-- TOC entry 3748 (class 2604 OID 90419)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location ALTER COLUMN id SET DEFAULT nextval('inventory_location_id_seq'::regclass);


--
-- TOC entry 3749 (class 2604 OID 90420)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('inventory_meta_code_id_seq'::regclass);


--
-- TOC entry 3750 (class 2604 OID 90421)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction ALTER COLUMN id SET DEFAULT nextval('inventory_transaction_id_seq'::regclass);


--
-- TOC entry 3751 (class 2604 OID 90422)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit ALTER COLUMN id SET DEFAULT nextval('inventory_unit_id_seq'::regclass);


--
-- TOC entry 3752 (class 2604 OID 90423)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor ALTER COLUMN id SET DEFAULT nextval('inventory_vendor_id_seq'::regclass);


--
-- TOC entry 3753 (class 2604 OID 90424)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('inventory_warehouse_id_seq'::regclass);


--
-- TOC entry 3754 (class 2604 OID 90425)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_id_seq'::regclass);


--
-- TOC entry 3758 (class 2604 OID 90426)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_item_id_seq'::regclass);


--
-- TOC entry 3759 (class 2604 OID 90427)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category ALTER COLUMN id SET DEFAULT nextval('menu_category_id_seq'::regclass);


--
-- TOC entry 3760 (class 2604 OID 90428)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group ALTER COLUMN id SET DEFAULT nextval('menu_group_id_seq'::regclass);


--
-- TOC entry 3761 (class 2604 OID 90429)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item ALTER COLUMN id SET DEFAULT nextval('menu_item_id_seq'::regclass);


--
-- TOC entry 3762 (class 2604 OID 90430)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size ALTER COLUMN id SET DEFAULT nextval('menu_item_size_id_seq'::regclass);


--
-- TOC entry 3763 (class 2604 OID 90431)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier ALTER COLUMN id SET DEFAULT nextval('menu_modifier_id_seq'::regclass);


--
-- TOC entry 3764 (class 2604 OID 90432)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('menu_modifier_group_id_seq'::regclass);


--
-- TOC entry 3765 (class 2604 OID 90433)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass);


--
-- TOC entry 3766 (class 2604 OID 90434)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift ALTER COLUMN id SET DEFAULT nextval('menuitem_shift_id_seq'::regclass);


--
-- TOC entry 3767 (class 2604 OID 90435)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('modifier_multiplier_price_id_seq'::regclass);


--
-- TOC entry 3768 (class 2604 OID 90436)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type ALTER COLUMN id SET DEFAULT nextval('order_type_id_seq'::regclass);


--
-- TOC entry 3769 (class 2604 OID 90437)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit ALTER COLUMN id SET DEFAULT nextval('packaging_unit_id_seq'::regclass);


--
-- TOC entry 3770 (class 2604 OID 90438)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons ALTER COLUMN id SET DEFAULT nextval('payout_reasons_id_seq'::regclass);


--
-- TOC entry 3771 (class 2604 OID 90439)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients ALTER COLUMN id SET DEFAULT nextval('payout_recepients_id_seq'::regclass);


--
-- TOC entry 3772 (class 2604 OID 90440)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust ALTER COLUMN id SET DEFAULT nextval('pizza_crust_id_seq'::regclass);


--
-- TOC entry 3773 (class 2604 OID 90441)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('pizza_modifier_price_id_seq'::regclass);


--
-- TOC entry 3774 (class 2604 OID 90442)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price ALTER COLUMN id SET DEFAULT nextval('pizza_price_id_seq'::regclass);


--
-- TOC entry 3775 (class 2604 OID 90443)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group ALTER COLUMN id SET DEFAULT nextval('printer_group_id_seq'::regclass);


--
-- TOC entry 3776 (class 2604 OID 90444)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order ALTER COLUMN id SET DEFAULT nextval('purchase_order_id_seq'::regclass);


--
-- TOC entry 3777 (class 2604 OID 90445)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie ALTER COLUMN id SET DEFAULT nextval('recepie_id_seq'::regclass);


--
-- TOC entry 3778 (class 2604 OID 90446)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item ALTER COLUMN id SET DEFAULT nextval('recepie_item_id_seq'::regclass);


--
-- TOC entry 3779 (class 2604 OID 90447)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift ALTER COLUMN id SET DEFAULT nextval('shift_id_seq'::regclass);


--
-- TOC entry 3780 (class 2604 OID 90448)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor ALTER COLUMN id SET DEFAULT nextval('shop_floor_id_seq'::regclass);


--
-- TOC entry 3781 (class 2604 OID 90449)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template ALTER COLUMN id SET DEFAULT nextval('shop_floor_template_id_seq'::regclass);


--
-- TOC entry 3782 (class 2604 OID 90450)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type ALTER COLUMN id SET DEFAULT nextval('shop_table_type_id_seq'::regclass);


--
-- TOC entry 3783 (class 2604 OID 90451)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info ALTER COLUMN id SET DEFAULT nextval('table_booking_info_id_seq'::regclass);


--
-- TOC entry 3784 (class 2604 OID 90452)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax ALTER COLUMN id SET DEFAULT nextval('tax_id_seq'::regclass);


--
-- TOC entry 3785 (class 2604 OID 90453)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers ALTER COLUMN id SET DEFAULT nextval('terminal_printers_id_seq'::regclass);


--
-- TOC entry 3755 (class 2604 OID 90454)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket ALTER COLUMN id SET DEFAULT nextval('ticket_id_seq'::regclass);


--
-- TOC entry 3786 (class 2604 OID 90455)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount ALTER COLUMN id SET DEFAULT nextval('ticket_discount_id_seq'::regclass);


--
-- TOC entry 3787 (class 2604 OID 90456)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item ALTER COLUMN id SET DEFAULT nextval('ticket_item_id_seq'::regclass);


--
-- TOC entry 3788 (class 2604 OID 90457)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('ticket_item_discount_id_seq'::regclass);


--
-- TOC entry 3789 (class 2604 OID 90458)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifier_id_seq'::regclass);


--
-- TOC entry 3790 (class 2604 OID 90459)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- TOC entry 3791 (class 2604 OID 90460)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type ALTER COLUMN id SET DEFAULT nextval('user_type_id_seq'::regclass);


--
-- TOC entry 3792 (class 2604 OID 90461)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users ALTER COLUMN auto_id SET DEFAULT nextval('users_auto_id_seq'::regclass);


--
-- TOC entry 3793 (class 2604 OID 90462)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer ALTER COLUMN id SET DEFAULT nextval('virtual_printer_id_seq'::regclass);


--
-- TOC entry 3794 (class 2604 OID 90463)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons ALTER COLUMN id SET DEFAULT nextval('void_reasons_id_seq'::regclass);


--
-- TOC entry 3795 (class 2604 OID 90464)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4091 (class 2604 OID 94396)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 4087 (class 2604 OID 94383)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 4270 (class 2604 OID 102633)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- TOC entry 3796 (class 2604 OID 92570)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3838 (class 2604 OID 92571)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 4095 (class 2604 OID 94441)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_id_seq'::regclass);


--
-- TOC entry 4107 (class 2604 OID 94485)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('caja_fondo_adj_id_seq'::regclass);


--
-- TOC entry 4109 (class 2604 OID 94502)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_arqueo_id_seq'::regclass);


--
-- TOC entry 4100 (class 2604 OID 94463)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('caja_fondo_mov_id_seq'::regclass);


--
-- TOC entry 4165 (class 2604 OID 94805)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('cash_fund_arqueos_id_seq'::regclass);


--
-- TOC entry 4166 (class 2604 OID 94833)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('cash_fund_movement_audit_log_id_seq'::regclass);


--
-- TOC entry 4158 (class 2604 OID 94769)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('cash_fund_movements_id_seq'::regclass);


--
-- TOC entry 4154 (class 2604 OID 94744)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds ALTER COLUMN id SET DEFAULT nextval('cash_funds_id_seq'::regclass);


--
-- TOC entry 4062 (class 2604 OID 93937)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 4064 (class 2604 OID 93953)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 4060 (class 2604 OID 93926)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 3839 (class 2604 OID 92572)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 4066 (class 2604 OID 93964)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 3841 (class 2604 OID 92573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 3845 (class 2604 OID 92574)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3851 (class 2604 OID 92575)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3852 (class 2604 OID 92576)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3798 (class 2604 OID 92577)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3854 (class 2604 OID 92578)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 3858 (class 2604 OID 92579)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 3862 (class 2604 OID 92580)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3872 (class 2604 OID 92581)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3876 (class 2604 OID 92582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 3880 (class 2604 OID 92583)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 4111 (class 2604 OID 94519)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_id_seq'::regclass);


--
-- TOC entry 4116 (class 2604 OID 94531)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_det_id_seq'::regclass);


--
-- TOC entry 4168 (class 2604 OID 94862)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_log_id_seq'::regclass);


--
-- TOC entry 4067 (class 2604 OID 93984)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 3884 (class 2604 OID 92584)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 4141 (class 2604 OID 94659)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('inventory_count_lines_id_seq'::regclass);


--
-- TOC entry 4137 (class 2604 OID 94638)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts ALTER COLUMN id SET DEFAULT nextval('inventory_counts_id_seq'::regclass);


--
-- TOC entry 4152 (class 2604 OID 94727)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes ALTER COLUMN id SET DEFAULT nextval('inventory_wastes_id_seq'::regclass);


--
-- TOC entry 4072 (class 2604 OID 94284)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 4075 (class 2604 OID 94322)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 3919 (class 2604 OID 92585)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3924 (class 2604 OID 92586)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 4196 (class 2604 OID 94997)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles ALTER COLUMN id SET DEFAULT nextval('labor_roles_id_seq'::regclass);


--
-- TOC entry 3925 (class 2604 OID 92587)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 4226 (class 2604 OID 95146)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('menu_engineering_snapshots_id_seq'::regclass);


--
-- TOC entry 4224 (class 2604 OID 95127)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('menu_item_sync_map_id_seq'::regclass);


--
-- TOC entry 4222 (class 2604 OID 95113)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- TOC entry 3928 (class 2604 OID 92588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 3930 (class 2604 OID 92589)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 3931 (class 2604 OID 92590)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 92591)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 3940 (class 2604 OID 92592)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 3943 (class 2604 OID 92593)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 3944 (class 2604 OID 92594)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 4202 (class 2604 OID 95028)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions ALTER COLUMN id SET DEFAULT nextval('overhead_definitions_id_seq'::regclass);


--
-- TOC entry 3951 (class 2604 OID 92595)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 3957 (class 2604 OID 92596)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 3961 (class 2604 OID 92597)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 4269 (class 2604 OID 95582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4265 (class 2604 OID 95539)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('pos_reprocess_log_id_seq'::regclass);


--
-- TOC entry 4261 (class 2604 OID 95522)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('pos_reverse_log_id_seq'::regclass);


--
-- TOC entry 4215 (class 2604 OID 95079)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('pos_sync_batches_id_seq'::regclass);


--
-- TOC entry 4220 (class 2604 OID 95094)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('pos_sync_logs_id_seq'::regclass);


--
-- TOC entry 3816 (class 2604 OID 92598)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 3820 (class 2604 OID 92599)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 3826 (class 2604 OID 92600)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 3828 (class 2604 OID 92601)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 4126 (class 2604 OID 94573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab ALTER COLUMN id SET DEFAULT nextval('prod_cab_id_seq'::regclass);


--
-- TOC entry 4129 (class 2604 OID 94588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det ALTER COLUMN id SET DEFAULT nextval('prod_det_id_seq'::regclass);


--
-- TOC entry 4150 (class 2604 OID 94699)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs ALTER COLUMN id SET DEFAULT nextval('production_order_inputs_id_seq'::regclass);


--
-- TOC entry 4151 (class 2604 OID 94713)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs ALTER COLUMN id SET DEFAULT nextval('production_order_outputs_id_seq'::regclass);


--
-- TOC entry 4145 (class 2604 OID 94676)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders ALTER COLUMN id SET DEFAULT nextval('production_orders_id_seq'::regclass);


--
-- TOC entry 4195 (class 2604 OID 94983)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents ALTER COLUMN id SET DEFAULT nextval('purchase_documents_id_seq'::regclass);


--
-- TOC entry 4192 (class 2604 OID 94968)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('purchase_order_lines_id_seq'::regclass);


--
-- TOC entry 4186 (class 2604 OID 94948)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders ALTER COLUMN id SET DEFAULT nextval('purchase_orders_id_seq'::regclass);


--
-- TOC entry 4175 (class 2604 OID 94899)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('purchase_request_lines_id_seq'::regclass);


--
-- TOC entry 4170 (class 2604 OID 94880)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests ALTER COLUMN id SET DEFAULT nextval('purchase_requests_id_seq'::regclass);


--
-- TOC entry 4253 (class 2604 OID 95417)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('purchase_suggestion_lines_id_seq'::regclass);


--
-- TOC entry 4244 (class 2604 OID 95367)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('purchase_suggestions_id_seq'::regclass);


--
-- TOC entry 4184 (class 2604 OID 94933)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quote_lines_id_seq'::regclass);


--
-- TOC entry 4177 (class 2604 OID 94914)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quotes_id_seq'::regclass);


--
-- TOC entry 3965 (class 2604 OID 92602)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 4136 (class 2604 OID 94626)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('recepcion_adjuntos_id_seq'::regclass);


--
-- TOC entry 3966 (class 2604 OID 92603)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 3968 (class 2604 OID 92604)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 3969 (class 2604 OID 92605)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 3980 (class 2604 OID 92606)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 3986 (class 2604 OID 92607)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 3987 (class 2604 OID 92608)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 3995 (class 2604 OID 92609)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 4084 (class 2604 OID 94367)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 4207 (class 2604 OID 95060)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_extended_cost_history_id_seq'::regclass);


--
-- TOC entry 4199 (class 2604 OID 95013)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('recipe_labor_steps_id_seq'::regclass);


--
-- TOC entry 4206 (class 2604 OID 95046)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('recipe_overhead_allocations_id_seq'::regclass);


--
-- TOC entry 4083 (class 2604 OID 94358)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 4080 (class 2604 OID 94344)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 4239 (class 2604 OID 95335)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('replenishment_suggestions_id_seq'::regclass);


--
-- TOC entry 4235 (class 2604 OID 95192)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions ALTER COLUMN id SET DEFAULT nextval('report_definitions_id_seq'::regclass);


--
-- TOC entry 4237 (class 2604 OID 95206)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs ALTER COLUMN id SET DEFAULT nextval('report_runs_id_seq'::regclass);


--
-- TOC entry 3999 (class 2604 OID 92610)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 4000 (class 2604 OID 92611)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 3831 (class 2604 OID 92612)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 4120 (class 2604 OID 94545)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('sol_prod_cab_id_seq'::regclass);


--
-- TOC entry 4124 (class 2604 OID 94559)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det ALTER COLUMN id SET DEFAULT nextval('sol_prod_det_id_seq'::regclass);


--
-- TOC entry 4001 (class 2604 OID 92613)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 4007 (class 2604 OID 92614)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 4010 (class 2604 OID 92615)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 4258 (class 2604 OID 95510)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifiers_id_seq'::regclass);


--
-- TOC entry 4013 (class 2604 OID 92616)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 4019 (class 2604 OID 92617)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 4131 (class 2604 OID 94602)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab ALTER COLUMN id SET DEFAULT nextval('transfer_cab_id_seq'::regclass);


--
-- TOC entry 4134 (class 2604 OID 94612)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det ALTER COLUMN id SET DEFAULT nextval('transfer_det_id_seq'::regclass);


--
-- TOC entry 4024 (class 2604 OID 92618)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 4026 (class 2604 OID 92619)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 4027 (class 2604 OID 92620)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 4032 (class 2604 OID 92621)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 4041 (class 2604 OID 92622)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 4046 (class 2604 OID 92623)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 4057 (class 2604 OID 92624)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- TOC entry 4273 (class 2606 OID 90476)
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4275 (class 2606 OID 90478)
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4277 (class 2606 OID 90480)
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- TOC entry 4279 (class 2606 OID 90482)
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4281 (class 2606 OID 90484)
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 4283 (class 2606 OID 90486)
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4285 (class 2606 OID 90488)
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- TOC entry 4289 (class 2606 OID 90490)
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- TOC entry 4287 (class 2606 OID 90492)
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- TOC entry 4291 (class 2606 OID 90494)
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- TOC entry 4293 (class 2606 OID 90496)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 4295 (class 2606 OID 90498)
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4297 (class 2606 OID 90500)
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- TOC entry 4299 (class 2606 OID 90502)
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- TOC entry 4301 (class 2606 OID 90504)
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- TOC entry 4303 (class 2606 OID 90506)
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- TOC entry 4305 (class 2606 OID 90508)
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 4307 (class 2606 OID 90510)
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 4309 (class 2606 OID 90512)
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4313 (class 2606 OID 90514)
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- TOC entry 4316 (class 2606 OID 90516)
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4318 (class 2606 OID 90518)
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- TOC entry 4320 (class 2606 OID 90520)
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- TOC entry 4322 (class 2606 OID 90522)
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- TOC entry 4324 (class 2606 OID 90524)
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- TOC entry 4326 (class 2606 OID 90526)
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4328 (class 2606 OID 90528)
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4330 (class 2606 OID 90530)
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- TOC entry 4332 (class 2606 OID 90532)
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- TOC entry 4334 (class 2606 OID 90534)
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 4336 (class 2606 OID 90536)
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 4338 (class 2606 OID 90538)
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 4340 (class 2606 OID 90540)
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- TOC entry 4365 (class 2606 OID 90542)
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 4368 (class 2606 OID 90544)
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4343 (class 2606 OID 90546)
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4371 (class 2606 OID 90548)
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- TOC entry 4373 (class 2606 OID 90550)
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4376 (class 2606 OID 90552)
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4378 (class 2606 OID 90554)
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- TOC entry 4380 (class 2606 OID 90556)
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- TOC entry 4385 (class 2606 OID 90558)
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4382 (class 2606 OID 90560)
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 4388 (class 2606 OID 90562)
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- TOC entry 4390 (class 2606 OID 90564)
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- TOC entry 4392 (class 2606 OID 90566)
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- TOC entry 4394 (class 2606 OID 90568)
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4396 (class 2606 OID 90570)
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- TOC entry 4398 (class 2606 OID 90572)
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- TOC entry 4400 (class 2606 OID 90574)
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4402 (class 2606 OID 90576)
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- TOC entry 4404 (class 2606 OID 90578)
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 4406 (class 2606 OID 90580)
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4408 (class 2606 OID 90582)
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- TOC entry 4410 (class 2606 OID 90584)
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- TOC entry 4412 (class 2606 OID 90586)
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4414 (class 2606 OID 90588)
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- TOC entry 4416 (class 2606 OID 90590)
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 4418 (class 2606 OID 90592)
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- TOC entry 4420 (class 2606 OID 90594)
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4422 (class 2606 OID 90596)
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 4426 (class 2606 OID 90598)
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4424 (class 2606 OID 90600)
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- TOC entry 4428 (class 2606 OID 90602)
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- TOC entry 4430 (class 2606 OID 90604)
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4432 (class 2606 OID 90606)
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- TOC entry 4434 (class 2606 OID 90608)
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- TOC entry 4436 (class 2606 OID 90610)
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- TOC entry 4438 (class 2606 OID 90612)
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- TOC entry 4440 (class 2606 OID 90614)
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4442 (class 2606 OID 90616)
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- TOC entry 4444 (class 2606 OID 90618)
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4446 (class 2606 OID 90620)
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4449 (class 2606 OID 90622)
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- TOC entry 4454 (class 2606 OID 90624)
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4452 (class 2606 OID 90626)
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 4345 (class 2606 OID 90628)
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4456 (class 2606 OID 90630)
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- TOC entry 4458 (class 2606 OID 90632)
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4460 (class 2606 OID 90634)
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4354 (class 2606 OID 90636)
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- TOC entry 4466 (class 2606 OID 90638)
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4468 (class 2606 OID 90640)
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- TOC entry 4470 (class 2606 OID 90642)
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 4472 (class 2606 OID 90644)
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 4474 (class 2606 OID 90646)
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 4464 (class 2606 OID 90648)
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4356 (class 2606 OID 90650)
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4476 (class 2606 OID 90652)
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4478 (class 2606 OID 90654)
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 4483 (class 2606 OID 90656)
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- TOC entry 4485 (class 2606 OID 90658)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 4487 (class 2606 OID 90660)
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- TOC entry 4489 (class 2606 OID 90662)
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4491 (class 2606 OID 90664)
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- TOC entry 4493 (class 2606 OID 90666)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 4495 (class 2606 OID 90668)
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- TOC entry 4497 (class 2606 OID 90670)
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- TOC entry 4499 (class 2606 OID 90672)
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- TOC entry 4501 (class 2606 OID 90674)
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- TOC entry 4503 (class 2606 OID 90676)
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 4505 (class 2606 OID 90678)
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4808 (class 2606 OID 94400)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4806 (class 2606 OID 94390)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4538 (class 2606 OID 92630)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 5044 (class 2606 OID 102639)
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4507 (class 2606 OID 90680)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4540 (class 2606 OID 92632)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 4542 (class 2606 OID 92634)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 4546 (class 2606 OID 92636)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4544 (class 2606 OID 92638)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 4817 (class 2606 OID 94491)
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- TOC entry 4819 (class 2606 OID 94508)
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- TOC entry 4815 (class 2606 OID 94474)
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- TOC entry 4811 (class 2606 OID 94447)
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- TOC entry 4813 (class 2606 OID 94452)
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- TOC entry 4899 (class 2606 OID 94824)
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- TOC entry 4902 (class 2606 OID 94810)
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- TOC entry 4904 (class 2606 OID 94839)
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4895 (class 2606 OID 94780)
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 4888 (class 2606 OID 94749)
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- TOC entry 4764 (class 2606 OID 93947)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 4766 (class 2606 OID 93940)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4768 (class 2606 OID 93956)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 4770 (class 2606 OID 93958)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 4760 (class 2606 OID 93931)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 4762 (class 2606 OID 93929)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 4548 (class 2606 OID 94009)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 4550 (class 2606 OID 92640)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4774 (class 2606 OID 93978)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4776 (class 2606 OID 93966)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4552 (class 2606 OID 92642)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4554 (class 2606 OID 92644)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 4556 (class 2606 OID 92646)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 4558 (class 2606 OID 92648)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 4560 (class 2606 OID 92650)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 4564 (class 2606 OID 92652)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4566 (class 2606 OID 92654)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4509 (class 2606 OID 90682)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 4568 (class 2606 OID 92656)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4572 (class 2606 OID 92658)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4575 (class 2606 OID 92660)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 4577 (class 2606 OID 92662)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4580 (class 2606 OID 92664)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4583 (class 2606 OID 102654)
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- TOC entry 4585 (class 2606 OID 92666)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4589 (class 2606 OID 92668)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4587 (class 2606 OID 92670)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 4827 (class 2606 OID 94534)
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4909 (class 2606 OID 94868)
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4821 (class 2606 OID 94523)
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4825 (class 2606 OID 94525)
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- TOC entry 4778 (class 2606 OID 93997)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 4780 (class 2606 OID 93990)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4593 (class 2606 OID 92672)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 4858 (class 2606 OID 94667)
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4849 (class 2606 OID 94653)
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- TOC entry 4851 (class 2606 OID 94646)
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- TOC entry 4882 (class 2606 OID 94733)
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- TOC entry 4784 (class 2606 OID 94294)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 4786 (class 2606 OID 94290)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4788 (class 2606 OID 94292)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 4790 (class 2606 OID 94314)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4596 (class 2606 OID 92674)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 4792 (class 2606 OID 94331)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 4601 (class 2606 OID 92676)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 4604 (class 2606 OID 92678)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4606 (class 2606 OID 92680)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 4608 (class 2606 OID 92682)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4951 (class 2606 OID 95007)
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- TOC entry 4953 (class 2606 OID 95004)
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4613 (class 2606 OID 92684)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 4987 (class 2606 OID 95159)
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4983 (class 2606 OID 95133)
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4979 (class 2606 OID 95119)
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4615 (class 2606 OID 92686)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 4617 (class 2606 OID 92688)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4620 (class 2606 OID 92690)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 4623 (class 2606 OID 92692)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 4625 (class 2606 OID 92694)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 4627 (class 2606 OID 92696)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4637 (class 2606 OID 92698)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 4639 (class 2606 OID 92700)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4641 (class 2606 OID 92702)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4643 (class 2606 OID 92704)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4645 (class 2606 OID 92706)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 4960 (class 2606 OID 95040)
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- TOC entry 4962 (class 2606 OID 95036)
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4647 (class 2606 OID 92708)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4649 (class 2606 OID 92710)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 4651 (class 2606 OID 92712)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 4654 (class 2606 OID 92714)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4656 (class 2606 OID 92716)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4658 (class 2606 OID 92718)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 5039 (class 2606 OID 95587)
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 5041 (class 2606 OID 95590)
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 4663 (class 2606 OID 92720)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 5037 (class 2606 OID 95547)
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5032 (class 2606 OID 95530)
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4973 (class 2606 OID 95088)
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4975 (class 2606 OID 95100)
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4514 (class 2606 OID 90684)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4525 (class 2606 OID 90686)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 4529 (class 2606 OID 90688)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 4519 (class 2606 OID 90690)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4835 (class 2606 OID 94577)
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4837 (class 2606 OID 94591)
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4872 (class 2606 OID 94704)
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4877 (class 2606 OID 94718)
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4862 (class 2606 OID 94693)
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4865 (class 2606 OID 94685)
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4665 (class 2606 OID 92722)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4946 (class 2606 OID 94988)
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 4943 (class 2606 OID 94975)
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4936 (class 2606 OID 94962)
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4938 (class 2606 OID 94958)
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4922 (class 2606 OID 94905)
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4915 (class 2606 OID 94893)
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- TOC entry 4917 (class 2606 OID 94888)
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 5021 (class 2606 OID 95426)
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5015 (class 2606 OID 95380)
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4931 (class 2606 OID 94939)
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4927 (class 2606 OID 94925)
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- TOC entry 4667 (class 2606 OID 92724)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4843 (class 2606 OID 94631)
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- TOC entry 4669 (class 2606 OID 92726)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4672 (class 2606 OID 92728)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4678 (class 2606 OID 92730)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 4680 (class 2606 OID 92732)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4674 (class 2606 OID 92734)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 4682 (class 2606 OID 92736)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4686 (class 2606 OID 92738)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4688 (class 2606 OID 92740)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, insumo_id);


--
-- TOC entry 4676 (class 2606 OID 92742)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4690 (class 2606 OID 92744)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 4694 (class 2606 OID 92746)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 4696 (class 2606 OID 92748)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 4804 (class 2606 OID 94374)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4971 (class 2606 OID 95072)
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4956 (class 2606 OID 95020)
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- TOC entry 4966 (class 2606 OID 95051)
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 4968 (class 2606 OID 95053)
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- TOC entry 4801 (class 2606 OID 94360)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4797 (class 2606 OID 94351)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 5000 (class 2606 OID 95355)
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 5003 (class 2606 OID 95344)
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4991 (class 2606 OID 95198)
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4995 (class 2606 OID 95212)
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- TOC entry 4698 (class 2606 OID 92750)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 4700 (class 2606 OID 92752)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 4702 (class 2606 OID 92754)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 4704 (class 2606 OID 92756)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4706 (class 2606 OID 92758)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4989 (class 2606 OID 95166)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- TOC entry 4985 (class 2606 OID 95140)
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- TOC entry 4981 (class 2606 OID 95121)
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- TOC entry 5017 (class 2606 OID 95411)
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4993 (class 2606 OID 95200)
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- TOC entry 4534 (class 2606 OID 90692)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 4536 (class 2606 OID 90694)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 4709 (class 2606 OID 92760)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 4831 (class 2606 OID 94553)
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4833 (class 2606 OID 94562)
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4715 (class 2606 OID 92762)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4720 (class 2606 OID 92764)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4717 (class 2606 OID 92766)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4725 (class 2606 OID 92768)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 5025 (class 2606 OID 95514)
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 4728 (class 2606 OID 92770)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 4730 (class 2606 OID 92772)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4732 (class 2606 OID 92774)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4839 (class 2606 OID 94606)
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4841 (class 2606 OID 94615)
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4734 (class 2606 OID 92776)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4736 (class 2606 OID 92778)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4738 (class 2606 OID 92780)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4740 (class 2606 OID 92782)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4742 (class 2606 OID 92784)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4744 (class 2606 OID 92786)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4746 (class 2606 OID 92788)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 4748 (class 2606 OID 92790)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4516 (class 2606 OID 90696)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4522 (class 2606 OID 92792)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 5023 (class 2606 OID 95443)
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- TOC entry 4750 (class 2606 OID 92794)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 4752 (class 2606 OID 92796)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4754 (class 2606 OID 92798)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4756 (class 2606 OID 92800)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 4758 (class 2606 OID 92802)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


SET search_path = public, pg_catalog;

--
-- TOC entry 4346 (class 1259 OID 90697)
-- Name: creationhour; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX creationhour ON ticket USING btree (creation_hour);


--
-- TOC entry 4347 (class 1259 OID 90698)
-- Name: deliverydate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX deliverydate ON ticket USING btree (deliveery_date);


--
-- TOC entry 4314 (class 1259 OID 90699)
-- Name: drawer_report_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawer_report_time ON drawer_pull_report USING btree (report_time);


--
-- TOC entry 4348 (class 1259 OID 90700)
-- Name: drawerresetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawerresetted ON ticket USING btree (drawer_resetted);


--
-- TOC entry 4369 (class 1259 OID 90701)
-- Name: food_category_visible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX food_category_visible ON menu_category USING btree (visible);


--
-- TOC entry 4447 (class 1259 OID 90702)
-- Name: fromdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX fromdate ON table_booking_info USING btree (from_date);


--
-- TOC entry 4310 (class 1259 OID 90703)
-- Name: idx_dah_user_op_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_dah_user_op_time ON drawer_assigned_history USING btree (a_user, operation, "time" DESC);


--
-- TOC entry 4311 (class 1259 OID 90704)
-- Name: idx_drawer_assigned_history_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_drawer_assigned_history_user_time ON drawer_assigned_history USING btree (a_user, "time");


--
-- TOC entry 4349 (class 1259 OID 90705)
-- Name: idx_ticket_close_term_owner; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_close_term_owner ON ticket USING btree (closing_date, terminal_id, owner_id);


--
-- TOC entry 4350 (class 1259 OID 94012)
-- Name: idx_ticket_closing_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_closing_date ON ticket USING btree (closing_date);


--
-- TOC entry 4461 (class 1259 OID 94013)
-- Name: idx_ticket_item_ticket; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_item_ticket ON ticket_item USING btree (ticket_id);


--
-- TOC entry 4479 (class 1259 OID 94011)
-- Name: idx_transactions_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_transactions_time ON transactions USING btree (transaction_time);


--
-- TOC entry 4480 (class 1259 OID 90706)
-- Name: idx_tx_term_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_tx_term_user_time ON transactions USING btree (terminal_id, user_id, transaction_time);


--
-- TOC entry 4366 (class 1259 OID 90707)
-- Name: ix_kitchen_ticket_item_item_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_item_item_id ON kitchen_ticket_item USING btree (ticket_item_id);


--
-- TOC entry 4341 (class 1259 OID 90708)
-- Name: ix_kitchen_ticket_ticket_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_ticket_id ON kitchen_ticket USING btree (ticket_id);


--
-- TOC entry 4351 (class 1259 OID 90709)
-- Name: ix_ticket_branch_key; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_branch_key ON ticket USING btree (branch_key);


--
-- TOC entry 4352 (class 1259 OID 90710)
-- Name: ix_ticket_folio_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_folio_date ON ticket USING btree (folio_date);


--
-- TOC entry 4462 (class 1259 OID 90711)
-- Name: ix_ticket_item_ticket_pg; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_item_ticket_pg ON ticket_item USING btree (ticket_id, pg_id);


--
-- TOC entry 4374 (class 1259 OID 90712)
-- Name: menugroupvisible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX menugroupvisible ON menu_group USING btree (visible);


--
-- TOC entry 4386 (class 1259 OID 90713)
-- Name: mg_enable; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX mg_enable ON menu_modifier_group USING btree (enabled);


--
-- TOC entry 4383 (class 1259 OID 90714)
-- Name: modifierenabled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX modifierenabled ON menu_modifier USING btree (enable);


--
-- TOC entry 4357 (class 1259 OID 90715)
-- Name: ticketactivedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketactivedate ON ticket USING btree (active_date);


--
-- TOC entry 4358 (class 1259 OID 90716)
-- Name: ticketclosingdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketclosingdate ON ticket USING btree (closing_date);


--
-- TOC entry 4359 (class 1259 OID 90717)
-- Name: ticketcreatedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketcreatedate ON ticket USING btree (create_date);


--
-- TOC entry 4360 (class 1259 OID 90718)
-- Name: ticketpaid; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketpaid ON ticket USING btree (paid);


--
-- TOC entry 4361 (class 1259 OID 90719)
-- Name: ticketsettled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketsettled ON ticket USING btree (settled);


--
-- TOC entry 4362 (class 1259 OID 90720)
-- Name: ticketvoided; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketvoided ON ticket USING btree (voided);


--
-- TOC entry 4450 (class 1259 OID 90721)
-- Name: todate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX todate ON table_booking_info USING btree (to_date);


--
-- TOC entry 4481 (class 1259 OID 90722)
-- Name: tran_drawer_resetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX tran_drawer_resetted ON transactions USING btree (drawer_resetted);


--
-- TOC entry 4363 (class 1259 OID 90723)
-- Name: ux_ticket_dailyfolio; Type: INDEX; Schema: public; Owner: floreant
--

CREATE UNIQUE INDEX ux_ticket_dailyfolio ON ticket USING btree (folio_date, branch_key, daily_folio) WHERE (daily_folio IS NOT NULL);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4897 (class 1259 OID 94821)
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON cash_fund_arqueos USING btree (cash_fund_id);


--
-- TOC entry 4900 (class 1259 OID 94822)
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON cash_fund_arqueos USING btree (created_by_user_id);


--
-- TOC entry 4891 (class 1259 OID 94796)
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON cash_fund_movements USING btree (cash_fund_id);


--
-- TOC entry 4892 (class 1259 OID 94799)
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON cash_fund_movements USING btree (created_by_user_id);


--
-- TOC entry 4893 (class 1259 OID 94798)
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON cash_fund_movements USING btree (estatus);


--
-- TOC entry 4896 (class 1259 OID 94797)
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON cash_fund_movements USING btree (tipo);


--
-- TOC entry 4885 (class 1259 OID 94762)
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON cash_funds USING btree (estado);


--
-- TOC entry 4886 (class 1259 OID 94761)
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON cash_funds USING btree (fecha);


--
-- TOC entry 4889 (class 1259 OID 94763)
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON cash_funds USING btree (responsable_user_id);


--
-- TOC entry 4890 (class 1259 OID 94760)
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON cash_funds USING btree (sucursal_id);


--
-- TOC entry 5045 (class 1259 OID 102645)
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON audit_log USING btree (accion);


--
-- TOC entry 5046 (class 1259 OID 102646)
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON audit_log USING btree (entidad);


--
-- TOC entry 5047 (class 1259 OID 102647)
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON audit_log USING btree (entidad_id);


--
-- TOC entry 5048 (class 1259 OID 102643)
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON audit_log USING btree ("timestamp");


--
-- TOC entry 5049 (class 1259 OID 102644)
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON audit_log USING btree (user_id);


--
-- TOC entry 4578 (class 1259 OID 93178)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4590 (class 1259 OID 93179)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 4591 (class 1259 OID 93180)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 4628 (class 1259 OID 93181)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 4629 (class 1259 OID 93182)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 4781 (class 1259 OID 94066)
-- Name: idx_mv_dashboard_formas_pago_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_formas_pago_pk ON mv_dashboard_formas_pago USING btree (fecha, sucursal_id, codigo_fp);


--
-- TOC entry 4782 (class 1259 OID 94075)
-- Name: idx_mv_dashboard_resumen_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_resumen_pk ON mv_dashboard_resumen USING btree (fecha, sucursal_id);


--
-- TOC entry 4652 (class 1259 OID 93183)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 4659 (class 1259 OID 94014)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 5033 (class 1259 OID 95550)
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON pos_reprocess_log USING btree (reprocessed_at);


--
-- TOC entry 5034 (class 1259 OID 95548)
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON pos_reprocess_log USING btree (ticket_id);


--
-- TOC entry 5035 (class 1259 OID 95549)
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON pos_reprocess_log USING btree (user_id);


--
-- TOC entry 5028 (class 1259 OID 95533)
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON pos_reverse_log USING btree (reversed_at);


--
-- TOC entry 5029 (class 1259 OID 95531)
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON pos_reverse_log USING btree (ticket_id);


--
-- TOC entry 5030 (class 1259 OID 95532)
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON pos_reverse_log USING btree (user_id);


--
-- TOC entry 4512 (class 1259 OID 93184)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 4523 (class 1259 OID 93185)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 4526 (class 1259 OID 93186)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4517 (class 1259 OID 90724)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 4911 (class 1259 OID 95468)
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON purchase_requests USING btree (fecha_requerida);


--
-- TOC entry 4912 (class 1259 OID 95469)
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON purchase_requests USING btree (urgente);


--
-- TOC entry 4771 (class 1259 OID 94217)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 4772 (class 1259 OID 94218)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 5010 (class 1259 OID 95406)
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON purchase_suggestions USING btree (estado);


--
-- TOC entry 5011 (class 1259 OID 95408)
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON purchase_suggestions USING btree (sugerido_en);


--
-- TOC entry 5012 (class 1259 OID 95407)
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON purchase_suggestions USING btree (prioridad);


--
-- TOC entry 5013 (class 1259 OID 95409)
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON purchase_suggestions USING btree (sucursal_id, estado);


--
-- TOC entry 5018 (class 1259 OID 95445)
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON purchase_suggestion_lines USING btree (item_id);


--
-- TOC entry 5019 (class 1259 OID 95444)
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON purchase_suggestion_lines USING btree (suggestion_id);


--
-- TOC entry 4691 (class 1259 OID 93187)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 4530 (class 1259 OID 93188)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4711 (class 1259 OID 93189)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4712 (class 1259 OID 93190)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 4718 (class 1259 OID 93191)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 4721 (class 1259 OID 93192)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 4722 (class 1259 OID 93193)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 4723 (class 1259 OID 93194)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 4726 (class 1259 OID 93195)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 4581 (class 1259 OID 102655)
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- TOC entry 4828 (class 1259 OID 95576)
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON inv_consumo_pos_det USING btree (procesado);


--
-- TOC entry 4829 (class 1259 OID 95575)
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- TOC entry 4910 (class 1259 OID 94869)
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON inv_consumo_pos_log USING btree (ticket_id);


--
-- TOC entry 4822 (class 1259 OID 95564)
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON inv_consumo_pos USING btree (procesado);


--
-- TOC entry 4823 (class 1259 OID 95563)
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON inv_consumo_pos USING btree (requiere_reproceso);


--
-- TOC entry 4854 (class 1259 OID 94670)
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON inventory_count_lines USING btree (inventory_batch_id);


--
-- TOC entry 4855 (class 1259 OID 94668)
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON inventory_count_lines USING btree (inventory_count_id);


--
-- TOC entry 4856 (class 1259 OID 94669)
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON inventory_count_lines USING btree (item_id);


--
-- TOC entry 4845 (class 1259 OID 94649)
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON inventory_counts USING btree (almacen_id);


--
-- TOC entry 4846 (class 1259 OID 94651)
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON inventory_counts USING btree (cerrado_en);


--
-- TOC entry 4847 (class 1259 OID 94647)
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON inventory_counts USING btree (estado);


--
-- TOC entry 4852 (class 1259 OID 94650)
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON inventory_counts USING btree (programado_para);


--
-- TOC entry 4853 (class 1259 OID 94648)
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON inventory_counts USING btree (sucursal_id);


--
-- TOC entry 4879 (class 1259 OID 94736)
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON inventory_wastes USING btree (inventory_batch_id);


--
-- TOC entry 4880 (class 1259 OID 94735)
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON inventory_wastes USING btree (item_id);


--
-- TOC entry 4883 (class 1259 OID 94734)
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON inventory_wastes USING btree (production_order_id);


--
-- TOC entry 4884 (class 1259 OID 94737)
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON inventory_wastes USING btree (sucursal_id);


--
-- TOC entry 4809 (class 1259 OID 94401)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 4510 (class 1259 OID 93196)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 4569 (class 1259 OID 93197)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva DESC);


--
-- TOC entry 4573 (class 1259 OID 93198)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 4594 (class 1259 OID 93199)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 4597 (class 1259 OID 94220)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 4598 (class 1259 OID 94219)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 4793 (class 1259 OID 94332)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 4794 (class 1259 OID 94334)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 4795 (class 1259 OID 94333)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 4561 (class 1259 OID 93200)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 4562 (class 1259 OID 93201)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 4610 (class 1259 OID 93202)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 4611 (class 1259 OID 93203)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (insumo_id);


--
-- TOC entry 4630 (class 1259 OID 93204)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4631 (class 1259 OID 93205)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 4632 (class 1259 OID 93206)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 4633 (class 1259 OID 93207)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 4634 (class 1259 OID 93208)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4635 (class 1259 OID 93209)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4660 (class 1259 OID 93210)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 4661 (class 1259 OID 93211)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 4527 (class 1259 OID 90725)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4802 (class 1259 OID 94375)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4683 (class 1259 OID 93212)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (insumo_id);


--
-- TOC entry 4684 (class 1259 OID 93213)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4692 (class 1259 OID 93214)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 4799 (class 1259 OID 94361)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 4531 (class 1259 OID 90726)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 4532 (class 1259 OID 90727)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4713 (class 1259 OID 93215)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4609 (class 1259 OID 93216)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 4949 (class 1259 OID 95005)
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON labor_roles USING btree (activo);


--
-- TOC entry 4618 (class 1259 OID 93217)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 4621 (class 1259 OID 93218)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 4958 (class 1259 OID 95037)
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON overhead_definitions USING btree (activo);


--
-- TOC entry 4963 (class 1259 OID 95038)
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON overhead_definitions USING btree (tipo);


--
-- TOC entry 5042 (class 1259 OID 95588)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 4520 (class 1259 OID 90728)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 4869 (class 1259 OID 94707)
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON production_order_inputs USING btree (inventory_batch_id);


--
-- TOC entry 4870 (class 1259 OID 94706)
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON production_order_inputs USING btree (item_id);


--
-- TOC entry 4873 (class 1259 OID 94705)
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON production_order_inputs USING btree (production_order_id);


--
-- TOC entry 4874 (class 1259 OID 94721)
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON production_order_outputs USING btree (inventory_batch_id);


--
-- TOC entry 4875 (class 1259 OID 94720)
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON production_order_outputs USING btree (item_id);


--
-- TOC entry 4878 (class 1259 OID 94719)
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON production_order_outputs USING btree (production_order_id);


--
-- TOC entry 4859 (class 1259 OID 94689)
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON production_orders USING btree (almacen_id);


--
-- TOC entry 4860 (class 1259 OID 94690)
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON production_orders USING btree (estado);


--
-- TOC entry 4863 (class 1259 OID 94687)
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON production_orders USING btree (item_id);


--
-- TOC entry 4866 (class 1259 OID 94691)
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON production_orders USING btree (programado_para);


--
-- TOC entry 4867 (class 1259 OID 94686)
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON production_orders USING btree (recipe_id);


--
-- TOC entry 4868 (class 1259 OID 94688)
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON production_orders USING btree (sucursal_id);


--
-- TOC entry 4944 (class 1259 OID 94991)
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON purchase_documents USING btree (order_id);


--
-- TOC entry 4947 (class 1259 OID 94990)
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON purchase_documents USING btree (quote_id);


--
-- TOC entry 4948 (class 1259 OID 94989)
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON purchase_documents USING btree (request_id);


--
-- TOC entry 4940 (class 1259 OID 94977)
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON purchase_order_lines USING btree (item_id);


--
-- TOC entry 4941 (class 1259 OID 94976)
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON purchase_order_lines USING btree (order_id);


--
-- TOC entry 4934 (class 1259 OID 94960)
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON purchase_orders USING btree (estado);


--
-- TOC entry 4939 (class 1259 OID 94959)
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON purchase_orders USING btree (vendor_id);


--
-- TOC entry 4920 (class 1259 OID 94907)
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON purchase_request_lines USING btree (item_id);


--
-- TOC entry 4923 (class 1259 OID 94908)
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON purchase_request_lines USING btree (preferred_vendor_id);


--
-- TOC entry 4924 (class 1259 OID 94906)
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON purchase_request_lines USING btree (request_id);


--
-- TOC entry 4913 (class 1259 OID 94890)
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON purchase_requests USING btree (estado);


--
-- TOC entry 4918 (class 1259 OID 94891)
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON purchase_requests USING btree (requested_at);


--
-- TOC entry 4919 (class 1259 OID 94889)
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON purchase_requests USING btree (sucursal_id);


--
-- TOC entry 4929 (class 1259 OID 94942)
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON purchase_vendor_quote_lines USING btree (item_id);


--
-- TOC entry 4932 (class 1259 OID 94940)
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON purchase_vendor_quote_lines USING btree (quote_id);


--
-- TOC entry 4933 (class 1259 OID 94941)
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON purchase_vendor_quote_lines USING btree (request_line_id);


--
-- TOC entry 4925 (class 1259 OID 94927)
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON purchase_vendor_quotes USING btree (estado);


--
-- TOC entry 4928 (class 1259 OID 94926)
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- TOC entry 4844 (class 1259 OID 94632)
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON recepcion_adjuntos USING btree (recepcion_id);


--
-- TOC entry 4969 (class 1259 OID 95073)
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4954 (class 1259 OID 95022)
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON recipe_labor_steps USING btree (labor_role_id);


--
-- TOC entry 4957 (class 1259 OID 95021)
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON recipe_labor_steps USING btree (recipe_id);


--
-- TOC entry 4964 (class 1259 OID 95054)
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON recipe_overhead_allocations USING btree (overhead_id);


--
-- TOC entry 4997 (class 1259 OID 95347)
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON replenishment_suggestions USING btree (estado);


--
-- TOC entry 4998 (class 1259 OID 95350)
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- TOC entry 5001 (class 1259 OID 95348)
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- TOC entry 5004 (class 1259 OID 95346)
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON replenishment_suggestions USING btree (prioridad);


--
-- TOC entry 5005 (class 1259 OID 95353)
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON replenishment_suggestions USING btree (production_order_id);


--
-- TOC entry 5006 (class 1259 OID 95352)
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON replenishment_suggestions USING btree (purchase_request_id);


--
-- TOC entry 5007 (class 1259 OID 95351)
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON replenishment_suggestions USING btree (revisado_por);


--
-- TOC entry 5008 (class 1259 OID 95349)
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON replenishment_suggestions USING btree (sugerido_en);


--
-- TOC entry 5009 (class 1259 OID 95345)
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON replenishment_suggestions USING btree (tipo);


--
-- TOC entry 5050 (class 1259 OID 102640)
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON audit_log USING btree (entidad, entidad_id);


--
-- TOC entry 5051 (class 1259 OID 102642)
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON audit_log USING btree ("timestamp");


--
-- TOC entry 5052 (class 1259 OID 102641)
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON audit_log USING btree (user_id);


--
-- TOC entry 4905 (class 1259 OID 94841)
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON cash_fund_movement_audit_log USING btree (action);


--
-- TOC entry 4906 (class 1259 OID 94842)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- TOC entry 4907 (class 1259 OID 94840)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON cash_fund_movement_audit_log USING btree (movement_id);


--
-- TOC entry 4976 (class 1259 OID 95106)
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON pos_sync_logs USING btree (batch_id, status);


--
-- TOC entry 4977 (class 1259 OID 95107)
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON pos_sync_logs USING btree (external_id);


--
-- TOC entry 4670 (class 1259 OID 95225)
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON recepcion_cab USING btree (almacen_id);


--
-- TOC entry 4996 (class 1259 OID 95218)
-- Name: selemti_report_runs_report_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_report_runs_report_id_status_index ON report_runs USING btree (report_id, status);


--
-- TOC entry 4707 (class 1259 OID 93219)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 4710 (class 1259 OID 93220)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 5026 (class 1259 OID 95515)
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON ticket_item_modifiers USING btree (ticket_id);


--
-- TOC entry 5027 (class 1259 OID 95516)
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON ticket_item_modifiers USING btree (ticket_item_id);


--
-- TOC entry 4511 (class 1259 OID 90729)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 4570 (class 1259 OID 93221)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 4599 (class 1259 OID 94213)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 4602 (class 1259 OID 94308)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 4798 (class 1259 OID 94352)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


SET search_path = public, pg_catalog;

--
-- TOC entry 5299 (class 2620 OID 93910)
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON ticket FOR EACH ROW EXECUTE PROCEDURE assign_daily_folio();


--
-- TOC entry 5300 (class 2620 OID 93911)
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE ON kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5301 (class 2620 OID 93912)
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE ON ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 5297 (class 2620 OID 90733)
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();


--
-- TOC entry 5298 (class 2620 OID 90734)
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- TOC entry 5302 (class 2620 OID 90735)
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5308 (class 2620 OID 94298)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 5307 (class 2620 OID 94316)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 5310 (class 2620 OID 94404)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 5309 (class 2620 OID 94336)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 5303 (class 2620 OID 93831)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 5304 (class 2620 OID 93832)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 5305 (class 2620 OID 93833)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 5306 (class 2620 OID 93834)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


SET search_path = public, pg_catalog;

--
-- TOC entry 5113 (class 2606 OID 90737)
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5100 (class 2606 OID 90742)
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5124 (class 2606 OID 90747)
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5123 (class 2606 OID 90752)
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES pizza_price(id);


--
-- TOC entry 5154 (class 2606 OID 90757)
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5143 (class 2606 OID 90762)
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5063 (class 2606 OID 90767)
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5064 (class 2606 OID 90772)
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES customer(auto_id);


--
-- TOC entry 5061 (class 2606 OID 90777)
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES currency(id);


--
-- TOC entry 5060 (class 2606 OID 90782)
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES cash_drawer(id);


--
-- TOC entry 5059 (class 2606 OID 90787)
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5174 (class 2606 OID 90792)
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES user_type(id);


--
-- TOC entry 5173 (class 2606 OID 90797)
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES user_permission(name);


--
-- TOC entry 5145 (class 2606 OID 90802)
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5144 (class 2606 OID 90807)
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 5122 (class 2606 OID 90812)
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5121 (class 2606 OID 90817)
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES menu_item(id);


--
-- TOC entry 5120 (class 2606 OID 90822)
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5091 (class 2606 OID 90827)
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5074 (class 2606 OID 90832)
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5073 (class 2606 OID 90837)
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5072 (class 2606 OID 90842)
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5160 (class 2606 OID 90847)
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5161 (class 2606 OID 90852)
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES ticket_item(id);


--
-- TOC entry 5053 (class 2606 OID 90857)
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5106 (class 2606 OID 90862)
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES menu_group(id);


--
-- TOC entry 5105 (class 2606 OID 90867)
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5104 (class 2606 OID 90872)
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES tax_group(id);


--
-- TOC entry 5103 (class 2606 OID 90877)
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5102 (class 2606 OID 90882)
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES recepie(id);


--
-- TOC entry 5177 (class 2606 OID 90887)
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5176 (class 2606 OID 90892)
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES user_type(id);


--
-- TOC entry 5175 (class 2606 OID 90897)
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES terminal(id);


--
-- TOC entry 5101 (class 2606 OID 90902)
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES menu_category(id);


--
-- TOC entry 5115 (class 2606 OID 90907)
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES menu_category(id);


--
-- TOC entry 5114 (class 2606 OID 90912)
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5099 (class 2606 OID 90917)
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 5128 (class 2606 OID 90922)
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5127 (class 2606 OID 90927)
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5083 (class 2606 OID 90932)
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5112 (class 2606 OID 90937)
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5111 (class 2606 OID 90942)
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 5110 (class 2606 OID 90947)
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 5065 (class 2606 OID 90952)
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES users(auto_id);


--
-- TOC entry 5164 (class 2606 OID 90957)
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5163 (class 2606 OID 90962)
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5057 (class 2606 OID 90967)
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5166 (class 2606 OID 90972)
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5137 (class 2606 OID 90977)
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES menu_item(id);


--
-- TOC entry 5147 (class 2606 OID 90982)
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES table_booking_info(id);


--
-- TOC entry 5146 (class 2606 OID 90987)
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5071 (class 2606 OID 90992)
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5070 (class 2606 OID 90997)
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5069 (class 2606 OID 91002)
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5165 (class 2606 OID 91007)
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES ticket(id);


--
-- TOC entry 5058 (class 2606 OID 91012)
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5082 (class 2606 OID 91017)
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES inventory_group(id);


--
-- TOC entry 5081 (class 2606 OID 91022)
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5080 (class 2606 OID 91027)
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 5079 (class 2606 OID 91032)
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES inventory_location(id);


--
-- TOC entry 5078 (class 2606 OID 91037)
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5140 (class 2606 OID 91042)
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES restaurant(id);


--
-- TOC entry 5139 (class 2606 OID 91047)
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES inventory_item(id);


--
-- TOC entry 5138 (class 2606 OID 91052)
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES recepie(id);


--
-- TOC entry 5131 (class 2606 OID 91057)
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES multiplier(name);


--
-- TOC entry 5130 (class 2606 OID 91062)
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 5129 (class 2606 OID 91067)
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 5162 (class 2606 OID 91072)
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5098 (class 2606 OID 91077)
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES users(auto_id);


--
-- TOC entry 5097 (class 2606 OID 91082)
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5096 (class 2606 OID 91087)
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5095 (class 2606 OID 91092)
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 5094 (class 2606 OID 91097)
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES gratuity(id);


--
-- TOC entry 5093 (class 2606 OID 91102)
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES users(auto_id);


--
-- TOC entry 5150 (class 2606 OID 91107)
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 5149 (class 2606 OID 91112)
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES shop_table_type(id);


--
-- TOC entry 5153 (class 2606 OID 91117)
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES terminal(id);


--
-- TOC entry 5157 (class 2606 OID 91122)
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5156 (class 2606 OID 91127)
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5155 (class 2606 OID 91132)
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 5068 (class 2606 OID 91137)
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 5152 (class 2606 OID 91142)
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5151 (class 2606 OID 91147)
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5178 (class 2606 OID 91152)
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 5109 (class 2606 OID 91157)
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5108 (class 2606 OID 91162)
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5159 (class 2606 OID 91167)
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 5158 (class 2606 OID 91172)
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 5067 (class 2606 OID 91177)
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5066 (class 2606 OID 91182)
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5088 (class 2606 OID 91187)
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES purchase_order(id);


--
-- TOC entry 5087 (class 2606 OID 91192)
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES inventory_item(id);


--
-- TOC entry 5086 (class 2606 OID 91197)
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 5085 (class 2606 OID 91202)
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5084 (class 2606 OID 91207)
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 5141 (class 2606 OID 91212)
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 5136 (class 2606 OID 91217)
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES printer_group(id);


--
-- TOC entry 5148 (class 2606 OID 91222)
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES shop_table_status(id);


--
-- TOC entry 5077 (class 2606 OID 91227)
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5132 (class 2606 OID 91232)
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5062 (class 2606 OID 91237)
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES customer(auto_id);


--
-- TOC entry 5142 (class 2606 OID 91242)
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES shop_floor_template(id);


--
-- TOC entry 5119 (class 2606 OID 91247)
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5118 (class 2606 OID 91252)
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5056 (class 2606 OID 91257)
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5055 (class 2606 OID 91262)
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5054 (class 2606 OID 91267)
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5126 (class 2606 OID 91272)
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 5125 (class 2606 OID 91277)
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 5090 (class 2606 OID 91282)
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES order_type(id);


--
-- TOC entry 5089 (class 2606 OID 91287)
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5117 (class 2606 OID 91292)
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES menu_group(id);


--
-- TOC entry 5116 (class 2606 OID 91297)
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 5167 (class 2606 OID 91302)
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES transactions(id);


--
-- TOC entry 5092 (class 2606 OID 91307)
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES users(auto_id);


--
-- TOC entry 5135 (class 2606 OID 91312)
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES pizza_crust(id);


--
-- TOC entry 5134 (class 2606 OID 91317)
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES order_type(id);


--
-- TOC entry 5133 (class 2606 OID 91322)
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 5076 (class 2606 OID 91327)
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES tax(id);


--
-- TOC entry 5075 (class 2606 OID 91332)
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES tax_group(id);


--
-- TOC entry 5107 (class 2606 OID 91337)
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 5172 (class 2606 OID 91342)
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 5171 (class 2606 OID 91347)
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 5170 (class 2606 OID 91352)
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 5169 (class 2606 OID 91357)
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES payout_recepients(id);


--
-- TOC entry 5168 (class 2606 OID 91362)
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES payout_reasons(id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 5183 (class 2606 OID 92803)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 5184 (class 2606 OID 92808)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 5266 (class 2606 OID 94492)
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES caja_fondo_mov(id) ON DELETE CASCADE;


--
-- TOC entry 5267 (class 2606 OID 94509)
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5265 (class 2606 OID 94475)
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5264 (class 2606 OID 94453)
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 5279 (class 2606 OID 94811)
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5278 (class 2606 OID 94816)
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5275 (class 2606 OID 94791)
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5277 (class 2606 OID 94781)
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 5276 (class 2606 OID 94786)
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5273 (class 2606 OID 94755)
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5274 (class 2606 OID 94750)
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5259 (class 2606 OID 93941)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5260 (class 2606 OID 93972)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5261 (class 2606 OID 93967)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 5185 (class 2606 OID 92813)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 5187 (class 2606 OID 92818)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5186 (class 2606 OID 92823)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5189 (class 2606 OID 92828)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5188 (class 2606 OID 92833)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5283 (class 2606 OID 95458)
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5282 (class 2606 OID 95463)
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE SET NULL;


--
-- TOC entry 5291 (class 2606 OID 95386)
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5288 (class 2606 OID 95401)
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES purchase_requests(id) ON DELETE SET NULL;


--
-- TOC entry 5292 (class 2606 OID 95381)
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5289 (class 2606 OID 95396)
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5290 (class 2606 OID 95391)
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5294 (class 2606 OID 95432)
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5293 (class 2606 OID 95437)
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES cat_proveedores(id) ON DELETE SET NULL;


--
-- TOC entry 5295 (class 2606 OID 95427)
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE CASCADE;


--
-- TOC entry 5248 (class 2606 OID 92838)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5190 (class 2606 OID 92843)
-- Name: hist_cost_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5191 (class 2606 OID 92848)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5192 (class 2606 OID 92853)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5193 (class 2606 OID 92858)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5196 (class 2606 OID 92863)
-- Name: insumo_presentacion_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5195 (class 2606 OID 92868)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5194 (class 2606 OID 92873)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5268 (class 2606 OID 94535)
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES inv_consumo_pos(id) ON DELETE CASCADE;


--
-- TOC entry 5262 (class 2606 OID 93998)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 5263 (class 2606 OID 93991)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 5197 (class 2606 OID 92878)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5199 (class 2606 OID 92883)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5198 (class 2606 OID 92888)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5200 (class 2606 OID 94299)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5203 (class 2606 OID 92893)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5202 (class 2606 OID 92898)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5201 (class 2606 OID 92903)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5204 (class 2606 OID 92908)
-- Name: lote_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5208 (class 2606 OID 92913)
-- Name: merma_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5207 (class 2606 OID 92918)
-- Name: merma_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 5206 (class 2606 OID 92923)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5205 (class 2606 OID 92928)
-- Name: merma_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 5209 (class 2606 OID 92933)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5210 (class 2606 OID 92938)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5211 (class 2606 OID 92943)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 5213 (class 2606 OID 92948)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5212 (class 2606 OID 92953)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5218 (class 2606 OID 92958)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5217 (class 2606 OID 92963)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 5216 (class 2606 OID 92968)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5215 (class 2606 OID 92973)
-- Name: op_cab_usuario_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES usuario(id);


--
-- TOC entry 5214 (class 2606 OID 92978)
-- Name: op_cab_usuario_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES usuario(id);


--
-- TOC entry 5221 (class 2606 OID 92983)
-- Name: op_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5220 (class 2606 OID 92988)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5219 (class 2606 OID 92993)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5222 (class 2606 OID 92998)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5223 (class 2606 OID 93003)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5226 (class 2606 OID 93008)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5225 (class 2606 OID 93013)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5224 (class 2606 OID 93018)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5179 (class 2606 OID 91367)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5181 (class 2606 OID 91372)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5182 (class 2606 OID 91377)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5180 (class 2606 OID 91382)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5270 (class 2606 OID 94578)
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id);


--
-- TOC entry 5271 (class 2606 OID 94592)
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5227 (class 2606 OID 93023)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 5229 (class 2606 OID 93028)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 5228 (class 2606 OID 93033)
-- Name: recepcion_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 5234 (class 2606 OID 93038)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES bodega(id);


--
-- TOC entry 5233 (class 2606 OID 93043)
-- Name: recepcion_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5232 (class 2606 OID 93048)
-- Name: recepcion_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 5231 (class 2606 OID 93053)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5230 (class 2606 OID 93058)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5236 (class 2606 OID 93063)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5235 (class 2606 OID 93068)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5238 (class 2606 OID 93073)
-- Name: receta_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5237 (class 2606 OID 93078)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5239 (class 2606 OID 93083)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 5241 (class 2606 OID 93088)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5240 (class 2606 OID 93093)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5296 (class 2606 OID 102648)
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5280 (class 2606 OID 94848)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5281 (class 2606 OID 94843)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES cash_fund_movements(id) ON DELETE CASCADE;


--
-- TOC entry 5286 (class 2606 OID 95160)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5285 (class 2606 OID 95134)
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5284 (class 2606 OID 95101)
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES pos_sync_batches(id) ON DELETE CASCADE;


--
-- TOC entry 5287 (class 2606 OID 95213)
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE;


--
-- TOC entry 5269 (class 2606 OID 94563)
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5242 (class 2606 OID 93098)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5245 (class 2606 OID 93103)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5244 (class 2606 OID 93108)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5243 (class 2606 OID 93113)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 5247 (class 2606 OID 93118)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 5246 (class 2606 OID 93123)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5272 (class 2606 OID 94616)
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES transfer_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5251 (class 2606 OID 93128)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 5250 (class 2606 OID 93133)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 5249 (class 2606 OID 93138)
-- Name: traspaso_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 5255 (class 2606 OID 93143)
-- Name: traspaso_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 5254 (class 2606 OID 93148)
-- Name: traspaso_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 5253 (class 2606 OID 93153)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5252 (class 2606 OID 93158)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5257 (class 2606 OID 93163)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5256 (class 2606 OID 93168)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida(id);


--
-- TOC entry 5258 (class 2606 OID 93173)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 5790 (class 0 OID 94058)
-- Dependencies: 533 5912
-- Name: mv_dashboard_formas_pago; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_formas_pago;


--
-- TOC entry 5791 (class 0 OID 94067)
-- Dependencies: 534 5790 5912
-- Name: mv_dashboard_resumen; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_resumen;


--
-- TOC entry 5917 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 6177 (class 0 OID 0)
-- Dependencies: 515
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-10-29 18:51:53

--
-- PostgreSQL database dump complete
--

