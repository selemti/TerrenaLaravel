-- DIAGNÓSTICO SIMPLE DEL PROBLEMA DE IMPORTACIÓN
-- Versión simplificada para PostgreSQL 9.5

-- 1. Verificar si existe la tabla users y su estructura
\echo '=== TABLA USERS ==='
SELECT
    'users' as tabla,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public')
         THEN 'EXISTS'
         ELSE 'NOT EXISTS'
    END as estado;

-- Si existe, ver sus columnas
\echo '=== COLUMNAS DE USERS ==='
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Verificar datos en action_history para ver qué user_id se usan
\echo '=== USER_ID EN ACTION_HISTORY ==='
SELECT
    user_id,
    COUNT(*) as count
FROM public.action_history
GROUP BY user_id
ORDER BY count DESC;

-- 3. Verificar datos en drawer_assigned_history
\echo '=== A_USER EN DRAWER_ASSIGNED_HISTORY ==='
SELECT
    a_user,
    COUNT(*) as count
FROM public.drawer_assigned_history
GROUP BY a_user
ORDER BY count DESC;

-- 4. Verificar qué usuarios faltan
\echo '=== USUARIOS FALTANTES ==='
SELECT DISTINCT ah.user_id
FROM public.action_history ah
WHERE NOT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.auto_id = ah.user_id
)
ORDER BY ah.user_id;

-- 5. Verificar constraints específicos que causan el error
\echo '=== CONSTRAINTS PROBLEMÁTICOS ==='
SELECT
    constraint_name,
    table_name
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
  AND table_schema = 'public'
  AND (table_name = 'action_history' OR table_name = 'drawer_assigned_history');