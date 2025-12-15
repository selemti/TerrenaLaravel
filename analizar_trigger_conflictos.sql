-- Análisis de conflictos del trigger trg_selemti_dah_ai
-- Identificar exactamente por qué falla

-- 1. Verificar si ya existen sesiones activas para el mismo usuario/terminal
SELECT 'Sesiones activas existentes (pueden causar conflicto UNIQUE):' as info;
SELECT terminal_id, cajero_usuario_id, COUNT(*) as sesiones_activas
FROM selemti.sesion_cajon
WHERE cierre_ts IS NULL
GROUP BY terminal_id, cajero_usuario_id
HAVING COUNT(*) > 0;

-- 2. Verificar el mapeo de usuarios entre public.users y selemti.sesion_cajon
SELECT 'Mapeo de usuarios:' as info;
SELECT pu.auto_id, pu.first_name, COUNT(sc.id) as sesiones_selemti
FROM public.users pu
LEFT JOIN selemti.sesion_cajon sc ON pu.auto_id = sc.cajero_usuario_id
WHERE pu.active = true
GROUP BY pu.auto_id, pu.first_name
ORDER BY pu.auto_id;

-- 3. Verificar usuarios que existen en public pero no en selemti.users
SELECT 'Usuarios en public que no existen en selemti.users:' as info;
SELECT pu.auto_id, pu.first_name, pu.last_name
FROM public.users pu
LEFT JOIN selemti.users su ON pu.auto_id = su.id
WHERE pu.active = true AND su.id IS NULL;

-- 4. Probar el trigger con datos reales
SELECT 'Simulando lo que haría el trigger:' as info;
SELECT
    t.id as terminal_id,
    t.name as terminal_name,
    t.assigned_user,
    pu.auto_id,
    pu.first_name,
    CASE WHEN pu.auto_id IS NOT NULL THEN 'OK' ELSE 'ERROR: Usuario no mapeado' END as status
FROM public.terminal t
LEFT JOIN public.users pu ON t.assigned_user = pu.auto_id
WHERE t.active = true
ORDER BY t.id;

-- 5. Verificar qué usuarios pueden tener múltiples sesiones el mismo día
SELECT 'Posibles conflictos de UNIQUE:' as info;
SELECT
    terminal_id,
    cajero_usuario_id,
    DATE(apertura_ts) as fecha,
    COUNT(*) as sesiones_dia
FROM selemti.sesion_cajon
WHERE apertura_ts >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY terminal_id, cajero_usuario_id, DATE(apertura_ts)
HAVING COUNT(*) > 1
ORDER BY fecha DESC, terminal_id;