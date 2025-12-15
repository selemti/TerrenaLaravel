-- ========================================
-- RESTAURACIÓN BACKUP 07_12_2025
-- Estrategia: PUBLIC completo + SELEMTI selectivo
-- Fecha de ejecución: 2025-12-08 03:53:54
-- ========================================

-- CREAR BACKUP ANTES DE RESTAURAR
DO $$
DECLARE
    backup_name TEXT := 'pre_restore_07_12_2025_' || to_char(now(), 'YYYY_MM_DD_HH24_MI_SS');
BEGIN
    EXECUTE 'CREATE DATABASE IF NOT EXISTS backup_' || backup_name;
    RAISE NOTICE 'Backup creado: %', backup_name;
END$$;

\c pos

-- ========================================
-- 1. RESTAURACIÓN COMPLETA SCHEMA PUBLIC
-- ========================================

-- RESTAURACIÓN COMPLETA SCHEMA PUBLIC
-- Backup: 07_12_2025

-- Deshabilitar checks de claves foráneas
SET session_replication_role = replica;


-- ========================================
-- 2. RESTAURACIÓN SELECTIVA SCHEMA SELEMTI
-- ========================================

-- RESTAURACIÓN SELECTIVA SCHEMA SELEMTI
-- Solo cortes y datos esenciales
-- Backup: 07_12_2025

-- Deshabilitar checks de claves foráneas
SET session_replication_role = replica;


-- ========================================
-- 3. POST-PROCESAMIENTO
-- ========================================

-- Rehabilitar checks de claves foráneas
SET session_replication_role = DEFAULT;

-- Actualizar secuencias importantes
SELECT setval(pg_get_serial_sequence('public.ticket', 'id'), coalesce(max(id), 1)) FROM public.ticket;
SELECT setval(pg_get_serial_sequence('public.ticket_item', 'id'), coalesce(max(id), 1)) FROM public.ticket_item;
SELECT setval(pg_get_serial_sequence('public.terminal', 'id'), coalesce(max(id), 1)) FROM public.terminal;
SELECT setval(pg_get_serial_sequence('selemti.sesion_cajon', 'id'), coalesce(max(id), 1)) FROM selemti.sesion_cajon;

-- Analizar tablas para optimizar consultas
ANALYZE public.ticket;
ANALYZE public.ticket_item;
ANALYZE public.transactions;
ANALYZE selemti.sesion_cajon;
ANALYZE selemti.mov_inv;

-- ========================================
-- 4. RESUMEN DE RESTAURACIÓN
-- ========================================

-- Mostrar registros restaurados principales
SELECT 
    'ticket' as tabla, COUNT(*) as registros
FROM public.ticket
UNION ALL
SELECT 'ticket_item', COUNT(*) FROM public.ticket_item
UNION ALL
SELECT 'sesion_cajon', COUNT(*) FROM selemti.sesion_cajon
UNION ALL
SELECT 'precorte', COUNT(*) FROM selemti.precorte
UNION ALL
SELECT 'postcorte', COUNT(*) FROM selemti.postcorte
ORDER BY registros DESC;

-- Verificar integridad referencial básica
SELECT 
    'Tickets sin items' as issue, COUNT(*) as count
FROM public.ticket t
LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
WHERE ti.ticket_id IS NULL
UNION ALL
SELECT 
    'Sesiones sin precorte', COUNT(*)
FROM selemti.sesion_cajon sc
LEFT JOIN selemti.precorte p ON sc.id = p.sesion_cajon_id
WHERE p.sesion_cajon_id IS NULL;

-- Finalizado: 2025-12-08 03:53:54
COMMIT;
