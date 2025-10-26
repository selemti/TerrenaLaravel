-- =========================================
--  ESQUEMA AUXILIAR TERRENA  (Safe for POS)
-- =========================================

-- 1) Sesión de cajón propia de Terrena (ventana de precorte/corte/postcorte)
CREATE TABLE IF NOT EXISTS terrena_drawer_session (
  id               BIGSERIAL PRIMARY KEY,
  terminal_id      INTEGER NOT NULL REFERENCES public.terminal(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  dah_id           INTEGER NULL REFERENCES public.drawer_assigned_history(id) ON UPDATE NO ACTION ON DELETE SET NULL,
  assigned_user    INTEGER NULL REFERENCES public.users(auto_id) ON UPDATE NO ACTION ON DELETE SET NULL,
  window_start     TIMESTAMP NOT NULL,           -- inicio de la “ventana” (último reset/corte o primer movimiento del día)
  window_end       TIMESTAMP NULL,               -- fin (cuando se corta / se cierra sesión)
  status           VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- OPEN | READY_FOR_CUT | CUT_DONE | CLOSED
  notes            TEXT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT now(),
  updated_at       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_terrena_session_terminal ON terrena_drawer_session(terminal_id, status);

-- 2) Precorte (encabezado)
CREATE TABLE IF NOT EXISTS terrena_precorte (
  id             BIGSERIAL PRIMARY KEY,
  session_id     BIGINT NOT NULL REFERENCES terrena_drawer_session(id) ON UPDATE NO ACTION ON DELETE CASCADE,
  user_id        INTEGER NULL REFERENCES public.users(auto_id),
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  notes          TEXT NULL
);

-- 3) Conteo rápido de efectivo (denominaciones)
CREATE TABLE IF NOT EXISTS terrena_precorte_cash (
  id            BIGSERIAL PRIMARY KEY,
  precorte_id   BIGINT NOT NULL REFERENCES terrena_precorte(id) ON UPDATE NO ACTION ON DELETE CASCADE,
  denom_value   NUMERIC(12,2) NOT NULL,
  qty           INTEGER NOT NULL DEFAULT 0
);

-- 4) Declarados por método (efectivo/tarjeta/transfer/etc.)
CREATE TABLE IF NOT EXISTS terrena_precorte_declared (
  id            BIGSERIAL PRIMARY KEY,
  precorte_id   BIGINT NOT NULL REFERENCES terrena_precorte(id) ON UPDATE NO ACTION ON DELETE CASCADE,
  method        VARCHAR(40) NOT NULL,            -- CASH | CREDIT | DEBIT | TRANSFER | CUSTOM:<name>
  amount        NUMERIC(14,2) NOT NULL DEFAULT 0
);

-- 5) Resultado de conciliación (postcorte)
CREATE TABLE IF NOT EXISTS terrena_conciliacion (
  id              BIGSERIAL PRIMARY KEY,
  session_id      BIGINT NOT NULL REFERENCES terrena_drawer_session(id) ON UPDATE NO ACTION ON DELETE CASCADE,
  declared_total  NUMERIC(14,2) NOT NULL DEFAULT 0,
  system_total    NUMERIC(14,2) NOT NULL DEFAULT 0,
  diff_total      NUMERIC(14,2) NOT NULL DEFAULT 0,
  details_json    JSONB NULL,                    -- breakdown (por método, descuentos, anulaciones, retiros…)
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

-- Helper: view de pagos en ventana (por terminal)
DROP VIEW IF EXISTS terrena_vw_window_payments;
CREATE VIEW terrena_vw_window_payments AS
SELECT
  s.id                AS session_id,
  t.terminal_id,
  t.user_id,
  t.payment_type,
  t.payment_sub_type,
  t.custom_payment_name,
  SUM(
    CASE
      WHEN COALESCE(t.voided,false) = TRUE THEN 0
      WHEN UPPER(COALESCE(t.transaction_type,'')) IN ('REFUND','VOID','RETURN') THEN 0
      ELSE COALESCE(t.amount,0)
    END
  ) AS total
FROM terrena_drawer_session s
JOIN transactions t
  ON t.terminal_id = s.terminal_id
 AND t.transaction_time >= s.window_start
 AND (s.window_end IS NULL OR t.transaction_time <= s.window_end)
GROUP BY s.id, t.terminal_id, t.user_id, t.payment_type, t.payment_sub_type, t.custom_payment_name;

-- Vendedores por ventana
DROP VIEW IF EXISTS terrena_vw_window_sellers;
CREATE VIEW terrena_vw_window_sellers AS
SELECT
  s.id      AS session_id,
  u.auto_id AS user_id,
  TRIM(COALESCE(u.first_name,'') || ' ' || COALESCE(u.last_name,'')) AS name,
  SUM(
    CASE
      WHEN COALESCE(t.voided,false) = TRUE THEN 0
      WHEN UPPER(COALESCE(t.transaction_type,'')) IN ('REFUND','VOID','RETURN') THEN 0
      ELSE COALESCE(t.amount,0)
    END
  ) AS total
FROM terrena_drawer_session s
JOIN transactions t
  ON t.terminal_id = s.terminal_id
 AND t.transaction_time >= s.window_start
 AND (s.window_end IS NULL OR t.transaction_time <= s.window_end)
JOIN users u ON u.auto_id = t.user_id
GROUP BY s.id, u.auto_id, name;

-- Descuentos por ventana (ticket y por ítem)
DROP VIEW IF EXISTS terrena_vw_window_discounts;
CREATE VIEW terrena_vw_window_discounts AS
SELECT s.id AS session_id,
       SUM(COALESCE(td.value,0)) AS ticket_discount_value,
       SUM(COALESCE(tid.amount,0)) AS item_discount_amount
FROM terrena_drawer_session s
LEFT JOIN ticket tk
  ON tk.terminal_id = s.terminal_id
 AND tk.create_date >= s.window_start
 AND (s.window_end IS NULL OR tk.create_date <= s.window_end)
LEFT JOIN ticket_discount td ON td.ticket_id = tk.id
LEFT JOIN ticket_item ti     ON ti.ticket_id = tk.id
LEFT JOIN ticket_item_discount tid ON tid.ticket_itemid = ti.id
GROUP BY s.id;

-- Retiros / PayOuts (transactions ya trae payout_* cuando aplica)
DROP VIEW IF EXISTS terrena_vw_window_payouts;
CREATE VIEW terrena_vw_window_payouts AS
SELECT s.id AS session_id,
       COUNT(*) FILTER (WHERE t.payout_reason_id IS NOT NULL) AS payout_count,
       COALESCE(SUM(CASE WHEN t.payout_reason_id IS NOT NULL THEN t.amount ELSE 0 END),0) AS payout_amount
FROM terrena_drawer_session s
LEFT JOIN transactions t
  ON t.terminal_id = s.terminal_id
 AND t.transaction_time >= s.window_start
 AND (s.window_end IS NULL OR t.transaction_time <= s.window_end)
GROUP BY s.id;