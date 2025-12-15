-- SCRIPT SIMPLE PARA IMPORTAR COMPLETO
-- Versión reducida sin funciones complejas

-- 1. Verificar estado actual
SELECT 'ESQUEMAS ACTUALES:' as info;
SELECT schemaname, COUNT(*) as tablas FROM pg_tables WHERE schemaname IN ('public', 'selemti') GROUP BY schemaname ORDER BY schemaname;

-- 2. Verificar usuarios existentes en public
SELECT 'USUARIOS EN ANTES DE IMPORTAR:' as info;
SELECT auto_id, user_id, first_name FROM public.users ORDER BY auto_id;

-- 3. Deshabilitar trigger problemático
ALTER TABLE public.drawer_assigned_history DISABLE TRIGGER ALL;

-- 4. Mensaje de importación
SELECT 'LISTO PARA IMPORTAR:' as info;
SELECT '1. EJECUTAR:' as paso, 'psql -h localhost -p 5433 -U postgres -d pos -f "UX_Solo_datos_08_12_2025_dump.sql"' as comando;

-- 5. Función para verificar después de importar
CREATE OR REPLACE FUNCTION post_import_verificacion()
RETURNS TABLE(
    esquema TEXT,
    tabla TEXT,
    registros_count BIGINT,
    estado TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar tablas public
    SELECT 'public' as esquema, tablename as tabla, COUNT(*)::BIGINT as registros_count,
           'VERIFICAR' as estado
    FROM pg_tables WHERE schemaname = 'public'

    UNION ALL

    -- Verificar tablas selemti
    SELECT 'selemti' as esquema, tablename as tabla, COUNT(*)::BIGINT as registros_count,
           'VERIFICAR' as estado
    FROM pg_tables WHERE schemaname = 'selemti';
END;
$$;