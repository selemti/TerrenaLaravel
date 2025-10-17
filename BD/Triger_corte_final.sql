-- ===========================================
--  SELEM POS — Despliegue auxiliar (v0.1)
--  Compatibilidad: PostgreSQL 9.5+
--  Objetivo: conciliación por sesión de cajón
--  Autor: Tavo+ChatGPT
-- ===========================================

-- ===========================================
-- 0) DIAGNÓSTICO (opcional pero recomendado)
--    Esto NO crea objetos; imprime cómo se llaman
--    las columnas relevantes para alinear mapeos.
-- ===========================================
DO $diag$
DECLARE
  tx_time_col TEXT;
  tx_amt_col  TEXT;
  tx_pay_col  TEXT;
  tx_type_col TEXT;
  tk_close_col TEXT;
  dah_assign_col TEXT;
  dah_release_col TEXT;
  term_balance_col TEXT;
BEGIN
  RAISE NOTICE '=== DIAGNÓSTICO DE ESQUEMA (transactions) ===';
  SELECT column_name INTO tx_time_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('tx_time','transaction_time','created','date','time','paid_time')
   ORDER BY CASE column_name
              WHEN 'tx_time' THEN 1
              WHEN 'transaction_time' THEN 2
              WHEN 'created' THEN 3
              WHEN 'date' THEN 4
              WHEN 'time' THEN 5
              WHEN 'paid_time' THEN 6
            END
   LIMIT 1;
  SELECT column_name INTO tx_amt_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('amount','total','value','amt')
   LIMIT 1;
  SELECT column_name INTO tx_pay_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('payment_type','tender_type','pay_type','method','payment_code')
   LIMIT 1;
  SELECT column_name INTO tx_type_col
    FROM information_schema.columns
   WHERE table_name='transactions'
     AND column_name IN ('transaction_type','type','txn_type')
   LIMIT 1;

  RAISE NOTICE 'transactions: tiempo=% , monto=% , payment=% , txn_type=%',
               COALESCE(tx_time_col,'(NO ENCONTRADO)'),
               COALESCE(tx_amt_col,'(NO ENCONTRADO)'),
               COALESCE(tx_pay_col,'(NO ENCONTRADO)'),
               COALESCE(tx_type_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÓSTICO DE ESQUEMA (ticket) ===';
  SELECT column_name INTO tk_close_col
    FROM information_schema.columns
   WHERE table_name='ticket'
     AND column_name IN ('closed_time','close_time','paid_time','modified_time','update_time')
   LIMIT 1;
  RAISE NOTICE 'ticket: closed_time=%', COALESCE(tk_close_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÓSTICO DE ESQUEMA (drawer_assigned_history) ===';
  SELECT column_name INTO dah_assign_col
    FROM information_schema.columns
   WHERE table_name='drawer_assigned_history'
     AND column_name IN ('assigned_time','assigned_at','created','start_time')
   LIMIT 1;
  SELECT column_name INTO dah_release_col
    FROM information_schema.columns
   WHERE table_name='drawer_assigned_history'
     AND column_name IN ('released_time','released_at','end_time','closed')
   LIMIT 1;
  RAISE NOTICE 'drawer_assigned_history: assigned=% , released=%',
               COALESCE(dah_assign_col,'(NO ENCONTRADO)'),
               COALESCE(dah_release_col,'(NO ENCONTRADO)');

  RAISE NOTICE '=== DIAGNÓSTICO DE ESQUEMA (terminal) ===';
  SELECT column_name INTO term_balance_col
    FROM information_schema.columns
   WHERE table_name='terminal'
     AND column_name IN ('current_balance','opening_balance','balance')
   LIMIT 1;
  RAISE NOTICE 'terminal: current_balance=%', COALESCE(term_balance_col,'(NO ENCONTRADO)');
END
$diag$;

-- ===========================================
-- 1) PARÁMETROS (ajusta SOLO si tu esquema difiere)
--    Si el diagnóstico anterior te dio otros nombres,
--    cámbialos aquí para que todo funcione.
-- ===========================================
DO $params$
BEGIN
  -- Mapa de columnas de transactions
  PERFORM set_config('selempos.tx_time_col',  'tx_time',            true);
  PERFORM set_config('selempos.tx_amount_col','amount',             true);
  PERFORM set_config('selempos.tx_pay_col',   'payment_type',       true);
  PERFORM set_config('selempos.tx_type_col',  'transaction_type',   true);

  -- ticket cerrado
  PERFORM set_config('selempos.ticket_closed_col','closed_time',    true);

  -- drawer_assigned_history tiempos
  PERFORM set_config('selempos.dah_assigned_col','assigned_time',   true);
  PERFORM set_config('selempos.dah_released_col','released_time',   true);

  -- terminal balance
  PERFORM set_config('selempos.terminal_balance_col','current_balance', true);
END
$params$;

-- Helper para referenciar columnas configuradas
CREATE OR REPLACE FUNCTION selempos_col(name TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT current_setting(name,true)
$$;

-- ===========================================
-- 2) ESQUEMA AUXILIAR
-- ===========================================
CREATE SCHEMA IF NOT EXISTS selempos;

-- Sesión de cajón (ventana de tiempo + snapshot opening_float)
CREATE TABLE IF NOT EXISTS selempos.selempos_drawer_session (
  id BIGSERIAL PRIMARY KEY,
  terminal_id INTEGER NOT NULL,
  cashier_user_id INTEGER NOT NULL,
  drawer_assigned_history_id BIGINT,
  opened_at TIMESTAMPTZ NOT NULL,
  closed_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE','READY_FOR_CUT','CUT_DONE','POSTCUT_DONE')) DEFAULT 'ACTIVE',
  opening_float NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER,
  CONSTRAINT ux_selempos_session UNIQUE (terminal_id, cashier_user_id, opened_at)
);
CREATE INDEX IF NOT EXISTS ix_selempos_session_terminal ON selempos.selempos_drawer_session(terminal_id, opened_at);
CREATE INDEX IF NOT EXISTS ix_selempos_session_cashier  ON selempos.selempos_drawer_session(cashier_user_id, opened_at);

-- Precorte (declarado)
CREATE TABLE IF NOT EXISTS selempos.selempos_precorte (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES selempos.selempos_drawer_session(id) ON DELETE CASCADE,
  declared_cash NUMERIC(12,2) NOT NULL DEFAULT 0,
  declared_other NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK (status IN ('PENDING','SUBMITTED','APPROVED','REJECTED')) DEFAULT 'PENDING',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER,
  client_ip INET
);

-- Detalle de efectivo por denominación (opcional)
CREATE TABLE IF NOT EXISTS selempos.selempos_precorte_cash (
  id BIGSERIAL PRIMARY KEY,
  precorte_id BIGINT NOT NULL REFERENCES selempos.selempos_precorte(id) ON DELETE CASCADE,
  denom NUMERIC(12,2) NOT NULL,
  qty   INTEGER NOT NULL,
  subtotal NUMERIC(12,2) GENERATED ALWAYS AS (denom * qty) STORED
);

-- Postcorte (conciliación final)
CREATE TABLE IF NOT EXISTS selempos.selempos_postcorte (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES selempos.selempos_drawer_session(id) ON DELETE CASCADE,
  declared_cash_final  NUMERIC(12,2) NOT NULL DEFAULT 0,
  declared_cards_final NUMERIC(12,2) NOT NULL DEFAULT 0,
  system_cash          NUMERIC(12,2) NOT NULL DEFAULT 0,
  system_cards         NUMERIC(12,2) NOT NULL DEFAULT 0,
  diff_cash            NUMERIC(12,2) NOT NULL DEFAULT 0,
  diff_cards           NUMERIC(12,2) NOT NULL DEFAULT 0,
  closed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by INTEGER
);

-- Mapa de formas de pago (ajustable a tu transactions)
CREATE TABLE IF NOT EXISTS selempos.selempos_payment_map (
  code TEXT PRIMARY KEY,     -- 'CASH','DEBIT','CREDIT','TRANSFER'
  match_expr TEXT NOT NULL   -- valor en transactions.(payment_type o transaction_type)
);
INSERT INTO selempos.selempos_payment_map(code, match_expr) VALUES
('CASH','CASH'),
('DEBIT','DEBIT'),
('CREDIT','CREDIT'),
('TRANSFER','TRANSFER')
ON CONFLICT DO NOTHING;

-- Auditoría simple
CREATE TABLE IF NOT EXISTS selempos.selempos_audit (
  id BIGSERIAL PRIMARY KEY,
  who INTEGER,
  what TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===========================================
-- 3) VISTAS DE TOTALES POR SESIÓN
-- ===========================================
-- 3.1 ventas por forma de pago en ventana de sesión
CREATE OR REPLACE VIEW selempos.selempos_vw_session_sales AS
WITH base AS (
  SELECT
    s.id AS session_id,
    t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC AS amount,
    pm.code AS payment_code
  FROM selempos.selempos_drawer_session s
  JOIN transactions t
    ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
   AND t.(SELECT selempos_col('selempos.tx_time_col')) < COALESCE(s.closed_at, now())
   AND t.terminal_id = s.terminal_id
   AND t.user_id     = s.cashier_user_id
  JOIN selempos.selempos_payment_map pm
    ON (t.(SELECT selempos_col('selempos.tx_pay_col'))  = pm.match_expr
     OR  t.(SELECT selempos_col('selempos.tx_type_col')) = pm.match_expr)
)
SELECT session_id, payment_code, SUM(amount) AS amount
FROM base
GROUP BY session_id, payment_code;

-- 3.2 descuentos (ajusta si tus descuentos están en otras tablas)
-- Si tus descuentos viven en ticket_discount/ticket_item_discount con timestamp y user/terminal:
CREATE OR REPLACE VIEW selempos.selempos_vw_session_discounts AS
SELECT s.id AS session_id, COALESCE(SUM(d.amount),0) AS discounts
FROM selempos.selempos_drawer_session s
LEFT JOIN ticket_discount d
  ON d.created_at >= s.opened_at
 AND d.created_at <  COALESCE(s.closed_at, now())
 AND d.terminal_id = s.terminal_id
 AND d.user_id     = s.cashier_user_id
GROUP BY s.id;

-- 3.3 anulaciones/devoluciones (VOID/REFUND) sobre ticket
CREATE OR REPLACE VIEW selempos.selempos_vw_session_voids AS
SELECT s.id AS session_id,
       COALESCE(SUM(CASE WHEN tk.status IN ('VOID','REFUND') THEN tk.total ELSE 0 END),0) AS void_total
FROM selempos.selempos_drawer_session s
LEFT JOIN ticket tk
  ON tk.(SELECT selempos_col('selempos.ticket_closed_col')) >= s.opened_at
 AND tk.(SELECT selempos_col('selempos.ticket_closed_col')) <  COALESCE(s.closed_at, now())
 AND tk.terminal_id = s.terminal_id
 AND tk.owner_id    = s.cashier_user_id
GROUP BY s.id;

-- 3.4 retiros/egresos (payouts/expenses) en ventana
CREATE OR REPLACE VIEW selempos.selempos_vw_session_payouts AS
SELECT s.id AS session_id, COALESCE(SUM(t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC),0) AS payouts
FROM selempos.selempos_drawer_session s
JOIN transactions t
  ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
 AND t.(SELECT selempos_col('selempos.tx_time_col')) <  COALESCE(s.closed_at, now())
 AND t.terminal_id = s.terminal_id
 AND t.user_id     = s.cashier_user_id
WHERE t.(SELECT selempos_col('selempos.tx_type_col')) IN ('PAYOUT','EXPENSE')
GROUP BY s.id;

-- 3.5 devoluciones EN EFECTIVO (si aplica)
CREATE OR REPLACE VIEW selempos.selempos_vw_session_cash_refunds AS
SELECT s.id AS session_id,
       COALESCE(SUM(t.(SELECT selempos_col('selempos.tx_amount_col'))::TEXT::NUMERIC),0) AS cash_refunds
FROM selempos.selempos_drawer_session s
JOIN transactions t
  ON t.(SELECT selempos_col('selempos.tx_time_col')) >= s.opened_at
 AND t.(SELECT selempos_col('selempos.tx_time_col')) <  COALESCE(s.closed_at, now())
 AND t.terminal_id = s.terminal_id
 AND t.user_id     = s.cashier_user_id
WHERE (t.(SELECT selempos_col('selempos.tx_type_col')) IN ('REFUND','RETURN') OR t.status='REFUND')
  AND (t.(SELECT selempos_col('selempos.tx_pay_col')) = 'CASH' OR t.(SELECT selempos_col('selempos.tx_type_col')) = 'CASH')
GROUP BY s.id;

-- 3.6 balance sintetizado con esperado en caja
CREATE OR REPLACE VIEW selempos.selempos_vw_session_balance AS
SELECT
  s.id AS session_id,
  s.terminal_id,
  s.cashier_user_id,
  s.opened_at,
  s.closed_at,
  s.status,
  s.opening_float,
  COALESCE(SUM(CASE WHEN sales.payment_code='CASH' THEN sales.amount END),0) AS sys_cash,
  COALESCE(SUM(CASE WHEN sales.payment_code IN ('DEBIT','CREDIT','TRANSFER') THEN sales.amount END),0) AS sys_non_cash,
  COALESCE(vd.discounts,0)  AS sys_discounts,
  COALESCE(vv.void_total,0) AS sys_voids,
  COALESCE(vp.payouts,0)    AS sys_payouts,
  COALESCE(vcr.cash_refunds,0) AS sys_cash_refunds,
  ( s.opening_float
    + COALESCE(SUM(CASE WHEN sales.payment_code='CASH' THEN sales.amount END),0)
    - COALESCE(vp.payouts,0)
    - COALESCE(vcr.cash_refunds,0)
  ) AS sys_expected_cash
FROM selempos.selempos_drawer_session s
LEFT JOIN selempos.selempos_vw_session_sales       sales ON sales.session_id = s.id
LEFT JOIN selempos.selempos_vw_session_discounts   vd    ON vd.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_voids       vv    ON vv.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_payouts     vp    ON vp.session_id    = s.id
LEFT JOIN selempos.selempos_vw_session_cash_refunds vcr  ON vcr.session_id   = s.id
GROUP BY s.id, s.terminal_id, s.cashier_user_id, s.opened_at, s.closed_at, s.status,
         s.opening_float, vd.discounts, vv.void_total, vp.payouts, vcr.cash_refunds;

-- ===========================================
-- 4) TRIGGERS DE SINCRONIZACIÓN CON ASIGNACIÓN DE CAJÓN
--    Al asignar: crea sesión y toma snapshot de terminal.current_balance
--    Al liberar: cierra ventana y avanza estado
-- ===========================================
CREATE OR REPLACE FUNCTION selempos.selempos_fn_on_drawer_assigned_ins()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
DECLARE
  v_opening NUMERIC(12,2) := 0;
  v_exists  BIGINT;
  v_assigned_col TEXT := current_setting('selempos.dah_assigned_col', true);
  v_bal_col      TEXT := current_setting('selempos.terminal_balance_col', true);
  v_assigned_ts  TIMESTAMPTZ;
  v_sql TEXT;
BEGIN
  -- obtener assigned_time (columna parametrizada)
  v_sql := format('SELECT ($1).%I::timestamptz', v_assigned_col);
  EXECUTE v_sql USING NEW INTO v_assigned_ts;

  -- snapshot del fondo en terminal.current_balance (columna parametrizada)
  v_sql := format('SELECT COALESCE(%I,0)::numeric FROM terminal WHERE id = $1', v_bal_col);
  EXECUTE v_sql INTO v_opening USING NEW.terminal_id;

  -- evitar duplicados por reintentos
  SELECT s.id INTO v_exists
  FROM selempos.selempos_drawer_session s
  WHERE s.terminal_id      = NEW.terminal_id
    AND s.cashier_user_id  = NEW.user_id
    AND s.opened_at        = COALESCE(v_assigned_ts, now());

  IF v_exists IS NULL THEN
    INSERT INTO selempos.selempos_drawer_session(
      terminal_id, cashier_user_id, drawer_assigned_history_id,
      opened_at, status, opening_float, created_by
    )
    VALUES (
      NEW.terminal_id, NEW.user_id, NEW.id,
      COALESCE(v_assigned_ts, now()), 'ACTIVE', v_opening, NEW.user_id
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_selempos_drawer_assigned_ins ON drawer_assigned_history;
CREATE TRIGGER trg_selempos_drawer_assigned_ins
AFTER INSERT ON drawer_assigned_history
FOR EACH ROW EXECUTE FUNCTION selempos.selempos_fn_on_drawer_assigned_ins();

-- Cierre de sesión al liberar cajón
CREATE OR REPLACE FUNCTION selempos.selempos_fn_on_drawer_assigned_upd()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
DECLARE
  v_released_col TEXT := current_setting('selempos.dah_released_col', true);
  v_released_ts  TIMESTAMPTZ;
  v_sql TEXT;
BEGIN
  IF NEW IS DISTINCT FROM OLD THEN
    v_sql := format('SELECT ($1).%I::timestamptz', v_released_col);
    EXECUTE v_sql USING NEW INTO v_released_ts;

    IF v_released_ts IS NOT NULL THEN
      UPDATE selempos.selempos_drawer_session s
      SET closed_at = v_released_ts,
          status = CASE WHEN s.status='ACTIVE' THEN 'READY_FOR_CUT' ELSE s.status END
      WHERE s.drawer_assigned_history_id = NEW.id
        AND s.closed_at IS NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_selempos_drawer_assigned_upd ON drawer_assigned_history;
CREATE TRIGGER trg_selempos_drawer_assigned_upd
AFTER UPDATE ON drawer_assigned_history
FOR EACH ROW EXECUTE FUNCTION selempos.selempos_fn_on_drawer_assigned_upd();

-- ===========================================
-- 5) COMPROBACIONES RÁPIDAS
-- ===========================================
-- ¿Sesiones activas?
-- SELECT * FROM selempos.selempos_drawer_session ORDER BY id DESC LIMIT 20;

-- ¿Balance por sesión?
-- SELECT * FROM selempos.selempos_vw_session_balance ORDER BY session_id DESC LIMIT 20;

-- ===========================================
-- FIN
-- ===========================================
