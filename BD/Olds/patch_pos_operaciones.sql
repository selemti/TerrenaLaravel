-- Script incremental para actualizar funciones, vistas y triggers
-- críticos del flujo de caja en Floreant POS sin recrear tablas ni
-- objetos existentes. Todas las definiciones usan CREATE OR REPLACE
-- y se restablecen los triggers necesarios.

BEGIN;

SET search_path = selemti, public;

-- ---------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION selemti.fn_resolver_terminal_para_usuario(
  p_user integer,
  p_ref_time timestamp with time zone DEFAULT now()
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_terminal_id integer;
BEGIN
  SELECT t.id
    INTO v_terminal_id
  FROM public.terminal t
  WHERE t.assigned_user = p_user
  ORDER BY t.id
  LIMIT 1;

  IF v_terminal_id IS NOT NULL THEN
    RETURN v_terminal_id;
  END IF;

  SELECT s.terminal_id
    INTO v_terminal_id
  FROM selemti.sesion_cajon s
  WHERE s.cajero_usuario_id = p_user
    AND (s.apertura_ts IS NULL OR s.apertura_ts <= COALESCE(p_ref_time, now()))
  ORDER BY (s.cierre_ts IS NULL) DESC, s.apertura_ts DESC
  LIMIT 1;

  RETURN v_terminal_id;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_fondo_actual(p_terminal_id integer)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  v_balance numeric(12,2);
BEGIN
  SELECT t.current_balance::numeric(12,2)
    INTO v_balance
  FROM public.terminal t
  WHERE t.id = p_terminal_id;

  RETURN COALESCE(v_balance, 0);
END;
$$;

-- ---------------------------------------------------------------
-- Funciones en esquema public
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._last_assign_window(
  _terminal_id integer,
  _user_id integer,
  _ref_time timestamp with time zone
)
RETURNS TABLE(from_ts timestamp with time zone, to_ts timestamp with time zone)
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

CREATE OR REPLACE FUNCTION public.assign_daily_folio()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_branch   text;
    v_date     date;
    v_next     integer;
BEGIN
    IF NEW.terminal_id IS NULL THEN
        RAISE EXCEPTION 'No se puede crear ticket sin terminal_id';
    END IF;
    IF NEW.create_date IS NULL THEN
        NEW.create_date := now();
    END IF;
    v_date := (NEW.create_date AT TIME ZONE 'America/Mexico_City')::date;
    SELECT COALESCE(NULLIF(UPPER(BTRIM(t.location)), ''), '')
      INTO v_branch
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
              AND id <> NEW.id
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
    NEW.folio_date   := v_date;
    NEW.branch_key   := v_branch;
    NEW.daily_folio  := v_next;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_correct_drawer_report(report_date date)
RETURNS TABLE(terminal_id integer, original_total_revenue numeric, corrected_neto_tickets numeric, adjustment numeric)
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

CREATE OR REPLACE FUNCTION public.fn_daily_reconciliation(report_date date)
RETURNS TABLE(
  terminal_id integer,
  tickets_count integer,
  transactions_count integer,
  ticket_net_total numeric,
  transactions_total numeric,
  difference numeric,
  status text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.terminal_id,
    COUNT(DISTINCT t.id) AS tickets_count,
    COUNT(tx.id) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_time::date = report_date
    ) AS transactions_count,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS ticket_net_total,
    SUM(tx.amount)::numeric(12,2) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_time::date = report_date
    ) AS transactions_total,
    SUM(tx.amount) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_time::date = report_date
    ) - SUM(t.total_price - t.total_discount) AS difference,
    CASE
      WHEN SUM(tx.amount) FILTER (
             WHERE tx.voided = FALSE
               AND tx.transaction_time::date = report_date
           ) - SUM(t.total_price - t.total_discount) = 0
        THEN 'CUADRA'
      ELSE 'REVISION'
    END AS status
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.voided = FALSE
  GROUP BY t.terminal_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_reconciliation_detail(report_date date)
RETURNS TABLE(
  ticket_id integer,
  terminal_id integer,
  ticket_number integer,
  ticket_total numeric,
  ticket_discount numeric,
  ticket_neto numeric,
  transactions_sum numeric,
  discrepancy numeric,
  discrepancy_type text
)
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
    SUM(tx.amount)::numeric(12,2) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_time::date = report_date
    ) AS transactions_sum,
    COALESCE(
      SUM(tx.amount) FILTER (
        WHERE tx.voided = FALSE
          AND tx.transaction_time::date = report_date
      ),
      0
    ) - (t.total_price - t.total_discount) AS discrepancy,
    CASE
      WHEN COALESCE(
             SUM(tx.amount) FILTER (
               WHERE tx.voided = FALSE
                 AND tx.transaction_time::date = report_date
             ), 0
           ) = (t.total_price - t.total_discount)
        THEN 'CUADRA'
      WHEN COALESCE(
             SUM(tx.amount) FILTER (
               WHERE tx.voided = FALSE
                 AND tx.transaction_time::date = report_date
             ), 0
           ) > (t.total_price - t.total_discount)
        THEN 'EXCESO'
      ELSE 'FALTA'
    END AS discrepancy_type
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.voided = FALSE
  GROUP BY t.id, t.terminal_id, t.daily_folio, t.total_price, t.total_discount;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_daily_stats(
  p_date date DEFAULT current_date
)
RETURNS TABLE(
  sucursal text,
  total_ordenes integer,
  total_ventas numeric,
  primer_orden time without time zone,
  ultima_orden time without time zone,
  promedio_por_hora numeric
)
LANGUAGE sql STABLE
AS $$
    SELECT
        tfc.branch_key,
        COUNT(*)::integer AS total_ordenes,
        SUM(tfc.total_price)::numeric AS total_ventas,
        MIN(tfc.create_date::time) AS primer_orden,
        MAX(tfc.create_date::time) AS ultima_orden,
        ROUND(
            (COUNT(*)::numeric /
            GREATEST(EXTRACT(EPOCH FROM (MAX(tfc.create_date) - MIN(tfc.create_date))) / 3600.0, 1))::numeric,
            2
        ) AS promedio_por_hora
    FROM public.ticket_folio_complete tfc
    WHERE tfc.folio_date = p_date
      AND tfc.status_simple <> 'CANCELADO'
    GROUP BY tfc.branch_key
    ORDER BY tfc.branch_key;
$$;

CREATE OR REPLACE FUNCTION public.get_ticket_folio_info(p_ticket_id integer)
RETURNS TABLE(
  daily_folio integer,
  folio_date date,
  branch_key text,
  folio_date_txt text,
  folio_display text,
  sucursal_completa text,
  terminal_name text
)
LANGUAGE sql STABLE
AS $$
    SELECT
        t.daily_folio,
        t.folio_date,
        t.branch_key,
        TO_CHAR(t.folio_date, 'DD/MM/YYYY') AS folio_date_txt,
        LPAD(t.daily_folio::text, 4, '0') AS folio_display,
        COALESCE(term.location, 'DEFAULT') AS sucursal_completa,
        term.name AS terminal_name
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.id = p_ticket_id;
$$;

CREATE OR REPLACE FUNCTION public.kds_notify()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ticket_id   integer;
    v_pg_id       integer;
    v_item_id     integer;
    v_status      text;
    v_total       integer;
    v_ready       integer;
    v_done        integer;
    v_type        text;
    v_daily_folio integer;
    v_branch_key  text;
    v_folio_fmt   text;
BEGIN
    IF TG_TABLE_NAME = 'kitchen_ticket_item' THEN
        IF NEW.ticket_item_id IS NULL THEN
            RAISE EXCEPTION 'ticket_item_id no puede ser NULL en kitchen_ticket_item';
        END IF;
        v_item_id := NEW.ticket_item_id;
        SELECT ti.ticket_id, ti.pg_id
          INTO v_ticket_id, v_pg_id
        FROM public.ticket_item ti
        WHERE ti.id = v_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket_item % no existe', v_item_id;
        END IF;
    ELSE
        v_item_id := NEW.id;
        v_ticket_id := NEW.ticket_id;
        v_pg_id := NEW.pg_id;
        IF v_ticket_id IS NULL THEN
            RAISE EXCEPTION 'ticket_id no puede ser NULL en ticket_item';
        END IF;
    END IF;

    SELECT daily_folio, branch_key
      INTO v_daily_folio, v_branch_key
    FROM public.ticket
    WHERE id = v_ticket_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'ticket % no existe', v_ticket_id;
    END IF;

    v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::text, 4, '0');
    v_status    := UPPER(COALESCE(NEW.status, ''));

    IF TG_OP = 'INSERT' THEN
        v_type := CASE WHEN TG_TABLE_NAME = 'kitchen_ticket_item' THEN 'item_upsert' ELSE 'item_insert' END;
    ELSE
        v_type := 'item_status';
    END IF;

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
            'ts',          now()
        )::text
    );

    IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
        WITH s AS (
            SELECT
                ti.id AS item_id,
                UPPER(COALESCE(kti.status, ti.status, '')) AS st
            FROM public.ticket_item ti
            LEFT JOIN public.kitchen_ticket_item kti
              ON kti.ticket_item_id = ti.id
            WHERE ti.ticket_id = v_ticket_id
              AND ti.pg_id = v_pg_id
            GROUP BY ti.id, st
        )
        SELECT
            COUNT(DISTINCT item_id),
            COUNT(DISTINCT item_id) FILTER (WHERE st IN ('READY', 'DONE')),
            COUNT(DISTINCT item_id) FILTER (WHERE st = 'DONE')
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
                    'ts',          now()
                )::text
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
                    'ts',          now()
                )::text
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.reset_daily_folio_smart(p_branch text DEFAULT NULL::text)
RETURNS TABLE(branch_reset text, tickets_affected integer)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date date := current_date;
    v_branch text;
    v_has_rows boolean;
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
         WHERE branch_key = v_branch
           AND folio_date = v_current_date;
        branch_reset := v_branch;
        tickets_affected := 0;
        RETURN NEXT;
    END LOOP;
    RETURN;
END;
$$;

-- ---------------------------------------------------------------
-- Funciones en esquema selemti
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_terminal_id integer;
  v_apertura_ts timestamptz := NEW."time";
  v_fondo       numeric(12,2) := 0;
  v_op          text := COALESCE(NEW.operation, '');
  v_obj_id      bigint;
BEGIN
  v_terminal_id := selemti.fn_resolver_terminal_para_usuario(NEW.a_user, NEW."time");

  IF v_terminal_id IS NULL THEN
    INSERT INTO selemti.auditoria(quien, que, payload)
    VALUES (
      NEW.a_user,
      'NO_SE_PUDO_RESOLVER_TERMINAL',
      jsonb_build_object('dah_id', NEW.id, 'operation', NEW.operation, 'time', NEW."time")
    );
    RETURN NEW;
  END IF;

  IF v_op ~* '(assign|asign|open|apert)' THEN
    v_fondo := selemti.fn_fondo_actual(v_terminal_id);

    IF NOT EXISTS (
      SELECT 1
      FROM selemti.sesion_cajon s
      WHERE s.terminal_id = v_terminal_id
        AND s.cajero_usuario_id = NEW.a_user
        AND s.apertura_ts = v_apertura_ts
    ) THEN
      INSERT INTO selemti.sesion_cajon(
        terminal_id,
        cajero_usuario_id,
        dah_evento_id,
        apertura_ts,
        estatus,
        opening_float,
        creado_por
      ) VALUES (
        v_terminal_id,
        NEW.a_user,
        NEW.id,
        v_apertura_ts,
        'ACTIVA',
        v_fondo,
        NEW.a_user
      );

      INSERT INTO selemti.auditoria(quien, que, payload)
      VALUES (
        NEW.a_user,
        'APERTURA_SESION_CAJON',
        jsonb_build_object('fondo', v_fondo)
      );
    END IF;
  END IF;

  IF v_op ~* '(release|liber|close|cerrar|unassign|fin|end)' THEN
    SELECT s.id
      INTO v_obj_id
    FROM selemti.sesion_cajon s
    WHERE s.terminal_id = v_terminal_id
      AND s.cajero_usuario_id = NEW.a_user
      AND s.cierre_ts IS NULL
    ORDER BY s.apertura_ts DESC
    LIMIT 1;

    IF v_obj_id IS NOT NULL THEN
      UPDATE selemti.sesion_cajon
      SET cierre_ts = COALESCE(cierre_ts, NEW."time"),
          estatus   = CASE WHEN estatus = 'ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
      WHERE id = v_obj_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert_refuerzo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_terminal_id integer;
  v_now_balance numeric(12,2);
  v_op          text := COALESCE(NEW.operation, '');
  v_obj_id      bigint;
BEGIN
  IF v_op !~* '(release|liber|close|cerrar|unassign|fin|end)' THEN
    RETURN NEW;
  END IF;

  v_terminal_id := selemti.fn_resolver_terminal_para_usuario(NEW.a_user, NEW."time");
  IF v_terminal_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT current_balance::numeric
    INTO v_now_balance
  FROM public.terminal
  WHERE id = v_terminal_id;

  SELECT s.id
    INTO v_obj_id
  FROM selemti.sesion_cajon s
  WHERE s.terminal_id = v_terminal_id
    AND s.cajero_usuario_id = NEW.a_user
    AND s.cierre_ts IS NULL
  ORDER BY s.apertura_ts DESC
  LIMIT 1;

  IF v_obj_id IS NOT NULL THEN
    UPDATE selemti.sesion_cajon
       SET closing_float = COALESCE(closing_float, NULLIF(v_now_balance, 0)),
           cierre_ts     = COALESCE(cierre_ts, NEW."time"),
           estatus       = CASE WHEN estatus = 'ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
     WHERE id = v_obj_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_generar_postcorte(p_sesion_id bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_postcorte_id bigint;
  v_precorte_id bigint;
  v_terminal_id int;
  v_apertura_ts timestamptz;
  v_cierre_ts timestamptz;
  v_decl_ef numeric;
  v_decl_cr numeric;
  v_decl_db numeric;
  v_decl_tr numeric;
  v_sys_ef numeric;
  v_sys_cr numeric;
  v_sys_db numeric;
  v_sys_tr numeric;
  v_dif_ef numeric;
  v_dif_tj numeric;
  v_dif_tr numeric;
BEGIN
  SELECT terminal_id, apertura_ts, cierre_ts
    INTO v_terminal_id, v_apertura_ts, v_cierre_ts
  FROM selemti.sesion_cajon
  WHERE id = p_sesion_id;

  SELECT id
    INTO v_precorte_id
  FROM selemti.precorte
  WHERE sesion_id = p_sesion_id
  ORDER BY id DESC
  LIMIT 1;

  SELECT COALESCE(SUM(subtotal), 0)
    INTO v_decl_ef
  FROM selemti.precorte_efectivo
  WHERE precorte_id = v_precorte_id;

  SELECT
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('CREDITO') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) = 'DEBITO' THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('TRANSFER', 'TRANSFERENCIA') THEN monto ELSE 0 END), 0)
  INTO v_decl_cr, v_decl_db, v_decl_tr
  FROM selemti.precorte_otros
  WHERE precorte_id = v_precorte_id;

  SELECT
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CASH' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CREDIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'DEBIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CUSTOM_PAYMENT'
                      AND UPPER(custom_payment_name) LIKE 'TRANSFER%' THEN amount ELSE 0 END), 0)
  INTO v_sys_ef, v_sys_cr, v_sys_db, v_sys_tr
  FROM public.transactions
  WHERE terminal_id = v_terminal_id
    AND transaction_time BETWEEN v_apertura_ts AND COALESCE(v_cierre_ts, now())
    AND UPPER(transaction_type) = 'CREDIT'
    AND voided = FALSE;

  v_dif_ef := v_decl_ef - v_sys_ef;
  v_dif_tj := (v_decl_cr + v_decl_db) - (v_sys_cr + v_sys_db);
  v_dif_tr := v_decl_tr - v_sys_tr;

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

CREATE OR REPLACE FUNCTION selemti.fn_normalizar_forma_pago(
  p_payment_type text,
  p_transaction_type text,
  p_payment_sub_type text,
  p_custom_name text
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  pt text := upper(coalesce(p_payment_type, ''));
  cn text := selemti.fn_slug(p_custom_name);
BEGIN
  IF pt IN ('CASH', 'CREDIT', 'DEBIT', 'TRANSFER') THEN
    RETURN pt;
  ELSIF pt = 'CUSTOM_PAYMENT' THEN
    IF cn LIKE 'TRANSFER%' THEN
      RETURN 'TRANSFER';
    ELSIF cn LIKE 'VALE%' THEN
      RETURN 'VALE';
    END IF;
  END IF;
  RETURN pt;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_precorte_efectivo_bi()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.subtotal := COALESCE(NEW.denominacion, 0) * COALESCE(NEW.cantidad, 0);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_reparar_sesion_apertura(
  p_terminal_id integer,
  p_usuario integer
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_term RECORD;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM selemti.sesion_cajon
    WHERE terminal_id = p_terminal_id
      AND cajero_usuario_id = p_usuario
      AND cierre_ts IS NULL
  ) THEN
    RETURN 'YA_EXISTE_SESION_ABIERTA';
  END IF;

  SELECT *
    INTO v_term
  FROM public.terminal
  WHERE id = p_terminal_id;

  IF NOT FOUND THEN
    RETURN 'TERMINAL_NO_ENCONTRADA';
  END IF;

  INSERT INTO selemti.sesion_cajon(
    terminal_id,
    terminal_nombre,
    sucursal,
    cajero_usuario_id,
    apertura_ts,
    estatus,
    opening_float,
    dah_evento_id
  ) VALUES (
    v_term.id,
    COALESCE(v_term.name, 'Terminal ' || v_term.id),
    COALESCE(v_term.location, ''),
    p_usuario,
    now(),
    'ACTIVA',
    COALESCE(v_term.current_balance, 0),
    NULL
  );

  RETURN 'SESION_RESTAURADA';
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_terminal_bu_snapshot_cierre()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_obj_id bigint;
BEGIN
  IF OLD.assigned_user IS NOT NULL AND NEW.assigned_user IS NULL THEN
    SELECT s.id
      INTO v_obj_id
    FROM selemti.sesion_cajon s
    WHERE s.terminal_id = OLD.id
      AND s.cajero_usuario_id = OLD.assigned_user
      AND s.cierre_ts IS NULL
    ORDER BY s.apertura_ts DESC
    LIMIT 1;

    IF v_obj_id IS NOT NULL THEN
      UPDATE selemti.sesion_cajon
      SET closing_float = COALESCE(closing_float, OLD.current_balance::numeric),
          cierre_ts     = COALESCE(cierre_ts, now()),
          estatus       = CASE WHEN estatus = 'ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
      WHERE id = v_obj_id;

      INSERT INTO selemti.auditoria(quien, que, payload)
      VALUES (
        OLD.assigned_user,
        'SNAPSHOT_CIERRE_TERMINAL',
        jsonb_build_object('terminal_id', OLD.id, 'closing_float', OLD.current_balance)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION selemti.fn_tx_after_insert_forma_pago()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_codigo text;
BEGIN
  v_codigo := selemti.fn_normalizar_forma_pago(
    NEW.payment_type,
    NEW.transaction_type,
    NEW.payment_sub_type,
    NEW.custom_payment_name
  );

  INSERT INTO selemti.formas_pago(
    codigo,
    payment_type,
    transaction_type,
    payment_sub_type,
    custom_name,
    custom_ref
  )
  VALUES (
    v_codigo,
    NEW.payment_type,
    NEW.transaction_type,
    NEW.payment_sub_type,
    NEW.custom_payment_name,
    NEW.custom_payment_ref
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------
-- Vistas clave
-- ---------------------------------------------------------------

CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
WITH base AS (
  SELECT
    s.id AS sesion_id,
    t.amount::numeric AS monto,
    COALESCE(
      fp.codigo,
      selemti.fn_normalizar_forma_pago(
        t.payment_type,
        t.transaction_type,
        t.payment_sub_type,
        t.custom_payment_name
      )
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time < COALESCE(s.cierre_ts, now())
   AND t.terminal_id = s.terminal_id
   AND t.user_id = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type = t.payment_type
   AND COALESCE(fp.transaction_type, '') = COALESCE(t.transaction_type, '')
   AND COALESCE(fp.payment_sub_type, '') = COALESCE(t.payment_sub_type, '')
   AND COALESCE(fp.custom_name, '') = COALESCE(t.custom_payment_name, '')
   AND COALESCE(fp.custom_ref, '')  = COALESCE(t.custom_payment_ref, '')
)
SELECT sesion_id, codigo_fp, SUM(monto) AS monto
FROM base
GROUP BY sesion_id, codigo_fp;

CREATE OR REPLACE VIEW selemti.vw_sesion_descuentos AS
SELECT s.id AS sesion_id, 0::numeric AS descuentos
FROM selemti.sesion_cajon s;

CREATE OR REPLACE VIEW selemti.vw_sesion_reembolsos_efectivo AS
SELECT s.id AS sesion_id, 0::numeric AS reembolsos
FROM selemti.sesion_cajon s;

CREATE OR REPLACE VIEW selemti.vw_sesion_retiros AS
SELECT s.id AS sesion_id, 0::numeric AS retiros
FROM selemti.sesion_cajon s;

CREATE OR REPLACE VIEW selemti.vw_conciliacion_sesion AS
SELECT
  s.id AS sesion_id,
  COALESCE(ventas.monto, 0) AS ventas_total,
  COALESCE(descuentos.descuentos, 0) AS descuentos,
  COALESCE(retiros.retiros, 0) AS retiros,
  COALESCE(reembolsos.reembolsos, 0) AS reembolsos
FROM selemti.sesion_cajon s
LEFT JOIN selemti.vw_sesion_ventas ventas
  ON ventas.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_descuentos descuentos
  ON descuentos.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_retiros retiros
  ON retiros.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_reembolsos_efectivo reembolsos
  ON reembolsos.sesion_id = s.id;

-- ---------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_assign_daily_folio ON public.ticket;
CREATE TRIGGER trg_assign_daily_folio
BEFORE INSERT ON public.ticket
FOR EACH ROW
EXECUTE PROCEDURE public.assign_daily_folio();

DROP TRIGGER IF EXISTS trg_kds_notify_kti ON public.kitchen_ticket_item;
CREATE TRIGGER trg_kds_notify_kti
AFTER INSERT OR UPDATE ON public.kitchen_ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();

DROP TRIGGER IF EXISTS trg_kds_notify_ti ON public.ticket_item;
CREATE TRIGGER trg_kds_notify_ti
AFTER INSERT OR UPDATE ON public.ticket_item
FOR EACH ROW
EXECUTE PROCEDURE public.kds_notify();

DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_dah_after_insert();

DROP TRIGGER IF EXISTS trg_selemti_dah_ai_refuerzo ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai_refuerzo
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_dah_after_insert_refuerzo();

DROP TRIGGER IF EXISTS trg_selemti_terminal_bu_snapshot ON public.terminal;
CREATE TRIGGER trg_selemti_terminal_bu_snapshot
BEFORE UPDATE ON public.terminal
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();

DROP TRIGGER IF EXISTS trg_selemti_tx_ai_forma_pago ON public.transactions;
CREATE TRIGGER trg_selemti_tx_ai_forma_pago
AFTER INSERT ON public.transactions
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();

DROP TRIGGER IF EXISTS trg_precorte_efectivo_bi ON selemti.precorte_efectivo;
CREATE TRIGGER trg_precorte_efectivo_bi
BEFORE INSERT OR UPDATE ON selemti.precorte_efectivo
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_precorte_efectivo_bi();

COMMIT;
