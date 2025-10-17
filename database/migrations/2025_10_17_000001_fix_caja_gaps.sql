-- ================================================================
-- MIGRATION: Fix Critical Gaps in Caja/Cortes System
-- Date: 2025-10-17
-- Description: Creates missing database objects for the cash register
--              management system based on gap analysis.
-- ================================================================

-- ================================================================
-- 1. CREATE TABLE: selemti.conciliacion
-- ================================================================
CREATE TABLE IF NOT EXISTS selemti.conciliacion (
  id BIGSERIAL PRIMARY KEY,
  postcorte_id BIGINT NOT NULL UNIQUE REFERENCES selemti.postcorte(id) ON DELETE CASCADE,
  conciliado_por INTEGER,
  conciliado_en TIMESTAMPTZ DEFAULT now(),
  estatus TEXT NOT NULL DEFAULT 'EN_REVISION'
    CHECK (estatus IN ('EN_REVISION','CONCILIADO','OBSERVADA')),
  notas TEXT
);

COMMENT ON TABLE selemti.conciliacion IS 'Registra el proceso de conciliación final después del postcorte';
COMMENT ON COLUMN selemti.conciliacion.postcorte_id IS 'FK a postcorte (UNIQUE - solo una conciliación por postcorte)';
COMMENT ON COLUMN selemti.conciliacion.conciliado_por IS 'Usuario que realizó la conciliación (supervisor/gerente)';

-- ================================================================
-- 2. ADD CONSTRAINT: UNIQUE on precorte(sesion_id)
-- ================================================================
-- Prevent multiple precortes for the same session
ALTER TABLE selemti.precorte
DROP CONSTRAINT IF EXISTS uq_precorte_sesion_id;

ALTER TABLE selemti.precorte
ADD CONSTRAINT uq_precorte_sesion_id UNIQUE(sesion_id);

-- ================================================================
-- 3. UPDATE CHECK CONSTRAINT: sesion_cajon.estatus
-- ================================================================
-- Add missing states: EN_CORTE, CONCILIADA, OBSERVADA
ALTER TABLE selemti.sesion_cajon
DROP CONSTRAINT IF EXISTS sesion_cajon_estatus_check;

ALTER TABLE selemti.sesion_cajon
ADD CONSTRAINT sesion_cajon_estatus_check
CHECK (estatus IN (
  'ACTIVA',
  'LISTO_PARA_CORTE',
  'EN_CORTE',
  'CERRADA',
  'CONCILIADA',
  'OBSERVADA'
));

-- ================================================================
-- 4. CREATE FUNCTION: fn_generar_postcorte(p_sesion_id)
-- ================================================================
-- Generates postcorte automatically based on precorte data and POS transactions
CREATE OR REPLACE FUNCTION selemti.fn_generar_postcorte(p_sesion_id BIGINT)
RETURNS BIGINT AS $$
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
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION selemti.fn_generar_postcorte(BIGINT) IS 'Genera automáticamente el postcorte basado en el precorte y transacciones POS';

-- ================================================================
-- 5. CREATE TRIGGERS: State Transitions
-- ================================================================

-- A. Trigger: Precorte INSERT → sesión EN_CORTE
CREATE OR REPLACE FUNCTION selemti.fn_precorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'EN_CORTE'
  WHERE id = NEW.sesion_id
    AND estatus = 'LISTO_PARA_CORTE';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_precorte_after_insert ON selemti.precorte;
CREATE TRIGGER trg_precorte_after_insert
AFTER INSERT ON selemti.precorte
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_precorte_after_insert();

COMMENT ON FUNCTION selemti.fn_precorte_after_insert() IS 'Trigger: Al crear precorte, marca sesión como EN_CORTE';

-- B. Trigger: Precorte UPDATE (APROBADO) → genera postcorte
CREATE OR REPLACE FUNCTION selemti.fn_precorte_after_update_aprobado()
RETURNS TRIGGER AS $$
DECLARE
  v_postcorte_id BIGINT;
BEGIN
  IF NEW.estatus = 'APROBADO' AND OLD.estatus != 'APROBADO' THEN
    -- Generar postcorte automáticamente
    SELECT selemti.fn_generar_postcorte(NEW.sesion_id) INTO v_postcorte_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_precorte_after_update_aprobado ON selemti.precorte;
CREATE TRIGGER trg_precorte_after_update_aprobado
AFTER UPDATE ON selemti.precorte
FOR EACH ROW
WHEN (NEW.estatus = 'APROBADO' AND OLD.estatus IS DISTINCT FROM 'APROBADO')
EXECUTE PROCEDURE selemti.fn_precorte_after_update_aprobado();

COMMENT ON FUNCTION selemti.fn_precorte_after_update_aprobado() IS 'Trigger: Al aprobar precorte, genera postcorte automáticamente';

-- C. Trigger: Postcorte INSERT → sesión CERRADA
CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'CERRADA',
      cierre_ts = COALESCE(cierre_ts, now())
  WHERE id = NEW.sesion_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_postcorte_after_insert ON selemti.postcorte;
CREATE TRIGGER trg_postcorte_after_insert
AFTER INSERT ON selemti.postcorte
FOR EACH ROW
EXECUTE PROCEDURE selemti.fn_postcorte_after_insert();

COMMENT ON FUNCTION selemti.fn_postcorte_after_insert() IS 'Trigger: Al crear postcorte, marca sesión como CERRADA';

-- ================================================================
-- 6. CREATE PERFORMANCE INDEXES
-- ================================================================

-- Índice en precorte_efectivo(precorte_id) para FK
CREATE INDEX IF NOT EXISTS idx_precorte_efectivo_precorte_id
ON selemti.precorte_efectivo(precorte_id);

-- Índice en precorte_otros(precorte_id) para FK
CREATE INDEX IF NOT EXISTS idx_precorte_otros_precorte_id
ON selemti.precorte_otros(precorte_id);

-- Índice parcial en public.ticket para preflight check
CREATE INDEX IF NOT EXISTS idx_ticket_terminal_open
ON public.ticket(terminal_id, closing_date)
WHERE closing_date IS NULL;

-- Índice en selemti.sesion_cajon para búsquedas por terminal y fecha
CREATE INDEX IF NOT EXISTS idx_sesion_cajon_terminal_apertura
ON selemti.sesion_cajon(terminal_id, apertura_ts);

-- Índice en selemti.postcorte para búsquedas por sesión
CREATE INDEX IF NOT EXISTS idx_postcorte_sesion_id
ON selemti.postcorte(sesion_id);

-- ================================================================
-- END OF MIGRATION
-- ================================================================
