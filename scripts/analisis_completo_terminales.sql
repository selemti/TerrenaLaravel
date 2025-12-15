-- ANÁLISIS COMPLETO DE TERMINALES
-- Período: Noviembre + Diciembre 2025
-- Enfoque: Anulaciones, Salidas de Dinero, Descuentos 100%

-- 1. Identificar todas las terminales activas
SELECT '=== TERMINALES ACTIVAS ===' as analisis;
SELECT DISTINCT
    terminal_id,
    MIN(closing_date) as primer_ticket,
    MAX(closing_date) as ultimo_ticket,
    COUNT(*) as total_tickets
FROM public.ticket
WHERE closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
GROUP BY terminal_id
ORDER BY terminal_id;

-- 2. Resumen mensual por terminal
SELECT '=== RESUMEN MENSUAL POR TERMINAL ===' as analisis;
SELECT
    terminal_id,
    DATE_TRUNC('month', closing_date)::date as mes,
    COUNT(*) as total_tickets,
    COUNT(CASE WHEN voided = true THEN 1 END) as anulados,
    COUNT(CASE WHEN voided = true THEN 1 END) * 100.0 / COUNT(*) as porcentaje_anulados,
    SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_brutas,
    SUM(CASE WHEN voided = false THEN total_discount ELSE 0 END) as descuentos,
    SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END) as ventas_netas
FROM public.ticket
WHERE closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
    AND terminal_id IS NOT NULL
GROUP BY terminal_id, DATE_TRUNC('month', closing_date)
ORDER BY terminal_id, mes;

-- 3. Análisis de tickets anulados por terminal y motivo
SELECT '=== ANÁLISIS DETALLADO DE ANULACIONES ===' as analisis;
SELECT
    terminal_id,
    closing_date::date as fecha,
    COUNT(*) as tickets_anulados,
    SUM(total_price) as monto_anulado,
    STRING_AGG(DISTINCT COALESCE(void_reason, 'SIN MOTIVO'), ', ') as motivos
FROM public.ticket
WHERE closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
    AND voided = true
    AND terminal_id IS NOT NULL
GROUP BY terminal_id, closing_date::date
HAVING COUNT(*) > 2  -- Mostrar días con más de 2 anulaciones
ORDER BY terminal_id, fecha DESC;

-- 4. Análisis de descuentos (especialmente 100%)
SELECT '=== ANÁLISIS DE DESCUENTOS ===' as analisis;

-- Tickets con descuentos
SELECT
    terminal_id,
    DATE_TRUNC('month', closing_date)::date as mes,
    COUNT(*) as tickets_con_descuento,
    SUM(total_discount) as total_descuentos,
    COUNT(CASE WHEN total_discount >= total_price * 0.99 THEN 1 END) as descuentos_100,
    SUM(CASE WHEN total_discount >= total_price * 0.99 THEN total_price ELSE 0 END) as monto_descuentos_100,
    AVG(CASE WHEN total_discount > 0 THEN total_discount ELSE NULL END) as descuento_promedio
FROM public.ticket
WHERE closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
    AND total_discount > 0
    AND terminal_id IS NOT NULL
GROUP BY terminal_id, DATE_TRUNC('month', closing_date)
ORDER BY terminal_id, mes;

-- 5. Salidas de dinero (transactions negativas o VOID_TRANS/REFUND)
SELECT '=== ANÁLISIS DE SALIDAS DE DINERO ===' as analisis;
SELECT
    t.terminal_id,
    DATE_TRUNC('month', t.closing_date)::date as mes,
    COUNT(*) as total_transacciones,
    COUNT(CASE WHEN tr.payment_type IN ('VOID_TRANS', 'REFUND') THEN 1 END) as salidas_dinero,
    SUM(CASE WHEN tr.payment_type IN ('VOID_TRANS', 'REFUND') THEN tr.amount ELSE 0 END) as monto_salidas,
    COUNT(CASE WHEN tr.amount < 0 THEN 1 END) as montos_negativos,
    SUM(CASE WHEN tr.amount < 0 THEN tr.amount ELSE 0 END) as total_negativo
FROM public.transactions tr
JOIN public.ticket t ON tr.ticket_id = t.id
WHERE t.closing_date >= '2025-11-01'
    AND t.closing_date <= CURRENT_DATE
    AND t.terminal_id IS NOT NULL
GROUP BY t.terminal_id, DATE_TRUNC('month', t.closing_date)
ORDER BY t.terminal_id, mes;

-- 6. Comparación mensual: Tickets vs Precortes
SELECT '=== COMPARACIÓN MENSUAL TICKETS VS PRECORTES ===' as analisis;

-- Datos de tickets mensuales por terminal
WITH tickets_mensuales AS (
    SELECT
        terminal_id,
        DATE_TRUNC('month', closing_date)::date as mes,
        SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END) as ventas_tickets,
        COUNT(*) as total_tickets,
        COUNT(CASE WHEN voided = true THEN 1 END) as anulados
    FROM public.ticket
    WHERE closing_date >= '2025-11-01'
        AND closing_date <= CURRENT_DATE
        AND terminal_id IS NOT NULL
    GROUP BY terminal_id, DATE_TRUNC('month', closing_date)
),

-- Datos de precortes mensuales por terminal
precortes_mensuales AS (
    SELECT
        sc.terminal_id,
        DATE_TRUNC('month', p.creado_en)::date as mes,
        COALESCE(SUM(p.declarado_efectivo + p.declarado_otros), 0) as declarado_total,
        COUNT(*) as total_precortes
    FROM selemti.precorte p
    JOIN selemti.sesion_cajon sc ON p.sesion_id = sc.id
    WHERE p.creado_en >= '2025-11-01'
        AND p.creado_en <= CURRENT_DATE
        AND sc.terminal_id IS NOT NULL
    GROUP BY sc.terminal_id, DATE_TRUNC('month', p.creado_en)
)

SELECT
    COALESCE(tm.terminal_id, pm.terminal_id) as terminal_id,
    COALESCE(tm.mes, pm.mes) as mes,
    tm.total_tickets,
    tm.anulados,
    tm.ventas_tickets,
    pm.total_precortes,
    pm.declarado_total,
    COALESCE(pm.declarado_total, 0) - COALESCE(tm.ventas_tickets, 0) as diferencia,
    CASE
        WHEN pm.declarado_total IS NULL THEN 'SIN PRECORTES'
        WHEN tm.ventas_tickets IS NULL THEN 'SIN TICKETS'
        WHEN ABS(pm.declarado_total - tm.ventas_tickets) > 5000 THEN 'DIFERENCIA SIGNIFICATIVA'
        WHEN ABS(pm.declarado_total - tm.ventas_tickets) > 1000 THEN 'DIFERENCIA MODERADA'
        ELSE 'OK'
    END as status
FROM tickets_mensuales tm
FULL OUTER JOIN precortes_mensuales pm
    ON tm.terminal_id = pm.terminal_id AND tm.mes = pm.mes
ORDER BY terminal_id, mes;

-- 7. Días con problemas específicos
SELECT '=== DÍAS CON PROBLEMAS ESPECÍFICOS ===' as analisis;

-- Anulaciones por día
SELECT
    'ANULACIONES' as tipo_problema,
    closing_date::date as fecha,
    terminal_id,
    COUNT(*) as cantidad,
    SUM(total_price) as monto_afectado
FROM public.ticket
WHERE voided = true
    AND closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
GROUP BY closing_date::date, terminal_id
HAVING COUNT(*) > 5 OR SUM(total_price) > 2000

UNION ALL

-- Descuentos 100% por día
SELECT
    'DESCUENTOS 100%' as tipo_problema,
    closing_date::date as fecha,
    terminal_id,
    COUNT(*) as cantidad,
    SUM(total_price) as monto_afectado
FROM public.ticket
WHERE total_discount >= total_price * 0.99
    AND total_price > 0
    AND closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
GROUP BY closing_date::date, terminal_id
HAVING COUNT(*) > 3 OR SUM(total_price) > 1000

UNION ALL

-- Salidas de dinero por día
SELECT
    'SALIDAS DE DINERO' as tipo_problema,
    t.closing_date::date as fecha,
    t.terminal_id,
    COUNT(*) as cantidad,
    SUM(tr.amount) as monto_afectado
FROM public.transactions tr
JOIN public.ticket t ON tr.ticket_id = t.id
WHERE tr.payment_type IN ('VOID_TRANS', 'REFUND') OR tr.amount < 0
    AND t.closing_date >= '2025-11-01'
    AND t.closing_date <= CURRENT_DATE
GROUP BY t.closing_date::date, t.terminal_id
HAVING COUNT(*) > 3 OR ABS(SUM(tr.amount)) > 500

ORDER BY tipo_problema, fecha DESC, terminal_id;

-- 8. Análisis de patrones por día de semana
SELECT '=== PATRONES POR DÍA DE SEMANA ===' as analisis;
SELECT
    terminal_id,
    EXTRACT(DOW FROM closing_date) as dia_semana_num,
    TO_CHAR(closing_date, 'Day') as dia_semana,
    COUNT(*) as tickets_promedio_dia,
    AVG(CASE WHEN voided = false THEN total_price - total_discount ELSE NULL END) as venta_promedio_dia,
    COUNT(CASE WHEN voided = true THEN 1 END) * 100.0 / COUNT(*) as porcentaje_anulados,
    COUNT(CASE WHEN total_discount >= total_price * 0.99 THEN 1 END) as descuentos_100
FROM public.ticket
WHERE closing_date >= '2025-11-01'
    AND closing_date <= CURRENT_DATE
    AND terminal_id IS NOT NULL
GROUP BY terminal_id, EXTRACT(DOW FROM closing_date), TO_CHAR(closing_date, 'Day')
ORDER BY terminal_id, dia_semana_num;