-- ============================================================================
-- SCRIPT DE DIAGNÓSTICO: Tickets Problemáticos
-- Fecha: 06 Noviembre 2025
-- Propósito: Identificar y clasificar todos los tickets con problemas
-- ============================================================================

-- RESUMEN GENERAL POR TIPO DE PROBLEMA
-- ============================================================================
WITH ticket_problems AS (
  SELECT
    CASE
      WHEN paid = true AND closing_date IS NULL THEN 'PAGADO_SIN_CIERRE'
      WHEN paid = false AND closing_date IS NOT NULL THEN 'CERRADO_SIN_PAGO'
      WHEN paid = false AND closing_date IS NULL AND due_amount > 0 THEN 'ABIERTO_CON_DEUDA'
      WHEN paid = false AND closing_date IS NULL AND total_price = 0 THEN 'ABIERTO_VACIO'
      ELSE 'NORMAL'
    END as problema,
    COUNT(*) as cantidad,
    SUM(total_price) as monto_total,
    SUM(due_amount) as deuda_total,
    MIN(create_date::date) as fecha_mas_antigua,
    MAX(create_date::date) as fecha_mas_reciente
  FROM public.ticket
  WHERE voided = false
  GROUP BY problema
)
SELECT * FROM ticket_problems
WHERE problema != 'NORMAL'
ORDER BY cantidad DESC;

-- DETALLE DE CADA TIPO DE PROBLEMA
-- ============================================================================

-- TIPO A: Tickets Cerrados sin Pago (CRÍTICO)
-- ----------------------------------------------------------------------------
SELECT
    'TIPO_A' as categoria,
    t.id,
    t.create_date,
    t.closing_date,
    t.total_price,
    t.due_amount,
    t.terminal_id,
    t.branch_key,
    t.status,
    (SELECT COUNT(*) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as num_transacciones,
    (SELECT SUM(tx.amount) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as monto_transacciones,
    CURRENT_DATE - t.create_date::date AS dias_desde_creacion
FROM public.ticket t
WHERE t.paid = false
    AND t.closing_date IS NOT NULL
    AND t.voided = false
ORDER BY t.create_date DESC;

-- TIPO B: Tickets Abiertos con Deuda
-- ----------------------------------------------------------------------------
SELECT
    'TIPO_B' as categoria,
    t.id,
    t.create_date,
    t.total_price,
    t.due_amount,
    t.terminal_id,
    t.branch_key,
    t.ticket_type,
    CURRENT_DATE - t.create_date::date AS dias_abierto,
    (SELECT COUNT(*) FROM ticket_item ti WHERE ti.ticket_id = t.id) as num_items
FROM public.ticket t
WHERE t.paid = false
    AND t.closing_date IS NULL
    AND t.voided = false
    AND t.due_amount > 0
ORDER BY t.create_date;

-- TIPO C: Tickets Abiertos Vacíos
-- ----------------------------------------------------------------------------
SELECT
    'TIPO_C' as categoria,
    t.id,
    t.create_date,
    t.terminal_id,
    t.branch_key,
    t.ticket_type,
    CURRENT_DATE - t.create_date::date AS dias_abierto,
    (SELECT COUNT(*) FROM ticket_item ti WHERE ti.ticket_id = t.id) as num_items
FROM public.ticket t
WHERE t.paid = false
    AND t.closing_date IS NULL
    AND t.voided = false
    AND t.total_price = 0
ORDER BY t.create_date;

-- TIPO D: Tickets Pagados sin Cierre
-- ----------------------------------------------------------------------------
SELECT
    'TIPO_D' as categoria,
    t.id,
    t.create_date,
    t.total_price,
    t.paid_amount,
    t.due_amount,
    t.terminal_id,
    t.branch_key,
    t.drawer_resetted,
    t.is_re_opened,
    (SELECT COUNT(*) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as num_transacciones,
    (SELECT SUM(tx.amount) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as monto_transacciones
FROM public.ticket t
WHERE t.paid = true
    AND t.closing_date IS NULL
    AND t.voided = false
ORDER BY t.create_date;

-- ANÁLISIS DE TICKETS HUÉRFANOS (Sin Transacciones)
-- ============================================================================
SELECT
    t.id AS ticket_id,
    t.create_date,
    t.closing_date,
    t.paid,
    t.total_price,
    t.due_amount,
    t.branch_key,
    'ORPHAN_TICKET' AS problema
FROM ticket t
LEFT JOIN transactions tx ON tx.ticket_id = t.id AND tx.voided = false
WHERE t.paid = true
    AND t.voided = false
    AND tx.ticket_id IS NULL
ORDER BY t.create_date DESC;

-- TERMINALES INVÁLIDOS
-- ============================================================================
SELECT DISTINCT
    t.terminal_id,
    COUNT(*) as num_tickets,
    SUM(t.total_price) as monto_total,
    MIN(t.create_date) as primer_ticket,
    MAX(t.create_date) as ultimo_ticket
FROM public.ticket t
WHERE t.terminal_id NOT IN (101, 102)
    AND t.voided = false
GROUP BY t.terminal_id
ORDER BY num_tickets DESC;
