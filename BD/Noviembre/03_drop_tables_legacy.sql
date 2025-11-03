-- =============================================================================
-- SCRIPT: 03_drop_tables_legacy.sql
-- Fecha: 2025-11-02
-- Objetivo: Eliminar tablas con sufijo _legacy que están vacías
-- =============================================================================

-- IMPORTANTE: Verificar antes de ejecutar que no hay referencias en código:
-- grep -r "conversiones_unidad_legacy|uom_conversion_legacy|unidad_medida_legacy|unidades_medida_legacy" app/ --include="*.php"

-- Verificación previa: Contar registros
SELECT
  'conversiones_unidad_legacy' as tabla,
  COUNT(*) as registros
FROM selemti.conversiones_unidad_legacy
UNION ALL
SELECT
  'uom_conversion_legacy',
  COUNT(*)
FROM selemti.uom_conversion_legacy
UNION ALL
SELECT
  'unidad_medida_legacy',
  COUNT(*)
FROM selemti.unidad_medida_legacy
UNION ALL
SELECT
  'unidades_medida_legacy',
  COUNT(*)
FROM selemti.unidades_medida_legacy
ORDER BY tabla;

-- Resultado esperado: 4 filas con 0 registros cada una

-- Si todas las tablas tienen 0 registros, proceder con DROP
BEGIN;

-- Tablas de Unidades de Medida Legacy (4 tablas)
DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidades_medida_legacy CASCADE;

COMMIT;

-- Verificación post-eliminación
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename LIKE '%_legacy'
ORDER BY tablename;

-- Resultado esperado: 0 filas (todas las tablas legacy eliminadas)
