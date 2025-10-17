-- ============================================================================
-- SELEMTI v2.0  (PostgreSQL 9.5)
-- Auxiliar de Caja, Precorte, Conciliación con integración a Floreant POS
-- ============================================================================
-- Supone esquema base de Floreant en "public" con:
--   - public.drawer_assigned_history(id, time, operation, a_user)
--   - public.terminal(id, assigned_user, current_balance, name, location, has_cash_drawer, in_use, active, floor_id)
--   - public.transactions(id, terminal_id, user_id, transaction_time, payment_type, transaction_type, payment_sub_type,
--                         custom_payment_name, custom_payment_ref, amount, voided)
--   - public.ticket(id, terminal_id, owner_id, create_date, closing_date, status, total_price)
--   - public.drawer_pull_report(...)  -- resumen de corte POS (opcional)
-- ============================================================================
ALTER TABLE public.drawer_pull_report_voidtickets
ADD COLUMN id SERIAL PRIMARY KEY;
INSERT INTO public.payout_reasons(id, reason_text) VALUES
(100,'Compra de insumos menor'),(200,'Gastos operativos'),(300,'Reposición de caja')
ON CONFLICT DO NOTHING;

INSERT INTO public.void_reasons(id, reason_text) VALUES
(10,'Error de captura'),(20,'Pago mal tipificado'),(30,'Cliente cancela')
ON CONFLICT DO NOTHING;


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='selemti') THEN
    EXECUTE 'CREATE SCHEMA selemti';
  END IF;
END $$;

-- =======================================
-- 0) Auditoría mínima
-- =======================================
CREATE TABLE IF NOT EXISTS selemti.auditoria(
  id         BIGSERIAL PRIMARY KEY,
  quien      INTEGER,
  que        TEXT NOT NULL,
  payload    JSONB,
  creado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =======================================
-- 1) Sesiones de cajón
-- =======================================
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
  dah_evento_id      INTEGER,         -- id del evento de drawer_assigned_history que abrió la sesión
  UNIQUE(terminal_id, cajero_usuario_id, apertura_ts)
);
CREATE INDEX IF NOT EXISTS ix_sesion_cajon_terminal ON selemti.sesion_cajon(terminal_id, apertura_ts);
CREATE INDEX IF NOT EXISTS ix_sesion_cajon_cajero   ON selemti.sesion_cajon(cajero_usuario_id, apertura_ts);

-- =======================================
-- 2) Precorte (encabezado + detalle opcional)
-- =======================================
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

-- Declaración de no-efectivo (TC/TD/TRANSFER/custom)
CREATE TABLE IF NOT EXISTS selemti.precorte_otros(
  id            BIGSERIAL PRIMARY KEY,
  precorte_id   BIGINT NOT NULL REFERENCES selemti.precorte(id) ON DELETE CASCADE,
  tipo          TEXT NOT NULL,     -- 'CREDITO'|'DEBITO'|'TRANSFER'|'CUSTOM:xxx'
  monto         NUMERIC(12,2) NOT NULL DEFAULT 0,
  referencia    TEXT,
  evidencia_url TEXT,
  notas         TEXT,
  creado_en     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_precorte_otros_precorte ON selemti.precorte_otros(precorte_id);

-- =======================================
-- 3) Postcorte (veredicto final por sesión)
-- =======================================
CREATE TABLE IF NOT EXISTS selemti.postcorte(
  id                       BIGSERIAL PRIMARY KEY,
  sesion_id                BIGINT NOT NULL REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE,
  sistema_efectivo_esperado NUMERIC(12,2) NOT NULL DEFAULT 0,
  declarado_efectivo        NUMERIC(12,2) NOT NULL DEFAULT 0,
  diferencia_efectivo       NUMERIC(12,2) NOT NULL DEFAULT 0,
  veredicto_efectivo        TEXT NOT NULL DEFAULT 'CUADRA' CHECK(veredicto_efectivo IN ('CUADRA','A_FAVOR','EN_CONTRA')),
  sistema_tarjetas          NUMERIC(12,2) NOT NULL DEFAULT 0,
  declarado_tarjetas        NUMERIC(12,2) NOT NULL DEFAULT 0,
  diferencia_tarjetas       NUMERIC(12,2) NOT NULL DEFAULT 0,
  veredicto_tarjetas        TEXT NOT NULL DEFAULT 'CUADRA' CHECK(veredicto_tarjetas IN ('CUADRA','A_FAVOR','EN_CONTRA')),
  creado_en                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  creado_por                INTEGER,
  notas                     TEXT
);

-- =======================================
-- 4) Catálogo de formas de pago + normalizador
-- =======================================
CREATE TABLE IF NOT EXISTS selemti.formas_pago(
  id               BIGSERIAL PRIMARY KEY,
  codigo           TEXT NOT NULL,              -- 'CASH','CREDIT','DEBIT','TRANSFER','CUSTOM:xxxxx', etc
  payment_type     TEXT,
  transaction_type TEXT,
  payment_sub_type TEXT,
  custom_name      TEXT,
  custom_ref       TEXT,
  activo           BOOLEAN NOT NULL DEFAULT TRUE,
  prioridad        INTEGER NOT NULL DEFAULT 100,
  creado_en        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice único por “huella” (compatible con 9.5)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_fp_huella_expr') THEN
    EXECUTE '
      CREATE UNIQUE INDEX uq_fp_huella_expr ON selemti.formas_pago
      ( (payment_type), (COALESCE(transaction_type, '''')), (COALESCE(payment_sub_type, '''')),
        (COALESCE(custom_name, '''')), (COALESCE(custom_ref, '''')) )';
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
  p_payment_type TEXT, p_transaction_type TEXT, p_payment_sub_type TEXT, p_custom_name TEXT
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE pt TEXT := upper(coalesce(p_payment_type,''));
DECLARE cn TEXT := selemti.fn_slug(p_custom_name);
BEGIN
  IF pt IN ('CASH','CREDIT','DEBIT','TRANSFER') THEN
    RETURN pt;
  ELSIF pt = 'CUSTOM_PAYMENT' THEN
    IF cn IS NOT NULL THEN RETURN 'CUSTOM:'||cn; ELSE RETURN 'CUSTOM'; END IF;
  ELSE
    RETURN pt;
  END IF;
END $$;

-- Alimentar catálogo con cada transacción nueva
CREATE OR REPLACE FUNCTION selemti.fn_tx_after_insert_forma_pago()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_codigo TEXT;
BEGIN
  v_codigo := selemti.fn_normalizar_forma_pago(
                NEW.payment_type, NEW.transaction_type, NEW.payment_sub_type, NEW.custom_payment_name);
  INSERT INTO selemti.formas_pago(codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref)
  VALUES (v_codigo, NEW.payment_type, NEW.transaction_type, NEW.payment_sub_type, NEW.custom_payment_name, NEW.custom_payment_ref)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_selemti_tx_ai_forma_pago ON public.transactions;
CREATE TRIGGER trg_selemti_tx_ai_forma_pago
AFTER INSERT ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();

-- Semilla básica
INSERT INTO selemti.formas_pago(codigo, payment_type)
VALUES ('CASH','CASH'),('CREDIT','CREDIT'),('DEBIT','DEBIT'),('TRANSFER','TRANSFER')
ON CONFLICT DO NOTHING;

-- =======================================
-- 5) Apertura/cierre automáticos desde Floreant
-- =======================================

-- 5.1 BEFORE UPDATE en public.terminal para snapshot de cierre/apertura
CREATE OR REPLACE FUNCTION selemti.fn_terminal_bu_snapshot_cierre()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_sesion_id BIGINT;
BEGIN
  -- CIERRE: si assigned_user pasa de NOT NULL -> NULL, cerramos sesión previa
  IF (OLD.assigned_user IS NOT NULL AND NEW.assigned_user IS NULL) THEN
    UPDATE selemti.sesion_cajon
      SET cierre_ts = now(),
          estatus = 'LISTO_PARA_CORTE',
          closing_float = COALESCE(OLD.current_balance,0)
    WHERE terminal_id = OLD.id
      AND cajero_usuario_id = OLD.assigned_user
      AND cierre_ts IS NULL;
    PERFORM selemti.auditoria.id FROM selemti.auditoria
    WHERE false; -- no-op para compilar
  END IF;

  -- APERTURA: si assigned_user pasa de NULL -> NOT NULL, abrimos nueva sesión
  IF (OLD.assigned_user IS NULL AND NEW.assigned_user IS NOT NULL) THEN
    INSERT INTO selemti.sesion_cajon(terminal_id, terminal_nombre, sucursal,
                                     cajero_usuario_id, apertura_ts, estatus, opening_float, dah_evento_id)
    VALUES(NEW.id, COALESCE(NEW.name, 'Terminal '||NEW.id), COALESCE(NEW.location,''),
           NEW.assigned_user, now(), 'ACTIVA', COALESCE(NEW.current_balance,0), NULL);
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_selemti_terminal_bu_snapshot ON public.terminal;
CREATE TRIGGER trg_selemti_terminal_bu_snapshot
BEFORE UPDATE ON public.terminal
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();

-- 5.2 AFTER INSERT en drawer_assigned_history para registrar apertura/cierre con rastreabilidad
-- operation = 'ASIGNAR' abre sesión; 'CERRAR' marca cierre con closing_float (de terminal)
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_term RECORD;
BEGIN
  IF NEW.operation = 'ASIGNAR' THEN
    SELECT * INTO v_term FROM public.terminal WHERE assigned_user = NEW.a_user ORDER BY id LIMIT 1;
    IF v_term IS NULL THEN
      INSERT INTO selemti.auditoria(quien,que,payload)
      VALUES(NEW.a_user,'NO_SE_PUDO_RESOLVER_TERMINAL', jsonb_build_object('dah_id',NEW.id,'operation',NEW.operation,'time',NEW.time));
      RETURN NEW;
    END IF;
    INSERT INTO selemti.sesion_cajon(terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
                                     apertura_ts, estatus, opening_float, dah_evento_id)
    VALUES (v_term.id, COALESCE(v_term.name,'Terminal '||v_term.id), COALESCE(v_term.location,''),
            NEW.a_user, COALESCE(NEW.time, now()), 'ACTIVA', COALESCE(v_term.current_balance,0), NEW.id);
  ELSIF NEW.operation = 'CERRAR' THEN
    SELECT * INTO v_term FROM public.terminal WHERE assigned_user = NEW.a_user ORDER BY id LIMIT 1;
    UPDATE selemti.sesion_cajon
      SET cierre_ts     = COALESCE(NEW.time, now()),
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

-- Reparador manual de apertura (por si no se generó)
CREATE OR REPLACE FUNCTION selemti.fn_reparar_sesion_apertura(p_terminal_id INT, p_usuario INT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE v_term RECORD;
BEGIN
  IF EXISTS (SELECT 1 FROM selemti.sesion_cajon
             WHERE terminal_id=p_terminal_id AND cajero_usuario_id=p_usuario AND cierre_ts IS NULL) THEN
    RETURN 'YA_EXISTE_SESION_ABIERTA';
  END IF;
  SELECT * INTO v_term FROM public.terminal WHERE id=p_terminal_id;
  IF v_term IS NULL THEN RETURN 'TERMINAL_NO_ENCONTRADA'; END IF;
  INSERT INTO selemti.sesion_cajon(terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
                                   apertura_ts, estatus, opening_float)
  VALUES (p_terminal_id, COALESCE(v_term.name,'Terminal '||p_terminal_id), COALESCE(v_term.location,''),
          p_usuario, now(), 'ACTIVA', COALESCE(v_term.current_balance,0));
  RETURN 'CREADA';
END $$;

-- =======================================
-- 6) Vistas operativas por sesión
-- =======================================

-- 6.1 Ventas normalizadas por forma de pago
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
    ON fp.payment_type                  = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
)
SELECT sesion_id, codigo_fp, SUM(monto) AS monto
FROM base
GROUP BY sesion_id, codigo_fp;

-- 6.2 Descuentos (si no existen a nivel item, dejamos 0)
CREATE OR REPLACE VIEW selemti.vw_sesion_descuentos AS
SELECT s.id AS sesion_id, 0::numeric AS descuentos
FROM selemti.sesion_cajon s;

-- 6.3 Anulaciones / Refund (ticket.status)
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

-- 6.4 Retiros / Egresos (transactions.transaction_type)
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

-- 6.5 Reembolsos en EFECTIVO (heurística)
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

-- 6.6 (OPCIONAL) Resumen “tira” de Floreant: tomar el ÚLTIMO drawer_pull_report de la ventana
--     Si no hay datos en drawer_pull_report, estos campos quedarán NULL.
--     Columnas confirmadas en el dump de Floreant. :contentReference[oaicite:2]{index=2}
CREATE OR REPLACE VIEW selemti.vw_sesion_dpr AS
WITH ult AS (
  SELECT s.id AS sesion_id, dpr.*
  FROM selemti.sesion_cajon s
  JOIN LATERAL (
    SELECT *
    FROM public.drawer_pull_report r
    WHERE r.terminal_id = s.terminal_id
      AND r.user_id     = s.cajero_usuario_id
      AND r.report_time >= s.apertura_ts
      AND r.report_time <  COALESCE(s.cierre_ts, now())
    ORDER BY r.report_time DESC
    LIMIT 1
  ) dpr ON true
)
SELECT
  sesion_id,
  begin_cash::numeric(12,2)     AS dpr_begin_cash,
  cash_receipt_amount::numeric  AS dpr_cash_receipts,
  credit_card_receipt_amount::numeric AS dpr_credit_amount,
  debit_card_receipt_amount::numeric  AS dpr_debit_amount,
  pay_out_amount::numeric       AS dpr_payout,
  drawer_bleed_amount::numeric  AS dpr_bleed,
  refund_amount::numeric        AS dpr_refunds,
  variance::numeric             AS dpr_variance,
  totalvoid::numeric            AS dpr_total_void,
  totaldiscountamount::numeric  AS dpr_total_discount
FROM ult;

-- 6.7 Vista final de conciliación
CREATE OR REPLACE VIEW selemti.vw_conciliacion_sesion AS
WITH ventas AS (
  SELECT
    sesion_id,
    SUM(CASE WHEN codigo_fp = 'CASH' THEN monto ELSE 0 END) AS ventas_efectivo,
    SUM(CASE WHEN codigo_fp IN ('CREDIT','DEBIT','TRANSFER') OR codigo_fp LIKE 'CUSTOM:%'
             THEN monto ELSE 0 END) AS ventas_no_efectivo
  FROM selemti.vw_sesion_ventas
  GROUP BY sesion_id
),
decl AS (
  SELECT
    p.sesion_id,
    COALESCE(MAX(p.declarado_efectivo),0)::numeric AS precorte_efectivo,
    COALESCE(SUM(CASE WHEN o.tipo='CREDITO'  THEN o.monto ELSE 0 END),0)::numeric AS decl_tc,
    COALESCE(SUM(CASE WHEN o.tipo='DEBITO'   THEN o.monto ELSE 0 END),0)::numeric AS decl_td,
    COALESCE(SUM(CASE WHEN o.tipo='TRANSFER' THEN o.monto ELSE 0 END),0)::numeric AS decl_transfer
  FROM selemti.precorte p
  LEFT JOIN selemti.precorte_otros o ON o.precorte_id = p.id
  GROUP BY p.sesion_id
)
SELECT
  s.id AS sesion_id,
  s.terminal_id, s.terminal_nombre, s.sucursal,
  s.cajero_usuario_id, s.apertura_ts, s.cierre_ts, s.estatus,
  -- Sistema
  COALESCE(s.opening_float,0) AS opening_float,
  COALESCE(v.ventas_efectivo,0)      AS sistema_efectivo,
  COALESCE(v.ventas_no_efectivo,0)   AS sistema_no_efectivo,
  COALESCE(dsc.descuentos,0)         AS sistema_descuentos,
  COALESCE(an.total_anulado,0)       AS sistema_anulaciones,
  COALESCE(reti.retiros,0)           AS sistema_retiros,
  COALESCE(reem.reembolsos_efectivo,0) AS sistema_reembolsos_efectivo,
  ( COALESCE(s.opening_float,0) + COALESCE(v.ventas_efectivo,0)
    - COALESCE(reti.retiros,0) - COALESCE(reem.reembolsos_efectivo,0)
  )::numeric(12,2) AS sistema_efectivo_esperado,
  -- Declarados (precorte)
  COALESCE(d.precorte_efectivo,0) AS declarado_precorte_efectivo,
  (COALESCE(d.decl_tc,0)+COALESCE(d.decl_td,0)+COALESCE(d.decl_transfer,0))::numeric(12,2) AS declarado_precorte_tarjetas,
  -- Snapshot POS (si existe) y cierre final preferente
  s.closing_float AS cierre_pos_snapshot,
  COALESCE(s.closing_float,
           ( COALESCE(s.opening_float,0) + COALESCE(v.ventas_efectivo,0)
             - COALESCE(reti.retiros,0) - COALESCE(reem.reembolsos_efectivo,0)
           ))::numeric(12,2) AS cierre_pos_efectivo_final,
  -- DPR (tira POS) opcional
  dpr.dpr_begin_cash, dpr.dpr_cash_receipts, dpr.dpr_credit_amount, dpr.dpr_debit_amount,
  dpr.dpr_payout, dpr.dpr_bleed, dpr.dpr_refunds, dpr.dpr_variance, dpr.dpr_total_void, dpr.dpr_total_discount,
  -- Dif y veredictos
  (COALESCE(d.precorte_efectivo,0) - (COALESCE(s.opening_float,0) + COALESCE(v.ventas_efectivo,0)
   - COALESCE(reti.retiros,0) - COALESCE(reem.reembolsos_efectivo,0)))::numeric(12,2) AS diferencia_efectivo,
  CASE
    WHEN COALESCE(d.precorte_efectivo,0) = (COALESCE(s.opening_float,0) + COALESCE(v.ventas_efectivo,0)
      - COALESCE(reti.retiros,0) - COALESCE(reem.reembolsos_efectivo,0)) THEN 'CUADRA'
    WHEN COALESCE(d.precorte_efectivo,0) > (COALESCE(s.opening_float,0) + COALESCE(v.ventas_efectivo,0)
      - COALESCE(reti.retiros,0) - COALESCE(reem.reembolsos_efectivo,0)) THEN 'A_FAVOR'
    ELSE 'EN_CONTRA'
  END AS veredicto_efectivo,
  ((COALESCE(d.decl_tc,0)+COALESCE(d.decl_td,0)+COALESCE(d.decl_transfer,0)) - COALESCE(v.ventas_no_efectivo,0))::numeric(12,2) AS diferencia_tarjetas,
  CASE
    WHEN (COALESCE(d.decl_tc,0)+COALESCE(d.decl_td,0)+COALESCE(d.decl_transfer,0)) = COALESCE(v.ventas_no_efectivo,0) THEN 'CUADRA'
    WHEN (COALESCE(d.decl_tc,0)+COALESCE(d.decl_td,0)+COALESCE(d.decl_transfer,0)) > COALESCE(v.ventas_no_efectivo,0) THEN 'A_FAVOR'
    ELSE 'EN_CONTRA'
  END AS veredicto_tarjetas
FROM selemti.sesion_cajon s
LEFT JOIN ventas                          v   ON v.sesion_id   = s.id
LEFT JOIN selemti.vw_sesion_descuentos    dsc ON dsc.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_anulaciones   an  ON an.sesion_id  = s.id
LEFT JOIN selemti.vw_sesion_retiros       reti ON reti.sesion_id= s.id
LEFT JOIN selemti.vw_sesion_reembolsos_efectivo reem ON reem.sesion_id = s.id
LEFT JOIN decl                            d   ON d.sesion_id   = s.id
LEFT JOIN selemti.vw_sesion_dpr           dpr ON dpr.sesion_id = s.id;

-- =======================================
-- 7) Índices recomendados en POS
-- =======================================
DO $ix$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='ix_transactions_ts_term_user') THEN
    EXECUTE 'CREATE INDEX ix_transactions_ts_term_user ON public.transactions (transaction_time, terminal_id, user_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='ix_ticket_closing_term_owner') THEN
    EXECUTE 'CREATE INDEX ix_ticket_closing_term_owner ON public.ticket (closing_date, terminal_id, owner_id)';
  END IF;
END
$ix$;

-- ============================================================================
-- FIN DEL DESPLIEGUE
-- ============================================================================
-- ================================================
-- SELEMTI v2.1 – Parche de compatibilidad (PG 9.5)
-- Alineado al dump_21_08_2025_Con_Query.sql
-- ================================================

-- 1) Índices prácticos (aceleran precorte/conciliación)
--    - transactions por ventana de turno y filtros típicos
--    - drawer_assigned_history por usuario/operación/tiempo
--    - ticket por cierre/terminal/cajero

CREATE INDEX IF NOT EXISTS idx_tx_term_user_time
  ON public.transactions (terminal_id, user_id, transaction_time);

CREATE INDEX IF NOT EXISTS idx_dah_user_op_time
  ON public.drawer_assigned_history (a_user, operation, "time" DESC);

CREATE INDEX IF NOT EXISTS idx_ticket_close_term_owner
  ON public.ticket (closing_date, terminal_id, owner_id);

-- 2) Ventana de asignación: compatible con tu drawer_assigned_history real
--    (en tu BD "drawer_assigned_history" no trae terminal_id; anclamos por usuario)
CREATE OR REPLACE FUNCTION public._last_assign_window(
    _terminal_id integer,  -- firma estable
    _user_id     integer,
    _ref_time    timestamptz
) RETURNS TABLE (from_ts timestamptz, to_ts timestamptz)
LANGUAGE sql STABLE AS $$
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

-- 3) Helpers de normalización (opcional, por si no estaban)
--    Nota: si ya existen en tu V2, esto sólo hace REPLACE sin romper nada.
CREATE SCHEMA IF NOT EXISTS selemti;

CREATE TABLE IF NOT EXISTS selemti.auditoria(
  id BIGSERIAL PRIMARY KEY,
  quien INTEGER,
  que TEXT NOT NULL,
  payload JSONB,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4) Smoke views (opcionales) para validar sin tocar lógica
CREATE OR REPLACE VIEW selemti.vw_fast_tx AS
SELECT t.terminal_id, t.user_id, t.transaction_time, t.payment_type, t.transaction_type,
       t.payment_sub_type, t.custom_payment_name, t.custom_payment_ref, t.amount, t.voided
FROM public.transactions t;

CREATE OR REPLACE VIEW selemti.vw_fast_tickets AS
SELECT tk.id, tk.terminal_id, tk.owner_id, tk.create_date, tk.closing_date,
       tk.status, tk.total_discount, tk.total_price
FROM public.ticket tk;


--- Query para vistas 
CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
WITH tx AS (
  SELECT
    s.id AS sesion_id,
    t.amount::numeric AS monto,
    COALESCE(
      fp.codigo,
      selemti.fn_normalizar_forma_pago(
        t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name
      )
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   -- 🔎 SIN filtro por usuario (t.user_id)
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type                  = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
  WHERE COALESCE(t.voided,false) = false
    AND UPPER(COALESCE(t.transaction_type,'')) NOT IN ('VOID','REFUND','RETURN')
)
SELECT sesion_id, codigo_fp, SUM(monto)::numeric(12,2) AS monto
FROM tx
GROUP BY sesion_id, codigo_fp;

ALTER TABLE selemti.vw_sesion_ventas OWNER TO postgres;

-------------------------------
--------------------------
-- =========================================================
-- 1) Columnas para TRANSFERENCIAS (compatibles con PG 9.5)
-- =========================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='sistema_transferencias'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN sistema_transferencias numeric(12,2) NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='declarado_transferencias'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN declarado_transferencias numeric(12,2) NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='diferencia_transferencias'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN diferencia_transferencias numeric(12,2) NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='veredicto_transferencias'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN veredicto_transferencias text NOT NULL DEFAULT 'CUADRA';
  END IF;
END
$$;

-- constraint del veredicto de transferencias (solo si falta)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t   ON c.conrelid = t.oid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname='selemti' AND t.relname='postcorte'
      AND c.conname='postcorte_veredicto_transfer_check'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD CONSTRAINT postcorte_veredicto_transfer_check
      CHECK (veredicto_transferencias IN ('CUADRA','A_FAVOR','EN_CONTRA'));
  END IF;
END
$$;

-- =========================================================
-- 2) Campos de VALIDACIÓN por supervisor (PG 9.5)
-- =========================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='validado'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN validado boolean NOT NULL DEFAULT FALSE;
    COMMENT ON COLUMN selemti.postcorte.validado
      IS 'TRUE cuando el supervisor valida/cierra el postcorte';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='validado_por'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN validado_por integer;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='validado_en'
  ) THEN
    ALTER TABLE selemti.postcorte
      ADD COLUMN validado_en timestamptz;
  END IF;
END
$$;







-----

CREATE OR REPLACE VIEW selemti.vw_sesion_dpr AS 
WITH s AS (
  SELECT
    sesion_cajon.id,
    sesion_cajon.terminal_id,
    sesion_cajon.cajero_usuario_id,
    sesion_cajon.apertura_ts,
    COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts
  FROM selemti.sesion_cajon
)
SELECT
  s.id AS sesion_id,
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
FROM s
JOIN public.drawer_pull_report dpr
  ON dpr.terminal_id = s.terminal_id
 -- 🔴 quitamos el filtro por usuario:
 -- AND dpr.user_id = s.cajero_usuario_id
 AND dpr.report_time >= s.apertura_ts
 AND dpr.report_time <  s.fin_ts;

ALTER TABLE selemti.vw_sesion_dpr OWNER TO postgres;

-------------
CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS 
WITH base AS (
  SELECT
    s.id AS sesion_id,
    t.amount::numeric AS monto,
    COALESCE(
      fp.codigo,
      selemti.fn_normalizar_forma_pago(
        t.payment_type::text,
        t.transaction_type::text,
        t.payment_sub_type::text,
        t.custom_payment_name::text
      )
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   -- 🔴 quitamos el filtro por usuario:
   -- AND t.user_id = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type                  = t.payment_type::text
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')::text
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')::text
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')::text
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')::text
  WHERE COALESCE(t.voided,false) = false
    AND t.transaction_type::text = 'CREDIT'::text
)
SELECT
  base.sesion_id,
  base.codigo_fp,
  SUM(base.monto)::numeric(12,2) AS monto
FROM base
GROUP BY base.sesion_id, base.codigo_fp;

ALTER TABLE selemti.vw_sesion_ventas OWNER TO postgres;
-- 1) Nota general del precorte
DO $$
BEGIN
  -- selemti.precorte.notas
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'selemti' AND table_name = 'precorte'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'selemti' AND table_name = 'precorte' AND column_name = 'notas'
    ) THEN
      ALTER TABLE selemti.precorte ADD COLUMN notas text;
    END IF;
  END IF;

  -- selemti.precorte_otros.notas (solo si la tabla existe)
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'selemti' AND table_name = 'precorte_otros'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'selemti' AND table_name = 'precorte_otros' AND column_name = 'notas'
    ) THEN
      ALTER TABLE selemti.precorte_otros ADD COLUMN notas text;
    END IF;
  END IF;
END
$$ LANGUAGE plpgsql;