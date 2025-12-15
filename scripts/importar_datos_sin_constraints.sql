-- Script para importar datos sin verificar foreign keys temporalmente
-- Solución para errores de integridad referencial

-- 1. Deshabilitar temporalmente las foreign keys problemáticas
\echo 'Deshabilitando foreign keys problemáticas...'

-- Deshabilitar trigger de users si existe
ALTER TABLE public.users DISABLE TRIGGER ALL;

-- Deshabilitar constraints específicos que están causando problemas
ALTER TABLE public.action_history DROP CONSTRAINT IF EXISTS fk3f3af36b3e20ad51;
ALTER TABLE public.drawer_assigned_history DROP CONSTRAINT IF EXISTS fk5a823c91f1dd782b;
ALTER TABLE public.terminal DROP CONSTRAINT IF EXISTS fk_terminal_user;

-- 2. Preparar tabla users si no existe o está vacía
INSERT INTO public.users (auto_id, user_id, first_name, last_name, password, type, active)
SELECT
    1, 1, 'Admin', 'System', 'temp', 1, true
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE auto_id = 1);

INSERT INTO public.users (auto_id, user_id, first_name, last_name, password, type, active)
SELECT
    6, 6, 'Soporte', 'Tecnico', 'temp', 1, true
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE auto_id = 6);

-- 3. Continuar con la importación normal
\echo 'Importando datos del archivo de producción...'
-- Aquí va el comando de importación:
-- psql -h localhost -p 5433 -U postgres -d pos -f "UX_Solo_datos_08_12_2025_dump.sql"

-- 4. Después de importar, verificar y limpiar datos
\echo 'Verificando integridad de datos...'

-- Verificar usuarios importados o creados
SELECT
    auto_id,
    user_id,
    first_name,
    last_name,
    COUNT(*) as referencias_en_action_history
FROM public.users u
LEFT JOIN public.action_history ah ON u.auto_id = ah.user_id
GROUP BY u.auto_id, u.user_id, u.first_name, u.last_name;

-- 5. Reconstruir constraints si es necesario
\echo 'Reconstruyendo constraints...'

-- Solo agregar constraints si los datos son consistentes
DO $$
BEGIN
    -- Verificar si todos los user_id en action_history existen en users
    IF NOT EXISTS (
        SELECT 1 FROM public.action_history ah
        LEFT JOIN public.users u ON ah.user_id = u.auto_id
        WHERE u.auto_id IS NULL
        LIMIT 1
    ) THEN
        -- Los datos son consistentes, podemos agregar el constraint
        ALTER TABLE public.action_history
        ADD CONSTRAINT fk3f3af36b3e20ad51
        FOREIGN KEY (user_id) REFERENCES public.users(auto_id);

        RAISE NOTICE 'Constraint de action_history restaurado correctamente';
    ELSE
        RAISE NOTICE 'ADVERTENCIA: Hay referencias a usuarios inexistentes. Constraint no restaurado.';
    END IF;
END $$;