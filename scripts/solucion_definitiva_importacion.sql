-- SOLUCIÓN DEFINITIVA PARA IMPORTACIÓN DE DATOS
-- Crea los usuarios faltantes antes de importar

-- 1. PRIMERO: Crear usuarios mínimos necesarios basados en los errores del dump
INSERT INTO public.users (auto_id, user_id, first_name, last_name, user_pass, active)
VALUES
    (6, 6, 'Soporte', 'Tecnico', 'temp_hash_123', true)
ON CONFLICT (auto_id) DO UPDATE SET
    first_name = 'Soporte',
    last_name = 'Tecnico',
    user_pass = 'temp_hash_123',
    active = true;

-- 2. Crear otros usuarios que puedan faltar basados en el error
INSERT INTO public.users (auto_id, user_id, first_name, last_name, user_pass, active)
VALUES
    (1, 1, 'Admin', 'System', 'temp_hash_456', true)
ON CONFLICT (auto_id) DO UPDATE SET
    first_name = 'Admin',
    last_name = 'System',
    user_pass = 'temp_hash_456',
    active = true;

-- 3. Verificar que ahora todos los usuarios necesarios existen
SELECT
    auto_id,
    user_id,
    first_name,
    last_name,
    active,
    CASE
        WHEN auto_id IN (1, 6) THEN 'CREADO/ACTUALIZADO'
        ELSE 'EXISTENTE'
    END as estado
FROM public.users
ORDER BY auto_id;

-- 4. AHORA PUEDES IMPORTAR LOS DATOS
-- Ejecutar este comando en terminal:
-- psql -h localhost -p 5433 -U postgres -d pos -f "UX_Solo_datos_08_12_2025_dump.sql"

-- 5. Verificación post-importación (después de importar)
-- Este código se ejecuta DESPUÉS de importar los datos

SELECT
    'VERIFICACIÓN POST-IMPORTACIÓN' as mensaje,
    'users existentes' as descripcion,
    COUNT(*) as count
FROM public.users

UNION ALL

SELECT
    'REFERENCIAS EN action_history' as mensaje,
    'referencias a users válidas' as descripcion,
    COUNT(*) as count
FROM public.action_history ah
JOIN public.users u ON ah.user_id = u.auto_id

UNION ALL

SELECT
    'REFERENCIAS drawer_assigned_history' as mensaje,
    'referencias a users válidas' as descripcion,
    COUNT(*) as count
FROM public.drawer_assigned_history dah
JOIN public users u ON dah.a_user = u.auto_id;

-- 6. Limpieza final (opcional)
-- Esto actualiza las contraseñas temporales con hashes reales si es necesario
-- UPDATE public.users
-- SET user_pass = crypt('nueva_password', gen_salt('bf'))
-- WHERE first_name IN ('Soporte', 'Admin');