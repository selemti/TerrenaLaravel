--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-17 23:28:39

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

SET search_path = selemti, pg_catalog;

--
-- TOC entry 1167 (class 1247 OID 151468)
-- Name: consumo_policy; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

--
-- TOC entry 1170 (class 1247 OID 151474)
-- Name: lote_estado; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

--
-- TOC entry 1173 (class 1247 OID 151482)
-- Name: merma_clase; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

--
-- TOC entry 1176 (class 1247 OID 151488)
-- Name: merma_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

--
-- TOC entry 1179 (class 1247 OID 151494)
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
-- TOC entry 1182 (class 1247 OID 151512)
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
-- TOC entry 1185 (class 1247 OID 151522)
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
-- TOC entry 1188 (class 1247 OID 151532)
-- Name: producto_tipo; Type: TYPE; Schema: selemti; Owner: postgres
--

CREATE TYPE producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE producto_tipo OWNER TO postgres;

--
-- TOC entry 776 (class 1255 OID 151552)
-- Name: audit_trigger_func(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION audit_trigger_func() RETURNS trigger
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
-- TOC entry 777 (class 1255 OID 151553)
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
-- TOC entry 778 (class 1255 OID 151554)
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
-- TOC entry 797 (class 1255 OID 151555)
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
-- TOC entry 811 (class 1255 OID 151556)
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
    SET estado = 'CONFIRMADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'PENDIENTE';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'CONFIRM', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_confirmar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 779 (class 1255 OID 151557)
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
-- TOC entry 780 (class 1255 OID 151558)
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
-- TOC entry 810 (class 1255 OID 151559)
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
-- TOC entry 781 (class 1255 OID 151560)
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
-- TOC entry 783 (class 1255 OID 151561)
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
-- TOC entry 784 (class 1255 OID 151562)
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
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 784
-- Name: FUNCTION fn_generar_postcorte(p_sesion_id bigint); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_generar_postcorte(p_sesion_id bigint) IS 'Genera automÃ¡ticamente el postcorte basado en el precorte y transacciones POS.';


--
-- TOC entry 791 (class 1255 OID 151563)
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
-- TOC entry 790 (class 1255 OID 151564)
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
-- TOC entry 785 (class 1255 OID 151565)
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
-- TOC entry 786 (class 1255 OID 151566)
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
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 786
-- Name: FUNCTION fn_postcorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_postcorte_after_insert() IS 'Trigger: al crear un postcorte, marca la sesiÃ³n como CERRADA.';


--
-- TOC entry 787 (class 1255 OID 151567)
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
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 787
-- Name: FUNCTION fn_precorte_after_insert(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_insert() IS 'Trigger: al crear un precorte, marca la sesiÃ³n como EN_CORTE.';


--
-- TOC entry 788 (class 1255 OID 151568)
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
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 788
-- Name: FUNCTION fn_precorte_after_update_aprobado(); Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON FUNCTION fn_precorte_after_update_aprobado() IS 'Trigger: al aprobar un precorte, genera el postcorte automÃ¡ticamente.';


--
-- TOC entry 789 (class 1255 OID 151569)
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
-- TOC entry 799 (class 1255 OID 151570)
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
-- TOC entry 792 (class 1255 OID 151571)
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
-- TOC entry 782 (class 1255 OID 151572)
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
-- TOC entry 812 (class 1255 OID 151573)
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
    SET estado = 'ANULADO', updated_at = now()
    WHERE ticket_id = _ticket_id AND estado = 'CONFIRMADO';

    INSERT INTO selemti.inv_consumo_pos_log(ticket_id, accion, payload)
    VALUES (_ticket_id, 'REVERSE', NULL);
END;
$$;


ALTER FUNCTION selemti.fn_reversar_consumo_ticket(_ticket_id bigint) OWNER TO postgres;

--
-- TOC entry 793 (class 1255 OID 151574)
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
-- TOC entry 794 (class 1255 OID 151575)
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
-- TOC entry 795 (class 1255 OID 151576)
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
-- TOC entry 798 (class 1255 OID 151577)
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
-- TOC entry 801 (class 1255 OID 151578)
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
-- TOC entry 802 (class 1255 OID 151579)
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
-- TOC entry 803 (class 1255 OID 151580)
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
-- TOC entry 804 (class 1255 OID 151581)
-- Name: refresh_materialized_views(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION refresh_materialized_views() RETURNS void
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
-- TOC entry 805 (class 1255 OID 151582)
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
-- TOC entry 806 (class 1255 OID 151583)
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
-- TOC entry 807 (class 1255 OID 151584)
-- Name: set_timestamp_ipp(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION set_timestamp_ipp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.set_timestamp_ipp() OWNER TO postgres;

--
-- TOC entry 809 (class 1255 OID 151585)
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
-- TOC entry 808 (class 1255 OID 151586)
-- Name: tg_invshot_autofill(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION tg_invshot_autofill() RETURNS trigger
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
-- TOC entry 800 (class 1255 OID 151587)
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

--
-- TOC entry 796 (class 1255 OID 151588)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: selemti; Owner: postgres
--

CREATE FUNCTION update_updated_at_column() RETURNS trigger
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
-- TOC entry 5571 (class 0 OID 0)
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
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 192
-- Name: alert_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alert_rules_id_seq OWNED BY alert_rules.id;


--
-- TOC entry 698 (class 1259 OID 168502)
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
-- TOC entry 697 (class 1259 OID 168500)
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
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 697
-- Name: alertas_cortes_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: postgres
--

ALTER SEQUENCE alertas_cortes_id_seq OWNED BY alertas_cortes.id;


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
-- TOC entry 5574 (class 0 OID 0)
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
-- TOC entry 5575 (class 0 OID 0)
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
-- TOC entry 5576 (class 0 OID 0)
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
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 199
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: selemti; Owner: floreant
--

ALTER SEQUENCE auditoria_id_seq OWNED BY auditoria.id;


--
-- TOC entry 699 (class 1259 OID 168570)
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
-- TOC entry 700 (class 1259 OID 168576)
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
-- TOC entry 701 (class 1259 OID 168582)
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
-- TOC entry 5578 (class 0 OID 0)
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
-- TOC entry 5579 (class 0 OID 0)
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
-- TOC entry 5580 (class 0 OID 0)
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
-- TOC entry 5581 (class 0 OID 0)
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
-- TOC entry 5582 (class 0 OID 0)
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
-- TOC entry 5583 (class 0 OID 0)
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
-- TOC entry 5584 (class 0 OID 0)
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
-- TOC entry 5585 (class 0 OID 0)
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
-- TOC entry 5586 (class 0 OID 0)
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
-- TOC entry 5587 (class 0 OID 0)
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
-- TOC entry 5588 (class 0 OID 0)
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
-- TOC entry 5589 (class 0 OID 0)
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
-- TOC entry 5590 (class 0 OID 0)
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
-- TOC entry 5591 (class 0 OID 0)
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
-- TOC entry 5592 (class 0 OID 0)
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
-- TOC entry 5593 (class 0 OID 0)
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
-- TOC entry 5594 (class 0 OID 0)
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
-- TOC entry 5595 (class 0 OID 0)
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
-- TOC entry 5596 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE conciliacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE conciliacion IS 'Registra el proceso de conciliaciÃ³n final despuÃ©s del postcorte.';


--
-- TOC entry 5597 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN conciliacion.postcorte_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliaciÃ³n por postcorte).';


--
-- TOC entry 5598 (class 0 OID 0)
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
-- TOC entry 5599 (class 0 OID 0)
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
-- TOC entry 5600 (class 0 OID 0)
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
-- TOC entry 5601 (class 0 OID 0)
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
-- TOC entry 5602 (class 0 OID 0)
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
-- TOC entry 5603 (class 0 OID 0)
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
-- TOC entry 5604 (class 0 OID 0)
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
-- TOC entry 5605 (class 0 OID 0)
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
-- TOC entry 5606 (class 0 OID 0)
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
-- TOC entry 5607 (class 0 OID 0)
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
-- TOC entry 5608 (class 0 OID 0)
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
-- TOC entry 5609 (class 0 OID 0)
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
-- TOC entry 5610 (class 0 OID 0)
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
-- TOC entry 5611 (class 0 OID 0)
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
-- TOC entry 5612 (class 0 OID 0)
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
-- TOC entry 5613 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.requiere_reproceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.requiere_reproceso IS 'Pendiente de reprocesar';


--
-- TOC entry 5614 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.procesado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.procesado IS 'Consumo confirmado';


--
-- TOC entry 5615 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN inv_consumo_pos.fecha_proceso; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN inv_consumo_pos.fecha_proceso IS 'Momento del procesamiento';


--
-- TOC entry 5616 (class 0 OID 0)
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
-- TOC entry 5617 (class 0 OID 0)
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
-- TOC entry 5618 (class 0 OID 0)
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
-- TOC entry 5619 (class 0 OID 0)
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
-- TOC entry 5620 (class 0 OID 0)
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
-- TOC entry 5621 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE inventory_batch; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE inventory_batch IS 'Lotes de inventario - Consolidada en Phase 2.3';


--
-- TOC entry 5622 (class 0 OID 0)
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
-- TOC entry 5623 (class 0 OID 0)
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
-- TOC entry 5624 (class 0 OID 0)
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
-- TOC entry 5625 (class 0 OID 0)
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
-- TOC entry 5626 (class 0 OID 0)
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
-- TOC entry 5627 (class 0 OID 0)
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
-- TOC entry 5628 (class 0 OID 0)
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
-- TOC entry 5629 (class 0 OID 0)
-- Dependencies: 279
-- Name: TABLE items; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE items IS 'CatÃ¡logo de items/insumos - Consolidada en Phase 2.3';


--
-- TOC entry 5630 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_medida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_medida_id IS 'Unidad BASE de inventario (KG, L, PZ) - FK a cat_unidades';


--
-- TOC entry 5631 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.factor_conversion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_conversion IS 'Factor adicional de conversión si se requiere (legacy, en desuso)';


--
-- TOC entry 5632 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_compra_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_compra_id IS 'Unidad de COMPRA del proveedor (CAJA, PAQUETE, COSTAL, etc) - FK a cat_unidades';


--
-- TOC entry 5633 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.factor_compra; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.factor_compra IS 'Factor de conversión: 1 unidad_compra = X unidades_base. Ej: 1 CAJA = 12 L';


--
-- TOC entry 5634 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.unidad_salida_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.unidad_salida_id IS 'Unidad de SALIDA para recetas (ML, TAZA, PORCION, etc) - FK a cat_unidades';


--
-- TOC entry 5635 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.es_producible; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_producible IS 'Indicates if this item is produced internally (sub-recipe).';


--
-- TOC entry 5636 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN items.es_consumible_operativo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN items.es_consumible_operativo IS 'Identifies operational use materials (cleaning, gloves).';


--
-- TOC entry 5637 (class 0 OID 0)
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
-- TOC entry 5638 (class 0 OID 0)
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
-- TOC entry 5639 (class 0 OID 0)
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
-- TOC entry 5640 (class 0 OID 0)
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
-- TOC entry 5641 (class 0 OID 0)
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
-- TOC entry 5642 (class 0 OID 0)
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
-- TOC entry 5643 (class 0 OID 0)
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
-- TOC entry 5644 (class 0 OID 0)
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
-- TOC entry 5645 (class 0 OID 0)
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
-- TOC entry 5646 (class 0 OID 0)
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
-- TOC entry 5647 (class 0 OID 0)
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
-- TOC entry 5648 (class 0 OID 0)
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
-- TOC entry 5649 (class 0 OID 0)
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
-- TOC entry 5650 (class 0 OID 0)
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
-- TOC entry 5651 (class 0 OID 0)
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
-- TOC entry 5652 (class 0 OID 0)
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
-- TOC entry 5653 (class 0 OID 0)
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
-- TOC entry 5654 (class 0 OID 0)
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
-- TOC entry 5655 (class 0 OID 0)
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
-- TOC entry 5656 (class 0 OID 0)
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
-- TOC entry 5657 (class 0 OID 0)
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
-- TOC entry 5658 (class 0 OID 0)
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
-- TOC entry 5659 (class 0 OID 0)
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
-- TOC entry 5660 (class 0 OID 0)
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
-- TOC entry 5661 (class 0 OID 0)
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
-- TOC entry 5662 (class 0 OID 0)
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
-- TOC entry 5663 (class 0 OID 0)
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
-- TOC entry 5664 (class 0 OID 0)
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
-- TOC entry 5665 (class 0 OID 0)
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
-- TOC entry 5666 (class 0 OID 0)
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
-- TOC entry 5667 (class 0 OID 0)
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
-- TOC entry 5668 (class 0 OID 0)
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
    requiere_aprobacion boolean DEFAULT false,
    aprobado_por integer,
    aprobado_en timestamp with time zone,
    motivo_irregular text,
    rechazado boolean DEFAULT false,
    motivo_rechazo text,
    rechazado_por integer,
    rechazado_en timestamp with time zone,
    CONSTRAINT postcorte_veredicto_efectivo_check CHECK ((veredicto_efectivo = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_tarjetas_check CHECK ((veredicto_tarjetas = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))),
    CONSTRAINT postcorte_veredicto_transfer_check CHECK ((veredicto_transferencias = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text])))
);


ALTER TABLE postcorte OWNER TO floreant;

--
-- TOC entry 5669 (class 0 OID 0)
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
-- TOC entry 5670 (class 0 OID 0)
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
-- TOC entry 5671 (class 0 OID 0)
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
-- TOC entry 5672 (class 0 OID 0)
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
-- TOC entry 5673 (class 0 OID 0)
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
-- TOC entry 5674 (class 0 OID 0)
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
-- TOC entry 5675 (class 0 OID 0)
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
-- TOC entry 5676 (class 0 OID 0)
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
-- TOC entry 5677 (class 0 OID 0)
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
-- TOC entry 5678 (class 0 OID 0)
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
-- TOC entry 5679 (class 0 OID 0)
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
-- TOC entry 5680 (class 0 OID 0)
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
-- TOC entry 5681 (class 0 OID 0)
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
-- TOC entry 5682 (class 0 OID 0)
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
-- TOC entry 5683 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.fecha_requerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.fecha_requerida IS 'Fecha límite operativa';


--
-- TOC entry 5684 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.almacen_destino_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material';


--
-- TOC entry 5685 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.justificacion; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.justificacion IS 'Por qué se solicita (ej: stock bajo, evento especial)';


--
-- TOC entry 5686 (class 0 OID 0)
-- Dependencies: 366
-- Name: COLUMN purchase_requests.urgente; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_requests.urgente IS 'Marca de urgencia operativa';


--
-- TOC entry 5687 (class 0 OID 0)
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
-- TOC entry 5688 (class 0 OID 0)
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
-- TOC entry 5689 (class 0 OID 0)
-- Dependencies: 368
-- Name: TABLE purchase_suggestion_lines; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra';


--
-- TOC entry 5690 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.suggestion_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.suggestion_id IS 'FK a purchase_suggestions';


--
-- TOC entry 5691 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.item_id IS 'FK a selemti.items.id (VARCHAR!)';


--
-- TOC entry 5692 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.dias_cobertura_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.dias_cobertura_actual IS 'Días de stock restante al ritmo actual';


--
-- TOC entry 5693 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.demanda_proyectada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.demanda_proyectada IS 'Consumo esperado en próximos N días';


--
-- TOC entry 5694 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_sugerida IS 'Cantidad calculada automáticamente';


--
-- TOC entry 5695 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.qty_ajustada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.qty_ajustada IS 'Cantidad modificada manualmente por usuario';


--
-- TOC entry 5696 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN purchase_suggestion_lines.uom; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestion_lines.uom IS 'Unidad de medida';


--
-- TOC entry 5697 (class 0 OID 0)
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
-- TOC entry 5698 (class 0 OID 0)
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
-- TOC entry 5699 (class 0 OID 0)
-- Dependencies: 370
-- Name: TABLE purchase_suggestions; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE purchase_suggestions IS 'Sugerencias automáticas
   de compra basadas en stock policies';


--
-- TOC entry 5700 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.folio IS 'PSC-2025-001234';


--
-- TOC entry 5701 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.estado; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.estado IS 'PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA';


--
-- TOC entry 5702 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.prioridad IS 'URGENTE, ALTA, NORMAL, BAJA';


--
-- TOC entry 5703 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.origen IS 'AUTO, MANUAL, EVENTO_ESPECIAL';


--
-- TOC entry 5704 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.sugerido_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.sugerido_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 5705 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.revisado_por_user_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.revisado_por_user_id IS 'FK a selemti.users.id';


--
-- TOC entry 5706 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN purchase_suggestions.convertido_a_request_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN purchase_suggestions.convertido_a_request_id IS 'FK a selemti.purchase_requests.id';


--
-- TOC entry 5707 (class 0 OID 0)
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
-- TOC entry 5708 (class 0 OID 0)
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
-- TOC entry 5709 (class 0 OID 0)
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
-- TOC entry 5710 (class 0 OID 0)
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
-- TOC entry 5711 (class 0 OID 0)
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
-- TOC entry 5712 (class 0 OID 0)
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
-- TOC entry 5713 (class 0 OID 0)
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
-- TOC entry 5714 (class 0 OID 0)
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
-- TOC entry 5715 (class 0 OID 0)
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
-- TOC entry 5716 (class 0 OID 0)
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
-- TOC entry 5717 (class 0 OID 0)
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
-- TOC entry 5718 (class 0 OID 0)
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
-- TOC entry 5719 (class 0 OID 0)
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
-- TOC entry 5720 (class 0 OID 0)
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
-- TOC entry 5721 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE recipe_cost_snapshots; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON TABLE recipe_cost_snapshots IS 'Snapshots historicos de costos de recetas para auditoria y performance';


--
-- TOC entry 5722 (class 0 OID 0)
-- Dependencies: 394
-- Name: COLUMN recipe_cost_snapshots.cost_breakdown; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN recipe_cost_snapshots.cost_breakdown IS 'JSONB array con detalle: [{"item_id": "...", "item_name": "...", "qty": 1.5, "uom": "KG", "unit_cost": 45.50, "total_cost": 68.25}]';


--
-- TOC entry 5723 (class 0 OID 0)
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
-- TOC entry 5724 (class 0 OID 0)
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
-- TOC entry 5725 (class 0 OID 0)
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
-- TOC entry 5726 (class 0 OID 0)
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
-- TOC entry 5727 (class 0 OID 0)
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
-- TOC entry 5728 (class 0 OID 0)
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
-- TOC entry 5729 (class 0 OID 0)
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
-- TOC entry 5730 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.folio; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.folio IS 'Folio único de la sugerencia';


--
-- TOC entry 5731 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.tipo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.tipo IS 'COMPRA | PRODUCCION';


--
-- TOC entry 5732 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.prioridad; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.prioridad IS 'URGENTE | ALTA | NORMAL | BAJA';


--
-- TOC entry 5733 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.origen; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.origen IS 'AUTO | MANUAL | EVENTO_ESPECIAL';


--
-- TOC entry 5734 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.item_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.item_id IS 'FK to items.id';


--
-- TOC entry 5735 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_actual; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_actual IS 'Stock al momento de la sugerencia';


--
-- TOC entry 5736 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_min; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_min IS 'Mínimo según política';


--
-- TOC entry 5737 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.stock_max; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.stock_max IS 'Máximo según política';


--
-- TOC entry 5738 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.qty_sugerida; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_sugerida IS 'Cantidad sugerida a pedir/producir';


--
-- TOC entry 5739 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.qty_aprobada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.qty_aprobada IS 'Cantidad ajustada por usuario';


--
-- TOC entry 5740 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.consumo_promedio_diario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.consumo_promedio_diario IS 'Promedio últimos 7-30 días';


--
-- TOC entry 5741 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.dias_stock_restante; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.dias_stock_restante IS 'Días de inventario al ritmo actual';


--
-- TOC entry 5742 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.fecha_agotamiento_estimada; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.fecha_agotamiento_estimada IS 'Cuándo se acabaría el stock';


--
-- TOC entry 5743 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.caduca_en; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.caduca_en IS 'Auto-rechazar si no se revisa antes de esta fecha';


--
-- TOC entry 5744 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.motivo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo IS 'Por qué se sugirió';


--
-- TOC entry 5745 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.motivo_rechazo; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.motivo_rechazo IS 'Por qué se rechazó';


--
-- TOC entry 5746 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN replenishment_suggestions.notas; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN replenishment_suggestions.notas IS 'Notas del usuario';


--
-- TOC entry 5747 (class 0 OID 0)
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
-- TOC entry 5748 (class 0 OID 0)
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
-- TOC entry 5749 (class 0 OID 0)
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
-- TOC entry 5750 (class 0 OID 0)
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
-- TOC entry 5751 (class 0 OID 0)
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
-- TOC entry 5752 (class 0 OID 0)
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
-- TOC entry 5753 (class 0 OID 0)
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
-- TOC entry 5754 (class 0 OID 0)
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
    CONSTRAINT sesion_cajon_estatus_check CHECK ((estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'EN_CORTE'::text, 'CERRADA'::text])))
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
-- TOC entry 5755 (class 0 OID 0)
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
-- TOC entry 5756 (class 0 OID 0)
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
-- TOC entry 5757 (class 0 OID 0)
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
-- TOC entry 5758 (class 0 OID 0)
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
-- TOC entry 5759 (class 0 OID 0)
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
-- TOC entry 5760 (class 0 OID 0)
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
-- TOC entry 5761 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN ticket_item_modifiers.pos_code; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.pos_code IS 'Código/modificador POS (opcional).';


--
-- TOC entry 5762 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN ticket_item_modifiers.recipe_version_id; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON COLUMN ticket_item_modifiers.recipe_version_id IS 'Versión de receta aplicada al modificador.';


--
-- TOC entry 5763 (class 0 OID 0)
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
-- TOC entry 5764 (class 0 OID 0)
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
-- TOC entry 5765 (class 0 OID 0)
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
-- TOC entry 5766 (class 0 OID 0)
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
-- TOC entry 5767 (class 0 OID 0)
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
-- TOC entry 5768 (class 0 OID 0)
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
-- TOC entry 5769 (class 0 OID 0)
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
-- TOC entry 5770 (class 0 OID 0)
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
-- TOC entry 5771 (class 0 OID 0)
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
-- TOC entry 5772 (class 0 OID 0)
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
-- TOC entry 5773 (class 0 OID 0)
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
-- TOC entry 5774 (class 0 OID 0)
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
-- TOC entry 5775 (class 0 OID 0)
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
-- TOC entry 5776 (class 0 OID 0)
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
-- TOC entry 5777 (class 0 OID 0)
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
-- TOC entry 5778 (class 0 OID 0)
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
-- TOC entry 5779 (class 0 OID 0)
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
-- TOC entry 5780 (class 0 OID 0)
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
-- TOC entry 5781 (class 0 OID 0)
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
-- TOC entry 5782 (class 0 OID 0)
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
-- TOC entry 5783 (class 0 OID 0)
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
-- TOC entry 5784 (class 0 OID 0)
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
-- TOC entry 5785 (class 0 OID 0)
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
-- TOC entry 5786 (class 0 OID 0)
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
-- TOC entry 5787 (class 0 OID 0)
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
-- TOC entry 5788 (class 0 OID 0)
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
-- TOC entry 5789 (class 0 OID 0)
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
-- TOC entry 5790 (class 0 OID 0)
-- Dependencies: 472
-- Name: VIEW v_usuario; Type: COMMENT; Schema: selemti; Owner: postgres
--

COMMENT ON VIEW v_usuario IS 'Vista de compatibilidad - Mapea users â†’ formato legacy usuario';


--
-- TOC entry 691 (class 1259 OID 166269)
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
-- TOC entry 677 (class 1259 OID 166175)
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
-- TOC entry 692 (class 1259 OID 166274)
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
-- TOC entry 679 (class 1259 OID 166184)
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
-- TOC entry 680 (class 1259 OID 166188)
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
-- TOC entry 689 (class 1259 OID 166260)
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
-- TOC entry 690 (class 1259 OID 166265)
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
-- TOC entry 678 (class 1259 OID 166180)
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
-- TOC entry 696 (class 1259 OID 168494)
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

--
-- TOC entry 693 (class 1259 OID 166278)
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
-- TOC entry 694 (class 1259 OID 166283)
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

--
-- TOC entry 3792 (class 2604 OID 154047)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events ALTER COLUMN id SET DEFAULT nextval('alert_events_id_seq'::regclass);


--
-- TOC entry 3796 (class 2604 OID 154048)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules ALTER COLUMN id SET DEFAULT nextval('alert_rules_id_seq'::regclass);


--
-- TOC entry 4321 (class 2604 OID 168505)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes ALTER COLUMN id SET DEFAULT nextval('alertas_cortes_id_seq'::regclass);


--
-- TOC entry 3802 (class 2604 OID 154049)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- TOC entry 3804 (class 2604 OID 154050)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global ALTER COLUMN id SET DEFAULT nextval('audit_log_global_id_seq'::regclass);


--
-- TOC entry 3807 (class 2604 OID 154051)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria ALTER COLUMN id SET DEFAULT nextval('auditoria_id_seq'::regclass);


--
-- TOC entry 3808 (class 2604 OID 154052)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega ALTER COLUMN id SET DEFAULT nextval('bodega_id_seq'::regclass);


--
-- TOC entry 3813 (class 2604 OID 154053)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_id_seq'::regclass);


--
-- TOC entry 3815 (class 2604 OID 154054)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj ALTER COLUMN id SET DEFAULT nextval('caja_fondo_adj_id_seq'::regclass);


--
-- TOC entry 3817 (class 2604 OID 154055)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo ALTER COLUMN id SET DEFAULT nextval('caja_fondo_arqueo_id_seq'::regclass);


--
-- TOC entry 3824 (class 2604 OID 154056)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov ALTER COLUMN id SET DEFAULT nextval('caja_fondo_mov_id_seq'::regclass);


--
-- TOC entry 3825 (class 2604 OID 154057)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos ALTER COLUMN id SET DEFAULT nextval('cash_fund_arqueos_id_seq'::regclass);


--
-- TOC entry 3827 (class 2604 OID 154058)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log ALTER COLUMN id SET DEFAULT nextval('cash_fund_movement_audit_log_id_seq'::regclass);


--
-- TOC entry 3828 (class 2604 OID 154059)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements ALTER COLUMN id SET DEFAULT nextval('cash_fund_movements_id_seq'::regclass);


--
-- TOC entry 3837 (class 2604 OID 154060)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds ALTER COLUMN id SET DEFAULT nextval('cash_funds_id_seq'::regclass);


--
-- TOC entry 3840 (class 2604 OID 154061)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes ALTER COLUMN id SET DEFAULT nextval('cat_almacenes_id_seq'::regclass);


--
-- TOC entry 3842 (class 2604 OID 154062)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores ALTER COLUMN id SET DEFAULT nextval('cat_proveedores_id_seq'::regclass);


--
-- TOC entry 3844 (class 2604 OID 154063)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales ALTER COLUMN id SET DEFAULT nextval('cat_sucursales_id_seq'::regclass);


--
-- TOC entry 3846 (class 2604 OID 154064)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);


--
-- TOC entry 3849 (class 2604 OID 154065)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);


--
-- TOC entry 3852 (class 2604 OID 154066)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion ALTER COLUMN id SET DEFAULT nextval('conciliacion_id_seq'::regclass);


--
-- TOC entry 3854 (class 2604 OID 154067)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy ALTER COLUMN id SET DEFAULT nextval('conversiones_unidad_id_seq'::regclass);


--
-- TOC entry 3860 (class 2604 OID 154068)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer ALTER COLUMN id SET DEFAULT nextval('cost_layer_id_seq'::regclass);


--
-- TOC entry 3862 (class 2604 OID 154069)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- TOC entry 3863 (class 2604 OID 154070)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago ALTER COLUMN id SET DEFAULT nextval('formas_pago_id_seq'::regclass);


--
-- TOC entry 3872 (class 2604 OID 154071)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo ALTER COLUMN id SET DEFAULT nextval('hist_cost_insumo_id_seq'::regclass);


--
-- TOC entry 3873 (class 2604 OID 154072)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta ALTER COLUMN id SET DEFAULT nextval('hist_cost_receta_id_seq'::regclass);


--
-- TOC entry 3883 (class 2604 OID 154073)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item ALTER COLUMN id SET DEFAULT nextval('historial_costos_item_id_seq'::regclass);


--
-- TOC entry 3887 (class 2604 OID 154074)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta ALTER COLUMN id SET DEFAULT nextval('historial_costos_receta_id_seq'::regclass);


--
-- TOC entry 3891 (class 2604 OID 154075)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo ALTER COLUMN id SET DEFAULT nextval('insumo_id_seq'::regclass);


--
-- TOC entry 3900 (class 2604 OID 154076)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_presentacion_id_seq'::regclass);


--
-- TOC entry 3907 (class 2604 OID 154077)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion ALTER COLUMN id SET DEFAULT nextval('insumo_proveedor_presentacion_id_seq'::regclass);


--
-- TOC entry 3912 (class 2604 OID 154078)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_id_seq'::regclass);


--
-- TOC entry 3917 (class 2604 OID 154079)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_det_id_seq'::regclass);


--
-- TOC entry 3920 (class 2604 OID 154080)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log ALTER COLUMN id SET DEFAULT nextval('inv_consumo_pos_log_id_seq'::regclass);


--
-- TOC entry 3925 (class 2604 OID 154081)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy ALTER COLUMN id SET DEFAULT nextval('inv_stock_policy_id_seq'::regclass);


--
-- TOC entry 3930 (class 2604 OID 154082)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch ALTER COLUMN id SET DEFAULT nextval('inventory_batch_id_seq'::regclass);


--
-- TOC entry 3938 (class 2604 OID 154083)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines ALTER COLUMN id SET DEFAULT nextval('inventory_count_lines_id_seq'::regclass);


--
-- TOC entry 3942 (class 2604 OID 154084)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts ALTER COLUMN id SET DEFAULT nextval('inventory_counts_id_seq'::regclass);


--
-- TOC entry 3950 (class 2604 OID 154085)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes ALTER COLUMN id SET DEFAULT nextval('inventory_wastes_id_seq'::regclass);


--
-- TOC entry 3952 (class 2604 OID 154086)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories ALTER COLUMN id SET DEFAULT nextval('item_categories_id_seq'::regclass);


--
-- TOC entry 3964 (class 2604 OID 154087)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices ALTER COLUMN id SET DEFAULT nextval('item_vendor_prices_id_seq'::regclass);


--
-- TOC entry 3984 (class 2604 OID 154088)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue ALTER COLUMN id SET DEFAULT nextval('job_recalc_queue_id_seq'::regclass);


--
-- TOC entry 3987 (class 2604 OID 154089)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- TOC entry 3990 (class 2604 OID 154090)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles ALTER COLUMN id SET DEFAULT nextval('labor_roles_id_seq'::regclass);


--
-- TOC entry 3993 (class 2604 OID 154091)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote ALTER COLUMN id SET DEFAULT nextval('lote_id_seq'::regclass);


--
-- TOC entry 4002 (class 2604 OID 154092)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots ALTER COLUMN id SET DEFAULT nextval('menu_engineering_snapshots_id_seq'::regclass);


--
-- TOC entry 4004 (class 2604 OID 154093)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map ALTER COLUMN id SET DEFAULT nextval('menu_item_sync_map_id_seq'::regclass);


--
-- TOC entry 4006 (class 2604 OID 154094)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- TOC entry 4007 (class 2604 OID 154095)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma ALTER COLUMN id SET DEFAULT nextval('merma_id_seq'::regclass);


--
-- TOC entry 4011 (class 2604 OID 154096)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations ALTER COLUMN id SET DEFAULT nextval('migrations_id_seq'::regclass);


--
-- TOC entry 4014 (class 2604 OID 154097)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos ALTER COLUMN id SET DEFAULT nextval('modificadores_pos_id_seq'::regclass);


--
-- TOC entry 4016 (class 2604 OID 154098)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv ALTER COLUMN id SET DEFAULT nextval('mov_inv_id_seq'::regclass);


--
-- TOC entry 4049 (class 2604 OID 154099)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab ALTER COLUMN id SET DEFAULT nextval('op_cab_id_seq'::regclass);


--
-- TOC entry 4052 (class 2604 OID 154100)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo ALTER COLUMN id SET DEFAULT nextval('op_insumo_id_seq'::regclass);


--
-- TOC entry 4053 (class 2604 OID 154101)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab ALTER COLUMN id SET DEFAULT nextval('op_produccion_cab_id_seq'::regclass);


--
-- TOC entry 4060 (class 2604 OID 154102)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions ALTER COLUMN id SET DEFAULT nextval('overhead_definitions_id_seq'::regclass);


--
-- TOC entry 4069 (class 2604 OID 154103)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal ALTER COLUMN id SET DEFAULT nextval('param_sucursal_id_seq'::regclass);


--
-- TOC entry 4072 (class 2604 OID 154104)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log ALTER COLUMN id SET DEFAULT nextval('perdida_log_id_seq'::regclass);


--
-- TOC entry 4074 (class 2604 OID 154105)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- TOC entry 4075 (class 2604 OID 154106)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('personal_access_tokens_id_seq'::regclass);


--
-- TOC entry 4086 (class 2604 OID 154107)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log ALTER COLUMN id SET DEFAULT nextval('pos_reprocess_log_id_seq'::regclass);


--
-- TOC entry 4090 (class 2604 OID 154108)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log ALTER COLUMN id SET DEFAULT nextval('pos_reverse_log_id_seq'::regclass);


--
-- TOC entry 4098 (class 2604 OID 154109)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches ALTER COLUMN id SET DEFAULT nextval('pos_sync_batches_id_seq'::regclass);


--
-- TOC entry 4100 (class 2604 OID 154110)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs ALTER COLUMN id SET DEFAULT nextval('pos_sync_logs_id_seq'::regclass);


--
-- TOC entry 4115 (class 2604 OID 154111)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte ALTER COLUMN id SET DEFAULT nextval('postcorte_id_seq'::regclass);


--
-- TOC entry 4125 (class 2604 OID 154112)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte ALTER COLUMN id SET DEFAULT nextval('precorte_id_seq'::regclass);


--
-- TOC entry 4128 (class 2604 OID 154113)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo ALTER COLUMN id SET DEFAULT nextval('precorte_efectivo_id_seq'::regclass);


--
-- TOC entry 4131 (class 2604 OID 154114)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros ALTER COLUMN id SET DEFAULT nextval('precorte_otros_id_seq'::regclass);


--
-- TOC entry 4134 (class 2604 OID 154115)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab ALTER COLUMN id SET DEFAULT nextval('prod_cab_id_seq'::regclass);


--
-- TOC entry 4136 (class 2604 OID 154116)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det ALTER COLUMN id SET DEFAULT nextval('prod_det_id_seq'::regclass);


--
-- TOC entry 4137 (class 2604 OID 154117)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs ALTER COLUMN id SET DEFAULT nextval('production_order_inputs_id_seq'::regclass);


--
-- TOC entry 4138 (class 2604 OID 154118)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs ALTER COLUMN id SET DEFAULT nextval('production_order_outputs_id_seq'::regclass);


--
-- TOC entry 4143 (class 2604 OID 154119)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders ALTER COLUMN id SET DEFAULT nextval('production_orders_id_seq'::regclass);


--
-- TOC entry 4145 (class 2604 OID 154120)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents ALTER COLUMN id SET DEFAULT nextval('purchase_documents_id_seq'::regclass);


--
-- TOC entry 4148 (class 2604 OID 154121)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines ALTER COLUMN id SET DEFAULT nextval('purchase_order_lines_id_seq'::regclass);


--
-- TOC entry 4154 (class 2604 OID 154122)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders ALTER COLUMN id SET DEFAULT nextval('purchase_orders_id_seq'::regclass);


--
-- TOC entry 4156 (class 2604 OID 154123)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines ALTER COLUMN id SET DEFAULT nextval('purchase_request_lines_id_seq'::regclass);


--
-- TOC entry 4161 (class 2604 OID 154124)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests ALTER COLUMN id SET DEFAULT nextval('purchase_requests_id_seq'::regclass);


--
-- TOC entry 4166 (class 2604 OID 154125)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines ALTER COLUMN id SET DEFAULT nextval('purchase_suggestion_lines_id_seq'::regclass);


--
-- TOC entry 4175 (class 2604 OID 154126)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions ALTER COLUMN id SET DEFAULT nextval('purchase_suggestions_id_seq'::regclass);


--
-- TOC entry 4177 (class 2604 OID 154127)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quote_lines_id_seq'::regclass);


--
-- TOC entry 4184 (class 2604 OID 154128)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes ALTER COLUMN id SET DEFAULT nextval('purchase_vendor_quotes_id_seq'::regclass);


--
-- TOC entry 4185 (class 2604 OID 154129)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log ALTER COLUMN id SET DEFAULT nextval('recalc_log_id_seq'::regclass);


--
-- TOC entry 4186 (class 2604 OID 154130)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos ALTER COLUMN id SET DEFAULT nextval('recepcion_adjuntos_id_seq'::regclass);


--
-- TOC entry 4187 (class 2604 OID 154131)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab ALTER COLUMN id SET DEFAULT nextval('recepcion_cab_id_seq'::regclass);


--
-- TOC entry 4193 (class 2604 OID 154132)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det ALTER COLUMN id SET DEFAULT nextval('recepcion_det_id_seq'::regclass);


--
-- TOC entry 4196 (class 2604 OID 154133)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta ALTER COLUMN id SET DEFAULT nextval('receta_id_seq'::regclass);


--
-- TOC entry 4035 (class 2604 OID 154134)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det ALTER COLUMN id SET DEFAULT nextval('receta_det_id_seq'::regclass);


--
-- TOC entry 4197 (class 2604 OID 154135)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo ALTER COLUMN id SET DEFAULT nextval('receta_insumo_id_seq'::regclass);


--
-- TOC entry 4203 (class 2604 OID 154136)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow ALTER COLUMN id SET DEFAULT nextval('receta_shadow_id_seq'::regclass);


--
-- TOC entry 4041 (class 2604 OID 154137)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version ALTER COLUMN id SET DEFAULT nextval('receta_version_id_seq'::regclass);


--
-- TOC entry 4208 (class 2604 OID 154138)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_cost_history_id_seq'::regclass);


--
-- TOC entry 4214 (class 2604 OID 154139)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots ALTER COLUMN id SET DEFAULT nextval('recipe_cost_snapshots_id_seq'::regclass);


--
-- TOC entry 4222 (class 2604 OID 154140)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history ALTER COLUMN id SET DEFAULT nextval('recipe_extended_cost_history_id_seq'::regclass);


--
-- TOC entry 4225 (class 2604 OID 154141)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps ALTER COLUMN id SET DEFAULT nextval('recipe_labor_steps_id_seq'::regclass);


--
-- TOC entry 4226 (class 2604 OID 154142)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations ALTER COLUMN id SET DEFAULT nextval('recipe_overhead_allocations_id_seq'::regclass);


--
-- TOC entry 4227 (class 2604 OID 154143)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items ALTER COLUMN id SET DEFAULT nextval('recipe_version_items_id_seq'::regclass);


--
-- TOC entry 4230 (class 2604 OID 154144)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions ALTER COLUMN id SET DEFAULT nextval('recipe_versions_id_seq'::regclass);


--
-- TOC entry 4235 (class 2604 OID 154145)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions ALTER COLUMN id SET DEFAULT nextval('replenishment_suggestions_id_seq'::regclass);


--
-- TOC entry 4317 (class 2604 OID 156909)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions ALTER COLUMN id SET DEFAULT nextval('report_definitions_id_seq'::regclass);


--
-- TOC entry 4236 (class 2604 OID 154147)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites ALTER COLUMN id SET DEFAULT nextval('report_favorites_id_seq'::regclass);


--
-- TOC entry 4319 (class 2604 OID 156923)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs ALTER COLUMN id SET DEFAULT nextval('report_runs_id_seq'::regclass);


--
-- TOC entry 4237 (class 2604 OID 154149)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol ALTER COLUMN id SET DEFAULT nextval('rol_id_seq'::regclass);


--
-- TOC entry 4238 (class 2604 OID 154150)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- TOC entry 4025 (class 2604 OID 154151)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon ALTER COLUMN id SET DEFAULT nextval('sesion_cajon_id_seq'::regclass);


--
-- TOC entry 4239 (class 2604 OID 154152)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab ALTER COLUMN id SET DEFAULT nextval('sol_prod_cab_id_seq'::regclass);


--
-- TOC entry 4244 (class 2604 OID 154153)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det ALTER COLUMN id SET DEFAULT nextval('sol_prod_det_id_seq'::regclass);


--
-- TOC entry 4249 (class 2604 OID 154154)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy ALTER COLUMN id SET DEFAULT nextval('stock_policy_id_seq'::regclass);


--
-- TOC entry 4253 (class 2604 OID 154155)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal ALTER COLUMN id SET DEFAULT nextval('sucursal_almacen_terminal_id_seq'::regclass);


--
-- TOC entry 4256 (class 2604 OID 154156)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo ALTER COLUMN id SET DEFAULT nextval('ticket_det_consumo_id_seq'::regclass);


--
-- TOC entry 4260 (class 2604 OID 154157)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers ALTER COLUMN id SET DEFAULT nextval('ticket_item_modifiers_id_seq'::regclass);


--
-- TOC entry 4265 (class 2604 OID 154158)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab ALTER COLUMN id SET DEFAULT nextval('ticket_venta_cab_id_seq'::regclass);


--
-- TOC entry 4267 (class 2604 OID 154159)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det ALTER COLUMN id SET DEFAULT nextval('ticket_venta_det_id_seq'::regclass);


--
-- TOC entry 4274 (class 2604 OID 154160)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab ALTER COLUMN id SET DEFAULT nextval('transfer_cab_id_seq'::regclass);


--
-- TOC entry 4276 (class 2604 OID 154161)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det ALTER COLUMN id SET DEFAULT nextval('transfer_det_id_seq'::regclass);


--
-- TOC entry 4277 (class 2604 OID 154162)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab ALTER COLUMN id SET DEFAULT nextval('traspaso_cab_id_seq'::regclass);


--
-- TOC entry 4283 (class 2604 OID 154163)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det ALTER COLUMN id SET DEFAULT nextval('traspaso_det_id_seq'::regclass);


--
-- TOC entry 4284 (class 2604 OID 154164)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidad_medida_id_seq'::regclass);


--
-- TOC entry 4293 (class 2604 OID 154165)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy ALTER COLUMN id SET DEFAULT nextval('unidades_medida_id_seq'::regclass);


--
-- TOC entry 4298 (class 2604 OID 154166)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy ALTER COLUMN id SET DEFAULT nextval('uom_conversion_id_seq'::regclass);


--
-- TOC entry 4308 (class 2604 OID 154167)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 4316 (class 2604 OID 154168)
-- Name: id; Type: DEFAULT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);


--
-- TOC entry 4325 (class 2606 OID 154380)
-- Name: alert_events_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_events
    ADD CONSTRAINT alert_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4328 (class 2606 OID 154382)
-- Name: alert_rules_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4946 (class 2606 OID 168509)
-- Name: alertas_cortes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_pkey PRIMARY KEY (id);


--
-- TOC entry 4330 (class 2606 OID 154384)
-- Name: almacen_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id);


--
-- TOC entry 4342 (class 2606 OID 154386)
-- Name: audit_log_global_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_pkey PRIMARY KEY (id);


--
-- TOC entry 4332 (class 2606 OID 154388)
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4348 (class 2606 OID 154390)
-- Name: auditoria_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- TOC entry 4350 (class 2606 OID 154392)
-- Name: bodega_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_pkey PRIMARY KEY (id);


--
-- TOC entry 4352 (class 2606 OID 154394)
-- Name: bodega_sucursal_id_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_codigo_key UNIQUE (sucursal_id, codigo);


--
-- TOC entry 4356 (class 2606 OID 154396)
-- Name: cache_locks_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- TOC entry 4354 (class 2606 OID 154398)
-- Name: cache_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- TOC entry 4360 (class 2606 OID 154400)
-- Name: caja_fondo_adj_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_pkey PRIMARY KEY (id);


--
-- TOC entry 4362 (class 2606 OID 154402)
-- Name: caja_fondo_arqueo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_pkey PRIMARY KEY (id);


--
-- TOC entry 4364 (class 2606 OID 154404)
-- Name: caja_fondo_mov_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_pkey PRIMARY KEY (id);


--
-- TOC entry 4358 (class 2606 OID 154406)
-- Name: caja_fondo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo
    ADD CONSTRAINT caja_fondo_pkey PRIMARY KEY (id);


--
-- TOC entry 4366 (class 2606 OID 154408)
-- Name: caja_fondo_usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_pkey PRIMARY KEY (fondo_id, user_id);


--
-- TOC entry 4369 (class 2606 OID 154410)
-- Name: cash_fund_arqueos_cash_fund_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_unique UNIQUE (cash_fund_id);


--
-- TOC entry 4372 (class 2606 OID 154412)
-- Name: cash_fund_arqueos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_pkey PRIMARY KEY (id);


--
-- TOC entry 4374 (class 2606 OID 154414)
-- Name: cash_fund_movement_audit_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT cash_fund_movement_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4382 (class 2606 OID 154416)
-- Name: cash_fund_movements_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 4387 (class 2606 OID 154418)
-- Name: cash_funds_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_pkey PRIMARY KEY (id);


--
-- TOC entry 4391 (class 2606 OID 154420)
-- Name: cat_almacenes_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_clave_unique UNIQUE (clave);


--
-- TOC entry 4393 (class 2606 OID 154422)
-- Name: cat_almacenes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_pkey PRIMARY KEY (id);


--
-- TOC entry 4395 (class 2606 OID 154424)
-- Name: cat_proveedores_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_pkey PRIMARY KEY (id);


--
-- TOC entry 4397 (class 2606 OID 154426)
-- Name: cat_proveedores_rfc_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_proveedores
    ADD CONSTRAINT cat_proveedores_rfc_unique UNIQUE (rfc);


--
-- TOC entry 4401 (class 2606 OID 154428)
-- Name: cat_sucursales_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_clave_unique UNIQUE (clave);


--
-- TOC entry 4403 (class 2606 OID 154430)
-- Name: cat_sucursales_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_sucursales
    ADD CONSTRAINT cat_sucursales_pkey PRIMARY KEY (id);


--
-- TOC entry 4406 (class 2606 OID 154432)
-- Name: cat_unidades_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);


--
-- TOC entry 4408 (class 2606 OID 154434)
-- Name: cat_unidades_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_unidades
    ADD CONSTRAINT cat_unidades_pkey PRIMARY KEY (id);


--
-- TOC entry 4413 (class 2606 OID 154436)
-- Name: cat_uom_conversion_origen_id_destino_id_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_destino_id_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4415 (class 2606 OID 154438)
-- Name: cat_uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4417 (class 2606 OID 154440)
-- Name: cat_uom_conversion_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);


--
-- TOC entry 4422 (class 2606 OID 154442)
-- Name: conciliacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4424 (class 2606 OID 154444)
-- Name: conciliacion_postcorte_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_key UNIQUE (postcorte_id);


--
-- TOC entry 4426 (class 2606 OID 154446)
-- Name: conversiones_unidad_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_pkey PRIMARY KEY (id);


--
-- TOC entry 4428 (class 2606 OID 154448)
-- Name: conversiones_unidad_unidad_origen_id_unidad_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_unidad_destino_id_key UNIQUE (unidad_origen_id, unidad_destino_id);


--
-- TOC entry 4430 (class 2606 OID 154450)
-- Name: cost_layer_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_pkey PRIMARY KEY (id);


--
-- TOC entry 4434 (class 2606 OID 154452)
-- Name: failed_jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4436 (class 2606 OID 154454)
-- Name: failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- TOC entry 4438 (class 2606 OID 154456)
-- Name: formas_pago_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY formas_pago
    ADD CONSTRAINT formas_pago_pkey PRIMARY KEY (id);


--
-- TOC entry 4442 (class 2606 OID 154458)
-- Name: hist_cost_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4446 (class 2606 OID 154460)
-- Name: hist_cost_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4449 (class 2606 OID 154462)
-- Name: historial_costos_item_item_id_fecha_efectiva_version_datos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fecha_efectiva_version_datos_key UNIQUE (item_id, fecha_efectiva, version_datos);


--
-- TOC entry 4451 (class 2606 OID 154464)
-- Name: historial_costos_item_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4454 (class 2606 OID 154466)
-- Name: historial_costos_receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4457 (class 2606 OID 156389)
-- Name: insumo_codigo_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_codigo_unique UNIQUE (codigo);


--
-- TOC entry 4459 (class 2606 OID 154470)
-- Name: insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4463 (class 2606 OID 154472)
-- Name: insumo_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4465 (class 2606 OID 154474)
-- Name: insumo_proveedor_presentacion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_pkey PRIMARY KEY (id);


--
-- TOC entry 4461 (class 2606 OID 154476)
-- Name: insumo_sku_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_sku_key UNIQUE (sku);


--
-- TOC entry 4478 (class 2606 OID 154478)
-- Name: inv_consumo_pos_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4483 (class 2606 OID 154480)
-- Name: inv_consumo_pos_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_log
    ADD CONSTRAINT inv_consumo_pos_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4471 (class 2606 OID 154482)
-- Name: inv_consumo_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4476 (class 2606 OID 154484)
-- Name: inv_consumo_pos_ticket_id_ticket_item_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos
    ADD CONSTRAINT inv_consumo_pos_ticket_id_ticket_item_id_key UNIQUE (ticket_id, ticket_item_id);


--
-- TOC entry 4486 (class 2606 OID 154486)
-- Name: inv_stock_policy_item_store_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_store_unique UNIQUE (item_id, sucursal_id);


--
-- TOC entry 4488 (class 2606 OID 154488)
-- Name: inv_stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4493 (class 2606 OID 154490)
-- Name: inventory_batch_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_pkey PRIMARY KEY (id);


--
-- TOC entry 4499 (class 2606 OID 154492)
-- Name: inventory_count_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_count_lines
    ADD CONSTRAINT inventory_count_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4504 (class 2606 OID 154494)
-- Name: inventory_counts_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_folio_unique UNIQUE (folio);


--
-- TOC entry 4506 (class 2606 OID 154496)
-- Name: inventory_counts_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_counts
    ADD CONSTRAINT inventory_counts_pkey PRIMARY KEY (id);


--
-- TOC entry 4517 (class 2606 OID 154498)
-- Name: inventory_wastes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_wastes
    ADD CONSTRAINT inventory_wastes_pkey PRIMARY KEY (id);


--
-- TOC entry 4521 (class 2606 OID 154500)
-- Name: item_categories_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_codigo_key UNIQUE (codigo);


--
-- TOC entry 4523 (class 2606 OID 154502)
-- Name: item_categories_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4525 (class 2606 OID 154504)
-- Name: item_categories_slug_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_categories
    ADD CONSTRAINT item_categories_slug_key UNIQUE (slug);


--
-- TOC entry 4527 (class 2606 OID 154506)
-- Name: item_category_counters_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_category_counters
    ADD CONSTRAINT item_category_counters_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4529 (class 2606 OID 154508)
-- Name: item_vendor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion);


--
-- TOC entry 4534 (class 2606 OID 154510)
-- Name: item_vendor_prices_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor_prices
    ADD CONSTRAINT item_vendor_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 4546 (class 2606 OID 154512)
-- Name: items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- TOC entry 4549 (class 2606 OID 154514)
-- Name: job_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4551 (class 2606 OID 154516)
-- Name: job_recalc_queue_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY job_recalc_queue
    ADD CONSTRAINT job_recalc_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 4553 (class 2606 OID 154518)
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 4557 (class 2606 OID 154520)
-- Name: labor_roles_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_clave_unique UNIQUE (clave);


--
-- TOC entry 4559 (class 2606 OID 154522)
-- Name: labor_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY labor_roles
    ADD CONSTRAINT labor_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4563 (class 2606 OID 154524)
-- Name: lote_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- TOC entry 4565 (class 2606 OID 154526)
-- Name: menu_engineering_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT menu_engineering_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4569 (class 2606 OID 154528)
-- Name: menu_item_sync_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT menu_item_sync_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4573 (class 2606 OID 154530)
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4581 (class 2606 OID 154532)
-- Name: merma_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_pkey PRIMARY KEY (id);


--
-- TOC entry 4583 (class 2606 OID 154534)
-- Name: migrations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4586 (class 2606 OID 154536)
-- Name: model_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- TOC entry 4589 (class 2606 OID 154538)
-- Name: model_has_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- TOC entry 4591 (class 2606 OID 154540)
-- Name: modificadores_pos_codigo_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_codigo_pos_key UNIQUE (codigo_pos);


--
-- TOC entry 4593 (class 2606 OID 154542)
-- Name: modificadores_pos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_pkey PRIMARY KEY (id);


--
-- TOC entry 4607 (class 2606 OID 154544)
-- Name: mov_inv_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_pkey PRIMARY KEY (id);


--
-- TOC entry 4635 (class 2606 OID 154546)
-- Name: op_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4639 (class 2606 OID 154548)
-- Name: op_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4641 (class 2606 OID 154550)
-- Name: op_produccion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4643 (class 2606 OID 154552)
-- Name: op_yield_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_pkey PRIMARY KEY (op_id);


--
-- TOC entry 4646 (class 2606 OID 154554)
-- Name: overhead_definitions_clave_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_clave_unique UNIQUE (clave);


--
-- TOC entry 4648 (class 2606 OID 154556)
-- Name: overhead_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY overhead_definitions
    ADD CONSTRAINT overhead_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4651 (class 2606 OID 154558)
-- Name: param_sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4653 (class 2606 OID 154560)
-- Name: param_sucursal_sucursal_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY param_sucursal
    ADD CONSTRAINT param_sucursal_sucursal_id_key UNIQUE (sucursal_id);


--
-- TOC entry 4655 (class 2606 OID 154562)
-- Name: password_reset_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- TOC entry 4658 (class 2606 OID 154564)
-- Name: perdida_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4660 (class 2606 OID 154566)
-- Name: permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4662 (class 2606 OID 154568)
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4664 (class 2606 OID 154570)
-- Name: personal_access_tokens_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4666 (class 2606 OID 154572)
-- Name: personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- TOC entry 4513 (class 2606 OID 154574)
-- Name: pk_inventory_snapshot; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT pk_inventory_snapshot PRIMARY KEY (snapshot_date, branch_id, item_id);


--
-- TOC entry 4672 (class 2606 OID 154576)
-- Name: pos_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);


--
-- TOC entry 4675 (class 2606 OID 154578)
-- Name: pos_modifiers_map_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pkey PRIMARY KEY (id);


--
-- TOC entry 4677 (class 2606 OID 154580)
-- Name: pos_modifiers_map_pos_modifier_code_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_modifiers_map
    ADD CONSTRAINT pos_modifiers_map_pos_modifier_code_key UNIQUE (pos_modifier_code);


--
-- TOC entry 4682 (class 2606 OID 154582)
-- Name: pos_reprocess_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reprocess_log
    ADD CONSTRAINT pos_reprocess_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4687 (class 2606 OID 154584)
-- Name: pos_reverse_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_reverse_log
    ADD CONSTRAINT pos_reverse_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4689 (class 2606 OID 154586)
-- Name: pos_sync_batches_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_batches
    ADD CONSTRAINT pos_sync_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 4691 (class 2606 OID 154588)
-- Name: pos_sync_logs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT pos_sync_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4697 (class 2606 OID 154590)
-- Name: postcorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4708 (class 2606 OID 154592)
-- Name: precorte_efectivo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_pkey PRIMARY KEY (id);


--
-- TOC entry 4712 (class 2606 OID 154594)
-- Name: precorte_otros_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_pkey PRIMARY KEY (id);


--
-- TOC entry 4702 (class 2606 OID 154596)
-- Name: precorte_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_pkey PRIMARY KEY (id);


--
-- TOC entry 4714 (class 2606 OID 154598)
-- Name: prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4716 (class 2606 OID 154600)
-- Name: prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4720 (class 2606 OID 154602)
-- Name: production_order_inputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_inputs
    ADD CONSTRAINT production_order_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4725 (class 2606 OID 154604)
-- Name: production_order_outputs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_order_outputs
    ADD CONSTRAINT production_order_outputs_pkey PRIMARY KEY (id);


--
-- TOC entry 4730 (class 2606 OID 154606)
-- Name: production_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4733 (class 2606 OID 154608)
-- Name: production_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4738 (class 2606 OID 154610)
-- Name: proveedor_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4741 (class 2606 OID 154612)
-- Name: purchase_documents_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_documents
    ADD CONSTRAINT purchase_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 4747 (class 2606 OID 154614)
-- Name: purchase_order_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4750 (class 2606 OID 154616)
-- Name: purchase_orders_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_folio_unique UNIQUE (folio);


--
-- TOC entry 4752 (class 2606 OID 154618)
-- Name: purchase_orders_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4756 (class 2606 OID 154620)
-- Name: purchase_request_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_request_lines
    ADD CONSTRAINT purchase_request_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4763 (class 2606 OID 154622)
-- Name: purchase_requests_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_folio_unique UNIQUE (folio);


--
-- TOC entry 4765 (class 2606 OID 154624)
-- Name: purchase_requests_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 4771 (class 2606 OID 154626)
-- Name: purchase_suggestion_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT purchase_suggestion_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4779 (class 2606 OID 154628)
-- Name: purchase_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT purchase_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4784 (class 2606 OID 154630)
-- Name: purchase_vendor_quote_lines_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quote_lines
    ADD CONSTRAINT purchase_vendor_quote_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 4789 (class 2606 OID 154632)
-- Name: purchase_vendor_quotes_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_vendor_quotes
    ADD CONSTRAINT purchase_vendor_quotes_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 154634)
-- Name: recalc_log_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4794 (class 2606 OID 154636)
-- Name: recepcion_adjuntos_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_adjuntos
    ADD CONSTRAINT recepcion_adjuntos_pkey PRIMARY KEY (id);


--
-- TOC entry 4798 (class 2606 OID 154638)
-- Name: recepcion_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4804 (class 2606 OID 154640)
-- Name: recepcion_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4621 (class 2606 OID 154642)
-- Name: receta_cab_codigo_plato_pos_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_codigo_plato_pos_key UNIQUE (codigo_plato_pos);


--
-- TOC entry 4623 (class 2606 OID 154644)
-- Name: receta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_cab
    ADD CONSTRAINT receta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4806 (class 2606 OID 154646)
-- Name: receta_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_codigo_key UNIQUE (codigo);


--
-- TOC entry 4625 (class 2606 OID 154648)
-- Name: receta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4814 (class 2606 OID 154650)
-- Name: receta_insumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4816 (class 2606 OID 154652)
-- Name: receta_insumo_receta_version_id_insumo_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_insumo_id_key UNIQUE (receta_version_id, item_id);


--
-- TOC entry 4808 (class 2606 OID 154654)
-- Name: receta_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- TOC entry 4818 (class 2606 OID 154656)
-- Name: receta_shadow_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_shadow
    ADD CONSTRAINT receta_shadow_pkey PRIMARY KEY (id);


--
-- TOC entry 4629 (class 2606 OID 154658)
-- Name: receta_version_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_pkey PRIMARY KEY (id);


--
-- TOC entry 4631 (class 2606 OID 154660)
-- Name: receta_version_receta_id_version_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_version_key UNIQUE (receta_id, version);


--
-- TOC entry 4821 (class 2606 OID 154662)
-- Name: recipe_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_history
    ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4825 (class 2606 OID 154664)
-- Name: recipe_cost_snapshots_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT recipe_cost_snapshots_pkey PRIMARY KEY (id);


--
-- TOC entry 4828 (class 2606 OID 154666)
-- Name: recipe_extended_cost_history_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_extended_cost_history
    ADD CONSTRAINT recipe_extended_cost_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4831 (class 2606 OID 154668)
-- Name: recipe_labor_steps_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_labor_steps
    ADD CONSTRAINT recipe_labor_steps_pkey PRIMARY KEY (id);


--
-- TOC entry 4835 (class 2606 OID 154670)
-- Name: recipe_overhead_allocations_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 4837 (class 2606 OID 154672)
-- Name: recipe_overhead_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_overhead_allocations
    ADD CONSTRAINT recipe_overhead_unique UNIQUE (recipe_id, overhead_id);


--
-- TOC entry 4840 (class 2606 OID 154674)
-- Name: recipe_version_items_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_version_items
    ADD CONSTRAINT recipe_version_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4842 (class 2606 OID 154676)
-- Name: recipe_versions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_versions
    ADD CONSTRAINT recipe_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4847 (class 2606 OID 154678)
-- Name: replenishment_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4850 (class 2606 OID 154680)
-- Name: replenishment_suggestions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY replenishment_suggestions
    ADD CONSTRAINT replenishment_suggestions_pkey PRIMARY KEY (id);


--
-- TOC entry 4939 (class 2606 OID 156915)
-- Name: report_definitions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- TOC entry 4859 (class 2606 OID 154684)
-- Name: report_favorites_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_favorites
    ADD CONSTRAINT report_favorites_pkey PRIMARY KEY (id);


--
-- TOC entry 4944 (class 2606 OID 156929)
-- Name: report_runs_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT report_runs_pkey PRIMARY KEY (id);


--
-- TOC entry 4862 (class 2606 OID 154688)
-- Name: rol_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 4864 (class 2606 OID 154690)
-- Name: rol_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 4866 (class 2606 OID 154692)
-- Name: role_has_permissions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- TOC entry 4868 (class 2606 OID 154694)
-- Name: roles_name_guard_name_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- TOC entry 4870 (class 2606 OID 154696)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4567 (class 2606 OID 154698)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_period_start_pe; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_period_start_pe UNIQUE (menu_item_id, period_start, period_end);


--
-- TOC entry 4571 (class 2606 OID 154700)
-- Name: selemti_menu_item_sync_map_pos_identifier_channel_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_pos_identifier_channel_unique UNIQUE (pos_identifier, channel);


--
-- TOC entry 4575 (class 2606 OID 154702)
-- Name: selemti_menu_items_plu_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT selemti_menu_items_plu_unique UNIQUE (plu);


--
-- TOC entry 4781 (class 2606 OID 154704)
-- Name: selemti_purchase_suggestions_folio_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT selemti_purchase_suggestions_folio_unique UNIQUE (folio);


--
-- TOC entry 4941 (class 2606 OID 156917)
-- Name: selemti_report_definitions_slug_unique; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_definitions
    ADD CONSTRAINT selemti_report_definitions_slug_unique UNIQUE (slug);


--
-- TOC entry 4612 (class 2606 OID 154708)
-- Name: sesion_cajon_pkey; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_pkey PRIMARY KEY (id);


--
-- TOC entry 4614 (class 2606 OID 154710)
-- Name: sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY sesion_cajon
    ADD CONSTRAINT sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key UNIQUE (terminal_id, cajero_usuario_id, apertura_ts);


--
-- TOC entry 4873 (class 2606 OID 154712)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 4876 (class 2606 OID 154714)
-- Name: sol_prod_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_cab
    ADD CONSTRAINT sol_prod_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4878 (class 2606 OID 154716)
-- Name: sol_prod_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4883 (class 2606 OID 154718)
-- Name: stock_policy_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_pkey PRIMARY KEY (id);


--
-- TOC entry 4888 (class 2606 OID 154720)
-- Name: sucursal_almacen_terminal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal_almacen_terminal
    ADD CONSTRAINT sucursal_almacen_terminal_pkey PRIMARY KEY (id);


--
-- TOC entry 4885 (class 2606 OID 154722)
-- Name: sucursal_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id);


--
-- TOC entry 4893 (class 2606 OID 154724)
-- Name: ticket_det_consumo_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_pkey PRIMARY KEY (id);


--
-- TOC entry 4895 (class 2606 OID 154726)
-- Name: ticket_item_modifiers_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_item_modifiers
    ADD CONSTRAINT ticket_item_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 4900 (class 2606 OID 154728)
-- Name: ticket_venta_cab_numero_ticket_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_numero_ticket_key UNIQUE (numero_ticket);


--
-- TOC entry 4902 (class 2606 OID 154730)
-- Name: ticket_venta_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_cab
    ADD CONSTRAINT ticket_venta_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4904 (class 2606 OID 154732)
-- Name: ticket_venta_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4906 (class 2606 OID 154734)
-- Name: transfer_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_cab
    ADD CONSTRAINT transfer_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4908 (class 2606 OID 154736)
-- Name: transfer_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4911 (class 2606 OID 154738)
-- Name: traspaso_cab_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_pkey PRIMARY KEY (id);


--
-- TOC entry 4915 (class 2606 OID 154740)
-- Name: traspaso_det_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_pkey PRIMARY KEY (id);


--
-- TOC entry 4917 (class 2606 OID 154742)
-- Name: unidad_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4919 (class 2606 OID 154744)
-- Name: unidad_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidad_medida_legacy
    ADD CONSTRAINT unidad_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4921 (class 2606 OID 154746)
-- Name: unidades_medida_codigo_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_codigo_key UNIQUE (codigo);


--
-- TOC entry 4923 (class 2606 OID 154748)
-- Name: unidades_medida_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY unidades_medida_legacy
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id);


--
-- TOC entry 4925 (class 2606 OID 154750)
-- Name: uom_conversion_origen_id_destino_id_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_destino_id_key UNIQUE (origen_id, destino_id);


--
-- TOC entry 4927 (class 2606 OID 154752)
-- Name: uom_conversion_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_pkey PRIMARY KEY (id);


--
-- TOC entry 4699 (class 2606 OID 154754)
-- Name: uq_postcorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4705 (class 2606 OID 154756)
-- Name: uq_precorte_sesion_id; Type: CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT uq_precorte_sesion_id UNIQUE (sesion_id);


--
-- TOC entry 4773 (class 2606 OID 154758)
-- Name: uq_psuggline_suggestion_item; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT uq_psuggline_suggestion_item UNIQUE (suggestion_id, item_id);


--
-- TOC entry 4929 (class 2606 OID 154760)
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 4931 (class 2606 OID 154762)
-- Name: users_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4933 (class 2606 OID 154764)
-- Name: users_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4935 (class 2606 OID 154766)
-- Name: usuario_pkey; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- TOC entry 4937 (class 2606 OID 154768)
-- Name: usuario_username_key; Type: CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 4367 (class 1259 OID 154799)
-- Name: cash_fund_arqueos_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_cash_fund_id_index ON cash_fund_arqueos USING btree (cash_fund_id);


--
-- TOC entry 4370 (class 1259 OID 154800)
-- Name: cash_fund_arqueos_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_arqueos_created_by_user_id_index ON cash_fund_arqueos USING btree (created_by_user_id);


--
-- TOC entry 4378 (class 1259 OID 154801)
-- Name: cash_fund_movements_cash_fund_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_cash_fund_id_index ON cash_fund_movements USING btree (cash_fund_id);


--
-- TOC entry 4379 (class 1259 OID 154802)
-- Name: cash_fund_movements_created_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_created_by_user_id_index ON cash_fund_movements USING btree (created_by_user_id);


--
-- TOC entry 4380 (class 1259 OID 154803)
-- Name: cash_fund_movements_estatus_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_estatus_index ON cash_fund_movements USING btree (estatus);


--
-- TOC entry 4383 (class 1259 OID 154804)
-- Name: cash_fund_movements_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_fund_movements_tipo_index ON cash_fund_movements USING btree (tipo);


--
-- TOC entry 4384 (class 1259 OID 154805)
-- Name: cash_funds_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_estado_index ON cash_funds USING btree (estado);


--
-- TOC entry 4385 (class 1259 OID 154806)
-- Name: cash_funds_fecha_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_fecha_index ON cash_funds USING btree (fecha);


--
-- TOC entry 4388 (class 1259 OID 154807)
-- Name: cash_funds_responsable_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_responsable_user_id_index ON cash_funds USING btree (responsable_user_id);


--
-- TOC entry 4389 (class 1259 OID 154808)
-- Name: cash_funds_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX cash_funds_sucursal_id_index ON cash_funds USING btree (sucursal_id);


--
-- TOC entry 4947 (class 1259 OID 168525)
-- Name: idx_alertas_cortes_destinatario; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_destinatario ON alertas_cortes USING btree (destinatario_id, leida);


--
-- TOC entry 4948 (class 1259 OID 168526)
-- Name: idx_alertas_cortes_postcorte; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_alertas_cortes_postcorte ON alertas_cortes USING btree (postcorte_id);


--
-- TOC entry 4333 (class 1259 OID 154809)
-- Name: idx_audit_log_accion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_accion ON audit_log USING btree (accion);


--
-- TOC entry 4334 (class 1259 OID 154810)
-- Name: idx_audit_log_entidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad ON audit_log USING btree (entidad);


--
-- TOC entry 4335 (class 1259 OID 154811)
-- Name: idx_audit_log_entidad_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_entidad_id ON audit_log USING btree (entidad_id);


--
-- TOC entry 4343 (class 1259 OID 154812)
-- Name: idx_audit_log_global_changed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_changed_at ON audit_log_global USING btree (changed_at);


--
-- TOC entry 4344 (class 1259 OID 154813)
-- Name: idx_audit_log_global_operation; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_operation ON audit_log_global USING btree (operation);


--
-- TOC entry 4345 (class 1259 OID 154814)
-- Name: idx_audit_log_global_table; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_table ON audit_log_global USING btree (table_name);


--
-- TOC entry 4346 (class 1259 OID 154815)
-- Name: idx_audit_log_global_user; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_global_user ON audit_log_global USING btree (changed_by_user_id);


--
-- TOC entry 4336 (class 1259 OID 154816)
-- Name: idx_audit_log_timestamp; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_timestamp ON audit_log USING btree ("timestamp");


--
-- TOC entry 4337 (class 1259 OID 154817)
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON audit_log USING btree (user_id);


--
-- TOC entry 4404 (class 1259 OID 154818)
-- Name: idx_cat_sucursales_pos_location; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_sucursales_pos_location ON cat_sucursales USING btree (pos_location);


--
-- TOC entry 4409 (class 1259 OID 154819)
-- Name: idx_cat_unidades_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_activo ON cat_unidades USING btree (activo);


--
-- TOC entry 4410 (class 1259 OID 154820)
-- Name: idx_cat_unidades_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_categoria ON cat_unidades USING btree (categoria);


--
-- TOC entry 4411 (class 1259 OID 154821)
-- Name: idx_cat_unidades_clave; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_unidades_clave ON cat_unidades USING btree (clave);


--
-- TOC entry 4418 (class 1259 OID 154822)
-- Name: idx_cat_uom_conversion_destino; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_destino ON cat_uom_conversion USING btree (destino_id);


--
-- TOC entry 4419 (class 1259 OID 154823)
-- Name: idx_cat_uom_conversion_origen; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_origen ON cat_uom_conversion USING btree (origen_id);


--
-- TOC entry 4420 (class 1259 OID 154824)
-- Name: idx_cat_uom_conversion_scope; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_cat_uom_conversion_scope ON cat_uom_conversion USING btree (scope);


--
-- TOC entry 4452 (class 1259 OID 154825)
-- Name: idx_historial_costos_item_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_historial_costos_item_fecha ON historial_costos_item USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4489 (class 1259 OID 154826)
-- Name: idx_inventory_batch_caducidad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_caducidad ON inventory_batch USING btree (fecha_caducidad);


--
-- TOC entry 4490 (class 1259 OID 154827)
-- Name: idx_inventory_batch_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item ON inventory_batch USING btree (item_id);


--
-- TOC entry 4491 (class 1259 OID 154828)
-- Name: idx_inventory_batch_item_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_inventory_batch_item_estado ON inventory_batch USING btree (item_id, estado);


--
-- TOC entry 4509 (class 1259 OID 154829)
-- Name: idx_invshot_branch_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_branch_date ON inventory_snapshot USING btree (branch_id, snapshot_date);


--
-- TOC entry 4510 (class 1259 OID 154830)
-- Name: idx_invshot_item_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_item_date ON inventory_snapshot USING btree (item_id, snapshot_date);


--
-- TOC entry 4511 (class 1259 OID 154831)
-- Name: idx_invshot_variance; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_invshot_variance ON inventory_snapshot USING btree (snapshot_date, branch_id, variance_qty);


--
-- TOC entry 4538 (class 1259 OID 154832)
-- Name: idx_items_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo ON items USING btree (activo) WHERE (activo = true);


--
-- TOC entry 4539 (class 1259 OID 154833)
-- Name: idx_items_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_activo_categoria ON items USING btree (activo, categoria_id) WHERE (activo = true);


--
-- TOC entry 4540 (class 1259 OID 154834)
-- Name: idx_items_categoria_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_categoria_id ON items USING btree (categoria_id);


--
-- TOC entry 4541 (class 1259 OID 154835)
-- Name: idx_items_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_nombre_lower ON items USING btree (lower((nombre)::text));


--
-- TOC entry 4542 (class 1259 OID 154836)
-- Name: idx_items_unidad_compra_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_compra_id ON items USING btree (unidad_compra_id) WHERE ((activo = true) AND (unidad_compra_id IS NOT NULL));


--
-- TOC entry 4543 (class 1259 OID 154837)
-- Name: idx_items_unidad_medida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_medida_id ON items USING btree (unidad_medida_id) WHERE (activo = true);


--
-- TOC entry 4544 (class 1259 OID 154838)
-- Name: idx_items_unidad_salida_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_items_unidad_salida_id ON items USING btree (unidad_salida_id) WHERE ((activo = true) AND (unidad_salida_id IS NOT NULL));


--
-- TOC entry 4576 (class 1259 OID 154839)
-- Name: idx_merma_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_batch_id ON merma USING btree (batch_id);


--
-- TOC entry 4577 (class 1259 OID 154840)
-- Name: idx_merma_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_deleted_at ON merma USING btree (deleted_at);


--
-- TOC entry 4578 (class 1259 OID 154841)
-- Name: idx_merma_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_item_id ON merma USING btree (item_id);


--
-- TOC entry 4579 (class 1259 OID 154842)
-- Name: idx_merma_usuario_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_merma_usuario_id ON merma USING btree (usuario_id);


--
-- TOC entry 4594 (class 1259 OID 154843)
-- Name: idx_mov_inv_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4595 (class 1259 OID 154844)
-- Name: idx_mov_inv_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_item_ts ON mov_inv USING btree (item_id, ts);


--
-- TOC entry 4596 (class 1259 OID 154845)
-- Name: idx_mov_inv_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4597 (class 1259 OID 154846)
-- Name: idx_mov_inv_tipo_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_tipo_fecha ON mov_inv USING btree (tipo, ts);


--
-- TOC entry 4598 (class 1259 OID 154847)
-- Name: idx_mov_inv_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4599 (class 1259 OID 154848)
-- Name: idx_mov_inv_ts_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_mov_inv_ts_tipo ON mov_inv USING btree (ts, tipo);


--
-- TOC entry 4633 (class 1259 OID 154850)
-- Name: idx_op_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_cab_deleted_at ON op_cab USING btree (deleted_at);


--
-- TOC entry 4636 (class 1259 OID 154851)
-- Name: idx_op_insumo_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_batch_id ON op_insumo USING btree (batch_id);


--
-- TOC entry 4637 (class 1259 OID 154852)
-- Name: idx_op_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_op_insumo_item_id ON op_insumo USING btree (item_id);


--
-- TOC entry 4656 (class 1259 OID 154853)
-- Name: idx_perdida_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_perdida_item_ts ON perdida_log USING btree (item_id, ts DESC);


--
-- TOC entry 4668 (class 1259 OID 154854)
-- Name: idx_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);


--
-- TOC entry 4678 (class 1259 OID 154855)
-- Name: idx_pos_reprocess_log_reprocessed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_reprocessed_at ON pos_reprocess_log USING btree (reprocessed_at);


--
-- TOC entry 4679 (class 1259 OID 154856)
-- Name: idx_pos_reprocess_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_ticket_id ON pos_reprocess_log USING btree (ticket_id);


--
-- TOC entry 4680 (class 1259 OID 154857)
-- Name: idx_pos_reprocess_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reprocess_log_user_id ON pos_reprocess_log USING btree (user_id);


--
-- TOC entry 4683 (class 1259 OID 154858)
-- Name: idx_pos_reverse_log_reversed_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_reversed_at ON pos_reverse_log USING btree (reversed_at);


--
-- TOC entry 4684 (class 1259 OID 154859)
-- Name: idx_pos_reverse_log_ticket_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_ticket_id ON pos_reverse_log USING btree (ticket_id);


--
-- TOC entry 4685 (class 1259 OID 154860)
-- Name: idx_pos_reverse_log_user_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_pos_reverse_log_user_id ON pos_reverse_log USING btree (user_id);


--
-- TOC entry 4673 (class 1259 OID 154861)
-- Name: idx_posmod_active_valid; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_posmod_active_valid ON pos_modifiers_map USING btree (active, valid_from, (COALESCE(valid_to, '2999-12-31'::date)));


--
-- TOC entry 4694 (class 1259 OID 168552)
-- Name: idx_postcorte_requiere_aprobacion; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_requiere_aprobacion ON postcorte USING btree (requiere_aprobacion) WHERE (requiere_aprobacion = true);


--
-- TOC entry 4695 (class 1259 OID 154862)
-- Name: idx_postcorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_postcorte_sesion_id ON postcorte USING btree (sesion_id);


--
-- TOC entry 4706 (class 1259 OID 154863)
-- Name: idx_precorte_efectivo_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_efectivo_precorte_id ON precorte_efectivo USING btree (precorte_id);


--
-- TOC entry 4709 (class 1259 OID 154864)
-- Name: idx_precorte_otros_precorte_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_otros_precorte_id ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4700 (class 1259 OID 154865)
-- Name: idx_precorte_sesion_id; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_precorte_sesion_id ON precorte USING btree (sesion_id);


--
-- TOC entry 4759 (class 1259 OID 154866)
-- Name: idx_preq_fecha_requerida; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_fecha_requerida ON purchase_requests USING btree (fecha_requerida);


--
-- TOC entry 4760 (class 1259 OID 154867)
-- Name: idx_preq_urgente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_preq_urgente ON purchase_requests USING btree (urgente);


--
-- TOC entry 4398 (class 1259 OID 154868)
-- Name: idx_prov_razon_social; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_razon_social ON cat_proveedores USING btree (razon_social);


--
-- TOC entry 4399 (class 1259 OID 154869)
-- Name: idx_prov_rfc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_prov_rfc ON cat_proveedores USING btree (rfc);


--
-- TOC entry 4774 (class 1259 OID 154870)
-- Name: idx_psugg_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_estado ON purchase_suggestions USING btree (estado);


--
-- TOC entry 4775 (class 1259 OID 154871)
-- Name: idx_psugg_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_fecha ON purchase_suggestions USING btree (sugerido_en);


--
-- TOC entry 4776 (class 1259 OID 154872)
-- Name: idx_psugg_prioridad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_prioridad ON purchase_suggestions USING btree (prioridad);


--
-- TOC entry 4777 (class 1259 OID 154873)
-- Name: idx_psugg_sucursal_estado; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psugg_sucursal_estado ON purchase_suggestions USING btree (sucursal_id, estado);


--
-- TOC entry 4768 (class 1259 OID 154874)
-- Name: idx_psuggline_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_item ON purchase_suggestion_lines USING btree (item_id);


--
-- TOC entry 4769 (class 1259 OID 154875)
-- Name: idx_psuggline_suggestion; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_psuggline_suggestion ON purchase_suggestion_lines USING btree (suggestion_id);


--
-- TOC entry 4796 (class 1259 OID 154876)
-- Name: idx_recepcion_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_cab_deleted_at ON recepcion_cab USING btree (deleted_at);


--
-- TOC entry 4800 (class 1259 OID 154877)
-- Name: idx_recepcion_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_batch_id ON recepcion_det USING btree (batch_id);


--
-- TOC entry 4801 (class 1259 OID 154878)
-- Name: idx_recepcion_det_bodega_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_bodega_id ON recepcion_det USING btree (bodega_id);


--
-- TOC entry 4802 (class 1259 OID 154879)
-- Name: idx_recepcion_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recepcion_det_item_id ON recepcion_det USING btree (item_id);


--
-- TOC entry 4616 (class 1259 OID 154880)
-- Name: idx_receta_cab_activo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo ON receta_cab USING btree (activo) WHERE (activo = true);


--
-- TOC entry 4617 (class 1259 OID 154881)
-- Name: idx_receta_cab_activo_categoria; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_activo_categoria ON receta_cab USING btree (activo, categoria_plato) WHERE (activo = true);


--
-- TOC entry 4618 (class 1259 OID 154882)
-- Name: idx_receta_cab_categoria_plato; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_categoria_plato ON receta_cab USING btree (categoria_plato);


--
-- TOC entry 4619 (class 1259 OID 154883)
-- Name: idx_receta_cab_nombre_lower; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_cab_nombre_lower ON receta_cab USING btree (lower((nombre_plato)::text));


--
-- TOC entry 4809 (class 1259 OID 154884)
-- Name: idx_receta_insumo_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_item_id ON receta_insumo USING btree (item_id);


--
-- TOC entry 4810 (class 1259 OID 154885)
-- Name: idx_receta_insumo_receta_version_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_insumo_receta_version_id ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4626 (class 1259 OID 154886)
-- Name: idx_receta_version_publicada; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_receta_version_publicada ON receta_version USING btree (version_publicada);


--
-- TOC entry 4822 (class 1259 OID 154887)
-- Name: idx_recipe_cost_snap_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_date ON recipe_cost_snapshots USING btree (snapshot_date DESC);


--
-- TOC entry 4823 (class 1259 OID 154888)
-- Name: idx_recipe_cost_snap_recipe_date; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_recipe_cost_snap_recipe_date ON recipe_cost_snapshots USING btree (recipe_id, snapshot_date DESC);


--
-- TOC entry 4857 (class 1259 OID 154889)
-- Name: idx_report_key; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_key ON report_favorites USING btree (report_key);


--
-- TOC entry 4942 (class 1259 OID 156935)
-- Name: idx_report_runs_report_status; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_report_runs_report_status ON report_runs USING btree (report_id, status);


--
-- TOC entry 4608 (class 1259 OID 154890)
-- Name: idx_sesion_cajon_terminal_apertura; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX idx_sesion_cajon_terminal_apertura ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4879 (class 1259 OID 154891)
-- Name: idx_stock_policy_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_stock_policy_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4880 (class 1259 OID 154892)
-- Name: idx_stock_policy_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_stock_policy_unique ON stock_policy USING btree (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text)));


--
-- TOC entry 4886 (class 1259 OID 154893)
-- Name: idx_suc_alm_term_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_suc_alm_term_unique ON sucursal_almacen_terminal USING btree (sucursal_id, almacen_id, (COALESCE(terminal_id, 0)));


--
-- TOC entry 4889 (class 1259 OID 154894)
-- Name: idx_tick_cons_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX idx_tick_cons_unique ON ticket_det_consumo USING btree (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0)));


--
-- TOC entry 4890 (class 1259 OID 154895)
-- Name: idx_tickcons_lote; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_lote ON ticket_det_consumo USING btree (item_id, lote_id);


--
-- TOC entry 4891 (class 1259 OID 154896)
-- Name: idx_tickcons_ticket; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_tickcons_ticket ON ticket_det_consumo USING btree (ticket_id, ticket_det_id);


--
-- TOC entry 4898 (class 1259 OID 154897)
-- Name: idx_ticket_venta_fecha; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_ticket_venta_fecha ON ticket_venta_cab USING btree (fecha_venta);


--
-- TOC entry 4909 (class 1259 OID 154898)
-- Name: idx_traspaso_cab_deleted_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_cab_deleted_at ON traspaso_cab USING btree (deleted_at);


--
-- TOC entry 4912 (class 1259 OID 154899)
-- Name: idx_traspaso_det_batch_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_batch_id ON traspaso_det USING btree (batch_id);


--
-- TOC entry 4913 (class 1259 OID 154900)
-- Name: idx_traspaso_det_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX idx_traspaso_det_item_id ON traspaso_det USING btree (item_id);


--
-- TOC entry 4455 (class 1259 OID 156390)
-- Name: insumo_cat_sub_cons_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX insumo_cat_sub_cons_idx ON insumo USING btree (categoria_codigo, subcategoria_codigo, consecutivo);


--
-- TOC entry 4479 (class 1259 OID 154902)
-- Name: inv_consumo_pos_det_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_procesado_idx ON inv_consumo_pos_det USING btree (procesado);


--
-- TOC entry 4480 (class 1259 OID 154903)
-- Name: inv_consumo_pos_det_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_requiere_reproceso_idx ON inv_consumo_pos_det USING btree (requiere_reproceso);


--
-- TOC entry 4481 (class 1259 OID 156387)
-- Name: inv_consumo_pos_det_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_det_revertido_idx ON inv_consumo_pos_det USING btree (revertido);


--
-- TOC entry 4484 (class 1259 OID 154904)
-- Name: inv_consumo_pos_log_ticket_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_log_ticket_id_index ON inv_consumo_pos_log USING btree (ticket_id);


--
-- TOC entry 4472 (class 1259 OID 154905)
-- Name: inv_consumo_pos_procesado_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_procesado_idx ON inv_consumo_pos USING btree (procesado);


--
-- TOC entry 4473 (class 1259 OID 154906)
-- Name: inv_consumo_pos_requiere_reproceso_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_requiere_reproceso_idx ON inv_consumo_pos USING btree (requiere_reproceso);


--
-- TOC entry 4474 (class 1259 OID 156379)
-- Name: inv_consumo_pos_revertido_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inv_consumo_pos_revertido_idx ON inv_consumo_pos USING btree (revertido);


--
-- TOC entry 4495 (class 1259 OID 154907)
-- Name: inventory_count_lines_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_batch_id_index ON inventory_count_lines USING btree (inventory_batch_id);


--
-- TOC entry 4496 (class 1259 OID 154908)
-- Name: inventory_count_lines_inventory_count_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_inventory_count_id_index ON inventory_count_lines USING btree (inventory_count_id);


--
-- TOC entry 4497 (class 1259 OID 156391)
-- Name: inventory_count_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_count_lines_item_id_index ON inventory_count_lines USING btree (item_id);


--
-- TOC entry 4500 (class 1259 OID 154910)
-- Name: inventory_counts_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_almacen_id_index ON inventory_counts USING btree (almacen_id);


--
-- TOC entry 4501 (class 1259 OID 154911)
-- Name: inventory_counts_cerrado_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_cerrado_en_index ON inventory_counts USING btree (cerrado_en);


--
-- TOC entry 4502 (class 1259 OID 154912)
-- Name: inventory_counts_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_estado_index ON inventory_counts USING btree (estado);


--
-- TOC entry 4507 (class 1259 OID 154913)
-- Name: inventory_counts_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_programado_para_index ON inventory_counts USING btree (programado_para);


--
-- TOC entry 4508 (class 1259 OID 154914)
-- Name: inventory_counts_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_counts_sucursal_id_index ON inventory_counts USING btree (sucursal_id);


--
-- TOC entry 4514 (class 1259 OID 154915)
-- Name: inventory_wastes_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_inventory_batch_id_index ON inventory_wastes USING btree (inventory_batch_id);


--
-- TOC entry 4515 (class 1259 OID 154916)
-- Name: inventory_wastes_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_item_id_index ON inventory_wastes USING btree (item_id);


--
-- TOC entry 4518 (class 1259 OID 154917)
-- Name: inventory_wastes_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_production_order_id_index ON inventory_wastes USING btree (production_order_id);


--
-- TOC entry 4519 (class 1259 OID 154918)
-- Name: inventory_wastes_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX inventory_wastes_sucursal_id_index ON inventory_wastes USING btree (sucursal_id);


--
-- TOC entry 4466 (class 1259 OID 154919)
-- Name: ipp_activo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_activo_idx ON insumo_proveedor_presentacion USING btree (activo);


--
-- TOC entry 4467 (class 1259 OID 154920)
-- Name: ipp_insumo_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_insumo_idx ON insumo_proveedor_presentacion USING btree (item_id);


--
-- TOC entry 4468 (class 1259 OID 154921)
-- Name: ipp_proveedor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ipp_proveedor_idx ON insumo_proveedor_presentacion USING btree (proveedor_id);


--
-- TOC entry 4469 (class 1259 OID 154922)
-- Name: ipp_uni; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ipp_uni ON insumo_proveedor_presentacion USING btree (item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra);


--
-- TOC entry 4326 (class 1259 OID 154923)
-- Name: ix_alert_events_recipe; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_alert_events_recipe ON alert_events USING btree (recipe_id, created_at);


--
-- TOC entry 4439 (class 1259 OID 154924)
-- Name: ix_fp_codigo; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_fp_codigo ON formas_pago USING btree (codigo);


--
-- TOC entry 4443 (class 1259 OID 154925)
-- Name: ix_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva DESC);


--
-- TOC entry 4447 (class 1259 OID 154926)
-- Name: ix_hist_cost_receta; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_hist_cost_receta ON hist_cost_receta USING btree (receta_version_id, fecha_calculo);


--
-- TOC entry 4494 (class 1259 OID 154927)
-- Name: ix_ib_item_caduc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ib_item_caduc ON inventory_batch USING btree (item_id, fecha_caducidad);


--
-- TOC entry 4530 (class 1259 OID 154928)
-- Name: ix_itemvendor_preferente; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_preferente ON item_vendor USING btree (preferente);


--
-- TOC entry 4531 (class 1259 OID 154929)
-- Name: ix_itemvendor_vendor_sku; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_itemvendor_vendor_sku ON item_vendor USING btree (vendor_id, vendor_sku);


--
-- TOC entry 4535 (class 1259 OID 154930)
-- Name: ix_ivp_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_item ON item_vendor_prices USING btree (item_id);


--
-- TOC entry 4536 (class 1259 OID 154931)
-- Name: ix_ivp_validity; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_validity ON item_vendor_prices USING btree (item_id, effective_from, effective_to);


--
-- TOC entry 4537 (class 1259 OID 154932)
-- Name: ix_ivp_vendor; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ivp_vendor ON item_vendor_prices USING btree (vendor_id);


--
-- TOC entry 4431 (class 1259 OID 154933)
-- Name: ix_layer_item; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item ON cost_layer USING btree (item_id, ts_in);


--
-- TOC entry 4432 (class 1259 OID 154934)
-- Name: ix_layer_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_layer_item_suc ON cost_layer USING btree (item_id, sucursal_id);


--
-- TOC entry 4560 (class 1259 OID 154935)
-- Name: ix_lote_cad; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_cad ON lote USING btree (caducidad);


--
-- TOC entry 4561 (class 1259 OID 154936)
-- Name: ix_lote_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_lote_insumo ON lote USING btree (item_id);


--
-- TOC entry 4600 (class 1259 OID 154937)
-- Name: ix_mov_item_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_id ON mov_inv USING btree (item_id);


--
-- TOC entry 4601 (class 1259 OID 154938)
-- Name: ix_mov_item_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_item_ts ON mov_inv USING btree (item_id, ts DESC);


--
-- TOC entry 4602 (class 1259 OID 154939)
-- Name: ix_mov_ref; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ref ON mov_inv USING btree (ref_tipo, ref_id);


--
-- TOC entry 4603 (class 1259 OID 154940)
-- Name: ix_mov_sucursal; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_sucursal ON mov_inv USING btree (sucursal_id);


--
-- TOC entry 4604 (class 1259 OID 154941)
-- Name: ix_mov_tipo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_tipo ON mov_inv USING btree (tipo);


--
-- TOC entry 4605 (class 1259 OID 154942)
-- Name: ix_mov_ts; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_mov_ts ON mov_inv USING btree (ts);


--
-- TOC entry 4669 (class 1259 OID 154943)
-- Name: ix_pm_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pm_plu ON pos_map USING btree (plu);


--
-- TOC entry 4670 (class 1259 OID 154944)
-- Name: ix_pos_map_plu; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);


--
-- TOC entry 4710 (class 1259 OID 154945)
-- Name: ix_precorte_otros_precorte; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_precorte_otros_precorte ON precorte_otros USING btree (precorte_id);


--
-- TOC entry 4819 (class 1259 OID 154946)
-- Name: ix_rch_recipe_at; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rch_recipe_at ON recipe_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4811 (class 1259 OID 154947)
-- Name: ix_ri_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_insumo ON receta_insumo USING btree (item_id);


--
-- TOC entry 4812 (class 1259 OID 154948)
-- Name: ix_ri_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_ri_rv ON receta_insumo USING btree (receta_version_id);


--
-- TOC entry 4627 (class 1259 OID 154949)
-- Name: ix_rv_id; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rv_id ON receta_version USING btree (id);


--
-- TOC entry 4838 (class 1259 OID 154950)
-- Name: ix_rvi_rv; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_rvi_rv ON recipe_version_items USING btree (recipe_version_id);


--
-- TOC entry 4609 (class 1259 OID 154951)
-- Name: ix_sesion_cajon_cajero; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts);


--
-- TOC entry 4610 (class 1259 OID 154952)
-- Name: ix_sesion_cajon_terminal; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts);


--
-- TOC entry 4881 (class 1259 OID 154953)
-- Name: ix_sp_item_suc; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ix_sp_item_suc ON stock_policy USING btree (item_id, sucursal_id);


--
-- TOC entry 4554 (class 1259 OID 154954)
-- Name: jobs_queue_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX jobs_queue_index ON jobs USING btree (queue);


--
-- TOC entry 4555 (class 1259 OID 154955)
-- Name: labor_roles_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX labor_roles_activo_index ON labor_roles USING btree (activo);


--
-- TOC entry 4584 (class 1259 OID 154956)
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON model_has_permissions USING btree (model_id, model_type);


--
-- TOC entry 4587 (class 1259 OID 154957)
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON model_has_roles USING btree (model_id, model_type);


--
-- TOC entry 4615 (class 1259 OID 154958)
-- Name: mv_inventario_actual_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_inventario_actual_item_id_idx ON mv_inventario_actual USING btree (item_id);


--
-- TOC entry 4632 (class 1259 OID 154959)
-- Name: mv_recetas_costos_receta_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX mv_recetas_costos_receta_id_idx ON mv_recetas_costos USING btree (receta_id);


--
-- TOC entry 4644 (class 1259 OID 154960)
-- Name: overhead_definitions_activo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_activo_index ON overhead_definitions USING btree (activo);


--
-- TOC entry 4649 (class 1259 OID 154961)
-- Name: overhead_definitions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX overhead_definitions_tipo_index ON overhead_definitions USING btree (tipo);


--
-- TOC entry 4667 (class 1259 OID 154962)
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- TOC entry 4703 (class 1259 OID 154963)
-- Name: precorte_sesion_id_idx; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE INDEX precorte_sesion_id_idx ON precorte USING btree (sesion_id);


--
-- TOC entry 4717 (class 1259 OID 154964)
-- Name: production_order_inputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_inventory_batch_id_index ON production_order_inputs USING btree (inventory_batch_id);


--
-- TOC entry 4718 (class 1259 OID 154965)
-- Name: production_order_inputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_item_id_index ON production_order_inputs USING btree (item_id);


--
-- TOC entry 4721 (class 1259 OID 154966)
-- Name: production_order_inputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_inputs_production_order_id_index ON production_order_inputs USING btree (production_order_id);


--
-- TOC entry 4722 (class 1259 OID 154967)
-- Name: production_order_outputs_inventory_batch_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_inventory_batch_id_index ON production_order_outputs USING btree (inventory_batch_id);


--
-- TOC entry 4723 (class 1259 OID 154968)
-- Name: production_order_outputs_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_item_id_index ON production_order_outputs USING btree (item_id);


--
-- TOC entry 4726 (class 1259 OID 154969)
-- Name: production_order_outputs_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_order_outputs_production_order_id_index ON production_order_outputs USING btree (production_order_id);


--
-- TOC entry 4727 (class 1259 OID 154970)
-- Name: production_orders_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_almacen_id_index ON production_orders USING btree (almacen_id);


--
-- TOC entry 4728 (class 1259 OID 154971)
-- Name: production_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_estado_index ON production_orders USING btree (estado);


--
-- TOC entry 4731 (class 1259 OID 154972)
-- Name: production_orders_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_item_id_index ON production_orders USING btree (item_id);


--
-- TOC entry 4734 (class 1259 OID 154973)
-- Name: production_orders_programado_para_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_programado_para_index ON production_orders USING btree (programado_para);


--
-- TOC entry 4735 (class 1259 OID 154974)
-- Name: production_orders_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_recipe_id_index ON production_orders USING btree (recipe_id);


--
-- TOC entry 4736 (class 1259 OID 154975)
-- Name: production_orders_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX production_orders_sucursal_id_index ON production_orders USING btree (sucursal_id);


--
-- TOC entry 4739 (class 1259 OID 154976)
-- Name: purchase_documents_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_order_id_index ON purchase_documents USING btree (order_id);


--
-- TOC entry 4742 (class 1259 OID 154977)
-- Name: purchase_documents_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_quote_id_index ON purchase_documents USING btree (quote_id);


--
-- TOC entry 4743 (class 1259 OID 154978)
-- Name: purchase_documents_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_documents_request_id_index ON purchase_documents USING btree (request_id);


--
-- TOC entry 4744 (class 1259 OID 154979)
-- Name: purchase_order_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_item_id_index ON purchase_order_lines USING btree (item_id);


--
-- TOC entry 4745 (class 1259 OID 154980)
-- Name: purchase_order_lines_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_order_lines_order_id_index ON purchase_order_lines USING btree (order_id);


--
-- TOC entry 4748 (class 1259 OID 154981)
-- Name: purchase_orders_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_estado_index ON purchase_orders USING btree (estado);


--
-- TOC entry 4753 (class 1259 OID 154982)
-- Name: purchase_orders_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_orders_vendor_id_index ON purchase_orders USING btree (vendor_id);


--
-- TOC entry 4754 (class 1259 OID 154983)
-- Name: purchase_request_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_item_id_index ON purchase_request_lines USING btree (item_id);


--
-- TOC entry 4757 (class 1259 OID 154984)
-- Name: purchase_request_lines_preferred_vendor_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_preferred_vendor_id_index ON purchase_request_lines USING btree (preferred_vendor_id);


--
-- TOC entry 4758 (class 1259 OID 154985)
-- Name: purchase_request_lines_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_request_lines_request_id_index ON purchase_request_lines USING btree (request_id);


--
-- TOC entry 4761 (class 1259 OID 154986)
-- Name: purchase_requests_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_estado_index ON purchase_requests USING btree (estado);


--
-- TOC entry 4766 (class 1259 OID 154987)
-- Name: purchase_requests_requested_at_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_requested_at_index ON purchase_requests USING btree (requested_at);


--
-- TOC entry 4767 (class 1259 OID 154988)
-- Name: purchase_requests_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_requests_sucursal_id_index ON purchase_requests USING btree (sucursal_id);


--
-- TOC entry 4782 (class 1259 OID 154989)
-- Name: purchase_vendor_quote_lines_item_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_item_id_index ON purchase_vendor_quote_lines USING btree (item_id);


--
-- TOC entry 4785 (class 1259 OID 154990)
-- Name: purchase_vendor_quote_lines_quote_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_quote_id_index ON purchase_vendor_quote_lines USING btree (quote_id);


--
-- TOC entry 4786 (class 1259 OID 154991)
-- Name: purchase_vendor_quote_lines_request_line_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quote_lines_request_line_id_index ON purchase_vendor_quote_lines USING btree (request_line_id);


--
-- TOC entry 4787 (class 1259 OID 154992)
-- Name: purchase_vendor_quotes_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_estado_index ON purchase_vendor_quotes USING btree (estado);


--
-- TOC entry 4790 (class 1259 OID 154993)
-- Name: purchase_vendor_quotes_request_vendor_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX purchase_vendor_quotes_request_vendor_idx ON purchase_vendor_quotes USING btree (request_id, vendor_id);


--
-- TOC entry 4795 (class 1259 OID 154994)
-- Name: recepcion_adjuntos_recepcion_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recepcion_adjuntos_recepcion_id_index ON recepcion_adjuntos USING btree (recepcion_id);


--
-- TOC entry 4826 (class 1259 OID 154995)
-- Name: recipe_extended_cost_hist_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_extended_cost_hist_idx ON recipe_extended_cost_history USING btree (recipe_id, snapshot_at);


--
-- TOC entry 4829 (class 1259 OID 154996)
-- Name: recipe_labor_steps_labor_role_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_labor_role_id_index ON recipe_labor_steps USING btree (labor_role_id);


--
-- TOC entry 4832 (class 1259 OID 154997)
-- Name: recipe_labor_steps_recipe_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_labor_steps_recipe_id_index ON recipe_labor_steps USING btree (recipe_id);


--
-- TOC entry 4833 (class 1259 OID 154998)
-- Name: recipe_overhead_allocations_overhead_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX recipe_overhead_allocations_overhead_id_index ON recipe_overhead_allocations USING btree (overhead_id);


--
-- TOC entry 4844 (class 1259 OID 154999)
-- Name: replenishment_suggestions_estado_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_estado_index ON replenishment_suggestions USING btree (estado);


--
-- TOC entry 4845 (class 1259 OID 155000)
-- Name: replenishment_suggestions_fecha_agotamiento_estimada_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_fecha_agotamiento_estimada_index ON replenishment_suggestions USING btree (fecha_agotamiento_estimada);


--
-- TOC entry 4848 (class 1259 OID 155001)
-- Name: replenishment_suggestions_item_id_sucursal_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_item_id_sucursal_id_index ON replenishment_suggestions USING btree (item_id, sucursal_id);


--
-- TOC entry 4851 (class 1259 OID 155002)
-- Name: replenishment_suggestions_prioridad_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_prioridad_index ON replenishment_suggestions USING btree (prioridad);


--
-- TOC entry 4852 (class 1259 OID 155003)
-- Name: replenishment_suggestions_production_order_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_production_order_id_index ON replenishment_suggestions USING btree (production_order_id);


--
-- TOC entry 4853 (class 1259 OID 155004)
-- Name: replenishment_suggestions_purchase_request_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_purchase_request_id_index ON replenishment_suggestions USING btree (purchase_request_id);


--
-- TOC entry 4854 (class 1259 OID 155005)
-- Name: replenishment_suggestions_revisado_por_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_revisado_por_index ON replenishment_suggestions USING btree (revisado_por);


--
-- TOC entry 4855 (class 1259 OID 155006)
-- Name: replenishment_suggestions_sugerido_en_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_sugerido_en_index ON replenishment_suggestions USING btree (sugerido_en);


--
-- TOC entry 4856 (class 1259 OID 155007)
-- Name: replenishment_suggestions_tipo_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX replenishment_suggestions_tipo_index ON replenishment_suggestions USING btree (tipo);


--
-- TOC entry 4860 (class 1259 OID 155008)
-- Name: report_favorites_user_id_report_key_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX report_favorites_user_id_report_key_unique ON report_favorites USING btree (user_id, report_key);


--
-- TOC entry 4338 (class 1259 OID 155009)
-- Name: selemti_audit_log_entidad_entidad_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_entidad_entidad_id_index ON audit_log USING btree (entidad, entidad_id);


--
-- TOC entry 4339 (class 1259 OID 155010)
-- Name: selemti_audit_log_timestamp_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_timestamp_index ON audit_log USING btree ("timestamp");


--
-- TOC entry 4340 (class 1259 OID 155011)
-- Name: selemti_audit_log_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_audit_log_user_id_index ON audit_log USING btree (user_id);


--
-- TOC entry 4375 (class 1259 OID 155012)
-- Name: selemti_cash_fund_movement_audit_log_action_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_action_index ON cash_fund_movement_audit_log USING btree (action);


--
-- TOC entry 4376 (class 1259 OID 155013)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_changed_by_user_id_index ON cash_fund_movement_audit_log USING btree (changed_by_user_id);


--
-- TOC entry 4377 (class 1259 OID 155014)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_cash_fund_movement_audit_log_movement_id_index ON cash_fund_movement_audit_log USING btree (movement_id);


--
-- TOC entry 4692 (class 1259 OID 155015)
-- Name: selemti_pos_sync_logs_batch_id_status_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_batch_id_status_index ON pos_sync_logs USING btree (batch_id, status);


--
-- TOC entry 4693 (class 1259 OID 155016)
-- Name: selemti_pos_sync_logs_external_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_pos_sync_logs_external_id_index ON pos_sync_logs USING btree (external_id);


--
-- TOC entry 4799 (class 1259 OID 155017)
-- Name: selemti_recepcion_cab_almacen_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX selemti_recepcion_cab_almacen_id_index ON recepcion_cab USING btree (almacen_id);


--
-- TOC entry 4871 (class 1259 OID 155019)
-- Name: sessions_last_activity_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON sessions USING btree (last_activity);


--
-- TOC entry 4874 (class 1259 OID 155020)
-- Name: sessions_user_id_index; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON sessions USING btree (user_id);


--
-- TOC entry 4896 (class 1259 OID 155021)
-- Name: ticket_item_modifiers_ticket_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_id_idx ON ticket_item_modifiers USING btree (ticket_id);


--
-- TOC entry 4897 (class 1259 OID 155022)
-- Name: ticket_item_modifiers_ticket_item_id_idx; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE INDEX ticket_item_modifiers_ticket_item_id_idx ON ticket_item_modifiers USING btree (ticket_item_id);


--
-- TOC entry 4440 (class 1259 OID 155023)
-- Name: uq_fp_huella_expr; Type: INDEX; Schema: selemti; Owner: floreant
--

CREATE UNIQUE INDEX uq_fp_huella_expr ON formas_pago USING btree (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text)));


--
-- TOC entry 4444 (class 1259 OID 155024)
-- Name: ux_hist_cost_insumo; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_hist_cost_insumo ON hist_cost_insumo USING btree (item_id, fecha_efectiva, (COALESCE(valid_to, '9999-12-31'::date)));


--
-- TOC entry 4532 (class 1259 OID 155025)
-- Name: ux_item_vendor_preferente_unique; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_item_vendor_preferente_unique ON item_vendor USING btree (item_id) WHERE (preferente = true);


--
-- TOC entry 4547 (class 1259 OID 155026)
-- Name: ux_items_item_code; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_items_item_code ON items USING btree (item_code);


--
-- TOC entry 4843 (class 1259 OID 155027)
-- Name: ux_recipe_version; Type: INDEX; Schema: selemti; Owner: postgres
--

CREATE UNIQUE INDEX ux_recipe_version ON recipe_versions USING btree (recipe_id, version_no);


--
-- TOC entry 5087 (class 2620 OID 155034)
-- Name: trg_invshot_biur; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_invshot_biur BEFORE INSERT OR UPDATE ON inventory_snapshot FOR EACH ROW EXECUTE PROCEDURE tg_invshot_autofill();


--
-- TOC entry 5085 (class 2620 OID 155035)
-- Name: trg_ipp_set_timestamp; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ipp_set_timestamp BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE set_timestamp_ipp();


--
-- TOC entry 5088 (class 2620 OID 155036)
-- Name: trg_item_categories_autocode; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_item_categories_autocode BEFORE INSERT ON item_categories FOR EACH ROW EXECUTE PROCEDURE fn_gen_cat_codigo();


--
-- TOC entry 5091 (class 2620 OID 155037)
-- Name: trg_items_assign_code; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_items_assign_code BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE fn_assign_item_code();


--
-- TOC entry 5089 (class 2620 OID 155038)
-- Name: trg_ivp_after_insert; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_after_insert AFTER INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_after_price_insert_alert();


--
-- TOC entry 5090 (class 2620 OID 155039)
-- Name: trg_ivp_close_prev; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER trg_ivp_close_prev BEFORE INSERT ON item_vendor_prices FOR EACH ROW EXECUTE PROCEDURE fn_ivp_upsert_close_prev();


--
-- TOC entry 5095 (class 2620 OID 155040)
-- Name: trg_postcorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_postcorte_after_insert AFTER INSERT ON postcorte FOR EACH ROW EXECUTE PROCEDURE fn_postcorte_after_insert();


--
-- TOC entry 5096 (class 2620 OID 155041)
-- Name: trg_precorte_after_insert; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_insert AFTER INSERT ON precorte FOR EACH ROW EXECUTE PROCEDURE fn_precorte_after_insert();


--
-- TOC entry 5097 (class 2620 OID 155042)
-- Name: trg_precorte_after_update_aprobado; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_after_update_aprobado AFTER UPDATE ON precorte FOR EACH ROW WHEN (((new.estatus = 'APROBADO'::text) AND (old.estatus IS DISTINCT FROM 'APROBADO'::text))) EXECUTE PROCEDURE fn_precorte_after_update_aprobado();


--
-- TOC entry 5098 (class 2620 OID 155043)
-- Name: trg_precorte_efectivo_bi; Type: TRIGGER; Schema: selemti; Owner: floreant
--

CREATE TRIGGER trg_precorte_efectivo_bi BEFORE INSERT OR UPDATE ON precorte_efectivo FOR EACH ROW EXECUTE PROCEDURE fn_precorte_efectivo_bi();


--
-- TOC entry 5083 (class 2620 OID 155044)
-- Name: update_hist_cost_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_hist_cost_insumo_updated_at BEFORE UPDATE ON hist_cost_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5084 (class 2620 OID 155045)
-- Name: update_insumo_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_presentacion_updated_at BEFORE UPDATE ON insumo_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5086 (class 2620 OID 155046)
-- Name: update_insumo_proveedor_presentacion_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_insumo_proveedor_presentacion_updated_at BEFORE UPDATE ON insumo_proveedor_presentacion FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5092 (class 2620 OID 155047)
-- Name: update_merma_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_merma_updated_at BEFORE UPDATE ON merma FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5093 (class 2620 OID 155048)
-- Name: update_op_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_cab_updated_at BEFORE UPDATE ON op_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5094 (class 2620 OID 155049)
-- Name: update_op_insumo_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_op_insumo_updated_at BEFORE UPDATE ON op_insumo FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5099 (class 2620 OID 155050)
-- Name: update_recepcion_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_cab_updated_at BEFORE UPDATE ON recepcion_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5100 (class 2620 OID 155051)
-- Name: update_recepcion_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_recepcion_det_updated_at BEFORE UPDATE ON recepcion_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5101 (class 2620 OID 155052)
-- Name: update_traspaso_cab_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_cab_updated_at BEFORE UPDATE ON traspaso_cab FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5102 (class 2620 OID 155053)
-- Name: update_traspaso_det_updated_at; Type: TRIGGER; Schema: selemti; Owner: postgres
--

CREATE TRIGGER update_traspaso_det_updated_at BEFORE UPDATE ON traspaso_det FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- TOC entry 5082 (class 2606 OID 168520)
-- Name: alertas_cortes_destinatario_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_destinatario_id_fkey FOREIGN KEY (destinatario_id) REFERENCES users(id);


--
-- TOC entry 5080 (class 2606 OID 168510)
-- Name: alertas_cortes_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 5081 (class 2606 OID 168515)
-- Name: alertas_cortes_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY alertas_cortes
    ADD CONSTRAINT alertas_cortes_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 4949 (class 2606 OID 155684)
-- Name: almacen_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY almacen
    ADD CONSTRAINT almacen_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 4951 (class 2606 OID 155689)
-- Name: audit_log_global_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log_global
    ADD CONSTRAINT audit_log_global_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES users(id);


--
-- TOC entry 4952 (class 2606 OID 155694)
-- Name: bodega_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY bodega
    ADD CONSTRAINT bodega_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 4953 (class 2606 OID 155699)
-- Name: caja_fondo_adj_mov_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_adj
    ADD CONSTRAINT caja_fondo_adj_mov_id_fkey FOREIGN KEY (mov_id) REFERENCES caja_fondo_mov(id) ON DELETE CASCADE;


--
-- TOC entry 4954 (class 2606 OID 155704)
-- Name: caja_fondo_arqueo_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_arqueo
    ADD CONSTRAINT caja_fondo_arqueo_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4955 (class 2606 OID 155709)
-- Name: caja_fondo_mov_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_mov
    ADD CONSTRAINT caja_fondo_mov_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4956 (class 2606 OID 155714)
-- Name: caja_fondo_usuario_fondo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY caja_fondo_usuario
    ADD CONSTRAINT caja_fondo_usuario_fondo_id_fkey FOREIGN KEY (fondo_id) REFERENCES caja_fondo(id) ON DELETE CASCADE;


--
-- TOC entry 4957 (class 2606 OID 155719)
-- Name: cash_fund_arqueos_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 4958 (class 2606 OID 155724)
-- Name: cash_fund_arqueos_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4961 (class 2606 OID 155729)
-- Name: cash_fund_movements_approved_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4962 (class 2606 OID 155734)
-- Name: cash_fund_movements_cash_fund_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_cash_fund_id_foreign FOREIGN KEY (cash_fund_id) REFERENCES cash_funds(id) ON DELETE CASCADE;


--
-- TOC entry 4963 (class 2606 OID 155739)
-- Name: cash_fund_movements_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4964 (class 2606 OID 155744)
-- Name: cash_funds_created_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4965 (class 2606 OID 155749)
-- Name: cash_funds_responsable_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign FOREIGN KEY (responsable_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4966 (class 2606 OID 155754)
-- Name: cat_almacenes_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_almacenes
    ADD CONSTRAINT cat_almacenes_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 4967 (class 2606 OID 155759)
-- Name: cat_uom_conversion_destino_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_destino_id_foreign FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 4968 (class 2606 OID 155764)
-- Name: cat_uom_conversion_origen_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cat_uom_conversion
    ADD CONSTRAINT cat_uom_conversion_origen_id_foreign FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;


--
-- TOC entry 4969 (class 2606 OID 155769)
-- Name: conciliacion_postcorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conciliacion
    ADD CONSTRAINT conciliacion_postcorte_id_fkey FOREIGN KEY (postcorte_id) REFERENCES postcorte(id) ON DELETE CASCADE;


--
-- TOC entry 4970 (class 2606 OID 155774)
-- Name: conversiones_unidad_unidad_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_destino_id_fkey FOREIGN KEY (unidad_destino_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4971 (class 2606 OID 155779)
-- Name: conversiones_unidad_unidad_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY conversiones_unidad_legacy
    ADD CONSTRAINT conversiones_unidad_unidad_origen_id_fkey FOREIGN KEY (unidad_origen_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4972 (class 2606 OID 155784)
-- Name: cost_layer_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 4973 (class 2606 OID 155789)
-- Name: cost_layer_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cost_layer
    ADD CONSTRAINT cost_layer_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4989 (class 2606 OID 155794)
-- Name: fk_inventory_snapshot_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_snapshot
    ADD CONSTRAINT fk_inventory_snapshot_item FOREIGN KEY (item_id) REFERENCES items(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5025 (class 2606 OID 155799)
-- Name: fk_pos_map_receta; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_map
    ADD CONSTRAINT fk_pos_map_receta FOREIGN KEY (receta_id) REFERENCES receta_cab(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5036 (class 2606 OID 155804)
-- Name: fk_preq_almacen_destino; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_almacen_destino FOREIGN KEY (almacen_destino_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5037 (class 2606 OID 155809)
-- Name: fk_preq_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_requests
    ADD CONSTRAINT fk_preq_suggestion FOREIGN KEY (origen_suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE SET NULL;


--
-- TOC entry 5041 (class 2606 OID 155814)
-- Name: fk_psugg_almacen; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_almacen FOREIGN KEY (almacen_id) REFERENCES cat_almacenes(id) ON DELETE SET NULL;


--
-- TOC entry 5042 (class 2606 OID 155819)
-- Name: fk_psugg_request; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_request FOREIGN KEY (convertido_a_request_id) REFERENCES purchase_requests(id) ON DELETE SET NULL;


--
-- TOC entry 5043 (class 2606 OID 155824)
-- Name: fk_psugg_sucursal; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_sucursal FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE SET NULL;


--
-- TOC entry 5044 (class 2606 OID 155829)
-- Name: fk_psugg_user_revisado; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado FOREIGN KEY (revisado_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5045 (class 2606 OID 155834)
-- Name: fk_psugg_user_sugerido; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido FOREIGN KEY (sugerido_por_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5038 (class 2606 OID 155839)
-- Name: fk_psuggline_item; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 5039 (class 2606 OID 155844)
-- Name: fk_psuggline_proveedor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_proveedor FOREIGN KEY (proveedor_sugerido_id) REFERENCES cat_proveedores(id) ON DELETE SET NULL;


--
-- TOC entry 5040 (class 2606 OID 155849)
-- Name: fk_psuggline_suggestion; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_suggestion_lines
    ADD CONSTRAINT fk_psuggline_suggestion FOREIGN KEY (suggestion_id) REFERENCES purchase_suggestions(id) ON DELETE CASCADE;


--
-- TOC entry 5035 (class 2606 OID 155854)
-- Name: fk_purchase_orders_vendor; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY purchase_orders
    ADD CONSTRAINT fk_purchase_orders_vendor FOREIGN KEY (vendor_id) REFERENCES cat_proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5056 (class 2606 OID 155859)
-- Name: fk_recipe_cost_snap_recipe; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_recipe FOREIGN KEY (recipe_id) REFERENCES receta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5057 (class 2606 OID 155864)
-- Name: fk_recipe_cost_snap_user; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recipe_cost_snapshots
    ADD CONSTRAINT fk_recipe_cost_snap_user FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 5065 (class 2606 OID 155869)
-- Name: fk_ticket_det_cab; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT fk_ticket_det_cab FOREIGN KEY (ticket_id) REFERENCES ticket_venta_cab(id) ON DELETE CASCADE;


--
-- TOC entry 4974 (class 2606 OID 155874)
-- Name: hist_cost_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_insumo
    ADD CONSTRAINT hist_cost_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 4975 (class 2606 OID 155879)
-- Name: hist_cost_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY hist_cost_receta
    ADD CONSTRAINT hist_cost_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4976 (class 2606 OID 155884)
-- Name: historial_costos_item_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_item
    ADD CONSTRAINT historial_costos_item_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4977 (class 2606 OID 155889)
-- Name: historial_costos_receta_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY historial_costos_receta
    ADD CONSTRAINT historial_costos_receta_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 4979 (class 2606 OID 155894)
-- Name: insumo_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT;


--
-- TOC entry 4980 (class 2606 OID 155899)
-- Name: insumo_presentacion_um_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_presentacion
    ADD CONSTRAINT insumo_presentacion_um_compra_id_fkey FOREIGN KEY (um_compra_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4981 (class 2606 OID 155904)
-- Name: insumo_proveedor_presentacion_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4978 (class 2606 OID 155909)
-- Name: insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo
    ADD CONSTRAINT insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 4985 (class 2606 OID 155914)
-- Name: inv_consumo_pos_det_consumo_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_consumo_pos_det
    ADD CONSTRAINT inv_consumo_pos_det_consumo_id_fkey FOREIGN KEY (consumo_id) REFERENCES inv_consumo_pos(id) ON DELETE CASCADE;


--
-- TOC entry 4986 (class 2606 OID 155919)
-- Name: inv_stock_policy_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_item_id_foreign FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;


--
-- TOC entry 4987 (class 2606 OID 155924)
-- Name: inv_stock_policy_sucursal_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inv_stock_policy
    ADD CONSTRAINT inv_stock_policy_sucursal_id_foreign FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE CASCADE;


--
-- TOC entry 4988 (class 2606 OID 155929)
-- Name: inventory_batch_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY inventory_batch
    ADD CONSTRAINT inventory_batch_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4982 (class 2606 OID 155934)
-- Name: ipp_proveedor_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_proveedor_fk FOREIGN KEY (proveedor_id) REFERENCES proveedor(id);


--
-- TOC entry 4983 (class 2606 OID 155939)
-- Name: ipp_uom_base_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_base_fk FOREIGN KEY (uom_base_id) REFERENCES cat_unidades(id);


--
-- TOC entry 4984 (class 2606 OID 155944)
-- Name: ipp_uom_compra_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY insumo_proveedor_presentacion
    ADD CONSTRAINT ipp_uom_compra_fk FOREIGN KEY (uom_compra_id) REFERENCES cat_unidades(id);


--
-- TOC entry 4990 (class 2606 OID 155949)
-- Name: item_vendor_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4991 (class 2606 OID 155954)
-- Name: item_vendor_unidad_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY item_vendor
    ADD CONSTRAINT item_vendor_unidad_presentacion_id_fkey FOREIGN KEY (unidad_presentacion_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 4992 (class 2606 OID 155959)
-- Name: items_category_fk; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_category_fk FOREIGN KEY (category_id) REFERENCES item_categories(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4993 (class 2606 OID 155964)
-- Name: items_unidad_compra_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_compra_id_fkey FOREIGN KEY (unidad_compra_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4994 (class 2606 OID 155969)
-- Name: items_unidad_medida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4995 (class 2606 OID 155974)
-- Name: items_unidad_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_unidad_salida_id_fkey FOREIGN KEY (unidad_salida_id) REFERENCES cat_unidades(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4996 (class 2606 OID 155979)
-- Name: lote_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY lote
    ADD CONSTRAINT lote_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 4999 (class 2606 OID 155984)
-- Name: merma_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5000 (class 2606 OID 155989)
-- Name: merma_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5001 (class 2606 OID 155994)
-- Name: merma_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5002 (class 2606 OID 155999)
-- Name: merma_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY merma
    ADD CONSTRAINT merma_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5003 (class 2606 OID 156004)
-- Name: model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5004 (class 2606 OID 156009)
-- Name: model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 5005 (class 2606 OID 156014)
-- Name: modificadores_pos_receta_modificador_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY modificadores_pos
    ADD CONSTRAINT modificadores_pos_receta_modificador_id_fkey FOREIGN KEY (receta_modificador_id) REFERENCES receta_cab(id);


--
-- TOC entry 5006 (class 2606 OID 156019)
-- Name: mov_inv_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5007 (class 2606 OID 156024)
-- Name: mov_inv_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY mov_inv
    ADD CONSTRAINT mov_inv_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5011 (class 2606 OID 156029)
-- Name: op_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5012 (class 2606 OID 156034)
-- Name: op_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5013 (class 2606 OID 156039)
-- Name: op_cab_um_salida_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_um_salida_id_fkey FOREIGN KEY (um_salida_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5014 (class 2606 OID 156044)
-- Name: op_cab_user_abre_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey FOREIGN KEY (usuario_abre) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5015 (class 2606 OID 156049)
-- Name: op_cab_user_cierra_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey FOREIGN KEY (usuario_cierra) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5016 (class 2606 OID 156054)
-- Name: op_insumo_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5017 (class 2606 OID 156059)
-- Name: op_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5018 (class 2606 OID 156064)
-- Name: op_insumo_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5019 (class 2606 OID 156069)
-- Name: op_insumo_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_insumo
    ADD CONSTRAINT op_insumo_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5020 (class 2606 OID 156074)
-- Name: op_produccion_cab_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_produccion_cab
    ADD CONSTRAINT op_produccion_cab_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5021 (class 2606 OID 156079)
-- Name: op_yield_op_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY op_yield
    ADD CONSTRAINT op_yield_op_id_fkey FOREIGN KEY (op_id) REFERENCES op_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5022 (class 2606 OID 156084)
-- Name: perdida_log_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5023 (class 2606 OID 156089)
-- Name: perdida_log_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5024 (class 2606 OID 156094)
-- Name: perdida_log_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY perdida_log
    ADD CONSTRAINT perdida_log_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5028 (class 2606 OID 168537)
-- Name: postcorte_aprobado_por_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_aprobado_por_fkey FOREIGN KEY (aprobado_por) REFERENCES users(id);


--
-- TOC entry 5027 (class 2606 OID 168553)
-- Name: postcorte_rechazado_por_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_rechazado_por_fkey FOREIGN KEY (rechazado_por) REFERENCES users(id);


--
-- TOC entry 5029 (class 2606 OID 157151)
-- Name: postcorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY postcorte
    ADD CONSTRAINT postcorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5031 (class 2606 OID 156104)
-- Name: precorte_efectivo_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_efectivo
    ADD CONSTRAINT precorte_efectivo_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5032 (class 2606 OID 156109)
-- Name: precorte_otros_precorte_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte_otros
    ADD CONSTRAINT precorte_otros_precorte_id_fkey FOREIGN KEY (precorte_id) REFERENCES precorte(id) ON DELETE CASCADE;


--
-- TOC entry 5030 (class 2606 OID 157156)
-- Name: precorte_sesion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: floreant
--

ALTER TABLE ONLY precorte
    ADD CONSTRAINT precorte_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesion_cajon(id) ON DELETE CASCADE;


--
-- TOC entry 5033 (class 2606 OID 156119)
-- Name: prod_cab_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_cab
    ADD CONSTRAINT prod_cab_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id);


--
-- TOC entry 5034 (class 2606 OID 156124)
-- Name: prod_det_prod_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY prod_det
    ADD CONSTRAINT prod_det_prod_id_fkey FOREIGN KEY (prod_id) REFERENCES prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5046 (class 2606 OID 156129)
-- Name: recalc_log_job_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recalc_log
    ADD CONSTRAINT recalc_log_job_id_fkey FOREIGN KEY (job_id) REFERENCES job_recalc_queue(id);


--
-- TOC entry 5047 (class 2606 OID 156134)
-- Name: recepcion_cab_sucursal_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_sucursal_id_fkey FOREIGN KEY (sucursal_id) REFERENCES cat_sucursales(id) ON DELETE RESTRICT;


--
-- TOC entry 5048 (class 2606 OID 156139)
-- Name: recepcion_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5049 (class 2606 OID 156144)
-- Name: recepcion_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5050 (class 2606 OID 156149)
-- Name: recepcion_det_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_bodega_id_fkey FOREIGN KEY (bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5051 (class 2606 OID 156154)
-- Name: recepcion_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5052 (class 2606 OID 156159)
-- Name: recepcion_det_recepcion_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_recepcion_id_fkey FOREIGN KEY (recepcion_id) REFERENCES recepcion_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5053 (class 2606 OID 156164)
-- Name: recepcion_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY recepcion_det
    ADD CONSTRAINT recepcion_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5008 (class 2606 OID 156169)
-- Name: receta_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5009 (class 2606 OID 156174)
-- Name: receta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_det
    ADD CONSTRAINT receta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5054 (class 2606 OID 156179)
-- Name: receta_insumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5055 (class 2606 OID 156184)
-- Name: receta_insumo_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_insumo
    ADD CONSTRAINT receta_insumo_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5010 (class 2606 OID 156189)
-- Name: receta_version_receta_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY receta_version
    ADD CONSTRAINT receta_version_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES receta_cab(id);


--
-- TOC entry 5058 (class 2606 OID 156194)
-- Name: role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;


--
-- TOC entry 5059 (class 2606 OID 156199)
-- Name: role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- TOC entry 4950 (class 2606 OID 156204)
-- Name: selemti_audit_log_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- TOC entry 4959 (class 2606 OID 156209)
-- Name: selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 4960 (class 2606 OID 156214)
-- Name: selemti_cash_fund_movement_audit_log_movement_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_movement_id_foreign FOREIGN KEY (movement_id) REFERENCES cash_fund_movements(id) ON DELETE CASCADE;


--
-- TOC entry 4997 (class 2606 OID 156219)
-- Name: selemti_menu_engineering_snapshots_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_engineering_snapshots
    ADD CONSTRAINT selemti_menu_engineering_snapshots_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 4998 (class 2606 OID 156224)
-- Name: selemti_menu_item_sync_map_menu_item_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY menu_item_sync_map
    ADD CONSTRAINT selemti_menu_item_sync_map_menu_item_id_foreign FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- TOC entry 5026 (class 2606 OID 156229)
-- Name: selemti_pos_sync_logs_batch_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY pos_sync_logs
    ADD CONSTRAINT selemti_pos_sync_logs_batch_id_foreign FOREIGN KEY (batch_id) REFERENCES pos_sync_batches(id) ON DELETE CASCADE;


--
-- TOC entry 5079 (class 2606 OID 156930)
-- Name: selemti_report_runs_report_id_foreign; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY report_runs
    ADD CONSTRAINT selemti_report_runs_report_id_foreign FOREIGN KEY (report_id) REFERENCES report_definitions(id) ON DELETE CASCADE;


--
-- TOC entry 5060 (class 2606 OID 156239)
-- Name: sol_prod_det_sol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY sol_prod_det
    ADD CONSTRAINT sol_prod_det_sol_id_fkey FOREIGN KEY (sol_id) REFERENCES sol_prod_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5061 (class 2606 OID 156244)
-- Name: stock_policy_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY stock_policy
    ADD CONSTRAINT stock_policy_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5062 (class 2606 OID 156249)
-- Name: ticket_det_consumo_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5063 (class 2606 OID 156254)
-- Name: ticket_det_consumo_lote_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5064 (class 2606 OID 156259)
-- Name: ticket_det_consumo_uom_original_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_det_consumo
    ADD CONSTRAINT ticket_det_consumo_uom_original_id_fkey FOREIGN KEY (uom_original_id) REFERENCES unidades_medida_legacy(id);


--
-- TOC entry 5066 (class 2606 OID 156264)
-- Name: ticket_venta_det_receta_shadow_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_shadow_id_fkey FOREIGN KEY (receta_shadow_id) REFERENCES receta_shadow(id);


--
-- TOC entry 5067 (class 2606 OID 156269)
-- Name: ticket_venta_det_receta_version_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY ticket_venta_det
    ADD CONSTRAINT ticket_venta_det_receta_version_id_fkey FOREIGN KEY (receta_version_id) REFERENCES receta_version(id);


--
-- TOC entry 5068 (class 2606 OID 156274)
-- Name: transfer_det_transfer_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY transfer_det
    ADD CONSTRAINT transfer_det_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES transfer_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5069 (class 2606 OID 156279)
-- Name: traspaso_cab_from_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey FOREIGN KEY (from_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5070 (class 2606 OID 156284)
-- Name: traspaso_cab_to_bodega_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey FOREIGN KEY (to_bodega_id) REFERENCES cat_almacenes(id) ON DELETE RESTRICT;


--
-- TOC entry 5071 (class 2606 OID 156289)
-- Name: traspaso_cab_user_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- TOC entry 5072 (class 2606 OID 156294)
-- Name: traspaso_det_batch_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES inventory_batch(id);


--
-- TOC entry 5073 (class 2606 OID 156299)
-- Name: traspaso_det_item_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- TOC entry 5074 (class 2606 OID 156304)
-- Name: traspaso_det_traspaso_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_traspaso_id_fkey FOREIGN KEY (traspaso_id) REFERENCES traspaso_cab(id) ON DELETE CASCADE;


--
-- TOC entry 5075 (class 2606 OID 156309)
-- Name: traspaso_det_um_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY traspaso_det
    ADD CONSTRAINT traspaso_det_um_id_fkey FOREIGN KEY (um_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5076 (class 2606 OID 156314)
-- Name: uom_conversion_destino_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5077 (class 2606 OID 156319)
-- Name: uom_conversion_origen_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY uom_conversion_legacy
    ADD CONSTRAINT uom_conversion_origen_id_fkey FOREIGN KEY (origen_id) REFERENCES unidad_medida_legacy(id);


--
-- TOC entry 5078 (class 2606 OID 156324)
-- Name: usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: selemti; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES rol(id);


--
-- TOC entry 5406 (class 0 OID 152949)
-- Dependencies: 306 5564
-- Name: mv_inventario_actual; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_inventario_actual;


--
-- TOC entry 5410 (class 0 OID 152991)
-- Dependencies: 310 5564
-- Name: mv_recetas_costos; Type: MATERIALIZED VIEW DATA; Schema: selemti; Owner: postgres
--

REFRESH MATERIALIZED VIEW mv_recetas_costos;


--
-- TOC entry 5791 (class 0 OID 0)
-- Dependencies: 696
-- Name: vw_sesion_dpr; Type: ACL; Schema: selemti; Owner: postgres
--

REVOKE ALL ON TABLE vw_sesion_dpr FROM PUBLIC;
REVOKE ALL ON TABLE vw_sesion_dpr FROM postgres;
GRANT ALL ON TABLE vw_sesion_dpr TO postgres;
GRANT SELECT ON TABLE vw_sesion_dpr TO floreant;


-- Completed on 2025-11-17 23:28:40

--
-- PostgreSQL database dump complete
--

