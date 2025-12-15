-- Trigger ROBUSTO para sincronización completa Floreant-Laravel
-- Maneja todos los casos sin bloquear operaciones, registrando errores específicos

-- 1. Eliminar trigger anterior si existe
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;

-- 2. Función robusta con manejo completo de errores
CREATE OR REPLACE FUNCTION selemti.fn_dah_robusto()
RETURNS TRIGGER AS $$
DECLARE
    v_terminal_id INTEGER;
    v_terminal_name TEXT;
    v_terminal_location TEXT;
    v_sesion_id BIGINT;
    v_error_message TEXT;
    v_operation_result TEXT;
    v_debug_info JSONB;
BEGIN
    -- Inicializar variables de debugging
    v_error_message := NULL;
    v_operation_result := 'PROCESADO';

    -- Construir información de debugging
    v_debug_info := jsonb_build_object(
        'dah_id', NEW.id,
        'operation', NEW.operation,
        'a_user', NEW.a_user,
        'time', NEW.time,
        'assigned_user', NEW.assigned_user
    );

    -- 1. Obtener información de la terminal asignada
    BEGIN
        SELECT id, name, location INTO v_terminal_id, v_terminal_name, v_terminal_location
        FROM public.terminal
        WHERE assigned_user = NEW.a_user
        LIMIT 1;

        -- Si no hay terminal asignada, registrar pero continuar
        IF v_terminal_id IS NULL THEN
            v_operation_result := 'SIN_TERMINAL';
            v_error_message := 'Usuario ' || NEW.a_user || ' no tiene terminal asignada';

            INSERT INTO selemti.auditoria(quien, que, payload)
            VALUES(NEW.a_user, v_operation_result,
                   v_debug_info || jsonb_build_object('error', v_error_message));
            RETURN NEW;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := 'Error buscando terminal: ' || SQLERRM;
            v_operation_result := 'ERROR_TERMINAL';

            INSERT INTO selemti.auditoria(quien, que, payload)
            VALUES(NEW.a_user, v_operation_result,
                   v_debug_info || jsonb_build_object('error', v_error_message));
            RETURN NEW;
    END;

    -- 2. Procesar según operación
    IF NEW.operation = 'ASIGNAR' THEN
        -- Verificar si ya existe sesión activa para evitar duplicados
        BEGIN
            SELECT id INTO v_sesion_id
            FROM selemti.sesion_cajon
            WHERE terminal_id = v_terminal_id
              AND cajero_usuario_id = NEW.a_user
              AND DATE(apertura_ts) = DATE(NEW.time)
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
                    COALESCE(v_terminal_location, ''),
                    NEW.a_user,
                    NEW.time,
                    'ACTIVA',
                    COALESCE(NEW.amount, 0),
                    NEW.id
                );

                v_operation_result := 'SESION_CREADA';

            ELSE
                v_operation_result := 'SESION_EXISTENTE';
                v_error_message := 'Ya existe sesión activa ID: ' || v_sesion_id;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_message := 'Error creando sesión: ' || SQLERRM;
                v_operation_result := 'ERROR_SESION';
        END;

    ELSIF NEW.operation = 'CERRAR' THEN
        -- Cerrar sesión existente
        BEGIN
            UPDATE selemti.sesion_cajon
            SET
                cierre_ts = NEW.time,
                estatus = 'LISTO_PARA_CORTE',
                closing_float = COALESCE(NEW.amount, 0),
                dah_evento_id = NEW.id
            WHERE terminal_id = v_terminal_id
              AND cajero_usuario_id = NEW.a_user
              AND cierre_ts IS NULL
              AND estatus = 'ACTIVA';

            -- Verificar si se actualizó alguna sesión
            IF NOT FOUND THEN
                v_operation_result := 'SESION_NO_ENCONTRADA';
                v_error_message := 'No hay sesión activa para cerrar';
            ELSE
                v_operation_result := 'SESION_CERRADA';
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_message := 'Error cerrando sesión: ' || SQLERRM;
                v_operation_result := 'ERROR_CIERRE';
        END;

    ELSE
        -- Operación no reconocida
        v_operation_result := 'OPERACION_DESCONOCIDA';
        v_error_message := 'Operación: ' || COALESCE(NEW.operation, 'NULL');
    END IF;

    -- 3. Registrar resultado en auditoría
    BEGIN
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(
            NEW.a_user,
            v_operation_result,
            v_debug_info || jsonb_build_object(
                'terminal_id', v_terminal_id,
                'terminal_name', v_terminal_name,
                'error', v_error_message,
                'timestamp', now()
            )
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Si la auditoría falla, no bloquear la operación principal
            NULL;
    END;

    -- 4. Siempre retornar NEW para no bloquear Floreant
    RETURN NEW;

EXCEPTION
    -- Captura final de errores no manejados
    WHEN OTHERS THEN
        -- Último recurso: registrar error crítico pero no bloquear
        BEGIN
            INSERT INTO selemti.auditoria(quien, que, payload)
            VALUES(NEW.a_user, 'ERROR_CRITICO',
                   v_debug_info || jsonb_build_object('critical_error', SQLERRM));
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- No hacer nada si todo falla
        END;

        RETURN NEW; -- Siempre permitir que continúe Floreant
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el trigger robusto
CREATE TRIGGER trg_selemti_dah_ai
AFTER INSERT ON public.drawer_assigned_history
FOR EACH ROW EXECUTE PROCEDURE selemti.fn_dah_robusto();

-- 4. Verificación de la creación
SELECT 'TRIGGER ROBUSTO CREADO CORRECTAMENTE' as resultado;
SELECT 'Sincronización completa con manejo de errores habilitada' as info;

-- 5. Probar con datos existentes (opcional)
-- SELECT * FROM vw_drawer_pending_sync WHERE sync_status = 'PENDIENTE' LIMIT 5;