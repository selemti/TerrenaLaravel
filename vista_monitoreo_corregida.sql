-- Vista de monitoreo corregida para sincronización Floreant-Laravel

-- 1. Vista para monitorear sincronización en tiempo real
CREATE OR REPLACE VIEW vw_sync_status AS
SELECT
    dah.id as drawer_event_id,
    dah.time as event_time,
    dah.operation,
    dah.a_user as user_id,
    pu.first_name || ' ' || pu.last_name as user_name,
    t.name as terminal_name,
    CASE
        WHEN sc.id IS NOT NULL AND sc.cierre_ts IS NULL THEN 'SESION_ACTIVA'
        WHEN sc.id IS NOT NULL AND sc.cierre_ts IS NOT NULL THEN 'SESION_CERRADA'
        ELSE 'NO_SINCronIZADO'
    END as sync_status,
    sc.id as sesion_id,
    sc.apertura_ts as sesion_apertura,
    sc.cierre_ts as sesion_cierre,
    sc.estatus as sesion_estatus
FROM public.drawer_assigned_history dah
LEFT JOIN public.users pu ON dah.a_user = pu.auto_id
LEFT JOIN public.terminal t ON t.assigned_user = pu.auto_id
LEFT JOIN selemti.sesion_cajon sc ON sc.dah_evento_id = dah.id
WHERE dah.time >= CURRENT_DATE - INTERVAL '2 days'
ORDER BY dah.time DESC;

-- 2. Conteo de sincronización por estado
CREATE OR REPLACE VIEW vw_sync_resumen AS
SELECT
    sync_status,
    COUNT(*) as total_eventos,
    MIN(event_time) as primer_evento,
    MAX(event_time) as ultimo_evento,
    COUNT(DISTINCT user_id) as usuarios_unicos,
    COUNT(DISTINCT terminal_name) as terminales_unicas
FROM vw_sync_status
GROUP BY sync_status
ORDER BY total_eventos DESC;

-- 3. Errores recientes para debugging
CREATE OR REPLACE VIEW vw_sync_errores AS
SELECT
    aud.creado_en as error_timestamp,
    aud.quien as user_id,
    pu.first_name || ' ' || pu.last_name as user_name,
    aud.que as error_type,
    aud.payload->>'error' as error_message,
    aud.payload->>'terminal_id' as terminal_id,
    aud.payload->>'dah_id' as drawer_event_id,
    aud.payload as full_payload
FROM selemti.auditoria aud
LEFT JOIN public.users pu ON aud.quien = pu.auto_id
WHERE aud.que IN ('ERROR_SESION', 'ERROR_CIERRE', 'ERROR_TERMINAL', 'ERROR_CRITICO', 'SIN_TERMINAL')
  AND aud.creado_en >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY aud.creado_en DESC;

-- 4. Verificación de las vistas creadas
SELECT 'Vistas de monitoreo corregidas correctamente' as resultado;
SELECT 'vw_sync_status - Estado completo de sincronización' as vista1;
SELECT 'vw_sync_resumen - Resumen por estado' as vista2;
SELECT 'vw_sync_errores - Errores recientes para debugging' as vista3;