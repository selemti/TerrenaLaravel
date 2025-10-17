/* ======================================================================
   011.delta_merma_desperdicio_porciones.sql
   Complemento: Merma vs Desperdicio + Porcionamiento de preparaciones
   Compatibilidad: PostgreSQL 9.5, idempotente
   Supone: esquema selemti, OP/lotes internos, mov_inv y ticket_venta_* existentes
   ====================================================================== */

SET client_min_messages = WARNING;
SET TIME ZONE 'America/Mexico_City';
SET search_path TO selemti, public;

/* --------------------------------------------------------------
   1) Clasificación de pérdida: MERMA vs DESPERDICIO
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='merma_clase') THEN
    CREATE TYPE selemti.merma_clase AS ENUM ('MERMA','DESPERDICIO');
  END IF;
END$$;

-- Tabla de pérdidas (operativa), enlazada al kardex (opcional en tu flujo).
-- Permite justificar salida por caducidad/proceso/servicio y evidenciarla.
CREATE TABLE IF NOT EXISTS selemti.perdida_log (
  id              BIGSERIAL PRIMARY KEY,
  ts              TIMESTAMP NOT NULL DEFAULT now(),
  item_id         TEXT      NOT NULL,
  lote_id         BIGINT,
  sucursal_id     TEXT,
  clase           selemti.merma_clase NOT NULL,     -- MERMA (aprovechable/esperable) o DESPERDICIO (no aprovechable)
  motivo          TEXT,                              -- texto libre: caducidad, sobrante servicio, contaminación, etc.
  qty_canonica    NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
  qty_original    NUMERIC(14,6),
  uom_original_id INT REFERENCES selemti.unidades_medida(id),
  evidencia_url   TEXT,                              -- foto/acta
  usuario_id      INT,
  ref_tipo        TEXT,                              -- p.ej. 'CIERRE_PREP'
  ref_id          BIGINT,
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_perdida_item_ts' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_perdida_item_ts ON selemti.perdida_log(item_id, ts DESC);
  END IF;
END$$;

/* --------------------------------------------------------------
   2) Porcionamiento de preparaciones: registro por ticket/plato
   -------------------------------------------------------------- */
-- Detalle de consumo por ticket (grano fino): qué lote/preparación se usó,
-- cuánta cantidad (en canónica y original) y a qué ticket_item se aplicó.
CREATE TABLE IF NOT EXISTS selemti.ticket_det_consumo (
  id                  BIGSERIAL PRIMARY KEY,
  ticket_id           BIGINT     NOT NULL,           -- FK a ticket_venta_cab (lógico)
  ticket_det_id       BIGINT     NOT NULL,           -- FK a ticket_venta_det (lógico)
  item_id             TEXT       NOT NULL,           -- insumo o preparado consumido
  lote_id             BIGINT,                        -- lote específico (incluye lotes internos de OP)
  qty_canonica        NUMERIC(14,6) NOT NULL CHECK (qty_canonica > 0),
  qty_original        NUMERIC(14,6),
  uom_original_id     INT REFERENCES selemti.unidades_medida(id),
  sucursal_id         TEXT,
  ref_tipo            TEXT,                          -- 'VENTA','OP','SERVICIO'
  ref_id              BIGINT,
  created_at          TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (ticket_det_id, item_id, lote_id, qty_canonica, COALESCE(uom_original_id,0))
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_tickcons_ticket' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_tickcons_ticket ON selemti.ticket_det_consumo (ticket_id, ticket_det_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_tickcons_lote' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_tickcons_lote ON selemti.ticket_det_consumo (item_id, lote_id);
  END IF;
END$$;

/* --------------------------------------------------------------
   3) Cierre de lote preparado (remanente → merma o desperdicio)
   -------------------------------------------------------------- */
-- Al finalizar el turno/día o al vencimiento, registra el remanente de una
-- preparación (lote interno) como salida + log de pérdida con clase.
-- Esta función no hace cálculos de FEFO/PEPS, asume lote explícito.
CREATE OR REPLACE FUNCTION selemti.cerrar_lote_preparado(
  p_lote_id       BIGINT,
  p_clase         selemti.merma_clase,      -- 'MERMA' o 'DESPERDICIO'
  p_motivo        TEXT,
  p_usuario_id    INT DEFAULT NULL,
  p_uom_id        INT DEFAULT NULL          -- si envías qty_original/uom
) RETURNS BIGINT AS $$
DECLARE
  v_item_id        TEXT;
  v_qty_disponible NUMERIC(14,6);
  v_mov_id         BIGINT;
BEGIN
  -- Disponibilidad del lote (en canónica)
  SELECT b.item_id,
         COALESCE(SUM(CASE WHEN m.signo IS NULL THEN 0 ELSE m.signo * m.cantidad END),0)
  INTO   v_item_id, v_qty_disponible
  FROM   selemti.inventory_batch b
  LEFT JOIN selemti.v_kardex_por_lote m ON m.lote_id = b.id        -- o suma de mov_inv por lote
  WHERE  b.id = p_lote_id
  GROUP  BY b.item_id;

  IF v_item_id IS NULL THEN
    RAISE EXCEPTION 'Lote % no existe', p_lote_id;
  END IF;

  IF v_qty_disponible IS NULL OR v_qty_disponible <= 0 THEN
    RETURN 0; -- nada que cerrar
  END IF;

  -- 3.1) Registrar salida en kardex (MERMA operativa)
  INSERT INTO selemti.mov_inv (
    ts, item_id, lote_id, cantidad, qty_original, uom_original_id,
    tipo, ref_tipo, ref_id, sucursal_id
  )
  VALUES (
    now(), v_item_id, p_lote_id, 0 - v_qty_disponible, NULL, p_uom_id,
    'MERMA', 'CIERRE_PREP', p_lote_id, NULL
  )
  RETURNING id INTO v_mov_id;

  -- 3.2) Log de pérdida con clase (MERMA/DESPERDICIO)
  INSERT INTO selemti.perdida_log (
    ts, item_id, lote_id, clase, motivo, qty_canonica, uom_original_id,
    usuario_id, ref_tipo, ref_id
  ) VALUES (
    now(), v_item_id, p_lote_id, p_clase, p_motivo, v_qty_disponible, p_uom_id,
    p_usuario_id, 'CIERRE_PREP', v_mov_id
  );

  RETURN v_mov_id;
END;
$$ LANGUAGE plpgsql;

/* --------------------------------------------------------------
   4) Vistas KPI: Merma vs Desperdicio y Rendimiento de preparación
   -------------------------------------------------------------- */
-- 4.1) KPI por semana y clase (MERMA/DESPERDICIO)
CREATE OR REPLACE VIEW selemti.v_perdida_clase_semana AS
SELECT
  item_id,
  date_trunc('week', ts)::date AS semana,
  clase,
  SUM(qty_canonica) AS qty_canonica
FROM selemti.perdida_log
GROUP BY 1,2,3;

-- 4.2) Rendimiento de preparación: usa OP (teórico) vs entregado (real) y consumo registrado
-- Nota: ajusta nombres de tablas de OP/lotes internos según tu esquema.
-- Este es un esqueleto que asume:
--   - selemti.op_produccion (id, receta_id, qty_planeada, qty_real, lote_resultado_id, ts_cierre)
--   - v_kardex_por_lote suma mov_inv por lote.
CREATE OR REPLACE VIEW selemti.v_rendimiento_preparacion AS
SELECT
  op.id                       AS op_id,
  op.receta_id,
  op.lote_resultado_id        AS lote_id,
  op.qty_planeada,
  op.qty_real,
  (CASE WHEN op.qty_planeada IS NULL OR op.qty_planeada=0 THEN NULL
        ELSE ROUND(100.0 * op.qty_real / op.qty_planeada, 2) END) AS rendimiento_pct,
  kardex.saldo_final_canonica AS saldo_lote_canonica,
  (CASE WHEN op.qty_real IS NULL OR op.qty_real=0 THEN NULL
        ELSE ROUND(100.0 * kardex.saldo_final_canonica / op.qty_real, 2) END) AS sobrante_pct
FROM selemti.op_produccion op
LEFT JOIN (
  SELECT
    lote_id,
    SUM(CASE WHEN signo IS NULL THEN 0 ELSE signo * cantidad END) AS saldo_final_canonica
  FROM selemti.v_kardex_por_lote   -- o arma una suma de mov_inv por lote
  GROUP BY lote_id
) kardex ON kardex.lote_id = op.lote_resultado_id;

/* --------------------------------------------------------------
   5) Vista de porciones por ticket (para preparaciones compartidas)
   -------------------------------------------------------------- */
CREATE OR REPLACE VIEW selemti.v_porciones_por_ticket AS
SELECT
  tdc.ticket_id,
  tdc.ticket_det_id,
  tdc.item_id       AS insumo_preparado,
  tdc.lote_id,
  SUM(tdc.qty_canonica) AS qty_total_canonica,
  COUNT(*)              AS usos
FROM selemti.ticket_det_consumo tdc
GROUP BY 1,2,3,4;

/* ======================================================================
   FIN 011.delta_merma_desperdicio_porciones.sql
   ====================================================================== */
