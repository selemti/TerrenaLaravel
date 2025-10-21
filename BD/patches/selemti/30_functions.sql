-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
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

CREATE OR REPLACE FUNCTION selemti.fn_fondo_actual(p_terminal_id integer)
RETURNS numeric
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
  -- Obtener datos de sesión
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
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('DEBITO', 'DÉBITO') THEN monto ELSE 0 END), 0),
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

CREATE FUNCTION fn_precorte_after_update_aprobado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_postcorte_id BIGINT;
BEGIN
  IF NEW.estatus = 'APROBADO' AND OLD.estatus != 'APROBADO' THEN
    -- Generar postcorte automáticamente
    SELECT selemti.fn_generar_postcorte(NEW.sesion_id) INTO v_postcorte_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION selemti.fn_precorte_after_update_aprobado() OWNER TO postgres;

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

CREATE FUNCTION ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM 1;
  RETURN;
END;
$$;


ALTER FUNCTION selemti.ingesta_ticket(p_ticket_id bigint, p_sucursal_id integer, p_bodega_id integer, p_usuario_id bigint) OWNER TO postgres;

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

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

COMMIT;
