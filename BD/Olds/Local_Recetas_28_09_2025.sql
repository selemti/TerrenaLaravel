--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-09-30 01:46:34

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE pos;
--
-- TOC entry 4240 (class 1262 OID 67811)
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
-- TOC entry 4241 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 6 (class 2615 OID 67812)
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

--
-- TOC entry 467 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 4244 (class 0 OID 0)
-- Dependencies: 467
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = selemti, pg_catalog;

--
-- TOC entry 1487 (class 1247 OID 77525)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1505 (class 1247 OID 77583)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1484 (class 1247 OID 77513)
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
-- TOC entry 468 (class 1255 OID 67813)
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
-- TOC entry 482 (class 1255 OID 67814)
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
-- TOC entry 494 (class 1255 OID 69478)
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
    AND t.paid=TRUE AND t.voided=FALSE
  GROUP BY dr.terminal_id, dr.total_revenue;
END';


ALTER FUNCTION public.fn_correct_drawer_report(report_date date) OWNER TO postgres;

--
-- TOC entry 495 (class 1255 OID 69476)
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
      WHERE tx.voided=FALSE 
        AND tx.transaction_type=''CREDIT''
        AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
    ) AS transactions_count,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS ticket_net_total,
    SUM(CASE 
          WHEN tx.voided=FALSE 
           AND tx.transaction_type=''CREDIT''
           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
          THEN tx.amount ELSE 0 END
    )::numeric(12,2) AS transactions_total,
    (SUM(CASE 
           WHEN tx.voided=FALSE 
            AND tx.transaction_type=''CREDIT''
            AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
           THEN tx.amount ELSE 0 END
     ) - SUM(t.total_price - t.total_discount)
    )::numeric(12,2) AS difference,
    CASE 
      WHEN SUM(CASE 
                 WHEN tx.voided=FALSE 
                  AND tx.transaction_type=''CREDIT''
                  AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                 THEN tx.amount ELSE 0 END
           ) = SUM(t.total_price - t.total_discount)
      THEN ''OK'' ELSE ''DISCREPANCY'' END AS status
  FROM public.ticket t
  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.terminal_id;
END';


ALTER FUNCTION public.fn_daily_reconciliation(report_date date) OWNER TO postgres;

--
-- TOC entry 493 (class 1255 OID 69477)
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
    COALESCE(SUM(CASE 
                   WHEN tx.voided=FALSE 
                    AND tx.transaction_type=''CREDIT'' 
                    AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                   THEN tx.amount END),0)::numeric(12,2) AS transactions_sum,
    (COALESCE(SUM(CASE 
                    WHEN tx.voided=FALSE 
                     AND tx.transaction_type=''CREDIT'' 
                     AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                    THEN tx.amount END),0)
     - (t.total_price - t.total_discount)
    )::numeric(12,2) AS discrepancy,
    CASE 
      WHEN COALESCE(SUM(CASE 
                          WHEN tx.voided=FALSE 
                           AND tx.transaction_type=''CREDIT'' 
                           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                          THEN tx.amount END),0) 
           > (t.total_price - t.total_discount) THEN ''OVERSTATED''
      WHEN COALESCE(SUM(CASE 
                          WHEN tx.voided=FALSE 
                           AND tx.transaction_type=''CREDIT'' 
                           AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                          THEN tx.amount END),0) 
           < (t.total_price - t.total_discount) THEN ''UNDERSTATED''
      ELSE ''OK'' END AS discrepancy_type
  FROM public.ticket t
  LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid=TRUE AND t.voided=FALSE
  GROUP BY t.id, t.terminal_id, t.daily_folio, t.total_price, t.total_discount
  HAVING COALESCE(SUM(CASE 
                        WHEN tx.voided=FALSE 
                         AND tx.transaction_type=''CREDIT'' 
                         AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                        THEN tx.amount END),0) 
         <> (t.total_price - t.total_discount)
  ORDER BY ABS(
    COALESCE(SUM(CASE 
                   WHEN tx.voided=FALSE 
                    AND tx.transaction_type=''CREDIT'' 
                    AND tx.payment_type NOT IN (''REFUND'',''VOID_TRANS'')
                   THEN tx.amount END),0) 
    - (t.total_price - t.total_discount)
  ) DESC;
END';


ALTER FUNCTION public.fn_reconciliation_detail(report_date date) OWNER TO postgres;

--
-- TOC entry 483 (class 1255 OID 67815)
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
-- TOC entry 484 (class 1255 OID 67816)
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
-- TOC entry 485 (class 1255 OID 67817)
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
-- TOC entry 486 (class 1255 OID 67818)
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
-- TOC entry 498 (class 1255 OID 77664)
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

    INSERT INTO selemti.mov_inv (ts, item_id, lote_id, cantidad, tipo, ref_tipo, ref_id)
    VALUES (now(), v_item_id, p_lote_id, 0 - v_qty_disponible, ''MERMA'', ''CIERRE_PREP'', p_lote_id)
    RETURNING id INTO v_mov_id;

    INSERT INTO selemti.perdida_log (ts, item_id, lote_id, clase, motivo, qty_canonica, usuario_id, ref_tipo, ref_id)
    VALUES (now(), v_item_id, p_lote_id, p_clase, p_motivo, v_qty_disponible, p_usuario_id, ''CIERRE_PREP'', v_mov_id);

    RETURN v_mov_id;
END;
';


ALTER FUNCTION selemti.cerrar_lote_preparado(p_lote_id bigint, p_clase merma_clase, p_motivo text, p_usuario_id integer, p_uom_id integer) OWNER TO postgres;

--
-- TOC entry 487 (class 1255 OID 67819)
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
-- TOC entry 488 (class 1255 OID 67820)
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
-- TOC entry 481 (class 1255 OID 67821)
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
-- TOC entry 489 (class 1255 OID 67822)
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
-- TOC entry 490 (class 1255 OID 67823)
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
-- TOC entry 491 (class 1255 OID 67824)
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
-- TOC entry 492 (class 1255 OID 67825)
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
-- TOC entry 497 (class 1255 OID 77663)
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
        
        UPDATE selemti.ticket_venta_det
        SET receta_shadow_id = currval(''selemti.receta_shadow_id_seq''), reprocesado = TRUE, version_reproceso = 1
        WHERE item_id = v_plato_record.item_id
          AND ticket_id IN (SELECT id FROM selemti.ticket_venta_cab WHERE fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta);
        
        v_recetas_inferidas := v_recetas_inferidas + 1;
    END LOOP;
    
    RETURN v_recetas_inferidas;
END;
';


ALTER FUNCTION selemti.inferir_recetas_de_ventas(p_fecha_desde date, p_fecha_hasta date) OWNER TO postgres;

--
-- TOC entry 499 (class 1255 OID 77999)
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
END;
';


ALTER FUNCTION selemti.registrar_consumo_porcionado(p_ticket_id bigint, p_ticket_det_id bigint, p_item_id text, p_qty_total numeric, p_distribucion json) OWNER TO postgres;

--
-- TOC entry 496 (class 1255 OID 77662)
-- Name: reprocesar_costos_historicos(date, date, character varying, integer); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date DEFAULT NULL::date, p_algoritmo character varying DEFAULT 'WAC'::character varying, p_usuario_id integer DEFAULT 1) RETURNS integer
    LANGUAGE plpgsql
    AS '
DECLARE
    v_lote_id INTEGER;
    v_total_actualizados INTEGER := 0;
    v_item_record RECORD;
BEGIN
    IF p_fecha_hasta IS NULL THEN
        p_fecha_hasta := CURRENT_DATE;
    END IF;
    
    INSERT INTO selemti.job_recalc_queue (scope_type, scope_from, scope_to, reason, status)
    VALUES (''PERIODO'', p_fecha_desde, p_fecha_hasta, ''Reproceso costos '' || p_algoritmo, ''RUNNING'')
    RETURNING id INTO v_lote_id;
    
    FOR v_item_record IN 
        SELECT DISTINCT item_id 
        FROM selemti.mov_inv 
        WHERE ts BETWEEN p_fecha_desde AND p_fecha_hasta
    LOOP
        UPDATE selemti.historial_costos_item
        SET costo_wac = (
            SELECT AVG(costo_unit * cantidad) / NULLIF(SUM(cantidad), 0)
            FROM selemti.mov_inv 
            WHERE item_id = v_item_record.item_id 
            AND ts BETWEEN p_fecha_desde AND p_fecha_hasta 
            AND tipo IN (''COMPRA'', ''RECEPCION'')
        )
        WHERE item_id = v_item_record.item_id AND fecha_efectiva BETWEEN p_fecha_desde AND p_fecha_hasta;
        
        v_total_actualizados := v_total_actualizados + 1;
    END LOOP;
    
    UPDATE selemti.job_recalc_queue 
    SET status = ''DONE'', 
        result = (''{"actualizados": '' || v_total_actualizados || ''}'')::json
    WHERE id = v_lote_id;
    
    RETURN v_total_actualizados;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE selemti.job_recalc_queue 
        SET status = ''FAILED'', 
            result = (''{"error": "'' || REPLACE(SQLERRM, ''"'', ''\"'') || ''"}'')::json
        WHERE id = v_lote_id;
        RAISE;
END;
';


ALTER FUNCTION selemti.reprocesar_costos_historicos(p_fecha_desde date, p_fecha_hasta date, p_algoritmo character varying, p_usuario_id integer) OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 181 (class 1259 OID 67826)
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
-- TOC entry 182 (class 1259 OID 67832)
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
-- TOC entry 4246 (class 0 OID 0)
-- Dependencies: 182
-- Name: action_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE action_history_id_seq OWNED BY action_history.id;


--
-- TOC entry 183 (class 1259 OID 67834)
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
-- TOC entry 184 (class 1259 OID 67837)
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
-- TOC entry 4248 (class 0 OID 0)
-- Dependencies: 184
-- Name: attendence_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE attendence_history_id_seq OWNED BY attendence_history.id;


--
-- TOC entry 185 (class 1259 OID 67839)
-- Name: cash_drawer; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer (
    id integer NOT NULL,
    terminal_id integer
);


ALTER TABLE cash_drawer OWNER TO floreant;

--
-- TOC entry 186 (class 1259 OID 67842)
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
-- TOC entry 4250 (class 0 OID 0)
-- Dependencies: 186
-- Name: cash_drawer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_id_seq OWNED BY cash_drawer.id;


--
-- TOC entry 187 (class 1259 OID 67844)
-- Name: cash_drawer_reset_history; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cash_drawer_reset_history (
    id integer NOT NULL,
    reset_time timestamp without time zone,
    user_id integer
);


ALTER TABLE cash_drawer_reset_history OWNER TO floreant;

--
-- TOC entry 188 (class 1259 OID 67847)
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
-- TOC entry 4252 (class 0 OID 0)
-- Dependencies: 188
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cash_drawer_reset_history_id_seq OWNED BY cash_drawer_reset_history.id;


--
-- TOC entry 189 (class 1259 OID 67849)
-- Name: cooking_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE cooking_instruction (
    id integer NOT NULL,
    description character varying(60)
);


ALTER TABLE cooking_instruction OWNER TO floreant;

--
-- TOC entry 190 (class 1259 OID 67852)
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
-- TOC entry 4254 (class 0 OID 0)
-- Dependencies: 190
-- Name: cooking_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE cooking_instruction_id_seq OWNED BY cooking_instruction.id;


--
-- TOC entry 191 (class 1259 OID 67854)
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
-- TOC entry 192 (class 1259 OID 67857)
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
-- TOC entry 4256 (class 0 OID 0)
-- Dependencies: 192
-- Name: coupon_and_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE coupon_and_discount_id_seq OWNED BY coupon_and_discount.id;


--
-- TOC entry 193 (class 1259 OID 67859)
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
-- TOC entry 194 (class 1259 OID 67862)
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
-- TOC entry 195 (class 1259 OID 67865)
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
-- TOC entry 4259 (class 0 OID 0)
-- Dependencies: 195
-- Name: currency_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_balance_id_seq OWNED BY currency_balance.id;


--
-- TOC entry 196 (class 1259 OID 67867)
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
-- TOC entry 4260 (class 0 OID 0)
-- Dependencies: 196
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE currency_id_seq OWNED BY currency.id;


--
-- TOC entry 197 (class 1259 OID 67869)
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
-- TOC entry 198 (class 1259 OID 67872)
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
-- TOC entry 4262 (class 0 OID 0)
-- Dependencies: 198
-- Name: custom_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE custom_payment_id_seq OWNED BY custom_payment.id;


--
-- TOC entry 199 (class 1259 OID 67874)
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
-- TOC entry 200 (class 1259 OID 67880)
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
-- TOC entry 4264 (class 0 OID 0)
-- Dependencies: 200
-- Name: customer_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE customer_auto_id_seq OWNED BY customer.auto_id;


--
-- TOC entry 201 (class 1259 OID 67882)
-- Name: customer_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE customer_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE customer_properties OWNER TO floreant;

--
-- TOC entry 202 (class 1259 OID 67888)
-- Name: daily_folio_counter; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE daily_folio_counter (
    folio_date date NOT NULL,
    branch_key text NOT NULL,
    last_value integer DEFAULT 0 NOT NULL
);


ALTER TABLE daily_folio_counter OWNER TO floreant;

--
-- TOC entry 203 (class 1259 OID 67895)
-- Name: data_update_info; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE data_update_info (
    id integer NOT NULL,
    last_update_time timestamp without time zone
);


ALTER TABLE data_update_info OWNER TO floreant;

--
-- TOC entry 204 (class 1259 OID 67898)
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
-- TOC entry 4268 (class 0 OID 0)
-- Dependencies: 204
-- Name: data_update_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE data_update_info_id_seq OWNED BY data_update_info.id;


--
-- TOC entry 205 (class 1259 OID 67900)
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
-- TOC entry 206 (class 1259 OID 67903)
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
-- TOC entry 4270 (class 0 OID 0)
-- Dependencies: 206
-- Name: delivery_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_address_id_seq OWNED BY delivery_address.id;


--
-- TOC entry 207 (class 1259 OID 67905)
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
-- TOC entry 208 (class 1259 OID 67908)
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
-- TOC entry 4272 (class 0 OID 0)
-- Dependencies: 208
-- Name: delivery_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_charge_id_seq OWNED BY delivery_charge.id;


--
-- TOC entry 209 (class 1259 OID 67910)
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
-- TOC entry 210 (class 1259 OID 67913)
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
-- TOC entry 4274 (class 0 OID 0)
-- Dependencies: 210
-- Name: delivery_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_configuration_id_seq OWNED BY delivery_configuration.id;


--
-- TOC entry 211 (class 1259 OID 67915)
-- Name: delivery_instruction; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE delivery_instruction (
    id integer NOT NULL,
    notes character varying(220),
    customer_no integer
);


ALTER TABLE delivery_instruction OWNER TO floreant;

--
-- TOC entry 212 (class 1259 OID 67918)
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
-- TOC entry 4276 (class 0 OID 0)
-- Dependencies: 212
-- Name: delivery_instruction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE delivery_instruction_id_seq OWNED BY delivery_instruction.id;


--
-- TOC entry 213 (class 1259 OID 67920)
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
-- TOC entry 214 (class 1259 OID 67923)
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
-- TOC entry 4278 (class 0 OID 0)
-- Dependencies: 214
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_assigned_history_id_seq OWNED BY drawer_assigned_history.id;


--
-- TOC entry 215 (class 1259 OID 67925)
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
-- TOC entry 216 (class 1259 OID 67928)
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
-- TOC entry 4280 (class 0 OID 0)
-- Dependencies: 216
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE drawer_pull_report_id_seq OWNED BY drawer_pull_report.id;


--
-- TOC entry 217 (class 1259 OID 67930)
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
-- TOC entry 218 (class 1259 OID 67936)
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
-- TOC entry 219 (class 1259 OID 67939)
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
-- TOC entry 4283 (class 0 OID 0)
-- Dependencies: 219
-- Name: employee_in_out_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE employee_in_out_history_id_seq OWNED BY employee_in_out_history.id;


--
-- TOC entry 220 (class 1259 OID 67941)
-- Name: global_config; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE global_config (
    id integer NOT NULL,
    pos_key character varying(60),
    pos_value character varying(220)
);


ALTER TABLE global_config OWNER TO floreant;

--
-- TOC entry 221 (class 1259 OID 67944)
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
-- TOC entry 4285 (class 0 OID 0)
-- Dependencies: 221
-- Name: global_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE global_config_id_seq OWNED BY global_config.id;


--
-- TOC entry 222 (class 1259 OID 67946)
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
-- TOC entry 223 (class 1259 OID 67949)
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
-- TOC entry 4287 (class 0 OID 0)
-- Dependencies: 223
-- Name: gratuity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE gratuity_id_seq OWNED BY gratuity.id;


--
-- TOC entry 224 (class 1259 OID 67951)
-- Name: group_taxes; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE group_taxes (
    group_id character varying(128) NOT NULL,
    elt integer NOT NULL
);


ALTER TABLE group_taxes OWNER TO floreant;

--
-- TOC entry 225 (class 1259 OID 67954)
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
-- TOC entry 226 (class 1259 OID 67957)
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
-- TOC entry 4290 (class 0 OID 0)
-- Dependencies: 226
-- Name: guest_check_print_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE guest_check_print_id_seq OWNED BY guest_check_print.id;


--
-- TOC entry 227 (class 1259 OID 67959)
-- Name: inventory_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_group OWNER TO floreant;

--
-- TOC entry 228 (class 1259 OID 67962)
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
-- TOC entry 4292 (class 0 OID 0)
-- Dependencies: 228
-- Name: inventory_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_group_id_seq OWNED BY inventory_group.id;


--
-- TOC entry 229 (class 1259 OID 67964)
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
-- TOC entry 230 (class 1259 OID 67967)
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
-- TOC entry 4294 (class 0 OID 0)
-- Dependencies: 230
-- Name: inventory_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_item_id_seq OWNED BY inventory_item.id;


--
-- TOC entry 231 (class 1259 OID 67969)
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
-- TOC entry 232 (class 1259 OID 67972)
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
-- TOC entry 4296 (class 0 OID 0)
-- Dependencies: 232
-- Name: inventory_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_location_id_seq OWNED BY inventory_location.id;


--
-- TOC entry 233 (class 1259 OID 67974)
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
-- TOC entry 234 (class 1259 OID 67980)
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
-- TOC entry 4298 (class 0 OID 0)
-- Dependencies: 234
-- Name: inventory_meta_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_meta_code_id_seq OWNED BY inventory_meta_code.id;


--
-- TOC entry 235 (class 1259 OID 67982)
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
-- TOC entry 236 (class 1259 OID 67985)
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
-- TOC entry 4300 (class 0 OID 0)
-- Dependencies: 236
-- Name: inventory_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_transaction_id_seq OWNED BY inventory_transaction.id;


--
-- TOC entry 237 (class 1259 OID 67987)
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
-- TOC entry 238 (class 1259 OID 67993)
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
-- TOC entry 4302 (class 0 OID 0)
-- Dependencies: 238
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_unit_id_seq OWNED BY inventory_unit.id;


--
-- TOC entry 239 (class 1259 OID 67995)
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
-- TOC entry 240 (class 1259 OID 68001)
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
-- TOC entry 4304 (class 0 OID 0)
-- Dependencies: 240
-- Name: inventory_vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_vendor_id_seq OWNED BY inventory_vendor.id;


--
-- TOC entry 241 (class 1259 OID 68003)
-- Name: inventory_warehouse; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE inventory_warehouse (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    visible boolean
);


ALTER TABLE inventory_warehouse OWNER TO floreant;

--
-- TOC entry 242 (class 1259 OID 68006)
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
-- TOC entry 4306 (class 0 OID 0)
-- Dependencies: 242
-- Name: inventory_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE inventory_warehouse_id_seq OWNED BY inventory_warehouse.id;


--
-- TOC entry 243 (class 1259 OID 68008)
-- Name: item_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE item_order_type (
    menu_item_id integer NOT NULL,
    order_type_id integer NOT NULL
);


ALTER TABLE item_order_type OWNER TO floreant;

--
-- TOC entry 244 (class 1259 OID 68011)
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
-- TOC entry 245 (class 1259 OID 68014)
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
-- TOC entry 246 (class 1259 OID 68020)
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
-- TOC entry 247 (class 1259 OID 68027)
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
-- TOC entry 248 (class 1259 OID 68032)
-- Name: kds_ready_log; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kds_ready_log (
    ticket_id integer NOT NULL,
    notified_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE kds_ready_log OWNER TO floreant;

--
-- TOC entry 249 (class 1259 OID 68036)
-- Name: kit_ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE kit_ticket_table_num (
    kit_ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE kit_ticket_table_num OWNER TO floreant;

--
-- TOC entry 250 (class 1259 OID 68039)
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
-- TOC entry 4314 (class 0 OID 0)
-- Dependencies: 250
-- Name: kitchen_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_id_seq OWNED BY kitchen_ticket.id;


--
-- TOC entry 251 (class 1259 OID 68041)
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
-- TOC entry 252 (class 1259 OID 68047)
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
-- TOC entry 4316 (class 0 OID 0)
-- Dependencies: 252
-- Name: kitchen_ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE kitchen_ticket_item_id_seq OWNED BY kitchen_ticket_item.id;


--
-- TOC entry 253 (class 1259 OID 68049)
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
-- TOC entry 254 (class 1259 OID 68052)
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
-- TOC entry 4318 (class 0 OID 0)
-- Dependencies: 254
-- Name: menu_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_category_id_seq OWNED BY menu_category.id;


--
-- TOC entry 255 (class 1259 OID 68054)
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
-- TOC entry 256 (class 1259 OID 68057)
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
-- TOC entry 4320 (class 0 OID 0)
-- Dependencies: 256
-- Name: menu_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_group_id_seq OWNED BY menu_group.id;


--
-- TOC entry 257 (class 1259 OID 68059)
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
-- TOC entry 258 (class 1259 OID 68065)
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
-- TOC entry 4322 (class 0 OID 0)
-- Dependencies: 258
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_id_seq OWNED BY menu_item.id;


--
-- TOC entry 259 (class 1259 OID 68067)
-- Name: menu_item_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_properties (
    menu_item_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_item_properties OWNER TO floreant;

--
-- TOC entry 260 (class 1259 OID 68070)
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
-- TOC entry 261 (class 1259 OID 68073)
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
-- TOC entry 4325 (class 0 OID 0)
-- Dependencies: 261
-- Name: menu_item_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_item_size_id_seq OWNED BY menu_item_size.id;


--
-- TOC entry 262 (class 1259 OID 68075)
-- Name: menu_item_terminal_ref; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_item_terminal_ref (
    menu_item_id integer NOT NULL,
    terminal_id integer NOT NULL
);


ALTER TABLE menu_item_terminal_ref OWNER TO floreant;

--
-- TOC entry 263 (class 1259 OID 68078)
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
-- TOC entry 264 (class 1259 OID 68081)
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
-- TOC entry 265 (class 1259 OID 68084)
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
-- TOC entry 4329 (class 0 OID 0)
-- Dependencies: 265
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_group_id_seq OWNED BY menu_modifier_group.id;


--
-- TOC entry 266 (class 1259 OID 68086)
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
-- TOC entry 4330 (class 0 OID 0)
-- Dependencies: 266
-- Name: menu_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menu_modifier_id_seq OWNED BY menu_modifier.id;


--
-- TOC entry 267 (class 1259 OID 68088)
-- Name: menu_modifier_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menu_modifier_properties (
    menu_modifier_id integer NOT NULL,
    property_value character varying(100),
    property_name character varying(255) NOT NULL
);


ALTER TABLE menu_modifier_properties OWNER TO floreant;

--
-- TOC entry 268 (class 1259 OID 68091)
-- Name: menucategory_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menucategory_discount (
    discount_id integer NOT NULL,
    menucategory_id integer NOT NULL
);


ALTER TABLE menucategory_discount OWNER TO floreant;

--
-- TOC entry 269 (class 1259 OID 68094)
-- Name: menugroup_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menugroup_discount (
    discount_id integer NOT NULL,
    menugroup_id integer NOT NULL
);


ALTER TABLE menugroup_discount OWNER TO floreant;

--
-- TOC entry 270 (class 1259 OID 68097)
-- Name: menuitem_discount; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_discount (
    discount_id integer NOT NULL,
    menuitem_id integer NOT NULL
);


ALTER TABLE menuitem_discount OWNER TO floreant;

--
-- TOC entry 271 (class 1259 OID 68100)
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
-- TOC entry 272 (class 1259 OID 68103)
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
-- TOC entry 4336 (class 0 OID 0)
-- Dependencies: 272
-- Name: menuitem_modifiergroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_modifiergroup_id_seq OWNED BY menuitem_modifiergroup.id;


--
-- TOC entry 273 (class 1259 OID 68105)
-- Name: menuitem_pizzapirce; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menuitem_pizzapirce (
    menu_item_id integer NOT NULL,
    pizza_price_id integer NOT NULL
);


ALTER TABLE menuitem_pizzapirce OWNER TO floreant;

--
-- TOC entry 274 (class 1259 OID 68108)
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
-- TOC entry 275 (class 1259 OID 68111)
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
-- TOC entry 4339 (class 0 OID 0)
-- Dependencies: 275
-- Name: menuitem_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE menuitem_shift_id_seq OWNED BY menuitem_shift.id;


--
-- TOC entry 276 (class 1259 OID 68113)
-- Name: menumodifier_pizzamodifierprice; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE menumodifier_pizzamodifierprice (
    menumodifier_id integer NOT NULL,
    pizzamodifierprice_id integer NOT NULL
);


ALTER TABLE menumodifier_pizzamodifierprice OWNER TO floreant;

--
-- TOC entry 389 (class 1259 OID 73602)
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 73600)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE migrations_id_seq OWNER TO postgres;

--
-- TOC entry 4342 (class 0 OID 0)
-- Dependencies: 388
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


--
-- TOC entry 277 (class 1259 OID 68116)
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
-- TOC entry 278 (class 1259 OID 68119)
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
-- TOC entry 4344 (class 0 OID 0)
-- Dependencies: 278
-- Name: modifier_multiplier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE modifier_multiplier_price_id_seq OWNED BY modifier_multiplier_price.id;


--
-- TOC entry 279 (class 1259 OID 68121)
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
-- TOC entry 280 (class 1259 OID 68124)
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
-- TOC entry 281 (class 1259 OID 68130)
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
-- TOC entry 4347 (class 0 OID 0)
-- Dependencies: 281
-- Name: order_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE order_type_id_seq OWNED BY order_type.id;


--
-- TOC entry 282 (class 1259 OID 68132)
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
-- TOC entry 283 (class 1259 OID 68135)
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
-- TOC entry 4349 (class 0 OID 0)
-- Dependencies: 283
-- Name: packaging_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE packaging_unit_id_seq OWNED BY packaging_unit.id;


--
-- TOC entry 284 (class 1259 OID 68137)
-- Name: payout_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_reasons (
    id integer NOT NULL,
    reason character varying(255)
);


ALTER TABLE payout_reasons OWNER TO floreant;

--
-- TOC entry 285 (class 1259 OID 68140)
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
-- TOC entry 4351 (class 0 OID 0)
-- Dependencies: 285
-- Name: payout_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_reasons_id_seq OWNED BY payout_reasons.id;


--
-- TOC entry 286 (class 1259 OID 68142)
-- Name: payout_recepients; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE payout_recepients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE payout_recepients OWNER TO floreant;

--
-- TOC entry 287 (class 1259 OID 68145)
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
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 287
-- Name: payout_recepients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE payout_recepients_id_seq OWNED BY payout_recepients.id;


--
-- TOC entry 288 (class 1259 OID 68147)
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
-- TOC entry 289 (class 1259 OID 68150)
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
-- TOC entry 4355 (class 0 OID 0)
-- Dependencies: 289
-- Name: pizza_crust_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_crust_id_seq OWNED BY pizza_crust.id;


--
-- TOC entry 290 (class 1259 OID 68152)
-- Name: pizza_modifier_price; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE pizza_modifier_price (
    id integer NOT NULL,
    item_size integer
);


ALTER TABLE pizza_modifier_price OWNER TO floreant;

--
-- TOC entry 291 (class 1259 OID 68155)
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
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 291
-- Name: pizza_modifier_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_modifier_price_id_seq OWNED BY pizza_modifier_price.id;


--
-- TOC entry 292 (class 1259 OID 68157)
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
-- TOC entry 293 (class 1259 OID 68160)
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
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 293
-- Name: pizza_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE pizza_price_id_seq OWNED BY pizza_price.id;


--
-- TOC entry 294 (class 1259 OID 68162)
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
-- TOC entry 295 (class 1259 OID 68168)
-- Name: printer_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    is_default boolean
);


ALTER TABLE printer_group OWNER TO floreant;

--
-- TOC entry 296 (class 1259 OID 68171)
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
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 296
-- Name: printer_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE printer_group_id_seq OWNED BY printer_group.id;


--
-- TOC entry 297 (class 1259 OID 68173)
-- Name: printer_group_printers; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE printer_group_printers (
    printer_id integer NOT NULL,
    printer_name character varying(255)
);


ALTER TABLE printer_group_printers OWNER TO floreant;

--
-- TOC entry 298 (class 1259 OID 68176)
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE purchase_order (
    id integer NOT NULL,
    order_id character varying(30),
    name character varying(30)
);


ALTER TABLE purchase_order OWNER TO floreant;

--
-- TOC entry 299 (class 1259 OID 68179)
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
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 299
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE purchase_order_id_seq OWNED BY purchase_order.id;


--
-- TOC entry 300 (class 1259 OID 68181)
-- Name: recepie; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE recepie (
    id integer NOT NULL,
    menu_item integer
);


ALTER TABLE recepie OWNER TO floreant;

--
-- TOC entry 301 (class 1259 OID 68184)
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
-- TOC entry 4367 (class 0 OID 0)
-- Dependencies: 301
-- Name: recepie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_id_seq OWNED BY recepie.id;


--
-- TOC entry 302 (class 1259 OID 68186)
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
-- TOC entry 303 (class 1259 OID 68189)
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
-- TOC entry 4369 (class 0 OID 0)
-- Dependencies: 303
-- Name: recepie_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE recepie_item_id_seq OWNED BY recepie_item.id;


--
-- TOC entry 304 (class 1259 OID 68191)
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
-- TOC entry 305 (class 1259 OID 68194)
-- Name: restaurant_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE restaurant_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE restaurant_properties OWNER TO floreant;

--
-- TOC entry 306 (class 1259 OID 68200)
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
-- TOC entry 307 (class 1259 OID 68203)
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
-- TOC entry 4373 (class 0 OID 0)
-- Dependencies: 307
-- Name: shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shift_id_seq OWNED BY shift.id;


--
-- TOC entry 308 (class 1259 OID 68205)
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
-- TOC entry 309 (class 1259 OID 68208)
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
-- TOC entry 4375 (class 0 OID 0)
-- Dependencies: 309
-- Name: shop_floor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_id_seq OWNED BY shop_floor.id;


--
-- TOC entry 310 (class 1259 OID 68210)
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
-- TOC entry 311 (class 1259 OID 68213)
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
-- TOC entry 4377 (class 0 OID 0)
-- Dependencies: 311
-- Name: shop_floor_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_floor_template_id_seq OWNED BY shop_floor_template.id;


--
-- TOC entry 312 (class 1259 OID 68215)
-- Name: shop_floor_template_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_floor_template_properties (
    id integer NOT NULL,
    property_value character varying(60),
    property_name character varying(255) NOT NULL
);


ALTER TABLE shop_floor_template_properties OWNER TO floreant;

--
-- TOC entry 313 (class 1259 OID 68218)
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
-- TOC entry 314 (class 1259 OID 68221)
-- Name: shop_table_status; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_status (
    id integer NOT NULL,
    table_status integer
);


ALTER TABLE shop_table_status OWNER TO floreant;

--
-- TOC entry 315 (class 1259 OID 68224)
-- Name: shop_table_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE shop_table_type (
    id integer NOT NULL,
    description character varying(120),
    name character varying(40)
);


ALTER TABLE shop_table_type OWNER TO floreant;

--
-- TOC entry 316 (class 1259 OID 68227)
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
-- TOC entry 4382 (class 0 OID 0)
-- Dependencies: 316
-- Name: shop_table_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE shop_table_type_id_seq OWNED BY shop_table_type.id;


--
-- TOC entry 317 (class 1259 OID 68229)
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
-- TOC entry 318 (class 1259 OID 68232)
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
-- TOC entry 4384 (class 0 OID 0)
-- Dependencies: 318
-- Name: table_booking_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE table_booking_info_id_seq OWNED BY table_booking_info.id;


--
-- TOC entry 319 (class 1259 OID 68234)
-- Name: table_booking_mapping; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_booking_mapping (
    booking_id integer NOT NULL,
    table_id integer NOT NULL
);


ALTER TABLE table_booking_mapping OWNER TO floreant;

--
-- TOC entry 320 (class 1259 OID 68237)
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
-- TOC entry 321 (class 1259 OID 68240)
-- Name: table_type_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE table_type_relation (
    table_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE table_type_relation OWNER TO floreant;

--
-- TOC entry 322 (class 1259 OID 68243)
-- Name: tax; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    rate double precision
);


ALTER TABLE tax OWNER TO floreant;

--
-- TOC entry 323 (class 1259 OID 68246)
-- Name: tax_group; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE tax_group (
    id character varying(128) NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE tax_group OWNER TO floreant;

--
-- TOC entry 324 (class 1259 OID 68249)
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
-- TOC entry 4390 (class 0 OID 0)
-- Dependencies: 324
-- Name: tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE tax_id_seq OWNED BY tax.id;


--
-- TOC entry 325 (class 1259 OID 68251)
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
-- TOC entry 326 (class 1259 OID 68254)
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
-- TOC entry 4392 (class 0 OID 0)
-- Dependencies: 326
-- Name: terminal_printers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE terminal_printers_id_seq OWNED BY terminal_printers.id;


--
-- TOC entry 327 (class 1259 OID 68256)
-- Name: terminal_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE terminal_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE terminal_properties OWNER TO floreant;

--
-- TOC entry 328 (class 1259 OID 68262)
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
-- TOC entry 329 (class 1259 OID 68265)
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
-- TOC entry 4395 (class 0 OID 0)
-- Dependencies: 329
-- Name: ticket_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_discount_id_seq OWNED BY ticket_discount.id;


--
-- TOC entry 330 (class 1259 OID 68267)
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
-- TOC entry 331 (class 1259 OID 68272)
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
-- TOC entry 4397 (class 0 OID 0)
-- Dependencies: 331
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_id_seq OWNED BY ticket.id;


--
-- TOC entry 332 (class 1259 OID 68274)
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
-- TOC entry 333 (class 1259 OID 68280)
-- Name: ticket_item_addon_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_addon_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_addon_relation OWNER TO floreant;

--
-- TOC entry 334 (class 1259 OID 68283)
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
-- TOC entry 335 (class 1259 OID 68286)
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
-- TOC entry 336 (class 1259 OID 68289)
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
-- TOC entry 4402 (class 0 OID 0)
-- Dependencies: 336
-- Name: ticket_item_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_discount_id_seq OWNED BY ticket_item_discount.id;


--
-- TOC entry 337 (class 1259 OID 68291)
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
-- TOC entry 4403 (class 0 OID 0)
-- Dependencies: 337
-- Name: ticket_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_id_seq OWNED BY ticket_item.id;


--
-- TOC entry 338 (class 1259 OID 68293)
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
-- TOC entry 339 (class 1259 OID 68296)
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
-- TOC entry 4405 (class 0 OID 0)
-- Dependencies: 339
-- Name: ticket_item_modifier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE ticket_item_modifier_id_seq OWNED BY ticket_item_modifier.id;


--
-- TOC entry 340 (class 1259 OID 68298)
-- Name: ticket_item_modifier_relation; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_item_modifier_relation (
    ticket_item_id integer NOT NULL,
    modifier_id integer NOT NULL,
    list_order integer NOT NULL
);


ALTER TABLE ticket_item_modifier_relation OWNER TO floreant;

--
-- TOC entry 341 (class 1259 OID 68301)
-- Name: ticket_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_properties (
    id integer NOT NULL,
    property_value character varying(1000),
    property_name character varying(255) NOT NULL
);


ALTER TABLE ticket_properties OWNER TO floreant;

--
-- TOC entry 342 (class 1259 OID 68307)
-- Name: ticket_table_num; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE ticket_table_num (
    ticket_id integer NOT NULL,
    table_id integer
);


ALTER TABLE ticket_table_num OWNER TO floreant;

--
-- TOC entry 343 (class 1259 OID 68310)
-- Name: transaction_properties; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE transaction_properties (
    id integer NOT NULL,
    property_value character varying(255),
    property_name character varying(255) NOT NULL
);


ALTER TABLE transaction_properties OWNER TO floreant;

--
-- TOC entry 344 (class 1259 OID 68316)
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
-- TOC entry 345 (class 1259 OID 68322)
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
-- TOC entry 4411 (class 0 OID 0)
-- Dependencies: 345
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- TOC entry 346 (class 1259 OID 68324)
-- Name: user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_permission (
    name character varying(40) NOT NULL
);


ALTER TABLE user_permission OWNER TO floreant;

--
-- TOC entry 347 (class 1259 OID 68327)
-- Name: user_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_type (
    id integer NOT NULL,
    p_name character varying(60)
);


ALTER TABLE user_type OWNER TO floreant;

--
-- TOC entry 348 (class 1259 OID 68330)
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
-- TOC entry 4414 (class 0 OID 0)
-- Dependencies: 348
-- Name: user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE user_type_id_seq OWNED BY user_type.id;


--
-- TOC entry 349 (class 1259 OID 68332)
-- Name: user_user_permission; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE user_user_permission (
    permissionid integer NOT NULL,
    elt character varying(40) NOT NULL
);


ALTER TABLE user_user_permission OWNER TO floreant;

--
-- TOC entry 350 (class 1259 OID 68335)
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
-- TOC entry 351 (class 1259 OID 68338)
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
-- TOC entry 4417 (class 0 OID 0)
-- Dependencies: 351
-- Name: users_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE users_auto_id_seq OWNED BY users.auto_id;


--
-- TOC entry 352 (class 1259 OID 68340)
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
-- TOC entry 353 (class 1259 OID 68343)
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
-- TOC entry 4419 (class 0 OID 0)
-- Dependencies: 353
-- Name: virtual_printer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE virtual_printer_id_seq OWNED BY virtual_printer.id;


--
-- TOC entry 354 (class 1259 OID 68345)
-- Name: virtualprinter_order_type; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE virtualprinter_order_type (
    printer_id integer NOT NULL,
    order_type character varying(255)
);


ALTER TABLE virtualprinter_order_type OWNER TO floreant;

--
-- TOC entry 355 (class 1259 OID 68348)
-- Name: void_reasons; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE void_reasons (
    id integer NOT NULL,
    reason_text character varying(255)
);


ALTER TABLE void_reasons OWNER TO floreant;

--
-- TOC entry 356 (class 1259 OID 68351)
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
-- TOC entry 4422 (class 0 OID 0)
-- Dependencies: 356
-- Name: void_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE void_reasons_id_seq OWNED BY void_reasons.id;


--
-- TOC entry 381 (class 1259 OID 69479)
-- Name: vw_reconciliation_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_reconciliation_status AS
 SELECT (t.closing_date)::date AS report_date,
    t.terminal_id,
    count(DISTINCT t.id) AS tickets_count,
    count(tx.id) FILTER (WHERE ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[])))) AS transactions_count,
    (sum((t.total_price - t.total_discount)))::numeric(12,2) AS correct_total,
    (sum(
        CASE
            WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS current_system_total,
    ((sum(
        CASE
            WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
            ELSE (0)::double precision
        END) - sum((t.total_price - t.total_discount))))::numeric(12,2) AS discrepancy,
        CASE
            WHEN (NULLIF(sum((t.total_price - t.total_discount)), (0)::double precision) IS NULL) THEN (0)::numeric
            ELSE round(((((sum(
            CASE
                WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
                ELSE (0)::double precision
            END) - sum((t.total_price - t.total_discount))) / sum((t.total_price - t.total_discount))) * (100)::double precision))::numeric, 2)
        END AS discrepancy_percent
   FROM (ticket t
     LEFT JOIN transactions tx ON ((tx.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND ((t.closing_date)::date >= (('now'::text)::date - '7 days'::interval)))
  GROUP BY ((t.closing_date)::date), t.terminal_id;


ALTER TABLE vw_reconciliation_status OWNER TO postgres;

--
-- TOC entry 357 (class 1259 OID 68353)
-- Name: zip_code_vs_delivery_charge; Type: TABLE; Schema: public; Owner: floreant
--

CREATE TABLE zip_code_vs_delivery_charge (
    auto_id integer NOT NULL,
    zip_code character varying(10) NOT NULL,
    delivery_charge double precision NOT NULL
);


ALTER TABLE zip_code_vs_delivery_charge OWNER TO floreant;

--
-- TOC entry 358 (class 1259 OID 68356)
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
-- TOC entry 4425 (class 0 OID 0)
-- Dependencies: 358
-- Name: zip_code_vs_delivery_charge_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: floreant
--

ALTER SEQUENCE zip_code_vs_delivery_charge_auto_id_seq OWNED BY zip_code_vs_delivery_charge.auto_id;


SET search_path = selemti, pg_catalog;

--
-- TOC entry 464 (class 1259 OID 77970)
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
-- TOC entry 359 (class 1259 OID 68358)
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
-- TOC entry 360 (class 1259 OID 68365)
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
-- TOC entry 4426 (class 0 OID 0)
-- Dependencies: 360
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE auditoria_id_seq OWNED BY auditoria.id;


--
-- TOC entry 394 (class 1259 OID 73651)
-- Name: cache; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache OWNER TO postgres;

--
-- TOC entry 395 (class 1259 OID 73659)
-- Name: cache_locks; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE cache_locks OWNER TO postgres;

--
-- TOC entry 402 (class 1259 OID 73704)
-- Name: cat_unidades; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE cat_unidades OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 73702)
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
-- TOC entry 4427 (class 0 OID 0)
-- Dependencies: 401
-- Name: cat_unidades_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;


--
-- TOC entry 423 (class 1259 OID 77265)
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
-- TOC entry 422 (class 1259 OID 77263)
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
-- TOC entry 4428 (class 0 OID 0)
-- Dependencies: 422
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad.id;


--
-- TOC entry 431 (class 1259 OID 77393)
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
-- TOC entry 430 (class 1259 OID 77391)
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
-- TOC entry 4429 (class 0 OID 0)
-- Dependencies: 430
-- Name: cost_layer_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE cost_layer_id_seq OWNED BY cost_layer.id;


--
-- TOC entry 400 (class 1259 OID 73689)
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
-- TOC entry 399 (class 1259 OID 73687)
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
-- TOC entry 4430 (class 0 OID 0)
-- Dependencies: 399
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


--
-- TOC entry 361 (class 1259 OID 68367)
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
-- TOC entry 362 (class 1259 OID 68376)
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
-- TOC entry 4431 (class 0 OID 0)
-- Dependencies: 362
-- Name: formas_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE formas_pago_id_seq OWNED BY formas_pago.id;


--
-- TOC entry 425 (class 1259 OID 77319)
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
    CONSTRAINT historial_costos_item_algoritmo_principal_check CHECK (((algoritmo_principal)::text = ANY ((ARRAY['WAC'::character varying, 'PEPS'::character varying, 'UEPS'::character varying, 'ESTANDAR'::character varying])::text[]))),
    CONSTRAINT historial_costos_item_fuente_datos_check CHECK (((fuente_datos)::text = ANY ((ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying, 'IMPORTACION'::character varying])::text[]))),
    CONSTRAINT historial_costos_item_tipo_cambio_check CHECK (((tipo_cambio)::text = ANY ((ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying])::text[])))
);


ALTER TABLE historial_costos_item OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 77317)
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
-- TOC entry 4432 (class 0 OID 0)
-- Dependencies: 424
-- Name: historial_costos_item_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_item_id_seq OWNED BY historial_costos_item.id;


--
-- TOC entry 427 (class 1259 OID 77351)
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
-- TOC entry 426 (class 1259 OID 77349)
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
-- TOC entry 4433 (class 0 OID 0)
-- Dependencies: 426
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE historial_costos_receta_id_seq OWNED BY historial_costos_receta.id;


--
-- TOC entry 406 (class 1259 OID 77073)
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
    CONSTRAINT inventory_batch_cantidad_actual_check CHECK ((cantidad_actual >= (0)::numeric)),
    CONSTRAINT inventory_batch_cantidad_original_check CHECK ((cantidad_original > (0)::numeric)),
    CONSTRAINT inventory_batch_check CHECK ((cantidad_actual <= cantidad_original)),
    CONSTRAINT inventory_batch_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'BLOQUEADO'::character varying, 'RECALL'::character varying])::text[]))),
    CONSTRAINT inventory_batch_lote_proveedor_check CHECK (((length((lote_proveedor)::text) >= 1) AND (length((lote_proveedor)::text) <= 50))),
    CONSTRAINT inventory_batch_temperatura_recepcion_check CHECK (((temperatura_recepcion >= ('-30'::integer)::numeric) AND (temperatura_recepcion <= (60)::numeric))),
    CONSTRAINT inventory_batch_ubicacion_id_check CHECK (((ubicacion_id)::text ~~ 'UBIC-%'::text))
);


ALTER TABLE inventory_batch OWNER TO postgres;

--
-- TOC entry 4434 (class 0 OID 0)
-- Dependencies: 406
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario con trazabilidad completa';


--
-- TOC entry 405 (class 1259 OID 77071)
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
-- TOC entry 4435 (class 0 OID 0)
-- Dependencies: 405
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


--
-- TOC entry 439 (class 1259 OID 77489)
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
    CONSTRAINT item_vendor_factor_a_canonica_check CHECK ((factor_a_canonica > (0)::numeric))
);


ALTER TABLE item_vendor OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 77052)
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
    CONSTRAINT items_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric)),
    CONSTRAINT items_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_unidad_medida_check CHECK (((unidad_medida)::text = ANY ((ARRAY['KG'::character varying, 'LT'::character varying, 'PZ'::character varying, 'BULTO'::character varying, 'CAJA'::character varying])::text[])))
);


ALTER TABLE items OWNER TO postgres;

--
-- TOC entry 4436 (class 0 OID 0)
-- Dependencies: 404
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'Maestro de todos los ítems del sistema';


--
-- TOC entry 398 (class 1259 OID 73679)
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
-- TOC entry 436 (class 1259 OID 77460)
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
-- TOC entry 435 (class 1259 OID 77458)
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
-- TOC entry 4437 (class 0 OID 0)
-- Dependencies: 435
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE job_recalc_queue_id_seq OWNED BY job_recalc_queue.id;


--
-- TOC entry 397 (class 1259 OID 73669)
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
-- TOC entry 396 (class 1259 OID 73667)
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
-- TOC entry 4438 (class 0 OID 0)
-- Dependencies: 396
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- TOC entry 391 (class 1259 OID 73614)
-- Name: migrations; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE migrations OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 73612)
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
-- TOC entry 4439 (class 0 OID 0)
-- Dependencies: 390
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE migrations_id_seq OWNED BY migrations.id;


--
-- TOC entry 459 (class 1259 OID 77739)
-- Name: model_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_permissions OWNER TO postgres;

--
-- TOC entry 460 (class 1259 OID 77750)
-- Name: model_has_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id bigint NOT NULL
);


ALTER TABLE model_has_roles OWNER TO postgres;

--
-- TOC entry 434 (class 1259 OID 77424)
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
    CONSTRAINT modificadores_pos_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['AGREGADO'::character varying, 'SUSTITUCION'::character varying, 'ELIMINACION'::character varying])::text[])))
);


ALTER TABLE modificadores_pos OWNER TO postgres;

--
-- TOC entry 433 (class 1259 OID 77422)
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
-- TOC entry 4440 (class 0 OID 0)
-- Dependencies: 433
-- Name: modificadores_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE modificadores_pos_id_seq OWNED BY modificadores_pos.id;


--
-- TOC entry 408 (class 1259 OID 77097)
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
    CONSTRAINT mov_inv_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SALIDA'::character varying, 'AJUSTE'::character varying, 'MERMA'::character varying, 'TRASPASO'::character varying])::text[])))
);


ALTER TABLE mov_inv OWNER TO postgres;

--
-- TOC entry 4441 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE mov_inv; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE mov_inv IS 'Kardex completo de movimientos de inventario';


--
-- TOC entry 407 (class 1259 OID 77095)
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
-- TOC entry 4442 (class 0 OID 0)
-- Dependencies: 407
-- Name: mov_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE mov_inv_id_seq OWNED BY mov_inv.id;


--
-- TOC entry 415 (class 1259 OID 77194)
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
    CONSTRAINT op_produccion_cab_estado_check CHECK (((estado)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying, 'COMPLETADA'::character varying, 'CANCELADA'::character varying])::text[])))
);


ALTER TABLE op_produccion_cab OWNER TO postgres;

--
-- TOC entry 4443 (class 0 OID 0)
-- Dependencies: 415
-- Name: TABLE op_produccion_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE op_produccion_cab IS 'Órdenes de producción para elaborados';


--
-- TOC entry 414 (class 1259 OID 77192)
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
-- TOC entry 4444 (class 0 OID 0)
-- Dependencies: 414
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE op_produccion_cab_id_seq OWNED BY op_produccion_cab.id;


--
-- TOC entry 441 (class 1259 OID 77531)
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
-- TOC entry 440 (class 1259 OID 77529)
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
-- TOC entry 4445 (class 0 OID 0)
-- Dependencies: 440
-- Name: param_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE param_sucursal_id_seq OWNED BY param_sucursal.id;


--
-- TOC entry 392 (class 1259 OID 73633)
-- Name: password_reset_tokens; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE password_reset_tokens OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 77589)
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
-- TOC entry 446 (class 1259 OID 77587)
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
-- TOC entry 4446 (class 0 OID 0)
-- Dependencies: 446
-- Name: perdida_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE perdida_log_id_seq OWNED BY perdida_log.id;


--
-- TOC entry 456 (class 1259 OID 77715)
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
-- TOC entry 455 (class 1259 OID 77713)
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
-- TOC entry 4447 (class 0 OID 0)
-- Dependencies: 455
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- TOC entry 432 (class 1259 OID 77412)
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
    CONSTRAINT pos_map_tipo_check CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text])))
);


ALTER TABLE pos_map OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 68378)
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
-- TOC entry 4448 (class 0 OID 0)
-- Dependencies: 363
-- Name: COLUMN postcorte.validado; Type: COMMENT; Schema: selemti; Owner: floreant
--

COMMENT ON COLUMN postcorte.validado IS 'TRUE cuando el supervisor valida/cierra el postcorte';


--
-- TOC entry 364 (class 1259 OID 68401)
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
-- TOC entry 4449 (class 0 OID 0)
-- Dependencies: 364
-- Name: postcorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE postcorte_id_seq OWNED BY postcorte.id;


--
-- TOC entry 365 (class 1259 OID 68403)
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
-- TOC entry 366 (class 1259 OID 68414)
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
-- TOC entry 367 (class 1259 OID 68418)
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
-- TOC entry 4450 (class 0 OID 0)
-- Dependencies: 367
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_efectivo_id_seq OWNED BY precorte_efectivo.id;


--
-- TOC entry 368 (class 1259 OID 68420)
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
-- TOC entry 4451 (class 0 OID 0)
-- Dependencies: 368
-- Name: precorte_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_id_seq OWNED BY precorte.id;


--
-- TOC entry 369 (class 1259 OID 68422)
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
-- TOC entry 370 (class 1259 OID 68430)
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
-- TOC entry 4452 (class 0 OID 0)
-- Dependencies: 370
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_otros_id_seq OWNED BY precorte_otros.id;


--
-- TOC entry 465 (class 1259 OID 77984)
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
-- TOC entry 438 (class 1259 OID 77475)
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
-- TOC entry 437 (class 1259 OID 77473)
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
-- TOC entry 4453 (class 0 OID 0)
-- Dependencies: 437
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


--
-- TOC entry 409 (class 1259 OID 77122)
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
-- TOC entry 4454 (class 0 OID 0)
-- Dependencies: 409
-- Name: TABLE receta_cab; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_cab IS 'Cabecera de recetas y platos del menú';


--
-- TOC entry 413 (class 1259 OID 77168)
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
-- TOC entry 4455 (class 0 OID 0)
-- Dependencies: 413
-- Name: TABLE receta_det; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_det IS 'Detalle de ingredientes por versión de receta';


--
-- TOC entry 412 (class 1259 OID 77166)
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
-- TOC entry 4456 (class 0 OID 0)
-- Dependencies: 412
-- Name: receta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_det_id_seq OWNED BY receta_det.id;


--
-- TOC entry 429 (class 1259 OID 77370)
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
    CONSTRAINT receta_shadow_estado_check CHECK (((estado)::text = ANY ((ARRAY['INFERIDA'::character varying, 'VALIDADA'::character varying, 'DESCARTADA'::character varying])::text[])))
);


ALTER TABLE receta_shadow OWNER TO postgres;

--
-- TOC entry 428 (class 1259 OID 77368)
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
-- TOC entry 4457 (class 0 OID 0)
-- Dependencies: 428
-- Name: receta_shadow_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_shadow_id_seq OWNED BY receta_shadow.id;


--
-- TOC entry 411 (class 1259 OID 77142)
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
-- TOC entry 4458 (class 0 OID 0)
-- Dependencies: 411
-- Name: TABLE receta_version; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE receta_version IS 'Control de versiones de recetas';


--
-- TOC entry 410 (class 1259 OID 77140)
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
-- TOC entry 4459 (class 0 OID 0)
-- Dependencies: 410
-- Name: receta_version_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE receta_version_id_seq OWNED BY receta_version.id;


--
-- TOC entry 461 (class 1259 OID 77761)
-- Name: role_has_permissions; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE role_has_permissions OWNER TO postgres;

--
-- TOC entry 458 (class 1259 OID 77728)
-- Name: roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE roles OWNER TO postgres;

--
-- TOC entry 457 (class 1259 OID 77726)
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
-- TOC entry 4460 (class 0 OID 0)
-- Dependencies: 457
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- TOC entry 371 (class 1259 OID 68432)
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
-- TOC entry 372 (class 1259 OID 68443)
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
-- TOC entry 4461 (class 0 OID 0)
-- Dependencies: 372
-- Name: sesion_cajon_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE sesion_cajon_id_seq OWNED BY sesion_cajon.id;


--
-- TOC entry 393 (class 1259 OID 73641)
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
-- TOC entry 443 (class 1259 OID 77549)
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
-- TOC entry 442 (class 1259 OID 77547)
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
-- TOC entry 4462 (class 0 OID 0)
-- Dependencies: 442
-- Name: stock_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE stock_policy_id_seq OWNED BY stock_policy.id;


--
-- TOC entry 463 (class 1259 OID 77961)
-- Name: sucursal; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE sucursal (
    id text NOT NULL,
    nombre text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE sucursal OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 77570)
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
-- TOC entry 444 (class 1259 OID 77568)
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
-- TOC entry 4463 (class 0 OID 0)
-- Dependencies: 444
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE sucursal_almacen_terminal_id_seq OWNED BY sucursal_almacen_terminal.id;


--
-- TOC entry 449 (class 1259 OID 77623)
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
-- TOC entry 448 (class 1259 OID 77621)
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
-- TOC entry 4464 (class 0 OID 0)
-- Dependencies: 448
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


--
-- TOC entry 417 (class 1259 OID 77217)
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
    CONSTRAINT ticket_venta_cab_estado_check CHECK (((estado)::text = ANY ((ARRAY['ABIERTO'::character varying, 'CERRADO'::character varying, 'ANULADO'::character varying])::text[])))
);


ALTER TABLE ticket_venta_cab OWNER TO postgres;

--
-- TOC entry 416 (class 1259 OID 77215)
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
-- TOC entry 4465 (class 0 OID 0)
-- Dependencies: 416
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_cab_id_seq OWNED BY ticket_venta_cab.id;


--
-- TOC entry 419 (class 1259 OID 77232)
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
-- TOC entry 418 (class 1259 OID 77230)
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
-- TOC entry 4466 (class 0 OID 0)
-- Dependencies: 418
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


--
-- TOC entry 421 (class 1259 OID 77247)
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
    CONSTRAINT unidades_medida_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['METRICO'::character varying, 'IMPERIAL'::character varying, 'CULINARIO'::character varying])::text[]))),
    CONSTRAINT unidades_medida_codigo_check CHECK (((codigo)::text ~ '^[A-Z]{2,5}$'::text)),
    CONSTRAINT unidades_medida_decimales_check CHECK (((decimales >= 0) AND (decimales <= 6))),
    CONSTRAINT unidades_medida_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['PESO'::character varying, 'VOLUMEN'::character varying, 'UNIDAD'::character varying, 'TIEMPO'::character varying])::text[])))
);


ALTER TABLE unidades_medida OWNER TO postgres;

--
-- TOC entry 420 (class 1259 OID 77245)
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
-- TOC entry 4467 (class 0 OID 0)
-- Dependencies: 420
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida.id;


--
-- TOC entry 403 (class 1259 OID 77035)
-- Name: user_roles; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE user_roles (
    user_id integer NOT NULL,
    role_id character varying(20) NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer,
    CONSTRAINT user_roles_role_id_check CHECK (((role_id)::text = ANY ((ARRAY['GERENTE'::character varying, 'CHEF'::character varying, 'ALMACEN'::character varying, 'CAJERO'::character varying, 'AUDITOR'::character varying, 'SISTEMA'::character varying])::text[])))
);


ALTER TABLE user_roles OWNER TO postgres;

--
-- TOC entry 4468 (class 0 OID 0)
-- Dependencies: 403
-- Name: TABLE user_roles; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE user_roles IS 'Asignación de roles a usuarios (RBAC)';


--
-- TOC entry 454 (class 1259 OID 77685)
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
    CONSTRAINT users_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT users_intentos_login_check CHECK ((intentos_login >= 0)),
    CONSTRAINT users_password_hash_check CHECK ((length((password_hash)::text) = 60)),
    CONSTRAINT users_sucursal_id_check CHECK (((sucursal_id)::text = ANY ((ARRAY['SUR'::character varying, 'NORTE'::character varying, 'CENTRO'::character varying])::text[]))),
    CONSTRAINT users_username_check CHECK ((length((username)::text) >= 3))
);


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 4469 (class 0 OID 0)
-- Dependencies: 454
-- Name: TABLE users; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE users IS 'Usuarios del sistema con sus credenciales y estado';


--
-- TOC entry 453 (class 1259 OID 77683)
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
-- TOC entry 4470 (class 0 OID 0)
-- Dependencies: 453
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 451 (class 1259 OID 77670)
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
-- TOC entry 462 (class 1259 OID 77951)
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
-- TOC entry 452 (class 1259 OID 77675)
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
-- TOC entry 450 (class 1259 OID 77665)
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
-- TOC entry 466 (class 1259 OID 77993)
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
                    WHEN ((mov_inv.tipo)::text = ANY ((ARRAY['SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying, 'TRASPASO'::character varying])::text[])) THEN (- mov_inv.cantidad)
                    ELSE (0)::numeric
                END) AS stock_actual
           FROM mov_inv
          GROUP BY mov_inv.item_id) sa ON (((sa.item_id)::text = sp.item_id)));


ALTER TABLE v_stock_brechas OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 69489)
-- Name: vw_anulaciones_por_terminal_dia; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_anulaciones_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tx.transaction_time) AS fecha,
    (sum(
        CASE
            WHEN ((tx.payment_type)::text = ANY ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[])) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS anulaciones_total
   FROM (public.transactions tx
     JOIN public.ticket tk ON ((tk.id = tx.ticket_id)))
  GROUP BY tk.terminal_id, (date(tx.transaction_time));


ALTER TABLE vw_anulaciones_por_terminal_dia OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 68455)
-- Name: vw_sesion_reembolsos_efectivo; Type: VIEW; Schema: selemti; Owner: floreant
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


ALTER TABLE vw_sesion_reembolsos_efectivo OWNER TO floreant;

--
-- TOC entry 376 (class 1259 OID 68460)
-- Name: vw_sesion_retiros; Type: VIEW; Schema: selemti; Owner: floreant
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


ALTER TABLE vw_sesion_retiros OWNER TO floreant;

--
-- TOC entry 377 (class 1259 OID 68465)
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
-- TOC entry 386 (class 1259 OID 69504)
-- Name: vw_conciliacion_efectivo; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_conciliacion_efectivo AS
 WITH c AS (
         SELECT s.id AS sesion_id,
            s.opening_float,
            (sum(
                CASE
                    WHEN (v.codigo_fp = 'CASH'::text) THEN v.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_cash
           FROM (sesion_cajon s
             LEFT JOIN vw_sesion_ventas v ON ((v.sesion_id = s.id)))
          GROUP BY s.id, s.opening_float
        ), r AS (
         SELECT vw_sesion_retiros.sesion_id,
            vw_sesion_retiros.retiros
           FROM vw_sesion_retiros
        ), re AS (
         SELECT vw_sesion_reembolsos_efectivo.sesion_id,
            vw_sesion_reembolsos_efectivo.reembolsos_efectivo
           FROM vw_sesion_reembolsos_efectivo
        ), dc AS (
         SELECT p.sesion_id,
            (sum(pe.subtotal))::numeric(12,2) AS declarado_efectivo
           FROM (precorte p
             LEFT JOIN precorte_efectivo pe ON ((pe.precorte_id = p.id)))
          GROUP BY p.sesion_id
        )
 SELECT c.sesion_id,
    c.opening_float,
    c.sys_cash AS cash_in,
    (COALESCE(r.retiros, (0)::numeric))::numeric(12,2) AS cash_out,
    (COALESCE(re.reembolsos_efectivo, (0)::numeric))::numeric(12,2) AS cash_refund,
    ((((c.opening_float + c.sys_cash) - COALESCE(r.retiros, (0)::numeric)) - COALESCE(re.reembolsos_efectivo, (0)::numeric)))::numeric(12,2) AS sistema_efectivo_esperado,
    (COALESCE(dc.declarado_efectivo, (0)::numeric))::numeric(12,2) AS declarado_efectivo,
    ((COALESCE(dc.declarado_efectivo, (0)::numeric) - (((c.opening_float + c.sys_cash) - COALESCE(r.retiros, (0)::numeric)) - COALESCE(re.reembolsos_efectivo, (0)::numeric))))::numeric(12,2) AS diferencia_efectivo
   FROM (((c
     LEFT JOIN r USING (sesion_id))
     LEFT JOIN re USING (sesion_id))
     LEFT JOIN dc USING (sesion_id));


ALTER TABLE vw_conciliacion_efectivo OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 68445)
-- Name: vw_sesion_descuentos; Type: VIEW; Schema: selemti; Owner: floreant
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


ALTER TABLE vw_sesion_descuentos OWNER TO floreant;

--
-- TOC entry 374 (class 1259 OID 68450)
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
-- TOC entry 378 (class 1259 OID 68470)
-- Name: vw_conciliacion_sesion; Type: VIEW; Schema: selemti; Owner: floreant
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
                    WHEN (po.tipo = ANY (ARRAY['CREDITO'::text, 'CREDIT'::text, 'CREDIT_CARD'::text])) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_credito,
            (sum(
                CASE
                    WHEN (po.tipo = ANY (ARRAY['DEBITO'::text, 'DEBIT'::text, 'DEBIT_CARD'::text])) THEN po.monto
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
         SELECT sys1.sesion_id,
            sys1.opening_float,
            (COALESCE(sys1.sys_cash, (0)::numeric))::numeric(12,2) AS cash_in,
            (COALESCE(re.retiros, (0)::numeric))::numeric(12,2) AS cash_out,
            (COALESCE(cr.reembolsos_efectivo, (0)::numeric))::numeric(12,2) AS cash_refund,
            ((((sys1.opening_float + COALESCE(sys1.sys_cash, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(cr.reembolsos_efectivo, (0)::numeric)))::numeric(12,2) AS sistema_efectivo_esperado
           FROM ((sys sys1
             LEFT JOIN re ON ((re.sesion_id = sys1.sesion_id)))
             LEFT JOIN cr ON ((cr.sesion_id = sys1.sesion_id)))
        ), tc AS (
         SELECT sys1.sesion_id,
            (((((COALESCE(sys1.sys_credito, (0)::numeric) + COALESCE(sys1.sys_debito, (0)::numeric)) + COALESCE(sys1.sys_transfer, (0)::numeric)) + COALESCE(sys1.sys_custom, (0)::numeric)) + COALESCE(sys1.sys_gift, (0)::numeric)))::numeric(12,2) AS sistema_no_efectivo
           FROM sys sys1
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
    dpr.report_time,
    sys.sys_cash,
    tc.sistema_no_efectivo AS sys_total_tarjetas,
    (((((COALESCE(dotros.decl_credito, (0)::numeric) + COALESCE(dotros.decl_debito, (0)::numeric)) + COALESCE(dotros.decl_transfer, (0)::numeric)) + COALESCE(dotros.decl_custom, (0)::numeric)) + COALESCE(dotros.decl_gift, (0)::numeric)))::numeric(12,2) AS decl_total_tarjetas,
    ((((((COALESCE(dotros.decl_credito, (0)::numeric) + COALESCE(dotros.decl_debito, (0)::numeric)) + COALESCE(dotros.decl_transfer, (0)::numeric)) + COALESCE(dotros.decl_custom, (0)::numeric)) + COALESCE(dotros.decl_gift, (0)::numeric)) - COALESCE(tc.sistema_no_efectivo, (0)::numeric)))::numeric(12,2) AS diferencia_tarjetas
   FROM ((((((sys
     LEFT JOIN eff ON ((eff.sesion_id = sys.sesion_id)))
     LEFT JOIN decl_cash dc ON ((dc.sesion_id = sys.sesion_id)))
     LEFT JOIN decl_otros dotros ON ((dotros.sesion_id = sys.sesion_id)))
     LEFT JOIN tc ON ((tc.sesion_id = sys.sesion_id)))
     LEFT JOIN ds ON ((ds.sesion_id = sys.sesion_id)))
     LEFT JOIN vw_sesion_dpr dpr ON ((dpr.sesion_id = sys.sesion_id)))
  ORDER BY sys.sesion_id DESC;


ALTER TABLE vw_conciliacion_sesion OWNER TO floreant;

--
-- TOC entry 385 (class 1259 OID 69499)
-- Name: vw_conciliacion_tarjetas; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_conciliacion_tarjetas AS
 WITH s AS (
         SELECT vw_sesion_ventas.sesion_id,
            (sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = ANY (ARRAY['CREDIT'::text, 'CREDIT_CARD'::text])) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_credito,
            (sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = ANY (ARRAY['DEBIT'::text, 'DEBIT_CARD'::text])) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_debito,
            (sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = 'TRANSFER'::text) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_transfer,
            (sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp ~~ 'CUSTOM:%'::text) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_custom,
            (sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = 'GIFT_CERT'::text) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS sys_gift
           FROM vw_sesion_ventas
          GROUP BY vw_sesion_ventas.sesion_id
        ), d AS (
         SELECT p.sesion_id,
            (sum(
                CASE
                    WHEN (po.tipo = ANY (ARRAY['CREDITO'::text, 'CREDIT'::text, 'CREDIT_CARD'::text])) THEN po.monto
                    ELSE (0)::numeric
                END))::numeric(12,2) AS decl_credito,
            (sum(
                CASE
                    WHEN (po.tipo = ANY (ARRAY['DEBITO'::text, 'DEBIT'::text, 'DEBIT_CARD'::text])) THEN po.monto
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
        )
 SELECT s.sesion_id,
    s.sys_credito,
    s.sys_debito,
    s.sys_transfer,
    s.sys_custom,
    s.sys_gift,
    (((((COALESCE(s.sys_credito, (0)::numeric) + COALESCE(s.sys_debito, (0)::numeric)) + COALESCE(s.sys_transfer, (0)::numeric)) + COALESCE(s.sys_custom, (0)::numeric)) + COALESCE(s.sys_gift, (0)::numeric)))::numeric(12,2) AS sys_total_tarjetas,
    d.decl_credito,
    d.decl_debito,
    d.decl_transfer,
    d.decl_custom,
    d.decl_gift,
    (((((COALESCE(d.decl_credito, (0)::numeric) + COALESCE(d.decl_debito, (0)::numeric)) + COALESCE(d.decl_transfer, (0)::numeric)) + COALESCE(d.decl_custom, (0)::numeric)) + COALESCE(d.decl_gift, (0)::numeric)))::numeric(12,2) AS decl_total_tarjetas,
    ((((((COALESCE(d.decl_credito, (0)::numeric) + COALESCE(d.decl_debito, (0)::numeric)) + COALESCE(d.decl_transfer, (0)::numeric)) + COALESCE(d.decl_custom, (0)::numeric)) + COALESCE(d.decl_gift, (0)::numeric)) - ((((COALESCE(s.sys_credito, (0)::numeric) + COALESCE(s.sys_debito, (0)::numeric)) + COALESCE(s.sys_transfer, (0)::numeric)) + COALESCE(s.sys_custom, (0)::numeric)) + COALESCE(s.sys_gift, (0)::numeric))))::numeric(12,2) AS diferencia_tarjetas
   FROM (s
     LEFT JOIN d USING (sesion_id));


ALTER TABLE vw_conciliacion_tarjetas OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 69484)
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
-- TOC entry 379 (class 1259 OID 68475)
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
-- TOC entry 380 (class 1259 OID 68479)
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
-- TOC entry 384 (class 1259 OID 69494)
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
            WHEN (((tx.payment_type)::text = ANY ((ARRAY['CREDIT_CARD'::character varying, 'DEBIT_CARD'::character varying])::text[])) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
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
-- TOC entry 387 (class 1259 OID 69523)
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

SET search_path = public, pg_catalog;

--
-- TOC entry 2997 (class 2604 OID 68483)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history ALTER COLUMN id SET DEFAULT nextval('action_history_id_seq'::regclass);


--
-- TOC entry 2998 (class 2604 OID 68484)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history ALTER COLUMN id SET DEFAULT nextval('attendence_history_id_seq'::regclass);


--
-- TOC entry 2999 (class 2604 OID 68485)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer ALTER COLUMN id SET DEFAULT nextval('cash_drawer_id_seq'::regclass);


--
-- TOC entry 3000 (class 2604 OID 68486)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history ALTER COLUMN id SET DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass);


--
-- TOC entry 3001 (class 2604 OID 68487)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction ALTER COLUMN id SET DEFAULT nextval('cooking_instruction_id_seq'::regclass);


--
-- TOC entry 3002 (class 2604 OID 68488)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount ALTER COLUMN id SET DEFAULT nextval('coupon_and_discount_id_seq'::regclass);


--
-- TOC entry 3003 (class 2604 OID 68489)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency ALTER COLUMN id SET DEFAULT nextval('currency_id_seq'::regclass);


--
-- TOC entry 3004 (class 2604 OID 68490)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance ALTER COLUMN id SET DEFAULT nextval('currency_balance_id_seq'::regclass);


--
-- TOC entry 3005 (class 2604 OID 68491)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment ALTER COLUMN id SET DEFAULT nextval('custom_payment_id_seq'::regclass);


--
-- TOC entry 3006 (class 2604 OID 68492)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer ALTER COLUMN auto_id SET DEFAULT nextval('customer_auto_id_seq'::regclass);


--
-- TOC entry 3008 (class 2604 OID 68493)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info ALTER COLUMN id SET DEFAULT nextval('data_update_info_id_seq'::regclass);


--
-- TOC entry 3009 (class 2604 OID 68494)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address ALTER COLUMN id SET DEFAULT nextval('delivery_address_id_seq'::regclass);


--
-- TOC entry 3010 (class 2604 OID 68495)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge ALTER COLUMN id SET DEFAULT nextval('delivery_charge_id_seq'::regclass);


--
-- TOC entry 3011 (class 2604 OID 68496)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration ALTER COLUMN id SET DEFAULT nextval('delivery_configuration_id_seq'::regclass);


--
-- TOC entry 3012 (class 2604 OID 68497)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction ALTER COLUMN id SET DEFAULT nextval('delivery_instruction_id_seq'::regclass);


--
-- TOC entry 3013 (class 2604 OID 68498)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history ALTER COLUMN id SET DEFAULT nextval('drawer_assigned_history_id_seq'::regclass);


--
-- TOC entry 3014 (class 2604 OID 68499)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report ALTER COLUMN id SET DEFAULT nextval('drawer_pull_report_id_seq'::regclass);


--
-- TOC entry 3015 (class 2604 OID 68500)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history ALTER COLUMN id SET DEFAULT nextval('employee_in_out_history_id_seq'::regclass);


--
-- TOC entry 3016 (class 2604 OID 68501)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config ALTER COLUMN id SET DEFAULT nextval('global_config_id_seq'::regclass);


--
-- TOC entry 3017 (class 2604 OID 68502)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity ALTER COLUMN id SET DEFAULT nextval('gratuity_id_seq'::regclass);


--
-- TOC entry 3018 (class 2604 OID 68503)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print ALTER COLUMN id SET DEFAULT nextval('guest_check_print_id_seq'::regclass);


--
-- TOC entry 3019 (class 2604 OID 68504)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group ALTER COLUMN id SET DEFAULT nextval('inventory_group_id_seq'::regclass);


--
-- TOC entry 3020 (class 2604 OID 68505)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item ALTER COLUMN id SET DEFAULT nextval('inventory_item_id_seq'::regclass);


--
-- TOC entry 3021 (class 2604 OID 68506)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location ALTER COLUMN id SET DEFAULT nextval('inventory_location_id_seq'::regclass);


--
-- TOC entry 3022 (class 2604 OID 68507)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code ALTER COLUMN id SET DEFAULT nextval('inventory_meta_code_id_seq'::regclass);


--
-- TOC entry 3023 (class 2604 OID 68508)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction ALTER COLUMN id SET DEFAULT nextval('inventory_transaction_id_seq'::regclass);


--
-- TOC entry 3024 (class 2604 OID 68509)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit ALTER COLUMN id SET DEFAULT nextval('inventory_unit_id_seq'::regclass);


--
-- TOC entry 3025 (class 2604 OID 68510)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor ALTER COLUMN id SET DEFAULT nextval('inventory_vendor_id_seq'::regclass);


--
-- TOC entry 3026 (class 2604 OID 68511)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse ALTER COLUMN id SET DEFAULT nextval('inventory_warehouse_id_seq'::regclass);


--
-- TOC entry 3027 (class 2604 OID 68512)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_id_seq'::regclass);


--
-- TOC entry 3031 (class 2604 OID 68513)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item ALTER COLUMN id SET DEFAULT nextval('kitchen_ticket_item_id_seq'::regclass);


--
-- TOC entry 3032 (class 2604 OID 68514)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category ALTER COLUMN id SET DEFAULT nextval('menu_category_id_seq'::regclass);


--
-- TOC entry 3033 (class 2604 OID 68515)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group ALTER COLUMN id SET DEFAULT nextval('menu_group_id_seq'::regclass);


--
-- TOC entry 3034 (class 2604 OID 68516)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item ALTER COLUMN id SET DEFAULT nextval('menu_item_id_seq'::regclass);


--
-- TOC entry 3035 (class 2604 OID 68517)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size ALTER COLUMN id SET DEFAULT nextval('menu_item_size_id_seq'::regclass);


--
-- TOC entry 3036 (class 2604 OID 68518)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier ALTER COLUMN id SET DEFAULT nextval('menu_modifier_id_seq'::regclass);


--
-- TOC entry 3037 (class 2604 OID 68519)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group ALTER COLUMN id SET DEFAULT nextval('menu_modifier_group_id_seq'::regclass);


--
-- TOC entry 3038 (class 2604 OID 68520)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup ALTER COLUMN id SET DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass);


--
-- TOC entry 3039 (class 2604 OID 68521)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift ALTER COLUMN id SET DEFAULT nextval('menuitem_shift_id_seq'::regclass);


--
-- TOC entry 3110 (class 2604 OID 73605)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 3040 (class 2604 OID 68522)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price ALTER COLUMN id SET DEFAULT nextval('modifier_multiplier_price_id_seq'::regclass);


--
-- TOC entry 3041 (class 2604 OID 68523)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type ALTER COLUMN id SET DEFAULT nextval('order_type_id_seq'::regclass);


--
-- TOC entry 3042 (class 2604 OID 68524)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit ALTER COLUMN id SET DEFAULT nextval('packaging_unit_id_seq'::regclass);


--
-- TOC entry 3043 (class 2604 OID 68525)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons ALTER COLUMN id SET DEFAULT nextval('payout_reasons_id_seq'::regclass);


--
-- TOC entry 3044 (class 2604 OID 68526)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients ALTER COLUMN id SET DEFAULT nextval('payout_recepients_id_seq'::regclass);


--
-- TOC entry 3045 (class 2604 OID 68527)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust ALTER COLUMN id SET DEFAULT nextval('pizza_crust_id_seq'::regclass);


--
-- TOC entry 3046 (class 2604 OID 68528)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price ALTER COLUMN id SET DEFAULT nextval('pizza_modifier_price_id_seq'::regclass);


--
-- TOC entry 3047 (class 2604 OID 68529)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price ALTER COLUMN id SET DEFAULT nextval('pizza_price_id_seq'::regclass);


--
-- TOC entry 3048 (class 2604 OID 68530)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group ALTER COLUMN id SET DEFAULT nextval('printer_group_id_seq'::regclass);


--
-- TOC entry 3049 (class 2604 OID 68531)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order ALTER COLUMN id SET DEFAULT nextval('purchase_order_id_seq'::regclass);


--
-- TOC entry 3050 (class 2604 OID 68532)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie ALTER COLUMN id SET DEFAULT nextval('recepie_id_seq'::regclass);


--
-- TOC entry 3051 (class 2604 OID 68533)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item ALTER COLUMN id SET DEFAULT nextval('recepie_item_id_seq'::regclass);


--
-- TOC entry 3052 (class 2604 OID 68534)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift ALTER COLUMN id SET DEFAULT nextval('shift_id_seq'::regclass);


--
-- TOC entry 3053 (class 2604 OID 68535)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor ALTER COLUMN id SET DEFAULT nextval('shop_floor_id_seq'::regclass);


--
-- TOC entry 3054 (class 2604 OID 68536)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template ALTER COLUMN id SET DEFAULT nextval('shop_floor_template_id_seq'::regclass);


--
-- TOC entry 3055 (class 2604 OID 68537)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type ALTER COLUMN id SET DEFAULT nextval('shop_table_type_id_seq'::regclass);


--
-- TOC entry 3056 (class 2604 OID 68538)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info ALTER COLUMN id SET DEFAULT nextval('table_booking_info_id_seq'::regclass);


--
-- TOC entry 3057 (class 2604 OID 68539)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax ALTER COLUMN id SET DEFAULT nextval('tax_id_seq'::regclass);


--
-- TOC entry 3058 (class 2604 OID 68540)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers ALTER COLUMN id SET DEFAULT nextval('terminal_printers_id_seq'::regclass);


--
-- TOC entry 3028 (class 2604 OID 68541)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket ALTER COLUMN id SET DEFAULT nextval('ticket_id_seq'::regclass);


--
-- TOC entry 3059 (class 2604 OID 68542)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount ALTER COLUMN id SET DEFAULT nextval('ticket_discount_id_seq'::regclass);


--
-- TOC entry 3060 (class 2604 OID 68543)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item ALTER COLUMN id SET DEFAULT nextval('ticket_item_id_seq'::regclass);


--
-- TOC entry 3061 (class 2604 OID 68544)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount ALTER COLUMN id SET DEFAULT nextval('ticket_item_discount_id_seq'::regclass);


--
-- TOC entry 3062 (class 2604 OID 68545)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifier_id_seq'::regclass);


--
-- TOC entry 3063 (class 2604 OID 68546)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- TOC entry 3064 (class 2604 OID 68547)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type ALTER COLUMN id SET DEFAULT nextval('user_type_id_seq'::regclass);


--
-- TOC entry 3065 (class 2604 OID 68548)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users ALTER COLUMN auto_id SET DEFAULT nextval('users_auto_id_seq'::regclass);


--
-- TOC entry 3066 (class 2604 OID 68549)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer ALTER COLUMN id SET DEFAULT nextval('virtual_printer_id_seq'::regclass);


--
-- TOC entry 3067 (class 2604 OID 68550)
-- Name: id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons ALTER COLUMN id SET DEFAULT nextval('void_reasons_id_seq'::regclass);


--
-- TOC entry 3068 (class 2604 OID 68551)
-- Name: auto_id; Type: DEFAULT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge ALTER COLUMN auto_id SET DEFAULT nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3069 (class 2604 OID 68552)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3115 (class 2604 OID 73707)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 3192 (class 2604 OID 77268)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3220 (class 2604 OID 77396)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3113 (class 2604 OID 73692)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3074 (class 2604 OID 68553)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3200 (class 2604 OID 77322)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3208 (class 2604 OID 77354)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3132 (class 2604 OID 77076)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 3227 (class 2604 OID 77463)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3112 (class 2604 OID 73672)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 3111 (class 2604 OID 73617)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 3223 (class 2604 OID 77427)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 3143 (class 2604 OID 77100)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 3166 (class 2604 OID 77197)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 3238 (class 2604 OID 77534)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 3252 (class 2604 OID 77592)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 3270 (class 2604 OID 77718)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 3089 (class 2604 OID 68554)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 3097 (class 2604 OID 68555)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 3099 (class 2604 OID 68556)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 3103 (class 2604 OID 68557)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 3232 (class 2604 OID 77478)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 3160 (class 2604 OID 77171)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 3212 (class 2604 OID 77373)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 3156 (class 2604 OID 77145)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 3271 (class 2604 OID 77731)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 3108 (class 2604 OID 68558)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 3244 (class 2604 OID 77552)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 3249 (class 2604 OID 77573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 3256 (class 2604 OID 77626)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 3172 (class 2604 OID 77220)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 3178 (class 2604 OID 77235)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 3183 (class 2604 OID 77250)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 3259 (class 2604 OID 77688)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- TOC entry 3276 (class 2606 OID 68562)
-- Name: action_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT action_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3278 (class 2606 OID 68564)
-- Name: attendence_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT attendence_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3280 (class 2606 OID 68566)
-- Name: cash_drawer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT cash_drawer_pkey PRIMARY KEY (id);


--
-- TOC entry 3282 (class 2606 OID 68568)
-- Name: cash_drawer_reset_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3284 (class 2606 OID 68570)
-- Name: cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cooking_instruction
    ADD CONSTRAINT cooking_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 3286 (class 2606 OID 68572)
-- Name: coupon_and_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 3288 (class 2606 OID 68574)
-- Name: coupon_and_discount_uuid_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY coupon_and_discount
    ADD CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid);


--
-- TOC entry 3292 (class 2606 OID 68576)
-- Name: currency_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT currency_balance_pkey PRIMARY KEY (id);


--
-- TOC entry 3290 (class 2606 OID 68578)
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- TOC entry 3294 (class 2606 OID 68580)
-- Name: custom_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY custom_payment
    ADD CONSTRAINT custom_payment_pkey PRIMARY KEY (id);


--
-- TOC entry 3296 (class 2606 OID 68582)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 3298 (class 2606 OID 68584)
-- Name: customer_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT customer_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3300 (class 2606 OID 68586)
-- Name: daily_folio_counter_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY daily_folio_counter
    ADD CONSTRAINT daily_folio_counter_pkey PRIMARY KEY (folio_date, branch_key);


--
-- TOC entry 3302 (class 2606 OID 68588)
-- Name: data_update_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY data_update_info
    ADD CONSTRAINT data_update_info_pkey PRIMARY KEY (id);


--
-- TOC entry 3304 (class 2606 OID 68590)
-- Name: delivery_address_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT delivery_address_pkey PRIMARY KEY (id);


--
-- TOC entry 3306 (class 2606 OID 68592)
-- Name: delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_charge
    ADD CONSTRAINT delivery_charge_pkey PRIMARY KEY (id);


--
-- TOC entry 3308 (class 2606 OID 68594)
-- Name: delivery_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_configuration
    ADD CONSTRAINT delivery_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 3310 (class 2606 OID 68596)
-- Name: delivery_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT delivery_instruction_pkey PRIMARY KEY (id);


--
-- TOC entry 3312 (class 2606 OID 68598)
-- Name: drawer_assigned_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3316 (class 2606 OID 68600)
-- Name: drawer_pull_report_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id);


--
-- TOC entry 3319 (class 2606 OID 68602)
-- Name: employee_in_out_history_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT employee_in_out_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3321 (class 2606 OID 68604)
-- Name: global_config_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (id);


--
-- TOC entry 3323 (class 2606 OID 68606)
-- Name: global_config_pos_key_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pos_key_key UNIQUE (pos_key);


--
-- TOC entry 3325 (class 2606 OID 68608)
-- Name: gratuity_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT gratuity_pkey PRIMARY KEY (id);


--
-- TOC entry 3327 (class 2606 OID 68610)
-- Name: guest_check_print_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT guest_check_print_pkey PRIMARY KEY (id);


--
-- TOC entry 3329 (class 2606 OID 68612)
-- Name: inventory_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_group
    ADD CONSTRAINT inventory_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3331 (class 2606 OID 68614)
-- Name: inventory_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT inventory_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3333 (class 2606 OID 68616)
-- Name: inventory_location_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT inventory_location_pkey PRIMARY KEY (id);


--
-- TOC entry 3335 (class 2606 OID 68618)
-- Name: inventory_meta_code_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_meta_code
    ADD CONSTRAINT inventory_meta_code_pkey PRIMARY KEY (id);


--
-- TOC entry 3337 (class 2606 OID 68620)
-- Name: inventory_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pkey PRIMARY KEY (id);


--
-- TOC entry 3339 (class 2606 OID 68622)
-- Name: inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 3341 (class 2606 OID 68624)
-- Name: inventory_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_vendor
    ADD CONSTRAINT inventory_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 3343 (class 2606 OID 68626)
-- Name: inventory_warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_warehouse
    ADD CONSTRAINT inventory_warehouse_pkey PRIMARY KEY (id);


--
-- TOC entry 3367 (class 2606 OID 68628)
-- Name: kds_ready_log_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kds_ready_log
    ADD CONSTRAINT kds_ready_log_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 3370 (class 2606 OID 68630)
-- Name: kitchen_ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT kitchen_ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3346 (class 2606 OID 68632)
-- Name: kitchen_ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT kitchen_ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 3373 (class 2606 OID 68634)
-- Name: menu_category_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_category
    ADD CONSTRAINT menu_category_pkey PRIMARY KEY (id);


--
-- TOC entry 3375 (class 2606 OID 68636)
-- Name: menu_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT menu_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3378 (class 2606 OID 68638)
-- Name: menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3380 (class 2606 OID 68640)
-- Name: menu_item_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT menu_item_properties_pkey PRIMARY KEY (menu_item_id, property_name);


--
-- TOC entry 3382 (class 2606 OID 68642)
-- Name: menu_item_size_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_size
    ADD CONSTRAINT menu_item_size_pkey PRIMARY KEY (id);


--
-- TOC entry 3387 (class 2606 OID 68644)
-- Name: menu_modifier_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_group
    ADD CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3384 (class 2606 OID 68646)
-- Name: menu_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT menu_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 3390 (class 2606 OID 68648)
-- Name: menu_modifier_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT menu_modifier_properties_pkey PRIMARY KEY (menu_modifier_id, property_name);


--
-- TOC entry 3392 (class 2606 OID 68650)
-- Name: menuitem_modifiergroup_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id);


--
-- TOC entry 3394 (class 2606 OID 68652)
-- Name: menuitem_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT menuitem_shift_pkey PRIMARY KEY (id);


--
-- TOC entry 3531 (class 2606 OID 73607)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3396 (class 2606 OID 68654)
-- Name: modifier_multiplier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT modifier_multiplier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3398 (class 2606 OID 68656)
-- Name: multiplier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY multiplier
    ADD CONSTRAINT multiplier_pkey PRIMARY KEY (name);


--
-- TOC entry 3400 (class 2606 OID 68658)
-- Name: order_type_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_name_key UNIQUE (name);


--
-- TOC entry 3402 (class 2606 OID 68660)
-- Name: order_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY order_type
    ADD CONSTRAINT order_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3404 (class 2606 OID 68662)
-- Name: packaging_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_name_key UNIQUE (name);


--
-- TOC entry 3406 (class 2606 OID 68664)
-- Name: packaging_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY packaging_unit
    ADD CONSTRAINT packaging_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 3408 (class 2606 OID 68666)
-- Name: payout_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_reasons
    ADD CONSTRAINT payout_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 3410 (class 2606 OID 68668)
-- Name: payout_recepients_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY payout_recepients
    ADD CONSTRAINT payout_recepients_pkey PRIMARY KEY (id);


--
-- TOC entry 3412 (class 2606 OID 68670)
-- Name: pizza_crust_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_crust
    ADD CONSTRAINT pizza_crust_pkey PRIMARY KEY (id);


--
-- TOC entry 3414 (class 2606 OID 68672)
-- Name: pizza_modifier_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT pizza_modifier_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3416 (class 2606 OID 68674)
-- Name: pizza_price_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT pizza_price_pkey PRIMARY KEY (id);


--
-- TOC entry 3418 (class 2606 OID 68676)
-- Name: printer_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_configuration
    ADD CONSTRAINT printer_configuration_pkey PRIMARY KEY (id);


--
-- TOC entry 3420 (class 2606 OID 68678)
-- Name: printer_group_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_name_key UNIQUE (name);


--
-- TOC entry 3422 (class 2606 OID 68680)
-- Name: printer_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group
    ADD CONSTRAINT printer_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3424 (class 2606 OID 68682)
-- Name: purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3428 (class 2606 OID 68684)
-- Name: recepie_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT recepie_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3426 (class 2606 OID 68686)
-- Name: recepie_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT recepie_pkey PRIMARY KEY (id);


--
-- TOC entry 3430 (class 2606 OID 68688)
-- Name: restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant
    ADD CONSTRAINT restaurant_pkey PRIMARY KEY (id);


--
-- TOC entry 3432 (class 2606 OID 68690)
-- Name: restaurant_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT restaurant_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3434 (class 2606 OID 68692)
-- Name: shift_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_name_key UNIQUE (name);


--
-- TOC entry 3436 (class 2606 OID 68694)
-- Name: shift_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (id);


--
-- TOC entry 3438 (class 2606 OID 68696)
-- Name: shop_floor_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor
    ADD CONSTRAINT shop_floor_pkey PRIMARY KEY (id);


--
-- TOC entry 3440 (class 2606 OID 68698)
-- Name: shop_floor_template_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT shop_floor_template_pkey PRIMARY KEY (id);


--
-- TOC entry 3442 (class 2606 OID 68700)
-- Name: shop_floor_template_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT shop_floor_template_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3444 (class 2606 OID 68702)
-- Name: shop_table_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT shop_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3446 (class 2606 OID 68704)
-- Name: shop_table_status_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_status
    ADD CONSTRAINT shop_table_status_pkey PRIMARY KEY (id);


--
-- TOC entry 3448 (class 2606 OID 68706)
-- Name: shop_table_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table_type
    ADD CONSTRAINT shop_table_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3451 (class 2606 OID 68708)
-- Name: table_booking_info_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT table_booking_info_pkey PRIMARY KEY (id);


--
-- TOC entry 3456 (class 2606 OID 68710)
-- Name: tax_group_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax_group
    ADD CONSTRAINT tax_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3454 (class 2606 OID 68712)
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 3348 (class 2606 OID 68714)
-- Name: terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 3458 (class 2606 OID 68716)
-- Name: terminal_printers_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT terminal_printers_pkey PRIMARY KEY (id);


--
-- TOC entry 3460 (class 2606 OID 68718)
-- Name: terminal_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT terminal_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3462 (class 2606 OID 68720)
-- Name: ticket_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT ticket_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 3356 (class 2606 OID 68722)
-- Name: ticket_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_global_id_key UNIQUE (global_id);


--
-- TOC entry 3467 (class 2606 OID 68724)
-- Name: ticket_item_addon_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT ticket_item_addon_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 3469 (class 2606 OID 68726)
-- Name: ticket_item_cooking_instruction_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT ticket_item_cooking_instruction_pkey PRIMARY KEY (ticket_item_id, item_order);


--
-- TOC entry 3471 (class 2606 OID 68728)
-- Name: ticket_item_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT ticket_item_discount_pkey PRIMARY KEY (id);


--
-- TOC entry 3473 (class 2606 OID 68730)
-- Name: ticket_item_modifier_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id);


--
-- TOC entry 3475 (class 2606 OID 68732)
-- Name: ticket_item_modifier_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order);


--
-- TOC entry 3465 (class 2606 OID 68734)
-- Name: ticket_item_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT ticket_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3358 (class 2606 OID 68736)
-- Name: ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 3477 (class 2606 OID 68738)
-- Name: ticket_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT ticket_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3479 (class 2606 OID 68740)
-- Name: transaction_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT transaction_properties_pkey PRIMARY KEY (id, property_name);


--
-- TOC entry 3483 (class 2606 OID 68742)
-- Name: transactions_global_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_global_id_key UNIQUE (global_id);


--
-- TOC entry 3485 (class 2606 OID 68744)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 3487 (class 2606 OID 68746)
-- Name: user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (name);


--
-- TOC entry 3489 (class 2606 OID 68748)
-- Name: user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3491 (class 2606 OID 68750)
-- Name: user_user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT user_user_permission_pkey PRIMARY KEY (permissionid, elt);


--
-- TOC entry 3493 (class 2606 OID 68752)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (auto_id);


--
-- TOC entry 3495 (class 2606 OID 68754)
-- Name: users_user_id_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_id_key UNIQUE (user_id);


--
-- TOC entry 3497 (class 2606 OID 68756)
-- Name: users_user_pass_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_pass_key UNIQUE (user_pass);


--
-- TOC entry 3499 (class 2606 OID 68758)
-- Name: virtual_printer_name_key; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_name_key UNIQUE (name);


--
-- TOC entry 3501 (class 2606 OID 68760)
-- Name: virtual_printer_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtual_printer
    ADD CONSTRAINT virtual_printer_pkey PRIMARY KEY (id);


--
-- TOC entry 3503 (class 2606 OID 68762)
-- Name: void_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY void_reasons
    ADD CONSTRAINT void_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 3505 (class 2606 OID 68764)
-- Name: zip_code_vs_delivery_charge_pkey; Type: CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY zip_code_vs_delivery_charge
    ADD CONSTRAINT zip_code_vs_delivery_charge_pkey PRIMARY KEY (auto_id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3661 (class 2606 OID 77978)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 3507 (class 2606 OID 68766)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 3543 (class 2606 OID 73666)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 3541 (class 2606 OID 73658)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 3554 (class 2606 OID 73709)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 3592 (class 2606 OID 77278)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 3594 (class 2606 OID 77280)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 3605 (class 2606 OID 77401)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 3550 (class 2606 OID 73698)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3552 (class 2606 OID 73700)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 3509 (class 2606 OID 68768)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 3596 (class 2606 OID 77338)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 3598 (class 2606 OID 77336)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3601 (class 2606 OID 77362)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3562 (class 2606 OID 77089)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 3618 (class 2606 OID 77501)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 3558 (class 2606 OID 77070)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 3548 (class 2606 OID 73686)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 3614 (class 2606 OID 77472)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3545 (class 2606 OID 73677)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3533 (class 2606 OID 73619)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3652 (class 2606 OID 77749)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 3655 (class 2606 OID 77760)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 3610 (class 2606 OID 77434)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 3612 (class 2606 OID 77432)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 3566 (class 2606 OID 77106)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 3579 (class 2606 OID 77204)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3620 (class 2606 OID 77544)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 3622 (class 2606 OID 77546)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 3535 (class 2606 OID 73640)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 3632 (class 2606 OID 77600)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3643 (class 2606 OID 77725)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 3645 (class 2606 OID 77723)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3608 (class 2606 OID 77421)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 3512 (class 2606 OID 68770)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 3520 (class 2606 OID 68772)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 3523 (class 2606 OID 68774)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 3517 (class 2606 OID 68776)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 3663 (class 2606 OID 77992)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 3616 (class 2606 OID 77483)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3568 (class 2606 OID 77139)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 3570 (class 2606 OID 77137)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3577 (class 2606 OID 77181)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3603 (class 2606 OID 77385)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 3573 (class 2606 OID 77153)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 3575 (class 2606 OID 77155)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 3657 (class 2606 OID 77775)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 3647 (class 2606 OID 77738)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 3649 (class 2606 OID 77736)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3527 (class 2606 OID 68778)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 3529 (class 2606 OID 68780)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 3538 (class 2606 OID 73648)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3626 (class 2606 OID 77561)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 3629 (class 2606 OID 77580)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 3659 (class 2606 OID 77969)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 3637 (class 2606 OID 77633)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3582 (class 2606 OID 77229)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 3584 (class 2606 OID 77227)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3586 (class 2606 OID 77239)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3588 (class 2606 OID 77262)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 3590 (class 2606 OID 77260)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 3514 (class 2606 OID 68782)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 3556 (class 2606 OID 77041)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 3639 (class 2606 OID 77703)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3641 (class 2606 OID 77705)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


SET search_path = public, pg_catalog;

--
-- TOC entry 3349 (class 1259 OID 68783)
-- Name: creationhour; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX creationhour ON ticket USING btree (creation_hour);


--
-- TOC entry 3350 (class 1259 OID 68784)
-- Name: deliverydate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX deliverydate ON ticket USING btree (deliveery_date);


--
-- TOC entry 3317 (class 1259 OID 68785)
-- Name: drawer_report_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawer_report_time ON drawer_pull_report USING btree (report_time);


--
-- TOC entry 3351 (class 1259 OID 68786)
-- Name: drawerresetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX drawerresetted ON ticket USING btree (drawer_resetted);


--
-- TOC entry 3371 (class 1259 OID 68787)
-- Name: food_category_visible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX food_category_visible ON menu_category USING btree (visible);


--
-- TOC entry 3449 (class 1259 OID 68788)
-- Name: fromdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX fromdate ON table_booking_info USING btree (from_date);


--
-- TOC entry 3313 (class 1259 OID 68789)
-- Name: idx_dah_user_op_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_dah_user_op_time ON drawer_assigned_history USING btree (a_user, operation, "time" DESC);


--
-- TOC entry 3314 (class 1259 OID 68790)
-- Name: idx_drawer_assigned_history_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_drawer_assigned_history_user_time ON drawer_assigned_history USING btree (a_user, "time");


--
-- TOC entry 3352 (class 1259 OID 68791)
-- Name: idx_ticket_close_term_owner; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_ticket_close_term_owner ON ticket USING btree (closing_date, terminal_id, owner_id);


--
-- TOC entry 3480 (class 1259 OID 68792)
-- Name: idx_tx_term_user_time; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX idx_tx_term_user_time ON transactions USING btree (terminal_id, user_id, transaction_time);


--
-- TOC entry 3368 (class 1259 OID 68793)
-- Name: ix_kitchen_ticket_item_item_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_item_item_id ON kitchen_ticket_item USING btree (ticket_item_id);


--
-- TOC entry 3344 (class 1259 OID 68794)
-- Name: ix_kitchen_ticket_ticket_id; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_kitchen_ticket_ticket_id ON kitchen_ticket USING btree (ticket_id);


--
-- TOC entry 3353 (class 1259 OID 68795)
-- Name: ix_ticket_branch_key; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_branch_key ON ticket USING btree (branch_key);


--
-- TOC entry 3354 (class 1259 OID 68796)
-- Name: ix_ticket_folio_date; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_folio_date ON ticket USING btree (folio_date);


--
-- TOC entry 3463 (class 1259 OID 68797)
-- Name: ix_ticket_item_ticket_pg; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ix_ticket_item_ticket_pg ON ticket_item USING btree (ticket_id, pg_id);


--
-- TOC entry 3376 (class 1259 OID 68798)
-- Name: menugroupvisible; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX menugroupvisible ON menu_group USING btree (visible);


--
-- TOC entry 3388 (class 1259 OID 68799)
-- Name: mg_enable; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX mg_enable ON menu_modifier_group USING btree (enabled);


--
-- TOC entry 3385 (class 1259 OID 68800)
-- Name: modifierenabled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX modifierenabled ON menu_modifier USING btree (enable);


--
-- TOC entry 3359 (class 1259 OID 68801)
-- Name: ticketactivedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketactivedate ON ticket USING btree (active_date);


--
-- TOC entry 3360 (class 1259 OID 68802)
-- Name: ticketclosingdate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketclosingdate ON ticket USING btree (closing_date);


--
-- TOC entry 3361 (class 1259 OID 68803)
-- Name: ticketcreatedate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketcreatedate ON ticket USING btree (create_date);


--
-- TOC entry 3362 (class 1259 OID 68804)
-- Name: ticketpaid; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketpaid ON ticket USING btree (paid);


--
-- TOC entry 3363 (class 1259 OID 68805)
-- Name: ticketsettled; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketsettled ON ticket USING btree (settled);


--
-- TOC entry 3364 (class 1259 OID 68806)
-- Name: ticketvoided; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX ticketvoided ON ticket USING btree (voided);


--
-- TOC entry 3452 (class 1259 OID 68807)
-- Name: todate; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX todate ON table_booking_info USING btree (to_date);


--
-- TOC entry 3481 (class 1259 OID 68808)
-- Name: tran_drawer_resetted; Type: INDEX; Schema: public; Owner: floreant
--

CREATE INDEX tran_drawer_resetted ON transactions USING btree (drawer_resetted);


--
-- TOC entry 3365 (class 1259 OID 68809)
-- Name: ux_ticket_dailyfolio; Type: INDEX; Schema: public; Owner: floreant
--

CREATE UNIQUE INDEX ux_ticket_dailyfolio ON ticket USING btree (folio_date, branch_key, daily_folio) WHERE (daily_folio IS NOT NULL);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3599 (class 1259 OID 77656)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 3559 (class 1259 OID 77653)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 3560 (class 1259 OID 77652)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 3563 (class 1259 OID 77651)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 3564 (class 1259 OID 77650)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 3630 (class 1259 OID 77658)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 3515 (class 1259 OID 68810)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 3571 (class 1259 OID 77654)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 3623 (class 1259 OID 77657)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 3624 (class 1259 OID 77567)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 3627 (class 1259 OID 77581)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 3633 (class 1259 OID 77649)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 3634 (class 1259 OID 77660)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 3635 (class 1259 OID 77659)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 3580 (class 1259 OID 77655)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 3606 (class 1259 OID 77661)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 3521 (class 1259 OID 68811)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 3524 (class 1259 OID 68812)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 3525 (class 1259 OID 68813)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 3546 (class 1259 OID 73678)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 3650 (class 1259 OID 77742)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 3653 (class 1259 OID 77753)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 3518 (class 1259 OID 68814)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 3536 (class 1259 OID 73650)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 3539 (class 1259 OID 73649)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 3510 (class 1259 OID 68815)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


SET search_path = public, pg_catalog;

--
-- TOC entry 3831 (class 2620 OID 68816)
-- Name: trg_assign_daily_folio; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_assign_daily_folio BEFORE INSERT ON ticket FOR EACH ROW EXECUTE PROCEDURE assign_daily_folio();


--
-- TOC entry 3832 (class 2620 OID 68817)
-- Name: trg_kds_notify_kti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_kti AFTER INSERT OR UPDATE OF status ON kitchen_ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 3833 (class 2620 OID 68818)
-- Name: trg_kds_notify_ti; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_kds_notify_ti AFTER INSERT OR UPDATE OF status ON ticket_item FOR EACH ROW EXECUTE PROCEDURE kds_notify();


--
-- TOC entry 3829 (class 2620 OID 68819)
-- Name: trg_selemti_dah_ai; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_dah_ai AFTER INSERT ON drawer_assigned_history FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();


--
-- TOC entry 3830 (class 2620 OID 68820)
-- Name: trg_selemti_terminal_bu_snapshot; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_terminal_bu_snapshot BEFORE UPDATE ON terminal FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();


--
-- TOC entry 3834 (class 2620 OID 68821)
-- Name: trg_selemti_tx_ai_forma_pago; Type: TRIGGER; Schema: public; Owner: floreant
--

CREATE TRIGGER trg_selemti_tx_ai_forma_pago AFTER INSERT ON transactions FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3835 (class 2620 OID 68822)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


SET search_path = public, pg_catalog;

--
-- TOC entry 3724 (class 2606 OID 68823)
-- Name: fk1273b4bbb79c6270; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier_properties
    ADD CONSTRAINT fk1273b4bbb79c6270 FOREIGN KEY (menu_modifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 3711 (class 2606 OID 68828)
-- Name: fk1462f02bcb07faa3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket_item
    ADD CONSTRAINT fk1462f02bcb07faa3 FOREIGN KEY (kithen_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 3735 (class 2606 OID 68833)
-- Name: fk17bd51a089fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a089fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 3734 (class 2606 OID 68838)
-- Name: fk17bd51a0ae5d580; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_pizzapirce
    ADD CONSTRAINT fk17bd51a0ae5d580 FOREIGN KEY (pizza_price_id) REFERENCES pizza_price(id);


--
-- TOC entry 3765 (class 2606 OID 68843)
-- Name: fk1fa465141df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_discount
    ADD CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 3754 (class 2606 OID 68848)
-- Name: fk2458e9258979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_table
    ADD CONSTRAINT fk2458e9258979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 3674 (class 2606 OID 68853)
-- Name: fk29aca6899e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_address
    ADD CONSTRAINT fk29aca6899e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 3675 (class 2606 OID 68858)
-- Name: fk29d9ca39e1c3d97; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY delivery_instruction
    ADD CONSTRAINT fk29d9ca39e1c3d97 FOREIGN KEY (customer_no) REFERENCES customer(auto_id);


--
-- TOC entry 3672 (class 2606 OID 68863)
-- Name: fk2cc0e08e28dd6c11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id) REFERENCES currency(id);


--
-- TOC entry 3671 (class 2606 OID 68868)
-- Name: fk2cc0e08e9006558; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id) REFERENCES cash_drawer(id);


--
-- TOC entry 3670 (class 2606 OID 68873)
-- Name: fk2cc0e08efb910735; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY currency_balance
    ADD CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 3785 (class 2606 OID 68878)
-- Name: fk2dbeaa4f283ecc6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f283ecc6 FOREIGN KEY (permissionid) REFERENCES user_type(id);


--
-- TOC entry 3784 (class 2606 OID 68883)
-- Name: fk2dbeaa4f8f23f5e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY user_user_permission
    ADD CONSTRAINT fk2dbeaa4f8f23f5e FOREIGN KEY (elt) REFERENCES user_permission(name);


--
-- TOC entry 3756 (class 2606 OID 68888)
-- Name: fk301c4de53e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de53e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3755 (class 2606 OID 68893)
-- Name: fk301c4de59e1c3cf1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_info
    ADD CONSTRAINT fk301c4de59e1c3cf1 FOREIGN KEY (customer_id) REFERENCES customer(auto_id);


--
-- TOC entry 3733 (class 2606 OID 68898)
-- Name: fk312b355b40fda3c9; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 3732 (class 2606 OID 68903)
-- Name: fk312b355b6e7b8b68; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id) REFERENCES menu_item(id);


--
-- TOC entry 3731 (class 2606 OID 68908)
-- Name: fk312b355b7f2f368; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_modifiergroup
    ADD CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group) REFERENCES menu_modifier_group(id);


--
-- TOC entry 3702 (class 2606 OID 68913)
-- Name: fk341cbc275cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kitchen_ticket
    ADD CONSTRAINT fk341cbc275cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 3685 (class 2606 OID 68918)
-- Name: fk34e4e3771df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3771df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 3684 (class 2606 OID 68923)
-- Name: fk34e4e3772ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e3772ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3683 (class 2606 OID 68928)
-- Name: fk34e4e377aa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY gratuity
    ADD CONSTRAINT fk34e4e377aa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 3771 (class 2606 OID 68933)
-- Name: fk3825f9d0dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_cooking_instruction
    ADD CONSTRAINT fk3825f9d0dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 3772 (class 2606 OID 68938)
-- Name: fk3df5d4fab9276e77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_discount
    ADD CONSTRAINT fk3df5d4fab9276e77 FOREIGN KEY (ticket_itemid) REFERENCES ticket_item(id);


--
-- TOC entry 3664 (class 2606 OID 68943)
-- Name: fk3f3af36b3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY action_history
    ADD CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3717 (class 2606 OID 68948)
-- Name: fk4cd5a1f35188aa24; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id) REFERENCES menu_group(id);


--
-- TOC entry 3716 (class 2606 OID 68953)
-- Name: fk4cd5a1f35cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 3715 (class 2606 OID 68958)
-- Name: fk4cd5a1f35ee9f27a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id) REFERENCES tax_group(id);


--
-- TOC entry 3714 (class 2606 OID 68963)
-- Name: fk4cd5a1f3a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 3713 (class 2606 OID 68968)
-- Name: fk4cd5a1f3f3b77c57; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item
    ADD CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie) REFERENCES recepie(id);


--
-- TOC entry 3788 (class 2606 OID 68973)
-- Name: fk4d495e87660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 3787 (class 2606 OID 68978)
-- Name: fk4d495e8897b1e39; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type) REFERENCES user_type(id);


--
-- TOC entry 3786 (class 2606 OID 68983)
-- Name: fk4d495e8d9409968; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal) REFERENCES terminal(id);


--
-- TOC entry 3712 (class 2606 OID 68988)
-- Name: fk4dc1ab7f2e347ff0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_group
    ADD CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id) REFERENCES menu_category(id);


--
-- TOC entry 3726 (class 2606 OID 68993)
-- Name: fk4f8523e38d9ea931; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id) REFERENCES menu_category(id);


--
-- TOC entry 3725 (class 2606 OID 68998)
-- Name: fk4f8523e3d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menucategory_discount
    ADD CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 3710 (class 2606 OID 69003)
-- Name: fk5696584bb73e273e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY kit_ticket_table_num
    ADD CONSTRAINT fk5696584bb73e273e FOREIGN KEY (kit_ticket_id) REFERENCES kitchen_ticket(id);


--
-- TOC entry 3739 (class 2606 OID 69008)
-- Name: fk572726f374be2c71; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f374be2c71 FOREIGN KEY (pizzamodifierprice_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 3738 (class 2606 OID 69013)
-- Name: fk572726f3ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menumodifier_pizzamodifierprice
    ADD CONSTRAINT fk572726f3ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 3694 (class 2606 OID 69018)
-- Name: fk59073b58c46a9c15; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_location
    ADD CONSTRAINT fk59073b58c46a9c15 FOREIGN KEY (warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 3723 (class 2606 OID 69023)
-- Name: fk59b6b1b72501cb2c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 3722 (class 2606 OID 69028)
-- Name: fk59b6b1b75e0c7b8d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id) REFERENCES menu_modifier_group(id);


--
-- TOC entry 3721 (class 2606 OID 69033)
-- Name: fk59b6b1b7a4802f83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_modifier
    ADD CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id) REFERENCES tax(id);


--
-- TOC entry 3676 (class 2606 OID 69038)
-- Name: fk5a823c91f1dd782b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_assigned_history
    ADD CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user) REFERENCES users(auto_id);


--
-- TOC entry 3775 (class 2606 OID 69043)
-- Name: fk5d3f9acb6c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 3774 (class 2606 OID 69048)
-- Name: fk5d3f9acbdec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier_relation
    ADD CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 3668 (class 2606 OID 69053)
-- Name: fk6221077d2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer
    ADD CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3777 (class 2606 OID 69058)
-- Name: fk65af15e21df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_table_num
    ADD CONSTRAINT fk65af15e21df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 3748 (class 2606 OID 69063)
-- Name: fk6b4e177764931efc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie
    ADD CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item) REFERENCES menu_item(id);


--
-- TOC entry 3758 (class 2606 OID 69068)
-- Name: fk6bc51417160de3b1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417160de3b1 FOREIGN KEY (booking_id) REFERENCES table_booking_info(id);


--
-- TOC entry 3757 (class 2606 OID 69073)
-- Name: fk6bc51417dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_booking_mapping
    ADD CONSTRAINT fk6bc51417dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 3682 (class 2606 OID 69078)
-- Name: fk6d5db9fa2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3681 (class 2606 OID 69083)
-- Name: fk6d5db9fa3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3680 (class 2606 OID 69088)
-- Name: fk6d5db9fa7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY employee_in_out_history
    ADD CONSTRAINT fk6d5db9fa7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 3776 (class 2606 OID 69093)
-- Name: fk70ecd046223049de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_properties
    ADD CONSTRAINT fk70ecd046223049de FOREIGN KEY (id) REFERENCES ticket(id);


--
-- TOC entry 3669 (class 2606 OID 69098)
-- Name: fk719418223e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY cash_drawer_reset_history
    ADD CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3693 (class 2606 OID 69103)
-- Name: fk7dc968362cd583c1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968362cd583c1 FOREIGN KEY (item_group_id) REFERENCES inventory_group(id);


--
-- TOC entry 3692 (class 2606 OID 69108)
-- Name: fk7dc968363525e956; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968363525e956 FOREIGN KEY (punit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 3691 (class 2606 OID 69113)
-- Name: fk7dc968366848d615; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968366848d615 FOREIGN KEY (recipe_unit_id) REFERENCES packaging_unit(id);


--
-- TOC entry 3690 (class 2606 OID 69118)
-- Name: fk7dc9683695e455d3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc9683695e455d3 FOREIGN KEY (item_location_id) REFERENCES inventory_location(id);


--
-- TOC entry 3689 (class 2606 OID 69123)
-- Name: fk7dc968369e60c333; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_item
    ADD CONSTRAINT fk7dc968369e60c333 FOREIGN KEY (item_vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 3751 (class 2606 OID 69128)
-- Name: fk80ad9f75fc64768f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY restaurant_properties
    ADD CONSTRAINT fk80ad9f75fc64768f FOREIGN KEY (id) REFERENCES restaurant(id);


--
-- TOC entry 3750 (class 2606 OID 69133)
-- Name: fk855626db1682b10e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item) REFERENCES inventory_item(id);


--
-- TOC entry 3749 (class 2606 OID 69138)
-- Name: fk855626dbcae89b83; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY recepie_item
    ADD CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id) REFERENCES recepie(id);


--
-- TOC entry 3742 (class 2606 OID 69143)
-- Name: fk8a16099391d62c51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a16099391d62c51 FOREIGN KEY (multiplier_id) REFERENCES multiplier(name);


--
-- TOC entry 3741 (class 2606 OID 69148)
-- Name: fk8a1609939c9e4883; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a1609939c9e4883 FOREIGN KEY (pizza_modifier_price_id) REFERENCES pizza_modifier_price(id);


--
-- TOC entry 3740 (class 2606 OID 69153)
-- Name: fk8a160993ae3f2e91; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY modifier_multiplier_price
    ADD CONSTRAINT fk8a160993ae3f2e91 FOREIGN KEY (menumodifier_id) REFERENCES menu_modifier(id);


--
-- TOC entry 3773 (class 2606 OID 69158)
-- Name: fk8fd6290dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_modifier
    ADD CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 3709 (class 2606 OID 69163)
-- Name: fk937b5f0c1f6a9a4a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user) REFERENCES users(auto_id);


--
-- TOC entry 3708 (class 2606 OID 69168)
-- Name: fk937b5f0c2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3707 (class 2606 OID 69173)
-- Name: fk937b5f0c7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 3706 (class 2606 OID 69178)
-- Name: fk937b5f0caa075d69; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id) REFERENCES users(auto_id);


--
-- TOC entry 3705 (class 2606 OID 69183)
-- Name: fk937b5f0cc188ea51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id) REFERENCES gratuity(id);


--
-- TOC entry 3704 (class 2606 OID 69188)
-- Name: fk937b5f0cf575c7d4; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id) REFERENCES users(auto_id);


--
-- TOC entry 3761 (class 2606 OID 69193)
-- Name: fk93802290dc46948d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290dc46948d FOREIGN KEY (table_id) REFERENCES shop_table(id);


--
-- TOC entry 3760 (class 2606 OID 69198)
-- Name: fk93802290f5d6e47b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_type_relation
    ADD CONSTRAINT fk93802290f5d6e47b FOREIGN KEY (type_id) REFERENCES shop_table_type(id);


--
-- TOC entry 3764 (class 2606 OID 69203)
-- Name: fk963f26d69d31df8e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_properties
    ADD CONSTRAINT fk963f26d69d31df8e FOREIGN KEY (id) REFERENCES terminal(id);


--
-- TOC entry 3768 (class 2606 OID 69208)
-- Name: fk979f54661df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 3767 (class 2606 OID 69213)
-- Name: fk979f546633e5d3b2; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 3766 (class 2606 OID 69218)
-- Name: fk979f54665cf1375f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item
    ADD CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id) REFERENCES printer_group(id);


--
-- TOC entry 3679 (class 2606 OID 69223)
-- Name: fk98cf9b143ef4cd9b; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report_voidtickets
    ADD CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id) REFERENCES drawer_pull_report(id);


--
-- TOC entry 3763 (class 2606 OID 69228)
-- Name: fk99ede5fc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3762 (class 2606 OID 69233)
-- Name: fk99ede5fcc433e65a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal_printers
    ADD CONSTRAINT fk99ede5fcc433e65a FOREIGN KEY (virtual_printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 3789 (class 2606 OID 69238)
-- Name: fk9af7853bcf15f4a6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY virtualprinter_order_type
    ADD CONSTRAINT fk9af7853bcf15f4a6 FOREIGN KEY (printer_id) REFERENCES virtual_printer(id);


--
-- TOC entry 3720 (class 2606 OID 69243)
-- Name: fk9ea1afc2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3719 (class 2606 OID 69248)
-- Name: fk9ea1afc89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_terminal_ref
    ADD CONSTRAINT fk9ea1afc89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 3770 (class 2606 OID 69253)
-- Name: fk9f1996346c108ef0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f1996346c108ef0 FOREIGN KEY (modifier_id) REFERENCES ticket_item_modifier(id);


--
-- TOC entry 3769 (class 2606 OID 69258)
-- Name: fk9f199634dec6120a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY ticket_item_addon_relation
    ADD CONSTRAINT fk9f199634dec6120a FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(id);


--
-- TOC entry 3678 (class 2606 OID 69263)
-- Name: fkaec362202ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3677 (class 2606 OID 69268)
-- Name: fkaec362203e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY drawer_pull_report
    ADD CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3699 (class 2606 OID 69273)
-- Name: fkaf48f43b5b397c5; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b5b397c5 FOREIGN KEY (reference_id) REFERENCES purchase_order(id);


--
-- TOC entry 3698 (class 2606 OID 69278)
-- Name: fkaf48f43b96a3d6bf; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43b96a3d6bf FOREIGN KEY (item_id) REFERENCES inventory_item(id);


--
-- TOC entry 3697 (class 2606 OID 69283)
-- Name: fkaf48f43bd152c95f; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bd152c95f FOREIGN KEY (vendor_id) REFERENCES inventory_vendor(id);


--
-- TOC entry 3696 (class 2606 OID 69288)
-- Name: fkaf48f43beda09759; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43beda09759 FOREIGN KEY (to_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 3695 (class 2606 OID 69293)
-- Name: fkaf48f43bff3f328a; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT fkaf48f43bff3f328a FOREIGN KEY (from_warehouse_id) REFERENCES inventory_warehouse(id);


--
-- TOC entry 3752 (class 2606 OID 69298)
-- Name: fkba6efbd68979c3cd; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template
    ADD CONSTRAINT fkba6efbd68979c3cd FOREIGN KEY (floor_id) REFERENCES shop_floor(id);


--
-- TOC entry 3747 (class 2606 OID 69303)
-- Name: fkc05b805e5f31265c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY printer_group_printers
    ADD CONSTRAINT fkc05b805e5f31265c FOREIGN KEY (printer_id) REFERENCES printer_group(id);


--
-- TOC entry 3759 (class 2606 OID 69308)
-- Name: fkcbeff0e454031ec1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY table_ticket_num
    ADD CONSTRAINT fkcbeff0e454031ec1 FOREIGN KEY (shop_table_status_id) REFERENCES shop_table_status(id);


--
-- TOC entry 3688 (class 2606 OID 69313)
-- Name: fkce827c6f3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY guest_check_print
    ADD CONSTRAINT fkce827c6f3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3743 (class 2606 OID 69318)
-- Name: fkd3de7e7896183657; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_modifier_price
    ADD CONSTRAINT fkd3de7e7896183657 FOREIGN KEY (item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 3673 (class 2606 OID 69323)
-- Name: fkd43068347bbccf0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY customer_properties
    ADD CONSTRAINT fkd43068347bbccf0 FOREIGN KEY (id) REFERENCES customer(auto_id);


--
-- TOC entry 3753 (class 2606 OID 69328)
-- Name: fkd70c313ca36ab054; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY shop_floor_template_properties
    ADD CONSTRAINT fkd70c313ca36ab054 FOREIGN KEY (id) REFERENCES shop_floor_template(id);


--
-- TOC entry 3730 (class 2606 OID 69333)
-- Name: fkd89ccdee33662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdee33662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 3729 (class 2606 OID 69338)
-- Name: fkd89ccdeed3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_discount
    ADD CONSTRAINT fkd89ccdeed3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 3667 (class 2606 OID 69343)
-- Name: fkdfe829a2ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a2ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3666 (class 2606 OID 69348)
-- Name: fkdfe829a3e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a3e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3665 (class 2606 OID 69353)
-- Name: fkdfe829a7660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY attendence_history
    ADD CONSTRAINT fkdfe829a7660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 3737 (class 2606 OID 69358)
-- Name: fke03c92d533662891; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d533662891 FOREIGN KEY (menuitem_id) REFERENCES menu_item(id);


--
-- TOC entry 3736 (class 2606 OID 69363)
-- Name: fke03c92d57660a5e3; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menuitem_shift
    ADD CONSTRAINT fke03c92d57660a5e3 FOREIGN KEY (shift_id) REFERENCES shift(id);


--
-- TOC entry 3701 (class 2606 OID 69368)
-- Name: fke2b846573ac1d2e0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b846573ac1d2e0 FOREIGN KEY (order_type_id) REFERENCES order_type(id);


--
-- TOC entry 3700 (class 2606 OID 69373)
-- Name: fke2b8465789fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY item_order_type
    ADD CONSTRAINT fke2b8465789fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 3728 (class 2606 OID 69378)
-- Name: fke3790e40113bf083; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40113bf083 FOREIGN KEY (menugroup_id) REFERENCES menu_group(id);


--
-- TOC entry 3727 (class 2606 OID 69383)
-- Name: fke3790e40d3e91e11; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menugroup_discount
    ADD CONSTRAINT fke3790e40d3e91e11 FOREIGN KEY (discount_id) REFERENCES coupon_and_discount(id);


--
-- TOC entry 3778 (class 2606 OID 69388)
-- Name: fke3de65548e8203bc; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transaction_properties
    ADD CONSTRAINT fke3de65548e8203bc FOREIGN KEY (id) REFERENCES transactions(id);


--
-- TOC entry 3703 (class 2606 OID 69393)
-- Name: fke83d827c969c6de; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY terminal
    ADD CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user) REFERENCES users(auto_id);


--
-- TOC entry 3746 (class 2606 OID 69398)
-- Name: fkeac112927c59441d; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac112927c59441d FOREIGN KEY (crust) REFERENCES pizza_crust(id);


--
-- TOC entry 3745 (class 2606 OID 69403)
-- Name: fkeac11292a56d141c; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292a56d141c FOREIGN KEY (order_type) REFERENCES order_type(id);


--
-- TOC entry 3744 (class 2606 OID 69408)
-- Name: fkeac11292dd545b77; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY pizza_price
    ADD CONSTRAINT fkeac11292dd545b77 FOREIGN KEY (menu_item_size) REFERENCES menu_item_size(id);


--
-- TOC entry 3687 (class 2606 OID 69413)
-- Name: fkf8a37399d900aa01; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399d900aa01 FOREIGN KEY (elt) REFERENCES tax(id);


--
-- TOC entry 3686 (class 2606 OID 69418)
-- Name: fkf8a37399eff11066; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY group_taxes
    ADD CONSTRAINT fkf8a37399eff11066 FOREIGN KEY (group_id) REFERENCES tax_group(id);


--
-- TOC entry 3718 (class 2606 OID 69423)
-- Name: fkf94186ff89fe23f0; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY menu_item_properties
    ADD CONSTRAINT fkf94186ff89fe23f0 FOREIGN KEY (menu_item_id) REFERENCES menu_item(id);


--
-- TOC entry 3783 (class 2606 OID 69428)
-- Name: fkfe9871551df2d7f1; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id) REFERENCES ticket(id);


--
-- TOC entry 3782 (class 2606 OID 69433)
-- Name: fkfe9871552ad2d031; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id) REFERENCES terminal(id);


--
-- TOC entry 3781 (class 2606 OID 69438)
-- Name: fkfe9871553e20ad51; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id) REFERENCES users(auto_id);


--
-- TOC entry 3780 (class 2606 OID 69443)
-- Name: fkfe987155ca43b6; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id) REFERENCES payout_recepients(id);


--
-- TOC entry 3779 (class 2606 OID 69448)
-- Name: fkfe987155fc697d9e; Type: FK CONSTRAINT; Schema: public; Owner: floreant
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id) REFERENCES payout_reasons(id);


SET search_path = selemti, pg_catalog;

--
-- TOC entry 3828 (class 2606 OID 77979)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 3807 (class 2606 OID 77286)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3808 (class 2606 OID 77281)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3811 (class 2606 OID 77407)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3812 (class 2606 OID 77402)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3804 (class 2606 OID 77956)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3809 (class 2606 OID 77339)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3810 (class 2606 OID 77363)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3797 (class 2606 OID 77090)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3816 (class 2606 OID 77502)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3815 (class 2606 OID 77507)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3795 (class 2606 OID 77304)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3794 (class 2606 OID 77291)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3796 (class 2606 OID 77519)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3824 (class 2606 OID 77743)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 3825 (class 2606 OID 77754)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 3813 (class 2606 OID 77435)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 3799 (class 2606 OID 77107)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3798 (class 2606 OID 77112)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3803 (class 2606 OID 77205)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3820 (class 2606 OID 77601)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3819 (class 2606 OID 77606)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3818 (class 2606 OID 77611)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3790 (class 2606 OID 69453)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 3792 (class 2606 OID 69458)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 3793 (class 2606 OID 69463)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 3791 (class 2606 OID 69468)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 3814 (class 2606 OID 77484)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 3801 (class 2606 OID 77187)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3802 (class 2606 OID 77182)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3800 (class 2606 OID 77156)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 3827 (class 2606 OID 77764)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 3826 (class 2606 OID 77769)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 3817 (class 2606 OID 77562)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3823 (class 2606 OID 77634)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3822 (class 2606 OID 77639)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3821 (class 2606 OID 77644)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3805 (class 2606 OID 77440)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 3806 (class 2606 OID 77240)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4242 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO selemti_user;


--
-- TOC entry 4243 (class 0 OID 0)
-- Dependencies: 6
-- Name: selemti; Type: ACL; Schema: -; Owner: floreant
--

REVOKE ALL ON SCHEMA selemti FROM PUBLIC;
REVOKE ALL ON SCHEMA selemti FROM floreant;
GRANT ALL ON SCHEMA selemti TO floreant;
GRANT ALL ON SCHEMA selemti TO selemti_user;


SET search_path = public, pg_catalog;

--
-- TOC entry 4245 (class 0 OID 0)
-- Dependencies: 181
-- Name: action_history; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE action_history FROM PUBLIC;
REVOKE ALL ON TABLE action_history FROM floreant;
GRANT ALL ON TABLE action_history TO floreant;
GRANT SELECT ON TABLE action_history TO selemti_user;


--
-- TOC entry 4247 (class 0 OID 0)
-- Dependencies: 183
-- Name: attendence_history; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE attendence_history FROM PUBLIC;
REVOKE ALL ON TABLE attendence_history FROM floreant;
GRANT ALL ON TABLE attendence_history TO floreant;
GRANT SELECT ON TABLE attendence_history TO selemti_user;


--
-- TOC entry 4249 (class 0 OID 0)
-- Dependencies: 185
-- Name: cash_drawer; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE cash_drawer FROM PUBLIC;
REVOKE ALL ON TABLE cash_drawer FROM floreant;
GRANT ALL ON TABLE cash_drawer TO floreant;
GRANT SELECT ON TABLE cash_drawer TO selemti_user;


--
-- TOC entry 4251 (class 0 OID 0)
-- Dependencies: 187
-- Name: cash_drawer_reset_history; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE cash_drawer_reset_history FROM PUBLIC;
REVOKE ALL ON TABLE cash_drawer_reset_history FROM floreant;
GRANT ALL ON TABLE cash_drawer_reset_history TO floreant;
GRANT SELECT ON TABLE cash_drawer_reset_history TO selemti_user;


--
-- TOC entry 4253 (class 0 OID 0)
-- Dependencies: 189
-- Name: cooking_instruction; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE cooking_instruction FROM PUBLIC;
REVOKE ALL ON TABLE cooking_instruction FROM floreant;
GRANT ALL ON TABLE cooking_instruction TO floreant;
GRANT SELECT ON TABLE cooking_instruction TO selemti_user;


--
-- TOC entry 4255 (class 0 OID 0)
-- Dependencies: 191
-- Name: coupon_and_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE coupon_and_discount FROM PUBLIC;
REVOKE ALL ON TABLE coupon_and_discount FROM floreant;
GRANT ALL ON TABLE coupon_and_discount TO floreant;
GRANT SELECT ON TABLE coupon_and_discount TO selemti_user;


--
-- TOC entry 4257 (class 0 OID 0)
-- Dependencies: 193
-- Name: currency; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE currency FROM PUBLIC;
REVOKE ALL ON TABLE currency FROM floreant;
GRANT ALL ON TABLE currency TO floreant;
GRANT SELECT ON TABLE currency TO selemti_user;


--
-- TOC entry 4258 (class 0 OID 0)
-- Dependencies: 194
-- Name: currency_balance; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE currency_balance FROM PUBLIC;
REVOKE ALL ON TABLE currency_balance FROM floreant;
GRANT ALL ON TABLE currency_balance TO floreant;
GRANT SELECT ON TABLE currency_balance TO selemti_user;


--
-- TOC entry 4261 (class 0 OID 0)
-- Dependencies: 197
-- Name: custom_payment; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE custom_payment FROM PUBLIC;
REVOKE ALL ON TABLE custom_payment FROM floreant;
GRANT ALL ON TABLE custom_payment TO floreant;
GRANT SELECT ON TABLE custom_payment TO selemti_user;


--
-- TOC entry 4263 (class 0 OID 0)
-- Dependencies: 199
-- Name: customer; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE customer FROM PUBLIC;
REVOKE ALL ON TABLE customer FROM floreant;
GRANT ALL ON TABLE customer TO floreant;
GRANT SELECT ON TABLE customer TO selemti_user;


--
-- TOC entry 4265 (class 0 OID 0)
-- Dependencies: 201
-- Name: customer_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE customer_properties FROM PUBLIC;
REVOKE ALL ON TABLE customer_properties FROM floreant;
GRANT ALL ON TABLE customer_properties TO floreant;
GRANT SELECT ON TABLE customer_properties TO selemti_user;


--
-- TOC entry 4266 (class 0 OID 0)
-- Dependencies: 202
-- Name: daily_folio_counter; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE daily_folio_counter FROM PUBLIC;
REVOKE ALL ON TABLE daily_folio_counter FROM floreant;
GRANT ALL ON TABLE daily_folio_counter TO floreant;
GRANT SELECT ON TABLE daily_folio_counter TO selemti_user;


--
-- TOC entry 4267 (class 0 OID 0)
-- Dependencies: 203
-- Name: data_update_info; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE data_update_info FROM PUBLIC;
REVOKE ALL ON TABLE data_update_info FROM floreant;
GRANT ALL ON TABLE data_update_info TO floreant;
GRANT SELECT ON TABLE data_update_info TO selemti_user;


--
-- TOC entry 4269 (class 0 OID 0)
-- Dependencies: 205
-- Name: delivery_address; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE delivery_address FROM PUBLIC;
REVOKE ALL ON TABLE delivery_address FROM floreant;
GRANT ALL ON TABLE delivery_address TO floreant;
GRANT SELECT ON TABLE delivery_address TO selemti_user;


--
-- TOC entry 4271 (class 0 OID 0)
-- Dependencies: 207
-- Name: delivery_charge; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE delivery_charge FROM PUBLIC;
REVOKE ALL ON TABLE delivery_charge FROM floreant;
GRANT ALL ON TABLE delivery_charge TO floreant;
GRANT SELECT ON TABLE delivery_charge TO selemti_user;


--
-- TOC entry 4273 (class 0 OID 0)
-- Dependencies: 209
-- Name: delivery_configuration; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE delivery_configuration FROM PUBLIC;
REVOKE ALL ON TABLE delivery_configuration FROM floreant;
GRANT ALL ON TABLE delivery_configuration TO floreant;
GRANT SELECT ON TABLE delivery_configuration TO selemti_user;


--
-- TOC entry 4275 (class 0 OID 0)
-- Dependencies: 211
-- Name: delivery_instruction; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE delivery_instruction FROM PUBLIC;
REVOKE ALL ON TABLE delivery_instruction FROM floreant;
GRANT ALL ON TABLE delivery_instruction TO floreant;
GRANT SELECT ON TABLE delivery_instruction TO selemti_user;


--
-- TOC entry 4277 (class 0 OID 0)
-- Dependencies: 213
-- Name: drawer_assigned_history; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE drawer_assigned_history FROM PUBLIC;
REVOKE ALL ON TABLE drawer_assigned_history FROM floreant;
GRANT ALL ON TABLE drawer_assigned_history TO floreant;
GRANT SELECT ON TABLE drawer_assigned_history TO selemti_user;


--
-- TOC entry 4279 (class 0 OID 0)
-- Dependencies: 215
-- Name: drawer_pull_report; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE drawer_pull_report FROM PUBLIC;
REVOKE ALL ON TABLE drawer_pull_report FROM floreant;
GRANT ALL ON TABLE drawer_pull_report TO floreant;
GRANT SELECT ON TABLE drawer_pull_report TO selemti_user;


--
-- TOC entry 4281 (class 0 OID 0)
-- Dependencies: 217
-- Name: drawer_pull_report_voidtickets; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE drawer_pull_report_voidtickets FROM PUBLIC;
REVOKE ALL ON TABLE drawer_pull_report_voidtickets FROM floreant;
GRANT ALL ON TABLE drawer_pull_report_voidtickets TO floreant;
GRANT SELECT ON TABLE drawer_pull_report_voidtickets TO selemti_user;


--
-- TOC entry 4282 (class 0 OID 0)
-- Dependencies: 218
-- Name: employee_in_out_history; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE employee_in_out_history FROM PUBLIC;
REVOKE ALL ON TABLE employee_in_out_history FROM floreant;
GRANT ALL ON TABLE employee_in_out_history TO floreant;
GRANT SELECT ON TABLE employee_in_out_history TO selemti_user;


--
-- TOC entry 4284 (class 0 OID 0)
-- Dependencies: 220
-- Name: global_config; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE global_config FROM PUBLIC;
REVOKE ALL ON TABLE global_config FROM floreant;
GRANT ALL ON TABLE global_config TO floreant;
GRANT SELECT ON TABLE global_config TO selemti_user;


--
-- TOC entry 4286 (class 0 OID 0)
-- Dependencies: 222
-- Name: gratuity; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE gratuity FROM PUBLIC;
REVOKE ALL ON TABLE gratuity FROM floreant;
GRANT ALL ON TABLE gratuity TO floreant;
GRANT SELECT ON TABLE gratuity TO selemti_user;


--
-- TOC entry 4288 (class 0 OID 0)
-- Dependencies: 224
-- Name: group_taxes; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE group_taxes FROM PUBLIC;
REVOKE ALL ON TABLE group_taxes FROM floreant;
GRANT ALL ON TABLE group_taxes TO floreant;
GRANT SELECT ON TABLE group_taxes TO selemti_user;


--
-- TOC entry 4289 (class 0 OID 0)
-- Dependencies: 225
-- Name: guest_check_print; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE guest_check_print FROM PUBLIC;
REVOKE ALL ON TABLE guest_check_print FROM floreant;
GRANT ALL ON TABLE guest_check_print TO floreant;
GRANT SELECT ON TABLE guest_check_print TO selemti_user;


--
-- TOC entry 4291 (class 0 OID 0)
-- Dependencies: 227
-- Name: inventory_group; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_group FROM PUBLIC;
REVOKE ALL ON TABLE inventory_group FROM floreant;
GRANT ALL ON TABLE inventory_group TO floreant;
GRANT SELECT ON TABLE inventory_group TO selemti_user;


--
-- TOC entry 4293 (class 0 OID 0)
-- Dependencies: 229
-- Name: inventory_item; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_item FROM PUBLIC;
REVOKE ALL ON TABLE inventory_item FROM floreant;
GRANT ALL ON TABLE inventory_item TO floreant;
GRANT SELECT ON TABLE inventory_item TO selemti_user;


--
-- TOC entry 4295 (class 0 OID 0)
-- Dependencies: 231
-- Name: inventory_location; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_location FROM PUBLIC;
REVOKE ALL ON TABLE inventory_location FROM floreant;
GRANT ALL ON TABLE inventory_location TO floreant;
GRANT SELECT ON TABLE inventory_location TO selemti_user;


--
-- TOC entry 4297 (class 0 OID 0)
-- Dependencies: 233
-- Name: inventory_meta_code; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_meta_code FROM PUBLIC;
REVOKE ALL ON TABLE inventory_meta_code FROM floreant;
GRANT ALL ON TABLE inventory_meta_code TO floreant;
GRANT SELECT ON TABLE inventory_meta_code TO selemti_user;


--
-- TOC entry 4299 (class 0 OID 0)
-- Dependencies: 235
-- Name: inventory_transaction; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_transaction FROM PUBLIC;
REVOKE ALL ON TABLE inventory_transaction FROM floreant;
GRANT ALL ON TABLE inventory_transaction TO floreant;
GRANT SELECT ON TABLE inventory_transaction TO selemti_user;


--
-- TOC entry 4301 (class 0 OID 0)
-- Dependencies: 237
-- Name: inventory_unit; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_unit FROM PUBLIC;
REVOKE ALL ON TABLE inventory_unit FROM floreant;
GRANT ALL ON TABLE inventory_unit TO floreant;
GRANT SELECT ON TABLE inventory_unit TO selemti_user;


--
-- TOC entry 4303 (class 0 OID 0)
-- Dependencies: 239
-- Name: inventory_vendor; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_vendor FROM PUBLIC;
REVOKE ALL ON TABLE inventory_vendor FROM floreant;
GRANT ALL ON TABLE inventory_vendor TO floreant;
GRANT SELECT ON TABLE inventory_vendor TO selemti_user;


--
-- TOC entry 4305 (class 0 OID 0)
-- Dependencies: 241
-- Name: inventory_warehouse; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE inventory_warehouse FROM PUBLIC;
REVOKE ALL ON TABLE inventory_warehouse FROM floreant;
GRANT ALL ON TABLE inventory_warehouse TO floreant;
GRANT SELECT ON TABLE inventory_warehouse TO selemti_user;


--
-- TOC entry 4307 (class 0 OID 0)
-- Dependencies: 243
-- Name: item_order_type; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE item_order_type FROM PUBLIC;
REVOKE ALL ON TABLE item_order_type FROM floreant;
GRANT ALL ON TABLE item_order_type TO floreant;
GRANT SELECT ON TABLE item_order_type TO selemti_user;


--
-- TOC entry 4308 (class 0 OID 0)
-- Dependencies: 244
-- Name: kitchen_ticket; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE kitchen_ticket FROM PUBLIC;
REVOKE ALL ON TABLE kitchen_ticket FROM floreant;
GRANT ALL ON TABLE kitchen_ticket TO floreant;
GRANT SELECT ON TABLE kitchen_ticket TO selemti_user;


--
-- TOC entry 4309 (class 0 OID 0)
-- Dependencies: 245
-- Name: terminal; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE terminal FROM PUBLIC;
REVOKE ALL ON TABLE terminal FROM floreant;
GRANT ALL ON TABLE terminal TO floreant;
GRANT SELECT ON TABLE terminal TO selemti_user;


--
-- TOC entry 4310 (class 0 OID 0)
-- Dependencies: 246
-- Name: ticket; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket FROM PUBLIC;
REVOKE ALL ON TABLE ticket FROM floreant;
GRANT ALL ON TABLE ticket TO floreant;
GRANT SELECT ON TABLE ticket TO selemti_user;


--
-- TOC entry 4311 (class 0 OID 0)
-- Dependencies: 247
-- Name: kds_orders_enhanced; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE kds_orders_enhanced FROM PUBLIC;
REVOKE ALL ON TABLE kds_orders_enhanced FROM floreant;
GRANT ALL ON TABLE kds_orders_enhanced TO floreant;
GRANT SELECT ON TABLE kds_orders_enhanced TO selemti_user;


--
-- TOC entry 4312 (class 0 OID 0)
-- Dependencies: 248
-- Name: kds_ready_log; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE kds_ready_log FROM PUBLIC;
REVOKE ALL ON TABLE kds_ready_log FROM floreant;
GRANT ALL ON TABLE kds_ready_log TO floreant;
GRANT SELECT ON TABLE kds_ready_log TO selemti_user;


--
-- TOC entry 4313 (class 0 OID 0)
-- Dependencies: 249
-- Name: kit_ticket_table_num; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE kit_ticket_table_num FROM PUBLIC;
REVOKE ALL ON TABLE kit_ticket_table_num FROM floreant;
GRANT ALL ON TABLE kit_ticket_table_num TO floreant;
GRANT SELECT ON TABLE kit_ticket_table_num TO selemti_user;


--
-- TOC entry 4315 (class 0 OID 0)
-- Dependencies: 251
-- Name: kitchen_ticket_item; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE kitchen_ticket_item FROM PUBLIC;
REVOKE ALL ON TABLE kitchen_ticket_item FROM floreant;
GRANT ALL ON TABLE kitchen_ticket_item TO floreant;
GRANT SELECT ON TABLE kitchen_ticket_item TO selemti_user;


--
-- TOC entry 4317 (class 0 OID 0)
-- Dependencies: 253
-- Name: menu_category; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_category FROM PUBLIC;
REVOKE ALL ON TABLE menu_category FROM floreant;
GRANT ALL ON TABLE menu_category TO floreant;
GRANT SELECT ON TABLE menu_category TO selemti_user;


--
-- TOC entry 4319 (class 0 OID 0)
-- Dependencies: 255
-- Name: menu_group; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_group FROM PUBLIC;
REVOKE ALL ON TABLE menu_group FROM floreant;
GRANT ALL ON TABLE menu_group TO floreant;
GRANT SELECT ON TABLE menu_group TO selemti_user;


--
-- TOC entry 4321 (class 0 OID 0)
-- Dependencies: 257
-- Name: menu_item; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_item FROM PUBLIC;
REVOKE ALL ON TABLE menu_item FROM floreant;
GRANT ALL ON TABLE menu_item TO floreant;
GRANT SELECT ON TABLE menu_item TO selemti_user;


--
-- TOC entry 4323 (class 0 OID 0)
-- Dependencies: 259
-- Name: menu_item_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_item_properties FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_properties FROM floreant;
GRANT ALL ON TABLE menu_item_properties TO floreant;
GRANT SELECT ON TABLE menu_item_properties TO selemti_user;


--
-- TOC entry 4324 (class 0 OID 0)
-- Dependencies: 260
-- Name: menu_item_size; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_item_size FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_size FROM floreant;
GRANT ALL ON TABLE menu_item_size TO floreant;
GRANT SELECT ON TABLE menu_item_size TO selemti_user;


--
-- TOC entry 4326 (class 0 OID 0)
-- Dependencies: 262
-- Name: menu_item_terminal_ref; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_item_terminal_ref FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_terminal_ref FROM floreant;
GRANT ALL ON TABLE menu_item_terminal_ref TO floreant;
GRANT SELECT ON TABLE menu_item_terminal_ref TO selemti_user;


--
-- TOC entry 4327 (class 0 OID 0)
-- Dependencies: 263
-- Name: menu_modifier; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_modifier FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier FROM floreant;
GRANT ALL ON TABLE menu_modifier TO floreant;
GRANT SELECT ON TABLE menu_modifier TO selemti_user;


--
-- TOC entry 4328 (class 0 OID 0)
-- Dependencies: 264
-- Name: menu_modifier_group; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_modifier_group FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier_group FROM floreant;
GRANT ALL ON TABLE menu_modifier_group TO floreant;
GRANT SELECT ON TABLE menu_modifier_group TO selemti_user;


--
-- TOC entry 4331 (class 0 OID 0)
-- Dependencies: 267
-- Name: menu_modifier_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menu_modifier_properties FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier_properties FROM floreant;
GRANT ALL ON TABLE menu_modifier_properties TO floreant;
GRANT SELECT ON TABLE menu_modifier_properties TO selemti_user;


--
-- TOC entry 4332 (class 0 OID 0)
-- Dependencies: 268
-- Name: menucategory_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menucategory_discount FROM PUBLIC;
REVOKE ALL ON TABLE menucategory_discount FROM floreant;
GRANT ALL ON TABLE menucategory_discount TO floreant;
GRANT SELECT ON TABLE menucategory_discount TO selemti_user;


--
-- TOC entry 4333 (class 0 OID 0)
-- Dependencies: 269
-- Name: menugroup_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menugroup_discount FROM PUBLIC;
REVOKE ALL ON TABLE menugroup_discount FROM floreant;
GRANT ALL ON TABLE menugroup_discount TO floreant;
GRANT SELECT ON TABLE menugroup_discount TO selemti_user;


--
-- TOC entry 4334 (class 0 OID 0)
-- Dependencies: 270
-- Name: menuitem_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menuitem_discount FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_discount FROM floreant;
GRANT ALL ON TABLE menuitem_discount TO floreant;
GRANT SELECT ON TABLE menuitem_discount TO selemti_user;


--
-- TOC entry 4335 (class 0 OID 0)
-- Dependencies: 271
-- Name: menuitem_modifiergroup; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menuitem_modifiergroup FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_modifiergroup FROM floreant;
GRANT ALL ON TABLE menuitem_modifiergroup TO floreant;
GRANT SELECT ON TABLE menuitem_modifiergroup TO selemti_user;


--
-- TOC entry 4337 (class 0 OID 0)
-- Dependencies: 273
-- Name: menuitem_pizzapirce; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menuitem_pizzapirce FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_pizzapirce FROM floreant;
GRANT ALL ON TABLE menuitem_pizzapirce TO floreant;
GRANT SELECT ON TABLE menuitem_pizzapirce TO selemti_user;


--
-- TOC entry 4338 (class 0 OID 0)
-- Dependencies: 274
-- Name: menuitem_shift; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menuitem_shift FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_shift FROM floreant;
GRANT ALL ON TABLE menuitem_shift TO floreant;
GRANT SELECT ON TABLE menuitem_shift TO selemti_user;


--
-- TOC entry 4340 (class 0 OID 0)
-- Dependencies: 276
-- Name: menumodifier_pizzamodifierprice; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE menumodifier_pizzamodifierprice FROM PUBLIC;
REVOKE ALL ON TABLE menumodifier_pizzamodifierprice FROM floreant;
GRANT ALL ON TABLE menumodifier_pizzamodifierprice TO floreant;
GRANT SELECT ON TABLE menumodifier_pizzamodifierprice TO selemti_user;


--
-- TOC entry 4341 (class 0 OID 0)
-- Dependencies: 389
-- Name: migrations; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE migrations FROM PUBLIC;
REVOKE ALL ON TABLE migrations FROM postgres;
GRANT ALL ON TABLE migrations TO postgres;
GRANT SELECT ON TABLE migrations TO selemti_user;


--
-- TOC entry 4343 (class 0 OID 0)
-- Dependencies: 277
-- Name: modifier_multiplier_price; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE modifier_multiplier_price FROM PUBLIC;
REVOKE ALL ON TABLE modifier_multiplier_price FROM floreant;
GRANT ALL ON TABLE modifier_multiplier_price TO floreant;
GRANT SELECT ON TABLE modifier_multiplier_price TO selemti_user;


--
-- TOC entry 4345 (class 0 OID 0)
-- Dependencies: 279
-- Name: multiplier; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE multiplier FROM PUBLIC;
REVOKE ALL ON TABLE multiplier FROM floreant;
GRANT ALL ON TABLE multiplier TO floreant;
GRANT SELECT ON TABLE multiplier TO selemti_user;


--
-- TOC entry 4346 (class 0 OID 0)
-- Dependencies: 280
-- Name: order_type; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE order_type FROM PUBLIC;
REVOKE ALL ON TABLE order_type FROM floreant;
GRANT ALL ON TABLE order_type TO floreant;
GRANT SELECT ON TABLE order_type TO selemti_user;


--
-- TOC entry 4348 (class 0 OID 0)
-- Dependencies: 282
-- Name: packaging_unit; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE packaging_unit FROM PUBLIC;
REVOKE ALL ON TABLE packaging_unit FROM floreant;
GRANT ALL ON TABLE packaging_unit TO floreant;
GRANT SELECT ON TABLE packaging_unit TO selemti_user;


--
-- TOC entry 4350 (class 0 OID 0)
-- Dependencies: 284
-- Name: payout_reasons; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE payout_reasons FROM PUBLIC;
REVOKE ALL ON TABLE payout_reasons FROM floreant;
GRANT ALL ON TABLE payout_reasons TO floreant;
GRANT SELECT ON TABLE payout_reasons TO selemti_user;


--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 286
-- Name: payout_recepients; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE payout_recepients FROM PUBLIC;
REVOKE ALL ON TABLE payout_recepients FROM floreant;
GRANT ALL ON TABLE payout_recepients TO floreant;
GRANT SELECT ON TABLE payout_recepients TO selemti_user;


--
-- TOC entry 4354 (class 0 OID 0)
-- Dependencies: 288
-- Name: pizza_crust; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE pizza_crust FROM PUBLIC;
REVOKE ALL ON TABLE pizza_crust FROM floreant;
GRANT ALL ON TABLE pizza_crust TO floreant;
GRANT SELECT ON TABLE pizza_crust TO selemti_user;


--
-- TOC entry 4356 (class 0 OID 0)
-- Dependencies: 290
-- Name: pizza_modifier_price; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE pizza_modifier_price FROM PUBLIC;
REVOKE ALL ON TABLE pizza_modifier_price FROM floreant;
GRANT ALL ON TABLE pizza_modifier_price TO floreant;
GRANT SELECT ON TABLE pizza_modifier_price TO selemti_user;


--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 292
-- Name: pizza_price; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE pizza_price FROM PUBLIC;
REVOKE ALL ON TABLE pizza_price FROM floreant;
GRANT ALL ON TABLE pizza_price TO floreant;
GRANT SELECT ON TABLE pizza_price TO selemti_user;


--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 294
-- Name: printer_configuration; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE printer_configuration FROM PUBLIC;
REVOKE ALL ON TABLE printer_configuration FROM floreant;
GRANT ALL ON TABLE printer_configuration TO floreant;
GRANT SELECT ON TABLE printer_configuration TO selemti_user;


--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 295
-- Name: printer_group; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE printer_group FROM PUBLIC;
REVOKE ALL ON TABLE printer_group FROM floreant;
GRANT ALL ON TABLE printer_group TO floreant;
GRANT SELECT ON TABLE printer_group TO selemti_user;


--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 297
-- Name: printer_group_printers; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE printer_group_printers FROM PUBLIC;
REVOKE ALL ON TABLE printer_group_printers FROM floreant;
GRANT ALL ON TABLE printer_group_printers TO floreant;
GRANT SELECT ON TABLE printer_group_printers TO selemti_user;


--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 298
-- Name: purchase_order; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE purchase_order FROM PUBLIC;
REVOKE ALL ON TABLE purchase_order FROM floreant;
GRANT ALL ON TABLE purchase_order TO floreant;
GRANT SELECT ON TABLE purchase_order TO selemti_user;


--
-- TOC entry 4366 (class 0 OID 0)
-- Dependencies: 300
-- Name: recepie; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE recepie FROM PUBLIC;
REVOKE ALL ON TABLE recepie FROM floreant;
GRANT ALL ON TABLE recepie TO floreant;
GRANT SELECT ON TABLE recepie TO selemti_user;


--
-- TOC entry 4368 (class 0 OID 0)
-- Dependencies: 302
-- Name: recepie_item; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE recepie_item FROM PUBLIC;
REVOKE ALL ON TABLE recepie_item FROM floreant;
GRANT ALL ON TABLE recepie_item TO floreant;
GRANT SELECT ON TABLE recepie_item TO selemti_user;


--
-- TOC entry 4370 (class 0 OID 0)
-- Dependencies: 304
-- Name: restaurant; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE restaurant FROM PUBLIC;
REVOKE ALL ON TABLE restaurant FROM floreant;
GRANT ALL ON TABLE restaurant TO floreant;
GRANT SELECT ON TABLE restaurant TO selemti_user;


--
-- TOC entry 4371 (class 0 OID 0)
-- Dependencies: 305
-- Name: restaurant_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE restaurant_properties FROM PUBLIC;
REVOKE ALL ON TABLE restaurant_properties FROM floreant;
GRANT ALL ON TABLE restaurant_properties TO floreant;
GRANT SELECT ON TABLE restaurant_properties TO selemti_user;


--
-- TOC entry 4372 (class 0 OID 0)
-- Dependencies: 306
-- Name: shift; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shift FROM PUBLIC;
REVOKE ALL ON TABLE shift FROM floreant;
GRANT ALL ON TABLE shift TO floreant;
GRANT SELECT ON TABLE shift TO selemti_user;


--
-- TOC entry 4374 (class 0 OID 0)
-- Dependencies: 308
-- Name: shop_floor; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_floor FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor FROM floreant;
GRANT ALL ON TABLE shop_floor TO floreant;
GRANT SELECT ON TABLE shop_floor TO selemti_user;


--
-- TOC entry 4376 (class 0 OID 0)
-- Dependencies: 310
-- Name: shop_floor_template; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_floor_template FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor_template FROM floreant;
GRANT ALL ON TABLE shop_floor_template TO floreant;
GRANT SELECT ON TABLE shop_floor_template TO selemti_user;


--
-- TOC entry 4378 (class 0 OID 0)
-- Dependencies: 312
-- Name: shop_floor_template_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_floor_template_properties FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor_template_properties FROM floreant;
GRANT ALL ON TABLE shop_floor_template_properties TO floreant;
GRANT SELECT ON TABLE shop_floor_template_properties TO selemti_user;


--
-- TOC entry 4379 (class 0 OID 0)
-- Dependencies: 313
-- Name: shop_table; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_table FROM PUBLIC;
REVOKE ALL ON TABLE shop_table FROM floreant;
GRANT ALL ON TABLE shop_table TO floreant;
GRANT SELECT ON TABLE shop_table TO selemti_user;


--
-- TOC entry 4380 (class 0 OID 0)
-- Dependencies: 314
-- Name: shop_table_status; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_table_status FROM PUBLIC;
REVOKE ALL ON TABLE shop_table_status FROM floreant;
GRANT ALL ON TABLE shop_table_status TO floreant;
GRANT SELECT ON TABLE shop_table_status TO selemti_user;


--
-- TOC entry 4381 (class 0 OID 0)
-- Dependencies: 315
-- Name: shop_table_type; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE shop_table_type FROM PUBLIC;
REVOKE ALL ON TABLE shop_table_type FROM floreant;
GRANT ALL ON TABLE shop_table_type TO floreant;
GRANT SELECT ON TABLE shop_table_type TO selemti_user;


--
-- TOC entry 4383 (class 0 OID 0)
-- Dependencies: 317
-- Name: table_booking_info; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE table_booking_info FROM PUBLIC;
REVOKE ALL ON TABLE table_booking_info FROM floreant;
GRANT ALL ON TABLE table_booking_info TO floreant;
GRANT SELECT ON TABLE table_booking_info TO selemti_user;


--
-- TOC entry 4385 (class 0 OID 0)
-- Dependencies: 319
-- Name: table_booking_mapping; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE table_booking_mapping FROM PUBLIC;
REVOKE ALL ON TABLE table_booking_mapping FROM floreant;
GRANT ALL ON TABLE table_booking_mapping TO floreant;
GRANT SELECT ON TABLE table_booking_mapping TO selemti_user;


--
-- TOC entry 4386 (class 0 OID 0)
-- Dependencies: 320
-- Name: table_ticket_num; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE table_ticket_num FROM PUBLIC;
REVOKE ALL ON TABLE table_ticket_num FROM floreant;
GRANT ALL ON TABLE table_ticket_num TO floreant;
GRANT SELECT ON TABLE table_ticket_num TO selemti_user;


--
-- TOC entry 4387 (class 0 OID 0)
-- Dependencies: 321
-- Name: table_type_relation; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE table_type_relation FROM PUBLIC;
REVOKE ALL ON TABLE table_type_relation FROM floreant;
GRANT ALL ON TABLE table_type_relation TO floreant;
GRANT SELECT ON TABLE table_type_relation TO selemti_user;


--
-- TOC entry 4388 (class 0 OID 0)
-- Dependencies: 322
-- Name: tax; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE tax FROM PUBLIC;
REVOKE ALL ON TABLE tax FROM floreant;
GRANT ALL ON TABLE tax TO floreant;
GRANT SELECT ON TABLE tax TO selemti_user;


--
-- TOC entry 4389 (class 0 OID 0)
-- Dependencies: 323
-- Name: tax_group; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE tax_group FROM PUBLIC;
REVOKE ALL ON TABLE tax_group FROM floreant;
GRANT ALL ON TABLE tax_group TO floreant;
GRANT SELECT ON TABLE tax_group TO selemti_user;


--
-- TOC entry 4391 (class 0 OID 0)
-- Dependencies: 325
-- Name: terminal_printers; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE terminal_printers FROM PUBLIC;
REVOKE ALL ON TABLE terminal_printers FROM floreant;
GRANT ALL ON TABLE terminal_printers TO floreant;
GRANT SELECT ON TABLE terminal_printers TO selemti_user;


--
-- TOC entry 4393 (class 0 OID 0)
-- Dependencies: 327
-- Name: terminal_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE terminal_properties FROM PUBLIC;
REVOKE ALL ON TABLE terminal_properties FROM floreant;
GRANT ALL ON TABLE terminal_properties TO floreant;
GRANT SELECT ON TABLE terminal_properties TO selemti_user;


--
-- TOC entry 4394 (class 0 OID 0)
-- Dependencies: 328
-- Name: ticket_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_discount FROM PUBLIC;
REVOKE ALL ON TABLE ticket_discount FROM floreant;
GRANT ALL ON TABLE ticket_discount TO floreant;
GRANT SELECT ON TABLE ticket_discount TO selemti_user;


--
-- TOC entry 4396 (class 0 OID 0)
-- Dependencies: 330
-- Name: ticket_folio_complete; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_folio_complete FROM PUBLIC;
REVOKE ALL ON TABLE ticket_folio_complete FROM floreant;
GRANT ALL ON TABLE ticket_folio_complete TO floreant;
GRANT SELECT ON TABLE ticket_folio_complete TO selemti_user;


--
-- TOC entry 4398 (class 0 OID 0)
-- Dependencies: 332
-- Name: ticket_item; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item FROM floreant;
GRANT ALL ON TABLE ticket_item TO floreant;
GRANT SELECT ON TABLE ticket_item TO selemti_user;


--
-- TOC entry 4399 (class 0 OID 0)
-- Dependencies: 333
-- Name: ticket_item_addon_relation; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item_addon_relation FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_addon_relation FROM floreant;
GRANT ALL ON TABLE ticket_item_addon_relation TO floreant;
GRANT SELECT ON TABLE ticket_item_addon_relation TO selemti_user;


--
-- TOC entry 4400 (class 0 OID 0)
-- Dependencies: 334
-- Name: ticket_item_cooking_instruction; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item_cooking_instruction FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_cooking_instruction FROM floreant;
GRANT ALL ON TABLE ticket_item_cooking_instruction TO floreant;
GRANT SELECT ON TABLE ticket_item_cooking_instruction TO selemti_user;


--
-- TOC entry 4401 (class 0 OID 0)
-- Dependencies: 335
-- Name: ticket_item_discount; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item_discount FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_discount FROM floreant;
GRANT ALL ON TABLE ticket_item_discount TO floreant;
GRANT SELECT ON TABLE ticket_item_discount TO selemti_user;


--
-- TOC entry 4404 (class 0 OID 0)
-- Dependencies: 338
-- Name: ticket_item_modifier; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item_modifier FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_modifier FROM floreant;
GRANT ALL ON TABLE ticket_item_modifier TO floreant;
GRANT SELECT ON TABLE ticket_item_modifier TO selemti_user;


--
-- TOC entry 4406 (class 0 OID 0)
-- Dependencies: 340
-- Name: ticket_item_modifier_relation; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_item_modifier_relation FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_modifier_relation FROM floreant;
GRANT ALL ON TABLE ticket_item_modifier_relation TO floreant;
GRANT SELECT ON TABLE ticket_item_modifier_relation TO selemti_user;


--
-- TOC entry 4407 (class 0 OID 0)
-- Dependencies: 341
-- Name: ticket_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_properties FROM PUBLIC;
REVOKE ALL ON TABLE ticket_properties FROM floreant;
GRANT ALL ON TABLE ticket_properties TO floreant;
GRANT SELECT ON TABLE ticket_properties TO selemti_user;


--
-- TOC entry 4408 (class 0 OID 0)
-- Dependencies: 342
-- Name: ticket_table_num; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE ticket_table_num FROM PUBLIC;
REVOKE ALL ON TABLE ticket_table_num FROM floreant;
GRANT ALL ON TABLE ticket_table_num TO floreant;
GRANT SELECT ON TABLE ticket_table_num TO selemti_user;


--
-- TOC entry 4409 (class 0 OID 0)
-- Dependencies: 343
-- Name: transaction_properties; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE transaction_properties FROM PUBLIC;
REVOKE ALL ON TABLE transaction_properties FROM floreant;
GRANT ALL ON TABLE transaction_properties TO floreant;
GRANT SELECT ON TABLE transaction_properties TO selemti_user;


--
-- TOC entry 4410 (class 0 OID 0)
-- Dependencies: 344
-- Name: transactions; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE transactions FROM PUBLIC;
REVOKE ALL ON TABLE transactions FROM floreant;
GRANT ALL ON TABLE transactions TO floreant;
GRANT SELECT ON TABLE transactions TO selemti_user;


--
-- TOC entry 4412 (class 0 OID 0)
-- Dependencies: 346
-- Name: user_permission; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE user_permission FROM PUBLIC;
REVOKE ALL ON TABLE user_permission FROM floreant;
GRANT ALL ON TABLE user_permission TO floreant;
GRANT SELECT ON TABLE user_permission TO selemti_user;


--
-- TOC entry 4413 (class 0 OID 0)
-- Dependencies: 347
-- Name: user_type; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE user_type FROM PUBLIC;
REVOKE ALL ON TABLE user_type FROM floreant;
GRANT ALL ON TABLE user_type TO floreant;
GRANT SELECT ON TABLE user_type TO selemti_user;


--
-- TOC entry 4415 (class 0 OID 0)
-- Dependencies: 349
-- Name: user_user_permission; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE user_user_permission FROM PUBLIC;
REVOKE ALL ON TABLE user_user_permission FROM floreant;
GRANT ALL ON TABLE user_user_permission TO floreant;
GRANT SELECT ON TABLE user_user_permission TO selemti_user;


--
-- TOC entry 4416 (class 0 OID 0)
-- Dependencies: 350
-- Name: users; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM floreant;
GRANT ALL ON TABLE users TO floreant;
GRANT SELECT ON TABLE users TO selemti_user;


--
-- TOC entry 4418 (class 0 OID 0)
-- Dependencies: 352
-- Name: virtual_printer; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE virtual_printer FROM PUBLIC;
REVOKE ALL ON TABLE virtual_printer FROM floreant;
GRANT ALL ON TABLE virtual_printer TO floreant;
GRANT SELECT ON TABLE virtual_printer TO selemti_user;


--
-- TOC entry 4420 (class 0 OID 0)
-- Dependencies: 354
-- Name: virtualprinter_order_type; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE virtualprinter_order_type FROM PUBLIC;
REVOKE ALL ON TABLE virtualprinter_order_type FROM floreant;
GRANT ALL ON TABLE virtualprinter_order_type TO floreant;
GRANT SELECT ON TABLE virtualprinter_order_type TO selemti_user;


--
-- TOC entry 4421 (class 0 OID 0)
-- Dependencies: 355
-- Name: void_reasons; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE void_reasons FROM PUBLIC;
REVOKE ALL ON TABLE void_reasons FROM floreant;
GRANT ALL ON TABLE void_reasons TO floreant;
GRANT SELECT ON TABLE void_reasons TO selemti_user;


--
-- TOC entry 4423 (class 0 OID 0)
-- Dependencies: 381
-- Name: vw_reconciliation_status; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE vw_reconciliation_status FROM PUBLIC;
REVOKE ALL ON TABLE vw_reconciliation_status FROM postgres;
GRANT ALL ON TABLE vw_reconciliation_status TO postgres;
GRANT SELECT ON TABLE vw_reconciliation_status TO selemti_user;


--
-- TOC entry 4424 (class 0 OID 0)
-- Dependencies: 357
-- Name: zip_code_vs_delivery_charge; Type: ACL; Schema: public; Owner: floreant
--

REVOKE ALL ON TABLE zip_code_vs_delivery_charge FROM PUBLIC;
REVOKE ALL ON TABLE zip_code_vs_delivery_charge FROM floreant;
GRANT ALL ON TABLE zip_code_vs_delivery_charge TO floreant;
GRANT SELECT ON TABLE zip_code_vs_delivery_charge TO selemti_user;


SET search_path = selemti, pg_catalog;

--
-- TOC entry 4471 (class 0 OID 0)
-- Dependencies: 377
-- Name: vw_sesion_ventas; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_ventas FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_ventas FROM postgres;
GRANT ALL ON TABLE vw_sesion_ventas TO postgres;
GRANT SELECT ON TABLE vw_sesion_ventas TO floreant;


--
-- TOC entry 4472 (class 0 OID 0)
-- Dependencies: 374
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-09-30 01:46:38

--
-- PostgreSQL database dump complete
--

