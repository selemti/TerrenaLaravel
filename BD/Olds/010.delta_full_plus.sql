/* ======================================================================
   010.delta_full_plus.sql
   Selemti - Deltas finales de modelo para operación multi-UOM, elaborados,
   traspasos, stock policies y mermas. PG ≥ 9.5
   ====================================================================== */

SET client_min_messages = WARNING;
SET TIME ZONE 'America/Mexico_City';

/* Asegurar esquema y search_path */
CREATE SCHEMA IF NOT EXISTS selemti;
SET search_path TO selemti, public;

/* --------------------------------------------------------------
   A) UOM original en movimientos (fidelidad operativa)
   -------------------------------------------------------------- */
-- Se asume que selemti.unidades_medida ya existe (GR, ML, PZ, etc.)

-- Kardex: cantidad en canónica ya existe (cantidad/qty). Agregamos
-- qty_original + uom_original_id para preservar la UOM de la transacción.
ALTER TABLE IF EXISTS selemti.mov_inv
  ADD COLUMN IF NOT EXISTS qty_original NUMERIC(14,6),
  ADD COLUMN IF NOT EXISTS uom_original_id INT REFERENCES selemti.unidades_medida(id);

-- Índices útiles (si no existen)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_movinv_item_ts' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_movinv_item_ts ON selemti.mov_inv (item_id, ts);
  END IF;
END$$;

/* --------------------------------------------------------------
   B) Presentaciones por proveedor (compra caja/saco/etc.)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.item_vendor (
  item_id            TEXT        NOT NULL,
  vendor_id          TEXT        NOT NULL,
  presentacion       TEXT        NOT NULL,   -- "caja 12x1L", "saco 25kg"
  unidad_presentacion_id INT     NOT NULL REFERENCES selemti.unidades_medida(id), -- PZ
  factor_a_canonica  NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),        -- p.ej. 12000 ML/PZ
  costo_ultimo       NUMERIC(14,6) NOT NULL DEFAULT 0,
  moneda             TEXT        NOT NULL DEFAULT 'MXN',
  lead_time_dias     INT,
  codigo_proveedor   TEXT,
  activo             BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMP   NOT NULL DEFAULT now(),
  PRIMARY KEY (item_id, vendor_id, presentacion)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_item_vendor_item' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_item_vendor_item ON selemti.item_vendor(item_id);
  END IF;
END$$;

/* --------------------------------------------------------------
   C) Tipo de producto y UOM de salida (elaborados)
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='producto_tipo') THEN
    CREATE TYPE selemti.producto_tipo AS ENUM ('MATERIA_PRIMA','ELABORADO','ENVASADO');
  END IF;
END$$;

-- items: tipología + UOM de salida (para recetas/OP)
ALTER TABLE IF EXISTS selemti.items
  ADD COLUMN IF NOT EXISTS tipo selemti.producto_tipo,
  ADD COLUMN IF NOT EXISTS unidad_salida_id INT REFERENCES selemti.unidades_medida(id);

/* --------------------------------------------------------------
   D) Políticas de consumo por sucursal (FEFO default / PEPS opcional)
   -------------------------------------------------------------- */
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='consumo_policy') THEN
    CREATE TYPE selemti.consumo_policy AS ENUM ('FEFO','PEPS');
  END IF;
END$$;

-- Parametrización a nivel sucursal (si la tabla no existe, se crea mínima)
CREATE TABLE IF NOT EXISTS selemti.param_sucursal (
  id             SERIAL PRIMARY KEY,
  sucursal_id    TEXT UNIQUE NOT NULL,
  consumo        selemti.consumo_policy NOT NULL DEFAULT 'FEFO',
  tolerancia_precorte_pct NUMERIC(8,4) DEFAULT 0.02,
  tolerancia_corte_abs    NUMERIC(12,4) DEFAULT 50.0,
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  updated_at     TIMESTAMP NOT NULL DEFAULT now()
);

/* --------------------------------------------------------------
   E) Políticas de stock (mín/max y alertas)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.stock_policy (
  id             BIGSERIAL PRIMARY KEY,
  item_id        TEXT NOT NULL,
  sucursal_id    TEXT NOT NULL,
  almacen_id     TEXT,                 -- opcional si manejas multi-almacén por sucursal
  min_qty        NUMERIC(14,6) NOT NULL DEFAULT 0,
  max_qty        NUMERIC(14,6) NOT NULL DEFAULT 0,
  reorder_lote   NUMERIC(14,6),        -- cantidad sugerida por OC
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (item_id, sucursal_id, COALESCE(almacen_id,'_'))
);

/* --------------------------------------------------------------
   F) Relación sucursal–almacén–terminal (Floreant)
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.sucursal_almacen_terminal (
  id           SERIAL PRIMARY KEY,
  sucursal_id  TEXT        NOT NULL,
  almacen_id   TEXT        NOT NULL,             -- catálogo propio p.ej. "ALM-PRIN"
  terminal_id  INT         NULL,                 -- FK a public.terminal(id) si existe
  location     TEXT,                             
  descripcion  TEXT,
  activo       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMP   NOT NULL DEFAULT now(),
  UNIQUE (sucursal_id, almacen_id, COALESCE(terminal_id,0))
);

/* --------------------------------------------------------------
   G) Modificadores POS con receta + JSONB en tickets
   -------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS selemti.modificadores_pos (
  id                 SERIAL PRIMARY KEY,
  codigo_pos         VARCHAR(40) UNIQUE NOT NULL,
  nombre             VARCHAR(120) NOT NULL,
  tipo               VARCHAR(20)  NOT NULL CHECK (tipo IN ('AGREGADO','SUSTITUCION','ELIMINACION')),
  precio_extra       NUMERIC(12,4) NOT NULL DEFAULT 0,
  receta_modificador_id TEXT,              -- id de receta del modificador (según tu catálogo)
  activo             BOOLEAN NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

-- ticket_venta_det: capturar los modificadores aplicados por línea
ALTER TABLE IF EXISTS selemti.ticket_venta_det
  ADD COLUMN IF NOT EXISTS modificadores_aplicados JSONB;

/* --------------------------------------------------------------
   H) Vista de mermas por ítem (operativa semanal)
   -------------------------------------------------------------- */
CREATE OR REPLACE VIEW selemti.v_merma_por_item AS
SELECT
  m.item_id,
  date_trunc('week', m.ts)::date AS semana,
  SUM(CASE WHEN m.tipo = 'MERMA' THEN m.cantidad ELSE 0 END)                AS qty_mermada,  -- en canónica
  SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) AS qty_recibida,
  CASE 
    WHEN SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END) > 0
    THEN ROUND(
      100.0 * SUM(CASE WHEN m.tipo='MERMA' THEN m.cantidad ELSE 0 END) /
      NULLIF(SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA') THEN m.cantidad ELSE 0 END),0)
    , 2)
    ELSE 0
  END AS merma_pct
FROM selemti.mov_inv m
GROUP BY 1,2;

/* --------------------------------------------------------------
   I) Reglas sugeridas para traspasos de elaborados
   (documental: se registran dos mov_inv correlacionados por ref)
   -------------------------------------------------------------- */
-- No requiere nuevas tablas si ya se usa mov_inv + inventory_batch.
-- Recomendación: en tus servicios, registrar:
--  - salida en origen: ref_tipo='TRASPASO', ref_id=<id_traspaso>, batch_id=<lote_elaborado>
--  - entrada en destino: ref_tipo='TRASPASO', ref_id=<mismo id>, batch_id=<mismo lote>
--  - qty en canónica y qty_original/uom_original según UI (p.ej., PZ)

/* --------------------------------------------------------------
   J) Guardas e índices complementarios (seguridad y performance)
   -------------------------------------------------------------- */
-- Índice para políticas de stock lookup
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_stock_policy_item_suc' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_stock_policy_item_suc ON selemti.stock_policy(item_id, sucursal_id);
  END IF;
END$$;

-- Índice para modificadores en tickets (consulta por llave)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relname='ix_ticketdet_mods_gin' AND n.nspname='selemti'
  ) THEN
    CREATE INDEX ix_ticketdet_mods_gin ON selemti.ticket_venta_det 
    USING GIN (modificadores_aplicados);
  END IF;
END$$;

/* --------------------------------------------------------------
   K) Defaults razonables / semillas mínimas (opcional)
   -------------------------------------------------------------- */
-- FEFO como default para sucursal "PRINCIPAL" si no existe
INSERT INTO selemti.param_sucursal (sucursal_id, consumo)
SELECT 'PRINCIPAL', 'FEFO'
WHERE NOT EXISTS (SELECT 1 FROM selemti.param_sucursal WHERE sucursal_id='PRINCIPAL');

/* ======================================================================
   FIN 010.delta_full_plus.sql
   - Compatibilidad PG 9.5
   - No usa particiones ni funciones avanzadas de versión posterior.
   - Ejecutable múltiples veces sin romper consistencia.
   ====================================================================== */
