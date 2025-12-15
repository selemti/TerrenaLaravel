-- Restauración Selectiva - Backup 07_12_2025
-- Target: Schema PUBLIC y tablas de cortes
-- Fecha: 2025-12-08 03:52:21

-- Deshabilitar triggers
SET session_replication_role = replica;

-- Dropear tablas existentes (con cuidado)
DROP TABLE IF EXISTS public.ticket CASCADE;
DROP TABLE IF EXISTS public.ticket_item CASCADE;
DROP TABLE IF EXISTS public.ticket_item_modifier CASCADE;
DROP TABLE IF EXISTS public.ticket_discount CASCADE;
DROP TABLE IF EXISTS public.ticket_item_addon_relation CASCADE;
DROP TABLE IF EXISTS public.ticket_item_cooking_instruction CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.payment CASCADE;
DROP TABLE IF EXISTS public.terminal CASCADE;
DROP TABLE IF EXISTS public.cash_drawer CASCADE;
DROP TABLE IF EXISTS public.drawer_pull_report CASCADE;
DROP TABLE IF EXISTS public.drawer_pull_report_voidtickets CASCADE;
DROP TABLE IF EXISTS public.user CASCADE;
DROP TABLE IF EXISTS public.restaurant CASCADE;
DROP TABLE IF EXISTS public.shift CASCADE;
DROP TABLE IF EXISTS public.tax CASCADE;
DROP TABLE IF EXISTS public.menu_item CASCADE;
DROP TABLE IF EXISTS public.menu_group CASCADE;
DROP TABLE IF EXISTS public.menu_item_modifier_group CASCADE;
DROP TABLE IF EXISTS public.menu_modifier CASCADE;
DROP TABLE IF EXISTS public.menu_modifier_group CASCADE;

-- Restaurar tablas PUBLIC

-- Restaurar tablas de cortes

-- Rehabilitar triggers
SET session_replication_role = DEFAULT;

-- Actualizar secuencias
SELECT setval(pg_get_serial_sequence('public.ticket', 'id'), coalesce(max(id), 1)) FROM public.ticket;
SELECT setval(pg_get_serial_sequence('public.ticket_item', 'id'), coalesce(max(id), 1)) FROM public.ticket_item;
SELECT setval(pg_get_serial_sequence('public.terminal', 'id'), coalesce(max(id), 1)) FROM public.terminal;

-- Analizar tablas para optimizar rendimiento
ANALYZE public.ticket;
ANALYZE public.ticket_item;
ANALYZE public.ticket_item_modifier;
ANALYZE public.transactions;
ANALYZE public.terminal;

-- Contar registros restaurados
SELECT 'ticket' as table_name, COUNT(*) as records FROM public.ticket
UNION ALL
SELECT 'ticket_item', COUNT(*) FROM public.ticket_item
UNION ALL
SELECT 'ticket_item_modifier', COUNT(*) FROM public.ticket_item_modifier
UNION ALL
SELECT 'transactions', COUNT(*) FROM public.transactions
UNION ALL
SELECT 'terminal', COUNT(*) FROM public.terminal;

COMMIT;

-- Finalizado: 2025-12-08 03:52:21
