-- Crear una versión mejorada del trigger que maneje conflictos correctamente
-- Reemplaza la función problemática con manejo de errores robusto

-- 1. Eliminar la función antigua
DROP FUNCTION IF EXISTS selemti.fn_dah_after_insert() CASCADE;

-- 2. Crear la función mejorada con manejo de errores
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_term RECORD;
    v_sesion_existente RECORD;
    v_usuario_selemti RECORD;
BEGIN
    -- Verificar que el usuario exista en selemti.users
    SELECT id INTO v_usuario_selemti
    FROM selemti.users
    WHERE id = NEW.a_user;

    IF v_usuario_selemti IS NULL THEN
        -- Usuario no existe en selemti.users, registrar auditoría y continuar
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(
            NEW.a_user,
            'USUARIO_NO_EXISTE_SELEMTI',
            jsonb_build_object(
                'dah_id', NEW.id,
                'operation', NEW.operation,
                'time', NEW.time,
                'a_user', NEW.a_user
            )
        );
        RETURN NEW;
    END IF;

    -- Verificar terminal asignado
    SELECT * INTO v_term
    FROM public.terminal
    WHERE assigned_user = NEW.a_user
    ORDER BY id
    LIMIT 1;

    IF v_term IS NULL THEN
        -- No hay terminal asignado, registrar auditoría y continuar
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(
            NEW.a_user,
            'SIN_TERMINAL_ASIGNADO',
            jsonb_build_object(
                'dah_id', NEW.id,
                'operation', NEW.operation,
                'time', NEW.time,
                'a_user', NEW.a_user
            )
        );
        RETURN NEW;
    END IF;

    -- Manejar operaciones
    IF NEW.operation = 'ASIGNAR' THEN
        -- Verificar si ya existe una sesión activa para este usuario/terminal hoy
        SELECT * INTO v_sesion_existente
        FROM selemti.sesion_cajon
        WHERE terminal_id = v_term.id
          AND cajero_usuario_id = NEW.a_user
          AND DATE(apertura_ts) = CURRENT_DATE
          AND cierre_ts IS NULL;

        IF v_sesion_existente IS NOT NULL THEN
            -- Ya existe sesión activa, registrar auditoría
            INSERT INTO selemti.auditoria(quien, que, payload)
            VALUES(
                NEW.a_user,
                'SESION_EXISTENTE',
                jsonb_build_object(
                    'dah_id', NEW.id,
                    'operacion', NEW.operation,
                    'terminal_id', v_term.id,
                    'sesion_existente_id', v_sesion_existente.id
                )
            );
            RETURN NEW;
        END IF;

        -- Crear nueva sesión
        INSERT INTO selemti.sesion_cajon(
            terminal_id,
            terminal_nombre,
            sucursal,
            cajero_usuario_id,
            apertura_ts,
            estatus,
            opening_float,
            dah_evento_id
        ) VALUES (
            v_term.id,
            COALESCE(v_term.name, 'Terminal ' || v_term.id),
            COALESCE(v_term.location, ''),
            NEW.a_user,
            COALESCE(NEW.time, now()),
            'ACTIVA',
            COALESCE(v_term.current_balance, 0),
            NEW.id
        );

    ELSIF NEW.operation = 'CERRAR' THEN
        -- Cerrar sesión existente
        UPDATE selemti.sesion_cajon
        SET
            cierre_ts = COALESCE(NEW.time, now()),
            estatus = 'LISTO_PARA_CORTE',
            closing_float = COALESCE(v_term.current_balance, 0),
            dah_evento_id = COALESCE(dah_evento_id, NEW.id)
        WHERE terminal_id = v_term.id
          AND cajero_usuario_id = NEW.a_user
          AND cierre_ts IS NULL;
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Registrar cualquier error y continuar
        INSERT INTO selemti.auditoria(quien, que, payload)
        VALUES(
            NEW.a_user,
            'ERROR_TRIGGER_DAH',
            jsonb_build_object(
                'dah_id', NEW.id,
                'operation', NEW.operation,
                'error', SQLERRM,
                'sqlstate', SQLSTATE
            )
        );
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Reactivar el trigger
ALTER TABLE public.drawer_assigned_history ENABLE TRIGGER trg_selemti_dah_ai;

SELECT 'TRIGGER MEJORADO CREADO Y ACTIVADO' as resultado;