-- =============================================================================
-- SCRIPT: 04_drop_tables_catalogs_empty.sql
-- Fecha: 2025-11-02
-- Objetivo: Eliminar tablas duplicadas de catálogos que están vacías
-- =============================================================================

-- IMPORTANTE: Verificar antes de ejecutar que no hay referencias en código:
-- grep -r "\bsucursal\b|\balmacen\b|\bproveedor\b" app/Models/ --include="*.php" | grep "table = "
-- grep -r "\breceta\b|receta_cab" app/Models/ --include="*.php" | grep "table = "

-- Verificación previa: Contar registros
SELECT
  'sucursal' as tabla,
  COUNT(*) as registros
FROM selemti.sucursal
UNION ALL
SELECT
  'almacen',
  COUNT(*)
FROM selemti.almacen
UNION ALL
SELECT
  'proveedor',
  COUNT(*)
FROM selemti.proveedor
UNION ALL
SELECT
  'receta',
  COUNT(*)
FROM selemti.receta
UNION ALL
SELECT
  'receta_cab',
  COUNT(*)
FROM selemti.receta_cab
ORDER BY tabla;

-- Resultado esperado: 5 filas con 0 registros cada una

-- Si todas las tablas tienen 0 registros, proceder con DROP
BEGIN;

-- Catálogos vacíos duplicados (5 tablas)
DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.almacen CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;
DROP TABLE IF EXISTS selemti.receta_cab CASCADE;

COMMIT;

-- Verificación post-eliminación
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('sucursal', 'almacen', 'proveedor', 'receta', 'receta_cab')
ORDER BY tablename;

-- Resultado esperado: 0 filas (todas las tablas eliminadas)

-- Verificar que las tablas correctas permanecen
SELECT tablename, (SELECT COUNT(*) FROM selemti.cat_sucursales) as sucursales_count
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename LIKE 'cat_%'
ORDER BY tablename;

-- Resultado esperado: Tablas cat_sucursales, cat_almacenes, cat_proveedores, etc.
