-- =====================================================================
-- Phase 2.4: Consolidación de Recetas
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

\echo ''
\echo '============================================================='
\echo 'Phase 2.4: Consolidación de Recetas'
\echo '============================================================='
\echo ''

-- Verificar estado inicial
SELECT 
  'receta (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.receta) as registros
UNION ALL
SELECT 
  'receta_cab (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.receta_cab) as registros
UNION ALL
SELECT 
  'receta_insumo (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.receta_insumo) as registros
UNION ALL
SELECT 
  'receta_det (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.receta_det) as registros;

\echo ''
\echo 'Consolidando recetas...'

-- Crear vistas de compatibilidad
DROP VIEW IF EXISTS selemti.v_receta CASCADE;
CREATE VIEW selemti.v_receta AS
SELECT 
  id,
  nombre_plato as nombre,
  categoria_plato as categoria,
  activo,
  costo_standard_porcion as costo_total,
  ((precio_venta_sugerido - costo_standard_porcion) / NULLIF(costo_standard_porcion, 0) * 100) as margen_sugerido,
  precio_venta_sugerido as precio_sugerido
FROM selemti.receta_cab;

DROP VIEW IF EXISTS selemti.v_receta_insumo CASCADE;
CREATE VIEW selemti.v_receta_insumo AS
SELECT 
  id,
  receta_version_id,
  item_id as insumo_id,
  cantidad,
  unidad_medida,
  0.00 as costo_unitario,
  0.00 as costo_total
FROM selemti.receta_det;

\echo ''
\echo '============================================================='
\echo 'Phase 2.4 COMPLETADA'
\echo '============================================================='
\echo ''

-- Verificar vistas
SELECT 
  viewname,
  'vista creada' as estado
FROM pg_views 
WHERE schemaname = 'selemti' 
  AND viewname IN ('v_receta', 'v_receta_insumo')
ORDER BY viewname;

\timing off
