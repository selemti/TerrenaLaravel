-- ANÁLISIS SIMPLE DE DISCREPANCIAS EN VENTAS
-- Compatible con PostgreSQL 9.5

-- 1. Resumen básico de tickets última semana
SELECT '=== RESUMEN TICKETS ÚLTIMA SEMANA (7 días) ===' as analisis;
SELECT
    terminal_id,
    COUNT(*) as total_tickets,
    COUNT(CASE WHEN voided = true THEN 1 END) as anulados,
    COUNT(CASE WHEN paid = true AND voided = false THEN 1 END) as pagados,
    SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_brutas
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
GROUP BY terminal_id
ORDER BY terminal_id;

-- 2. Ventas diarias por terminal
SELECT '=== VENTAS DIARIAS POR TERMINAL ===' as analisis;
SELECT
    closing_date::date as fecha,
    terminal_id,
    COUNT(*) as tickets_dia,
    SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_dia
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
GROUP BY closing_date::date, terminal_id
ORDER BY fecha, terminal_id;

-- 3. Formas de pago más comunes
SELECT '=== FORMAS DE PAGO ===' as analisis;
SELECT
    t.terminal_id,
    tr.payment_type,
    COUNT(*) as cantidad,
    SUM(tr.amount) as monto_total
FROM public.transactions tr
JOIN public.ticket t ON tr.ticket_id = t.id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.terminal_id IN (101, 102)
    AND tr.amount > 0
GROUP BY t.terminal_id, tr.payment_type
HAVING COUNT(*) > 0
ORDER BY t.terminal_id, monto_total DESC;

-- 4. Sesiones de cajón y precortes
SELECT '=== SESIONES Y PRECORTES ===' as analisis;
SELECT
    sc.terminal_id,
    sc.apertura_ts::date as fecha,
    COUNT(p.id) as precortes_count,
    COUNT(pc.id) as postcortes_count
FROM selemti.sesion_cajon sc
LEFT JOIN selemti.precorte p ON sc.id = p.sesion_id
LEFT JOIN selemti.postcorte pc ON sc.id = pc.sesion_id
WHERE sc.apertura_ts >= CURRENT_DATE - INTERVAL '7 days'
    AND sc.terminal_id IN (101, 102)
GROUP BY sc.terminal_id, sc.apertura_ts::date
ORDER BY sc.terminal_id, fecha;

-- 5. Tickets con problemas
SELECT '=== TICKETS PROBABLES PROBLEMAS ===' as analisis;

-- Tickets pagados pero sin transacciones
SELECT
    'Tickets pagados sin transacciones' as tipo_problema,
    t.terminal_id,
    t.closing_date::date as fecha,
    COUNT(*) as count,
    SUM(t.total_price) as monto_afectado
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.terminal_id IN (101, 102)
    AND t.paid = true
    AND tr.ticket_id IS NULL
GROUP BY t.terminal_id, t.closing_date::date
HAVING COUNT(*) > 0
UNION ALL

-- Tickets con monto alto sospechoso
SELECT
    'Tickets con monto alto (>5000)' as tipo_problema,
    terminal_id,
    closing_date::date as fecha,
    COUNT(*) as count,
    SUM(total_price) as monto_afectado
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
    AND total_price > 5000
    AND voided = false
GROUP BY terminal_id, closing_date::date
HAVING COUNT(*) > 0
ORDER BY fecha, terminal_id;

-- 6. Diferencias día por día (comparación simple)
SELECT '=== ANÁLISIS POR DÍA ===' as analisis;
SELECT
    fecha,
    terminal_id,
    tickets_dia,
    ventas_dia,
    CASE
        WHEN tickets_dia < 20 THEN 'BAJA ACTIVIDAD'
        WHEN tickets_dia > 200 THEN 'ALTA ACTIVIDAD'
        ELSE 'NORMAL'
    END as nivel_actividad,
    CASE
        WHEN ventas_dia < 1000 THEN 'BAJAS VENTAS'
        WHEN ventas_dia > 10000 THEN 'ALTAS VENTAS'
        ELSE 'VENTAS NORMALES'
    END as nivel_ventas
FROM (
    SELECT
        closing_date::date as fecha,
        terminal_id,
        COUNT(*) as tickets_dia,
        SUM(CASE WHEN voided = false THEN total_price ELSE 0 END) as ventas_dia
    FROM public.ticket
    WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
        AND terminal_id IN (101, 102)
    GROUP BY closing_date::date, terminal_id
) as datos
ORDER BY fecha, terminal_id;

-- 7. Comparación terminales 101 vs 102
SELECT '=== COMPARACIÓN TERMINAL 101 VS 102 ===' as analisis;
SELECT
    terminal_id,
    COUNT(*) as total_tickets_semana,
    SUM(CASE WHEN voided = true THEN 1 ELSE 0 END) as anulados,
    SUM(CASE WHEN paid = true AND voided = false THEN total_price ELSE 0 END) as ventas_semana,
    ROUND(AVG(CASE WHEN voided = false THEN total_price ELSE NULL END), 2) as ticket_promedio,
    MAX(total_price) as ticket_maximo
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
GROUP BY terminal_id
ORDER BY terminal_id;