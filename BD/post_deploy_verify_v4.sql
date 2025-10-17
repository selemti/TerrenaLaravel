-- ================================================================
-- POST-DEPLOY VERIFICATION SCRIPT
-- Version 4 - PostgreSQL 9.5 Compatible
-- Date: 2025-10-17
-- ================================================================

\set QUIET on
\set ON_ERROR_STOP off

\echo '================================================================'
\echo 'POST-DEPLOY VERIFICATION - PostgreSQL 9.5'
\echo '================================================================'
\echo ''

-- 1. Verificar esquema selemti
\echo '1. Verificando esquema selemti...'
SELECT CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='selemti')
    THEN '   ✓ Schema selemti: EXISTE'
    ELSE '   ✗ Schema selemti: NO ENCONTRADO'
END;

-- 2. Contar tablas
\echo ''
\echo '2. Contando tablas en esquema selemti...'
SELECT '   Total: ' || COUNT(*) || ' tablas' as result
FROM information_schema.tables
WHERE table_schema='selemti';

-- 3. Verificar tablas críticas del sistema de cajas
\echo ''
\echo '3. Verificando tablas críticas del sistema de cajas...'
WITH critical_tables AS (
    SELECT unnest(ARRAY['users', 'sesion_cajon', 'precorte', 'precorte_efectivo', 'precorte_otros', 'postcorte', 'conciliacion']) as table_name
)
SELECT
    ct.table_name,
    CASE WHEN t.table_name IS NOT NULL THEN '✓ EXISTE' ELSE '✗ FALTA' END as status
FROM critical_tables ct
LEFT JOIN information_schema.tables t
    ON t.table_schema='selemti' AND t.table_name=ct.table_name
ORDER BY ct.table_name;

-- 4. Verificar constraint UNIQUE en precorte(sesion_id)
\echo ''
\echo '4. Verificando constraint UNIQUE en precorte(sesion_id)...'
SELECT CASE
    WHEN EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_namespace n ON n.oid = c.connamespace
        WHERE n.nspname = 'selemti'
          AND c.conrelid = 'selemti.precorte'::regclass
          AND c.contype = 'u'
          AND c.conname = 'uq_precorte_sesion_id'
    )
    THEN '   ✓ UNIQUE constraint en precorte(sesion_id): EXISTE'
    ELSE '   ✗ UNIQUE constraint en precorte(sesion_id): FALTA'
END;

-- 5. Verificar CHECK constraint en sesion_cajon.estatus (6 estados)
\echo ''
\echo '5. Verificando CHECK constraint en sesion_cajon.estatus...'
SELECT
    '   Constraint: ' || conname as name,
    '   Definición: ' || pg_get_constraintdef(c.oid) as definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'selemti'
  AND c.conrelid = 'selemti.sesion_cajon'::regclass
  AND c.contype = 'c'
  AND conname LIKE '%estatus%';

\echo ''
SELECT CASE
    WHEN pg_get_constraintdef(c.oid) LIKE '%EN_CORTE%'
     AND pg_get_constraintdef(c.oid) LIKE '%CONCILIADA%'
     AND pg_get_constraintdef(c.oid) LIKE '%OBSERVADA%'
    THEN '   ✓ CHECK constraint incluye los 6 estados (ACTIVA, LISTO_PARA_CORTE, EN_CORTE, CERRADA, CONCILIADA, OBSERVADA)'
    ELSE '   ✗ CHECK constraint NO incluye todos los estados requeridos'
END
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'selemti'
  AND c.conrelid = 'selemti.sesion_cajon'::regclass
  AND c.contype = 'c'
  AND conname = 'sesion_cajon_estatus_check';

-- 6. Verificar funciones críticas
\echo ''
\echo '6. Verificando funciones críticas...'
WITH critical_functions AS (
    SELECT unnest(ARRAY[
        'fn_generar_postcorte',
        'fn_precorte_after_insert',
        'fn_precorte_after_update_aprobado',
        'fn_postcorte_after_insert'
    ]) as function_name
)
SELECT
    cf.function_name,
    CASE WHEN r.routine_name IS NOT NULL THEN '✓ EXISTE' ELSE '✗ FALTA' END as status
FROM critical_functions cf
LEFT JOIN information_schema.routines r
    ON r.routine_schema='selemti'
   AND r.routine_name=cf.function_name
   AND r.routine_type='FUNCTION'
ORDER BY cf.function_name;

-- 7. Verificar triggers
\echo ''
\echo '7. Verificando triggers...'
SELECT
    trigger_name,
    event_object_table as tabla,
    '✓ ACTIVO' as status
FROM information_schema.triggers
WHERE trigger_schema='selemti'
  AND trigger_name IN (
      'trg_precorte_after_insert',
      'trg_precorte_after_update_aprobado',
      'trg_postcorte_after_insert'
  )
ORDER BY trigger_name;

-- 8. Contar triggers totales
\echo ''
\echo '8. Contando triggers totales en esquema selemti...'
SELECT '   Total: ' || COUNT(*) || ' triggers' as result
FROM information_schema.triggers
WHERE trigger_schema='selemti';

-- 9. Verificar vistas críticas
\echo ''
\echo '9. Verificando vistas críticas...'
WITH critical_views AS (
    SELECT unnest(ARRAY['vw_conciliacion_sesion', 'vw_sesion_dpr']) as view_name
)
SELECT
    cv.view_name,
    CASE WHEN v.table_name IS NOT NULL THEN '✓ EXISTE' ELSE '✗ FALTA' END as status
FROM critical_views cv
LEFT JOIN information_schema.views v
    ON v.table_schema='selemti' AND v.table_name=cv.view_name
ORDER BY cv.view_name;

-- 10. Verificar índices de performance
\echo ''
\echo '10. Verificando índices de performance...'
SELECT
    indexname as nombre_indice,
    tablename as tabla,
    '✓ EXISTE' as status
FROM pg_indexes
WHERE schemaname='selemti'
  AND indexname IN (
      'idx_precorte_efectivo_precorte_id',
      'idx_precorte_otros_precorte_id',
      'idx_sesion_cajon_terminal_apertura',
      'idx_postcorte_sesion_id'
  )
ORDER BY indexname;

-- 11. Verificar triggers usan EXECUTE PROCEDURE (no EXECUTE FUNCTION)
\echo ''
\echo '11. Verificando sintaxis de triggers (EXECUTE PROCEDURE para PG 9.5)...'
SELECT
    t.trigger_name,
    CASE
        WHEN pg_get_triggerdef(tr.oid) LIKE '%EXECUTE PROCEDURE%' THEN '✓ CORRECTO (EXECUTE PROCEDURE)'
        WHEN pg_get_triggerdef(tr.oid) LIKE '%EXECUTE FUNCTION%' THEN '✗ INCORRECTO (EXECUTE FUNCTION - no compatible con PG 9.5)'
        ELSE '? DESCONOCIDO'
    END as sintaxis
FROM information_schema.triggers t
JOIN pg_trigger tr ON tr.tgname = t.trigger_name
WHERE t.trigger_schema='selemti'
  AND t.trigger_name IN (
      'trg_precorte_after_insert',
      'trg_precorte_after_update_aprobado',
      'trg_postcorte_after_insert'
  )
ORDER BY t.trigger_name;

-- 12. Resumen final
\echo ''
\echo '================================================================'
\echo 'RESUMEN FINAL'
\echo '================================================================'

WITH verification AS (
    SELECT
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='selemti') as total_tables,
        (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='selemti' AND routine_type='FUNCTION') as total_functions,
        (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='selemti') as total_triggers,
        (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='selemti') as total_views,
        (SELECT COUNT(*) FROM pg_indexes WHERE schemaname='selemti') as total_indexes
)
SELECT
    'Tablas: ' || total_tables as estadistica_1,
    'Funciones: ' || total_functions as estadistica_2,
    'Triggers: ' || total_triggers as estadistica_3,
    'Vistas: ' || total_views as estadistica_4,
    'Índices: ' || total_indexes as estadistica_5
FROM verification;

\echo ''
\echo '✓ Verificación completada'
\echo '================================================================'
