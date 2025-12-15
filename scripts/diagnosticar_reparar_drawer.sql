-- Diagnóstico y reparación de problemas con tablas drawer
-- Script para identificar y solucionar problemas de integridad

-- 1. Verificar estado actual de las tablas
\echo '=== DIAGNÓSTICO DE TABLAS DRAWER ==='

SELECT
    'drawer_assigned_history' as tabla,
    COUNT(*) as total_registros,
    MAX(id) as max_id,
    MIN(id) as min_id
FROM public.drawer_assigned_history

UNION ALL

SELECT
    'drawer_pull_report' as tabla,
    COUNT(*) as total_registros,
    MAX(id) as max_id,
    MIN(id) as min_id
FROM public.drawer_pull_report;

-- 2. Verificar si hay algún trigger o constraint que pueda estar causando problemas
\echo '=== VERIFICACIÓN DE TRIGGERS ==='

SELECT
    event_object_table,
    trigger_name,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('drawer_assigned_history', 'drawer_pull_report')
  AND trigger_schema = 'public';

-- 3. Verificar sequences
\echo '=== VERIFICACIÓN DE SEQUENCES ==='

SELECT
    schemaname,
    sequencename,
    last_value,
    is_called
FROM pg_sequences
WHERE sequencename LIKE '%drawer%'
  AND schemaname = 'public';

-- 4. Verificar si hay alguna relación esperada entre las tablas
\echo '=== ANÁLISIS DE POSIBLES RELACIONES ==='

-- Revisar si hay alguna columna que pueda relacionar las tablas
SELECT
    dpr.id,
    dpr.report_time::date as fecha,
    dpr.terminal_id,
    dpr.ticket_count,
    dah.id as dah_id,
    dah.time,
    dah.operation,
    dah.a_user
FROM public.drawer_pull_report dpr
CROSS JOIN public.drawer_assigned_history dah
WHERE DATE(dpr.report_time) = DATE(dah.time)
  AND dpr.terminal_id = (SELECT terminal_id FROM public.terminal WHERE id = dah.a_user LIMIT 1)
ORDER BY dpr.id DESC, dah.id DESC
LIMIT 20;

-- 5. Verificar integridad referencial
\echo '=== INTEGRIDAD REFERENCIAL ==='

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type IN ('FOREIGN KEY')
  AND tc.table_schema = 'public'
  AND (tc.table_name LIKE '%drawer%' OR ccu.table_name LIKE '%drawer%');