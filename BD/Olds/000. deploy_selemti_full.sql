-- =====================================================================
-- Selemti: Deploy Unificado (esquema, tipos, tablas, vistas, funciones)
-- Idempotente / Migration-Safe
-- Owner: postgres  |  TZ operativa: America/Mexico_City
-- Política consumo: FEFO (default) / PEPS por sucursal (parametrizable)
-- UOM base: GR (peso), ML (volumen), PZ (unidad)
-- =====================================================================

-- 0) Preámbulo
SET client_min_messages = WARNING;

-- Crear esquema
CREATE SCHEMA IF NOT EXISTS selemti AUTHORIZATION postgres;

-- Search path sugerido para aplicaciones:
--   ALTER ROLE selemti_user SET search_path = 'selemti, public';

-- Helper para crear ENUM si no existe (compatible 9.5+)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE t.typname='consumo_policy' AND n.nspname='selemti') THEN
    EXECUTE 'CREATE TYPE selemti.consumo_policy AS ENUM (''FEFO'',''PEPS'')';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE t.typname='lote_estado' AND n.nspname='selemti') THEN
    EXECUTE 'CREATE TYPE selemti.lote_estado AS ENUM (''ACTIVO'',''BLOQUEADO'',''RECALL'')';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE t.typname='mov_tipo' AND n.nspname='selemti') THEN
    EXECUTE 'CREATE TYPE selemti.mov_tipo AS ENUM (''RECEPCION'',''COMPRA'',''VENTA'',''CONSUMO_OP'',''AJUSTE'',''TRASPASO_IN'',''TRASPASO_OUT'',''ANULACION'')';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE t.typname='merma_tipo' AND n.nspname='selemti') THEN
    EXECUTE 'CREATE TYPE selemti.merma_tipo AS ENUM (''PROCESO'',''OPERATIVA'')';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE t.typname='op_estado' AND n.nspname='selemti') THEN
    EXECUTE 'CREATE TYPE selemti.op_estado AS ENUM (''ABIERTA'',''EN_PROCESO'',''CERRADA'',''ANULADA'')';
  END IF;
END$$;

-- 1) Catálogos de Unidades de Medida (UOM) y conversiones
CREATE TABLE IF NOT EXISTS selemti.unidad_medida (
  id SERIAL PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL,           -- 'GR','ML','PZ', etc.
  nombre TEXT NOT NULL,                  -- Gramo, Mililitro, Pieza...
  tipo TEXT NOT NULL CHECK (tipo IN ('PESO','VOLUMEN','UNIDAD','TIEMPO')),
  es_base BOOLEAN NOT NULL DEFAULT FALSE,
  factor_a_base NUMERIC(14,6) NOT NULL DEFAULT 1.0,
  decimales INT NOT NULL DEFAULT 2
);

INSERT INTO selemti.unidad_medida (codigo,nombre,tipo,es_base,factor_a_base,decimales)
VALUES
 ('GR','Gramo','PESO',TRUE,1,2),
 ('KG','Kilogramo','PESO',FALSE,1000,2),
 ('ML','Mililitro','VOLUMEN',TRUE,1,2),
 ('LT','Litro','VOLUMEN',FALSE,1000,2),
 ('PZ','Pieza','UNIDAD',TRUE,1,0),
 ('OZ','Onza','PESO',FALSE,28.3495,2),
 ('LB','Libra','PESO',FALSE,453.592,2)
ON CONFLICT (codigo) DO NOTHING;

CREATE TABLE IF NOT EXISTS selemti.uom_conversion (
  id SERIAL PRIMARY KEY,
  origen_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  destino_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  factor NUMERIC(14,6) NOT NULL CHECK (factor > 0),
  UNIQUE (origen_id, destino_id),
  CHECK (origen_id <> destino_id)
);

-- 2) Seguridad / Usuarios (propios) y mapeo a Floreant
CREATE TABLE IF NOT EXISTS selemti.rol (
  id SERIAL PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL, -- GERENTE, CHEF, ALMACEN, CAJERO, AUDITOR, SISTEMA
  nombre TEXT NOT NULL
);

INSERT INTO selemti.rol (codigo, nombre) VALUES
 ('GERENTE','Gerente'),('CHEF','Chef/Jefe Barra'),('ALMACEN','Almacén'),
 ('CAJERO','Cajero'),('AUDITOR','Auditor/APPCC'),('SISTEMA','Integración')
ON CONFLICT (codigo) DO NOTHING;

CREATE TABLE IF NOT EXISTS selemti.usuario (
  id BIGSERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  email TEXT,
  rol_id INT NOT NULL REFERENCES selemti.rol(id),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  password_hash TEXT,                     -- si aplica login nativo
  floreant_user_id INT,                   -- mapeo opcional a usuario POS
  meta JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 3) Parámetros por sucursal (políticas, tolerancias, etc.)
CREATE TABLE IF NOT EXISTS selemti.sucursal (
  id SERIAL PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'America/Mexico_City'
);

CREATE TABLE IF NOT EXISTS selemti.param_sucursal (
  id SERIAL PRIMARY KEY,
  sucursal_id INT NOT NULL REFERENCES selemti.sucursal(id),
  consumo_policy selemti.consumo_policy NOT NULL DEFAULT 'FEFO', -- per-sucursal
  tolerancia_caja_pct NUMERIC(6,3) NOT NULL DEFAULT 0.02,
  tolerancia_corte_abs NUMERIC(12,2) NOT NULL DEFAULT 50.00,
  alerta_caducidad_dias INT NOT NULL DEFAULT 7,
  UNIQUE (sucursal_id)
);

-- 4) Maestro de ítems (insumos y artículos vendibles)
-- Nota: si tus ítems maestros viven en 'public' (Floreant), aquí definimos uno propio
-- para insumos/estandarización. Puedes mapear artículos de venta con pos_map (abajo).
CREATE TABLE IF NOT EXISTS selemti.insumo (
  id BIGSERIAL PRIMARY KEY,
  sku TEXT UNIQUE,                         -- opcional
  nombre TEXT NOT NULL,
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  perecible BOOLEAN NOT NULL DEFAULT FALSE,
  merma_pct NUMERIC(6,3) NOT NULL DEFAULT 0.000,  -- AP->EP
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  meta JSONB
);

-- Presentaciones de compra por proveedor
CREATE TABLE IF NOT EXISTS selemti.insumo_presentacion (
  id BIGSERIAL PRIMARY KEY,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  proveedor_id INT,                        -- si mapeas a proveedor POS, usar FK NOT VALID
  um_compra_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  factor_a_um NUMERIC(14,6) NOT NULL DEFAULT 1.0, -- (UM compra -> UM uso)
  costo_ultimo NUMERIC(14,6) NOT NULL DEFAULT 0.0,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 5) Recetas (con versionado y congelamiento de costo)
CREATE TABLE IF NOT EXISTS selemti.receta (
  id BIGSERIAL PRIMARY KEY,
  codigo TEXT UNIQUE,
  nombre TEXT NOT NULL,
  porciones NUMERIC(12,4) NOT NULL DEFAULT 1.0,
  pvp_objetivo NUMERIC(12,4),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  meta JSONB
);

CREATE TABLE IF NOT EXISTS selemti.receta_version (
  id BIGSERIAL PRIMARY KEY,
  receta_id BIGINT NOT NULL REFERENCES selemti.receta(id),
  version INT NOT NULL,
  publicada BOOLEAN NOT NULL DEFAULT FALSE,
  vigente_desde TIMESTAMP,
  vigente_hasta TIMESTAMP,
  costo_congelado NUMERIC(14,6),        -- snapshot (opcional)
  algoritmo_costo TEXT DEFAULT 'WAC',   -- WAC/PEPS/UEPS/STD
  meta JSONB,
  UNIQUE (receta_id, version)
);

CREATE TABLE IF NOT EXISTS selemti.receta_insumo (
  id BIGSERIAL PRIMARY KEY,
  receta_version_id BIGINT NOT NULL REFERENCES selemti.receta_version(id),
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  cantidad NUMERIC(14,6) NOT NULL,
  UNIQUE (receta_version_id, insumo_id)
);

-- 6) POS Map: relación PLU / Modificadores ↔ Receta o Insumo
-- (soporta: a) PLU con receta, b) PLU sin receta, c) modificador con receta, d) modificador que descuenta insumo)
CREATE TABLE IF NOT EXISTS selemti.pos_map (
  id BIGSERIAL PRIMARY KEY,
  pos_system TEXT NOT NULL DEFAULT 'FLOREANT',
  plu TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('PLATO','MODIFICADOR','COMBO')),
  receta_version_id BIGINT,                     -- si aplica
  insumo_id BIGINT,                             -- si aplica (e.g., sabor=insumo, botella=PZ)
  factor_insumo NUMERIC(14,6) DEFAULT 1.0,      -- factor por unidad vendida
  vigente_desde TIMESTAMP NOT NULL DEFAULT now(),
  vigente_hasta TIMESTAMP,
  meta JSONB
);
CREATE INDEX IF NOT EXISTS ix_pos_map_plu ON selemti.pos_map (pos_system,plu,vigente_desde);

-- 7) Inventarios por Lote + Kardex unificado (mov_inv)
CREATE TABLE IF NOT EXISTS selemti.bodega (
  id SERIAL PRIMARY KEY,
  sucursal_id INT NOT NULL REFERENCES selemti.sucursal(id),
  codigo TEXT NOT NULL,
  nombre TEXT NOT NULL,
  UNIQUE (sucursal_id, codigo)
);

CREATE TABLE IF NOT EXISTS selemti.lote (
  id BIGSERIAL PRIMARY KEY,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  proveedor_id INT,
  codigo TEXT,
  caducidad DATE,
  estado selemti.lote_estado NOT NULL DEFAULT 'ACTIVO',
  creado_ts TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_lote_insumo ON selemti.lote (insumo_id);
CREATE INDEX IF NOT EXISTS ix_lote_cad ON selemti.lote (caducidad);

-- Kardex
CREATE TABLE IF NOT EXISTS selemti.mov_inv (
  id BIGSERIAL PRIMARY KEY,
  ts TIMESTAMP NOT NULL DEFAULT now(),
  sucursal_id INT REFERENCES selemti.sucursal(id),
  bodega_id INT REFERENCES selemti.bodega(id),
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  lote_id BIGINT REFERENCES selemti.lote(id),
  tipo selemti.mov_tipo NOT NULL,
  qty NUMERIC(14,6) NOT NULL,                    -- signo +/-
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  costo_unit NUMERIC(14,6),                      -- costo al momento
  ref_tipo TEXT,                                 -- TICKET, RECEPCION, OP, AJUSTE, etc.
  ref_id BIGINT,
  usuario_id BIGINT REFERENCES selemti.usuario(id),
  meta JSONB
);
CREATE INDEX IF NOT EXISTS ix_mov_ts ON selemti.mov_inv (ts);
CREATE INDEX IF NOT EXISTS ix_mov_insumo_ts ON selemti.mov_inv (insumo_id, ts DESC);
CREATE INDEX IF NOT EXISTS ix_mov_ref ON selemti.mov_inv (ref_tipo, ref_id);

-- Recepciones (perecibles con temperatura/evidencia)
CREATE TABLE IF NOT EXISTS selemti.recepcion_cab (
  id BIGSERIAL PRIMARY KEY,
  sucursal_id INT NOT NULL REFERENCES selemti.sucursal(id),
  proveedor_id INT,
  oc_ref TEXT,
  ts TIMESTAMP NOT NULL DEFAULT now(),
  usuario_id BIGINT REFERENCES selemti.usuario(id),
  meta JSONB
);

CREATE TABLE IF NOT EXISTS selemti.recepcion_det (
  id BIGSERIAL PRIMARY KEY,
  recepcion_id BIGINT NOT NULL REFERENCES selemti.recepcion_cab(id) ON DELETE CASCADE,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  bodega_id INT NOT NULL REFERENCES selemti.bodega(id),
  qty NUMERIC(14,6) NOT NULL,
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  costo_unit NUMERIC(14,6) NOT NULL,
  lote_id BIGINT REFERENCES selemti.lote(id),
  temperatura NUMERIC(6,2),
  doc_url TEXT,         -- evidencia
  meta JSONB
);

-- Traspasos
CREATE TABLE IF NOT EXISTS selemti.traspaso_cab (
  id BIGSERIAL PRIMARY KEY,
  from_bodega_id INT NOT NULL REFERENCES selemti.bodega(id),
  to_bodega_id INT NOT NULL REFERENCES selemti.bodega(id),
  ts TIMESTAMP NOT NULL DEFAULT now(),
  usuario_id BIGINT REFERENCES selemti.usuario(id),
  meta JSONB
);

CREATE TABLE IF NOT EXISTS selemti.traspaso_det (
  id BIGSERIAL PRIMARY KEY,
  traspaso_id BIGINT NOT NULL REFERENCES selemti.traspaso_cab(id) ON DELETE CASCADE,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  lote_id BIGINT REFERENCES selemti.lote(id),
  qty NUMERIC(14,6) NOT NULL,
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id)
);

-- Mermas
CREATE TABLE IF NOT EXISTS selemti.merma (
  id BIGSERIAL PRIMARY KEY,
  ts TIMESTAMP NOT NULL DEFAULT now(),
  tipo selemti.merma_tipo NOT NULL,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  lote_id BIGINT REFERENCES selemti.lote(id),
  op_id BIGINT,  -- si es PROCESO
  qty NUMERIC(14,6) NOT NULL,
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  usuario_id BIGINT REFERENCES selemti.usuario(id),
  motivo TEXT,
  meta JSONB
);

-- 8) Producción (OP) y yields
CREATE TABLE IF NOT EXISTS selemti.op_cab (
  id BIGSERIAL PRIMARY KEY,
  sucursal_id INT NOT NULL REFERENCES selemti.sucursal(id),
  receta_version_id BIGINT NOT NULL REFERENCES selemti.receta_version(id),
  cantidad_objetivo NUMERIC(14,6) NOT NULL,
  um_salida_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  estado selemti.op_estado NOT NULL DEFAULT 'ABIERTA',
  ts_apertura TIMESTAMP NOT NULL DEFAULT now(),
  ts_cierre TIMESTAMP,
  usuario_abre BIGINT REFERENCES selemti.usuario(id),
  usuario_cierra BIGINT REFERENCES selemti.usuario(id),
  lote_salida_id BIGINT, -- lote interno generado al cierre
  meta JSONB
);

CREATE TABLE IF NOT EXISTS selemti.op_insumo (
  id BIGSERIAL PRIMARY KEY,
  op_id BIGINT NOT NULL REFERENCES selemti.op_cab(id) ON DELETE CASCADE,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  qty_teorica NUMERIC(14,6) NOT NULL,
  qty_real NUMERIC(14,6),
  um_id INT NOT NULL REFERENCES selemti.unidad_medida(id),
  lote_id BIGINT,              -- lote consumido
  meta JSONB
);

CREATE TABLE IF NOT EXISTS selemti.op_yield (
  op_id BIGINT PRIMARY KEY REFERENCES selemti.op_cab(id) ON DELETE CASCADE,
  cantidad_real NUMERIC(14,6) NOT NULL,
  merma_real NUMERIC(14,6) NOT NULL DEFAULT 0,
  evidencia_url TEXT,
  meta JSONB
);

-- 9) Históricos de costos (ítem y receta) y capas (para PEPS)
CREATE TABLE IF NOT EXISTS selemti.cost_layer (
  id BIGSERIAL PRIMARY KEY,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  lote_id BIGINT REFERENCES selemti.lote(id),
  ts_in TIMESTAMP NOT NULL,
  qty_in NUMERIC(14,6) NOT NULL,
  qty_left NUMERIC(14,6) NOT NULL,
  unit_cost NUMERIC(14,6) NOT NULL,
  sucursal_id INT REFERENCES selemti.sucursal(id),
  source_ref TEXT,
  source_id BIGINT
);
CREATE INDEX IF NOT EXISTS ix_layer_insumo ON selemti.cost_layer (insumo_id, ts_in);

CREATE TABLE IF NOT EXISTS selemti.hist_cost_insumo (
  id BIGSERIAL PRIMARY KEY,
  insumo_id BIGINT NOT NULL REFERENCES selemti.insumo(id),
  fecha_efectiva DATE NOT NULL,
  costo_wac NUMERIC(14,6),
  costo_peps NUMERIC(14,6),
  costo_ueps NUMERIC(14,6),
  costo_std NUMERIC(14,6),
  algoritmo_principal TEXT DEFAULT 'WAC',
  valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
  valid_to DATE,
  sys_from TIMESTAMP NOT NULL DEFAULT now(),
  sys_to TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_hist_cost_insumo ON selemti.hist_cost_insumo (insumo_id, fecha_efectiva, COALESCE(valid_to,'9999-12-31'));

CREATE TABLE IF NOT EXISTS selemti.hist_cost_receta (
  id BIGSERIAL PRIMARY KEY,
  receta_version_id BIGINT NOT NULL REFERENCES selemti.receta_version(id),
  fecha_calculo DATE NOT NULL,
  costo_total NUMERIC(14,6),
  costo_porcion NUMERIC(14,6),
  algoritmo_utilizado TEXT DEFAULT 'WAC',
  valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
  valid_to DATE,
  sys_from TIMESTAMP NOT NULL DEFAULT now(),
  sys_to TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_hist_cost_receta ON selemti.hist_cost_receta (receta_version_id, fecha_calculo);

-- 10) Funciones clave (stubs seguros) -----------------------------

-- Política de selección de lote (FEFO/PEPS)
CREATE OR REPLACE FUNCTION selemti.pick_lotes(
  p_insumo_id BIGINT,
  p_sucursal_id INT,
  p_bodega_id INT,
  p_qty NUMERIC,
  p_policy selemti.consumo_policy DEFAULT 'FEFO'
) RETURNS TABLE(lote_id BIGINT, qty NUMERIC) AS $$
BEGIN
  -- FEFO: ordenar por caducidad asc; PEPS: por ts_in asc vía cost_layer o primer lote
  IF p_policy = 'FEFO' THEN
    RETURN QUERY
      SELECT l.id, LEAST(p_qty - COALESCE(SUM(m.qty) FILTER (WHERE 1=1),0), 0)::NUMERIC
      FROM selemti.lote l
      JOIN LATERAL (
        SELECT COALESCE(SUM(CASE WHEN mi.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN') THEN mi.qty
                                 WHEN mi.tipo IN ('VENTA','CONSUMO_OP','AJUSTE','TRASPASO_OUT','ANULACION') THEN -mi.qty
                            END),0) qty_disp
        FROM selemti.mov_inv mi
        WHERE mi.lote_id = l.id
      ) s ON true
      WHERE l.insumo_id = p_insumo_id
        AND l.estado='ACTIVO'
      ORDER BY l.caducidad NULLS LAST, l.id
      LIMIT 0; -- (stub para demo; implementar cálculo por partes)
  ELSE
    RETURN QUERY SELECT NULL::BIGINT, 0::NUMERIC LIMIT 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Ingesta de ticket POS → Descargo inventario (con PLU y modificadores)
CREATE OR REPLACE FUNCTION selemti.ingesta_ticket(
  p_ticket_id BIGINT,
  p_sucursal_id INT,
  p_bodega_id INT,
  p_usuario_id BIGINT
) RETURNS VOID AS $$
DECLARE
  r RECORD;
  v_policy selemti.consumo_policy;
BEGIN
  SELECT consumo_policy INTO v_policy
  FROM selemti.param_sucursal WHERE sucursal_id = p_sucursal_id;

  FOR r IN
    SELECT ti.id as ticket_item_id, ti.plu, ti.qty, ti.precio,
           pm.tipo, pm.receta_version_id, pm.insumo_id, pm.factor_insumo
    FROM public.ticket_item ti
    LEFT JOIN LATERAL (
      SELECT * FROM selemti.pos_map
      WHERE pos_system='FLOREANT' AND plu = ti.plu
        AND (vigente_hasta IS NULL OR vigente_hasta >= ti.created) -- ajustar campo fecha POS
      ORDER BY vigente_desde DESC
      LIMIT 1
    ) pm ON true
    WHERE ti.ticket_id = p_ticket_id
  LOOP
    IF r.receta_version_id IS NOT NULL THEN
      -- Descargo por receta
      INSERT INTO selemti.mov_inv(ts,sucursal_id,bodega_id,insumo_id,lote_id,tipo,qty,um_id,costo_unit,ref_tipo,ref_id,usuario_id)
      SELECT now(), p_sucursal_id, p_bodega_id, ri.insumo_id, NULL, 'VENTA',
             (ri.cantidad * r.qty) * -1, u.id, NULL, 'TICKET', r.ticket_item_id, p_usuario_id
      FROM selemti.receta_insumo ri
      JOIN selemti.insumo i ON i.id=ri.insumo_id
      JOIN selemti.unidad_medida u ON u.id=i.um_id
      WHERE ri.receta_version_id = r.receta_version_id;
    ELSIF r.insumo_id IS NOT NULL THEN
      -- Descargo directo de insumo (ej. botella PZ, sabor como insumo)
      INSERT INTO selemti.mov_inv(ts,sucursal_id,bodega_id,insumo_id,lote_id,tipo,qty,um_id,costo_unit,ref_tipo,ref_id,usuario_id)
      SELECT now(), p_sucursal_id, p_bodega_id, r.insumo_id, NULL, 'VENTA',
             (COALESCE(r.factor_insumo,1) * r.qty) * -1, i.um_id, NULL, 'TICKET', r.ticket_item_id, p_usuario_id
      FROM selemti.insumo i WHERE i.id=r.insumo_id;
    ELSE
      -- Sin impacto inventario (ej. servicio)
      CONTINUE;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Reproceso de costos históricos (WAC baseline; ampliable a PEPS)
CREATE OR REPLACE FUNCTION selemti.recalcular_costos_periodo(
  p_desde DATE,
  p_hasta DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
  v_cnt INT := 0;
BEGIN
  -- Ejemplo simple: recalcular costo WAC por insumo en rango (extensible)
  INSERT INTO selemti.hist_cost_insumo (insumo_id,fecha_efectiva,costo_wac,algoritmo_principal)
  SELECT mi.insumo_id, p_desde,
         CASE WHEN SUM(CASE WHEN mi.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN') THEN (mi.costo_unit * mi.qty) ELSE 0 END) <> 0
              THEN SUM(CASE WHEN mi.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN') THEN (mi.costo_unit * mi.qty) ELSE 0 END)
                   / NULLIF(SUM(CASE WHEN mi.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN') THEN mi.qty ELSE 0 END),0)
              ELSE NULL END,
         'WAC'
  FROM selemti.mov_inv mi
  WHERE mi.ts::date BETWEEN p_desde AND p_hasta
  GROUP BY mi.insumo_id
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_cnt = ROW_COUNT;
  RETURN v_cnt;
END;
$$ LANGUAGE plpgsql;

-- 11) Vistas útiles (ingeniería de menú, existencias por lote, trazabilidad)
CREATE OR REPLACE VIEW selemti.v_existencias_lote AS
SELECT
  l.id AS lote_id, l.insumo_id, i.nombre AS insumo,
  SUM(CASE WHEN m.tipo IN ('RECEPCION','COMPRA','TRASPASO_IN') THEN m.qty
           WHEN m.tipo IN ('VENTA','CONSUMO_OP','AJUSTE','TRASPASO_OUT','ANULACION') THEN -m.qty
      END) AS qty_disponible,
  l.caducidad, l.estado
FROM selemti.lote l
LEFT JOIN selemti.mov_inv m ON m.lote_id = l.id
JOIN selemti.insumo i ON i.id = l.insumo_id
GROUP BY l.id,i.nombre;

CREATE OR REPLACE VIEW selemti.v_trazabilidad_ticket AS
SELECT
  m.ref_id AS ticket_item_id, m.insumo_id, i.nombre AS insumo, m.qty, m.ts, m.lote_id
FROM selemti.mov_inv m
JOIN selemti.insumo i ON i.id=m.insumo_id
WHERE m.ref_tipo='TICKET';

-- 12) Roles y permisos sugeridos
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='selemti_user') THEN
    CREATE ROLE selemti_user LOGIN;
  END IF;
END$$;

GRANT USAGE ON SCHEMA selemti TO selemti_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA selemti TO selemti_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA selemti GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO selemti_user;

-- =====================================================================
-- Fin deploy_selemti_full.sql
-- Notas:
--  * La función pick_lotes es un stub: puedes implementar el reparto por FEFO/PEPS.
--  * ingesta_ticket asume public.ticket_item con campos (plu, qty, created, ticket_id).
--  * Completa FKs a 'public' con NOT VALID si quieres validación suave.
--  * Agrega índices a demanda según volumen.
-- =====================================================================
