-- Asegura esquema
CREATE SCHEMA IF NOT EXISTS selemti;

-- 1) TABLAS que faltaron / fallaron
-- 1.1 Detalle de efectivo por denominación
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='selemti' AND table_name='precorte_efectivo'
  ) THEN
    CREATE TABLE selemti.precorte_efectivo (
      id            BIGSERIAL PRIMARY KEY,
      precorte_id   BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
      denominacion  NUMERIC(12,2) NOT NULL,
      cantidad      INTEGER NOT NULL,
      subtotal      NUMERIC(12,2) NOT NULL DEFAULT 0
    );
  END IF;
END$$;

-- Trigger BI para subtotal
CREATE OR REPLACE FUNCTION selemti.fn_precorte_efectivo_bi()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.subtotal := COALESCE(NEW.denominacion,0) * COALESCE(NEW.cantidad,0);
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_precorte_efectivo_bi ON selemti.precorte_efectivo;
CREATE TRIGGER trg_precorte_efectivo_bi
BEFORE INSERT OR UPDATE ON selemti.precorte_efectivo
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_precorte_efectivo_bi();

-- 1.2 Catálogo de Formas de Pago (sin COALESCE en constraint)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='selemti' AND table_name='formas_pago'
  ) THEN
    CREATE TABLE selemti.formas_pago (
      id               BIGSERIAL PRIMARY KEY,
      codigo           TEXT NOT NULL,    -- 'CASH','CREDIT','DEBIT','TRANSFER','CUSTOM:<slug>'
      payment_type     TEXT NOT NULL,
      transaction_type TEXT,
      payment_sub_type TEXT,
      custom_name      TEXT,
      custom_ref       TEXT,
      activo           BOOLEAN NOT NULL DEFAULT TRUE,
      prioridad        INTEGER NOT NULL DEFAULT 100,
      creado_en        TIMESTAMPTZ NOT NULL DEFAULT now(),
      CONSTRAINT uq_fp_codigo UNIQUE (codigo)
    );
  END IF;
END$$;

-- UNIQUE INDEX por expresión para la “huella”
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='selemti' AND indexname='uq_fp_huella_expr'
  ) THEN
    CREATE UNIQUE INDEX uq_fp_huella_expr ON selemti.formas_pago (
      payment_type,
      (coalesce(transaction_type,'')),
      (coalesce(payment_sub_type,'')),
      (coalesce(custom_name,'')),
      (coalesce(custom_ref,''))
    );
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS ix_fp_codigo ON selemti.formas_pago(codigo);

-- 2) Funciones (ASCII-safe) y triggers

-- 2.1 Slug ASCII (evita problemas de codificación)
CREATE OR REPLACE FUNCTION selemti.fn_slug(txt text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE s TEXT := lower(coalesce(txt,''));
BEGIN
  -- sólo minúsculas y guiones (sin acentos para evitar encoding issues)
  s := regexp_replace(s, '[^a-z0-9]+', '-', 'g');
  s := regexp_replace(s, '(^-|-$)', '', 'g');
  IF s = '' THEN RETURN NULL; END IF;
  RETURN s;
END $$;

CREATE OR REPLACE FUNCTION selemti.fn_normalizar_forma_pago(
  p_payment_type TEXT,
  p_transaction_type TEXT,
  p_payment_sub_type TEXT,
  p_custom_name TEXT
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE pt TEXT := upper(coalesce(p_payment_type,''));
DECLARE cn TEXT := selemti.fn_slug(p_custom_name);
BEGIN
  IF pt IN ('CASH','CREDIT','DEBIT','TRANSFER') THEN
    RETURN pt;
  ELSIF pt = 'CUSTOM_PAYMENT' THEN
    IF cn IS NOT NULL THEN
      RETURN 'CUSTOM:' || cn;
    ELSE
      RETURN 'CUSTOM';
    END IF;
  ELSE
    RETURN pt; -- fallback
  END IF;
END $$;

-- Trigger en transactions para auto-poblar catálogo (usa ON CONFLICT DO NOTHING genérico)
CREATE OR REPLACE FUNCTION selemti.fn_tx_after_insert_forma_pago()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_codigo TEXT;
BEGIN
  v_codigo := selemti.fn_normalizar_forma_pago(
                NEW.payment_type,
                NEW.transaction_type,
                NEW.payment_sub_type,
                NEW.custom_payment_name
              );

  INSERT INTO selemti.formas_pago
    (codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref)
  VALUES
    (v_codigo, NEW.payment_type, NEW.transaction_type, NEW.payment_sub_type, NEW.custom_payment_name, NEW.custom_payment_ref)
  ON CONFLICT DO NOTHING;  -- aplica por uq_fp_codigo o por uq_fp_huella_expr

  RETURN NEW;
END $$;

-- (re)crear trigger
DROP TRIGGER IF EXISTS trg_selemti_tx_ai_forma_pago ON public.transactions;
CREATE TRIGGER trg_selemti_tx_ai_forma_pago
AFTER INSERT ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();

-- Semillas mínimas
INSERT INTO selemti.formas_pago(codigo, payment_type)
VALUES ('CASH','CASH'),('CREDIT','CREDIT'),('DEBIT','DEBIT'),('TRANSFER','TRANSFER')
ON CONFLICT DO NOTHING;

-- 2.2 Apertura/cierre por historial (corrige UPDATE sin ORDER BY LIMIT)
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_terminal_id   INTEGER;
  v_apertura_ts   TIMESTAMPTZ := NEW."time";
  v_fondo         NUMERIC(12,2) := 0;
  v_op            TEXT := COALESCE(NEW.operation,'');
  v_obj_id        BIGINT;
BEGIN
  v_terminal_id := selemti.fn_resolver_terminal_para_usuario(NEW.a_user, NEW."time");

  IF v_terminal_id IS NULL THEN
    INSERT INTO selemti.auditoria(quien, que, payload)
    VALUES (NEW.a_user, 'NO_SE_PUDO_RESOLVER_TERMINAL', jsonb_build_object('dah_id',NEW.id,'operation',NEW.operation,'time',NEW."time"));
    RETURN NEW;
  END IF;

  -- Apertura/asignación
  IF v_op ~* '(assign|asign|open|apert)' THEN
    v_fondo := selemti.fn_fondo_actual(v_terminal_id);

    IF NOT EXISTS (
      SELECT 1 FROM selemti.sesion_cajon s
      WHERE s.terminal_id = v_terminal_id
        AND s.cajero_usuario_id = NEW.a_user
        AND s.apertura_ts = v_apertura_ts
    ) THEN
      INSERT INTO selemti.sesion_cajon(terminal_id, cajero_usuario_id, dah_evento_id,
                                       apertura_ts, estatus, opening_float, creado_por)
      VALUES (v_terminal_id, NEW.a_user, NEW.id,
              v_apertura_ts, 'ACTIVA', v_fondo, NEW.a_user);

      INSERT INTO selemti.auditoria(quien, que, payload)
      VALUES (NEW.a_user, 'APERTURA_SESION_CAJON', jsonb_build_object('fondo',v_fondo));
    END IF;
  END IF;

  -- Cierre/liberación base (elige la última sesión abierta via subselect)
  IF v_op ~* '(release|liber|close|cerrar|unassign|fin|end)' THEN
    SELECT s.id INTO v_obj_id
    FROM selemti.sesion_cajon s
    WHERE s.terminal_id = v_terminal_id
      AND s.cajero_usuario_id = NEW.a_user
      AND s.cierre_ts IS NULL
    ORDER BY s.apertura_ts DESC
    LIMIT 1;

    IF v_obj_id IS NOT NULL THEN
      UPDATE selemti.sesion_cajon
         SET cierre_ts = COALESCE(cierre_ts, NEW."time"),
             estatus   = CASE WHEN estatus='ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
       WHERE id = v_obj_id;
    END IF;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();

-- 2.3 Snapshot de cierre (terminal BEFORE UPDATE) — corrige sintaxis
CREATE OR REPLACE FUNCTION selemti.fn_terminal_bu_snapshot_cierre()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_obj_id BIGINT;
BEGIN
  IF OLD.assigned_user IS NOT NULL AND NEW.assigned_user IS NULL THEN
    SELECT s.id INTO v_obj_id
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
             estatus       = CASE WHEN estatus='ACTIVA' THEN 'LISTO_PARA_CORTE' ELSE estatus END
       WHERE id = v_obj_id;

      INSERT INTO selemti.auditoria(quien, que, payload)
      VALUES (OLD.assigned_user, 'SNAPSHOT_CIERRE_TERMINAL',
              jsonb_build_object('terminal_id',OLD.id,'closing_float',OLD.current_balance));
    END IF;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_selemti_terminal_bu_snapshot ON public.terminal;
CREATE TRIGGER trg_selemti_terminal_bu_snapshot
BEFORE UPDATE ON public.terminal
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();

-- 2.4 Refuerzo de cierre en drawer_assigned_history (corrige UPDATE)
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert_refuerzo()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
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

DROP TRIGGER IF EXISTS trg_selemti_dah_ai_refuerzo ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai_refuerzo
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_dah_after_insert_refuerzo();

-- 3) VISTAS (crear/rehacer en orden; ya existe formas_pago)
-- 3.1 Ventas por forma de pago
CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
WITH base AS (
  SELECT
    s.id AS sesion_id,
    t.amount::numeric AS monto,
    COALESCE(
      fp.codigo,
      selemti.fn_normalizar_forma_pago(t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name)
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   AND t.user_id           = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type             = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
)
SELECT sesion_id, codigo_fp, SUM(monto) AS monto
FROM base
GROUP BY sesion_id, codigo_fp;

-- 3.2 Descuentos (placeholder)
CREATE OR REPLACE VIEW selemti.vw_sesion_descuentos AS
SELECT s.id AS sesion_id, 0::numeric AS descuentos
FROM selemti.sesion_cajon s;

-- 3.3 Anulaciones
CREATE OR REPLACE VIEW selemti.vw_sesion_anulaciones AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE WHEN tk.status IN ('VOID','REFUND') THEN tk.total_price ELSE 0 END),0)::numeric AS total_anulado
FROM selemti.sesion_cajon s
LEFT JOIN public.ticket tk
  ON tk.closing_date >= s.apertura_ts
 AND tk.closing_date <  COALESCE(s.cierre_ts, now())
 AND tk.terminal_id   = s.terminal_id
 AND tk.owner_id      = s.cajero_usuario_id
GROUP BY s.id;

-- 3.4 Retiros
CREATE OR REPLACE VIEW selemti.vw_sesion_retiros AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE WHEN t.transaction_type IN ('PAYOUT','EXPENSE') THEN t.amount::numeric ELSE 0 END),0) AS retiros
FROM selemti.sesion_cajon s
JOIN public.transactions t
  ON t.transaction_time >= s.apertura_ts
 AND t.transaction_time <  COALESCE(s.cierre_ts, now())
 AND t.terminal_id       = s.terminal_id
 AND t.user_id           = s.cajero_usuario_id
GROUP BY s.id;

-- 3.5 Reembolsos efectivo
CREATE OR REPLACE VIEW selemti.vw_sesion_reembolsos_efectivo AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE
         WHEN (t.transaction_type IN ('REFUND','RETURN') OR COALESCE(t.voided,false)=true)
          AND (t.payment_type = 'CASH' OR t.transaction_type = 'CASH')
         THEN t.amount::numeric ELSE 0 END),0) AS reembolsos_efectivo
FROM selemti.sesion_cajon s
JOIN public.transactions t
  ON t.transaction_time >= s.apertura_ts
 AND t.transaction_time <  COALESCE(s.cierre_ts, now())
 AND t.terminal_id       = s.terminal_id
 AND t.user_id           = s.cajero_usuario_id
GROUP BY s.id;

-- 3.6 Conciliación final
CREATE OR REPLACE VIEW selemti.vw_conciliacion_sesion AS
WITH ventas AS (
  SELECT
    sesion_id,
    SUM(CASE WHEN codigo_fp = 'CASH' THEN monto ELSE 0 END) AS ventas_efectivo,
    SUM(CASE WHEN codigo_fp IN ('CREDIT','DEBIT','TRANSFER') OR codigo_fp LIKE 'CUSTOM:%'
             THEN monto ELSE 0 END) AS ventas_no_efectivo
  FROM selemti.vw_sesion_veNTAS
  GROUP BY sesion_id
),
decl AS (
  SELECT
    s.id AS sesion_id,
    COALESCE(MAX(p.declarado_efectivo),0)::numeric      AS precorte_efectivo,
    COALESCE(MAX(pc.declarado_efectivo_fin),0)::numeric AS post_efectivo,
    COALESCE(MAX(pc.declarado_tarjetas_fin),0)::numeric AS post_tarjetas
  FROM selemti.sesion_cajon s
  LEFT JOIN selemti.precorte  p  ON p.sesion_id  = s.id
  LEFT JOIN selemti.postcorte pc ON pc.sesion_id = s.id
  GROUP BY s.id
)
SELECT
  s.id                AS sesion_id,
  s.terminal_id,
  s.cajero_usuario_id,
  s.apertura_ts,
  s.cierre_ts,
  s.estatus,

  s.opening_float,
  COALESCE(v.ventas_efectivo,0)      AS sistema_efectivo,
  COALESCE(v.ventas_no_efectivo,0)   AS sistema_no_efectivo,
  COALESCE(dsc.descuentos,0)         AS sistema_descuentos,
  COALESCE(an.total_anulado,0)       AS sistema_anulaciones,
  COALESCE(re.retiros,0)             AS sistema_retiros,
  COALESCE(rc.reembolsos_efectivo,0) AS sistema_reembolsos_efectivo,

  ( s.opening_float
    + COALESCE(v.ventas_efectivo,0)
    - COALESCE(re.retiros,0)
    - COALESCE(rc.reembolsos_efectivo,0)
  ) AS sistema_efectivo_esperado,

  COALESCE(dl.precorte_efectivo,0) AS declarado_precorte_efectivo,
  COALESCE(dl.post_efectivo,0)     AS declarado_post_efectivo,
  COALESCE(dl.post_tarjetas,0)     AS declarado_post_tarjetas,

  (COALESCE(dl.post_efectivo,0)  - ( s.opening_float
                                   + COALESCE(v.ventas_efectivo,0)
                                   - COALESCE(re.retiros,0)
                                   - COALESCE(rc.reembolsos_efectivo,0))) AS diferencia_efectivo,
  (COALESCE(dl.post_tarjetas,0) - COALESCE(v.ventas_no_efectivo,0))        AS diferencia_no_efectivo,

  s.closing_float AS cierre_pos_snapshot,
  COALESCE(s.closing_float,
           ( s.opening_float
             + COALESCE(v.ventas_efectivo,0)
             - COALESCE(re.retiros,0)
             - COALESCE(rc.reembolsos_efectivo,0)
           )) AS cierre_pos_efectivo_final

FROM selemti.sesion_cajon s
LEFT JOIN ventas                           v   ON v.sesion_id   = s.id
LEFT JOIN selemti.vw_sesion_descuentos     dsc ON dsc.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_anulaciones    an  ON an.sesion_id  = s.id
LEFT JOIN selemti.vw_sesion_retiros        re  ON re.sesion_id  = s.id
LEFT JOIN selemti.vw_sesion_reembolsos_efectivo rc ON rc.sesion_id = s.id
LEFT JOIN decl                             dl  ON dl.sesion_id  = s.id;
