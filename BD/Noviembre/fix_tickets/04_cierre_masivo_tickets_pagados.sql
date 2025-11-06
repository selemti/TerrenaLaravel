-- ============================================================================
-- CIERRE MASIVO: Tickets Pagados sin Fecha de Cierre
-- Fecha: 06 Noviembre 2025
-- Propósito: Cerrar tickets que tienen monto > 0, deuda = 0, pero sin closing_date
-- ============================================================================

-- IMPORTANTE: Este script está diseñado para ejecutarse en PRODUCCIÓN
-- Lee atentamente cada sección antes de ejecutar

-- ============================================================================
-- PASO 1: DIAGNÓSTICO - Identificar tickets candidatos
-- ============================================================================
-- Estos son tickets que:
-- - Tienen monto (total_price > 0)
-- - NO tienen deuda (due_amount = 0)
-- - NO están cerrados (closing_date IS NULL)
-- - NO están anulados (voided = false)
-- - Son antiguos (>7 días para evitar tickets del día)

SELECT
    'DIAGNOSTICO: Tickets candidatos para cierre masivo' as descripcion,
    COUNT(*) as cantidad_tickets,
    SUM(total_price) as monto_total,
    MIN(create_date::date) as fecha_mas_antigua,
    MAX(create_date::date) as fecha_mas_reciente
FROM public.ticket
WHERE total_price > 0
    AND COALESCE(due_amount, 0) = 0
    AND closing_date IS NULL
    AND voided = false
    AND paid = false  -- No están marcados como pagados
    AND create_date < CURRENT_DATE - INTERVAL '7 days';  -- Solo antiguos

-- Ver detalle de los primeros 20
SELECT
    id,
    create_date::date as fecha_creacion,
    total_price,
    due_amount,
    terminal_id,
    branch_key,
    ticket_type,
    CURRENT_DATE - create_date::date as dias_desde_creacion,
    (SELECT COUNT(*) FROM transactions tx WHERE tx.ticket_id = ticket.id AND tx.voided = false) as num_transacciones,
    (SELECT SUM(tx.amount) FROM transactions tx WHERE tx.ticket_id = ticket.id AND tx.voided = false) as monto_pagado
FROM public.ticket
WHERE total_price > 0
    AND COALESCE(due_amount, 0) = 0
    AND closing_date IS NULL
    AND voided = false
    AND paid = false
    AND create_date < CURRENT_DATE - INTERVAL '7 days'
ORDER BY create_date DESC
LIMIT 20;

-- ============================================================================
-- PASO 2: VERIFICACIÓN DE SEGURIDAD
-- ============================================================================
-- Verificar que estos tickets NO tienen transacciones pendientes

SELECT
    'VERIFICACION: Tickets con transacciones no procesadas' as alerta,
    COUNT(*) as cantidad
FROM public.ticket t
WHERE t.total_price > 0
    AND COALESCE(t.due_amount, 0) = 0
    AND t.closing_date IS NULL
    AND t.voided = false
    AND t.paid = false
    AND t.create_date < CURRENT_DATE - INTERVAL '7 days'
    AND EXISTS (
        SELECT 1 FROM transactions tx
        WHERE tx.ticket_id = t.id
        AND tx.voided = false
        AND UPPER(tx.transaction_type) NOT IN ('CREDIT', 'CASH')
    );

-- Si el resultado anterior es > 0, REVISAR MANUALMENTE esos tickets antes de continuar

-- ============================================================================
-- PASO 3: BACKUP - Guardar estado actual
-- ============================================================================
-- IMPORTANTE: Ejecutar esto ANTES de hacer cambios

CREATE TABLE IF NOT EXISTS public.backup_tickets_cierre_masivo_20251106 AS
SELECT
    t.*,
    CURRENT_TIMESTAMP as backup_timestamp,
    'Backup antes de cierre masivo' as backup_reason
FROM public.ticket t
WHERE t.total_price > 0
    AND COALESCE(t.due_amount, 0) = 0
    AND t.closing_date IS NULL
    AND t.voided = false
    AND t.paid = false
    AND t.create_date < CURRENT_DATE - INTERVAL '7 days';

-- Verificar que el backup se creó correctamente
SELECT
    'BACKUP CREADO' as estado,
    COUNT(*) as tickets_respaldados
FROM public.backup_tickets_cierre_masivo_20251106;

-- ============================================================================
-- PASO 4: CIERRE MASIVO - EJECUCIÓN
-- ============================================================================
-- Este UPDATE cerrará los tickets cumpliendo con:
-- 1. Asignar closing_date = create_date (fecha en que se creó el ticket)
-- 2. Marcar como paid = true
-- 3. Actualizar paid_amount
-- 4. Asegurar que due_amount = 0

-- VERSIÓN CONSERVADORA (Solo tickets >30 días)
-- Recomendado para primera ejecución
BEGIN;

UPDATE public.ticket
SET
    closing_date = create_date,
    paid = true,
    paid_amount = COALESCE(total_price, 0),
    due_amount = 0,
    status = 'CLOSED'
WHERE total_price > 0
    AND COALESCE(due_amount, 0) = 0
    AND closing_date IS NULL
    AND voided = false
    AND paid = false
    AND create_date < CURRENT_DATE - INTERVAL '30 days';  -- Solo >30 días

-- Verificar cuántos tickets se actualizaron
SELECT
    'TICKETS ACTUALIZADOS (>30 dias)' as resultado,
    COUNT(*) as cantidad
FROM public.ticket
WHERE closing_date = create_date::timestamp
    AND paid = true
    AND create_date < CURRENT_DATE - INTERVAL '30 days'
    AND create_date >= CURRENT_DATE - INTERVAL '120 days';

-- Si todo se ve bien, hacer COMMIT
COMMIT;
-- Si algo sale mal, hacer ROLLBACK;

-- ============================================================================
-- PASO 5 (OPCIONAL): CIERRE MASIVO AGRESIVO
-- ============================================================================
-- Ejecutar SOLO si el paso 4 funcionó correctamente
-- Esto cerrará tickets de 7-30 días

-- BEGIN;

-- UPDATE public.ticket
-- SET
--     closing_date = create_date,
--     paid = true,
--     paid_amount = COALESCE(total_price, 0),
--     due_amount = 0,
--     status = 'CLOSED'
-- WHERE total_price > 0
--     AND COALESCE(due_amount, 0) = 0
--     AND closing_date IS NULL
--     AND voided = false
--     AND paid = false
--     AND create_date >= CURRENT_DATE - INTERVAL '30 days'
--     AND create_date < CURRENT_DATE - INTERVAL '7 days';

-- COMMIT;

-- ============================================================================
-- PASO 6: VERIFICACIÓN POST-EJECUCIÓN
-- ============================================================================

-- Verificar cuántos tickets quedan pendientes
SELECT
    'TICKETS PENDIENTES DESPUÉS DEL CIERRE MASIVO' as estado,
    COUNT(*) as cantidad_restante,
    SUM(total_price) as monto_restante
FROM public.ticket
WHERE total_price > 0
    AND COALESCE(due_amount, 0) = 0
    AND closing_date IS NULL
    AND voided = false
    AND paid = false;

-- Verificar tickets cerrados hoy
SELECT
    'TICKETS CERRADOS HOY' as estado,
    COUNT(*) as cantidad,
    SUM(total_price) as monto_total
FROM public.ticket
WHERE closing_date::date = CURRENT_DATE
    AND paid = true;

-- Verificar que los tickets cerrados aparecen en vw_ticket_base
SELECT
    'TICKETS EN REPORTES DESPUÉS DEL CIERRE' as verificacion,
    COUNT(*) as cantidad_en_reportes
FROM public.vw_ticket_base
WHERE folio_date = CURRENT_DATE;

-- ============================================================================
-- PASO 7: ROLLBACK (SOLO SI ALGO SALIÓ MAL)
-- ============================================================================
-- Si necesitas revertir los cambios, ejecuta esto:

-- BEGIN;
--
-- -- Restaurar desde el backup
-- UPDATE public.ticket t
-- SET
--     closing_date = b.closing_date,
--     paid = b.paid,
--     paid_amount = b.paid_amount,
--     due_amount = b.due_amount,
--     status = b.status
-- FROM public.backup_tickets_cierre_masivo_20251106 b
-- WHERE t.id = b.id;
--
-- COMMIT;

-- ============================================================================
-- RESUMEN DE EJECUCIÓN
-- ============================================================================

SELECT
    'RESUMEN FINAL' as titulo,
    (SELECT COUNT(*) FROM backup_tickets_cierre_masivo_20251106) as tickets_respaldados,
    (SELECT COUNT(*) FROM public.ticket WHERE total_price > 0 AND due_amount = 0 AND closing_date IS NULL AND voided = false AND paid = false) as tickets_pendientes,
    (SELECT COUNT(*) FROM public.vw_ticket_base WHERE folio_date >= CURRENT_DATE - INTERVAL '7 days') as tickets_en_reportes_ultimos_7d;

-- ============================================================================
-- LIMPIEZA (OPCIONAL - Ejecutar después de verificar que todo está bien)
-- ============================================================================
-- Después de 30 días, si todo está correcto, puedes eliminar la tabla de backup:
-- DROP TABLE IF EXISTS public.backup_tickets_cierre_masivo_20251106;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 1. Este script usa transacciones (BEGIN/COMMIT) para poder revertir si algo sale mal
-- 2. El backup se crea automáticamente en la tabla backup_tickets_cierre_masivo_20251106
-- 3. Solo afecta tickets >30 días en la versión conservadora
-- 4. Puedes ejecutar el PASO 5 para tickets de 7-30 días después de verificar
-- 5. Todos los cambios quedan registrados en el backup
-- 6. Si algo sale mal, ejecuta ROLLBACK; o usa el PASO 7

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
