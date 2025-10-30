
-- =====================================================================
--  Selemti · Despliegue Inventarios — PostgreSQL 9.5 (CONSOLIDADO FINAL)
--  * Idempotente para ambientes limpios o parcialmente creados
--  * Incluye: orden de creación correcto, índices únicos parciales,
--    vistas estables (casts) y triggers al final.
---
--- # Deploy (tu ruta y puerto, como vienes usando)
---	.\psql -h localhost -p 5433 -U postgres -d pos -f "D:\Tavo\2025\UX\Inventarios\v3\selemti_deploy_inventarios_PG95_CONSOLIDADO_FINAL.sql"

---
-- =====================================================================

-- 0) Esquema
CREATE SCHEMA IF NOT EXISTS selemti;

-- 1) Tipos ENUM (crear solo si no existen)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='lot_tracking') THEN
    CREATE TYPE selemti.lot_tracking AS ENUM ('NONE','OPTIONAL','REQUIRED');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='estado_compra') THEN
    CREATE TYPE selemti.estado_compra AS ENUM ('DRAFT','SENT','PARTIAL','RECEIVED','CLOSED','CANCELLED');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='estado_recepcion') THEN
    CREATE TYPE selemti.estado_recepcion AS ENUM ('PENDING','APPROVED','POSTED');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='estado_traspaso') THEN
    CREATE TYPE selemti.estado_traspaso AS ENUM ('PENDING','IN_TRANSIT','RECEIVED','CLOSED','CANCELLED');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='estatus_produccion') THEN
    CREATE TYPE selemti.estatus_produccion AS ENUM ('PLANNED','APPROVED','IN_PROCESS','CLOSED','ADJUSTED');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='tipo_mov_inv') THEN
    CREATE TYPE selemti.tipo_mov_inv AS ENUM ('COMPRA','RECEPCION','TRANSFER_OUT','TRANSFER_IN','PROD_OUT','PROD_IN','VENTA_TEO','AJUSTE','MERMA');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='merma_categoria') THEN
    CREATE TYPE selemti.merma_categoria AS ENUM ('PREPARACION','CADUCIDAD','ROTURA','ROBO','OTRA');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typnamespace='selemti'::regnamespace AND typname='nivel_aut') THEN
    CREATE TYPE selemti.nivel_aut AS ENUM ('NINGUNO','ENCARGADO','SUPERVISOR','ADMIN');
  END IF;
END $$;

-- 2) Tablas núcleo (orden seguro para FK)
CREATE TABLE IF NOT EXISTS selemti.item_vendor (
  item_id                INT      NOT NULL REFERENCES public.inventory_item(id),
  vendor_id              INT      NOT NULL REFERENCES public.inventory_vendor(id),
  presentacion           TEXT     NOT NULL,
  unidad_presentacion_id INT      NOT NULL REFERENCES public.inventory_unit(id),
  factor_a_canonica      NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),
  costo_ultimo           NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (costo_ultimo >= 0),
  moneda                 TEXT     NOT NULL DEFAULT 'MXN',
  lead_time_dias         INT,
  codigo_proveedor       TEXT,
  lot_tracking           selemti.lot_tracking NOT NULL DEFAULT 'NONE',
  perishable             BOOLEAN  NOT NULL DEFAULT FALSE,
  shelf_life_days        INT CHECK (shelf_life_days IS NULL OR shelf_life_days >= 0),
  activo                 BOOLEAN  NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_item_vendor PRIMARY KEY (item_id, vendor_id, presentacion)
);

CREATE TABLE IF NOT EXISTS selemti.compra (
  id            BIGSERIAL PRIMARY KEY,
  folio         TEXT,
  vendor_id     INT      NOT NULL REFERENCES public.inventory_vendor(id),
  fecha         TIMESTAMP NOT NULL DEFAULT now(),
  estado        selemti.estado_compra NOT NULL DEFAULT 'DRAFT',
  moneda        TEXT     NOT NULL DEFAULT 'MXN',
  tipo_cambio   NUMERIC(12,6) NOT NULL DEFAULT 1 CHECK (tipo_cambio > 0),
  subtotal      NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  impuestos     NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (impuestos >= 0),
  total         NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (total >= 0),
  notas         TEXT,
  creado_por    INT      NOT NULL,
  aprobado_por  INT,
  sucursal_id   INT REFERENCES public.inventory_location(id)
);
CREATE INDEX IF NOT EXISTS ix_compra_vendor   ON selemti.compra(vendor_id);
CREATE INDEX IF NOT EXISTS ix_compra_sucursal ON selemti.compra(sucursal_id);

CREATE TABLE IF NOT EXISTS selemti.compra_det (
  id                     BIGSERIAL PRIMARY KEY,
  compra_id              BIGINT   NOT NULL REFERENCES selemti.compra(id) ON DELETE CASCADE,
  item_id                INT      NOT NULL REFERENCES public.inventory_item(id),
  cant_presentacion      NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (cant_presentacion >= 0),
  unidad_presentacion_id INT      NOT NULL REFERENCES public.inventory_unit(id),
  factor_a_canonica      NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),
  cant_canonica          NUMERIC(14,6) NOT NULL DEFAULT 0,
  precio_unit            NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (precio_unit >= 0),
  impuestos              NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (impuestos >= 0),
  descuento              NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
  location_id            INT REFERENCES public.inventory_location(id)
);
CREATE INDEX IF NOT EXISTS ix_compra_det_compra ON selemti.compra_det(compra_id);
CREATE INDEX IF NOT EXISTS ix_compra_det_item   ON selemti.compra_det(item_id);

-- INVENTORY BATCH debe existir ANTES de recepcion_det por FK
CREATE TABLE IF NOT EXISTS selemti.inventory_batch (
  id             BIGSERIAL PRIMARY KEY,
  item_id        INT    NOT NULL REFERENCES public.inventory_item(id),
  lote           TEXT   NOT NULL,
  caducidad      DATE,
  location_id    INT    NOT NULL REFERENCES public.inventory_location(id),
  qty_disponible NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (qty_disponible >= 0),
  CONSTRAINT uq_batch UNIQUE (item_id, location_id, lote)
);
CREATE INDEX IF NOT EXISTS ix_batch_item ON selemti.inventory_batch(item_id);

CREATE TABLE IF NOT EXISTS selemti.recepcion (
  id            BIGSERIAL PRIMARY KEY,
  compra_id     BIGINT REFERENCES selemti.compra(id),
  fecha         TIMESTAMP NOT NULL DEFAULT now(),
  estado        selemti.estado_recepcion NOT NULL DEFAULT 'PENDING',
  incidencias   TEXT,
  creado_por    INT NOT NULL,
  aprobado_por  INT
);

CREATE TABLE IF NOT EXISTS selemti.recepcion_det (
  id                        BIGSERIAL PRIMARY KEY,
  recepcion_id              BIGINT NOT NULL REFERENCES selemti.recepcion(id) ON DELETE CASCADE,
  item_id                   INT    NOT NULL REFERENCES public.inventory_item(id),
  cant_recibida_canonica    NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (cant_recibida_canonica >= 0),
  batch_id                  BIGINT,
  caducidad                 DATE,
  location_id               INT    NOT NULL REFERENCES public.inventory_location(id),
  rechazo_motivo            TEXT,
  CONSTRAINT fk_recepcion_det_batch FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX IF NOT EXISTS ix_recepcion_det_recepcion ON selemti.recepcion_det(recepcion_id);
CREATE INDEX IF NOT EXISTS ix_recepcion_det_item      ON selemti.recepcion_det(item_id);

CREATE TABLE IF NOT EXISTS selemti.traspaso (
  id                   BIGSERIAL PRIMARY KEY,
  fecha                TIMESTAMP NOT NULL DEFAULT now(),
  folio                TEXT,
  estado               selemti.estado_traspaso NOT NULL DEFAULT 'PENDING',
  origen_location_id   INT NOT NULL REFERENCES public.inventory_location(id),
  destino_location_id  INT NOT NULL REFERENCES public.inventory_location(id),
  motivo               TEXT,
  notas                TEXT,
  creado_por           INT NOT NULL,
  aprobado_por         INT,
  sucursal_id          INT REFERENCES public.inventory_location(id)
);
CREATE INDEX IF NOT EXISTS ix_traspaso_origen   ON selemti.traspaso(origen_location_id);
CREATE INDEX IF NOT EXISTS ix_traspaso_destino  ON selemti.traspaso(destino_location_id);
CREATE INDEX IF NOT EXISTS ix_traspaso_sucursal ON selemti.traspaso(sucursal_id);

CREATE TABLE IF NOT EXISTS selemti.traspaso_det (
  id           BIGSERIAL PRIMARY KEY,
  traspaso_id  BIGINT NOT NULL REFERENCES selemti.traspaso(id) ON DELETE CASCADE,
  item_id      INT    NOT NULL REFERENCES public.inventory_item(id),
  qty_canonica NUMERIC(14,6) NOT NULL CHECK (qty_canonica >= 0)
);
CREATE INDEX IF NOT EXISTS ix_traspaso_det_item ON selemti.traspaso_det(item_id);

CREATE TABLE IF NOT EXISTS selemti.produccion (
  id           BIGSERIAL PRIMARY KEY,
  fecha        TIMESTAMP NOT NULL DEFAULT now(),
  location_id  INT NOT NULL REFERENCES public.inventory_location(id),
  estatus      selemti.estatus_produccion NOT NULL DEFAULT 'PLANNED',
  notas        TEXT,
  creado_por   INT NOT NULL,
  aprobado_por INT
);

CREATE TABLE IF NOT EXISTS selemti.produccion_insumo (
  id             BIGSERIAL PRIMARY KEY,
  produccion_id  BIGINT NOT NULL REFERENCES selemti.produccion(id) ON DELETE CASCADE,
  item_id        INT    NOT NULL REFERENCES public.inventory_item(id),
  qty_canonica   NUMERIC(14,6) NOT NULL CHECK (qty_canonica >= 0),
  merma_pct      NUMERIC(6,3)  CHECK (merma_pct IS NULL OR merma_pct >= 0)
);
CREATE INDEX IF NOT EXISTS ix_prod_insumo_item ON selemti.produccion_insumo(item_id);

CREATE TABLE IF NOT EXISTS selemti.produccion_resultado (
  id                  BIGSERIAL PRIMARY KEY,
  produccion_id       BIGINT NOT NULL REFERENCES selemti.produccion(id) ON DELETE CASCADE,
  item_id             INT    NOT NULL REFERENCES public.inventory_item(id),
  qty_ok_canonica     NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (qty_ok_canonica >= 0),
  qty_merma_canonica  NUMERIC(14,6) NOT NULL DEFAULT 0 CHECK (qty_merma_canonica >= 0)
);
CREATE INDEX IF NOT EXISTS ix_prod_resultado_item ON selemti.produccion_resultado(item_id);

CREATE TABLE IF NOT EXISTS selemti.mov_inv (
  id           BIGSERIAL PRIMARY KEY,
  ts           TIMESTAMP NOT NULL DEFAULT now(),
  tipo         selemti.tipo_mov_inv NOT NULL,
  ref_table    TEXT,
  ref_id       BIGINT,
  item_id      INT    NOT NULL REFERENCES public.inventory_item(id),
  qty_canonica NUMERIC(14,6) NOT NULL,
  unidad       TEXT   NOT NULL CHECK (unidad IN ('g','ml','pz')),
  location_id  INT REFERENCES public.inventory_location(id),
  batch_id     BIGINT,
  costo_unit   NUMERIC(14,6),
  comentario   TEXT,
  user_id      INT,
  role         TEXT,
  merma_cat    selemti.merma_categoria,
  autorizado_por INT,
  CONSTRAINT fk_mov_batch FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id) DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT chk_merma_cat_required CHECK ( (tipo <> 'MERMA') OR (merma_cat IS NOT NULL) )
);
CREATE INDEX IF NOT EXISTS ix_mov_item_ts         ON selemti.mov_inv(item_id, ts);
CREATE INDEX IF NOT EXISTS ix_mov_tipo_ts         ON selemti.mov_inv(tipo, ts);
CREATE INDEX IF NOT EXISTS ix_mov_inv_item_loc    ON selemti.mov_inv(item_id, location_id);
CREATE INDEX IF NOT EXISTS ix_mov_inv_loc_ts      ON selemti.mov_inv(location_id, ts);
CREATE INDEX IF NOT EXISTS ix_mov_inv_tipo_itemts ON selemti.mov_inv(tipo, item_id, ts DESC);

CREATE TABLE IF NOT EXISTS selemti.pos_ingesta (
  id             BIGSERIAL PRIMARY KEY,
  last_ticket_id BIGINT,
  last_close_ts  TIMESTAMP,
  updated_at     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS selemti.costo_item (
  item_id    INT PRIMARY KEY REFERENCES public.inventory_item(id),
  wac        NUMERIC(14,6) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 2.1) conversion_template (sin UNIQUE con expresiones; índices parciales abajo)
CREATE TABLE IF NOT EXISTS selemti.conversion_template (
  id                       BIGSERIAL PRIMARY KEY,
  item_id                  INT REFERENCES public.inventory_item(id),
  vendor_id                INT REFERENCES public.inventory_vendor(id),
  presentacion             TEXT NOT NULL,
  unidad_presentacion_id   INT NOT NULL REFERENCES public.inventory_unit(id),
  unidad_canonica          TEXT NOT NULL CHECK (unidad_canonica IN ('g','ml','pz')),
  factor_a_canonica        NUMERIC(14,6) NOT NULL CHECK (factor_a_canonica > 0),
  preferred                BOOLEAN NOT NULL DEFAULT FALSE,
  activo                   BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2.2) Motor de alertas
CREATE TABLE IF NOT EXISTS selemti.alert_event (
  id           BIGSERIAL PRIMARY KEY,
  ts           TIMESTAMP NOT NULL DEFAULT now(),
  item_id      INT NOT NULL REFERENCES public.inventory_item(id),
  vendor_id    INT NULL REFERENCES public.inventory_vendor(id),
  source       TEXT NOT NULL,
  context_id   BIGINT NULL,
  old_cost     NUMERIC(14,6) NULL,
  new_cost     NUMERIC(14,6) NULL,
  delta_pct    NUMERIC(10,6) NULL,
  delta_abs    NUMERIC(14,6) NULL,
  currency     TEXT NOT NULL DEFAULT 'MXN',
  message      TEXT
);
CREATE INDEX IF NOT EXISTS ix_alert_event_item_ts ON selemti.alert_event(item_id, ts DESC);

CREATE TABLE IF NOT EXISTS selemti.alert_rule (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  metric_key TEXT NOT NULL,
  expr JSONB NOT NULL,
  scope JSONB,
  cooldown_min INT NOT NULL DEFAULT 1440,
  severity TEXT NOT NULL DEFAULT 'WARN',
  channels JSONB NOT NULL DEFAULT '{"pg_notify":true}'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS selemti.alert_cfg (
  id BIGSERIAL PRIMARY KEY,
  metric_key TEXT NOT NULL,
  defaults JSONB NOT NULL,
  scope JSONB
);

CREATE TABLE IF NOT EXISTS selemti.alert_subscription (
  id BIGSERIAL PRIMARY KEY,
  role TEXT,
  user_id INT,
  severity_min TEXT NOT NULL DEFAULT 'WARN',
  filters JSONB,
  channels JSONB NOT NULL DEFAULT '{"pg_notify":true}'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS selemti.alert_silence (
  id BIGSERIAL PRIMARY KEY,
  until_ts TIMESTAMP NOT NULL,
  scope JSONB,
  reason TEXT
);

CREATE TABLE IF NOT EXISTS selemti.alert_template (
  id BIGSERIAL PRIMARY KEY,
  metric_key TEXT NOT NULL,
  severity TEXT NOT NULL,
  title_tpl TEXT NOT NULL,
  body_tpl TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_template_metric_sev ON selemti.alert_template(metric_key, severity);

-- 2.3) Políticas de merma y preferencias UI
CREATE TABLE IF NOT EXISTS selemti.merma_policy (
  id           BIGSERIAL PRIMARY KEY,
  sucursal_id  INT NULL REFERENCES public.inventory_location(id),
  categoria    selemti.merma_categoria NOT NULL,
  th_warn      NUMERIC(14,2) NOT NULL DEFAULT 0,
  th_block     NUMERIC(14,2) NOT NULL DEFAULT 0,
  aut_req      selemti.nivel_aut NOT NULL DEFAULT 'SUPERVISOR',
  enabled      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS selemti.ui_prefs (
  id           BIGSERIAL PRIMARY KEY,
  sucursal_id  INT NULL REFERENCES public.inventory_location(id),
  key          TEXT NOT NULL,
  value_json   JSONB NOT NULL
);

-- 2.4) Modificadores en BOM
CREATE TABLE IF NOT EXISTS selemti.bom_modifier (
  id BIGSERIAL PRIMARY KEY,
  modifier_id INT NOT NULL,
  inventory_item_id INT NOT NULL REFERENCES public.inventory_item(id),
  qty_canonica NUMERIC(14,6) NOT NULL CHECK (qty_canonica >= 0),
  op TEXT NOT NULL DEFAULT 'ADD',
  scope JSONB
);

-- 2.x) ÍNDICES ÚNICOS PARCIALES
CREATE UNIQUE INDEX IF NOT EXISTS uq_conv_template_item_pres_null_vendor
  ON selemti.conversion_template(item_id, presentacion)
  WHERE vendor_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_conv_template_item_vendor_pres
  ON selemti.conversion_template(item_id, vendor_id, presentacion)
  WHERE vendor_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_null_scope
  ON selemti.alert_cfg(metric_key)
  WHERE scope IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_scope
  ON selemti.alert_cfg(metric_key, scope)
  WHERE scope IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_categoria_global
  ON selemti.merma_policy(categoria)
  WHERE sucursal_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_sucursal_categoria
  ON selemti.merma_policy(sucursal_id, categoria)
  WHERE sucursal_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_key_global
  ON selemti.ui_prefs(key)
  WHERE sucursal_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_sucursal_key
  ON selemti.ui_prefs(sucursal_id, key)
  WHERE sucursal_id IS NOT NULL;

-- 3) Vistas
CREATE OR REPLACE VIEW selemti.vw_stock_disponible AS
SELECT
  mi.item_id,
  mi.location_id,
  mi.batch_id,
  SUM(CASE
        WHEN mi.tipo IN ('COMPRA','RECEPCION','TRANSFER_IN','PROD_IN') THEN mi.qty_canonica
        WHEN mi.tipo IN ('TRANSFER_OUT','PROD_OUT','VENTA_TEO','AJUSTE','MERMA') THEN -mi.qty_canonica
        ELSE 0
      END) AS qty_disponible
FROM selemti.mov_inv mi
GROUP BY mi.item_id, mi.location_id, mi.batch_id;

 vw_bom_menu_item con casts explícitos y formato exacto
DROP VIEW IF EXISTS selemti.vw_bom_menu_item;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='menu_item')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='recepie')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='recepie_item') THEN

    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT
        mi.id::INT                             AS menu_item_id,
        mi.name::TEXT                          AS menu_item_name,
        r.id::INT                              AS recepie_id,
        ri.inventory_item::INT                 AS inventory_item_id,
        ri.percentage::NUMERIC(14,6)           AS percentage
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id;
    $SQL$;

  ELSE
    -- Placeholder si faltan tablas públicas
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT NULL::INT AS menu_item_id, NULL::TEXT AS menu_item_name,
             NULL::INT AS recepie_id, NULL::INT AS inventory_item_id,
             NULL::NUMERIC(14,6) AS percentage
      WHERE FALSE;
    $SQL$;
  END IF;
END $$;

  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='menu_item')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie_item') THEN
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT
        mi.id::int                             AS menu_item_id,
        mi.name::text                          AS menu_item_name,
        r.id::int                              AS recepie_id,
        ri.inventory_item::int                 AS inventory_item_id,
        CAST(ri.percentage AS numeric(14,6))   AS percentage
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id;
    $SQL$;
  ELSE
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT NULL::int AS menu_item_id, NULL::text AS menu_item_name,
             NULL::int AS recepie_id, NULL::int AS inventory_item_id,
             NULL::numeric(14,6) AS percentage
      WHERE FALSE;
    $SQL$;
  END IF;
END $$;

-- 2) vw_conversion_sugerida con ORDER BY en el mismo orden del DISTINCT ON
DROP VIEW IF EXISTS selemti.vw_conversion_sugerida;

CREATE VIEW selemti.vw_conversion_sugerida AS
SELECT DISTINCT ON (ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion)
  ct.item_id,
  ct.vendor_id,
  ct.presentacion,
  ct.unidad_presentacion_id,
  ct.unidad_canonica,
  ct.factor_a_canonica,
  ct.preferred
FROM selemti.conversion_template ct
WHERE ct.activo = TRUE
ORDER BY
  ct.item_id,
  COALESCE(ct.vendor_id,-1),
  ct.presentacion,
  ct.preferred DESC,
  ct.id DESC;

-- 4) Funciones
CREATE OR REPLACE FUNCTION selemti.fn_recalcula_wac(p_item_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_wac NUMERIC(14,6) := 0;
  v_stock NUMERIC(14,6) := 0;
  r RECORD;
BEGIN
  FOR r IN
    SELECT ts, tipo, qty_canonica, costo_unit
    FROM selemti.mov_inv
    WHERE item_id = p_item_id
    ORDER BY ts ASC, id ASC
  LOOP
    IF r.tipo IN ('RECEPCION','PROD_IN','TRANSFER_IN') THEN
      IF r.costo_unit IS NOT NULL AND r.qty_canonica > 0 THEN
        v_wac := CASE
          WHEN v_stock <= 0 THEN r.costo_unit
          ELSE ((v_wac * v_stock) + (r.costo_unit * r.qty_canonica)) / NULLIF(v_stock + r.qty_canonica,0)
        END;
      END IF;
      v_stock := v_stock + r.qty_canonica;
    ELSIF r.tipo IN ('TRANSFER_OUT','PROD_OUT','VENTA_TEO','AJUSTE','MERMA') THEN
      v_stock := v_stock - ABS(r.qty_canonica);
    END IF;
  END LOOP;

  INSERT INTO selemti.costo_item(item_id, wac, updated_at)
  VALUES (p_item_id, COALESCE(v_wac,0), now())
  ON CONFLICT (item_id) DO UPDATE SET wac = EXCLUDED.wac, updated_at = now();
END; $$;

CREATE OR REPLACE FUNCTION selemti.fn_generar_movimientos_por_documento(p_ref_table TEXT, p_ref_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  RAISE NOTICE 'TODO: generar movimientos para %.%', p_ref_table, p_ref_id;
END; $$;

CREATE OR REPLACE FUNCTION selemti.fn_ingesta_ventas(p_from_ts TIMESTAMP, p_to_ts TIMESTAMP)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  RAISE NOTICE 'TODO: leer tickets cerrados en rango [% .. %] y generar VENTA_TEO', p_from_ts, p_to_ts;
END; $$;

CREATE OR REPLACE FUNCTION selemti.fn_wac_apply(p_item_id INT, p_qty_in NUMERIC, p_cost_unit NUMERIC)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_stock   NUMERIC(14,6) := 0;
  v_old_wac NUMERIC(14,6) := 0;
  v_new_wac NUMERIC(14,6) := 0;
BEGIN
  IF p_qty_in IS NULL OR p_qty_in <= 0 OR p_cost_unit IS NULL THEN RETURN; END IF;

  SELECT COALESCE(SUM(CASE
           WHEN tipo IN ('COMPRA','RECEPCION','TRANSFER_IN','PROD_IN') THEN qty_canonica
           WHEN tipo IN ('TRANSFER_OUT','PROD_OUT','VENTA_TEO','AJUSTE','MERMA') THEN -qty_canonica
           ELSE 0 END), 0)
    INTO v_stock
  FROM selemti.mov_inv
  WHERE item_id = p_item_id;

  SELECT wac INTO v_old_wac FROM selemti.costo_item WHERE item_id=p_item_id FOR UPDATE;
  IF NOT FOUND THEN
    v_old_wac := 0;
    INSERT INTO selemti.costo_item(item_id, wac) VALUES (p_item_id, 0)
    ON CONFLICT (item_id) DO NOTHING;
  END IF;

  IF v_stock <= 0 THEN
    v_new_wac := p_cost_unit;
  ELSE
    v_new_wac := ((v_old_wac * v_stock) + (p_cost_unit * p_qty_in)) / NULLIF(v_stock + p_qty_in, 0);
  END IF;

  UPDATE selemti.costo_item SET wac = COALESCE(v_new_wac, p_cost_unit), updated_at = now() WHERE item_id = p_item_id;
END; $$;

-- 5) Triggers
CREATE OR REPLACE FUNCTION selemti.trg_recepcion_after_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.estado = 'POSTED' AND OLD.estado IS DISTINCT FROM 'POSTED' THEN
    PERFORM selemti.fn_generar_movimientos_por_documento('recepcion', NEW.id);
  END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_recepcion_after_update ON selemti.recepcion;
CREATE TRIGGER trg_recepcion_after_update
AFTER UPDATE ON selemti.recepcion
FOR EACH ROW EXECUTE PROCEDURE selemti.trg_recepcion_after_update();

CREATE OR REPLACE FUNCTION selemti.trg_pos_ingesta_after_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  PERFORM selemti.fn_ingesta_ventas(COALESCE(NEW.last_close_ts, NOW() - INTERVAL '10 minutes'), NOW());
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_pos_ingesta_after_update ON selemti.pos_ingesta;
CREATE TRIGGER trg_pos_ingesta_after_update
AFTER UPDATE ON selemti.pos_ingesta
FOR EACH ROW EXECUTE PROCEDURE selemti.trg_pos_ingesta_after_update();

CREATE OR REPLACE FUNCTION selemti.trg_recepcion_det_check()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_perishable BOOLEAN := FALSE;
BEGIN
  SELECT COALESCE(MAX(CASE WHEN iv.perishable THEN 1 ELSE 0 END)=1, FALSE)
    INTO v_perishable
  FROM selemti.item_vendor iv
  WHERE iv.item_id = NEW.item_id AND iv.activo = TRUE;

  IF v_perishable AND (NEW.caducidad IS NULL OR NEW.caducidad <= CURRENT_DATE) THEN
    RAISE EXCEPTION 'Item % requiere caducidad futura por ser perecedero', NEW.item_id;
  END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_recepcion_det_check ON selemti.recepcion_det;
CREATE TRIGGER trg_recepcion_det_check
BEFORE INSERT OR UPDATE ON selemti.recepcion_det
FOR EACH ROW EXECUTE PROCEDURE selemti.trg_recepcion_det_check();

CREATE OR REPLACE FUNCTION selemti.trg_mov_inv_wac()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.tipo IN ('RECEPCION','PROD_IN','TRANSFER_IN') AND NEW.costo_unit IS NOT NULL THEN
    PERFORM selemti.fn_wac_apply(NEW.item_id, NEW.qty_canonica, NEW.costo_unit);
  END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_mov_inv_wac ON selemti.mov_inv;
CREATE TRIGGER trg_mov_inv_wac
AFTER INSERT ON selemti.mov_inv
FOR EACH ROW EXECUTE PROCEDURE selemti.trg_mov_inv_wac();

CREATE OR REPLACE FUNCTION selemti.trg_compra_state_guard()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_ord NUMERIC(18,6); v_rec NUMERIC(18,6);
BEGIN
  IF NEW.estado = 'CLOSED' AND OLD.estado IS DISTINCT FROM 'CLOSED' THEN
    SELECT COALESCE(SUM(cd.cant_canonica),0) INTO v_ord
    FROM selemti.compra_det cd WHERE cd.compra_id = NEW.id;

    SELECT COALESCE(SUM(rd.cant_recibida_canonica),0) INTO v_rec
    FROM selemti.recepcion r
    JOIN selemti.recepcion_det rd ON rd.recepcion_id = r.id
    WHERE r.compra_id = NEW.id;

    IF v_rec + 0.000001 < v_ord THEN
      RAISE EXCEPTION 'No se puede cerrar la compra %, faltan recepciones (ordenadas=%, recibidas=%)', NEW.id, v_ord, v_rec;
    END IF;
  END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_compra_state_guard ON selemti.compra;
CREATE TRIGGER trg_compra_state_guard
BEFORE UPDATE ON selemti.compra
FOR EACH ROW EXECUTE PROCEDURE selemti.trg_compra_state_guard();

-- 6) Índices condicionales para ingesta (si existe public.ticket)
DO $$
DECLARE v_has_table BOOLEAN; v_col TEXT;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='ticket' AND c.relkind='r') INTO v_has_table;
  IF v_has_table THEN
    FOR v_col IN
      SELECT column_name FROM information_schema.columns
      WHERE table_schema='public' AND table_name='ticket'
        AND column_name IN ('close_ts','closed_at','closing_time','close_time','paid_time','settled_at')
    LOOP
      EXECUTE format('CREATE INDEX IF NOT EXISTS ix_ticket_%I ON public.ticket (%I);', v_col, v_col);
      EXIT;
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='ticket' AND indexname='ix_ticket_id') THEN
      EXECUTE 'CREATE INDEX ix_ticket_id ON public.ticket (id)';
    END IF;
  END IF;
END $$;

COMMENT ON SCHEMA selemti IS 'Inventarios y compras para Floreant POS (PG 9.5 Consolidado FINAL).';
-- =====================================================================
--  FIN DEPLOY
-- =====================================================================
-- =====================================================================
-- Selemti · Integración Modificadores + Vistas + Triggers (PG 9.5 SAFE)
-- (Append-only)  ✅ Idempotente sobre tu deploy consolidado
-- =====================================================================

-- 0) Guard esquema
CREATE SCHEMA IF NOT EXISTS selemti;

-- 1) Ampliar bom_modifier (PG 9.5: checar existencia de columnas)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='bom_modifier' AND column_name='costo_adicional'
  ) THEN
    EXECUTE 'ALTER TABLE selemti.bom_modifier ADD COLUMN costo_adicional NUMERIC(14,6) DEFAULT 0';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='bom_modifier' AND column_name='precio_adicional'
  ) THEN
    EXECUTE 'ALTER TABLE selemti.bom_modifier ADD COLUMN precio_adicional NUMERIC(14,6) DEFAULT 0';
  END IF;
END $$;

-- Índices sugeridos (idempotentes)
CREATE INDEX IF NOT EXISTS ix_bom_modifier_modifier ON selemti.bom_modifier(modifier_id);
CREATE INDEX IF NOT EXISTS ix_bom_modifier_item     ON selemti.bom_modifier(inventory_item_id);

-- 2) Rehacer vw_bom_menu_item con casts + guardias (placeholders si faltan tablas public.*)
DROP VIEW IF EXISTS selemti.vw_bom_menu_item;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='menu_item' AND c.relkind='r')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='recepie' AND c.relkind='r')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='recepie_item' AND c.relkind='r') THEN
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT
        mi.id::INT                     AS menu_item_id,
        mi.name::TEXT                  AS menu_item_name,
        r.id::INT                      AS recepie_id,
        ri.inventory_item::INT         AS inventory_item_id,
        ri.percentage::NUMERIC(14,6)   AS percentage
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id;
    $SQL$;
  ELSE
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT NULL::INT AS menu_item_id, NULL::TEXT AS menu_item_name,
             NULL::INT AS recepie_id,   NULL::INT AS inventory_item_id,
             NULL::NUMERIC(14,6) AS percentage
      WHERE FALSE;
    $SQL$;
  END IF;
END $$;

-- 3) Rehacer vw_conversion_sugerida con ORDER BY alineado al DISTINCT ON
DROP VIEW IF EXISTS selemti.vw_conversion_sugerida;
CREATE VIEW selemti.vw_conversion_sugerida AS
SELECT DISTINCT ON (ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion)
  ct.item_id,
  ct.vendor_id,
  ct.presentacion,
  ct.unidad_presentacion_id,
  ct.unidad_canonica,
  ct.factor_a_canonica,
  ct.preferred
FROM selemti.conversion_template ct
WHERE ct.activo = TRUE
ORDER BY
  ct.item_id,
  COALESCE(ct.vendor_id,-1),
  ct.presentacion,
  ct.preferred DESC,
  ct.id DESC;

-- 4) vw_receta_completa (base + modificadores, con guards y placeholder seguro)
DROP VIEW IF EXISTS selemti.vw_receta_completa;
CREATE VIEW selemti.vw_receta_completa AS
SELECT
  NULL::INT AS menu_item_id,
  NULL::INT AS inventory_item_id,
  NULL::NUMERIC(14,6) AS qty_canonica,
  NULL::INT AS modifier_id,
  NULL::NUMERIC(14,6) AS qty_mod,
  NULL::NUMERIC(14,6) AS costo_adicional,
  NULL::NUMERIC(14,6) AS precio_adicional,
  NULL::TEXT AS origen
WHERE FALSE;

-- 4a) Si existen tablas base de recetas → vista BASE
DO $MAIN$
DECLARE
  v_has_mi  BOOLEAN;
  v_has_r   BOOLEAN;
  v_has_ri  BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='menu_item' AND c.relkind='r') INTO v_has_mi;
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='recepie' AND c.relkind='r') INTO v_has_r;
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='recepie_item' AND c.relkind='r') INTO v_has_ri;

  IF v_has_mi AND v_has_r AND v_has_ri THEN
    EXECUTE $$
      CREATE OR REPLACE VIEW selemti.vw_receta_completa AS
      SELECT
        mi.id::INT                    AS menu_item_id,
        ri.inventory_item::INT        AS inventory_item_id,
        ri.percentage::NUMERIC(14,6)  AS qty_canonica,
        NULL::INT                     AS modifier_id,
        NULL::NUMERIC(14,6)           AS qty_mod,
        NULL::NUMERIC(14,6)           AS costo_adicional,
        NULL::NUMERIC(14,6)           AS precio_adicional,
        'BASE'::TEXT                  AS origen
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id
    $$;
  END IF;
END
$MAIN$;

-- 4b) Si hay catálogo de modificadores y vínculo → expandir con MODS
DO $MODS$
DECLARE
  v_has_mods BOOLEAN;
  v_has_mim  BOOLEAN; -- public.menu_item_modifier
  v_has_mmi  BOOLEAN; -- public.menu_modifier_item
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname IN ('menu_modifier','modifiers') AND c.relkind='r')
    INTO v_has_mods;
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='menu_item_modifier' AND c.relkind='r')
    INTO v_has_mim;
  SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                 WHERE n.nspname='public' AND c.relname='menu_modifier_item' AND c.relkind='r')
    INTO v_has_mmi;

  IF v_has_mods AND (v_has_mim OR v_has_mmi) THEN
    EXECUTE $$
      CREATE OR REPLACE VIEW selemti.vw_receta_completa AS
      WITH base AS (
        SELECT
          mi.id::INT                    AS menu_item_id,
          ri.inventory_item::INT        AS inventory_item_id,
          ri.percentage::NUMERIC(14,6)  AS qty_canonica,
          NULL::INT                     AS modifier_id,
          NULL::NUMERIC(14,6)           AS qty_mod,
          NULL::NUMERIC(14,6)           AS costo_adicional,
          NULL::NUMERIC(14,6)           AS precio_adicional,
          'BASE'::TEXT                  AS origen
        FROM public.menu_item mi
        JOIN public.recepie r       ON r.id = mi.recepie
        JOIN public.recepie_item ri ON ri.recepie_id = r.id
      ),
      mods AS (
        SELECT
          mim.menu_item_id::INT                AS menu_item_id,
          bm.inventory_item_id::INT            AS inventory_item_id,
          bm.qty_canonica::NUMERIC(14,6)       AS qty_canonica,
          bm.modifier_id::INT                  AS modifier_id,
          bm.qty_canonica::NUMERIC(14,6)       AS qty_mod,
          COALESCE(bm.costo_adicional,0)::NUMERIC(14,6)  AS costo_adicional,
          COALESCE(bm.precio_adicional,0)::NUMERIC(14,6) AS precio_adicional,
          'MOD'::TEXT                           AS origen
        FROM selemti.bom_modifier bm
        JOIN public.menu_item_modifier mim ON mim.modifier_id = bm.modifier_id
        WHERE EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                      WHERE n.nspname='public' AND c.relname='menu_item_modifier' AND c.relkind='r')
        UNION ALL
        SELECT
          mmi.menu_item_id::INT,
          bm.inventory_item_id::INT,
          bm.qty_canonica::NUMERIC(14,6),
          bm.modifier_id::INT,
          bm.qty_canonica::NUMERIC(14,6),
          COALESCE(bm.costo_adicional,0)::NUMERIC(14,6),
          COALESCE(bm.precio_adicional,0)::NUMERIC(14,6),
          'MOD'::TEXT
        FROM selemti.bom_modifier bm
        JOIN public.menu_modifier_item mmi ON mmi.modifier_id = bm.modifier_id
        WHERE EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                      WHERE n.nspname='public' AND c.relname='menu_modifier_item' AND c.relkind='r')
      )
      SELECT * FROM base
      UNION ALL
      SELECT * FROM mods
    $$;
  END IF;
END
$MODS$;

-- 5) Trigger de descuento teórico en venta (si existe tabla de líneas)
-- (a) ticketitem
DO $T1$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='ticketitem' AND c.relkind='r') THEN
    EXECUTE 'DROP TRIGGER IF EXISTS trg_venta_modificadores ON public.ticketitem';
    EXECUTE 'CREATE TRIGGER trg_venta_modificadores
             AFTER INSERT ON public.ticketitem
             FOR EACH ROW EXECUTE PROCEDURE selemti.trg_venta_modificadores()';
  END IF;
END
$T1$;

-- (b) ticket_line
DO $T2$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname=''public'' AND c.relname=''ticket_line'' AND c.relkind=''r'') THEN
    EXECUTE ''DROP TRIGGER IF EXISTS trg_venta_modificadores ON public.ticket_line'';
    EXECUTE ''CREATE TRIGGER trg_venta_modificadores
              AFTER INSERT ON public.ticket_line
              FOR EACH ROW EXECUTE PROCEDURE selemti.trg_venta_modificadores()'';
  END IF;
END
$T2$;

-- (c) ticket_items
DO $T3$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='ticket_items' AND c.relkind='r') THEN
    EXECUTE 'DROP TRIGGER IF EXISTS trg_venta_modificadores ON public.ticket_items';
    EXECUTE 'CREATE TRIGGER trg_venta_modificadores
             AFTER INSERT ON public.ticket_items
             FOR EACH ROW EXECUTE PROCEDURE selemti.trg_venta_modificadores()';
  END IF;
END
$T3$;

-- Listo.
-- =====================================================================
