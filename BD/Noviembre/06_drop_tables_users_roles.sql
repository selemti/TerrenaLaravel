-- =============================================================================
-- SCRIPT: 06_drop_tables_users_roles.sql
-- Fecha: 2025-11-02
-- Objetivo: Eliminar tablas duplicadas de usuarios y roles que están vacías
-- =============================================================================

-- PRERREQUISITO: Ejecutar 01_agregar_campos_users.sql ANTES de este script

-- Verificación previa: Contar registros
SELECT
  'usuario' as tabla,
  COUNT(*) as registros
FROM selemti.usuario
UNION ALL
SELECT
  'rol',
  COUNT(*)
FROM selemti.rol
ORDER BY tabla;

-- Resultado esperado: 2 filas con 0 registros cada una

-- Verificar que los campos fueron agregados a selemti.users
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'users'
  AND column_name IN ('floreant_user_id', 'meta')
ORDER BY column_name;

-- Resultado esperado: 2 filas (floreant_user_id, meta)
-- Si no aparecen, ejecutar primero 01_agregar_campos_users.sql

-- Si la verificación es correcta, proceder con DROP
BEGIN;

-- Eliminar tabla usuario vacía (campos únicos ya migrados a users)
DROP TABLE IF EXISTS selemti.usuario CASCADE;

-- Eliminar tabla rol vacía
DROP TABLE IF EXISTS selemti.rol CASCADE;

COMMIT;

-- Verificación post-eliminación
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('usuario', 'rol')
ORDER BY tablename;

-- Resultado esperado: 0 filas (ambas tablas eliminadas)

-- Verificar que las tablas correctas permanecen
SELECT
  tablename,
  (SELECT COUNT(*) FROM selemti.users) as users_count,
  (SELECT COUNT(*) FROM selemti.roles) as roles_count
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('users', 'roles')
ORDER BY tablename;

-- Resultado esperado:
-- users    | 1 | 7
-- roles    | 1 | 7
