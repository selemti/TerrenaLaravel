-- Trigger que REGISTRA errores pero no falla
CREATE OR REPLACE FUNCTION selemti.fn_dah_debug()
RETURNS TRIGGER AS $$
DECLARE
    v_terminal_id INTEGER;
    v_terminal_name TEXT;
    v_error_detalle TEXT;
    v_result TEXT;
BEGIN
    -- Intentar obtener terminal
    SELECT id, name INTO v_terminal_id, v_terminal_name
    FROM public.terminal
    WHERE assigned_user = NEW.a_user
    LIMIT 1;

    -- Registrar intento
    v_result := 'OK';

    -- Operación ASIGNAR
    IF NEW.operation = 'ASIGNAR' THEN
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
            v_result := 'SESION_CREADA';
        EXCEPTION
            WHEN OTHERS THEN
                v_result := 'ERROR_SESION: ' || SQLERRM;
                v_error_detalle := SQLERRM;
        END;
    END IF;

    -- Operación CERRAR
    IF NEW.operation = 'CERRAR' THEN
        BEGIN
            UPDATE selemti.sesion_cajon
            SET
                cierre_ts = NEW.time,
                estatus = 'LISTO_PARA_CORTE',
                closing_float = 0,
                dah_evento_id = NEW.id
            WHERE terminal_id = COALESCE(v_terminal_id, 0)
              AND cajero_usuario_id = NEW.a_user
              AND cierre_ts IS NULL;
            v_result := 'SESION_CERRADA';
        EXCEPTION
            WHEN OTHERS THEN
                v_result := 'ERROR_UPDATE: ' || SQLERRM;
                v_error_detalle := SQLERRM;
        END;
    END IF;

    -- Registrar resultado en auditoría (sin bloquear)
    BEGIN
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(
            NEW.a_user,
            v_result,
            jsonb_build_object(
                'dah_id', NEW.id,
                'operation', NEW.operation,
                'time', NEW.time,
                'terminal_id', v_terminal_id,
                'error', v_error_detalle
            )
        );
        EXCEPTION
            WHEN OTHERS THEN
                -- Si la auditoría falla, ignorar para no bloquear
                NULL;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Reemplazar trigger
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_debug();

SELECT 'TRIGGER DEPURGADO CREADO' as resultado;
SELECT 'Verificar auditoría para ver errores específicos' as info;