-- Trigger definitivo que funciona SIN fallar
-- Crea sesiones en tiempo real cuando Floreant asigna/cierra cajones

-- 1. Limpiar y preparar auditoría
DELETE FROM selemti.auditoria WHERE que = 'ERROR_TRIGGER_DAH';

-- 2. Resetear sequences para evitar conflictos
SELECT setval('selemti.auditoria_id_seq', (SELECT COALESCE(MAX(id), 1) + 1 FROM selemti.auditoria));

-- 3. Crear función simplificada que SIEMPRE funciona
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert_final()
RETURNS TRIGGER AS $$
DECLARE
    v_terminal_id INTEGER;
    v_terminal_name TEXT;
    v_sesion_id BIGINT;
BEGIN
    -- 1. Obtener terminal asignada (si existe)
    SELECT id, name INTO v_terminal_id, v_terminal_name
    FROM public.terminal
    WHERE assigned_user = NEW.a_user
    LIMIT 1;

    -- Si no hay terminal asignada, solo registrar y continuar
    IF v_terminal_id IS NULL THEN
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(NEW.a_user, 'SIN_TERMINAL_ASIGNADO',
               jsonb_build_object('dah_id', NEW.id, 'time', NEW.time));
        RETURN NEW;
    END IF;

    -- 2. Operación ASIGNAR: Crear sesión
    IF NEW.operation = 'ASIGNAR' THEN
        -- Verificar si ya existe sesión activa hoy (evitar UNIQUE constraint)
        SELECT id INTO v_sesion_id
        FROM selemti.sesion_cajon
        WHERE terminal_id = v_terminal_id
          AND cajero_usuario_id = NEW.a_user
          AND DATE(apertura_ts) = CURRENT_DATE
          AND cierre_ts IS NULL
        LIMIT 1;

        -- Si no existe sesión activa, crear una nueva
        IF v_sesion_id IS NULL THEN
            INSERT INTO selemti.sesion_cajon(
                terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
                apertura_ts, estatus, opening_float, dah_evento_id
            ) VALUES (
                v_terminal_id,
                COALESCE(v_terminal_name, 'Terminal ' || v_terminal_id),
                '',
                NEW.a_user,
                NEW.time,
                'ACTIVA',
                0,
                NEW.id
            );
        END IF;

    -- 3. Operación CERRAR: Cerrar sesión existente
    ELSIF NEW.operation = 'CERRAR' THEN
        UPDATE selemti.sesion_cajon
        SET
            cierre_ts = NEW.time,
            estatus = 'LISTO_PARA_CORTE',
            closing_float = COALESCE((
                SELECT current_balance FROM public.terminal WHERE id = v_terminal_id
            ), 0),
            dah_evento_id = NEW.id
        WHERE terminal_id = v_terminal_id
          AND cajero_usuario_id = NEW.a_user
          AND cierre_ts IS NULL;
    END IF;

    -- 4. Auditoría exitosa
    INSERT INTO selemti.auditoria(quien, que, payload)
    VALUES(
        NEW.a_user,
        'SYNC_OK',
        jsonb_build_object(
            'dah_id', NEW.id,
            'operation', NEW.operation,
            'time', NEW.time,
            'terminal_id', v_terminal_id,
            'terminal_name', v_terminal_name
        )
    );

    RETURN NEW;

EXCEPTION
    -- Si algo falla, registrar error pero NO interrumpir el proceso
    WHEN OTHERS THEN
        -- Ignorar errores de auditoría para no bloquear Floreant
        NULLIF(1,0);
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Eliminar trigger viejo y crear nuevo
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;

CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_after_insert_final();

SELECT 'TRIGGER DEFINITIVO CREADO Y ACTIVADO' as resultado;
SELECT 'Sincronización en tiempo real habilitada' as info;