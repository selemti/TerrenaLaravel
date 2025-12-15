-- Crear una vista para debugear qué está pasando con las inserciones de Floreant
-- Monitorea las inserciones que fallan en drawer_assigned_history

-- 1. Habilitar log de errores
ALTER SYSTEM SET log_min_error_statement = ERROR;
ALTER SYSTEM SET log_min_messages = INFO;
SELECT pg_reload_conf();

-- 2. Crear función para logging
CREATE OR REPLACE FUNCTION debug_drawer_assigned_history()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'DEBUG: Insertando en drawer_assigned_history: id=%, time=%, operation=%, a_user=%',
        NEW.id, NEW.time, NEW.operation, NEW.a_user;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR en drawer_assigned_history: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear trigger de debug (si no existe)
DROP TRIGGER IF EXISTS debug_dah_trigger ON public.drawer_assigned_history;
CREATE TRIGGER debug_dah_trigger
BEFORE INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE FUNCTION debug_drawer_assigned_history();

-- 4. Verificar estado actual
SELECT 'Estado actual de drawer_assigned_history:' as info;
SELECT COUNT(*) as total_registros, MAX(id) as max_id FROM public.drawer_assigned_history;

SELECT 'Estado del sequence:' as info;
SELECT last_value, is_called FROM drawer_assigned_history_id_seq;

SELECT 'Usuarios disponibles para FK:' as info;
SELECT auto_id, first_name, last_name FROM public.users WHERE active = true ORDER BY auto_id LIMIT 5;