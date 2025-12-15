-- DIAGNÓSTICO DE ESQUEMAS DUALES
-- Análisis de users en ambos esquemas

-- 1. Verificar usuarios en Floreant POS (public)
\echo '=== USUARIOS EN FLOREANT POS (public) ==='
SELECT
    'public' as esquema,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public')
         THEN 'EXISTS'
         ELSE 'NOT EXISTS'
    END as estado;

-- Si existe, mostrar estructura y datos
\echo '=== STRUCTURA public.users ==='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Mostrar datos si la tabla existe
\echo '=== DATOS EN public.users ==='
SELECT
    auto_id,
    user_id,
    first_name,
    last_name
FROM public.users
ORDER BY auto_id
LIMIT 10;

-- 2. Verificar usuarios en nuestro sistema (selemti)
\echo '=== USUARIOS EN SISTEMA PROPIO (selemti) ==='
SELECT
    'selemti' as esquema,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'selemti')
         THEN 'EXISTS'
         ELSE 'NOT EXISTS'
    END as estado;

-- Mostrar estructura de users en selemti
\echo '=== STRUCTURE selemti.users ==='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND table_schema = 'selemti'
ORDER BY ordinal_position;

-- Mostrar datos de users en selemti
\echo '=== DATOS EN selemti.users ==='
SELECT
    id,
    name,
    username,
    role,
    email,
    active
FROM selemti.users
ORDER BY id
LIMIT 10;

-- 3. Verificar cuáles tablas tienen foreign keys a users en public
\echo '=== FOREIGN KEYS A public.users ==='
SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'users'
  AND ccu.table_schema = 'public'
  AND tc.table_schema = 'public';

-- 4. Verificar qué user_id se usan en las tablas de Floreant POS
\echo '=== USER_ID UTILIZADOS EN TABLAS FLOREANT ==='
-- action_history
SELECT DISTINCT user_id
FROM public.action_history
WHERE user_id IS NOT NULL

UNION ALL

-- drawer_assigned_history
SELECT DISTINCT a_user as user_id
FROM public.drawer_assigned_history
WHERE a_user IS NOT NULL

UNION ALL

-- drawer_pull_report
SELECT DISTINCT user_id
FROM public.drawer_pull_report
WHERE user_id IS NOT NULL

UNION ALL

-- transactions
SELECT DISTINCT user_id
FROM public.transactions
WHERE user_id IS NOT NULL;