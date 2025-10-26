-- ============================================================================
-- SELEMTI v2.1  (PostgreSQL 9.5)
-- Auxiliar de Caja / Precorte / Conciliación para Floreant POS
-- Alineado a tu dump_21_08_2025_Con_Query.sql
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='selemti') THEN
    EXECUTE 'CREATE SCHEMA selemti';
  END IF;
END $$;

-- 0) Auditoría mínima ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS selemti.auditoria(
  id         BIGSERIAL PRIMARY KEY,
  quien      INTEGER,
  que        TEXT NOT NULL,
  payload    JSONB,
  creado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1) Sesiones de cajón --------------------------------------------------------
CREATE TABLE IF NOT EXISTS selemti.sesion_cajon(
  id                 BIGSERIAL PRIMARY KEY,
  sucursal           TEXT,
  terminal_id        INTEGER NOT NULL,
  terminal_nombre    TEXT,
  cajero_usuario_id  INTEGER NOT NULL,
  apertura_ts        TIMESTAMPTZ NOT NULL DEFAULT now(),
  cierre_ts          TIMESTAMPTZ,
  estatus            TEXT NOT NULL DEFAULT 'ACTIVA' CHECK(estatus IN ('ACTIVA','LISTO_PARA_CORTE','CERRADA')),
  opening_float      NUMERIC(12,2) NOT NULL DEFAULT 0,
  closing_float      NUMERIC(12,2),
  dah_evento_id      INTEGER,
  UNIQUE(terminal_id, cajero_usuario_id, apertura_ts)
);
CREATE INDEX IF NOT EXISTS ix_sesion_cajon_terminal ON selemti.sesion_cajon(terminal_id, apertura_ts);
CREATE INDEX IF NOT EXISTS ix_sesion_cajon_cajero   ON selemti.sesion_cajon(cajero_usuario_id, apertura_ts);

-- 2) Precorte -----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS selemti.precorte(
  id                 BIGSERIAL PRIMARY KEY,
  sesion_id          BIGINT NOT NULL REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE,
  declarado_efectivo NUMERIC(12,2) NOT NULL DEFAULT 0,
  declarado_otros    NUMERIC(12,2) NOT NULL DEFAULT 0,
  estatus            TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK(estatus IN ('PENDIENTE','ENVIADO','APROBADO','RECHAZADO')),
  creado_en          TIMESTAMPTZ NOT NULL DEFAULT now(),
  creado_por         INTEGER,
  ip_cliente         INET
);

CREATE TABLE IF NOT EXISTS selemti.precorte_efectivo(
  id            BIGSERIAL PRIMARY KEY,
  precorte_id   BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
  denominacion  NUMERIC(12,2) NOT NULL,
  cantidad      INTEGER NOT NULL,
  subtotal      NUMERIC(12,2) NOT NULL DEFAULT 0
);
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

CREATE TABLE IF NOT EXISTS selemti.precorte_otros(
  id            BIGSERIAL PRIMARY KEY,
  precorte_id   BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
  tipo          TEXT NOT NULL, -- 'CREDITO'|'DEBITO'|'TRANSFER'|'GIFT_CERT'|'CUSTOM:xxx'
  monto         NUMERIC(12,2) NOT NULL DEFAULT 0,
  referencia    TEXT,
  evidencia_url TEXT,
  notas         TEXT,
  creado_en     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_precorte_otros_precorte ON selemti.precorte_otros(precorte_id);

-- 3) Postcorte ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS selemti.postcorte(
  id                         BIGSERIAL PRIMARY KEY,
  sesion_id                  BIGINT NOT NULL REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE,
  sistema_efectivo_esperado  NUMERIC(12,2) NOT NULL DEFAULT 0,
  declarado_efectivo         NUMERIC(12,2) NOT NULL DEFAULT 0,
  diferencia_efectivo        NUMERIC(12,2) NOT NULL DEFAULT 0,
  veredicto_efectivo         TEXT NOT NULL DEFAULT 'CUADRA' CHECK(veredicto_efectivo IN ('CUADRA','A_FAVOR','EN_CONTRA')),
  sistema_tarjetas           NUMERIC(12,2) NOT NULL DEFAULT 0,
  declarado_tarjetas         NUMERIC(12,2) NOT NULL DEFAULT 0,
  diferencia_tarjetas        NUMERIC(12,2) NOT NULL DEFAULT 0,
  veredicto_tarjetas         TEXT NOT NULL DEFAULT 'CUADRA' CHECK(veredicto_tarjetas IN ('CUADRA','A_FAVOR','EN_CONTRA')),
  creado_en                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  creado_por                 INTEGER,
  notas                      TEXT
);

-- 4) Catálogo y normalizador de formas de pago --------------------------------
CREATE TABLE IF NOT EXISTS selemti.formas_pago(
  id               BIGSERIAL PRIMARY KEY,
  codigo           TEXT NOT NULL,
  payment_type     TEXT,
  transaction_type TEXT,
  payment_sub_type TEXT,
  custom_name      TEXT,
  custom_ref       TEXT,
  activo           BOOLEAN NOT NULL DEFAULT TRUE,
  prioridad        INTEGER NOT NULL DEFAULT 100,
  creado_en        TIMESTAMPTZ NOT NULL DEFAULT now()
);
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_fp_huella_expr') THEN
    EXECUTE '
      CREATE UNIQUE INDEX uq_fp_huella_expr ON selemti.formas_pago (
        (payment_type),
        (COALESCE(transaction_type, '''')),
        (COALESCE(payment_sub_type, '''')),
        (COALESCE(custom_name, '''')),
        (COALESCE(custom_ref, ''''))
      )';
  END IF;
END $$;

CREATE OR REPLACE FUNCTION selemti.fn_slug(in_text TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE s TEXT := lower(coalesce(in_text,''));
BEGIN
  s := translate(s, 'ÁÉÍÓÚÜÑáéíóúüñ', 'AEIOUUNaeiouun');
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
    IF cn IS NOT NULL THEN RETURN 'CUSTOM:'||cn; ELSE RETURN 'CUSTOM'; END IF;
  ELSIF pt IN ('REFUND','PAY_OUT','CASH_DROP') THEN
    RETURN pt; -- egresos/ajustes estandarizados
  ELSE
    RETURN pt;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION selemti.fn_tx_after_insert_forma_pago()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
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

DROP TRIGGER IF EXISTS trg_selemti_tx_ai_forma_pago ON public.transactions;
CREATE TRIGGER trg_selemti_tx_ai_forma_pago
AFTER INSERT ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();

INSERT INTO selemti.formas_pago(codigo, payment_type) VALUES
  ('CASH','CASH'),('CREDIT','CREDIT'),('DEBIT','DEBIT'),('TRANSFER','TRANSFER'),
  ('REFUND','REFUND'),('PAY_OUT','PAY_OUT'),('CASH_DROP','CASH_DROP')
ON CONFLICT DO NOTHING;

-- 5) Hooks con Floreant (terminal + asignaciones) -----------------------------
-- 1) Crear columna solo si no existe (compatible con versiones viejas)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name   = 'sesion_cajon'
      AND column_name  = 'skipped_precorte'
  ) THEN
    ALTER TABLE selemti.sesion_cajon
      ADD COLUMN skipped_precorte boolean DEFAULT false NOT NULL;
    COMMENT ON COLUMN selemti.sesion_cajon.skipped_precorte
      IS 'TRUE si se cerró la sesión/corte sin tener un precorte (conteo) previo.';
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_precorte_sesion_id
  ON selemti.precorte (sesion_id);
ALTER TABLE selemti.postcorte
ADD COLUMN validado boolean DEFAULT FALSE;
ALTER TABLE selemti.postcorte
ADD COLUMN validado_en timestamp without time zone;
ALTER TABLE selemti.postcorte
ADD COLUMN validado_por integer;


ALTER TABLE selemti.postcorte
ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);
DO $$
BEGIN
  ALTER TABLE selemti.precorte ADD COLUMN notas text;
EXCEPTION WHEN duplicate_column THEN
  -- ya existía, no hacer nada
  NULL;
END$$;

CREATE INDEX IF NOT EXISTS idx_precorte_sesion_id
  ON selemti.precorte (sesion_id);


ALTER TABLE selemti.postcorte
ADD CONSTRAINT uq_postcorte_sesion_id UNIQUE (sesion_id);


CREATE OR REPLACE FUNCTION selemti.fn_terminal_bu_snapshot_cierre()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_has_old boolean := (OLD.assigned_user IS NOT NULL);
DECLARE v_has_new boolean := (NEW.assigned_user IS NOT NULL);
BEGIN
  IF (v_has_old AND NOT v_has_new) THEN
    UPDATE selemti.sesion_cajon
      SET cierre_ts = now(),
          estatus   = 'LISTO_PARA_CORTE',
          closing_float = COALESCE(OLD.current_balance,0)
    WHERE terminal_id = OLD.id
      AND cajero_usuario_id = OLD.assigned_user
      AND cierre_ts IS NULL;
  END IF;

  IF (NOT v_has_old AND v_has_new) THEN
    INSERT INTO selemti.sesion_cajon(
      terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
      apertura_ts, estatus, opening_float, dah_evento_id
    )
    VALUES(
      NEW.id, COALESCE(NEW.name, 'Terminal '||NEW.id), COALESCE(NEW.location,''),
      NEW.assigned_user, now(), 'ACTIVA', COALESCE(NEW.current_balance,0), NULL
    );
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_selemti_terminal_bu_snapshot ON public.terminal;
CREATE TRIGGER trg_selemti_terminal_bu_snapshot
BEFORE UPDATE ON public.terminal
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();

-- Asegurar índice útil para la historia de asignaciones (columnas reales)
CREATE INDEX IF NOT EXISTS idx_drawer_assigned_history_user_time
  ON public.drawer_assigned_history (a_user, "time");

CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
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
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert();

CREATE OR REPLACE FUNCTION selemti.fn_reparar_sesion_apertura(p_terminal_id INT, p_usuario INT)
RETURNS TEXT LANGUAGE plpgsql AS $$
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

-- 6) Vistas operativas por sesión --------------------------------------------

-- 6.1 Ventas válidas por forma de pago (solo cobros: transaction_type='CREDIT', no void)
CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
WITH base AS (
  SELECT
    s.id AS sesion_id,
    t.amount::numeric AS monto,
    COALESCE( fp.codigo,
      selemti.fn_normalizar_forma_pago(t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name)
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   AND t.user_id           = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type                  = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
  WHERE COALESCE(t.voided,false)=false
    AND t.transaction_type = 'CREDIT'
)
SELECT sesion_id, codigo_fp, SUM(monto)::numeric(12,2) AS monto
FROM base
GROUP BY sesion_id, codigo_fp;

-- 6.2 Descuentos reales (ticket + ítem) en la ventana de la sesión
CREATE OR REPLACE VIEW selemti.vw_sesion_descuentos AS
WITH tk_win AS (
  SELECT s.id AS sesion_id, tk.id AS ticket_id
  FROM selemti.sesion_cajon s
  JOIN public.ticket tk
    ON tk.terminal_id = s.terminal_id
   AND tk.owner_id    = s.cajero_usuario_id
   AND tk.create_date >= s.apertura_ts
   AND tk.create_date <  COALESCE(s.cierre_ts, now())
),
td_agg AS ( -- descuentos al ticket (columna 'value')
  SELECT td.ticket_id, SUM(COALESCE(td.value,0))::numeric AS sum_td
  FROM public.ticket_discount td
  GROUP BY td.ticket_id
),
tid_agg AS ( -- descuentos por ítem (columna 'amount')
  SELECT ti.ticket_id, SUM(COALESCE(tid.amount,0))::numeric AS sum_tid
  FROM public.ticket_item_discount tid
  JOIN public.ticket_item ti ON ti.id = tid.ticket_itemid
  GROUP BY ti.ticket_id
)
SELECT tw.sesion_id,
       COALESCE(SUM(td_agg.sum_td),0)::numeric + COALESCE(SUM(tid_agg.sum_tid),0)::numeric AS descuentos
FROM tk_win tw
LEFT JOIN td_agg  ON td_agg.ticket_id  = tw.ticket_id
LEFT JOIN tid_agg ON tid_agg.ticket_id = tw.ticket_id
GROUP BY tw.sesion_id;

-- 6.3 Retiros / Bleed (egresos de caja): PAY_OUT + CASH_DROP
CREATE OR REPLACE VIEW selemti.vw_sesion_retiros AS
WITH tx AS (
  SELECT
    s.id AS sesion_id,
    COALESCE( fp.codigo,
      selemti.fn_normalizar_forma_pago(t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name)
    ) AS codigo_fp,
    t.amount::numeric AS monto
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   AND t.user_id           = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type                  = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
)
SELECT sesion_id,
       SUM(CASE WHEN codigo_fp IN ('PAY_OUT','CASH_DROP') THEN monto ELSE 0 END)::numeric(12,2) AS retiros
FROM tx
GROUP BY sesion_id;

-- 6.4 Reembolsos en EFECTIVO (REFUND cuyo sub-tipo sea CASH)
CREATE OR REPLACE VIEW selemti.vw_sesion_reembolsos_efectivo AS
WITH tx AS (
  SELECT
    s.id AS sesion_id,
    t.payment_sub_type,
    COALESCE( fp.codigo,
      selemti.fn_normalizar_forma_pago(t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name)
    ) AS codigo_fp,
    t.amount::numeric AS monto
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   AND t.user_id           = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type                  = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
)
SELECT sesion_id,
       SUM(CASE WHEN codigo_fp='REFUND' AND UPPER(COALESCE(payment_sub_type,''))='CASH'
                THEN monto ELSE 0 END)::numeric(12,2) AS reembolsos_efectivo
FROM tx
GROUP BY sesion_id;

-- 6.5 DPR por sesión (oficial Floreant, si cae en la ventana)
CREATE OR REPLACE VIEW selemti.vw_sesion_dpr AS
WITH s AS (
  SELECT id, terminal_id, cajero_usuario_id, apertura_ts, COALESCE(cierre_ts, now()) AS fin_ts
  FROM selemti.sesion_cajon
)
SELECT
  s.id AS sesion_id,
  dpr.*
FROM s
JOIN public.drawer_pull_report dpr
  ON dpr.terminal_id = s.terminal_id
 AND dpr.user_id     = s.cajero_usuario_id
 AND dpr.report_time >= s.apertura_ts
 AND dpr.report_time <  s.fin_ts;

-- 7) Vista final: Conciliación por sesión -------------------------------------
CREATE OR REPLACE VIEW selemti.vw_conciliacion_sesion AS
WITH sys AS (
  SELECT
    s.id AS sesion_id,
    s.opening_float,
    SUM(CASE WHEN v.codigo_fp='CASH'                 THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_cash,
    SUM(CASE WHEN v.codigo_fp IN ('CREDIT','CREDIT_CARD') THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_credito,
    SUM(CASE WHEN v.codigo_fp IN ('DEBIT','DEBIT_CARD')   THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_debito,
    SUM(CASE WHEN v.codigo_fp LIKE 'CUSTOM:%'        THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_custom,
    SUM(CASE WHEN v.codigo_fp='TRANSFER'             THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_transfer,
    SUM(CASE WHEN v.codigo_fp='GIFT_CERT'            THEN v.monto ELSE 0 END)::numeric(12,2) AS sys_gift
  FROM selemti.sesion_cajon s
  LEFT JOIN selemti.vw_sesion_ventas v ON v.sesion_id = s.id
  GROUP BY s.id, s.opening_float
),
re AS (
  SELECT sesion_id, retiros FROM selemti.vw_sesion_retiros
),
cr AS (
  SELECT sesion_id, reembolsos_efectivo FROM selemti.vw_sesion_reembolsos_efectivo
),
ds AS (
  SELECT sesion_id, descuentos FROM selemti.vw_sesion_descuentos
),
decl_cash AS ( -- último precorte por sesión (efectivo contado)
  SELECT p.sesion_id, SUM(pe.subtotal)::numeric(12,2) AS declarado_efectivo
  FROM selemti.precorte p
  LEFT JOIN selemti.precorte_efectivo pe ON pe.precorte_id = p.id
  GROUP BY p.sesion_id
),
decl_otros AS ( -- declarados no-efectivo por tipo
  SELECT
    p.sesion_id,
    SUM(CASE WHEN po.tipo='CREDITO'            THEN po.monto ELSE 0 END)::numeric(12,2) AS decl_credito,
    SUM(CASE WHEN po.tipo='DEBITO'             THEN po.monto ELSE 0 END)::numeric(12,2) AS decl_debito,
    SUM(CASE WHEN po.tipo IN ('TRANSFER')      THEN po.monto ELSE 0 END)::numeric(12,2) AS decl_transfer,
    SUM(CASE WHEN po.tipo LIKE 'CUSTOM:%'      THEN po.monto ELSE 0 END)::numeric(12,2) AS decl_custom,
    SUM(CASE WHEN po.tipo='GIFT_CERT'          THEN po.monto ELSE 0 END)::numeric(12,2) AS decl_gift
  FROM selemti.precorte p
  LEFT JOIN selemti.precorte_otros po ON po.precorte_id = p.id
  GROUP BY p.sesion_id
),
eff AS (
  SELECT
    sys.sesion_id,
    sys.opening_float,
    COALESCE(sys.sys_cash,0)           AS cash_in,
    COALESCE(re.retiros,0)             AS cash_out,
    COALESCE(cr.reembolsos_efectivo,0) AS cash_refund,
    (sys.opening_float + COALESCE(sys.sys_cash,0) - COALESCE(re.retiros,0) - COALESCE(cr.reembolsos_efectivo,0))::numeric(12,2)
      AS sistema_efectivo_esperado
  FROM sys
  LEFT JOIN re ON re.sesion_id = sys.sesion_id
  LEFT JOIN cr ON cr.sesion_id = sys.sesion_id
),
tc AS (
  SELECT
    sys.sesion_id,
    (COALESCE(sys.sys_credito,0)+COALESCE(sys.sys_debito,0)+COALESCE(sys.sys_transfer,0)+COALESCE(sys.sys_custom,0)+COALESCE(sys.sys_gift,0))::numeric(12,2)
      AS sistema_no_efectivo
  FROM sys
)
SELECT
  sys.sesion_id,

  -- EFECTIVO
  eff.sistema_efectivo_esperado,
  COALESCE(dc.declarado_efectivo,0)::numeric(12,2) AS declarado_efectivo,
  (COALESCE(dc.declarado_efectivo,0) - eff.sistema_efectivo_esperado)::numeric(12,2) AS diferencia_efectivo,
  CASE
    WHEN COALESCE(dc.declarado_efectivo,0) = eff.sistema_efectivo_esperado THEN 'CUADRA'
    WHEN COALESCE(dc.declarado_efectivo,0) > eff.sistema_efectivo_esperado THEN 'A_FAVOR'
    ELSE 'EN_CONTRA'
  END AS veredicto_efectivo,

  -- SISTEMA – NO EFECTIVO (desglose) y DECLARADOS
  sys.sys_credito, sys.sys_debito, sys.sys_transfer, sys.sys_custom, sys.sys_gift,
  dotros.decl_credito, dotros.decl_debito, dotros.decl_transfer, dotros.decl_custom, dotros.decl_gift,
  tc.sistema_no_efectivo,

  -- Descuentos calculados (BD) y DPR oficial (si existe en ventana)
  ds.descuentos AS total_descuentos,
  dpr.begin_cash, dpr.cash_receipt_amount, dpr.credit_card_receipt_amount, dpr.debit_card_receipt_amount,
  dpr.pay_out_amount, dpr.drawer_bleed_amount, dpr.refund_amount, dpr.totaldiscountamount, dpr.totalvoid,
  dpr.drawer_accountable, dpr.cash_to_deposit, dpr.variance, dpr.report_time

FROM sys
LEFT JOIN eff        ON eff.sesion_id = sys.sesion_id
LEFT JOIN decl_cash  dc  ON dc.sesion_id  = sys.sesion_id
LEFT JOIN decl_otros dotros ON dotros.sesion_id = sys.sesion_id
LEFT JOIN tc         ON tc.sesion_id     = sys.sesion_id
LEFT JOIN ds         ON ds.sesion_id     = sys.sesion_id
LEFT JOIN selemti.vw_sesion_dpr dpr ON dpr.sesion_id = sys.sesion_id
ORDER BY sys.sesion_id DESC;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name   = 'sesion_cajon'
      AND column_name  = 'skipped_precorte'
  ) THEN
    ALTER TABLE selemti.sesion_cajon
      ADD COLUMN skipped_precorte boolean NOT NULL DEFAULT FALSE;
  END IF;
END $$;


CREATE INDEX IF NOT EXISTS precorte_sesion_id_idx
