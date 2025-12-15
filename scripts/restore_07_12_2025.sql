-- ========================================
-- RESTAURACIÓN BACKUP 07_12_2025
-- Estrategia: PUBLIC completo + SELEMTI selectivo
-- ========================================

-- Iniciar transacción
BEGIN;

-- Deshabilitar triggers y constraints
SET session_replication_role = replica;

-- ========================================
-- 1. ELIMINAR DATOS EXISTENTES DE PUBLIC
-- ========================================

-- Eliminar tablas de PUBLIC en orden correcto (hijos primero)
DROP TABLE IF EXISTS public.ticket_item_modifier CASCADE;
DROP TABLE IF EXISTS public.ticket_item_addon_relation CASCADE;
DROP TABLE IF EXISTS public.ticket_item_cooking_instruction CASCADE;
DROP TABLE IF EXISTS public.ticket_item CASCADE;
DROP TABLE IF EXISTS public.ticket_discount CASCADE;
DROP TABLE IF EXISTS public.ticket CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.payment CASCADE;
DROP TABLE IF EXISTS public.drawer_pull_report CASCADE;
DROP TABLE IF EXISTS public.drawer_pull_report_voidtickets CASCADE;
DROP TABLE IF EXISTS public.cash_drawer CASCADE;
DROP TABLE IF EXISTS public.terminal CASCADE;
DROP TABLE IF EXISTS public.user CASCADE;
DROP TABLE IF EXISTS public.restaurant CASCADE;
DROP TABLE IF EXISTS public.shift CASCADE;

-- ========================================
-- 2. RESTAURAR TABLAS DE CORTES EN SELEMTI
-- (Solo las que queremos actualizar)
-- ========================================

-- Eliminar datos existentes (preservar estructura)
DELETE FROM selemti.postcorte;
DELETE FROM selemti.precorte_otros;
DELETE FROM selemti.precorte_efectivo;
DELETE FROM selemti.precorte;
DELETE FROM selemti.sesion_cajon;
DELETE FROM selemti.conciliacion;
DELETE FROM selemti.alertas_cortes;
DELETE FROM selemti.caja_fondo_arqueo;
DELETE FROM selemti.cash_fund_arqueos;

-- Resetear secuencias
ALTER SEQUENCE selemti.sesion_cajon_id_seq RESTART WITH 1;
ALTER SEQUENCE selemti.precorte_id_seq RESTART WITH 1;
ALTER SEQUENCE selemti.postcorte_id_seq RESTART WITH 1;

-- ========================================
-- 3. IMPORTAR DEL BACKUP
-- ========================================

-- Nota: Esto se ejecutará después con el comando psql completo
-- psql -h localhost -p 5433 -U postgres -d pos -f BD/Diciembre/07_12_2025/dump_UX_07_12_2025.sql

-- Pero primero necesitamos preparar el entorno
SET client_min_messages = warning;

-- ========================================
-- 4. POST-PROCESAMIENTO
-- ========================================

-- Rehabilitar triggers
SET session_replication_role = DEFAULT;

-- Actualizar secuencias para tablas PUBLIC
SELECT setval(pg_get_serial_sequence('public.ticket', 'id'), coalesce(max(id), 1)) FROM public.ticket;
SELECT setval(pg_get_serial_sequence('public.ticket_item', 'id'), coalesce(max(id), 1)) FROM public.ticket_item;
SELECT setval(pg_get_serial_sequence('public.terminal', 'id'), coalesce(max(id), 1)) FROM public.terminal;
SELECT setval(pg_get_serial_sequence('public.user', 'id'), coalesce(max(id), 1)) FROM public.user;

-- Actualizar secuencias para tablas SELEMTI
SELECT setval(pg_get_serial_sequence('selemti.sesion_cajon', 'id'), coalesce(max(id), 1)) FROM selemti.sesion_cajon;
SELECT setval(pg_get_serial_sequence('selemti.precorte', 'id'), coalesce(max(id), 1)) FROM selemti.precorte;
SELECT setval(pg_get_serial_sequence('selemti.postcorte', 'id'), coalesce(max(id), 1)) FROM selemti.postcorte;

-- Analizar tablas para optimizar rendimiento
ANALYZE public.ticket;
ANALYZE public.ticket_item;
ANALYZE public.ticket_item_modifier;
ANALYZE public.transactions;
ANALYZE public.terminal;
ANALYZE public.user;
ANALYZE selemti.sesion_cajon;
ANALYZE selemti.precorte;
ANALYZE selemti.postcorte;
ANALYZE selemti.mov_inv;

-- ========================================
-- 5. VERIFICACIÓN
-- ========================================

-- Mostrar resumen de datos restaurados
SELECT 'RESUMEN DE RESTAURACIÓN' as info, '' as detalle
UNION ALL
SELECT
    'Tickets totales', COUNT(*)::text
FROM public.ticket
UNION ALL
SELECT
    'Items de tickets', COUNT(*)::text
FROM public.ticket_item
UNION ALL
SELECT
    'Modificadores de items', COUNT(*)::text
FROM public.ticket_item_modifier
UNION ALL
SELECT
    'Sesiones de cajón', COUNT(*)::text
FROM selemti.sesion_cajon
UNION ALL
SELECT
    'Precortes', COUNT(*)::text
FROM selemti.precorte
UNION ALL
SELECT
    'Postcortes', COUNT(*)::text
FROM selemti.postcorte
UNION ALL
SELECT
    'Transacciones', COUNT(*)::text
FROM public.transactions
ORDER BY info;

-- Verificar integridad básica
SELECT
    'VERIFICACIÓN DE INTEGRIDAD' as check_type,
    CASE
        WHEN COUNT(*) > 0 THEN 'Tickets sin items: ' || COUNT(*)::text
        ELSE 'Todos los tickets tienen items'
    END as result
FROM public.ticket t
LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
WHERE ti.ticket_id IS NULL

UNION ALL

SELECT
    'Sesiones sin precorte',
    CASE
        WHEN COUNT(*) > 0 THEN 'Sesiones abiertas: ' || COUNT(*)::text
        ELSE 'Todas las sesiones tienen precorte'
    END
FROM selemti.sesion_cajon sc
LEFT JOIN selemti.precorte p ON sc.id = p.sesion_cajon_id
WHERE p.sesion_cajon_id IS NULL;

-- Finalizar transacción
COMMIT;

-- Finalizado: SELECT CURRENT_TIMESTAMP;

-- ========================================
-- INSTRUCCIONES PARA EJECUTAR
-- ========================================

-- 1. Ejecutar este archivo primero:
--    psql -h localhost -p 5433 -U postgres -d pos -f scripts/restore_07_12_2025.sql
--
-- 2. Luego ejecutar el backup completo (restaurará todo pero preservará estructura):
--    psql -h localhost -p 5433 -U postgres -d pos -f BD/Diciembre/07_12_2025/dump_UX_07_12_2025.sql
--
-- NOTA: El paso 1 limpia y prepara. El paso 2 restaura todos los datos.