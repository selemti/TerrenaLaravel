
-- =====================================================================
--  Selemti · Hotfix PG 9.5 Compat v2 (post-deploy)
--  - Crea tablas faltantes: alert_cfg, merma_policy, ui_prefs
--  - Rehace vistas con tipos estables (drop + create)
--  - Ajusta UNIQUE con índices parciales
--  - Reinstala trigger de recepción_det si aplica
--  Idempotente para PG 9.5
-- =====================================================================

-- 0) Guard: esquema
CREATE SCHEMA IF NOT EXISTS selemti;

-- 1) Tablas faltantes (si no existen)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='alert_cfg'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.alert_cfg (
        id BIGSERIAL PRIMARY KEY,
        metric_key TEXT NOT NULL,
        defaults JSONB NOT NULL,
        scope JSONB
      );
    $SQL$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='merma_policy'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.merma_policy (
        id           BIGSERIAL PRIMARY KEY,
        sucursal_id  INT NULL REFERENCES public.inventory_location(id),
        categoria    selemti.merma_categoria NOT NULL,
        th_warn      NUMERIC(14,2) NOT NULL DEFAULT 0,
        th_block     NUMERIC(14,2) NOT NULL DEFAULT 0,
        aut_req      selemti.nivel_aut NOT NULL DEFAULT 'SUPERVISOR',
        enabled      BOOLEAN NOT NULL DEFAULT TRUE
      );
    $SQL$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='ui_prefs'
  ) THEN
    EXECUTE $SQL$
      CREATE TABLE selemti.ui_prefs (
        id           BIGSERIAL PRIMARY KEY,
        sucursal_id  INT NULL REFERENCES public.inventory_location(id),
        key          TEXT NOT NULL,
        value_json   JSONB NOT NULL
      );
    $SQL$;
  END IF;
END $$;

-- 2) Índices únicos parciales (sustituyen constraints no soportadas)
-- alert_cfg
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_null_scope
    ON selemti.alert_cfg(metric_key)
    WHERE scope IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_alert_cfg_metric_scope
    ON selemti.alert_cfg(metric_key, scope)
    WHERE scope IS NOT NULL;
END $$;

-- merma_policy
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_categoria_global
    ON selemti.merma_policy(categoria)
    WHERE sucursal_id IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_merma_policy_sucursal_categoria
    ON selemti.merma_policy(sucursal_id, categoria)
    WHERE sucursal_id IS NOT NULL;
END $$;

-- ui_prefs
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_key_global
    ON selemti.ui_prefs(key)
    WHERE sucursal_id IS NULL;

  CREATE UNIQUE INDEX IF NOT EXISTS uq_ui_prefs_sucursal_key
    ON selemti.ui_prefs(sucursal_id, key)
    WHERE sucursal_id IS NOT NULL;
END $$;

-- 3) Vistas (drop + create para evitar conflictos de tipo en PG 9.5)
-- 3.1 vw_bom_menu_item
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema='selemti' AND table_name='vw_bom_menu_item') THEN
    EXECUTE 'DROP VIEW selemti.vw_bom_menu_item';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='menu_item')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie')
     AND EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='recepie_item') THEN
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT
        mi.id               AS menu_item_id,
        mi.name::TEXT       AS menu_item_name,
        r.id                AS recepie_id,
        ri.inventory_item   AS inventory_item_id,
        ri.percentage::NUMERIC(14,6) AS percentage
      FROM public.menu_item mi
      JOIN public.recepie r       ON r.id = mi.recepie
      JOIN public.recepie_item ri ON ri.recepie_id = r.id;
    $SQL$;
  ELSE
    -- Si no existen tablas públicas, dejar vista vacía compatible
    EXECUTE $SQL$
      CREATE VIEW selemti.vw_bom_menu_item AS
      SELECT NULL::INT AS menu_item_id, NULL::TEXT AS menu_item_name,
             NULL::INT AS recepie_id, NULL::INT AS inventory_item_id,
             NULL::NUMERIC(14,6) AS percentage
      WHERE FALSE;
    $SQL$;
  END IF;
END $$;

-- 3.2 vw_conversion_sugerida — corregir ORDER BY para DISTINCT ON
DROP VIEW IF EXISTS selemti.vw_conversion_sugerida;
CREATE VIEW selemti.vw_conversion_sugerida AS
SELECT DISTINCT ON (ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion)
  ct.item_id, ct.vendor_id, ct.presentacion,
  ct.unidad_presentacion_id, ct.unidad_canonica, ct.factor_a_canonica, ct.preferred
FROM selemti.conversion_template ct
WHERE ct.activo = TRUE
ORDER BY ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion, ct.preferred DESC, ct.id DESC;

-- 4) Trigger recepcion_det (por si falló antes)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='recepcion_det') THEN
    DROP TRIGGER IF EXISTS trg_recepcion_det_check ON selemti.recepcion_det;
    CREATE TRIGGER trg_recepcion_det_check
    BEFORE INSERT OR UPDATE ON selemti.recepcion_det
    FOR EACH ROW EXECUTE PROCEDURE selemti.trg_recepcion_det_check();
  END IF;
END $$;

-- =====================================================================
--  FIN HOTFIX v2
-- =====================================================================
