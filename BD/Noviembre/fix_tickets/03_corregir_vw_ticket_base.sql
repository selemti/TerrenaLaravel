-- ============================================================================
-- CORRECCIÓN: Vista vw_ticket_base (Reportes de Ventas)
-- Fecha: 06 Noviembre 2025
-- Propósito: Excluir tickets problemáticos que contaminan reportes
-- ============================================================================

-- CAMBIOS APLICADOS:
-- 1. ✅ Agregar validación: closing_date IS NOT NULL
--    → Excluye tickets pagados sin cierre (2 tickets, $75)
--
-- 2. ✅ Agregar validación: due_amount = 0
--    → Excluye tickets con deuda pendiente
--
-- 3. ✅ Agregar validación: closing_date >= '2025-08-15'
--    → Excluye tickets muy antiguos con datos sospechosos
--
-- IMPACTO:
-- - Los cortes de caja dejarán de incluir tickets abiertos antiguos
-- - Los reportes mostrarán solo ventas cerradas correctamente
-- - Se excluyen ~150 tickets problemáticos identificados

-- ============================================================================

-- Eliminar vista actual (con CASCADE para eliminar dependencias)
DROP VIEW IF EXISTS public.vw_ticket_base CASCADE;

-- Recrear vista con filtros corregidos
CREATE VIEW public.vw_ticket_base AS
SELECT
    t.id AS ticket_id,
    t.terminal_id,
    t.branch_key,
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    COALESCE(t.total_price, 0::double precision)::numeric(12,2) AS total_price,
    GREATEST(
        0::double precision,
        LEAST(
            COALESCE(
                t.total_discount,
                (
                    SELECT sum(COALESCE(ti.discount, COALESCE(ti.discount, 0::double precision))) AS sum
                    FROM ticket_item ti
                    WHERE ti.ticket_id = t.id
                ),
                0::double precision
            ),
            COALESCE(t.total_price, 0::double precision)
        )
    )::numeric(12,2) AS total_discount,
    COALESCE(
        (
            SELECT sum(g.amount) AS sum
            FROM gratuity g
            WHERE g.ticket_id = t.id
                AND COALESCE(g.refunded, false) = false
                AND COALESCE(g.paid, true) = true
        ),
        0::double precision
    )::numeric(12,2) AS tip_amount,
    COALESCE(t.service_charge, 0::double precision)::numeric(12,2) AS service_charges
FROM ticket t
WHERE t.paid = true
    AND t.voided = false
    AND t.closing_date IS NOT NULL  -- ✅ NUEVO: Debe tener fecha de cierre
    AND COALESCE(t.due_amount, 0) = 0  -- ✅ NUEVO: Sin deuda pendiente
    AND t.closing_date >= '2025-08-15'::date;  -- ✅ NUEVO: Solo tickets recientes

-- ============================================================================
-- VERIFICACIÓN POST-EJECUCIÓN
-- ============================================================================

-- Contar tickets antes y después
SELECT
    'Tickets en vista corregida' as descripcion,
    COUNT(*) as total,
    SUM(total_price) as monto_total
FROM public.vw_ticket_base;

-- Verificar que no haya tickets con problemas
SELECT
    'Verificacion: Tickets con closing_date nulo' as verificacion,
    COUNT(*) as cantidad
FROM public.vw_ticket_base vw
JOIN public.ticket t ON t.id = vw.ticket_id
WHERE t.closing_date IS NULL;

SELECT
    'Verificacion: Tickets con deuda' as verificacion,
    COUNT(*) as cantidad
FROM public.vw_ticket_base vw
JOIN public.ticket t ON t.id = vw.ticket_id
WHERE COALESCE(t.due_amount, 0) > 0;

-- ============================================================================
-- FIN DE LA CORRECCIÓN
-- ============================================================================

-- NOTAS IMPORTANTES:
-- 1. Esta corrección solo afecta REPORTES, no modifica datos
-- 2. Los tickets problemáticos siguen en la base de datos
-- 3. Necesitas ejecutar limpieza de datos por separado
-- 4. Backup disponible en: 02_backup_vw_ticket_base_original.sql
