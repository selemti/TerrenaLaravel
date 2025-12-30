-- Solución completa para problemas de Floreant POS
-- Ejecutar si los errores persisten

-- 1. Limpiar completamente drawer_assigned_history y empezar fresco
TRUNCATE TABLE public.drawer_assigned_history RESTART IDENTITY CASCADE;

-- 2. Resetear sequence a valor inicial
ALTER SEQUENCE public.drawer_assigned_history_id_seq RESTART WITH 1;

-- 3. Verificar todos los usuarios activos
SELECT 'Usuarios activos:' as info;
SELECT auto_id, first_name, last_name, user_id, active
FROM public.users
WHERE active = true
ORDER BY auto_id;

-- 4. Verificar terminales disponibles
SELECT 'Terminales disponibles:' as info;
SELECT id, name, assigned_user, active
FROM public.terminal
WHERE active = true
ORDER BY id;

-- 5. Desactivar completamente todos los triggers problemáticos
ALTER TABLE public.drawer_assigned_history DISABLE TRIGGER ALL;

-- 6. Crear índices si no existen para mejorar performance
CREATE INDEX IF NOT EXISTS idx_dah_time_user ON public.drawer_assigned_history("time", a_user);

-- 7. Dar permisos explícitos
GRANT ALL ON TABLE public.drawer_assigned_history TO floreant;
GRANT ALL ON SEQUENCE public.drawer_assigned_history_id_seq TO floreant;

SELECT 'FIX COMPLETO - Intenta usar Floreant ahora' as resultado;