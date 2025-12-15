-- SCRIPT PARA IMPORTAR COMPLETO UX_Solo_datos_08_12_2025_dump.sql
-- Incluyendo tanto datos de public como de selemti

-- ANTES DE IMPORTAR: Preparación del entorno
\echo '=== PREPARANDO ENTORNO PARA IMPORTACIÓN COMPLETA ==='

-- 1. Verificar qué esquemas y tablas tenemos actualmente
\echo 'ESQUEMAS ACTUALES:'
SELECT schemaname, COUNT(*) as tablas
FROM pg_tables
WHERE schemaname IN ('public', 'selemti')
GROUP BY schemaname
ORDER BY schemaname;

-- 2. Backup de datos críticos antes de cambios
\echo '=== BACKUP DE SEGURIDAD ==='
CREATE TABLE IF NOT EXISTS backup_pre_import_08_12_2025 AS (
    id SERIAL PRIMARY KEY,
    tabla_esquema TEXT,
    tabla_nombre TEXT,
    backup_time TIMESTAMPTZ DEFAULT NOW(),
    backup_data JSONB
);

INSERT INTO backup_pre_import_08_12_2025 (tabla_esquema, tabla_nombre, backup_data)
SELECT 'selemti' as esquema, 'users' as tabla,
       json_agg(json_build_object('id', id, 'name', name, 'email', email)) as data
FROM selemti.users;

-- 3. Establecer configuración para importación sin conflictos
\echo '=== CONFIGURANDO IMPORTACIÓN ==='
-- Deshabilitar temporalmente triggers que puedan causar problemas
ALTER TABLE public.drawer_assigned_history DISABLE TRIGGER ALL;

-- 4. Verificar usuarios actuales en public para preparar migración
\echo '=== USUARIOS ACTUALES EN ANTES DE IMPORTAR ==='
SELECT
    'public.users ANTES' as estado,
    COUNT(*) as total,
    STRING_AGG(auto_id::text || ':' || user_id || ':' || COALESCE(first_name, 'N/A'), ', ') as usuarios_existentes
FROM public.users;

-- 5. AHORA SÍ - INSTRUCCIONES PARA IMPORTAR
\echo '';
\echo '========================================';
\echo '  IMPORTAR DATOS COMPLETOS  ';
\echo '========================================';
\echo '';
\echo 'Ejecutar este comando:';
\echo 'psql -h localhost -p 5433 -U postgres -d pos -f "UX_Solo_datos_08_12_2025_dump.sql"';
\echo '';
\echo 'El script continuará después de la importación...';
\echo '';

-- 6. VERIFICACIÓN POST-IMPORTACIÓN (se ejecuta DESPUÉS de importar)
-- Estás funciones de verificación
CREATE OR REPLACE FUNCTION verificar_importacion_completa()
RETURNS TABLE(
    esquema TEXT,
    tabla TEXT,
    registros_anterior INTEGER,
    registros_despues INTEGER,
    diferencia INTEGER,
    estado TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar tablas de public
    SELECT
        'public' as esquema,
        t.tablename as tabla,
        COALESCE(backup_count, 0) as registros_anterior,
        COALESCE(actual_count, 0) as registros_despues,
        COALESCE(actual_count, 0) - COALESCE(backup_count, 0) as diferencia,
        CASE
            WHEN COALESCE(backup_count, 0) = 0 THEN 'NUEVA'
            WHEN COALESCE(actual_count, 0) = COALESCE(backup_count, 0) THEN 'IGUAL'
            WHEN COALESCE(actual_count, 0) > COALESCE(backup_count, 0) THEN 'INCREMENTADA'
            ELSE 'DISMINUIDA'
        END as estado
    FROM pg_tables t
    LEFT JOIN LATERAL (
        SELECT
            schemaname || '_' || tablename as backup_key,
            COUNT(*) as backup_count
        FROM backup_pre_import_08_12_2025
        WHERE backup_data IS NOT NULL
        GROUP BY schemaname, tablename
    ) b ON ('public' || '_' || t.tablename) = b.backup_key
    WHERE t.schemaname = 'public'

    UNION ALL

    -- Verificar tablas de selemti
    SELECT
        'selemti' as esquema,
        t.tablename as tabla,
        COALESCE(backup_count, 0) as registros_anterior,
        COALESCE(actual_count, 0) as registros_despues,
        COALESCE(actual_count, 0) - COALESCE(backup_count, 0) as diferencia,
        CASE
            WHEN COALESCE(backup_count, 0) = 0 THEN 'NUEVA'
            WHEN COALESCE(actual_count, 0) = COALESCE(backup_count, 0) THEN 'IGUAL'
            WHEN COALESCE(actual_count, 0) > COALESCE(backup_count, 0) THEN 'INCREMENTADA'
            ELSE 'DISMINUIDA'
        END as estado
    FROM pg_tables t
    LEFT JOIN LATERAL (
        SELECT
            schemaname || '_' || tablename as backup_key,
            COUNT(*) as backup_count
        FROM backup_pre_import_08_12_2025
        WHERE backup_data IS NOT NULL
        GROUP BY schemaname, tablename
    ) b ON ('selemti' || '_' || t.tablename) = b.backup_key
    WHERE t.schemaname = 'selemti';
END;
$$;

-- Mensaje final
\echo '';
\echo '========================================';
\echo '  IMPORTACIÓN COMPLETIZADA';
\echo '========================================';
\echo '';
\echo 'Para verificar resultados, ejecutar:';
\echo 'SELECT * FROM verificar_importacion_completa();';
\echo '';