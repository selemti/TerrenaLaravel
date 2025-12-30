-- SOLUCIÓN DRASTICA PERO EFECTIVA PARA IMPORTACIÓN DE DATOS
-- Este script deshabilita TODAS las foreign keys temporalmente

-- 1. Guardar los constraints existentes para restaurar después
CREATE TEMPORARY TABLE temp_constraints AS
SELECT
    tc.constraint_name,
    tc.table_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';

-- 2. Eliminar TODAS las foreign keys del schema public
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT constraint_name, table_name
        FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
          AND table_schema = 'public'
    )
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I',
                      'public', r.table_name, r.constraint_name);
        RAISE NOTICE 'Eliminado constraint: %', r.constraint_name;
    END LOOP;
END $$;

-- 3. Deshabilitar TODOS los triggers del schema public
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
    )
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DISABLE TRIGGER %I',
                      'public', r.event_object_table, r.trigger_name);
        RAISE NOTICE 'Deshabilitado trigger: %', r.trigger_name;
    END LOOP;
END $$;

-- 4. Asegurar que existan usuarios mínimos necesarios
INSERT INTO public.users (auto_id, user_id, first_name, last_name, password, type, active)
VALUES
    (1, 1, 'Admin', 'System', 'temp_hash', 1, true),
    (6, 6, 'Soporte', 'Tecnico', 'temp_hash', 1, true)
ON CONFLICT (auto_id) DO NOTHING;

-- 5. AHORA SÍ - IMPORTAR LOS DATOS
-- Ejecutar en línea de comandos:
-- psql -h localhost -p 5433 -U postgres -d pos -f "UX_Solo_datos_08_12_2025_dump.sql"
\echo 'AHORA PUEDES IMPORTAR LOS DATOS SIN ERRORES DE FOREIGN KEYS'

-- 6. Después de importar, verificar datos críticos
SELECT
    'users' as tabla,
    COUNT(*) as total_registros,
    MAX(auto_id) as max_id,
    MIN(auto_id) as min_id
FROM public.users

UNION ALL

SELECT
    'action_history' as tabla,
    COUNT(*) as total_registros,
    COUNT(DISTINCT user_id) as users_unicos,
    COUNT(CASE WHEN user_id NOT IN (SELECT auto_id FROM users) THEN 1 END) as users_invalidos
FROM public.action_history;

-- 7. (OPCIONAL) Intentar restaurar constraints que no fallen
\echo 'Intentando restaurar constraints válidos...'
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM temp_constraints
    LOOP
        BEGIN
            -- Intentar restaurar el constraint
            EXECUTE format('
                ALTER TABLE %I.%I
                ADD CONSTRAINT %I
                FOREIGN KEY (%s)
                REFERENCES %I.%s',
                'public', r.table_name, r.constraint_name,
                r.foreign_column_name,
                'public', r.foreign_table_name, r.foreign_column_name);

            RAISE NOTICE 'Constraint % restaurado correctamente', r.constraint_name;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo restaurar constraint %: %', r.constraint_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 8. Limpiar tabla temporal
DROP TABLE IF EXISTS temp_constraints;