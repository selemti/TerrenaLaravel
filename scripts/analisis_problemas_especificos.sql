-- ANÁLISIS DETALLADO DE PROBLEMAS ESPECÍFICOS
-- Enfoque en errores de cálculo de cortes con anulaciones, salidas y descuentos

-- 1. Análisis CRÍTICO: Descuentos 100%
-- ESTE ES UN PROBLEMA GRAVE: 78 tickets con descuento 100% pero monto 0
SELECT '=== CRÍTICO: DESCUENTOS 100% CON PROBLEMAS ===' as analisis;
SELECT
    terminal_id,
    closing_date::date as fecha,
    COUNT(*) as tickets_descuento_100,
    SUM(total_price) as monto_total_tickets,
    SUM(total_discount) as monto_descuento,
    COUNT(CASE WHEN total_discount = total_price AND total_price > 0 THEN 1 END) as descuento_real_100,
    COUNT(CASE WHEN total_discount >= total_price * 0.99 AND total_price > 0 THEN 1 END) as descuento_casi_100,
    STRING_AGG(CASE WHEN total_discount = total_price AND total_price > 0
                   THEN id::text ELSE NULL END, ', ') as ejemplos_id
FROM public.ticket
WHERE total_discount > 0
    AND closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
    AND terminal_id IN (101, 102, 301, 2486) -- Terminales principales
GROUP BY terminal_id, closing_date::date
HAVING COUNT(CASE WHEN total_discount >= total_price * 0.99 THEN 1 END) > 0
ORDER BY fecha DESC, terminal_id;

-- 2. Análisis de errores en anulaciones
SELECT '=== ERRORES EN ANULACIONES ===' as analisis;
SELECT
    t.terminal_id,
    t.closing_date::date as fecha,
    COUNT(*) as tickets_anulados,
    SUM(t.total_price) as monto_anulado,
    COUNT(tr.id) as transacciones_anulacion,
    SUM(tr.amount) as monto_transacciones,
    CASE
        WHEN COUNT(tr.id) = 0 THEN 'SIN TRANSACCIONES'
        WHEN SUM(tr.amount) = 0 THEN 'TRANSACCIONES EN CERO'
        ELSE 'CON TRANSACCIONES'
    END as status_transacciones
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
    AND (tr.payment_type = 'VOID_TRANS' OR tr.payment_type = 'REFUND')
WHERE t.voided = true
    AND t.closing_date >= '2025-11-01'
    AND t.closing_date <= CURRENT_DATE
    AND t.terminal_id IN (101, 102, 301, 2486)
GROUP BY t.terminal_id, t.closing_date::date
HAVING COUNT(*) > 2  -- Días con más de 2 anulaciones
ORDER BY fecha DESC, t.terminal_id;

-- 3. Análisis de inconsistencia: Tickets pagados vs transacciones
SELECT '=== INCONSISTENCIA: TICKETS PAGADOS SIN TRANSACCIONES ===' as analisis;
SELECT
    terminal_id,
    COUNT(*) as tickets_pagados_sin_tx,
    SUM(total_price - total_discount) as monto_afectado,
    COUNT(CASE WHEN total_price > 1000 THEN 1 END) as tickets_altos,
    MAX(total_price) as monto_maximo,
    STRING_AGG(id::text, ', ') as ejemplos_ids
FROM public.ticket t
WHERE t.paid = true
    AND t.voided = false
    AND t.closing_date >= '2025-11-01'
    AND t.closing_date <= CURRENT_DATE
    AND NOT EXISTS (
        SELECT 1 FROM public.transactions tr
        WHERE tr.ticket_id = t.id AND tr.amount != 0
    )
    AND t.terminal_id IN (101, 102, 301, 2486)
GROUP BY terminal_id
ORDER BY monto_afectado DESC;

-- 4. Análisis de cálculo de totales en precortes (ERROR SISTÉMICO)
SELECT '=== ERROR EN CÁLCULO DE PRECORTES ===' as analisis;

-- Comparación por día específico
WITH tickets_dia AS (
    SELECT
        closing_date::date as fecha,
        terminal_id,
        SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END) as ventas_netas,
        SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END) as efectivo_tickets,
        SUM(CASE WHEN tr.payment_type IN ('CREDIT_CARD', 'DEBIT_CARD') THEN tr.amount ELSE 0 END) as tarjetas_tickets,
        COUNT(*) as total_tickets,
        COUNT(CASE WHEN voided = true THEN 1 END) as anulados
    FROM public.ticket t
    LEFT JOIN public.transactions tr ON t.id = tr.ticket_id AND tr.amount > 0
    WHERE closing_date >= '2025-11-01'
        AND closing_date <= CURRENT_DATE
        AND terminal_id IN (101, 102, 301, 2486)
    GROUP BY closing_date::date, terminal_id
),

precortes_dia AS (
    SELECT
        p.creado_en::date as fecha,
        sc.terminal_id,
        p.declarado_efectivo,
        p.declarado_otros,
        (p.declarado_efectivo + p.declarado_otros) as declarado_total
    FROM selemti.precorte p
    JOIN selemti.sesion_cajon sc ON p.sesion_id = sc.id
    WHERE p.creado_en >= '2025-11-01'
        AND p.creado_en <= CURRENT_DATE
        AND sc.terminal_id IN (101, 102, 301, 2486)
)

SELECT
    COALESCE(td.fecha, pd.fecha) as fecha,
    td.terminal_id,
    td.ventas_netas,
    td.efectivo_tickets,
    td.tarjetas_tickets,
    pd.declarado_efectivo,
    pd.declarado_otros,
    pd.declarado_total,
    (pd.declarado_efectivo - td.efectivo_tickets) as dif_efectivo,
    (pd.declarado_otros - td.tarjetas_tickets) as dif_tarjetas,
    (pd.declarado_total - td.ventas_netas) as dif_total,
    CASE
        WHEN pd.declarado_total IS NULL THEN 'SIN PRECORTE'
        WHEN ABS(pd.declarado_total - td.ventas_netas) > td.ventas_netas * 0.20 THEN 'ERROR >20%'
        WHEN ABS(pd.declarado_total - td.ventas_netas) > 1000 THEN 'ERROR SIGNIFICATIVO'
        ELSE 'OK'
    END as nivel_error
FROM tickets_dia td
LEFT JOIN precortes_dia pd ON td.fecha = pd.fecha AND td.terminal_id = pd.terminal_id
WHERE td.terminal_id IN (101, 102, 301, 2486)
    AND (ABS(pd.declarado_total - td.ventas_netas) > 500 OR pd.declarado_total IS NULL)
ORDER BY td.fecha DESC, td.terminal_id;

-- 5. Identificación de errores de cálculo específicos
SELECT '=== ERRORES ESPECÍFICOS DE CÁLCULO ===' as analisis;

-- Caso 1: Diferencias masivas (>50%)
SELECT
    'DIFERENCIA MASIVA (>50%)' as tipo_error,
    td.fecha,
    td.terminal_id,
    td.ventas_netas,
    pd.declarado_total,
    ROUND((pd.declarado_total - td.ventas_netas) / td.ventas_netas * 100, 1) as porcentaje_error
FROM tickets_dia td
JOIN precortes_dia pd ON td.fecha = pd.fecha AND td.terminal_id = pd.terminal_id
WHERE ABS(pd.declarado_total - td.ventas_netas) > td.ventas_netas * 0.5
ORDER BY porcentaje_error DESC

UNION ALL

-- Caso 2: Terminales sin precortes pero con ventas
SELECT
    'TERMINAL SIN PRECORTES' as tipo_error,
    td.fecha,
    td.terminal_id,
    td.ventas_netas,
    0 as declarado_total,
    100 as porcentaje_error
FROM tickets_dia td
LEFT JOIN precortes_dia pd ON td.fecha = pd.fecha AND td.terminal_id = pd.terminal_id
WHERE pd.terminal_id IS NULL AND td.ventas_netas > 1000

UNION ALL

-- Caso 3: Días con muchas anulaciones
SELECT
    'ALTAS ANULACIONES (>5%)' as tipo_error,
    td.fecha,
    td.terminal_id,
    td.ventas_netas,
    td.anulados as problema,
    ROUND(td.anulados * 100.0 / td.total_tickets, 1) as porcentaje_error
FROM tickets_dia td
WHERE td.anulados > 0 AND td.anulados * 100.0 / td.total_tickets > 5

ORDER BY fecha DESC, tipo_error;