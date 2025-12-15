-- ANÁLISIS PREVIO A IMPORTACIÓN
-- Diagnóstico de problemas específicos con usuarios y foreign keys

-- 1. Verificar usuarios actuales en la BD local
\echo '=== USUARIOS ACTUALES EN BD LOCAL ==='
SELECT
    auto_id,
    user_id,
    first_name,
    last_name,
    type,
    active
FROM public.users
ORDER BY auto_id;

-- 2. Verificar qué user_id están referenciados en tablas importantes
\echo '=== USER_ID REFERENCIADOS EN TABLAS IMPORTANTES ==='

SELECT
    'action_history' as tabla,
    COUNT(DISTINCT user_id) as users_unicos,
    COUNT(*) as total_registros,
    STRING_AGG(DISTINCT user_id::text, ', ') as lista_users
FROM public.action_history
GROUP BY 'action_history'

UNION ALL

SELECT
    'drawer_assigned_history' as tabla,
    COUNT(DISTINCT a_user) as users_unicos,
    COUNT(*) as total_registros,
    STRING_AGG(DISTINCT a_user::text, ', ') as lista_users
FROM public.drawer_assigned_history
GROUP BY 'drawer_assigned_history';

-- 3. Identificar usuarios que faltan
\echo '=== USUARIOS FALTANTES (PROBLEMA REAL) ==='

SELECT
    ah.user_id,
    COUNT(*) as veces_referenciado,
    MIN(ah.time) as primera_referencia,
    MAX(ah.time) as ultima_referencia
FROM public.action_history ah
LEFT JOIN public.users u ON ah.user_id = u.auto_id
WHERE u.auto_id IS NULL
GROUP BY ah.user_id
ORDER BY veces_referenciado DESC;

-- 4. Verificar estado de la tabla users si existe
\echo '=== VERIFICACIÓN DE TABLA USERS ==='
SELECT
    'action_history' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) como user_id_nulos,
    COUNT(DISTINCT user_id) as users_unicos
FROM public.action_history

UNION ALL

SELECT
    'drawer_assigned_history' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN a_user IS NULL THEN 1 END) como user_id_nulos,
    COUNT(DISTINCT a_user) as users_unicos
FROM public.drawer_assigned_history;

-- 5. Analizar una muestra del archivo de importación (si pudieramos abrirlo)
-- Por ahora, simulamos que podemos leer el dump

-- 6. Verificar constraints que pueden causar problemas
\echo '=== CONSTRAINTS QUE PUEDEN CAUSAR PROBLEMAS ==='
SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.update_rule,
    rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
LEFT JOIN information_schema.referential_constraints rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND (tc.table_name LIKE '%action%'
       OR tc.table_name LIKE '%drawer%'
       OR tc.table_name LIKE '%user%'
       OR ccu.table_name LIKE '%user%');

-- 7. Verificar triggers activos
\echo '=== TRIGGERS ACTIVOS ==='
SELECT
    trigger_name,
    event_object_table,
    action_timing,
    action_condition,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND (event_object_table LIKE '%action%'
       OR event_object_table LIKE '%drawer%'
       OR event_object_table LIKE '%user%');

-- 8. Verificar secuencias de usuarios
\echo '=== SECUENCIAS DE USUARIOS ==='
SELECT
    sequencename,
    last_value,
    is_called
FROM pg_sequences
WHERE sequencename LIKE '%user%'
  AND schemaname = 'public';

-- 9. Solución específica para este caso
\echo '=== SOLUCIÓN ESPECÍFICA PROPUESTA ==='
SELECT
    'SOLUCION' as recomendacion,
    'Crear usuarios mínimos necesarios para la importación' as detalle,
    'user_id=1 (Admin) y user_id=6 (Soporte)' as usuarios_a_crear
UNION ALL
SELECT
    'POST-IMPORTACIÓN' as recomendacion,
    'Verificar y limpiar referencias huérfanas' as detalle,
    'Eliminar o corregir registros con user_id inválidos' as usuarios_a_crear;