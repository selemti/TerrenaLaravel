
-- Checks v2
SELECT 'alert_cfg_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='alert_cfg'
) AS ok;

SELECT 'merma_policy_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='merma_policy'
) AS ok;

SELECT 'ui_prefs_exists' AS check, EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='ui_prefs'
) AS ok;

SELECT 'vw_bom_menu_item_ok' AS check, pg_get_viewdef('selemti.vw_bom_menu_item'::regclass) ILIKE '%name::text%' 
  AND pg_get_viewdef('selemti.vw_bom_menu_item'::regclass) ILIKE '%percentage::numeric%' AS ok;

SELECT 'vw_conv_ok_order' AS check, pg_get_viewdef('selemti.vw_conversion_sugerida'::regclass) ILIKE '%ORDER BY ct.item_id, COALESCE(ct.vendor_id,-1), ct.presentacion, ct.preferred DESC, ct.id DESC%' AS ok;

-- Unique partials present
SELECT 'uq_alert_cfg_metric_null_scope' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_alert_cfg_metric_null_scope'
) AS ok;

SELECT 'uq_merma_policy_sucursal_categoria' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_merma_policy_sucursal_categoria'
) AS ok;

SELECT 'uq_ui_prefs_sucursal_key' AS check, EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='uq_ui_prefs_sucursal_key'
) AS ok;
