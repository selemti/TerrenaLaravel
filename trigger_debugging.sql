-- Trigger simplificado para debugging del problema

-- 1. Primero, probar manualmente la lógica del trigger
DO $$
DECLARE
    v_user_id INTEGER := 7;
    v_terminal_id INTEGER;
    v_terminal_name TEXT;
BEGIN
    -- Probar la consulta que busca la terminal
    SELECT id, name INTO v_terminal_id, v_terminal_name
    FROM public.terminal
    WHERE assigned_user = v_user_id
    LIMIT 1;

    RAISE NOTICE 'Usuario %: Terminal ID = %, Nombre = %', v_user_id, v_terminal_id, v_terminal_name;

    -- Probar inserción en sesión
    INSERT INTO selemti.sesion_cajon(
        terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
        apertura_ts, estatus, opening_float, dah_evento_id
    ) VALUES (
        v_terminal_id,
        COALESCE(v_terminal_name, 'Terminal ' || v_terminal_id),
        'TEST',
        v_user_id,
        CURRENT_TIMESTAMP,
        'ACTIVA',
        0,
        999
    );

    RAISE NOTICE 'Sesión de prueba creada correctamente';
END $$;

-- 2. Verificar si se creó
SELECT * FROM selemti.sesion_cajon WHERE dah_evento_id = 999;