--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-10-30 13:24:00

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
-- TOC entry 1502 (class 1247 OID 91389)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1505 (class 1247 OID 91394)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1508 (class 1247 OID 91402)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1511 (class 1247 OID 91408)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1514 (class 1247 OID 91414)
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
-- TOC entry 1517 (class 1247 OID 91432)
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
-- TOC entry 2028 (class 1247 OID 102913)
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
-- TOC entry 1520 (class 1247 OID 91442)
-- Name: producto_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE producto_tipo OWNER TO postgres;

--
-- TOC entry 735 (class 1255 OID 93223)
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
-- TOC entry 761 (class 1255 OID 94403)
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
-- TOC entry 769 (class 1255 OID 94315)
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
-- TOC entry 777 (class 1255 OID 94871)
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
    SET estado = ''CONFIRMADO'',
        requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = ''PENDIENTE'';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = false,
        procesado = true,
        fecha_proceso = now(),
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, ''CONFIRM'', NULL);
END;
';


ALTER FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 718 (class 1255 OID 89732)
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
-- TOC entry 737 (class 1255 OID 93225)
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
-- TOC entry 775 (class 1255 OID 94870)
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
-- TOC entry 736 (class 1255 OID 93224)
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
-- TOC entry 677 (class 1255 OID 94297)
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
-- TOC entry 746 (class 1255 OID 93226)
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
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 746
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 772 (class 1255 OID 94338)
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
-- TOC entry 770 (class 1255 OID 94335)
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
-- TOC entry 719 (class 1255 OID 89733)
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
-- TOC entry 747 (class 1255 OID 93227)
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
-- TOC entry 5340 (class 0 OID 0)
-- Dependencies: 747
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 748 (class 1255 OID 93228)
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
-- TOC entry 5341 (class 0 OID 0)
-- Dependencies: 748
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 749 (class 1255 OID 93229)
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
-- TOC entry 5342 (class 0 OID 0)
-- Dependencies: 749
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 693 (class 1255 OID 89734)
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
-- TOC entry 773 (class 1255 OID 94376)
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
-- TOC entry 680 (class 1255 OID 94402)
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
-- TOC entry 731 (class 1255 OID 89735)
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
-- TOC entry 762 (class 1255 OID 94872)
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
    SET estado = ''ANULADO'',
        requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = ''CONFIRMADO'';

    UPDATE selemti.inv_consumo_pos_det
    SET requiere_reproceso = true,
        procesado = false,
        fecha_proceso = NULL,
        updated_at = now()
    WHERE consumo_id IN (
        SELECT id FROM selemti.inv_consumo_pos WHERE ticket_id = _ticket_id
    );

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, ''REVERSE'', NULL);
END;
';


ALTER FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 732 (class 1255 OID 89736)
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
-- TOC entry 733 (class 1255 OID 89737)
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
-- TOC entry 734 (class 1255 OID 89738)
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
-- TOC entry 771 (class 1255 OID 94337)
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
-- TOC entry 750 (class 1255 OID 93230)
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
-- TOC entry 751 (class 1255 OID 93231)
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
-- TOC entry 752 (class 1255 OID 93232)
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
-- TOC entry 753 (class 1255 OID 93233)
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
-- TOC entry 759 (class 1255 OID 93234)
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
-- TOC entry 678 (class 1255 OID 102788)
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
-- TOC entry 774 (class 1255 OID 94377)
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
-- TOC entry 766 (class 1255 OID 102952)
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
-- TOC entry 776 (class 1255 OID 94873)
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
-- TOC entry 5343 (class 0 OID 0)
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
-- TOC entry 5344 (class 0 OID 0)
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
-- TOC entry 5345 (class 0 OID 0)
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
-- TOC entry 5346 (class 0 OID 0)
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
-- TOC entry 5347 (class 0 OID 0)
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
-- TOC entry 5348 (class 0 OID 0)
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
-- TOC entry 5349 (class 0 OID 0)
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
-- TOC entry 5350 (class 0 OID 0)
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
-- TOC entry 5351 (class 0 OID 0)
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
-- TOC entry 5352 (class 0 OID 0)
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
-- TOC entry 5353 (class 0 OID 0)
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
-- TOC entry 5354 (class 0 OID 0)
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
-- TOC entry 5355 (class 0 OID 0)
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
-- TOC entry 5356 (class 0 OID 0)
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
-- TOC entry 5357 (class 0 OID 0)
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
-- TOC entry 5358 (class 0 OID 0)
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
-- TOC entry 5359 (class 0 OID 0)
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
-- TOC entry 5360 (class 0 OID 0)
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
    updated_at timestamp(0) without time zone,
    is_exact boolean DEFAULT true NOT NULL,
    scope character varying(16) DEFAULT 'global'::character varying NOT NULL,
    notes text
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
-- TOC entry 5361 (class 0 OID 0)
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
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 426
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 5364 (class 0 OID 0)
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
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 375
-- Name: conciliacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conciliacion_id_seq OWNED BY conciliacion.id;


--
-- TOC entry 670 (class 1259 OID 102847)
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
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 670
-- Name: VIEW conversiones_unidad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW conversiones_unidad IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy conversiones_unidad';


--
-- TOC entry 427 (class 1259 OID 92096)
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
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 376
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE conversiones_unidad_id_seq OWNED BY conversiones_unidad_legacy.id;


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
-- TOC entry 5368 (class 0 OID 0)
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
-- TOC entry 5369 (class 0 OID 0)
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
-- TOC entry 5370 (class 0 OID 0)
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
-- TOC entry 5371 (class 0 OID 0)
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
-- TOC entry 5372 (class 0 OID 0)
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
-- TOC entry 5373 (class 0 OID 0)
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
-- TOC entry 5374 (class 0 OID 0)
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
-- TOC entry 5375 (class 0 OID 0)
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
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 384
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_presentacion_id_seq OWNED BY insumo_presentacion.id;


--
-- TOC entry 666 (class 1259 OID 102770)
-- Name: insumo_proveedor_presentacion; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE insumo_proveedor_presentacion (
    id bigint NOT NULL,
    insumo_id bigint NOT NULL,
    proveedor_id text NOT NULL,
    uom_compra_id integer NOT NULL,
    cantidad_en_uom_compra numeric(14,6) DEFAULT 1 NOT NULL,
    uom_base_id integer NOT NULL,
    factor_a_base numeric(20,10) DEFAULT 1 NOT NULL,
    precio_compra numeric(14,6),
    moneda character(3) DEFAULT 'MXN'::bpchar NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE insumo_proveedor_presentacion OWNER TO postgres;

--
-- TOC entry 665 (class 1259 OID 102768)
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
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 665
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE insumo_proveedor_presentacion_id_seq OWNED BY insumo_proveedor_presentacion.id;


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
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 571
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- TOC entry 5380 (class 0 OID 0)
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
-- TOC entry 5381 (class 0 OID 0)
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
-- TOC entry 5382 (class 0 OID 0)
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
-- TOC entry 5383 (class 0 OID 0)
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
-- TOC entry 5384 (class 0 OID 0)
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
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 436
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario con trazabilidad completa.';


--
-- TOC entry 5386 (class 0 OID 0)
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
-- TOC entry 5387 (class 0 OID 0)
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
-- TOC entry 5388 (class 0 OID 0)
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
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 588
-- Name: inventory_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE inventory_counts_id_seq OWNED BY inventory_counts.id;


--
-- TOC entry 672 (class 1259 OID 102938)
-- Name: inventory_snapshot; Type: TABLE; Schema: selemti; Owner: postgres
--

CREATE TABLE inventory_snapshot (
    snapshot_date date NOT NULL,
    branch_id text NOT NULL,
    item_id uuid NOT NULL,
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
-- TOC entry 5390 (class 0 OID 0)
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
-- TOC entry 5391 (class 0 OID 0)
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
-- TOC entry 5392 (class 0 OID 0)
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
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 438
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'Maestro de todos los productos/insumos del sistema.';


--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 438
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 438
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- TOC entry 5396 (class 0 OID 0)
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
-- TOC entry 5397 (class 0 OID 0)
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
-- TOC entry 5398 (class 0 OID 0)
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
-- TOC entry 5399 (class 0 OID 0)
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
-- TOC entry 5400 (class 0 OID 0)
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
-- TOC entry 5401 (class 0 OID 0)
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
-- TOC entry 5402 (class 0 OID 0)
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
-- TOC entry 5403 (class 0 OID 0)
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
-- TOC entry 5404 (class 0 OID 0)
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
-- TOC entry 5405 (class 0 OID 0)
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
-- TOC entry 5406 (class 0 OID 0)
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
-- TOC entry 5407 (class 0 OID 0)
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
-- TOC entry 5408 (class 0 OID 0)
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
-- TOC entry 5409 (class 0 OID 0)
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
-- TOC entry 5410 (class 0 OID 0)
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
-- TOC entry 5411 (class 0 OID 0)
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
-- TOC entry 5412 (class 0 OID 0)
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
-- TOC entry 5413 (class 0 OID 0)
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
-- TOC entry 5414 (class 0 OID 0)
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
-- TOC entry 5415 (class 0 OID 0)
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
-- TOC entry 5416 (class 0 OID 0)
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
-- TOC entry 5417 (class 0 OID 0)
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
-- TOC entry 5418 (class 0 OID 0)
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
-- TOC entry 671 (class 1259 OID 102921)
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
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 671
-- Name: TABLE pos_modifiers_map; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE pos_modifiers_map IS 'Mapa de modificadores POS → impacto en receta/costo/consumo.';


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
-- TOC entry 5420 (class 0 OID 0)
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
-- TOC entry 5421 (class 0 OID 0)
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
-- TOC entry 5422 (class 0 OID 0)
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
-- TOC entry 5423 (class 0 OID 0)
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
-- TOC entry 5424 (class 0 OID 0)
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
-- TOC entry 5425 (class 0 OID 0)
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
-- TOC entry 5426 (class 0 OID 0)
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
-- TOC entry 5427 (class 0 OID 0)
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
-- TOC entry 5428 (class 0 OID 0)
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
-- TOC entry 5429 (class 0 OID 0)
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
-- TOC entry 5430 (class 0 OID 0)
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
-- TOC entry 5431 (class 0 OID 0)
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
-- TOC entry 5432 (class 0 OID 0)
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
-- TOC entry 5433 (class 0 OID 0)
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
-- TOC entry 5434 (class 0 OID 0)
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
-- TOC entry 5435 (class 0 OID 0)
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
-- TOC entry 5436 (class 0 OID 0)
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
-- TOC entry 5437 (class 0 OID 0)
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
-- TOC entry 5438 (class 0 OID 0)
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
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.fecha_requerida IS 'Fecha
  límite operativa';


--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- TOC entry 5443 (class 0 OID 0)
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
-- TOC entry 5444 (class 0 OID 0)
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
-- TOC entry 5445 (class 0 OID 0)
-- Dependencies: 654
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- TOC entry 5446 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 654
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- TOC entry 5453 (class 0 OID 0)
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
-- TOC entry 5454 (class 0 OID 0)
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
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 652
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- TOC entry 5457 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- TOC entry 5458 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- TOC entry 5459 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- TOC entry 5460 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 5461 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 5462 (class 0 OID 0)
-- Dependencies: 652
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- TOC entry 5463 (class 0 OID 0)
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
-- TOC entry 5464 (class 0 OID 0)
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
-- TOC entry 5465 (class 0 OID 0)
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
-- TOC entry 5466 (class 0 OID 0)
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
-- TOC entry 5467 (class 0 OID 0)
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
-- TOC entry 5468 (class 0 OID 0)
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
-- TOC entry 5469 (class 0 OID 0)
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
-- TOC entry 5470 (class 0 OID 0)
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
-- TOC entry 5471 (class 0 OID 0)
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
-- TOC entry 5472 (class 0 OID 0)
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
-- TOC entry 5473 (class 0 OID 0)
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
-- TOC entry 5474 (class 0 OID 0)
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
-- TOC entry 5475 (class 0 OID 0)
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
-- TOC entry 5476 (class 0 OID 0)
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
-- TOC entry 5477 (class 0 OID 0)
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
-- TOC entry 5478 (class 0 OID 0)
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
-- TOC entry 5479 (class 0 OID 0)
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
-- TOC entry 5480 (class 0 OID 0)
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
-- TOC entry 5481 (class 0 OID 0)
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
-- TOC entry 5482 (class 0 OID 0)
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
-- TOC entry 5483 (class 0 OID 0)
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
-- TOC entry 5484 (class 0 OID 0)
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
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.item_id IS 'FK to items.id';


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 649
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.notas IS 'Notas del usuario';


--
-- TOC entry 5502 (class 0 OID 0)
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
-- TOC entry 5503 (class 0 OID 0)
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
-- TOC entry 5504 (class 0 OID 0)
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
-- TOC entry 5505 (class 0 OID 0)
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
-- TOC entry 5506 (class 0 OID 0)
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
-- TOC entry 5507 (class 0 OID 0)
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
-- TOC entry 5508 (class 0 OID 0)
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
-- TOC entry 5509 (class 0 OID 0)
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
-- TOC entry 5510 (class 0 OID 0)
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
-- TOC entry 5511 (class 0 OID 0)
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
-- TOC entry 5512 (class 0 OID 0)
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
-- TOC entry 5513 (class 0 OID 0)
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
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 656
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 656
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- TOC entry 5516 (class 0 OID 0)
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
-- TOC entry 5517 (class 0 OID 0)
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
-- TOC entry 5518 (class 0 OID 0)
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
-- TOC entry 5519 (class 0 OID 0)
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
-- TOC entry 5520 (class 0 OID 0)
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
-- TOC entry 5521 (class 0 OID 0)
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
-- TOC entry 5522 (class 0 OID 0)
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
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 415
-- Name: traspaso_det_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE traspaso_det_id_seq OWNED BY traspaso_det.id;


--
-- TOC entry 667 (class 1259 OID 102833)
-- Name: unidad_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW unidad_medida AS
 SELECT (cat_unidades.id)::integer AS id,
    cat_unidades.clave AS codigo,
    cat_unidades.nombre,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['KG'::character varying, 'G'::character varying, 'MG'::character varying, 'LB'::character varying, 'OZ'::character varying])::text[])) THEN 'PESO'::text
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['L'::character varying, 'ML'::character varying, 'M3'::character varying, 'FLOZ'::character varying, 'CUP'::character varying, 'TBSP'::character varying, 'TSP'::character varying])::text[])) THEN 'VOLUMEN'::text
            WHEN ((cat_unidades.clave)::text = 'PZ'::text) THEN 'UNIDAD'::text
            ELSE 'UNIDAD'::text
        END AS tipo,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['KG'::character varying, 'L'::character varying, 'PZ'::character varying])::text[])) THEN true
            ELSE false
        END AS es_base,
    1.0::numeric(14,6) AS factor_a_base,
    2 AS decimales
   FROM cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE unidad_medida OWNER TO postgres;

--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 667
-- Name: VIEW unidad_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidad_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidad_medida';


--
-- TOC entry 480 (class 1259 OID 92515)
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
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 416
-- Name: unidad_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidad_medida_id_seq OWNED BY unidad_medida_legacy.id;


--
-- TOC entry 668 (class 1259 OID 102838)
-- Name: unidades_medida; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW unidades_medida AS
 SELECT (cat_unidades.id)::integer AS id,
    cat_unidades.clave AS codigo,
    cat_unidades.nombre,
    (
        CASE
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['KG'::character varying, 'G'::character varying, 'MG'::character varying, 'LB'::character varying, 'OZ'::character varying])::text[])) THEN 'PESO'::text
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['L'::character varying, 'ML'::character varying, 'M3'::character varying, 'FLOZ'::character varying, 'CUP'::character varying, 'TBSP'::character varying, 'TSP'::character varying])::text[])) THEN 'VOLUMEN'::text
            WHEN ((cat_unidades.clave)::text = 'PZ'::text) THEN 'UNIDAD'::text
            ELSE 'UNIDAD'::text
        END)::character varying(10) AS tipo,
    (
        CASE
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['KG'::character varying, 'G'::character varying, 'MG'::character varying, 'L'::character varying, 'ML'::character varying, 'M3'::character varying])::text[])) THEN 'METRICO'::text
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['LB'::character varying, 'OZ'::character varying, 'FLOZ'::character varying])::text[])) THEN 'IMPERIAL'::text
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['CUP'::character varying, 'TBSP'::character varying, 'TSP'::character varying])::text[])) THEN 'CULINARIO'::text
            ELSE 'METRICO'::text
        END)::character varying(20) AS categoria,
        CASE
            WHEN ((cat_unidades.clave)::text = ANY ((ARRAY['KG'::character varying, 'L'::character varying, 'PZ'::character varying])::text[])) THEN true
            ELSE false
        END AS es_base,
    1.0::numeric(12,6) AS factor_conversion_base,
    2 AS decimales,
    cat_unidades.created_at
   FROM cat_unidades
  WHERE (cat_unidades.activo = true);


ALTER TABLE unidades_medida OWNER TO postgres;

--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 668
-- Name: VIEW unidades_medida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW unidades_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidades_medida con categoria';


--
-- TOC entry 481 (class 1259 OID 92525)
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
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 417
-- Name: unidades_medida_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE unidades_medida_id_seq OWNED BY unidades_medida_legacy.id;


--
-- TOC entry 669 (class 1259 OID 102843)
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
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 669
-- Name: VIEW uom_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW uom_conversion IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy uom_conversion';


--
-- TOC entry 482 (class 1259 OID 92536)
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
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 418
-- Name: uom_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE uom_conversion_id_seq OWNED BY uom_conversion_legacy.id;


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
-- TOC entry 5530 (class 0 OID 0)
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
-- TOC entry 5531 (class 0 OID 0)
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
-- TOC entry 5532 (class 0 OID 0)
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
-- TOC entry 5533 (class 0 OID 0)
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
     LEFT JOIN unidades_medida_legacy um ON ((um.id = i.unidad_medida_id)));


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
-- TOC entry 673 (class 1259 OID 102954)
-- Name: vw_inventory_snapshot_summary; Type: VIEW; Schema: selemti; Owner: postgres
--

CREATE VIEW vw_inventory_snapshot_summary AS
 SELECT inventory_snapshot.snapshot_date,
    inventory_snapshot.branch_id,
    inventory_snapshot.item_id,
    inventory_snapshot.teorico_qty,
    inventory_snapshot.fisico_qty,
    inventory_snapshot.teorico_cost,
    inventory_snapshot.valor_teorico,
    inventory_snapshot.variance_qty,
    inventory_snapshot.variance_cost
   FROM inventory_snapshot;


ALTER TABLE vw_inventory_snapshot_summary OWNER TO postgres;

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

--
-- TOC entry 4003 (class 2604 OID 94396)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 3999 (class 2604 OID 94383)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 4182 (class 2604 OID 102633)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- TOC entry 3706 (class 2604 OID 92570)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3748 (class 2604 OID 92571)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 4007 (class 2604 OID 94441)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_id_seq'::regclass);


--
-- TOC entry 4019 (class 2604 OID 94485)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('caja_fondo_adj_id_seq'::regclass);


--
-- TOC entry 4021 (class 2604 OID 94502)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_arqueo_id_seq'::regclass);


--
-- TOC entry 4012 (class 2604 OID 94463)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('caja_fondo_mov_id_seq'::regclass);


--
-- TOC entry 4077 (class 2604 OID 94805)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('cash_fund_arqueos_id_seq'::regclass);


--
-- TOC entry 4078 (class 2604 OID 94833)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('cash_fund_movement_audit_log_id_seq'::regclass);


--
-- TOC entry 4070 (class 2604 OID 94769)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('cash_fund_movements_id_seq'::regclass);


--
-- TOC entry 4066 (class 2604 OID 94744)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds ALTER COLUMN id SET DEFAULT nextval('cash_funds_id_seq'::regclass);


--
-- TOC entry 3972 (class 2604 OID 93937)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 3974 (class 2604 OID 93953)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 3970 (class 2604 OID 93926)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 3749 (class 2604 OID 92572)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 3976 (class 2604 OID 93964)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 3751 (class 2604 OID 92573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 3755 (class 2604 OID 92574)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3761 (class 2604 OID 92575)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3762 (class 2604 OID 92576)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3708 (class 2604 OID 92577)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3764 (class 2604 OID 92578)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 3768 (class 2604 OID 92579)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 3772 (class 2604 OID 92580)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3782 (class 2604 OID 92581)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3786 (class 2604 OID 92582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 3790 (class 2604 OID 92583)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 4184 (class 2604 OID 102773)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_proveedor_presentacion_id_seq'::regclass);


--
-- TOC entry 4023 (class 2604 OID 94519)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_id_seq'::regclass);


--
-- TOC entry 4028 (class 2604 OID 94531)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_det_id_seq'::regclass);


--
-- TOC entry 4080 (class 2604 OID 94862)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_log_id_seq'::regclass);


--
-- TOC entry 3979 (class 2604 OID 93984)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 3794 (class 2604 OID 92584)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 4053 (class 2604 OID 94659)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('inventory_count_lines_id_seq'::regclass);


--
-- TOC entry 4049 (class 2604 OID 94638)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts ALTER COLUMN id SET DEFAULT nextval('inventory_counts_id_seq'::regclass);


--
-- TOC entry 4064 (class 2604 OID 94727)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes ALTER COLUMN id SET DEFAULT nextval('inventory_wastes_id_seq'::regclass);


--
-- TOC entry 3984 (class 2604 OID 94284)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 3987 (class 2604 OID 94322)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 3829 (class 2604 OID 92585)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3834 (class 2604 OID 92586)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 4108 (class 2604 OID 94997)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles ALTER COLUMN id SET DEFAULT nextval('labor_roles_id_seq'::regclass);


--
-- TOC entry 3835 (class 2604 OID 92587)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 4138 (class 2604 OID 95146)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('menu_engineering_snapshots_id_seq'::regclass);


--
-- TOC entry 4136 (class 2604 OID 95127)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('menu_item_sync_map_id_seq'::regclass);


--
-- TOC entry 4134 (class 2604 OID 95113)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- TOC entry 3838 (class 2604 OID 92588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 3840 (class 2604 OID 92589)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 3841 (class 2604 OID 92590)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 3845 (class 2604 OID 92591)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 3850 (class 2604 OID 92592)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 3853 (class 2604 OID 92593)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 3854 (class 2604 OID 92594)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 4114 (class 2604 OID 95028)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions ALTER COLUMN id SET DEFAULT nextval('overhead_definitions_id_seq'::regclass);


--
-- TOC entry 3861 (class 2604 OID 92595)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 3867 (class 2604 OID 92596)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 3871 (class 2604 OID 92597)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 4181 (class 2604 OID 95582)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4177 (class 2604 OID 95539)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('pos_reprocess_log_id_seq'::regclass);


--
-- TOC entry 4173 (class 2604 OID 95522)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('pos_reverse_log_id_seq'::regclass);


--
-- TOC entry 4127 (class 2604 OID 95079)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('pos_sync_batches_id_seq'::regclass);


--
-- TOC entry 4132 (class 2604 OID 95094)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('pos_sync_logs_id_seq'::regclass);


--
-- TOC entry 3726 (class 2604 OID 92598)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 3730 (class 2604 OID 92599)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 3736 (class 2604 OID 92600)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 3738 (class 2604 OID 92601)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 4038 (class 2604 OID 94573)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab ALTER COLUMN id SET DEFAULT nextval('prod_cab_id_seq'::regclass);


--
-- TOC entry 4041 (class 2604 OID 94588)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det ALTER COLUMN id SET DEFAULT nextval('prod_det_id_seq'::regclass);


--
-- TOC entry 4062 (class 2604 OID 94699)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs ALTER COLUMN id SET DEFAULT nextval('production_order_inputs_id_seq'::regclass);


--
-- TOC entry 4063 (class 2604 OID 94713)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs ALTER COLUMN id SET DEFAULT nextval('production_order_outputs_id_seq'::regclass);


--
-- TOC entry 4057 (class 2604 OID 94676)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders ALTER COLUMN id SET DEFAULT nextval('production_orders_id_seq'::regclass);


--
-- TOC entry 4107 (class 2604 OID 94983)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents ALTER COLUMN id SET DEFAULT nextval('purchase_documents_id_seq'::regclass);


--
-- TOC entry 4104 (class 2604 OID 94968)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('purchase_order_lines_id_seq'::regclass);


--
-- TOC entry 4098 (class 2604 OID 94948)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders ALTER COLUMN id SET DEFAULT nextval('purchase_orders_id_seq'::regclass);


--
-- TOC entry 4087 (class 2604 OID 94899)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('purchase_request_lines_id_seq'::regclass);


--
-- TOC entry 4082 (class 2604 OID 94880)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests ALTER COLUMN id SET DEFAULT nextval('purchase_requests_id_seq'::regclass);


--
-- TOC entry 4165 (class 2604 OID 95417)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('purchase_suggestion_lines_id_seq'::regclass);


--
-- TOC entry 4156 (class 2604 OID 95367)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('purchase_suggestions_id_seq'::regclass);


--
-- TOC entry 4096 (class 2604 OID 94933)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quote_lines_id_seq'::regclass);


--
-- TOC entry 4089 (class 2604 OID 94914)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quotes_id_seq'::regclass);


--
-- TOC entry 3875 (class 2604 OID 92602)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 4048 (class 2604 OID 94626)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('recepcion_adjuntos_id_seq'::regclass);


--
-- TOC entry 3876 (class 2604 OID 92603)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 3878 (class 2604 OID 92604)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 3879 (class 2604 OID 92605)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 3890 (class 2604 OID 92606)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 3896 (class 2604 OID 92607)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 3897 (class 2604 OID 92608)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 3905 (class 2604 OID 92609)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 3996 (class 2604 OID 94367)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 4119 (class 2604 OID 95060)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_extended_cost_history_id_seq'::regclass);


--
-- TOC entry 4111 (class 2604 OID 95013)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('recipe_labor_steps_id_seq'::regclass);


--
-- TOC entry 4118 (class 2604 OID 95046)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('recipe_overhead_allocations_id_seq'::regclass);


--
-- TOC entry 3995 (class 2604 OID 94358)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 3992 (class 2604 OID 94344)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 4151 (class 2604 OID 95335)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('replenishment_suggestions_id_seq'::regclass);


--
-- TOC entry 4147 (class 2604 OID 95192)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions ALTER COLUMN id SET DEFAULT nextval('report_definitions_id_seq'::regclass);


--
-- TOC entry 4149 (class 2604 OID 95206)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs ALTER COLUMN id SET DEFAULT nextval('report_runs_id_seq'::regclass);


--
-- TOC entry 3909 (class 2604 OID 92610)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 3910 (class 2604 OID 92611)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 3741 (class 2604 OID 92612)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 4032 (class 2604 OID 94545)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('sol_prod_cab_id_seq'::regclass);


--
-- TOC entry 4036 (class 2604 OID 94559)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det ALTER COLUMN id SET DEFAULT nextval('sol_prod_det_id_seq'::regclass);


--
-- TOC entry 3911 (class 2604 OID 92613)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 3917 (class 2604 OID 92614)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 3920 (class 2604 OID 92615)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 4170 (class 2604 OID 95510)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifiers_id_seq'::regclass);


--
-- TOC entry 3923 (class 2604 OID 92616)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 3929 (class 2604 OID 92617)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 4043 (class 2604 OID 94602)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab ALTER COLUMN id SET DEFAULT nextval('transfer_cab_id_seq'::regclass);


--
-- TOC entry 4046 (class 2604 OID 94612)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det ALTER COLUMN id SET DEFAULT nextval('transfer_det_id_seq'::regclass);


--
-- TOC entry 3934 (class 2604 OID 92618)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 3936 (class 2604 OID 92619)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 3937 (class 2604 OID 92620)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 3942 (class 2604 OID 92621)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 3951 (class 2604 OID 92622)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 3956 (class 2604 OID 92623)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 3967 (class 2604 OID 92624)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


--
-- TOC entry 4509 (class 2606 OID 94400)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4507 (class 2606 OID 94390)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4232 (class 2606 OID 92630)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 4745 (class 2606 OID 102639)
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4201 (class 2606 OID 90680)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4234 (class 2606 OID 92632)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 4236 (class 2606 OID 92634)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 4240 (class 2606 OID 92636)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4238 (class 2606 OID 92638)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 4518 (class 2606 OID 94491)
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- TOC entry 4520 (class 2606 OID 94508)
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- TOC entry 4516 (class 2606 OID 94474)
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- TOC entry 4512 (class 2606 OID 94447)
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- TOC entry 4514 (class 2606 OID 94452)
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- TOC entry 4600 (class 2606 OID 94824)
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- TOC entry 4603 (class 2606 OID 94810)
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- TOC entry 4605 (class 2606 OID 94839)
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4596 (class 2606 OID 94780)
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 4589 (class 2606 OID 94749)
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- TOC entry 4460 (class 2606 OID 93947)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 4462 (class 2606 OID 93940)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4464 (class 2606 OID 93956)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 4466 (class 2606 OID 93958)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 4456 (class 2606 OID 93931)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 4458 (class 2606 OID 93929)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 4242 (class 2606 OID 94009)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 4244 (class 2606 OID 92640)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4470 (class 2606 OID 93978)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4472 (class 2606 OID 93966)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4474 (class 2606 OID 102827)
-- Name: cat_uom_conversion_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4248 (class 2606 OID 92642)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4250 (class 2606 OID 92644)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 4252 (class 2606 OID 92646)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 4254 (class 2606 OID 92648)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 4256 (class 2606 OID 92650)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 4260 (class 2606 OID 92652)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4262 (class 2606 OID 92654)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4203 (class 2606 OID 90682)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 4264 (class 2606 OID 92656)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4268 (class 2606 OID 92658)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4271 (class 2606 OID 92660)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 4273 (class 2606 OID 92662)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4276 (class 2606 OID 92664)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4279 (class 2606 OID 102654)
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- TOC entry 4281 (class 2606 OID 92666)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4285 (class 2606 OID 92668)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4755 (class 2606 OID 102784)
-- Name: insumo_proveedor_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4283 (class 2606 OID 92670)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 4528 (class 2606 OID 94534)
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4610 (class 2606 OID 94868)
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4522 (class 2606 OID 94523)
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4526 (class 2606 OID 94525)
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- TOC entry 4479 (class 2606 OID 93997)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 4481 (class 2606 OID 93990)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4289 (class 2606 OID 92672)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 4559 (class 2606 OID 94667)
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4550 (class 2606 OID 94653)
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- TOC entry 4552 (class 2606 OID 94646)
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- TOC entry 4583 (class 2606 OID 94733)
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- TOC entry 4485 (class 2606 OID 94294)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 4487 (class 2606 OID 94290)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4489 (class 2606 OID 94292)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 4491 (class 2606 OID 94314)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4292 (class 2606 OID 92674)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 4493 (class 2606 OID 94331)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 4297 (class 2606 OID 92676)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 4300 (class 2606 OID 92678)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4302 (class 2606 OID 92680)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 4304 (class 2606 OID 92682)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4652 (class 2606 OID 95007)
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- TOC entry 4654 (class 2606 OID 95004)
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4309 (class 2606 OID 92684)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 4688 (class 2606 OID 95159)
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4684 (class 2606 OID 95133)
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4680 (class 2606 OID 95119)
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4311 (class 2606 OID 92686)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 4313 (class 2606 OID 92688)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4316 (class 2606 OID 92690)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 4319 (class 2606 OID 92692)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 4321 (class 2606 OID 92694)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 4323 (class 2606 OID 92696)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4333 (class 2606 OID 92698)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 4335 (class 2606 OID 92700)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4337 (class 2606 OID 92702)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4339 (class 2606 OID 92704)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4341 (class 2606 OID 92706)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 4661 (class 2606 OID 95040)
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- TOC entry 4663 (class 2606 OID 95036)
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4343 (class 2606 OID 92708)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4345 (class 2606 OID 92710)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 4347 (class 2606 OID 92712)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 4350 (class 2606 OID 92714)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4352 (class 2606 OID 92716)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4354 (class 2606 OID 92718)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4740 (class 2606 OID 95587)
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4742 (class 2606 OID 95590)
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 4769 (class 2606 OID 102948)
-- Name: pk_inventory_snapshot; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT pk_inventory_snapshot PRIMARY KEY (snapshot_date, branch_id, item_id);


--
-- TOC entry 4359 (class 2606 OID 92720)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 4762 (class 2606 OID 102933)
-- Name: pos_modifiers_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4764 (class 2606 OID 102935)
-- Name: pos_modifiers_map_pos_modifier_code_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pos_modifier_code_key UNIQUE (pos_modifier_code);


--
-- TOC entry 4738 (class 2606 OID 95547)
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4733 (class 2606 OID 95530)
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4674 (class 2606 OID 95088)
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4676 (class 2606 OID 95100)
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4208 (class 2606 OID 90684)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4219 (class 2606 OID 90686)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 4223 (class 2606 OID 90688)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 4213 (class 2606 OID 90690)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4536 (class 2606 OID 94577)
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4538 (class 2606 OID 94591)
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4573 (class 2606 OID 94704)
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4578 (class 2606 OID 94718)
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4563 (class 2606 OID 94693)
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4566 (class 2606 OID 94685)
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4361 (class 2606 OID 92722)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4647 (class 2606 OID 94988)
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 4644 (class 2606 OID 94975)
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4637 (class 2606 OID 94962)
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4639 (class 2606 OID 94958)
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4623 (class 2606 OID 94905)
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4616 (class 2606 OID 94893)
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- TOC entry 4618 (class 2606 OID 94888)
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 4722 (class 2606 OID 95426)
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4716 (class 2606 OID 95380)
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4632 (class 2606 OID 94939)
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4628 (class 2606 OID 94925)
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- TOC entry 4363 (class 2606 OID 92724)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4544 (class 2606 OID 94631)
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- TOC entry 4365 (class 2606 OID 92726)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4368 (class 2606 OID 92728)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4374 (class 2606 OID 92730)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 4376 (class 2606 OID 92732)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4370 (class 2606 OID 92734)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 4378 (class 2606 OID 92736)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4382 (class 2606 OID 92738)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4384 (class 2606 OID 92740)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, insumo_id);


--
-- TOC entry 4372 (class 2606 OID 92742)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4386 (class 2606 OID 92744)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 4390 (class 2606 OID 92746)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 4392 (class 2606 OID 92748)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 4505 (class 2606 OID 94374)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4672 (class 2606 OID 95072)
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4657 (class 2606 OID 95020)
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- TOC entry 4667 (class 2606 OID 95051)
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 4669 (class 2606 OID 95053)
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- TOC entry 4502 (class 2606 OID 94360)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4498 (class 2606 OID 94351)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4701 (class 2606 OID 95355)
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4704 (class 2606 OID 95344)
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4692 (class 2606 OID 95198)
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4696 (class 2606 OID 95212)
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- TOC entry 4394 (class 2606 OID 92750)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 4396 (class 2606 OID 92752)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 4398 (class 2606 OID 92754)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 4400 (class 2606 OID 92756)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4402 (class 2606 OID 92758)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4690 (class 2606 OID 95166)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- TOC entry 4686 (class 2606 OID 95140)
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- TOC entry 4682 (class 2606 OID 95121)
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- TOC entry 4718 (class 2606 OID 95411)
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4694 (class 2606 OID 95200)
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- TOC entry 4228 (class 2606 OID 90692)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 4230 (class 2606 OID 90694)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 4405 (class 2606 OID 92760)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 4532 (class 2606 OID 94553)
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4534 (class 2606 OID 94562)
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4411 (class 2606 OID 92762)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4416 (class 2606 OID 92764)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4413 (class 2606 OID 92766)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4421 (class 2606 OID 92768)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4726 (class 2606 OID 95514)
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 4424 (class 2606 OID 92770)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 4426 (class 2606 OID 92772)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4428 (class 2606 OID 92774)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4540 (class 2606 OID 94606)
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4542 (class 2606 OID 94615)
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4430 (class 2606 OID 92776)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4432 (class 2606 OID 92778)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4434 (class 2606 OID 92780)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4436 (class 2606 OID 92782)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4438 (class 2606 OID 92784)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4440 (class 2606 OID 92786)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4442 (class 2606 OID 92788)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 4444 (class 2606 OID 92790)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4210 (class 2606 OID 90696)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4216 (class 2606 OID 92792)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4724 (class 2606 OID 95443)
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- TOC entry 4446 (class 2606 OID 92794)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 4448 (class 2606 OID 92796)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4450 (class 2606 OID 92798)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4452 (class 2606 OID 92800)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 4454 (class 2606 OID 92802)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 4598 (class 1259 OID 94821)
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON cash_fund_arqueos USING btree (cash_fund_id);


--
-- TOC entry 4601 (class 1259 OID 94822)
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON cash_fund_arqueos USING btree (created_by_user_id);


--
-- TOC entry 4592 (class 1259 OID 94796)
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON cash_fund_movements USING btree (cash_fund_id);


--
-- TOC entry 4593 (class 1259 OID 94799)
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON cash_fund_movements USING btree (created_by_user_id);


--
-- TOC entry 4594 (class 1259 OID 94798)
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON cash_fund_movements USING btree (estatus);


--
-- TOC entry 4597 (class 1259 OID 94797)
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON cash_fund_movements USING btree (tipo);


--
-- TOC entry 4586 (class 1259 OID 94762)
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON cash_funds USING btree (estado);


--
-- TOC entry 4587 (class 1259 OID 94761)
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON cash_funds USING btree (fecha);


--
-- TOC entry 4590 (class 1259 OID 94763)
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON cash_funds USING btree (responsable_user_id);


--
-- TOC entry 4591 (class 1259 OID 94760)
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON cash_funds USING btree (sucursal_id);


--
-- TOC entry 4746 (class 1259 OID 102645)
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON audit_log USING btree (accion);


--
-- TOC entry 4747 (class 1259 OID 102646)
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON audit_log USING btree (entidad);


--
-- TOC entry 4748 (class 1259 OID 102647)
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON audit_log USING btree (entidad_id);


--
-- TOC entry 4749 (class 1259 OID 102643)
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON audit_log USING btree ("timestamp");


--
-- TOC entry 4750 (class 1259 OID 102644)
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON audit_log USING btree (user_id);


--
-- TOC entry 4245 (class 1259 OID 102829)
-- Name: idx_cat_unidades_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_activo ON cat_unidades USING btree (activo);


--
-- TOC entry 4246 (class 1259 OID 102828)
-- Name: idx_cat_unidades_clave; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_clave ON cat_unidades USING btree (clave);


--
-- TOC entry 4475 (class 1259 OID 102831)
-- Name: idx_cat_uom_conversion_destino; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_destino ON cat_uom_conversion USING btree (destino_id);


--
-- TOC entry 4476 (class 1259 OID 102830)
-- Name: idx_cat_uom_conversion_origen; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_origen ON cat_uom_conversion USING btree (origen_id);


--
-- TOC entry 4477 (class 1259 OID 102832)
-- Name: idx_cat_uom_conversion_scope; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_scope ON cat_uom_conversion USING btree (scope);


--
-- TOC entry 4274 (class 1259 OID 93178)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4286 (class 1259 OID 93179)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 4287 (class 1259 OID 93180)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 4765 (class 1259 OID 102949)
-- Name: idx_invshot_branch_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_branch_date ON inventory_snapshot USING btree (branch_id, snapshot_date);


--
-- TOC entry 4766 (class 1259 OID 102950)
-- Name: idx_invshot_item_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_item_date ON inventory_snapshot USING btree (item_id, snapshot_date);


--
-- TOC entry 4767 (class 1259 OID 102951)
-- Name: idx_invshot_variance; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_variance ON inventory_snapshot USING btree (snapshot_date, branch_id, variance_qty);


--
-- TOC entry 4324 (class 1259 OID 93181)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 4325 (class 1259 OID 93182)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 4482 (class 1259 OID 94066)
-- Name: idx_mv_dashboard_formas_pago_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_formas_pago_pk ON mv_dashboard_formas_pago USING btree (fecha, sucursal_id, codigo_fp);


--
-- TOC entry 4483 (class 1259 OID 94075)
-- Name: idx_mv_dashboard_resumen_pk; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dashboard_resumen_pk ON mv_dashboard_resumen USING btree (fecha, sucursal_id);


--
-- TOC entry 4348 (class 1259 OID 93183)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 4355 (class 1259 OID 94014)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 4734 (class 1259 OID 95550)
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON pos_reprocess_log USING btree (reprocessed_at);


--
-- TOC entry 4735 (class 1259 OID 95548)
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON pos_reprocess_log USING btree (ticket_id);


--
-- TOC entry 4736 (class 1259 OID 95549)
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON pos_reprocess_log USING btree (user_id);


--
-- TOC entry 4729 (class 1259 OID 95533)
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON pos_reverse_log USING btree (reversed_at);


--
-- TOC entry 4730 (class 1259 OID 95531)
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON pos_reverse_log USING btree (ticket_id);


--
-- TOC entry 4731 (class 1259 OID 95532)
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON pos_reverse_log USING btree (user_id);


--
-- TOC entry 4760 (class 1259 OID 102936)
-- Name: idx_posmod_active_valid; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_posmod_active_valid ON pos_modifiers_map USING btree (active, valid_from, (COALESCE(valid_to, '2999-12-31'::date)));


--
-- TOC entry 4206 (class 1259 OID 93184)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 4217 (class 1259 OID 93185)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 4220 (class 1259 OID 93186)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4211 (class 1259 OID 90724)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 4612 (class 1259 OID 95468)
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON purchase_requests USING btree (fecha_requerida);


--
-- TOC entry 4613 (class 1259 OID 95469)
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON purchase_requests USING btree (urgente);


--
-- TOC entry 4467 (class 1259 OID 94217)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 4468 (class 1259 OID 94218)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 4711 (class 1259 OID 95406)
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON purchase_suggestions USING btree (estado);


--
-- TOC entry 4712 (class 1259 OID 95408)
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON purchase_suggestions USING btree (sugerido_en);


--
-- TOC entry 4713 (class 1259 OID 95407)
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON purchase_suggestions USING btree (prioridad);


--
-- TOC entry 4714 (class 1259 OID 95409)
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON purchase_suggestions USING btree (sucursal_id, estado);


--
-- TOC entry 4719 (class 1259 OID 95445)
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON purchase_suggestion_lines USING btree (item_id);


--
-- TOC entry 4720 (class 1259 OID 95444)
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON purchase_suggestion_lines USING btree (suggestion_id);


--
-- TOC entry 4387 (class 1259 OID 93187)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 4224 (class 1259 OID 93188)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4407 (class 1259 OID 93189)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4408 (class 1259 OID 93190)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 4414 (class 1259 OID 93191)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 4417 (class 1259 OID 93192)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 4418 (class 1259 OID 93193)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 4419 (class 1259 OID 93194)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 4422 (class 1259 OID 93195)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 4277 (class 1259 OID 102655)
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- TOC entry 4529 (class 1259 OID 95576)
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON inv_consumo_pos_det USING btree (procesado);


--
-- TOC entry 4530 (class 1259 OID 95575)
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- TOC entry 4611 (class 1259 OID 94869)
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON inv_consumo_pos_log USING btree (ticket_id);


--
-- TOC entry 4523 (class 1259 OID 95564)
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON inv_consumo_pos USING btree (procesado);


--
-- TOC entry 4524 (class 1259 OID 95563)
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON inv_consumo_pos USING btree (requiere_reproceso);


--
-- TOC entry 4555 (class 1259 OID 94670)
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON inventory_count_lines USING btree (inventory_batch_id);


--
-- TOC entry 4556 (class 1259 OID 94668)
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON inventory_count_lines USING btree (inventory_count_id);


--
-- TOC entry 4557 (class 1259 OID 94669)
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON inventory_count_lines USING btree (item_id);


--
-- TOC entry 4546 (class 1259 OID 94649)
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON inventory_counts USING btree (almacen_id);


--
-- TOC entry 4547 (class 1259 OID 94651)
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON inventory_counts USING btree (cerrado_en);


--
-- TOC entry 4548 (class 1259 OID 94647)
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON inventory_counts USING btree (estado);


--
-- TOC entry 4553 (class 1259 OID 94650)
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON inventory_counts USING btree (programado_para);


--
-- TOC entry 4554 (class 1259 OID 94648)
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON inventory_counts USING btree (sucursal_id);


--
-- TOC entry 4580 (class 1259 OID 94736)
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON inventory_wastes USING btree (inventory_batch_id);


--
-- TOC entry 4581 (class 1259 OID 94735)
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON inventory_wastes USING btree (item_id);


--
-- TOC entry 4584 (class 1259 OID 94734)
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON inventory_wastes USING btree (production_order_id);


--
-- TOC entry 4585 (class 1259 OID 94737)
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON inventory_wastes USING btree (sucursal_id);


--
-- TOC entry 4756 (class 1259 OID 102787)
-- Name: ipp_activo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_activo_idx ON insumo_proveedor_presentacion USING btree (activo);


--
-- TOC entry 4757 (class 1259 OID 102785)
-- Name: ipp_insumo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_insumo_idx ON insumo_proveedor_presentacion USING btree (insumo_id);


--
-- TOC entry 4758 (class 1259 OID 102786)
-- Name: ipp_proveedor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_proveedor_idx ON insumo_proveedor_presentacion USING btree (proveedor_id);


--
-- TOC entry 4759 (class 1259 OID 102810)
-- Name: ipp_uni; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ipp_uni ON insumo_proveedor_presentacion USING btree (insumo_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra);


--
-- TOC entry 4510 (class 1259 OID 94401)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 4204 (class 1259 OID 93196)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 4265 (class 1259 OID 93197)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva DESC);


--
-- TOC entry 4269 (class 1259 OID 93198)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 4290 (class 1259 OID 93199)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 4293 (class 1259 OID 94220)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 4294 (class 1259 OID 94219)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 4494 (class 1259 OID 94332)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 4495 (class 1259 OID 94334)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 4496 (class 1259 OID 94333)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 4257 (class 1259 OID 93200)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 4258 (class 1259 OID 93201)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 4306 (class 1259 OID 93202)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 4307 (class 1259 OID 93203)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (insumo_id);


--
-- TOC entry 4326 (class 1259 OID 93204)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4327 (class 1259 OID 93205)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 4328 (class 1259 OID 93206)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 4329 (class 1259 OID 93207)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 4330 (class 1259 OID 93208)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4331 (class 1259 OID 93209)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4356 (class 1259 OID 93210)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 4357 (class 1259 OID 93211)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 4221 (class 1259 OID 90725)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4503 (class 1259 OID 94375)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4379 (class 1259 OID 93212)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (insumo_id);


--
-- TOC entry 4380 (class 1259 OID 93213)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4388 (class 1259 OID 93214)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 4500 (class 1259 OID 94361)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 4225 (class 1259 OID 90726)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 4226 (class 1259 OID 90727)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4409 (class 1259 OID 93215)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4305 (class 1259 OID 93216)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 4650 (class 1259 OID 95005)
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON labor_roles USING btree (activo);


--
-- TOC entry 4314 (class 1259 OID 93217)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 4317 (class 1259 OID 93218)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 4659 (class 1259 OID 95037)
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON overhead_definitions USING btree (activo);


--
-- TOC entry 4664 (class 1259 OID 95038)
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON overhead_definitions USING btree (tipo);


--
-- TOC entry 4743 (class 1259 OID 95588)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 4214 (class 1259 OID 90728)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 4570 (class 1259 OID 94707)
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON production_order_inputs USING btree (inventory_batch_id);


--
-- TOC entry 4571 (class 1259 OID 94706)
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON production_order_inputs USING btree (item_id);


--
-- TOC entry 4574 (class 1259 OID 94705)
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON production_order_inputs USING btree (production_order_id);


--
-- TOC entry 4575 (class 1259 OID 94721)
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON production_order_outputs USING btree (inventory_batch_id);


--
-- TOC entry 4576 (class 1259 OID 94720)
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON production_order_outputs USING btree (item_id);


--
-- TOC entry 4579 (class 1259 OID 94719)
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON production_order_outputs USING btree (production_order_id);


--
-- TOC entry 4560 (class 1259 OID 94689)
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON production_orders USING btree (almacen_id);


--
-- TOC entry 4561 (class 1259 OID 94690)
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON production_orders USING btree (estado);


--
-- TOC entry 4564 (class 1259 OID 94687)
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON production_orders USING btree (item_id);


--
-- TOC entry 4567 (class 1259 OID 94691)
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON production_orders USING btree (programado_para);


--
-- TOC entry 4568 (class 1259 OID 94686)
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON production_orders USING btree (recipe_id);


--
-- TOC entry 4569 (class 1259 OID 94688)
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON production_orders USING btree (sucursal_id);


--
-- TOC entry 4645 (class 1259 OID 94991)
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON purchase_documents USING btree (order_id);


--
-- TOC entry 4648 (class 1259 OID 94990)
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON purchase_documents USING btree (quote_id);


--
-- TOC entry 4649 (class 1259 OID 94989)
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON purchase_documents USING btree (request_id);


--
-- TOC entry 4641 (class 1259 OID 94977)
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON purchase_order_lines USING btree (item_id);


--
-- TOC entry 4642 (class 1259 OID 94976)
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON purchase_order_lines USING btree (order_id);


--
-- TOC entry 4635 (class 1259 OID 94960)
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON purchase_orders USING btree (estado);


--
-- TOC entry 4640 (class 1259 OID 94959)
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON purchase_orders USING btree (vendor_id);


--
-- TOC entry 4621 (class 1259 OID 94907)
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON purchase_request_lines USING btree (item_id);


--
-- TOC entry 4624 (class 1259 OID 94908)
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON purchase_request_lines USING btree (preferred_vendor_id);


--
-- TOC entry 4625 (class 1259 OID 94906)
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON purchase_request_lines USING btree (request_id);


--
-- TOC entry 4614 (class 1259 OID 94890)
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON purchase_requests USING btree (estado);


--
-- TOC entry 4619 (class 1259 OID 94891)
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON purchase_requests USING btree (requested_at);


--
-- TOC entry 4620 (class 1259 OID 94889)
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON purchase_requests USING btree (sucursal_id);


--
-- TOC entry 4630 (class 1259 OID 94942)
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON purchase_vendor_quote_lines USING btree (item_id);


--
-- TOC entry 4633 (class 1259 OID 94940)
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON purchase_vendor_quote_lines USING btree (quote_id);


--
-- TOC entry 4634 (class 1259 OID 94941)
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON purchase_vendor_quote_lines USING btree (request_line_id);


--
-- TOC entry 4626 (class 1259 OID 94927)
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON purchase_vendor_quotes USING btree (estado);


--
-- TOC entry 4629 (class 1259 OID 94926)
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- TOC entry 4545 (class 1259 OID 94632)
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON recepcion_adjuntos USING btree (recepcion_id);


--
-- TOC entry 4670 (class 1259 OID 95073)
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4655 (class 1259 OID 95022)
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON recipe_labor_steps USING btree (labor_role_id);


--
-- TOC entry 4658 (class 1259 OID 95021)
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON recipe_labor_steps USING btree (recipe_id);


--
-- TOC entry 4665 (class 1259 OID 95054)
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON recipe_overhead_allocations USING btree (overhead_id);


--
-- TOC entry 4698 (class 1259 OID 95347)
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON replenishment_suggestions USING btree (estado);


--
-- TOC entry 4699 (class 1259 OID 95350)
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- TOC entry 4702 (class 1259 OID 95348)
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- TOC entry 4705 (class 1259 OID 95346)
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON replenishment_suggestions USING btree (prioridad);


--
-- TOC entry 4706 (class 1259 OID 95353)
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON replenishment_suggestions USING btree (production_order_id);


--
-- TOC entry 4707 (class 1259 OID 95352)
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON replenishment_suggestions USING btree (purchase_request_id);


--
-- TOC entry 4708 (class 1259 OID 95351)
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON replenishment_suggestions USING btree (revisado_por);


--
-- TOC entry 4709 (class 1259 OID 95349)
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON replenishment_suggestions USING btree (sugerido_en);


--
-- TOC entry 4710 (class 1259 OID 95345)
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON replenishment_suggestions USING btree (tipo);


--
-- TOC entry 4751 (class 1259 OID 102640)
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON audit_log USING btree (entidad, entidad_id);


--
-- TOC entry 4752 (class 1259 OID 102642)
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON audit_log USING btree ("timestamp");


--
-- TOC entry 4753 (class 1259 OID 102641)
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON audit_log USING btree (user_id);


--
-- TOC entry 4606 (class 1259 OID 94841)
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON cash_fund_movement_audit_log USING btree (action);


--
-- TOC entry 4607 (class 1259 OID 94842)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- TOC entry 4608 (class 1259 OID 94840)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON cash_fund_movement_audit_log USING btree (movement_id);


--
-- TOC entry 4677 (class 1259 OID 95106)
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON pos_sync_logs USING btree (batch_id, status);


--
-- TOC entry 4678 (class 1259 OID 95107)
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON pos_sync_logs USING btree (external_id);


--
-- TOC entry 4366 (class 1259 OID 95225)
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON recepcion_cab USING btree (almacen_id);


--
-- TOC entry 4697 (class 1259 OID 95218)
-- Name: selemti_report_runs_report_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_report_runs_report_id_status_index ON report_runs USING btree (report_id, status);


--
-- TOC entry 4403 (class 1259 OID 93219)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 4406 (class 1259 OID 93220)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 4727 (class 1259 OID 95515)
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON ticket_item_modifiers USING btree (ticket_id);


--
-- TOC entry 4728 (class 1259 OID 95516)
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON ticket_item_modifiers USING btree (ticket_item_id);


--
-- TOC entry 4205 (class 1259 OID 90729)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 4266 (class 1259 OID 93221)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (insumo_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 4295 (class 1259 OID 94213)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 4298 (class 1259 OID 94308)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 4499 (class 1259 OID 94352)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


--
-- TOC entry 4901 (class 2620 OID 102953)
-- Name: trg_invshot_biur; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_invshot_biur BEFORE INSERT OR UPDATE ON inventory_snapshot FOR EACH ROW EXECUTE PROCEDURE tg_invshot_autofill();


--
-- TOC entry 4900 (class 2620 OID 102789)
-- Name: trg_ipp_set_timestamp; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ipp_set_timestamp BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE set_timestamp_ipp();


--
-- TOC entry 4897 (class 2620 OID 94298)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 4896 (class 2620 OID 94316)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 4899 (class 2620 OID 94404)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 4898 (class 2620 OID 94336)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 4892 (class 2620 OID 93831)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 4893 (class 2620 OID 93832)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 4894 (class 2620 OID 93833)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 4895 (class 2620 OID 93834)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


--
-- TOC entry 4774 (class 2606 OID 92803)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 4775 (class 2606 OID 92808)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 4857 (class 2606 OID 94492)
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES caja_fondo_mov(id) ON DELETE CASCADE;


--
-- TOC entry 4858 (class 2606 OID 94509)
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4856 (class 2606 OID 94475)
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4855 (class 2606 OID 94453)
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4870 (class 2606 OID 94811)
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 4869 (class 2606 OID 94816)
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4866 (class 2606 OID 94791)
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4868 (class 2606 OID 94781)
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 4867 (class 2606 OID 94786)
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4864 (class 2606 OID 94755)
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4865 (class 2606 OID 94750)
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4850 (class 2606 OID 93941)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 4851 (class 2606 OID 93972)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 4852 (class 2606 OID 93967)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 4776 (class 2606 OID 92813)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 4778 (class 2606 OID 92818)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4777 (class 2606 OID 92823)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4780 (class 2606 OID 92828)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 4779 (class 2606 OID 92833)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4874 (class 2606 OID 95458)
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 4873 (class 2606 OID 95463)
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE SET NULL;


--
-- TOC entry 4882 (class 2606 OID 95386)
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 4879 (class 2606 OID 95401)
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES purchase_requests(id) ON DELETE SET NULL;


--
-- TOC entry 4883 (class 2606 OID 95381)
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 4880 (class 2606 OID 95396)
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4881 (class 2606 OID 95391)
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4885 (class 2606 OID 95432)
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 4884 (class 2606 OID 95437)
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES cat_proveedores(id) ON DELETE SET NULL;


--
-- TOC entry 4886 (class 2606 OID 95427)
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE CASCADE;


--
-- TOC entry 4839 (class 2606 OID 92838)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4781 (class 2606 OID 92843)
-- Name: hist_cost_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4782 (class 2606 OID 92848)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4783 (class 2606 OID 92853)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4784 (class 2606 OID 92858)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4787 (class 2606 OID 92863)
-- Name: insumo_presentacion_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4786 (class 2606 OID 92868)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4785 (class 2606 OID 92873)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4859 (class 2606 OID 94535)
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES inv_consumo_pos(id) ON DELETE CASCADE;


--
-- TOC entry 4853 (class 2606 OID 93998)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 4854 (class 2606 OID 93991)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 4788 (class 2606 OID 92878)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4891 (class 2606 OID 102790)
-- Name: ipp_insumo_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_insumo_fk FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4888 (class 2606 OID 102805)
-- Name: ipp_proveedor_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_proveedor_fk FOREIGN KEY (proveedor_id) REFERENCES proveedor(id);


--
-- TOC entry 4889 (class 2606 OID 102800)
-- Name: ipp_uom_base_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_base_fk FOREIGN KEY (uom_base_id) REFERENCES cat_unidades(id);


--
-- TOC entry 4890 (class 2606 OID 102795)
-- Name: ipp_uom_compra_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_compra_fk FOREIGN KEY (uom_compra_id) REFERENCES cat_unidades(id);


--
-- TOC entry 4790 (class 2606 OID 92883)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4789 (class 2606 OID 92888)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4791 (class 2606 OID 94299)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4794 (class 2606 OID 92893)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4793 (class 2606 OID 92898)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4792 (class 2606 OID 92903)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4795 (class 2606 OID 92908)
-- Name: lote_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4799 (class 2606 OID 92913)
-- Name: merma_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4798 (class 2606 OID 92918)
-- Name: merma_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 4797 (class 2606 OID 92923)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4796 (class 2606 OID 92928)
-- Name: merma_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 4800 (class 2606 OID 92933)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 4801 (class 2606 OID 92938)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 4802 (class 2606 OID 92943)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 4804 (class 2606 OID 92948)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4803 (class 2606 OID 92953)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 4809 (class 2606 OID 92958)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4808 (class 2606 OID 92963)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 4807 (class 2606 OID 92968)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4806 (class 2606 OID 92973)
-- Name: op_cab_usuario_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES usuario(id);


--
-- TOC entry 4805 (class 2606 OID 92978)
-- Name: op_cab_usuario_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_usuario_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES usuario(id);


--
-- TOC entry 4812 (class 2606 OID 92983)
-- Name: op_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4811 (class 2606 OID 92988)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4810 (class 2606 OID 92993)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4813 (class 2606 OID 92998)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4814 (class 2606 OID 93003)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4817 (class 2606 OID 93008)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4816 (class 2606 OID 93013)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 4815 (class 2606 OID 93018)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4770 (class 2606 OID 91367)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 4772 (class 2606 OID 91372)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 4773 (class 2606 OID 91377)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 4771 (class 2606 OID 91382)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 4861 (class 2606 OID 94578)
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id);


--
-- TOC entry 4862 (class 2606 OID 94592)
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4818 (class 2606 OID 93023)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 4820 (class 2606 OID 93028)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES sucursal(id);


--
-- TOC entry 4819 (class 2606 OID 93033)
-- Name: recepcion_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 4825 (class 2606 OID 93038)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES bodega(id);


--
-- TOC entry 4824 (class 2606 OID 93043)
-- Name: recepcion_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4823 (class 2606 OID 93048)
-- Name: recepcion_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 4822 (class 2606 OID 93053)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4821 (class 2606 OID 93058)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4827 (class 2606 OID 93063)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4826 (class 2606 OID 93068)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4829 (class 2606 OID 93073)
-- Name: receta_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4828 (class 2606 OID 93078)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4830 (class 2606 OID 93083)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 4832 (class 2606 OID 93088)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 4831 (class 2606 OID 93093)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 4887 (class 2606 OID 102648)
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4871 (class 2606 OID 94848)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4872 (class 2606 OID 94843)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES cash_fund_movements(id) ON DELETE CASCADE;


--
-- TOC entry 4877 (class 2606 OID 95160)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 4876 (class 2606 OID 95134)
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 4875 (class 2606 OID 95101)
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES pos_sync_batches(id) ON DELETE CASCADE;


--
-- TOC entry 4878 (class 2606 OID 95213)
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE;


--
-- TOC entry 4860 (class 2606 OID 94563)
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4833 (class 2606 OID 93098)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4836 (class 2606 OID 93103)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4835 (class 2606 OID 93108)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 4834 (class 2606 OID 93113)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4838 (class 2606 OID 93118)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 4837 (class 2606 OID 93123)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4863 (class 2606 OID 94616)
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES transfer_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4842 (class 2606 OID 93128)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 4841 (class 2606 OID 93133)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES bodega(id);


--
-- TOC entry 4840 (class 2606 OID 93138)
-- Name: traspaso_cab_usuario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuario(id);


--
-- TOC entry 4846 (class 2606 OID 93143)
-- Name: traspaso_det_insumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES insumo(id);


--
-- TOC entry 4845 (class 2606 OID 93148)
-- Name: traspaso_det_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES lote(id);


--
-- TOC entry 4844 (class 2606 OID 93153)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4843 (class 2606 OID 93158)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4848 (class 2606 OID 93163)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4847 (class 2606 OID 93168)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4849 (class 2606 OID 93173)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 5210 (class 0 OID 94058)
-- Dependencies: 533 5336
-- Name: mv_dashboard_formas_pago; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_formas_pago;


--
-- TOC entry 5211 (class 0 OID 94067)
-- Dependencies: 534 5210 5336
-- Name: mv_dashboard_resumen; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_dashboard_resumen;


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 515
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-10-30 13:24:02

--
-- PostgreSQL database dump complete
--

