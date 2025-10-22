--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-10-21 22:16:07

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 89725)
-- Name: selemti; Type: SCHEMA; Schema: -; Owner: floreant
--

CREATE SCHEMA selemti;


ALTER SCHEMA selemti OWNER TO floreant;

SET search_path = selemti, pg_catalog;

--
-- TOC entry 1322 (class 1247 OID 91389)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1325 (class 1247 OID 91394)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1328 (class 1247 OID 91402)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1331 (class 1247 OID 91408)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1334 (class 1247 OID 91414)
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
-- TOC entry 1337 (class 1247 OID 91432)
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
-- TOC entry 1340 (class 1247 OID 91442)
-- Name: producto_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE producto_tipo OWNER TO postgres;

--
-- TOC entry 587 (class 1255 OID 93223)
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
-- TOC entry 600 (class 1255 OID 94403)
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
-- TOC entry 603 (class 1255 OID 94315)
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
-- TOC entry 581 (class 1255 OID 89732)
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
-- TOC entry 589 (class 1255 OID 93225)
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
-- TOC entry 588 (class 1255 OID 93224)
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
-- TOC entry 560 (class 1255 OID 94297)
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
-- TOC entry 590 (class 1255 OID 93226)
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
-- TOC entry 4254 (class 0 OID 0)
-- Dependencies: 590
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 606 (class 1255 OID 94338)
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
-- TOC entry 604 (class 1255 OID 94335)
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
-- TOC entry 582 (class 1255 OID 89733)
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
-- TOC entry 591 (class 1255 OID 93227)
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
-- TOC entry 4255 (class 0 OID 0)
-- Dependencies: 591
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 592 (class 1255 OID 93228)
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
-- TOC entry 4256 (class 0 OID 0)
-- Dependencies: 592
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 593 (class 1255 OID 93229)
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
-- TOC entry 4257 (class 0 OID 0)
-- Dependencies: 593
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 575 (class 1255 OID 89734)
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
-- TOC entry 607 (class 1255 OID 94376)
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
-- TOC entry 562 (class 1255 OID 94402)
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
-- TOC entry 583 (class 1255 OID 89735)
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
-- TOC entry 584 (class 1255 OID 89736)
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
-- TOC entry 585 (class 1255 OID 89737)
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
-- TOC entry 586 (class 1255 OID 89738)
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
-- TOC entry 605 (class 1255 OID 94337)
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
-- TOC entry 594 (class 1255 OID 93230)
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
-- TOC entry 595 (class 1255 OID 93231)
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
-- TOC entry 596 (class 1255 OID 93232)
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
-- TOC entry 597 (class 1255 OID 93233)
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
-- TOC entry 598 (class 1255 OID 93234)
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
-- TOC entry 608 (class 1255 OID 94377)
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

SET default_tablespace = '';

SET default_with_oids = false;

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
    handled boolean DEFAULT false NOT NULL
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
-- TOC entry 4258 (class 0 OID 0)
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
    notes text
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
-- TOC entry 4259 (class 0 OID 0)
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
-- TOC entry 4260 (class 0 OID 0)
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
-- TOC entry 4261 (class 0 OID 0)
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
-- TOC entry 4262 (class 0 OID 0)
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
-- TOC entry 4263 (class 0 OID 0)
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
-- TOC entry 4264 (class 0 OID 0)
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
-- TOC entry 4265 (class 0 OID 0)
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
-- TOC entry 4266 (class 0 OID 0)
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
-- TOC entry 4267 (class 0 OID 0)
-- Dependencies: 426
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 4268 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 4269 (class 0 OID 0)
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
-- TOC entry 4270 (class 0 OID 0)
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
-- TOC entry 4271 (class 0 OID 0)
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
-- TOC entry 4272 (class 0 OID 0)
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
-- TOC entry 4273 (class 0 OID 0)
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
-- TOC entry 4274 (class 0 OID 0)
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
-- TOC entry 4275 (class 0 OID 0)
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
-- TOC entry 4276 (class 0 OID 0)
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
-- TOC entry 4277 (class 0 OID 0)
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
-- TOC entry 4278 (class 0 OID 0)
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
    meta jsonb
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
-- TOC entry 4279 (class 0 OID 0)
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
-- TOC entry 4280 (class 0 OID 0)
-- Dependencies: 384
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


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
-- TOC entry 4281 (class 0 OID 0)
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
-- TOC entry 4282 (class 0 OID 0)
-- Dependencies: 436
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario con trazabilidad completa.';


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
-- TOC entry 4283 (class 0 OID 0)
-- Dependencies: 385
-- Name: inventory_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_batch_id_seq OWNED BY inventory_batch.id;


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
-- TOC entry 4284 (class 0 OID 0)
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
-- TOC entry 4285 (class 0 OID 0)
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
    CONSTRAINT items_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric)),
    CONSTRAINT items_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_unidad_medida_check CHECK (((unidad_medida)::text = ANY (ARRAY[('KG'::character varying)::text, ('LT'::character varying)::text, ('PZ'::character varying)::text, ('BULTO'::character varying)::text, ('CAJA'::character varying)::text])))
);


ALTER TABLE items OWNER TO postgres;

--
-- TOC entry 4286 (class 0 OID 0)
-- Dependencies: 438
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'Maestro de todos los productos/insumos del sistema.';


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
-- TOC entry 4287 (class 0 OID 0)
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
-- TOC entry 4288 (class 0 OID 0)
-- Dependencies: 387
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


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
-- TOC entry 4289 (class 0 OID 0)
-- Dependencies: 388
-- Name: lote_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE lote_id_seq OWNED BY lote.id;


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
-- TOC entry 4290 (class 0 OID 0)
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
-- TOC entry 4291 (class 0 OID 0)
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
-- TOC entry 4292 (class 0 OID 0)
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
-- TOC entry 4293 (class 0 OID 0)
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
-- TOC entry 4294 (class 0 OID 0)
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
-- TOC entry 4295 (class 0 OID 0)
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
-- TOC entry 4296 (class 0 OID 0)
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
-- TOC entry 4297 (class 0 OID 0)
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
-- TOC entry 4298 (class 0 OID 0)
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
-- TOC entry 4299 (class 0 OID 0)
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
-- TOC entry 4300 (class 0 OID 0)
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
-- TOC entry 4301 (class 0 OID 0)
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
-- TOC entry 4302 (class 0 OID 0)
-- Dependencies: 398
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


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
-- TOC entry 4303 (class 0 OID 0)
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
-- TOC entry 4304 (class 0 OID 0)
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
-- TOC entry 4305 (class 0 OID 0)
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
-- TOC entry 4306 (class 0 OID 0)
-- Dependencies: 370
-- Name: precorte_otros_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE precorte_otros_id_seq OWNED BY precorte_otros.id;


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
-- TOC entry 4307 (class 0 OID 0)
-- Dependencies: 399
-- Name: recalc_log_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recalc_log_id_seq OWNED BY recalc_log.id;


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
    meta jsonb
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
-- TOC entry 4308 (class 0 OID 0)
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
-- TOC entry 4309 (class 0 OID 0)
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
-- TOC entry 4310 (class 0 OID 0)
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
-- TOC entry 4311 (class 0 OID 0)
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
-- TOC entry 4312 (class 0 OID 0)
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
-- TOC entry 4313 (class 0 OID 0)
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
-- TOC entry 4314 (class 0 OID 0)
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
-- TOC entry 4315 (class 0 OID 0)
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
-- TOC entry 4316 (class 0 OID 0)
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
-- TOC entry 4317 (class 0 OID 0)
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
-- TOC entry 4318 (class 0 OID 0)
-- Dependencies: 553
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_cost_history_id_seq OWNED BY recipe_cost_history.id;


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
-- TOC entry 4319 (class 0 OID 0)
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
-- TOC entry 4320 (class 0 OID 0)
-- Dependencies: 549
-- Name: recipe_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE recipe_versions_id_seq OWNED BY recipe_versions.id;


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
-- TOC entry 4321 (class 0 OID 0)
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
    updated_at timestamp(0) without time zone
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
-- TOC entry 4322 (class 0 OID 0)
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
-- TOC entry 4323 (class 0 OID 0)
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
-- TOC entry 4324 (class 0 OID 0)
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
-- TOC entry 4325 (class 0 OID 0)
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
-- TOC entry 4326 (class 0 OID 0)
-- Dependencies: 411
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_det_consumo_id_seq OWNED BY ticket_det_consumo.id;


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
-- TOC entry 4327 (class 0 OID 0)
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
-- TOC entry 4328 (class 0 OID 0)
-- Dependencies: 413
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE ticket_venta_det_id_seq OWNED BY ticket_venta_det.id;


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
-- TOC entry 4329 (class 0 OID 0)
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
-- TOC entry 4330 (class 0 OID 0)
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
-- TOC entry 4331 (class 0 OID 0)
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
-- TOC entry 4332 (class 0 OID 0)
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
-- TOC entry 4333 (class 0 OID 0)
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
-- TOC entry 4334 (class 0 OID 0)
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
    CONSTRAINT users_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT users_intentos_login_check CHECK ((intentos_login >= 0)),
    CONSTRAINT users_password_hash_check CHECK ((length((password_hash)::text) = 60)),
    CONSTRAINT users_sucursal_id_check CHECK (((sucursal_id)::text = ANY (ARRAY[('SUR'::character varying)::text, ('NORTE'::character varying)::text, ('CENTRO'::character varying)::text]))),
    CONSTRAINT users_username_check CHECK ((length((username)::text) >= 3))
);


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 4335 (class 0 OID 0)
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
-- TOC entry 4336 (class 0 OID 0)
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
-- TOC entry 4337 (class 0 OID 0)
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

--
-- TOC entry 3536 (class 2604 OID 94396)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 3533 (class 2604 OID 94383)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 3246 (class 2604 OID 92570)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3288 (class 2604 OID 92571)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 3508 (class 2604 OID 93937)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 3510 (class 2604 OID 93953)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 3506 (class 2604 OID 93926)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 3289 (class 2604 OID 92572)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 3512 (class 2604 OID 93964)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 3293 (class 2604 OID 92573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 3298 (class 2604 OID 92574)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3301 (class 2604 OID 92575)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3302 (class 2604 OID 92576)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3251 (class 2604 OID 92577)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3307 (class 2604 OID 92578)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 3311 (class 2604 OID 92579)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 3318 (class 2604 OID 92580)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3325 (class 2604 OID 92581)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3329 (class 2604 OID 92582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 3333 (class 2604 OID 92583)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 3513 (class 2604 OID 93984)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 3337 (class 2604 OID 92584)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 3518 (class 2604 OID 94284)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 3521 (class 2604 OID 94322)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 3367 (class 2604 OID 92585)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 92586)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 92587)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 92588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 92589)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 92590)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 3384 (class 2604 OID 92591)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 3388 (class 2604 OID 92592)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 3389 (class 2604 OID 92593)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 3393 (class 2604 OID 92594)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 3402 (class 2604 OID 92595)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 3405 (class 2604 OID 92596)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 3407 (class 2604 OID 92597)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 3266 (class 2604 OID 92598)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 3274 (class 2604 OID 92599)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 3276 (class 2604 OID 92600)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 3280 (class 2604 OID 92601)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 3411 (class 2604 OID 92602)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 3412 (class 2604 OID 92603)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 3414 (class 2604 OID 92604)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 3417 (class 2604 OID 92605)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 3429 (class 2604 OID 92606)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 3432 (class 2604 OID 92607)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 3438 (class 2604 OID 92608)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 3444 (class 2604 OID 92609)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 3530 (class 2604 OID 94367)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 3529 (class 2604 OID 94358)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 3526 (class 2604 OID 94344)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 3445 (class 2604 OID 92610)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 3446 (class 2604 OID 92611)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 3285 (class 2604 OID 92612)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 3451 (class 2604 OID 92613)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 3455 (class 2604 OID 92614)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 3456 (class 2604 OID 92615)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 3463 (class 2604 OID 92616)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 3468 (class 2604 OID 92617)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 3470 (class 2604 OID 92618)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 3472 (class 2604 OID 92619)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 3476 (class 2604 OID 92620)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 3482 (class 2604 OID 92621)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 3487 (class 2604 OID 92622)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 3497 (class 2604 OID 92623)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 3505 (class 2604 OID 92624)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


--
-- TOC entry 4249 (class 0 OID 94393)
-- Dependencies: 558
-- Data for Name: alert_events; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4339 (class 0 OID 0)
-- Dependencies: 557
-- Name: alert_events_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_events_id_seq', 1, false);


--
-- TOC entry 4247 (class 0 OID 94380)
-- Dependencies: 556
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4340 (class 0 OID 0)
-- Dependencies: 555
-- Name: alert_rules_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_rules_id_seq', 1, false);


--
-- TOC entry 4157 (class 0 OID 92059)
-- Dependencies: 421
-- Data for Name: almacen; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4095 (class 0 OID 90271)
-- Dependencies: 359
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
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (61, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T12:40:31.622", "dah_id": 268, "operation": "ASIGNAR"}', '2025-10-20 12:40:31.623507-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (62, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T14:17:23.595", "dah_id": 270, "operation": "ASIGNAR"}', '2025-10-20 14:17:23.602981-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (63, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T14:17:47.874", "dah_id": 272, "operation": "ASIGNAR"}', '2025-10-20 14:17:47.876369-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (64, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T14:43:01.936", "dah_id": 274, "operation": "ASIGNAR"}', '2025-10-20 14:43:01.938724-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (65, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T15:47:40.198", "dah_id": 276, "operation": "ASIGNAR"}', '2025-10-20 15:47:40.199604-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (66, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T16:05:09.669", "dah_id": 278, "operation": "ASIGNAR"}', '2025-10-20 16:05:09.669902-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (67, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-20T18:34:39.758", "dah_id": 280, "operation": "ASIGNAR"}', '2025-10-20 18:34:39.759763-05');
INSERT INTO auditoria (id, quien, que, payload, creado_en) VALUES (68, 1, 'NO_SE_PUDO_RESOLVER_TERMINAL', '{"time": "2025-10-21T01:33:34.942", "dah_id": 282, "operation": "ASIGNAR"}', '2025-10-21 01:33:34.944314-05');


--
-- TOC entry 4341 (class 0 OID 0)
-- Dependencies: 360
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('auditoria_id_seq', 68, true);


--
-- TOC entry 4158 (class 0 OID 92066)
-- Dependencies: 422
-- Data for Name: bodega; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4342 (class 0 OID 0)
-- Dependencies: 373
-- Name: bodega_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('bodega_id_seq', 1, false);


--
-- TOC entry 4159 (class 0 OID 92072)
-- Dependencies: 423
-- Data for Name: cache; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4160 (class 0 OID 92078)
-- Dependencies: 424
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4225 (class 0 OID 93934)
-- Dependencies: 526
-- Data for Name: cat_almacenes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (53, 'NB', 'Na Balam', 18, true, '2025-10-21 05:06:10', '2025-10-21 05:06:10');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (54, 'TORRE', 'Torre UX', 20, true, '2025-10-21 05:06:27', '2025-10-21 05:06:27');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (55, 'COC-REF', 'Cocina Refrigeranción', 19, true, '2025-10-21 05:07:18', '2025-10-21 05:07:18');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (56, 'CAF-PRIN', 'Cafetería-Principal', 19, true, '2025-10-21 05:07:58', '2025-10-21 05:07:58');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (57, 'ALM-GEN', 'Almacen General', NULL, true, '2025-10-21 05:08:19', '2025-10-21 05:08:19');
INSERT INTO cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) VALUES (58, 'SELEMTI', 'PRUEBA SELEMTI', 22, true, '2025-10-21 05:08:40', '2025-10-21 05:08:40');


--
-- TOC entry 4343 (class 0 OID 0)
-- Dependencies: 525
-- Name: cat_almacenes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_almacenes_id_seq', 58, true);


--
-- TOC entry 4227 (class 0 OID 93950)
-- Dependencies: 528
-- Data for Name: cat_proveedores; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (10, 'XAXX010101000-U1', 'URBANO CASTILLO CENTRAL DE ABASTOS', NULL, NULL, true, '2025-10-21 12:57:52', '2025-10-21 12:57:52', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (11, 'AFA8807024B1', 'Abarrotes Fasti S.A. de C.V. .', NULL, NULL, true, '2025-10-21 12:58:37', '2025-10-21 12:58:37', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (9, 'NWM9709244W4', 'Sam''s Club México.', NULL, NULL, true, '2025-10-21 12:50:23', '2025-10-21 12:59:02', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (12, 'CCA8805089W1', 'Costco de México.', NULL, NULL, true, '2025-10-21 12:59:24', '2025-10-21 12:59:24', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (13, 'CCO670202HB7', 'Coca-Cola Femsa Veracruz', NULL, NULL, true, '2025-10-21 12:59:50', '2025-10-21 12:59:50', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (14, 'DCO100916H51', 'Distribuidora Comercial Oriental .', NULL, NULL, true, '2025-10-21 13:00:12', '2025-10-21 13:00:12', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (15, 'BIM4601016X8', 'Grupo Bimbo', NULL, NULL, true, '2025-10-21 13:00:34', '2025-10-21 13:00:34', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (16, 'CHE8507029B1', 'Chedraui Veracruz filial', NULL, NULL, true, '2025-10-21 13:01:17', '2025-10-21 13:01:17', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (17, 'LJO9201012B1', 'Quesos La Joya Liz S.A. de C.V.', NULL, NULL, true, '2025-10-21 13:01:38', '2025-10-21 13:01:38', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (18, 'XAXX010101000-MP', 'MATERIAS PRIMAS LA AZTECA', NULL, NULL, true, '2025-10-21 13:02:04', '2025-10-21 13:02:04', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (19, 'XAXX010101000-CP', 'COAPEXPAN CARNES FRIAS', NULL, NULL, true, '2025-10-21 13:02:12', '2025-10-21 13:02:12', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (20, 'OFS000526912', 'EL BODEGON DE SEMILLAS, S.A. DE C.V.', NULL, NULL, true, '2025-10-21 13:03:03', '2025-10-21 13:03:03', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (21, 'XAXX010101000-FC', 'FERCAS', NULL, NULL, true, '2025-10-21 13:04:51', '2025-10-21 13:04:51', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (22, 'XAXX010101000-FR', 'FRUTA', NULL, NULL, true, '2025-10-21 13:05:03', '2025-10-21 13:05:03', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (23, 'XAXX010101000-PK', 'PANADERIA KAREN', NULL, NULL, true, '2025-10-21 13:05:19', '2025-10-21 13:05:19', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (24, 'XAXX010101000-GN', 'GENERICO', NULL, NULL, true, '2025-10-21 13:05:57', '2025-10-21 13:05:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (25, 'XAXX010101000-SL', 'SAN LUIS', NULL, NULL, true, '2025-10-21 13:06:13', '2025-10-21 13:06:13', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (26, 'XAXX010101000-PE', 'POLLERIA EL DORADO', NULL, NULL, true, '2025-10-21 13:07:44', '2025-10-21 13:07:44', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (27, 'XAXX010101000-QV', 'QUESOS Y ABARROTES VERONICA', NULL, NULL, true, '2025-10-21 13:08:00', '2025-10-21 13:08:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) VALUES (28, 'XAXX010101000-VD', 'VERDURAS', NULL, NULL, true, '2025-10-21 13:08:10', '2025-10-21 13:08:10', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 4344 (class 0 OID 0)
-- Dependencies: 527
-- Name: cat_proveedores_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_proveedores_id_seq', 28, true);


--
-- TOC entry 4223 (class 0 OID 93923)
-- Dependencies: 524
-- Data for Name: cat_sucursales; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at) VALUES (21, 'ENT', 'Entrada', 'UX', true, '2025-10-21 04:56:05', '2025-10-21 04:56:05');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at) VALUES (22, 'SELEMTI', 'Pruebas Selem', 'SelemTI', true, '2025-10-21 04:56:41', '2025-10-21 04:56:41');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at) VALUES (19, 'PRI', 'Principal', 'UX', true, '2025-10-21 04:55:30', '2025-10-21 05:42:19');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at) VALUES (20, 'TOR', 'Torre UX', 'UX', true, '2025-10-21 04:55:44', '2025-10-21 05:42:27');
INSERT INTO cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at) VALUES (18, 'NAB', 'Na Balam', 'UX', true, '2025-10-21 04:55:05', '2025-10-21 05:42:36');


--
-- TOC entry 4345 (class 0 OID 0)
-- Dependencies: 523
-- Name: cat_sucursales_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_sucursales_id_seq', 22, true);


--
-- TOC entry 4161 (class 0 OID 92084)
-- Dependencies: 425
-- Data for Name: cat_unidades; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4346 (class 0 OID 0)
-- Dependencies: 374
-- Name: cat_unidades_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_unidades_id_seq', 1, false);


--
-- TOC entry 4229 (class 0 OID 93961)
-- Dependencies: 530
-- Data for Name: cat_uom_conversion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4347 (class 0 OID 0)
-- Dependencies: 529
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_uom_conversion_id_seq', 1, false);


--
-- TOC entry 4162 (class 0 OID 92087)
-- Dependencies: 426
-- Data for Name: conciliacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4348 (class 0 OID 0)
-- Dependencies: 375
-- Name: conciliacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conciliacion_id_seq', 1, false);


--
-- TOC entry 4163 (class 0 OID 92096)
-- Dependencies: 427
-- Data for Name: conversiones_unidad; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4349 (class 0 OID 0)
-- Dependencies: 376
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conversiones_unidad_id_seq', 1, false);


--
-- TOC entry 4164 (class 0 OID 92107)
-- Dependencies: 428
-- Data for Name: cost_layer; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4350 (class 0 OID 0)
-- Dependencies: 377
-- Name: cost_layer_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cost_layer_id_seq', 1, false);


--
-- TOC entry 4165 (class 0 OID 92113)
-- Dependencies: 429
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4351 (class 0 OID 0)
-- Dependencies: 378
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('failed_jobs_id_seq', 1, false);


--
-- TOC entry 4097 (class 0 OID 90280)
-- Dependencies: 361
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
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11761, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', 'werwer', true, 100, '2025-10-20 14:43:50.917674-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11765, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', '55', true, 100, '2025-10-20 15:49:17.115169-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11769, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', 'rrr', true, 100, '2025-10-20 16:06:27.862772-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11778, 'GIFT_CERT', 'GIFT_CERT', 'CREDIT', 'GIFT_CERTIFICATE', NULL, NULL, true, 100, '2025-10-20 19:09:05.684174-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11779, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', '123123', true, 100, '2025-10-20 19:09:17.20293-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11780, 'CASH_DROP', 'CASH_DROP', 'CREDIT', 'CASH', NULL, NULL, true, 100, '2025-10-20 19:09:35.567954-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11781, 'PAY_OUT', 'PAY_OUT', 'DEBIT', 'CASH', NULL, NULL, true, 100, '2025-10-20 19:10:13.489315-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11791, 'CREDIT_CARD', 'CREDIT_CARD', 'CREDIT', 'AMEX', NULL, NULL, true, 100, '2025-10-21 01:34:10.1111-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11794, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', '45', true, 100, '2025-10-21 01:35:32.461231-05');
INSERT INTO formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) VALUES (11802, 'CUSTOM:tranferencia', 'CUSTOM_PAYMENT', 'CREDIT', 'CUSTOM PAYMENT', 'Tranferencia', '66', true, 100, '2025-10-21 01:39:02.762296-05');


--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 362
-- Name: formas_pago_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('formas_pago_id_seq', 11803, true);


--
-- TOC entry 4166 (class 0 OID 92120)
-- Dependencies: 430
-- Data for Name: hist_cost_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 379
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_insumo_id_seq', 1, false);


--
-- TOC entry 4167 (class 0 OID 92129)
-- Dependencies: 431
-- Data for Name: hist_cost_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4354 (class 0 OID 0)
-- Dependencies: 380
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_receta_id_seq', 1, false);


--
-- TOC entry 4168 (class 0 OID 92138)
-- Dependencies: 432
-- Data for Name: historial_costos_item; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4355 (class 0 OID 0)
-- Dependencies: 381
-- Name: historial_costos_item_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_item_id_seq', 1, false);


--
-- TOC entry 4169 (class 0 OID 92153)
-- Dependencies: 433
-- Data for Name: historial_costos_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4356 (class 0 OID 0)
-- Dependencies: 382
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_receta_id_seq', 1, false);


--
-- TOC entry 4170 (class 0 OID 92162)
-- Dependencies: 434
-- Data for Name: insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 383
-- Name: insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_id_seq', 1, false);


--
-- TOC entry 4171 (class 0 OID 92171)
-- Dependencies: 435
-- Data for Name: insumo_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 384
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_presentacion_id_seq', 1, false);


--
-- TOC entry 4231 (class 0 OID 93981)
-- Dependencies: 532
-- Data for Name: inv_stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 531
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_stock_policy_id_seq', 1, false);


--
-- TOC entry 4172 (class 0 OID 92177)
-- Dependencies: 436
-- Data for Name: inventory_batch; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 385
-- Name: inventory_batch_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_batch_id_seq', 1, false);


--
-- TOC entry 4235 (class 0 OID 94281)
-- Dependencies: 544
-- Data for Name: item_categories; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 543
-- Name: item_categories_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_categories_id_seq', 1, false);


--
-- TOC entry 4237 (class 0 OID 94309)
-- Dependencies: 546
-- Data for Name: item_category_counters; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4173 (class 0 OID 92190)
-- Dependencies: 437
-- Data for Name: item_vendor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4239 (class 0 OID 94319)
-- Dependencies: 548
-- Data for Name: item_vendor_prices; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 547
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_vendor_prices_id_seq', 1, false);


--
-- TOC entry 4174 (class 0 OID 92201)
-- Dependencies: 438
-- Data for Name: items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4175 (class 0 OID 92221)
-- Dependencies: 439
-- Data for Name: job_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4176 (class 0 OID 92227)
-- Dependencies: 440
-- Data for Name: job_recalc_queue; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 386
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('job_recalc_queue_id_seq', 1, false);


--
-- TOC entry 4177 (class 0 OID 92237)
-- Dependencies: 441
-- Data for Name: jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 387
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('jobs_id_seq', 1, false);


--
-- TOC entry 4178 (class 0 OID 92243)
-- Dependencies: 442
-- Data for Name: lote; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 388
-- Name: lote_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('lote_id_seq', 1, false);


--
-- TOC entry 4179 (class 0 OID 92251)
-- Dependencies: 443
-- Data for Name: merma; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4366 (class 0 OID 0)
-- Dependencies: 389
-- Name: merma_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('merma_id_seq', 1, false);


--
-- TOC entry 4180 (class 0 OID 92258)
-- Dependencies: 444
-- Data for Name: migrations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO migrations (id, migration, batch) VALUES (1, '0001_01_01_000000_create_users_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (2, '0001_01_01_000001_create_cache_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (3, '0001_01_01_000002_create_jobs_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (4, '2025_09_26_090415_create_cat_unidades_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (5, '2025_09_26_090657_create_cat_unidades_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (6, '2025_09_26_205955_create_permission_tables', 3);
INSERT INTO migrations (id, migration, batch) VALUES (7, '2025_10_18_000001_create_cat_sucursales_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (8, '2025_10_18_000002_create_cat_almacenes_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (9, '2025_10_18_000003_create_cat_proveedores_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (10, '2025_10_18_000004_create_cat_uom_conversion_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (11, '2025_10_18_000005_create_inv_stock_policy_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (12, '2025_10_19_000001_update_cat_unidades_structure', 4);
INSERT INTO migrations (id, migration, batch) VALUES (13, '2025_01_12_000000_add_preferente_to_selemti_item_vendor', 5);
INSERT INTO migrations (id, migration, batch) VALUES (14, '2025_10_21_123344_add_preferente_to_selemti_item_vendor', 6);
INSERT INTO migrations (id, migration, batch) VALUES (15, '2025_10_21_100100_alter_cat_proveedores_add_fields', 7);
INSERT INTO migrations (id, migration, batch) VALUES (16, '2025_10_21_100200_alter_item_vendor_add_vendor_sku', 7);
INSERT INTO migrations (id, migration, batch) VALUES (17, '2025_10_21_180000_create_item_categories', 8);
INSERT INTO migrations (id, migration, batch) VALUES (18, '2025_10_21_180100_backfill_item_categories', 8);
INSERT INTO migrations (id, migration, batch) VALUES (19, '2025_10_21_180200_ensure_items_id_autoincrement', 9);
INSERT INTO migrations (id, migration, batch) VALUES (20, '2025_10_21_190100_alter_items_add_item_code', 9);
INSERT INTO migrations (id, migration, batch) VALUES (21, '2025_10_21_190200_item_code_trigger_and_counter', 9);
INSERT INTO migrations (id, migration, batch) VALUES (22, '2025_10_21_190300_backfill_item_codes', 9);
INSERT INTO migrations (id, migration, batch) VALUES (23, '2025_10_21_200000_create_item_vendor_prices', 9);
INSERT INTO migrations (id, migration, batch) VALUES (24, '2025_10_21_200100_fn_item_cost_at', 9);
INSERT INTO migrations (id, migration, batch) VALUES (25, '2025_10_21_200200_recipe_versioning_and_history', 9);
INSERT INTO migrations (id, migration, batch) VALUES (26, '2025_10_21_200300_fn_recipe_cost_at', 9);
INSERT INTO migrations (id, migration, batch) VALUES (27, '2025_10_21_200400_sp_snapshot_recipe_cost', 9);
INSERT INTO migrations (id, migration, batch) VALUES (28, '2025_10_21_200500_alert_rules_and_events', 9);
INSERT INTO migrations (id, migration, batch) VALUES (29, '2025_10_21_200600_trg_on_price_change_alerts', 9);


--
-- TOC entry 4367 (class 0 OID 0)
-- Dependencies: 390
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('migrations_id_seq', 29, true);


--
-- TOC entry 4181 (class 0 OID 92261)
-- Dependencies: 445
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4182 (class 0 OID 92264)
-- Dependencies: 446
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4183 (class 0 OID 92267)
-- Dependencies: 447
-- Data for Name: modificadores_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (3, 'MOD-00001', 'Pollo', 'AGREGADO', 0.00, 'REC-MOD-00001', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (4, 'MOD-00002', 'Picadillo', 'AGREGADO', 0.00, 'REC-MOD-00002', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (5, 'MOD-00003', 'Queso', 'AGREGADO', 0.00, 'REC-MOD-00003', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (6, 'MOD-00004', 'Pollo', 'AGREGADO', 0.00, 'REC-MOD-00004', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (7, 'MOD-00005', 'Papa', 'AGREGADO', 0.00, 'REC-MOD-00005', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (8, 'MOD-00006', 'Pollo', 'AGREGADO', 0.00, 'REC-MOD-00006', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (9, 'MOD-00007', 'Jamón', 'AGREGADO', 0.00, 'REC-MOD-00007', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (10, 'MOD-00008', 'Maíz', 'AGREGADO', 0.00, 'REC-MOD-00008', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (11, 'MOD-00009', 'Harina', 'AGREGADO', 0.00, 'REC-MOD-00009', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (12, 'MOD-00010', 'Jamón', 'AGREGADO', 0.00, 'REC-MOD-00010', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (13, 'MOD-00011', 'Chorizo', 'AGREGADO', 3.00, 'REC-MOD-00011', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (14, 'MOD-00012', 'Pastor', 'AGREGADO', 13.00, 'REC-MOD-00012', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (15, 'MOD-00013', 'Champiñones', 'AGREGADO', 13.00, 'REC-MOD-00013', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (16, 'MOD-00014', 'Verde', 'AGREGADO', 0.00, 'REC-MOD-00014', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (17, 'MOD-00015', 'Roja', 'AGREGADO', 0.00, 'REC-MOD-00015', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (18, 'MOD-00016', 'Chileseco', 'AGREGADO', 0.00, 'REC-MOD-00016', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (19, 'MOD-00017', 'Frijoles', 'AGREGADO', 0.00, 'REC-MOD-00017', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (20, 'MOD-00018', 'Sencilla', 'AGREGADO', 0.00, 'REC-MOD-00018', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (21, 'MOD-00019', 'Huevo', 'AGREGADO', 17.00, 'REC-MOD-00019', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (22, 'MOD-00020', 'Pollo', 'AGREGADO', 20.00, 'REC-MOD-00020', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (23, 'MOD-00021', 'Chorizo', 'AGREGADO', 20.00, 'REC-MOD-00021', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (24, 'MOD-00022', 'Milanesa', 'AGREGADO', 0.00, 'REC-MOD-00022', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (25, 'MOD-00023', 'Cecina', 'AGREGADO', 0.00, 'REC-MOD-00023', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (26, 'MOD-00024', 'Pechuga', 'AGREGADO', 0.00, 'REC-MOD-00024', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (27, 'MOD-00025', 'Chorizo', 'AGREGADO', 0.00, 'REC-MOD-00025', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (28, 'MOD-00026', 'Arrachera', 'AGREGADO', 0.00, 'REC-MOD-00026', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (29, 'MOD-00027', 'Roja', 'AGREGADO', 0.00, 'REC-MOD-00027', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (30, 'MOD-00028', 'Verde', 'AGREGADO', 0.00, 'REC-MOD-00028', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (31, 'MOD-00029', 'Sencillas', 'AGREGADO', 0.00, 'REC-MOD-00029', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (32, 'MOD-00030', 'Pollo', 'AGREGADO', 15.00, 'REC-MOD-00030', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (33, 'MOD-00031', 'Huevo', 'AGREGADO', 15.00, 'REC-MOD-00031', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (34, 'MOD-00032', 'Jamón', 'AGREGADO', 18.00, 'REC-MOD-00032', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (35, 'MOD-00033', 'Queso de Hebra', 'AGREGADO', 18.00, 'REC-MOD-00033', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (36, 'MOD-00034', 'Milanesa', 'AGREGADO', 0.00, 'REC-MOD-00034', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (37, 'MOD-00035', 'Pechuga', 'AGREGADO', 0.00, 'REC-MOD-00035', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (38, 'MOD-00036', 'Cecina', 'AGREGADO', 10.00, 'REC-MOD-00036', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (39, 'MOD-00037', 'Arrachera', 'AGREGADO', 13.00, 'REC-MOD-00037', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (40, 'MOD-00038', 'Pollo', 'AGREGADO', 13.00, 'REC-MOD-00038', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (41, 'MOD-00039', 'Huevo', 'AGREGADO', 13.00, 'REC-MOD-00039', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (42, 'MOD-00040', 'Jamón', 'AGREGADO', 15.00, 'REC-MOD-00040', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (43, 'MOD-00041', 'Queso de Hebra', 'AGREGADO', 15.00, 'REC-MOD-00041', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (44, 'MOD-00042', 'Pechuga', 'AGREGADO', 0.00, 'REC-MOD-00042', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (45, 'MOD-00043', 'Cecina', 'AGREGADO', 20.00, 'REC-MOD-00043', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (46, 'MOD-00044', 'Arrachera', 'AGREGADO', 30.00, 'REC-MOD-00044', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (47, 'MOD-00045', 'Milanesa', 'AGREGADO', 0.00, 'REC-MOD-00045', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (48, 'MOD-00046', 'Estrellado', 'AGREGADO', 0.00, 'REC-MOD-00046', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (49, 'MOD-00047', 'Revuelto', 'AGREGADO', 0.00, 'REC-MOD-00047', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (50, 'MOD-00048', 'Tierno', 'AGREGADO', 0.00, 'REC-MOD-00048', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (51, 'MOD-00049', 'Medio', 'AGREGADO', 0.00, 'REC-MOD-00049', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (52, 'MOD-00050', 'Cocido', 'AGREGADO', 0.00, 'REC-MOD-00050', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (53, 'MOD-00051', 'Sencillas', 'AGREGADO', 0.00, 'REC-MOD-00051', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (54, 'MOD-00052', 'Pollo', 'AGREGADO', 18.00, 'REC-MOD-00052', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (55, 'MOD-00053', 'Chorizo', 'AGREGADO', 18.00, 'REC-MOD-00053', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (56, 'MOD-00054', 'Huevo', 'AGREGADO', 15.00, 'REC-MOD-00054', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (57, 'MOD-00055', 'Roja', 'AGREGADO', 0.00, 'REC-MOD-00055', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (58, 'MOD-00056', 'Verde', 'AGREGADO', 0.00, 'REC-MOD-00056', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (59, 'MOD-00057', 'Mole', 'AGREGADO', 0.00, 'REC-MOD-00057', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (60, 'MOD-00058', 'Huevo', 'AGREGADO', 15.00, 'REC-MOD-00058', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (61, 'MOD-00059', 'Pollo', 'AGREGADO', 15.00, 'REC-MOD-00059', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (62, 'MOD-00060', 'Jamón', 'AGREGADO', 18.00, 'REC-MOD-00060', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (63, 'MOD-00061', 'Queso de Hebra', 'AGREGADO', 18.00, 'REC-MOD-00061', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (64, 'MOD-00062', 'Milanesa', 'AGREGADO', 0.00, 'REC-MOD-00062', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (65, 'MOD-00063', 'Pechuga', 'AGREGADO', 0.00, 'REC-MOD-00063', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (66, 'MOD-00064', 'Pastor', 'AGREGADO', 0.00, 'REC-MOD-00064', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (67, 'MOD-00065', 'Cecina', 'AGREGADO', 10.00, 'REC-MOD-00065', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (68, 'MOD-00066', 'Arrachera', 'AGREGADO', 13.00, 'REC-MOD-00066', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (69, 'MOD-00067', 'Lechera', 'AGREGADO', 0.00, 'REC-MOD-00067', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (70, 'MOD-00068', 'Cajeta', 'AGREGADO', 0.00, 'REC-MOD-00068', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (71, 'MOD-00069', 'Maple', 'AGREGADO', 0.00, 'REC-MOD-00069', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (72, 'MOD-00070', 'Mermelada de Fresa', 'AGREGADO', 0.00, 'REC-MOD-00070', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (73, 'MOD-00071', 'Sencillo', 'AGREGADO', 0.00, 'REC-MOD-00071', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (74, 'MOD-00072', 'Chorizo', 'AGREGADO', 7.00, 'REC-MOD-00072', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (75, 'MOD-00073', 'Jamón y Queso', 'AGREGADO', 7.00, 'REC-MOD-00073', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (76, 'MOD-00074', 'Jamón y Queso', 'AGREGADO', 0.00, 'REC-MOD-00074', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (77, 'MOD-00075', 'Pollo', 'AGREGADO', 2.00, 'REC-MOD-00075', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (78, 'MOD-00076', 'Pierna', 'AGREGADO', 5.00, 'REC-MOD-00076', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (79, 'MOD-00077', 'Atún', 'AGREGADO', 5.00, 'REC-MOD-00077', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (80, 'MOD-00078', 'Milanesa', 'AGREGADO', 7.00, 'REC-MOD-00078', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (81, 'MOD-00079', 'Pierna', 'AGREGADO', 7.00, 'REC-MOD-00079', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (82, 'MOD-00080', 'Jamón y Queso', 'AGREGADO', 0.00, 'REC-MOD-00080', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (83, 'MOD-00081', 'Pollo', 'AGREGADO', 0.00, 'REC-MOD-00081', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (84, 'MOD-00082', 'Choriqueso', 'AGREGADO', 0.00, 'REC-MOD-00082', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (85, 'MOD-00083', 'Huevo', 'AGREGADO', 0.00, 'REC-MOD-00083', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (86, 'MOD-00084', 'Chilaquiles', 'AGREGADO', 0.00, 'REC-MOD-00084', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (87, 'MOD-00087', 'Carga extra Café', 'AGREGADO', 5.00, 'REC-MOD-00087', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (88, 'MOD-00088', 'Chocolate', 'AGREGADO', 0.00, 'REC-MOD-00088', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (89, 'MOD-00089', 'Vainilla', 'AGREGADO', 0.00, 'REC-MOD-00089', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (90, 'MOD-00090', 'Choco-Plátano', 'AGREGADO', 0.00, 'REC-MOD-00090', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (91, 'MOD-00091', 'Plátano', 'AGREGADO', 0.00, 'REC-MOD-00091', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (92, 'MOD-00092', 'Fresa', 'AGREGADO', 0.00, 'REC-MOD-00092', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (93, 'MOD-00093', 'Frutos rojos', 'AGREGADO', 4.00, 'REC-MOD-00093', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (94, 'MOD-00094', 'Chocolate', 'AGREGADO', 0.00, 'REC-MOD-00094', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (95, 'MOD-00095', 'Vainilla', 'AGREGADO', 0.00, 'REC-MOD-00095', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (96, 'MOD-00096', '2 Picadas', 'AGREGADO', 0.00, 'REC-MOD-00096', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (97, 'MOD-00097', '2 Enchiladas', 'AGREGADO', 0.00, 'REC-MOD-00097', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (98, 'MOD-00098', '2 Enmoladas', 'AGREGADO', 0.00, 'REC-MOD-00098', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (99, 'MOD-00099', 'Jamón', 'AGREGADO', 0.00, 'REC-MOD-00099', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (100, 'MOD-00100', 'Chorizo', 'AGREGADO', 0.00, 'REC-MOD-00100', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (101, 'MOD-00101', 'A la Mexicana', 'AGREGADO', 0.00, 'REC-MOD-00101', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (102, 'MOD-00102', 'Tocino', 'AGREGADO', 0.00, 'REC-MOD-00102', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (103, 'MOD-00103', 'Ensalada', 'AGREGADO', 0.00, 'REC-MOD-00103', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (104, 'MOD-00104', 'Verduras', 'AGREGADO', 0.00, 'REC-MOD-00104', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (105, 'MOD-00105', 'Fruta', 'AGREGADO', 0.00, 'REC-MOD-00105', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (106, 'MOD-00106', 'Frijoles', 'AGREGADO', 0.00, 'REC-MOD-00106', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (107, 'MOD-00107', 'Papa con Chorizo', 'AGREGADO', 0.00, 'REC-MOD-00107', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (108, 'MOD-00108', 'Milanesa', 'AGREGADO', 0.00, 'REC-MOD-00108', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (109, 'MOD-00109', 'Pastor', 'AGREGADO', 0.00, 'REC-MOD-00109', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (110, 'MOD-00110', 'Pollo', 'AGREGADO', 0.00, 'REC-MOD-00110', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (111, 'MOD-00111', 'Mexicana', 'AGREGADO', 0.00, 'REC-MOD-00111', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (112, 'MOD-00112', 'Molida', 'AGREGADO', 0.00, 'REC-MOD-00112', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (113, 'MOD-00113', 'Costilla', 'AGREGADO', 0.00, 'REC-MOD-00113', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (114, 'MOD-00114', 'Huevo con Jamon', 'AGREGADO', 0.00, 'REC-MOD-00114', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (115, 'MOD-00115', 'Huevo con Chorizo', 'AGREGADO', 0.00, 'REC-MOD-00115', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (116, 'MOD-00116', 'Rajas', 'AGREGADO', 0.00, 'REC-MOD-00116', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (117, 'MOD-00117', 'Salchicha', 'AGREGADO', 0.00, 'REC-MOD-00117', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (118, 'MOD-00118', 'Carnitas', 'AGREGADO', 0.00, 'REC-MOD-00118', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (119, 'MOD-00119', 'Chuleta', 'AGREGADO', 0.00, 'REC-MOD-00119', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (120, 'MOD-00120', 'Huevo en Salsa', 'AGREGADO', 0.00, 'REC-MOD-00120', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (121, 'MOD-00121', 'Chicharron', 'AGREGADO', 0.00, 'REC-MOD-00121', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (122, 'MOD-00122', 'Sencilla', 'AGREGADO', 0.00, 'REC-MOD-00122', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (123, 'MOD-00123', 'Caramelo', 'AGREGADO', 0.00, 'REC-MOD-00123', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (124, 'MOD-00124', 'Cookies & Cream', 'AGREGADO', 0.00, 'REC-MOD-00124', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (125, 'MOD-00125', 'Crema de Avellana', 'AGREGADO', 5.00, 'REC-MOD-00125', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (126, 'MOD-00126', 'Crema Irlandesa', 'AGREGADO', 0.00, 'REC-MOD-00126', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (127, 'MOD-00127', 'Moka', 'AGREGADO', 0.00, 'REC-MOD-00127', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (128, 'MOD-00128', 'Vainilla', 'AGREGADO', 0.00, 'REC-MOD-00128', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (129, 'MOD-00129', 'Vainilla', 'AGREGADO', 0.00, 'REC-MOD-00129', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (130, 'MOD-00130', 'Negro', 'AGREGADO', 0.00, 'REC-MOD-00130', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (131, 'MOD-00131', 'Verde', 'AGREGADO', 0.00, 'REC-MOD-00131', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (132, 'MOD-00132', 'Natrural', 'AGREGADO', 0.00, 'REC-MOD-00132', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (133, 'MOD-00133', 'Mineral', 'AGREGADO', 5.00, 'REC-MOD-00133', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (134, 'MOD-00134', 'BBQ', 'AGREGADO', 0.00, 'REC-MOD-00134', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (135, 'MOD-00135', 'Búfalo', 'AGREGADO', 0.00, 'REC-MOD-00135', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (136, 'MOD-00136', 'Mango-Habanero', 'AGREGADO', 0.00, 'REC-MOD-00136', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (137, 'MOD-00137', 'Parmesano', 'AGREGADO', 0.00, 'REC-MOD-00137', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (138, 'MOD-00138', 'Habanero', 'AGREGADO', 0.00, 'REC-MOD-00138', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (139, 'MOD-00139', 'Chipotle', 'AGREGADO', 0.00, 'REC-MOD-00139', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (140, 'MOD-00140', 'Fuego', 'AGREGADO', 0.00, 'REC-MOD-00140', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (141, 'MOD-00141', 'Jalapeño', 'AGREGADO', 0.00, 'REC-MOD-00141', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (142, 'MOD-00142', 'Especias', 'AGREGADO', 0.00, 'REC-MOD-00142', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (143, 'MOD-00143', 'Adobadas', 'AGREGADO', 0.00, 'REC-MOD-00143', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (144, 'MOD-00144', 'Mora azul', 'AGREGADO', 0.00, 'REC-MOD-00144', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (145, 'MOD-00145', 'Fresa kiwi', 'AGREGADO', 0.00, 'REC-MOD-00145', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (146, 'MOD-00146', 'Naranja mandarina', 'AGREGADO', 0.00, 'REC-MOD-00146', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (147, 'MOD-00147', 'Ponche de frutas', 'AGREGADO', 0.00, 'REC-MOD-00147', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (148, 'MOD-00148', 'Uva', 'AGREGADO', 0.00, 'REC-MOD-00148', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (149, 'MOD-00150', 'Sencillos', 'AGREGADO', 0.00, 'REC-MOD-00150', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (150, 'MOD-00151', 'Fresa-Kiwi', 'AGREGADO', 0.00, 'REC-MOD-00151', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (151, 'MOD-00152', 'Naranja-Mandarina', 'AGREGADO', 0.00, 'REC-MOD-00152', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (152, 'MOD-00153', 'Ponche de Frutas', 'AGREGADO', 0.00, 'REC-MOD-00153', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (153, 'MOD-00154', 'Fresa', 'AGREGADO', 0.00, 'REC-MOD-00154', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (154, 'MOD-00155', 'Mora-Azul', 'AGREGADO', 0.00, 'REC-MOD-00155', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (155, 'MOD-00156', 'C SALADO', 'AGREGADO', 0.00, 'REC-MOD-00156', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (156, 'MOD-00157', 'C NATURAL', 'AGREGADO', 0.00, 'REC-MOD-00157', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (157, 'MOD-00158', 'C SAL Y LIMON', 'AGREGADO', 0.00, 'REC-MOD-00158', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (158, 'MOD-00159', 'C JALAPEÑO', 'AGREGADO', 0.00, 'REC-MOD-00159', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (159, 'MOD-00160', 'C QUEXO', 'AGREGADO', 0.00, 'REC-MOD-00160', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (160, 'MOD-00161', 'C HABANERO AMARILLO', 'AGREGADO', 0.00, 'REC-MOD-00161', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (161, 'MOD-00162', 'C HABANERO VERDE ', 'AGREGADO', 0.00, 'REC-MOD-00162', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (162, 'MOD-00163', 'C TOREADOS ', 'AGREGADO', 0.00, 'REC-MOD-00163', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (163, 'MOD-00164', 'C AJO CON CHILE ', 'AGREGADO', 0.00, 'REC-MOD-00164', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (164, 'MOD-00165', 'C AL AJO ', 'AGREGADO', 0.00, 'REC-MOD-00165', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (165, 'MOD-00166', 'Freshmint', 'AGREGADO', 0.00, 'REC-MOD-00166', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (166, 'MOD-00167', 'Menta', 'AGREGADO', 0.00, 'REC-MOD-00167', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (167, 'MOD-00168', 'MAKU', 'AGREGADO', 20.00, 'REC-MOD-00168', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (168, 'MOD-00169', 'Pastor con Queso', 'AGREGADO', 7.00, 'REC-MOD-00169', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (169, 'MOD-00170', 'Moka Blanco', 'AGREGADO', 0.00, 'REC-MOD-00170', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (170, 'MOD-00171', 'Oreo', 'AGREGADO', 0.00, 'REC-MOD-00171', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (171, 'MOD-00172', 'Fresa', 'AGREGADO', 0.00, 'REC-MOD-00172', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (172, 'MOD-00173', 'Mango', 'AGREGADO', 0.00, 'REC-MOD-00173', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (173, 'MOD-00174', 'Piña', 'AGREGADO', 0.00, 'REC-MOD-00174', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (174, 'MOD-00175', 'Mora Azul', 'AGREGADO', 5.00, 'REC-MOD-00175', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (175, 'MOD-00176', 'Kiwi', 'AGREGADO', 5.00, 'REC-MOD-00176', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (176, 'MOD-00177', 'Cereza', 'AGREGADO', 0.00, 'REC-MOD-00177', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (177, 'MOD-00178', 'Fresa', 'AGREGADO', 0.00, 'REC-MOD-00178', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (178, 'MOD-00179', 'Sandia', 'AGREGADO', 0.00, 'REC-MOD-00179', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (179, 'MOD-00180', 'Arandanos', 'AGREGADO', 0.00, 'REC-MOD-00180', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (180, 'MOD-00181', 'Manzana Verde', 'AGREGADO', 0.00, 'REC-MOD-00181', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (181, 'MOD-00182', 'Mora Azul', 'AGREGADO', 0.00, 'REC-MOD-00182', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (182, 'MOD-00183', 'JAMON Y TOCINO', 'AGREGADO', 0.00, 'REC-MOD-00183', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (183, 'MOD-00184', 'QUESO Y ZARZAMORA', 'AGREGADO', 0.00, 'REC-MOD-00184', true);
INSERT INTO modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) VALUES (184, 'MOD-00185', 'NUTELLA Y NUEZ', 'AGREGADO', 0.00, 'REC-MOD-00185', true);


--
-- TOC entry 4368 (class 0 OID 0)
-- Dependencies: 391
-- Name: modificadores_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('modificadores_pos_id_seq', 184, true);


--
-- TOC entry 4184 (class 0 OID 92273)
-- Dependencies: 448
-- Data for Name: mov_inv; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4369 (class 0 OID 0)
-- Dependencies: 392
-- Name: mov_inv_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('mov_inv_id_seq', 1, false);


--
-- TOC entry 4185 (class 0 OID 92280)
-- Dependencies: 449
-- Data for Name: op_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4370 (class 0 OID 0)
-- Dependencies: 393
-- Name: op_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_cab_id_seq', 1, false);


--
-- TOC entry 4186 (class 0 OID 92288)
-- Dependencies: 450
-- Data for Name: op_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4371 (class 0 OID 0)
-- Dependencies: 394
-- Name: op_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_insumo_id_seq', 1, false);


--
-- TOC entry 4187 (class 0 OID 92294)
-- Dependencies: 451
-- Data for Name: op_produccion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4372 (class 0 OID 0)
-- Dependencies: 395
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_produccion_cab_id_seq', 1, false);


--
-- TOC entry 4188 (class 0 OID 92302)
-- Dependencies: 452
-- Data for Name: op_yield; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4189 (class 0 OID 92309)
-- Dependencies: 453
-- Data for Name: param_sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4373 (class 0 OID 0)
-- Dependencies: 396
-- Name: param_sucursal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('param_sucursal_id_seq', 1, false);


--
-- TOC entry 4190 (class 0 OID 92320)
-- Dependencies: 454
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4191 (class 0 OID 92326)
-- Dependencies: 455
-- Data for Name: perdida_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4374 (class 0 OID 0)
-- Dependencies: 397
-- Name: perdida_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('perdida_log_id_seq', 1, false);


--
-- TOC entry 4192 (class 0 OID 92335)
-- Dependencies: 456
-- Data for Name: permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4375 (class 0 OID 0)
-- Dependencies: 398
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('permissions_id_seq', 1, false);


--
-- TOC entry 4193 (class 0 OID 92341)
-- Dependencies: 457
-- Data for Name: pos_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4099 (class 0 OID 90291)
-- Dependencies: 363
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
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (26, 84, 0.00, 1000.00, 1000.00, 'A_FAVOR', 0.00, 4.00, 4.00, 'A_FAVOR', '2025-10-20 15:46:28.789329-05', 1, 'Adelante', 0.00, 1.00, 1.00, 'A_FAVOR', true, 1, '2025-10-20 15:46:47.128679-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (27, 86, 50.00, 283.00, 233.00, 'CUADRA', 30.00, 30.00, 0.00, 'A_FAVOR', '2025-10-20 16:04:35.166911-05', 1, 'Error tarjetas', 0.00, 35.00, 35.00, 'CUADRA', true, 1, '2025-10-20 16:05:00.450155-05');
INSERT INTO postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en) VALUES (28, 87, 50.00, 150.00, 100.00, 'CUADRA', 180.00, 180.00, 0.00, 'CUADRA', '2025-10-20 18:14:38.123151-05', 1, 'Cuadrado al 100%', 0.00, 50.00, 50.00, 'CUADRA', true, 1, '2025-10-20 18:14:51.762493-05');


--
-- TOC entry 4376 (class 0 OID 0)
-- Dependencies: 364
-- Name: postcorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('postcorte_id_seq', 28, true);


--
-- TOC entry 4101 (class 0 OID 90316)
-- Dependencies: 365
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
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (27, 84, 1000.00, 5.00, 'ENVIADO', '2025-10-20 14:42:36.050973-05', 1, '::1', NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (28, 86, 283.00, 65.00, 'ENVIADO', '2025-10-20 15:49:38.754793-05', 1, '::1', 'Corte previo');
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (29, 87, 150.00, 230.00, 'ENVIADO', '2025-10-20 16:06:45.129502-05', 1, '::1', NULL);
INSERT INTO precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) VALUES (30, 89, 0.00, 0.00, 'PENDIENTE', '2025-10-21 01:44:16.246219-05', 1, '::1', NULL);


--
-- TOC entry 4102 (class 0 OID 90327)
-- Dependencies: 366
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
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (192, 27, 1000.00, 1, 1000.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (193, 28, 10.00, 2, 20.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (194, 28, 5.00, 2, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (195, 28, 20.00, 2, 40.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (196, 28, 2.00, 5, 10.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (197, 28, 100.00, 2, 200.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (198, 28, 1.00, 2, 2.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (199, 28, 0.50, 2, 1.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (200, 29, 100.00, 1, 100.00);
INSERT INTO precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) VALUES (201, 29, 50.00, 1, 50.00);


--
-- TOC entry 4377 (class 0 OID 0)
-- Dependencies: 367
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_efectivo_id_seq', 201, true);


--
-- TOC entry 4378 (class 0 OID 0)
-- Dependencies: 368
-- Name: precorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_id_seq', 30, true);


--
-- TOC entry 4105 (class 0 OID 90335)
-- Dependencies: 369
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
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (46, 27, 'CREDITO', 2.00, NULL, NULL, '', '2025-10-20 14:57:28.768544-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (47, 27, 'DEBITO', 2.00, NULL, NULL, '', '2025-10-20 14:57:28.768544-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (48, 27, 'TRANSFER', 1.00, NULL, NULL, '', '2025-10-20 14:57:28.768544-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (49, 28, 'CREDITO', 10.00, NULL, NULL, 'Corte previo', '2025-10-20 15:53:11.744775-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (50, 28, 'DEBITO', 20.00, NULL, NULL, 'Corte previo', '2025-10-20 15:53:11.744775-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (51, 28, 'TRANSFER', 35.00, NULL, NULL, 'Corte previo', '2025-10-20 15:53:11.744775-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (52, 29, 'CREDITO', 100.00, NULL, NULL, '', '2025-10-20 16:09:56.838995-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (53, 29, 'DEBITO', 80.00, NULL, NULL, '', '2025-10-20 16:09:56.838995-05');
INSERT INTO precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) VALUES (54, 29, 'TRANSFER', 50.00, NULL, NULL, '', '2025-10-20 16:09:56.838995-05');


--
-- TOC entry 4379 (class 0 OID 0)
-- Dependencies: 370
-- Name: precorte_otros_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_otros_id_seq', 54, true);


--
-- TOC entry 4194 (class 0 OID 92349)
-- Dependencies: 458
-- Data for Name: proveedor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4195 (class 0 OID 92356)
-- Dependencies: 459
-- Data for Name: recalc_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4380 (class 0 OID 0)
-- Dependencies: 399
-- Name: recalc_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recalc_log_id_seq', 1, false);


--
-- TOC entry 4196 (class 0 OID 92362)
-- Dependencies: 460
-- Data for Name: recepcion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4381 (class 0 OID 0)
-- Dependencies: 400
-- Name: recepcion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_cab_id_seq', 1, false);


--
-- TOC entry 4197 (class 0 OID 92369)
-- Dependencies: 461
-- Data for Name: recepcion_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4382 (class 0 OID 0)
-- Dependencies: 401
-- Name: recepcion_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_det_id_seq', 1, false);


--
-- TOC entry 4198 (class 0 OID 92375)
-- Dependencies: 462
-- Data for Name: receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4199 (class 0 OID 92383)
-- Dependencies: 463
-- Data for Name: receta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00005', 'Quesadilla', '5', 'ANTOJITOS', 1, NULL, NULL, 0.00, 22.00, true, '2025-10-21 08:32:22.280728', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00006', 'Empanada', '6', 'ANTOJITOS', 1, NULL, NULL, 0.00, 16.00, true, '2025-10-21 08:32:22.28208', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00007', 'Taco de Guisado', '7', 'ANTOJITOS', 1, NULL, NULL, 0.00, 19.00, true, '2025-10-21 08:32:22.283418', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00008', 'Picada Terrena', '8', 'ANTOJITOS', 1, NULL, NULL, 0.00, 68.00, true, '2025-10-21 08:32:22.284696', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00009', 'Enchiladas', '9', 'ENCHILADAS & ENMOLADAS', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.285956', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00011', 'Enmoladas', '11', 'ENCHILADAS & ENMOLADAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.288854', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00012', 'Tampiqueña', '12', 'ENCHILADAS & ENMOLADAS', 1, NULL, NULL, 0.00, 90.00, true, '2025-10-21 08:32:22.289901', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00013', 'Puchero de Pollo', '13', 'SOPAS & PASTAS & MENU', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.29056', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00014', 'Sopa Azteca', '14', 'SOPAS & PASTAS & MENU', 1, NULL, NULL, 0.00, 52.00, true, '2025-10-21 08:32:22.291846', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00016', 'Pasta Pomodoro', '16', 'SOPAS & PASTAS & MENU', 1, NULL, NULL, 0.00, 78.00, true, '2025-10-21 08:32:22.294247', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00017', 'Ensalada Atún', '17', 'ENSALADAS', 1, NULL, NULL, 0.00, 95.00, true, '2025-10-21 08:32:22.295544', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00018', 'Ensalada Dulce', '18', 'ENSALADAS', 1, NULL, NULL, 0.00, 88.00, true, '2025-10-21 08:32:22.296517', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00019', 'Ensalada Pollo', '19', 'ENSALADAS', 1, NULL, NULL, 0.00, 95.00, true, '2025-10-21 08:32:22.297698', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00020', 'Boneless 5 pz', '20', 'BONELESS', 1, NULL, NULL, 0.00, 68.00, true, '2025-10-21 08:32:22.29874', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00021', 'Boneless 10 pz', '21', 'BONELESS', 1, NULL, NULL, 0.00, 110.00, true, '2025-10-21 08:32:22.29981', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00022', 'Boneless 17 pz', '22', 'BONELESS', 1, NULL, NULL, 0.00, 158.00, true, '2025-10-21 08:32:22.300821', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00023', 'Mollete', '23', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.302006', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00024', 'Sándwich', '24', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 33.00, true, '2025-10-21 08:32:22.303006', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00025', 'Club Sándwich', '25', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 60.00, true, '2025-10-21 08:32:22.303991', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00026', 'Cuernito Jamón con Queso', '26', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.304994', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00027', 'Torta', '27', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 38.00, true, '2025-10-21 08:32:22.306104', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00028', 'Huevos Sencillos', '28', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.306884', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00029', 'Huevos al Gusto', '29', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 63.00, true, '2025-10-21 08:32:22.307677', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00030', 'Huevos Tirados', '30', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 65.00, true, '2025-10-21 08:32:22.308418', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00031', 'Huevos Rancheros', '31', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 65.00, true, '2025-10-21 08:32:22.309125', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00032', 'Huevos Divorciados', '32', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 65.00, true, '2025-10-21 08:32:22.31227', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00033', 'Chilaquiles', '33', 'CHILAQUILES', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.312978', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00034', 'Chilaquiles Terrena', '34', 'CHILAQUILES', 1, NULL, NULL, 0.00, 85.00, true, '2025-10-21 08:32:22.313714', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00035', 'Enfrijoladas', '35', 'ENFRIJOLADAS', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.315071', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00036', 'Omelette Jamon & Tocino', '36', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 82.00, true, '2025-10-21 08:32:22.315983', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00037', 'Omelette Espinacas & Champiñón', '37', 'HUEVOS & OMELETTES', 1, NULL, NULL, 0.00, 85.00, true, '2025-10-21 08:32:22.316722', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00038', 'Hot Cakes', '38', 'HOT CAKES', 1, NULL, NULL, 0.00, 42.00, true, '2025-10-21 08:32:22.317505', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00039', 'Hot Cakes Terrena', '39', 'HOT CAKES', 1, NULL, NULL, 0.00, 58.00, true, '2025-10-21 08:32:22.318225', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00040', 'CÓCTEL DE FRUTAS', '40', 'CÓCTEL DE FRUTAS', 1, NULL, NULL, 0.00, 28.00, true, '2025-10-21 08:32:22.318905', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00041', 'CÓCTEL PREPARADO', '41', 'CÓCTEL DE FRUTAS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.31961', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00042', 'Tacos de Guisado', '42', 'TACOS', 1, NULL, NULL, 0.00, 19.00, true, '2025-10-21 08:32:22.320314', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00043', 'Americano', '43', 'CAFÉ', 1, NULL, NULL, 0.00, 30.00, true, '2025-10-21 08:32:22.323725', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00044', 'Capuchino', '44', 'CAFÉ', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.325065', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00045', 'Espresso', '45', 'CAFÉ', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.326335', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00046', 'Espresso Cortado', '46', 'CAFÉ', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.327931', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00047', 'Latte', '47', 'CAFÉ', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.329003', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00048', 'Latte Sabor', '48', 'CAFÉ', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.329949', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00049', 'Matcha Latte', '49', 'CAFÉ', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.33101', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00050', 'CHAI LATTE', '50', 'CAFÉ', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.332171', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00052', 'Té Manzana con Especias', '52', 'CHOCOLATE & TÉS', 1, NULL, NULL, 0.00, 30.00, true, '2025-10-21 08:32:22.333879', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00053', 'Té (Sabores)', '53', 'CHOCOLATE & TÉS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.334885', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00054', 'Jugo Naranja', '54', 'JUGOS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.336392', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00055', 'Jugo Zanahoria', '55', 'JUGOS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.338163', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00056', 'Jugo Verde', '56', 'JUGOS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.339041', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00057', 'Malteada', '57', 'MALTEADAS & LICUADOS', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.339678', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00058', 'Licuado', '58', 'MALTEADAS & LICUADOS', 1, NULL, NULL, 0.00, 38.00, true, '2025-10-21 08:32:22.340469', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00059', 'Chocomilk', '59', 'MALTEADAS & LICUADOS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.341331', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00060', 'Agua Embotellada 1 L', '60', 'REFRESCANTES', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:32:22.341942', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00061', 'Agua Embotellada 500 ML', '61', 'REFRESCANTES', 1, NULL, NULL, 0.00, 10.00, true, '2025-10-21 08:32:22.342658', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00062', 'Mineral 600 ml', '62', 'REFRESCANTES', 1, NULL, NULL, 0.00, 22.00, true, '2025-10-21 08:32:22.343434', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00063', 'Mineral Twist 600 ml', '63', 'REFRESCANTES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.344121', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00064', 'Topo Chico 600 ml', '64', 'REFRESCANTES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.345516', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00065', 'Electrolit', '65', 'REFRESCANTES', 1, NULL, NULL, 0.00, 30.00, true, '2025-10-21 08:32:22.34892', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00066', 'Agua de Sabor', '66', 'REFRESCANTES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.349658', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00067', 'Limonada', '67', 'REFRESCANTES', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.350401', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00068', 'Naranjada', '68', 'REFRESCANTES', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.351231', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00069', 'Cheesecake Frambuesa', '69', 'POSTRES', 1, NULL, NULL, 0.00, 40.00, true, '2025-10-21 08:32:22.352249', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00070', 'Cheesecake Tortuga', '70', 'POSTRES', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.353263', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00071', 'Chocoflan', '71', 'POSTRES', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.354221', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00072', 'Galleta Chispas', '72', 'POSTRES', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:32:22.355476', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00073', 'Gelatina con Yogurt', '73', 'POSTRES', 1, NULL, NULL, 0.00, 16.00, true, '2025-10-21 08:32:22.356791', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00003', 'Taco Dorado', '3', 'TACOS', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:32:22.277575', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00004', 'Tostada', '4', 'ANTOJITOS', 1, NULL, NULL, 0.00, 33.00, true, '2025-10-21 08:32:22.279167', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00080', 'MALANGA', '80', 'SNACKS', 1, NULL, NULL, 0.00, 28.00, true, '2025-10-21 08:32:22.36378', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00081', 'Papas', '81', 'SNACKS', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.364878', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00090', 'CHICLES CH', '90', 'SNACKS', 1, NULL, NULL, 0.00, 2.00, true, '2025-10-21 08:32:22.373049', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00091', 'GALLETA MASAFINA', '91', 'SNACKS', 1, NULL, NULL, 0.00, 6.00, true, '2025-10-21 08:32:22.37365', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00092', 'SEMILLAS HORNEADAS', '92', 'SNACKS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.374317', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00093', 'PALOMITAS', '93', 'SNACKS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.375089', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00100', 'Tacos de Canasta', '100', 'TACOS', 1, NULL, NULL, 0.00, 39.00, true, '2025-10-21 08:32:22.383447', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00101', 'Baguette Español', '101', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.38437', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00102', 'Baguette Jamón Pavo', '102', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.385328', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00103', 'Baguette Pastor con Queso', '103', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.38613', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00104', 'Super Hot Dog', '104', 'SÁNDWICHES & TORTAS', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.386877', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00105', 'Ice Latte', '105', 'ICE', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.387674', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00106', 'Ice Latte Sabor', '106', 'ICE', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.388423', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00107', 'Ice Latte Chai', '107', 'ICE', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.389112', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00108', 'Ice Latte Taro', '108', 'ICE', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.389852', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00109', 'Ice Latte Matcha', '109', 'ICE', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.39055', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00110', 'Naj Frappe Sabor', '110', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.391261', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00111', 'Chai Frappe', '111', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.394028', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00112', 'Matcha Frappe', '112', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.394921', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00113', 'Taro Frappe', '113', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 55.00, true, '2025-10-21 08:32:22.395893', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00114', 'Horchata Café', '114', 'MALTEADAS & LICUADOS', 1, NULL, NULL, 0.00, 40.00, true, '2025-10-21 08:32:22.396823', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00115', 'Smoothies', '115', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.397706', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00116', 'Soda Italiana', '116', 'FRAPPE / MOOTIES & SODAS', 1, NULL, NULL, 0.00, 50.00, true, '2025-10-21 08:32:22.398597', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00118', 'PAN MUERTO', '118', 'POSTRES', 1, NULL, NULL, 0.00, 48.00, true, '2025-10-21 08:32:22.399396', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00119', 'LILY GALLETAS', '119', 'SNACKS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.40601', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00120', 'TERMO CH', '120', 'SNACKS', 1, NULL, NULL, 0.00, 110.00, true, '2025-10-21 08:32:22.413188', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00121', 'TERMO GD', '121', 'SNACKS', 1, NULL, NULL, 0.00, 280.00, true, '2025-10-21 08:32:22.414244', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00122', 'BARRA DASAVENA', '122', 'SNACKS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.415441', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00123', 'RISE KRISPIES', '123', 'SNACKS', 1, NULL, NULL, 0.00, 10.00, true, '2025-10-21 08:32:22.416732', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00124', 'MAKU AGUA', '124', 'REFRESCANTES', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.417538', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00125', 'TAMALES', '125', 'ANTOJITOS', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:32:22.418367', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00001', 'Relleno Empanada · Pollo', 'MOD-00001', 'Relleno Empanada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00002', 'Relleno Empanada · Picadillo', 'MOD-00002', 'Relleno Empanada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00003', 'Relleno Empanada · Queso', 'MOD-00003', 'Relleno Empanada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00004', 'Relleno Taco Dorado · Pollo', 'MOD-00004', 'Relleno Taco Dorado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00005', 'Relleno Taco Dorado · Papa', 'MOD-00005', 'Relleno Taco Dorado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00006', 'Topping Tostada · Pollo', 'MOD-00006', 'Topping Tostada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00007', 'Topping Tostada · Jamón', 'MOD-00007', 'Topping Tostada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00008', 'Tortilla Quesadilla · Maíz', 'MOD-00008', 'Tortilla Quesadilla', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00009', 'Tortilla Quesadilla · Harina', 'MOD-00009', 'Tortilla Quesadilla', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00010', 'Proteína Quesadilla · Jamón', 'MOD-00010', 'Proteína Quesadilla', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00002', 'Picada', '2', 'ANTOJITOS', 1, NULL, NULL, 0.00, 38.00, true, '2025-10-21 08:32:22.264089', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00010', 'Enchiladas Terrena', '10', 'ENCHILADAS & ENMOLADAS', 1, NULL, NULL, 0.00, 85.00, true, '2025-10-21 08:32:22.287448', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00015', 'Pasta Boloñesa', '15', 'SOPAS & PASTAS & MENU', 1, NULL, NULL, 0.00, 82.00, true, '2025-10-21 08:32:22.292994', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00051', 'Chocolatito', '51', 'CHOCOLATE & TÉS', 1, NULL, NULL, 0.00, 40.00, true, '2025-10-21 08:32:22.333064', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00074', 'Muffin', '74', 'POSTRES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.357909', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00075', 'Pastel Chocolate Matilda', '75', 'POSTRES', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.359795', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00076', 'Pastel Zanahoria', '76', 'POSTRES', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.360664', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00077', 'Pay Limón', '77', 'POSTRES', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.361655', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00078', 'Limonada Mineral', '78', 'REFRESCANTES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.362439', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00079', 'Naranjada Mineral', '79', 'REFRESCANTES', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.363133', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00082', 'Platanos', '82', 'SNACKS', 1, NULL, NULL, 0.00, 25.00, true, '2025-10-21 08:32:22.365627', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00083', 'Halls', '83', 'MISELANEOS', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:32:22.366261', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00084', 'KIRLAND BARRA PROTEINA', '84', 'SNACKS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.366844', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00085', 'GREEN MOUNTAIN BARRA', '85', 'SNACKS', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.367776', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00086', 'MENU DEL DIA ', '86', 'SOPAS & PASTAS & MENU', 1, NULL, NULL, 0.00, 65.00, true, '2025-10-21 08:32:22.369218', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00087', 'CACAHUATE HORNEADO', '87', 'SNACKS', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:32:22.370029', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00088', 'Trident XtraCare', '88', 'MISELANEOS', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:32:22.371543', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00094', 'MAKU', '94', NULL, 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:32:22.375842', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00095', 'Chilaquiles Baby', '95', 'CHILAQUILES', 1, NULL, NULL, 0.00, 40.00, true, '2025-10-21 08:32:22.376483', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00096', 'Chilaquiles Baby Pastor', '96', 'CHILAQUILES', 1, NULL, NULL, 0.00, 40.00, true, '2025-10-21 08:32:22.377109', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00097', 'Quesadilla de Jamón', '97', 'TACOS', 1, NULL, NULL, 0.00, 28.00, true, '2025-10-21 08:32:22.377717', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00098', 'Quesadilla de Pastor', '98', 'TACOS', 1, NULL, NULL, 0.00, 35.00, true, '2025-10-21 08:32:22.378359', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00099', 'Taco Pastor', '99', 'TACOS', 1, NULL, NULL, 0.00, 19.00, true, '2025-10-21 08:32:22.38278', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-00089', 'Lechero', '89', 'CAFÉ', 1, NULL, NULL, 0.00, 45.00, true, '2025-10-21 08:32:22.372336', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00011', 'Proteína Quesadilla · Chorizo', 'MOD-00011', 'Proteína Quesadilla', 1, NULL, NULL, 0.00, 3.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00012', 'Proteína Quesadilla · Pastor', 'MOD-00012', 'Proteína Quesadilla', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00013', 'Proteína Quesadilla · Champiñones', 'MOD-00013', 'Proteína Quesadilla', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00014', 'Salsa Picada · Verde', 'MOD-00014', 'Salsa Picada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00015', 'Salsa Picada · Roja', 'MOD-00015', 'Salsa Picada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00016', 'Salsa Picada · Chileseco', 'MOD-00016', 'Salsa Picada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00017', 'Salsa Picada · Frijoles', 'MOD-00017', 'Salsa Picada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00018', 'Proteína Picada · Sencilla', 'MOD-00018', 'Proteína Picada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00019', 'Proteína Picada · Huevo', 'MOD-00019', 'Proteína Picada', 1, NULL, NULL, 0.00, 17.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00020', 'Proteína Picada · Pollo', 'MOD-00020', 'Proteína Picada', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00021', 'Proteína Picada · Chorizo', 'MOD-00021', 'Proteína Picada', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00022', 'Proteína Picada Terrena · Milanesa', 'MOD-00022', 'Proteína Picada Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00023', 'Proteína Picada Terrena · Cecina', 'MOD-00023', 'Proteína Picada Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00024', 'Proteína Picada Terrena · Pechuga', 'MOD-00024', 'Proteína Picada Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00025', 'Proteína Picada Terrena · Chorizo', 'MOD-00025', 'Proteína Picada Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00026', 'Proteína Picada Terrena · Arrachera', 'MOD-00026', 'Proteína Picada Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00027', 'Salsa Enchiladas · Roja', 'MOD-00027', 'Salsa Enchiladas', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00028', 'Salsa Enchiladas · Verde', 'MOD-00028', 'Salsa Enchiladas', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00029', 'Proteína Enchiladas Rellenas · Sencillas', 'MOD-00029', 'Proteína Enchiladas Rellenas', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00030', 'Proteína Enchiladas Rellenas · Pollo', 'MOD-00030', 'Proteína Enchiladas Rellenas', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00031', 'Proteína Enchiladas Rellenas · Huevo', 'MOD-00031', 'Proteína Enchiladas Rellenas', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00032', 'Proteína Enchiladas Rellenas · Jamón', 'MOD-00032', 'Proteína Enchiladas Rellenas', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00033', 'Proteína Enchiladas Rellenas · Queso de Hebra', 'MOD-00033', 'Proteína Enchiladas Rellenas', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00034', 'Proteína Enchiladas Terrena · Milanesa', 'MOD-00034', 'Proteína Enchiladas Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00035', 'Proteína Enchiladas Terrena · Pechuga', 'MOD-00035', 'Proteína Enchiladas Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00036', 'Proteína Enchiladas Terrena · Cecina', 'MOD-00036', 'Proteína Enchiladas Terrena', 1, NULL, NULL, 0.00, 10.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00037', 'Proteína Enchiladas Terrena · Arrachera', 'MOD-00037', 'Proteína Enchiladas Terrena', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00038', 'Proteína Enmoladas Rellenas · Pollo', 'MOD-00038', 'Proteína Enmoladas Rellenas', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00039', 'Proteína Enmoladas Rellenas · Huevo', 'MOD-00039', 'Proteína Enmoladas Rellenas', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00040', 'Proteína Enmoladas Rellenas · Jamón', 'MOD-00040', 'Proteína Enmoladas Rellenas', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00041', 'Proteína Enmoladas Rellenas · Queso de Hebra', 'MOD-00041', 'Proteína Enmoladas Rellenas', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00042', 'Proteína Tampiqueña · Pechuga', 'MOD-00042', 'Proteína Tampiqueña', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00043', 'Proteína Tampiqueña · Cecina', 'MOD-00043', 'Proteína Tampiqueña', 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00044', 'Proteína Tampiqueña · Arrachera', 'MOD-00044', 'Proteína Tampiqueña', 1, NULL, NULL, 0.00, 30.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00045', 'Proteína Tampiqueña · Milanesa', 'MOD-00045', 'Proteína Tampiqueña', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00046', 'Huevos – Tipo · Estrellado', 'MOD-00046', 'Huevos – Tipo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00047', 'Huevos – Tipo · Revuelto', 'MOD-00047', 'Huevos – Tipo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00048', 'Huevos – Término · Tierno', 'MOD-00048', 'Huevos – Término', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00049', 'Huevos – Término · Medio', 'MOD-00049', 'Huevos – Término', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00050', 'Huevos – Término · Cocido', 'MOD-00050', 'Huevos – Término', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00051', 'Proteína Enfrijoladas · Sencillas', 'MOD-00051', 'Proteína Enfrijoladas', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00052', 'Proteína Enfrijoladas · Pollo', 'MOD-00052', 'Proteína Enfrijoladas', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00053', 'Proteína Enfrijoladas · Chorizo', 'MOD-00053', 'Proteína Enfrijoladas', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00054', 'Proteína Enfrijoladas · Huevo', 'MOD-00054', 'Proteína Enfrijoladas', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00055', 'Salsa Chilaquiles · Roja', 'MOD-00055', 'Salsa Chilaquiles', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00056', 'Salsa Chilaquiles · Verde', 'MOD-00056', 'Salsa Chilaquiles', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00057', 'Salsa Chilaquiles · Mole', 'MOD-00057', 'Salsa Chilaquiles', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00058', 'Proteína Chilaquiles · Huevo', 'MOD-00058', 'Proteína Chilaquiles', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00059', 'Proteína Chilaquiles · Pollo', 'MOD-00059', 'Proteína Chilaquiles', 1, NULL, NULL, 0.00, 15.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00060', 'Proteína Chilaquiles · Jamón', 'MOD-00060', 'Proteína Chilaquiles', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00061', 'Proteína Chilaquiles · Queso de Hebra', 'MOD-00061', 'Proteína Chilaquiles', 1, NULL, NULL, 0.00, 18.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00062', 'Proteína Chilaquiles Terrena · Milanesa', 'MOD-00062', 'Proteína Chilaquiles Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00063', 'Proteína Chilaquiles Terrena · Pechuga', 'MOD-00063', 'Proteína Chilaquiles Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00064', 'Proteína Chilaquiles Terrena · Pastor', 'MOD-00064', 'Proteína Chilaquiles Terrena', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00065', 'Proteína Chilaquiles Terrena · Cecina', 'MOD-00065', 'Proteína Chilaquiles Terrena', 1, NULL, NULL, 0.00, 10.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00066', 'Proteína Chilaquiles Terrena · Arrachera', 'MOD-00066', 'Proteína Chilaquiles Terrena', 1, NULL, NULL, 0.00, 13.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00067', 'Topping Hot Cakes · Lechera', 'MOD-00067', 'Topping Hot Cakes', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00068', 'Topping Hot Cakes · Cajeta', 'MOD-00068', 'Topping Hot Cakes', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00069', 'Topping Hot Cakes · Maple', 'MOD-00069', 'Topping Hot Cakes', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00070', 'Topping Hot Cakes · Mermelada de Fresa', 'MOD-00070', 'Topping Hot Cakes', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00071', 'Proteína Mollete · Sencillo', 'MOD-00071', 'Proteína Mollete', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00072', 'Proteína Mollete · Chorizo', 'MOD-00072', 'Proteína Mollete', 1, NULL, NULL, 0.00, 7.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00073', 'Proteína Mollete · Jamón y Queso', 'MOD-00073', 'Proteína Mollete', 1, NULL, NULL, 0.00, 7.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00074', 'Proteína Sándwich · Jamón y Queso', 'MOD-00074', 'Proteína Sándwich', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00075', 'Proteína Sándwich · Pollo', 'MOD-00075', 'Proteína Sándwich', 1, NULL, NULL, 0.00, 2.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00076', 'Proteína Sándwich · Pierna', 'MOD-00076', 'Proteína Sándwich', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00077', 'Proteína Sándwich · Atún', 'MOD-00077', 'Proteína Sándwich', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00078', 'Proteína Torta · Milanesa', 'MOD-00078', 'Proteína Torta', 1, NULL, NULL, 0.00, 7.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00079', 'Proteína Torta · Pierna', 'MOD-00079', 'Proteína Torta', 1, NULL, NULL, 0.00, 7.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00080', 'Proteína Torta · Jamón y Queso', 'MOD-00080', 'Proteína Torta', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00081', 'Proteína Torta · Pollo', 'MOD-00081', 'Proteína Torta', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00082', 'Proteína Torta · Choriqueso', 'MOD-00082', 'Proteína Torta', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00083', 'Proteína Torta · Huevo', 'MOD-00083', 'Proteína Torta', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00084', 'Proteína Torta · Chilaquiles', 'MOD-00084', 'Proteína Torta', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00087', 'Carga extra Café · Carga extra Café', 'MOD-00087', 'Carga extra Café', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00088', 'Sabor Malteada · Chocolate', 'MOD-00088', 'Sabor Malteada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00089', 'Sabor Malteada · Vainilla', 'MOD-00089', 'Sabor Malteada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:57', '2025-10-21 08:03:57');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00090', 'Sabor Licuado · Choco-Plátano', 'MOD-00090', 'Sabor Licuado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00091', 'Sabor Licuado · Plátano', 'MOD-00091', 'Sabor Licuado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00092', 'Sabor Licuado · Fresa', 'MOD-00092', 'Sabor Licuado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00093', 'Sabor Licuado · Frutos rojos', 'MOD-00093', 'Sabor Licuado', 1, NULL, NULL, 0.00, 4.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00094', 'Sabor Muffin · Chocolate', 'MOD-00094', 'Sabor Muffin', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00095', 'Sabor Muffin · Vainilla', 'MOD-00095', 'Sabor Muffin', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00096', 'Opción Tampiqueña · 2 Picadas', 'MOD-00096', 'Opción Tampiqueña', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00097', 'Opción Tampiqueña · 2 Enchiladas', 'MOD-00097', 'Opción Tampiqueña', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00098', 'Opción Tampiqueña · 2 Enmoladas', 'MOD-00098', 'Opción Tampiqueña', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00099', 'Proteína Huevo · Jamón', 'MOD-00099', 'Proteína Huevo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00100', 'Proteína Huevo · Chorizo', 'MOD-00100', 'Proteína Huevo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00101', 'Proteína Huevo · A la Mexicana', 'MOD-00101', 'Proteína Huevo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00102', 'Proteína Huevo · Tocino', 'MOD-00102', 'Proteína Huevo', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00103', 'Guarnición Omelette · Ensalada', 'MOD-00103', 'Guarnición Omelette', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00104', 'Guarnición Omelette · Verduras', 'MOD-00104', 'Guarnición Omelette', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00105', 'Guarnición Omelette · Fruta', 'MOD-00105', 'Guarnición Omelette', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00106', 'Guarnición Omelette · Frijoles', 'MOD-00106', 'Guarnición Omelette', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00107', 'Tacos de Guisado · Papa con Chorizo', 'MOD-00107', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00108', 'Tacos de Guisado · Milanesa', 'MOD-00108', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00109', 'Tacos de Guisado · Pastor', 'MOD-00109', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00110', 'Tacos de Guisado · Pollo', 'MOD-00110', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00111', 'Tacos de Guisado · Mexicana', 'MOD-00111', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00112', 'Tacos de Guisado · Molida', 'MOD-00112', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00113', 'Tacos de Guisado · Costilla', 'MOD-00113', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00114', 'Tacos de Guisado · Huevo con Jamon', 'MOD-00114', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00115', 'Tacos de Guisado · Huevo con Chorizo', 'MOD-00115', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00116', 'Tacos de Guisado · Rajas', 'MOD-00116', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00117', 'Tacos de Guisado · Salchicha', 'MOD-00117', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00118', 'Tacos de Guisado · Carnitas', 'MOD-00118', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00119', 'Tacos de Guisado · Chuleta', 'MOD-00119', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00120', 'Tacos de Guisado · Huevo en Salsa', 'MOD-00120', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00121', 'Tacos de Guisado · Chicharron', 'MOD-00121', 'Tacos de Guisado', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00122', 'Proteína Enmoladas Rellenas · Sencilla', 'MOD-00122', 'Proteína Enmoladas Rellenas', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00123', 'Sabor Latte · Caramelo', 'MOD-00123', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00124', 'Sabor Latte · Cookies & Cream', 'MOD-00124', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00125', 'Sabor Latte · Crema de Avellana', 'MOD-00125', 'Sabor Latte', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00126', 'Sabor Latte · Crema Irlandesa', 'MOD-00126', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00127', 'Sabor Latte · Moka', 'MOD-00127', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00128', 'Sabor Latte · Vainilla', 'MOD-00128', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00129', 'Sabor Chai Latte · Vainilla', 'MOD-00129', 'Sabor Chai Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00130', 'Sabor Chai Latte · Negro', 'MOD-00130', 'Sabor Chai Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00131', 'Sabor Chai Latte · Verde', 'MOD-00131', 'Sabor Chai Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00132', 'Opción Limonada / Naranjada · Natrural', 'MOD-00132', 'Opción Limonada / Naranjada', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00133', 'Opción Limonada / Naranjada · Mineral', 'MOD-00133', 'Opción Limonada / Naranjada', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00134', 'Salsas Boneless · BBQ', 'MOD-00134', 'Salsas Boneless', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00135', 'Salsas Boneless · Búfalo', 'MOD-00135', 'Salsas Boneless', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00136', 'Salsas Boneless · Mango-Habanero', 'MOD-00136', 'Salsas Boneless', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00137', 'Salsas Boneless · Parmesano', 'MOD-00137', 'Salsas Boneless', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00138', 'Sabor malanga · Habanero', 'MOD-00138', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00139', 'Sabor malanga · Chipotle', 'MOD-00139', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00140', 'Sabor malanga · Fuego', 'MOD-00140', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00141', 'Sabor malanga · Jalapeño', 'MOD-00141', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00142', 'Sabor malanga · Especias', 'MOD-00142', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00143', 'Sabor malanga · Adobadas', 'MOD-00143', 'Sabor malanga', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00144', 'Mora azul', 'MOD-00144', NULL, 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00145', 'Fresa kiwi', 'MOD-00145', NULL, 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00146', 'Naranja mandarina', 'MOD-00146', NULL, 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00147', 'Ponche de frutas', 'MOD-00147', NULL, 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00148', 'Uva', 'MOD-00148', NULL, 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00150', 'Proteína Chilaquiles · Sencillos', 'MOD-00150', 'Proteína Chilaquiles', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00151', 'Sabor electrolit · Fresa-Kiwi', 'MOD-00151', 'Sabor electrolit', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00152', 'Sabor electrolit · Naranja-Mandarina', 'MOD-00152', 'Sabor electrolit', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00153', 'Sabor electrolit · Ponche de Frutas', 'MOD-00153', 'Sabor electrolit', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00154', 'Sabor electrolit · Fresa', 'MOD-00154', 'Sabor electrolit', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00155', 'Sabor electrolit · Mora-Azul', 'MOD-00155', 'Sabor electrolit', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00156', 'CACAHUATES HORNEADOS  · C SALADO', 'MOD-00156', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00157', 'CACAHUATES HORNEADOS  · C NATURAL', 'MOD-00157', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00158', 'CACAHUATES HORNEADOS  · C SAL Y LIMON', 'MOD-00158', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00159', 'CACAHUATES HORNEADOS  · C JALAPEÑO', 'MOD-00159', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00160', 'CACAHUATES HORNEADOS  · C QUEXO', 'MOD-00160', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00161', 'CACAHUATES HORNEADOS  · C HABANERO AMARILLO', 'MOD-00161', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00162', 'CACAHUATES HORNEADOS  · C HABANERO VERDE ', 'MOD-00162', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00163', 'CACAHUATES HORNEADOS  · C TOREADOS ', 'MOD-00163', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00164', 'CACAHUATES HORNEADOS  · C AJO CON CHILE ', 'MOD-00164', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00165', 'CACAHUATES HORNEADOS  · C AL AJO ', 'MOD-00165', 'CACAHUATES HORNEADOS ', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00166', 'Trident Sabor · Freshmint', 'MOD-00166', 'Trident Sabor', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00167', 'Trident Sabor · Menta', 'MOD-00167', 'Trident Sabor', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00168', 'MAKU', 'MOD-00168', NULL, 1, NULL, NULL, 0.00, 20.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00169', 'Proteína Torta · Pastor con Queso', 'MOD-00169', 'Proteína Torta', 1, NULL, NULL, 0.00, 7.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00170', 'Sabor Latte · Moka Blanco', 'MOD-00170', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00171', 'Sabor Latte · Oreo', 'MOD-00171', 'Sabor Latte', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00172', 'Sabor Smoothies · Fresa', 'MOD-00172', 'Sabor Smoothies', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00173', 'Sabor Smoothies · Mango', 'MOD-00173', 'Sabor Smoothies', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00174', 'Sabor Smoothies · Piña', 'MOD-00174', 'Sabor Smoothies', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00175', 'Sabor Smoothies · Mora Azul', 'MOD-00175', 'Sabor Smoothies', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00176', 'Sabor Smoothies · Kiwi', 'MOD-00176', 'Sabor Smoothies', 1, NULL, NULL, 0.00, 5.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00177', 'Sabor Soda Italiana · Cereza', 'MOD-00177', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00178', 'Sabor Soda Italiana · Fresa', 'MOD-00178', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00179', 'Sabor Soda Italiana · Sandia', 'MOD-00179', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00180', 'Sabor Soda Italiana · Arandanos', 'MOD-00180', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00181', 'Sabor Soda Italiana · Manzana Verde', 'MOD-00181', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00182', 'Sabor Soda Italiana · Mora Azul', 'MOD-00182', 'Sabor Soda Italiana', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00183', 'PAN MUERTO · JAMON Y TOCINO', 'MOD-00183', 'PAN MUERTO', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00184', 'PAN MUERTO · QUESO Y ZARZAMORA', 'MOD-00184', 'PAN MUERTO', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');
INSERT INTO receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) VALUES ('REC-MOD-00185', 'PAN MUERTO · NUTELLA Y NUEZ', 'MOD-00185', 'PAN MUERTO', 1, NULL, NULL, 0.00, 0.00, true, '2025-10-21 08:03:58', '2025-10-21 08:03:58');


--
-- TOC entry 4200 (class 0 OID 92397)
-- Dependencies: 464
-- Data for Name: receta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4383 (class 0 OID 0)
-- Dependencies: 402
-- Name: receta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_det_id_seq', 1, false);


--
-- TOC entry 4384 (class 0 OID 0)
-- Dependencies: 403
-- Name: receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_id_seq', 1, false);


--
-- TOC entry 4201 (class 0 OID 92408)
-- Dependencies: 465
-- Data for Name: receta_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4385 (class 0 OID 0)
-- Dependencies: 404
-- Name: receta_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_insumo_id_seq', 1, false);


--
-- TOC entry 4202 (class 0 OID 92411)
-- Dependencies: 466
-- Data for Name: receta_shadow; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4386 (class 0 OID 0)
-- Dependencies: 405
-- Name: receta_shadow_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_shadow_id_seq', 1, false);


--
-- TOC entry 4203 (class 0 OID 92424)
-- Dependencies: 467
-- Data for Name: receta_version; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (1, 'REC-00002', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.275689');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (2, 'REC-00003', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.278547');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (3, 'REC-00004', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.280079');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (4, 'REC-00005', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.281543');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (5, 'REC-00006', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.282884');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (6, 'REC-00007', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.284167');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (7, 'REC-00008', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.285304');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (8, 'REC-00009', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.286795');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (9, 'REC-00010', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.288383');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (10, 'REC-00011', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.289572');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (11, 'REC-00012', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.290306');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (12, 'REC-00013', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.291332');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (13, 'REC-00014', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.292616');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (14, 'REC-00015', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.293878');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (15, 'REC-00016', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.295049');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (16, 'REC-00017', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.29615');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (17, 'REC-00018', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.297103');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (18, 'REC-00019', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.298393');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (19, 'REC-00020', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.299332');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (20, 'REC-00021', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.300463');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (21, 'REC-00022', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.301494');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (22, 'REC-00023', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.302588');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (23, 'REC-00024', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.303573');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (24, 'REC-00025', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.304471');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (25, 'REC-00026', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.305784');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (26, 'REC-00027', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.306579');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (27, 'REC-00028', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.307365');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (28, 'REC-00029', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.308129');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (29, 'REC-00030', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.308851');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (30, 'REC-00031', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.309569');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (31, 'REC-00032', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.312703');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (32, 'REC-00033', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.313405');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (33, 'REC-00034', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.314529');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (34, 'REC-00035', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.315682');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (35, 'REC-00036', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.316447');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (36, 'REC-00037', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.317192');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (37, 'REC-00038', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.317951');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (38, 'REC-00039', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.318644');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (39, 'REC-00040', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.319332');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (40, 'REC-00041', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.320036');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (41, 'REC-00042', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.321757');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (42, 'REC-00043', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.324594');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (43, 'REC-00044', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.325846');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (44, 'REC-00045', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.32741');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (45, 'REC-00046', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.328563');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (46, 'REC-00047', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.329635');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (47, 'REC-00048', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.330421');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (48, 'REC-00049', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.331756');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (49, 'REC-00050', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.332715');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (50, 'REC-00051', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.333551');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (51, 'REC-00052', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.334389');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (52, 'REC-00053', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.335824');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (53, 'REC-00054', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.337518');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (54, 'REC-00055', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.338722');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (55, 'REC-00056', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.33943');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (56, 'REC-00057', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.340207');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (57, 'REC-00058', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.341085');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (58, 'REC-00059', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.341715');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (59, 'REC-00060', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.342315');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (60, 'REC-00061', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.343088');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (61, 'REC-00062', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.343829');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (62, 'REC-00063', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.34449');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (63, 'REC-00064', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.346038');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (64, 'REC-00065', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.349397');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (65, 'REC-00066', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.35008');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (66, 'REC-00067', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.350811');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (67, 'REC-00068', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.351733');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (68, 'REC-00069', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.352875');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (69, 'REC-00070', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.353849');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (70, 'REC-00071', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.354789');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (71, 'REC-00072', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.356269');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (72, 'REC-00073', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.357489');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (73, 'REC-00074', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.359495');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (74, 'REC-00075', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.360182');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (75, 'REC-00076', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.36126');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (76, 'REC-00077', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.362142');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (77, 'REC-00078', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.362844');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (78, 'REC-00079', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.363528');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (79, 'REC-00080', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.364526');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (80, 'REC-00081', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.365354');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (81, 'REC-00082', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.36602');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (82, 'REC-00083', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.366617');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (83, 'REC-00084', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.367258');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (84, 'REC-00085', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.368852');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (85, 'REC-00086', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.369709');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (86, 'REC-00087', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.370469');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (87, 'REC-00088', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.371991');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (88, 'REC-00089', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.372786');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (89, 'REC-00090', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.373419');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (90, 'REC-00091', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.374063');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (91, 'REC-00092', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.3747');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (92, 'REC-00093', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.375575');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (93, 'REC-00094', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.37622');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (94, 'REC-00095', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.376853');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (95, 'REC-00096', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.377484');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (96, 'REC-00097', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.378089');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (97, 'REC-00098', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.378912');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (98, 'REC-00099', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.383193');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (99, 'REC-00100', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.383824');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (100, 'REC-00101', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.384979');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (101, 'REC-00102', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.385818');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (102, 'REC-00103', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.386593');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (103, 'REC-00104', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.387339');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (104, 'REC-00105', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.388131');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (105, 'REC-00106', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.388845');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (106, 'REC-00107', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.389574');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (107, 'REC-00108', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.390277');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (108, 'REC-00109', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.390982');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (109, 'REC-00110', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.39374');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (110, 'REC-00111', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.39447');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (111, 'REC-00112', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.395478');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (112, 'REC-00113', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.396519');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (113, 'REC-00114', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.397314');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (114, 'REC-00115', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.398305');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (115, 'REC-00116', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.399046');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (116, 'REC-00118', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.400246');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (117, 'REC-00119', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.406557');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (118, 'REC-00120', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.413696');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (119, 'REC-00121', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.414911');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (120, 'REC-00122', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.416338');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (121, 'REC-00123', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.41724');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (122, 'REC-00124', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.41808');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (123, 'REC-00125', 1, 'Versión generada automáticamente desde Floreant POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:32:22.41882');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (124, 'REC-MOD-00001', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (125, 'REC-MOD-00002', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (126, 'REC-MOD-00003', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (127, 'REC-MOD-00004', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (128, 'REC-MOD-00005', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (129, 'REC-MOD-00006', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (130, 'REC-MOD-00007', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (131, 'REC-MOD-00008', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (132, 'REC-MOD-00009', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (133, 'REC-MOD-00010', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (134, 'REC-MOD-00011', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (135, 'REC-MOD-00012', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (136, 'REC-MOD-00013', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (137, 'REC-MOD-00014', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (138, 'REC-MOD-00015', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (139, 'REC-MOD-00016', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (140, 'REC-MOD-00017', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (141, 'REC-MOD-00018', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (142, 'REC-MOD-00019', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (143, 'REC-MOD-00020', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (144, 'REC-MOD-00021', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (145, 'REC-MOD-00022', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (146, 'REC-MOD-00023', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (147, 'REC-MOD-00024', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (148, 'REC-MOD-00025', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (149, 'REC-MOD-00026', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (150, 'REC-MOD-00027', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (151, 'REC-MOD-00028', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (152, 'REC-MOD-00029', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (153, 'REC-MOD-00030', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (154, 'REC-MOD-00031', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (155, 'REC-MOD-00032', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (156, 'REC-MOD-00033', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (157, 'REC-MOD-00034', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (158, 'REC-MOD-00035', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (159, 'REC-MOD-00036', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (160, 'REC-MOD-00037', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (161, 'REC-MOD-00038', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (162, 'REC-MOD-00039', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (163, 'REC-MOD-00040', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (164, 'REC-MOD-00041', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (165, 'REC-MOD-00042', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (166, 'REC-MOD-00043', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (167, 'REC-MOD-00044', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (168, 'REC-MOD-00045', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (169, 'REC-MOD-00046', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (170, 'REC-MOD-00047', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (171, 'REC-MOD-00048', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (172, 'REC-MOD-00049', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (173, 'REC-MOD-00050', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (174, 'REC-MOD-00051', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (175, 'REC-MOD-00052', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (176, 'REC-MOD-00053', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (177, 'REC-MOD-00054', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (178, 'REC-MOD-00055', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (179, 'REC-MOD-00056', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (180, 'REC-MOD-00057', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (181, 'REC-MOD-00058', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (182, 'REC-MOD-00059', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (183, 'REC-MOD-00060', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (184, 'REC-MOD-00061', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (185, 'REC-MOD-00062', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (186, 'REC-MOD-00063', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (187, 'REC-MOD-00064', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (188, 'REC-MOD-00065', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (189, 'REC-MOD-00066', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (190, 'REC-MOD-00067', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (191, 'REC-MOD-00068', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (192, 'REC-MOD-00069', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (193, 'REC-MOD-00070', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (194, 'REC-MOD-00071', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (195, 'REC-MOD-00072', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (196, 'REC-MOD-00073', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (197, 'REC-MOD-00074', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (198, 'REC-MOD-00075', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (199, 'REC-MOD-00076', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (200, 'REC-MOD-00077', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (201, 'REC-MOD-00078', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (202, 'REC-MOD-00079', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (203, 'REC-MOD-00080', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (204, 'REC-MOD-00081', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (205, 'REC-MOD-00082', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (206, 'REC-MOD-00083', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (207, 'REC-MOD-00084', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (208, 'REC-MOD-00087', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (209, 'REC-MOD-00088', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (210, 'REC-MOD-00089', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:57');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (211, 'REC-MOD-00090', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (212, 'REC-MOD-00091', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (213, 'REC-MOD-00092', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (214, 'REC-MOD-00093', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (215, 'REC-MOD-00094', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (216, 'REC-MOD-00095', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (217, 'REC-MOD-00096', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (218, 'REC-MOD-00097', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (219, 'REC-MOD-00098', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (220, 'REC-MOD-00099', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (221, 'REC-MOD-00100', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (222, 'REC-MOD-00101', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (223, 'REC-MOD-00102', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (224, 'REC-MOD-00103', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (225, 'REC-MOD-00104', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (226, 'REC-MOD-00105', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (227, 'REC-MOD-00106', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (228, 'REC-MOD-00107', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (229, 'REC-MOD-00108', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (230, 'REC-MOD-00109', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (231, 'REC-MOD-00110', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (232, 'REC-MOD-00111', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (233, 'REC-MOD-00112', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (234, 'REC-MOD-00113', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (235, 'REC-MOD-00114', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (236, 'REC-MOD-00115', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (237, 'REC-MOD-00116', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (238, 'REC-MOD-00117', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (239, 'REC-MOD-00118', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (240, 'REC-MOD-00119', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (241, 'REC-MOD-00120', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (242, 'REC-MOD-00121', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (243, 'REC-MOD-00122', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (244, 'REC-MOD-00123', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (245, 'REC-MOD-00124', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (246, 'REC-MOD-00125', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (247, 'REC-MOD-00126', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (248, 'REC-MOD-00127', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (249, 'REC-MOD-00128', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (250, 'REC-MOD-00129', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (251, 'REC-MOD-00130', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (252, 'REC-MOD-00131', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (253, 'REC-MOD-00132', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (254, 'REC-MOD-00133', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (255, 'REC-MOD-00134', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (256, 'REC-MOD-00135', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (257, 'REC-MOD-00136', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (258, 'REC-MOD-00137', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (259, 'REC-MOD-00138', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (260, 'REC-MOD-00139', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (261, 'REC-MOD-00140', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (262, 'REC-MOD-00141', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (263, 'REC-MOD-00142', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (264, 'REC-MOD-00143', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (265, 'REC-MOD-00144', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (266, 'REC-MOD-00145', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (267, 'REC-MOD-00146', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (268, 'REC-MOD-00147', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (269, 'REC-MOD-00148', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (270, 'REC-MOD-00150', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (271, 'REC-MOD-00151', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (272, 'REC-MOD-00152', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (273, 'REC-MOD-00153', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (274, 'REC-MOD-00154', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (275, 'REC-MOD-00155', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (276, 'REC-MOD-00156', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (277, 'REC-MOD-00157', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (278, 'REC-MOD-00158', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (279, 'REC-MOD-00159', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (280, 'REC-MOD-00160', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (281, 'REC-MOD-00161', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (282, 'REC-MOD-00162', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (283, 'REC-MOD-00163', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (284, 'REC-MOD-00164', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (285, 'REC-MOD-00165', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (286, 'REC-MOD-00166', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (287, 'REC-MOD-00167', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (288, 'REC-MOD-00168', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (289, 'REC-MOD-00169', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (290, 'REC-MOD-00170', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (291, 'REC-MOD-00171', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (292, 'REC-MOD-00172', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (293, 'REC-MOD-00173', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (294, 'REC-MOD-00174', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (295, 'REC-MOD-00175', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (296, 'REC-MOD-00176', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (297, 'REC-MOD-00177', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (298, 'REC-MOD-00178', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (299, 'REC-MOD-00179', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (300, 'REC-MOD-00180', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (301, 'REC-MOD-00181', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (302, 'REC-MOD-00182', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (303, 'REC-MOD-00183', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (304, 'REC-MOD-00184', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');
INSERT INTO receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) VALUES (305, 'REC-MOD-00185', 1, 'Placeholder auto-generado para modificador POS', '2025-10-21', false, NULL, NULL, '2025-10-21 08:03:58');


--
-- TOC entry 4387 (class 0 OID 0)
-- Dependencies: 406
-- Name: receta_version_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_version_id_seq', 305, true);


--
-- TOC entry 4245 (class 0 OID 94364)
-- Dependencies: 554
-- Data for Name: recipe_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4388 (class 0 OID 0)
-- Dependencies: 553
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_history_id_seq', 1, false);


--
-- TOC entry 4243 (class 0 OID 94355)
-- Dependencies: 552
-- Data for Name: recipe_version_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4389 (class 0 OID 0)
-- Dependencies: 551
-- Name: recipe_version_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_version_items_id_seq', 1, false);


--
-- TOC entry 4241 (class 0 OID 94341)
-- Dependencies: 550
-- Data for Name: recipe_versions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4390 (class 0 OID 0)
-- Dependencies: 549
-- Name: recipe_versions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_versions_id_seq', 1, false);


--
-- TOC entry 4204 (class 0 OID 92433)
-- Dependencies: 468
-- Data for Name: rol; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4391 (class 0 OID 0)
-- Dependencies: 407
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('rol_id_seq', 1, false);


--
-- TOC entry 4205 (class 0 OID 92439)
-- Dependencies: 469
-- Data for Name: role_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4206 (class 0 OID 92442)
-- Dependencies: 470
-- Data for Name: roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4392 (class 0 OID 0)
-- Dependencies: 408
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('roles_id_seq', 1, false);


--
-- TOC entry 4393 (class 0 OID 0)
-- Dependencies: 545
-- Name: seq_cat_codigo; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('seq_cat_codigo', 1, false);


--
-- TOC entry 4107 (class 0 OID 90345)
-- Dependencies: 371
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
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (75, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-16 07:07:00.991373-05', NULL, 'ACTIVA', 1000.00, NULL, NULL, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (76, 'ENTRADA', 401, 'Terminal 401', 8, '2025-10-16 10:02:43.681-05', NULL, 'ACTIVA', 1210.00, NULL, 259, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (78, 'PRINCIPAL', 101, '101', 6, '2025-10-16 09:03:55.646781-05', '2025-10-16 19:42:31.452-05', 'LISTO_PARA_CORTE', 2500.00, 7140.80, 261, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (77, 'PRINCIPAL', 102, '102', 8, '2025-10-16 09:02:43.794352-05', '2025-10-16 20:02:46.819-05', 'LISTO_PARA_CORTE', 2500.00, 8295.00, 262, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (81, 'PRINCIPAL', 101, '101', 6, '2025-10-17 09:09:49.931669-05', '2025-10-17 18:55:33.029-05', 'LISTO_PARA_CORTE', 2500.00, 4823.20, 265, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (79, 'PRINCIPAL', 102, '102', 6, '2025-10-17 08:47:06.451915-05', '2025-10-17 17:55:32.974294-05', 'LISTO_PARA_CORTE', 2500.00, 8582.00, NULL, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (80, 'PRINCIPAL', 102, '102', 6, '2025-10-17 10:09:49.867-05', '2025-10-17 17:55:32.974294-05', 'LISTO_PARA_CORTE', 2564.00, 8582.00, 264, true);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (13, '', 9939, '9939', 1, '2025-09-22 15:58:44.147496-05', '2025-10-20 12:40:00.873-05', 'LISTO_PARA_CORTE', 0.00, 90.00, 267, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (82, '', 9939, '9939', 1, '2025-10-20 12:40:31.623507-05', '2025-10-20 14:17:14.731-05', 'LISTO_PARA_CORTE', 500.00, 553.00, 269, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (83, '', 9939, '9939', 1, '2025-10-20 14:17:23.602981-05', '2025-10-20 14:17:42.97-05', 'LISTO_PARA_CORTE', 500.05, 500.05, 271, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (85, '', 9939, '9939', 1, '2025-10-20 14:43:01.938724-05', '2025-10-20 14:43:59.767-05', 'LISTO_PARA_CORTE', 500.00, 522.00, 275, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (84, '', 9939, '9939', 1, '2025-10-20 14:17:47.876369-05', '2025-10-20 14:42:57.083-05', 'CERRADA', 500.00, 500.00, 273, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (86, '', 9939, '9939', 1, '2025-10-20 15:47:40.199604-05', '2025-10-20 15:53:17.82-05', 'CERRADA', 233.00, 283.00, 277, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (87, '', 9939, '9939', 1, '2025-10-20 16:05:09.669902-05', '2025-10-20 16:10:00.956-05', 'CERRADA', 100.00, 150.00, 279, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (88, '', 9939, '9939', 1, '2025-10-20 18:34:39.759763-05', '2025-10-21 01:33:23.641-05', 'LISTO_PARA_CORTE', 500.00, 1108.80, 281, false);
INSERT INTO sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) VALUES (89, 'SelemTI', 9939, '9939', 1, '2025-10-21 01:33:34.944314-05', NULL, 'ACTIVA', 200.00, NULL, NULL, false);


--
-- TOC entry 4394 (class 0 OID 0)
-- Dependencies: 372
-- Name: sesion_cajon_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('sesion_cajon_id_seq', 89, true);


--
-- TOC entry 4207 (class 0 OID 92448)
-- Dependencies: 471
-- Data for Name: sessions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('7wtHfkpLvOGg1bTVJKZ6NTUOBDgDYb2fvB1SCdSN', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiRVhFZk9jMzFtRTdCN013OFFRYk5rcHQ5UWFhMXVQdlI5S1VnWE5TdiI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6Mzk6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvcmVjaXBlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1761066952);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('es5gvKuSUronNReIKrb5HNeFJOXeLlNb1YPo6GsT', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiMlhhOEFxVG9GNHdOaGlmdXc5a0JtVXBwNjVHTmlZMXMxZjhPUG52dSI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1761104136);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('QmJz0VnSLysZuGOqHhnIhgrRaaMux28GE14lxLF4', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoicGdISTBBdmJVUUNpajB5ZFBzT1NOa1JDMmdrTlVmS3RCMzNjMFpHayI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NzA6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvY2F0YWxvZ29zL3VuaWRhZGVzP2NhdGVnb3JpYT1DVUxJTkFSSU8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1761066952);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('nUF7NirZWGEEp4K86XlECuVQ7YFsXGbxExQJ4tP6', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiY3VzU0gwWDlva1NjWDQzanNvMUhyTEZwWkJ0MWdGR1lQcFZaeGZ4UyI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDc6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvaW52ZW50b3J5L2l0ZW1zIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1761078497);


--
-- TOC entry 4208 (class 0 OID 92454)
-- Dependencies: 472
-- Data for Name: stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4395 (class 0 OID 0)
-- Dependencies: 409
-- Name: stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('stock_policy_id_seq', 1, false);


--
-- TOC entry 4209 (class 0 OID 92464)
-- Dependencies: 473
-- Data for Name: sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4210 (class 0 OID 92471)
-- Dependencies: 474
-- Data for Name: sucursal_almacen_terminal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4396 (class 0 OID 0)
-- Dependencies: 410
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sucursal_almacen_terminal_id_seq', 1, false);


--
-- TOC entry 4211 (class 0 OID 92479)
-- Dependencies: 475
-- Data for Name: ticket_det_consumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4397 (class 0 OID 0)
-- Dependencies: 411
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_det_consumo_id_seq', 1, false);


--
-- TOC entry 4212 (class 0 OID 92487)
-- Dependencies: 476
-- Data for Name: ticket_venta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4398 (class 0 OID 0)
-- Dependencies: 412
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_cab_id_seq', 1, false);


--
-- TOC entry 4213 (class 0 OID 92495)
-- Dependencies: 477
-- Data for Name: ticket_venta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4399 (class 0 OID 0)
-- Dependencies: 413
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_det_id_seq', 1, false);


--
-- TOC entry 4214 (class 0 OID 92505)
-- Dependencies: 478
-- Data for Name: traspaso_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4400 (class 0 OID 0)
-- Dependencies: 414
-- Name: traspaso_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_cab_id_seq', 1, false);


--
-- TOC entry 4215 (class 0 OID 92512)
-- Dependencies: 479
-- Data for Name: traspaso_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4401 (class 0 OID 0)
-- Dependencies: 415
-- Name: traspaso_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_det_id_seq', 1, false);


--
-- TOC entry 4216 (class 0 OID 92515)
-- Dependencies: 480
-- Data for Name: unidad_medida; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4402 (class 0 OID 0)
-- Dependencies: 416
-- Name: unidad_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidad_medida_id_seq', 1, false);


--
-- TOC entry 4217 (class 0 OID 92525)
-- Dependencies: 481
-- Data for Name: unidades_medida; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (4, 'KG', 'Kilogramo', 'PESO', 'METRICO', true, 1.000000, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (5, 'GR', 'Gramo', 'PESO', 'METRICO', false, 0.001000, 1, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (6, 'MG', 'Miligramo', 'PESO', 'METRICO', false, 0.000001, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (7, 'TON', 'Tonelada', 'PESO', 'METRICO', false, 1000.000000, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (8, 'LB', 'Libra', 'PESO', 'IMPERIAL', false, 0.453592, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (9, 'OZ', 'Onza', 'PESO', 'IMPERIAL', false, 0.028350, 2, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (10, 'LT', 'Litro', 'VOLUMEN', 'METRICO', true, 1.000000, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (11, 'ML', 'Mililitro', 'VOLUMEN', 'METRICO', false, 0.001000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (12, 'MC', 'Metro Cúbico', 'VOLUMEN', 'METRICO', false, 1000.000000, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (13, 'GAL', 'Galón', 'VOLUMEN', 'IMPERIAL', false, 3.785410, 3, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (14, 'FLOZ', 'Onza Fluida', 'VOLUMEN', 'IMPERIAL', false, 0.029574, 2, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (15, 'TAZA', 'Taza', 'VOLUMEN', 'CULINARIO', false, 0.240000, 2, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (16, 'CDTA', 'Cucharadita', 'VOLUMEN', 'CULINARIO', false, 0.005000, 1, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (17, 'CDSP', 'Cucharada Sopera', 'VOLUMEN', 'CULINARIO', false, 0.015000, 1, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (18, 'PZ', 'Pieza', 'UNIDAD', 'METRICO', true, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (19, 'PAQ', 'Paquete', 'UNIDAD', 'METRICO', false, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (20, 'CAJA', 'Caja', 'UNIDAD', 'METRICO', false, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (21, 'COST', 'Costal', 'UNIDAD', 'METRICO', false, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (22, 'PORC', 'Porción', 'UNIDAD', 'CULINARIO', false, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (23, 'PLAT', 'Plato', 'UNIDAD', 'CULINARIO', false, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (24, 'MIN', 'Minuto', 'TIEMPO', 'METRICO', true, 1.000000, 0, '2025-10-21 01:36:13');
INSERT INTO unidades_medida (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) VALUES (25, 'HR', 'Hora', 'TIEMPO', 'METRICO', false, 60.000000, 2, '2025-10-21 01:36:13');


--
-- TOC entry 4403 (class 0 OID 0)
-- Dependencies: 417
-- Name: unidades_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidades_medida_id_seq', 25, true);


--
-- TOC entry 4218 (class 0 OID 92536)
-- Dependencies: 482
-- Data for Name: uom_conversion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4404 (class 0 OID 0)
-- Dependencies: 418
-- Name: uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('uom_conversion_id_seq', 1, false);


--
-- TOC entry 4219 (class 0 OID 92541)
-- Dependencies: 483
-- Data for Name: user_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4220 (class 0 OID 92546)
-- Dependencies: 484
-- Data for Name: users; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4405 (class 0 OID 0)
-- Dependencies: 419
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 1, false);


--
-- TOC entry 4221 (class 0 OID 92562)
-- Dependencies: 485
-- Data for Name: usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--



--
-- TOC entry 4406 (class 0 OID 0)
-- Dependencies: 420
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('usuario_id_seq', 1, false);


--
-- TOC entry 3837 (class 2606 OID 94400)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 3835 (class 2606 OID 94390)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 3571 (class 2606 OID 92630)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 3540 (class 2606 OID 90680)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 3573 (class 2606 OID 92632)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 3575 (class 2606 OID 92634)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 3579 (class 2606 OID 92636)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 3577 (class 2606 OID 92638)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 3793 (class 2606 OID 93947)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 3795 (class 2606 OID 93940)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 3797 (class 2606 OID 93956)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 3799 (class 2606 OID 93958)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 3789 (class 2606 OID 93931)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 3791 (class 2606 OID 93929)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 3581 (class 2606 OID 94009)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 3583 (class 2606 OID 92640)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 3803 (class 2606 OID 93978)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 3805 (class 2606 OID 93966)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 3585 (class 2606 OID 92642)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 3587 (class 2606 OID 92644)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 3589 (class 2606 OID 92646)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 3591 (class 2606 OID 92648)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 3593 (class 2606 OID 92650)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 3597 (class 2606 OID 92652)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3599 (class 2606 OID 92654)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 3542 (class 2606 OID 90682)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 3601 (class 2606 OID 92656)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3605 (class 2606 OID 92658)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3608 (class 2606 OID 92660)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 3610 (class 2606 OID 92662)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3613 (class 2606 OID 92664)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3615 (class 2606 OID 92666)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3619 (class 2606 OID 92668)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 3617 (class 2606 OID 92670)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 3807 (class 2606 OID 93997)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 3809 (class 2606 OID 93990)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 3623 (class 2606 OID 92672)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 3813 (class 2606 OID 94294)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 3815 (class 2606 OID 94290)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 3817 (class 2606 OID 94292)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 3819 (class 2606 OID 94314)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 3626 (class 2606 OID 92674)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 3821 (class 2606 OID 94331)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 3631 (class 2606 OID 92676)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 3634 (class 2606 OID 92678)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 3636 (class 2606 OID 92680)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3638 (class 2606 OID 92682)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 3643 (class 2606 OID 92684)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 3645 (class 2606 OID 92686)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 3647 (class 2606 OID 92688)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3650 (class 2606 OID 92690)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 3653 (class 2606 OID 92692)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 3655 (class 2606 OID 92694)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 3657 (class 2606 OID 92696)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 3667 (class 2606 OID 92698)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 3669 (class 2606 OID 92700)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3671 (class 2606 OID 92702)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3673 (class 2606 OID 92704)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3675 (class 2606 OID 92706)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 3677 (class 2606 OID 92708)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 3679 (class 2606 OID 92710)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 3681 (class 2606 OID 92712)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 3684 (class 2606 OID 92714)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3686 (class 2606 OID 92716)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 3688 (class 2606 OID 92718)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3693 (class 2606 OID 92720)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 3547 (class 2606 OID 90684)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 3558 (class 2606 OID 90686)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 3562 (class 2606 OID 90688)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 3552 (class 2606 OID 90690)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 3695 (class 2606 OID 92722)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 3697 (class 2606 OID 92724)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3699 (class 2606 OID 92726)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3701 (class 2606 OID 92728)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3707 (class 2606 OID 92730)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 3709 (class 2606 OID 92732)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3703 (class 2606 OID 92734)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 3711 (class 2606 OID 92736)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3715 (class 2606 OID 92738)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3717 (class 2606 OID 92740)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, insumo_id);


--
-- TOC entry 3705 (class 2606 OID 92742)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 3719 (class 2606 OID 92744)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 3723 (class 2606 OID 92746)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 3725 (class 2606 OID 92748)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 3833 (class 2606 OID 94374)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3830 (class 2606 OID 94360)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3826 (class 2606 OID 94351)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 3727 (class 2606 OID 92750)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 3729 (class 2606 OID 92752)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 3731 (class 2606 OID 92754)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 3733 (class 2606 OID 92756)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 3735 (class 2606 OID 92758)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3567 (class 2606 OID 90692)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 3569 (class 2606 OID 90694)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 3738 (class 2606 OID 92760)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3744 (class 2606 OID 92762)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 3749 (class 2606 OID 92764)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 3746 (class 2606 OID 92766)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 3754 (class 2606 OID 92768)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 3757 (class 2606 OID 92770)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 3759 (class 2606 OID 92772)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3761 (class 2606 OID 92774)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3763 (class 2606 OID 92776)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 3765 (class 2606 OID 92778)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 3767 (class 2606 OID 92780)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 3769 (class 2606 OID 92782)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 3771 (class 2606 OID 92784)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 3773 (class 2606 OID 92786)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 3775 (class 2606 OID 92788)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 3777 (class 2606 OID 92790)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 3549 (class 2606 OID 90696)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 3555 (class 2606 OID 92792)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 3779 (class 2606 OID 92794)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 3781 (class 2606 OID 92796)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3783 (class 2606 OID 92798)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 3785 (class 2606 OID 92800)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 3787 (class 2606 OID 92802)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 3611 (class 1259 OID 93178)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 3620 (class 1259 OID 93179)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 3621 (class 1259 OID 93180)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 3658 (class 1259 OID 93181)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 3659 (class 1259 OID 93182)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 3810 (class 1259 OID 94066)
-- Name: idx_mv_dashboard_formas_pago_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_formas_pago_pk ON mv_dashboard_formas_pago USING btree (fecha, sucursal_id, codigo_fp);


--
-- TOC entry 3811 (class 1259 OID 94075)
-- Name: idx_mv_dashboard_resumen_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_resumen_pk ON mv_dashboard_resumen USING btree (fecha, sucursal_id);


--
-- TOC entry 3682 (class 1259 OID 93183)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 3689 (class 1259 OID 94014)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 3545 (class 1259 OID 93184)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 3556 (class 1259 OID 93185)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 3559 (class 1259 OID 93186)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 3550 (class 1259 OID 90724)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 3800 (class 1259 OID 94217)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 3801 (class 1259 OID 94218)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 3720 (class 1259 OID 93187)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 3563 (class 1259 OID 93188)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 3740 (class 1259 OID 93189)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 3741 (class 1259 OID 93190)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 3747 (class 1259 OID 93191)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 3750 (class 1259 OID 93192)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 3751 (class 1259 OID 93193)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 3752 (class 1259 OID 93194)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 3755 (class 1259 OID 93195)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 3838 (class 1259 OID 94401)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 3543 (class 1259 OID 93196)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 3602 (class 1259 OID 93197)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva DESC);


--
-- TOC entry 3606 (class 1259 OID 93198)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 3624 (class 1259 OID 93199)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 3627 (class 1259 OID 94220)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 3628 (class 1259 OID 94219)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 3822 (class 1259 OID 94332)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 3823 (class 1259 OID 94334)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 3824 (class 1259 OID 94333)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 3594 (class 1259 OID 93200)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 3595 (class 1259 OID 93201)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 3640 (class 1259 OID 93202)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 3641 (class 1259 OID 93203)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (insumo_id);


--
-- TOC entry 3660 (class 1259 OID 93204)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 3661 (class 1259 OID 93205)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 3662 (class 1259 OID 93206)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 3663 (class 1259 OID 93207)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 3664 (class 1259 OID 93208)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 3665 (class 1259 OID 93209)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 3690 (class 1259 OID 93210)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 3691 (class 1259 OID 93211)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 3560 (class 1259 OID 90725)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 3831 (class 1259 OID 94375)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 3712 (class 1259 OID 93212)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (insumo_id);


--
-- TOC entry 3713 (class 1259 OID 93213)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 3721 (class 1259 OID 93214)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 3828 (class 1259 OID 94361)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 3564 (class 1259 OID 90726)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 3565 (class 1259 OID 90727)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 3742 (class 1259 OID 93215)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 3639 (class 1259 OID 93216)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 3648 (class 1259 OID 93217)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 3651 (class 1259 OID 93218)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 3553 (class 1259 OID 90728)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 3736 (class 1259 OID 93219)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 3739 (class 1259 OID 93220)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 3544 (class 1259 OID 90729)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 3603 (class 1259 OID 93221)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 3629 (class 1259 OID 94213)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 3632 (class 1259 OID 94308)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 3827 (class 1259 OID 94352)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


--
-- TOC entry 3929 (class 2620 OID 94298)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 3928 (class 2620 OID 94316)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 3931 (class 2620 OID 94404)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 3930 (class 2620 OID 94336)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 3924 (class 2620 OID 93831)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 3925 (class 2620 OID 93832)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 3926 (class 2620 OID 93833)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 3927 (class 2620 OID 93834)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


--
-- TOC entry 3843 (class 2606 OID 92803)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 3844 (class 2606 OID 92808)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 3919 (class 2606 OID 93941)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 3920 (class 2606 OID 93972)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 3921 (class 2606 OID 93967)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 3845 (class 2606 OID 92813)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 3847 (class 2606 OID 92818)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3846 (class 2606 OID 92823)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3849 (class 2606 OID 92828)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3848 (class 2606 OID 92833)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3908 (class 2606 OID 92838)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3850 (class 2606 OID 92843)
-- Name: hist_cost_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3851 (class 2606 OID 92848)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3852 (class 2606 OID 92853)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3853 (class 2606 OID 92858)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3856 (class 2606 OID 92863)
-- Name: insumo_presentacion_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3855 (class 2606 OID 92868)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3854 (class 2606 OID 92873)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3922 (class 2606 OID 93998)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 3923 (class 2606 OID 93991)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 3857 (class 2606 OID 92878)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3859 (class 2606 OID 92883)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3858 (class 2606 OID 92888)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3860 (class 2606 OID 94299)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3863 (class 2606 OID 92893)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3862 (class 2606 OID 92898)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3861 (class 2606 OID 92903)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3864 (class 2606 OID 92908)
-- Name: lote_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3868 (class 2606 OID 92913)
-- Name: merma_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3867 (class 2606 OID 92918)
-- Name: merma_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 3866 (class 2606 OID 92923)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3865 (class 2606 OID 92928)
-- Name: merma_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 3869 (class 2606 OID 92933)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 3870 (class 2606 OID 92938)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 3871 (class 2606 OID 92943)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 3873 (class 2606 OID 92948)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3872 (class 2606 OID 92953)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3878 (class 2606 OID 92958)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3877 (class 2606 OID 92963)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 3876 (class 2606 OID 92968)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3875 (class 2606 OID 92973)
-- Name: op_cab_usuario_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES usuario(id);


--
-- TOC entry 3874 (class 2606 OID 92978)
-- Name: op_cab_usuario_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES usuario(id);


--
-- TOC entry 3881 (class 2606 OID 92983)
-- Name: op_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3880 (class 2606 OID 92988)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3879 (class 2606 OID 92993)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3882 (class 2606 OID 92998)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3883 (class 2606 OID 93003)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3886 (class 2606 OID 93008)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3885 (class 2606 OID 93013)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3884 (class 2606 OID 93018)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3839 (class 2606 OID 91367)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 3841 (class 2606 OID 91372)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 3842 (class 2606 OID 91377)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 3840 (class 2606 OID 91382)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 3887 (class 2606 OID 93023)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 3889 (class 2606 OID 93028)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 3888 (class 2606 OID 93033)
-- Name: recepcion_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 3894 (class 2606 OID 93038)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES bodega(id);


--
-- TOC entry 3893 (class 2606 OID 93043)
-- Name: recepcion_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3892 (class 2606 OID 93048)
-- Name: recepcion_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 3891 (class 2606 OID 93053)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3890 (class 2606 OID 93058)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3896 (class 2606 OID 93063)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3895 (class 2606 OID 93068)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3898 (class 2606 OID 93073)
-- Name: receta_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3897 (class 2606 OID 93078)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3899 (class 2606 OID 93083)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 3901 (class 2606 OID 93088)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 3900 (class 2606 OID 93093)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 3902 (class 2606 OID 93098)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3905 (class 2606 OID 93103)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 3904 (class 2606 OID 93108)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 3903 (class 2606 OID 93113)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida(id);


--
-- TOC entry 3907 (class 2606 OID 93118)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 3906 (class 2606 OID 93123)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 3911 (class 2606 OID 93128)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 3910 (class 2606 OID 93133)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 3909 (class 2606 OID 93138)
-- Name: traspaso_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 3915 (class 2606 OID 93143)
-- Name: traspaso_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 3914 (class 2606 OID 93148)
-- Name: traspaso_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 3913 (class 2606 OID 93153)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 3912 (class 2606 OID 93158)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3917 (class 2606 OID 93163)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3916 (class 2606 OID 93168)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida(id);


--
-- TOC entry 3918 (class 2606 OID 93173)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 4232 (class 0 OID 94058)
-- Dependencies: 533 4251
-- Name: mv_dashboard_formas_pago; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_formas_pago;


--
-- TOC entry 4233 (class 0 OID 94067)
-- Dependencies: 534 4232 4251
-- Name: mv_dashboard_resumen; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_resumen;


--
-- TOC entry 4338 (class 0 OID 0)
-- Dependencies: 515
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-10-21 22:16:09

--
-- PostgreSQL database dump complete
--

