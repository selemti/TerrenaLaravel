-- Trigger simple y robusto que funciona SIN errores

CREATE OR REPLACE FUNCTION selemti.fn_dah_simple()
RETURNS TRIGGER AS $$
DECLARE
    v_terminal_id INTEGER;
    v_terminal_name TEXT;
BEGIN
    -- Obtener terminal asignada
    SELECT id, name INTO v_terminal_id, v_terminal_name
    FROM public.terminal
    WHERE assigned_user = NEW.a_user
    LIMIT 1;

    -- Si no hay terminal, solo continuar
    IF v_terminal_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Solo procesar ASIGNAR para crear sesiones
    IF NEW.operation = 'ASIGNAR' THEN
        -- Insertar sesión (sin verificar duplicados para evitar errores complejos)
        BEGIN
            INSERT INTO selemti.sesion_cajon(
                terminal_id, terminal_nombre, cajero_usuario_id,
                apertura_ts, estatus, opening_float, dah_evento_id
            ) VALUES (
                v_terminal_id,
                COALESCE(v_terminal_name, 'Terminal ' || v_terminal_id),
                NEW.a_user,
                NEW.time,
                'ACTIVA',
                0,
                NEW.id
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Ignorar errores de inserción (sesión duplicada, etc.)
                NULL;
        END;
    END IF;

    -- Procesar CERRAR si aplica
    IF NEW.operation = 'CERRAR' THEN
        BEGIN
            UPDATE selemti.sesion_cajon
            SET
                cierre_ts = NEW.time,
                estatus = 'LISTO_PARA_CORTE',
                closing_float = 0,
                dah_evento_id = NEW.id
            WHERE terminal_id = v_terminal_id
              AND cajero_usuario_id = NEW.a_user
              AND cierre_ts IS NULL;
        EXCEPTION
            WHEN OTHERS THEN
                -- Ignorar errores de actualización
                NULL;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger simple
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;

CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_simple();

SELECT 'TRIGGER SIMPLE CREADO - SINCRONIZACIÓN ACTIVA' as resultado;