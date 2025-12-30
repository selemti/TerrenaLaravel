-- Sistema de sincronización alternativa
-- En lugar de usar triggers, usamos un proceso programado o manual

-- 1. Vista para identificar sesiones que necesitan sincronización
CREATE OR REPLACE VIEW vw_drawer_pending_sync AS
SELECT
    dah.id,
    dah.time,
    dah.operation,
    dah.a_user,
    pu.first_name as user_name,
    pu.first_name || ' ' || pu.last_name as user_fullname,
    t.name as terminal_name,
    CASE
        WHEN sc.id IS NULL THEN 'PENDIENTE'
        ELSE 'PROCESADO'
    END as sync_status,
    dah.time as sync_timestamp
FROM public.drawer_assigned_history dah
JOIN public.users pu ON dah.a_user = pu.auto_id
LEFT JOIN public.terminal t ON t.assigned_user = pu.auto_id
LEFT JOIN selemti.sesion_cajon sc ON sc.dah_evento_id = dah.id
WHERE dah.time >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY dah.time DESC;

-- 2. Procedimiento para sincronizar manualmente
CREATE OR REPLACE FUNCTION sincronizar_drawer_assignments(
    p_desde_fecha DATE DEFAULT CURRENT_DATE - INTERVAL '1 day',
    p_hasta_fecha DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_dah RECORD;
    v_terminal RECORD;
    v_sesion_existente RECORD;
BEGIN
    -- Procesar cada asignación de cajón pendiente
    FOR v_dah IN
        SELECT *
        FROM public.drawer_assigned_history dah
        WHERE dah.time >= p_desde_fecha::timestamp
          AND dah.time <= (p_hasta_fecha + 1)::timestamp
          AND NOT EXISTS (
              SELECT 1 FROM selemti.sesion_cajon sc
              WHERE sc.dah_evento_id = dah.id
          )
        ORDER BY dah.time
    LOOP
        -- Buscar terminal asignado
        SELECT * INTO v_terminal
        FROM public.terminal
        WHERE assigned_user = v_dah.a_user
        LIMIT 1;

        -- Verificar si ya existe sesión activa
        SELECT * INTO v_sesion_existente
        FROM selemti.sesion_cajon
        WHERE terminal_id = COALESCE(v_terminal.id, 0)
          AND cajero_usuario_id = v_dah.a_user
          AND DATE(apertura_ts) = DATE(v_dah.time)
          AND cierre_ts IS NULL;

        -- Procesar según operación
        IF v_dah.operation = 'ASIGNAR' AND v_sesion_existente IS NULL THEN
            -- Crear nueva sesión
            INSERT INTO selemti.sesion_cajon(
                terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
                apertura_ts, estatus, opening_float, dah_evento_id
            ) VALUES (
                COALESCE(v_terminal.id, 0),
                COALESCE(v_terminal.name, 'Terminal ' || v_terminal.id),
                COALESCE(v_terminal.location, ''),
                v_dah.a_user,
                v_dah.time,
                'ACTIVA',
                COALESCE(v_terminal.current_balance, 0),
                v_dah.id
            );
            v_count := v_count + 1;

        ELSIF v_dah.operation = 'CERRAR' AND v_sesion_existente IS NOT NULL THEN
            -- Cerrar sesión existente
            UPDATE selemti.sesion_cajon
            SET
                cierre_ts = v_dah.time,
                estatus = 'LISTO_PARA_CORTE',
                closing_float = COALESCE(v_terminal.current_balance, 0),
                dah_evento_id = COALESCE(dah_evento_id, v_dah.id)
            WHERE id = v_sesion_existente.id;
            v_count := v_count + 1;
        END IF;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Verificación
SELECT 'Sistema de sincronización alternativa creado' as resultado;
SELECT count(*) as pendientes_sincronizar FROM vw_drawer_pending_sync WHERE sync_status = 'PENDIENTE';