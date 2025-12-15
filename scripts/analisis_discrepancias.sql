-- ANÁLISIS DE DISCREPANCIAS EN VENTAS
-- Período: Últimos 7 días
-- Terminales: 101 y 102

-- 1. Resumen de tickets por terminal
SELECT '=== RESUMEN TICKETS ÚLTIMA SEMANA ===' as analisis;
SELECT
    terminal_id,
    COUNT(*) as total_tickets,
    COUNT(CASE WHEN voided = true THEN 1 END) as anulados,
    COUNT(CASE WHEN paid = true AND voided = false THEN 1 END) as pagados,
    ROUND(SUM(CASE WHEN voided = false THEN total_price ELSE 0 END), 2) as ventas_brutas,
    ROUND(SUM(CASE WHEN voided = false THEN total_discount ELSE 0 END), 2) as descuentos,
    ROUND(SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END), 2) as ventas_netas
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
GROUP BY terminal_id
ORDER BY terminal_id;

-- 2. Análisis diario de ventas
SELECT '=== ANÁLISIS DIARIO DE VENTAS ===' as analisis;
SELECT
    closing_date::date as fecha,
    terminal_id,
    COUNT(*) as tickets_dia,
    ROUND(SUM(CASE WHEN voided = false THEN total_price ELSE 0 END), 2) as ventas_brutas_dia,
    ROUND(SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END), 2) as ventas_netas_dia
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
GROUP BY closing_date::date, terminal_id
ORDER BY fecha, terminal_id;

-- 3. Formas de pago por terminal
SELECT '=== FORMAS DE PAGO POR TERMINAL ===' as analisis;
SELECT
    t.terminal_id,
    tr.payment_type,
    COUNT(*) as transacciones,
    ROUND(SUM(tr.amount), 2) as monto_total
FROM public.transactions tr
JOIN public.ticket t ON tr.ticket_id = t.id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.terminal_id IN (101, 102)
    AND tr.amount > 0
GROUP BY t.terminal_id, tr.payment_type
ORDER BY t.terminal_id, monto_total DESC;

-- 4. Precortes por terminal
SELECT '=== PRECORTES POR TERMINAL ===' as analisis;
SELECT
    sc.terminal_id,
    p.fecha_hora::date as fecha,
    COUNT(*) as precortes_dia,
    ROUND(SUM(p.ventas_reportadas), 2) as ventas_reportadas,
    ROUND(SUM(p.efectivo_reportado), 2) as efectivo_reportado,
    ROUND(SUM(p.tarjetas_reportadas), 2) as tarjetas_reportadas
FROM selemti.precorte p
JOIN selemti.sesion_cajon sc ON p.sesion_cajon_id = sc.id
WHERE p.fecha_hora >= CURRENT_DATE - INTERVAL '7 days'
    AND sc.terminal_id IN (101, 102)
GROUP BY sc.terminal_id, p.fecha_hora::date
ORDER BY sc.terminal_id, fecha;

-- 5. Comparación tickets vs precortes
SELECT '=== COMPARACIÓN TICKETS VS PRECORTES ===' as analisis;

-- Datos de tickets por día/terminal
WITH tickets_diarios AS (
    SELECT
        closing_date::date as fecha,
        terminal_id,
        ROUND(SUM(CASE WHEN voided = false THEN total_price - total_discount ELSE 0 END), 2) as ventas_tickets,
        COUNT(*) as tickets_count
    FROM public.ticket
    WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
        AND terminal_id IN (101, 102)
    GROUP BY closing_date::date, terminal_id
),

-- Datos de precortes por día/terminal
precortes_diarios AS (
    SELECT
        p.fecha_hora::date as fecha,
        sc.terminal_id,
        COALESCE(SUM(p.ventas_reportadas), 0) as ventas_precorte,
        COUNT(*) as precorte_count
    FROM selemti.precorte p
    JOIN selemti.sesion_cajon sc ON p.sesion_cajon_id = sc.id
    WHERE p.fecha_hora >= CURRENT_DATE - INTERVAL '7 days'
        AND sc.terminal_id IN (101, 102)
    GROUP BY p.fecha_hora::date, sc.terminal_id
)

SELECT
    td.fecha,
    td.terminal_id,
    td.tickets_count as tickets,
    td.ventas_tickets,
    pd.ventas_precorte,
    COALESCE(pd.ventas_precorte, 0) as ventas_reportadas,
    ROUND(td.ventas_tickets - COALESCE(pd.ventas_precorte, 0), 2) as diferencia,
    CASE
        WHEN pd.ventas_precorte = 0 THEN 'SIN PRECORTE'
        WHEN ABS(td.ventas_tickets - pd.ventas_precorte) > 100 THEN 'DIFERENCIA SIGNIFICATIVA'
        WHEN ABS(td.ventas_tickets - pd.ventas_precorte) > 50 THEN 'DIFERENCIA MODERADA'
        ELSE 'OK'
    END as status
FROM tickets_diarios td
LEFT JOIN precortes_diarios pd ON td.fecha = pd.fecha AND td.terminal_id = pd.terminal_id
ORDER BY td.fecha, td.terminal_id;

-- 6. Tickets anulados por día/terminal
SELECT '=== TICKETS ANULADOS ===' as analisis;
SELECT
    closing_date::date as fecha,
    terminal_id,
    COUNT(*) as anulados,
    ROUND(SUM(total_price), 2) as monto_anulado,
    STRING_AGG(DISTINCT void_reason, ', ') as razones
FROM public.ticket
WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND terminal_id IN (101, 102)
    AND voided = true
GROUP BY closing_date::date, terminal_id
ORDER BY fecha, terminal_id;

-- 7. Análisis de tickets sin pagos
SELECT '=== TICKETS SIN PAGOS REGISTRADOS ===' as analisis;
SELECT
    t.closing_date::date as fecha,
    t.terminal_id,
    COUNT(*) as tickets_sin_pagos,
    ROUND(SUM(t.total_price - t.total_discount), 2) as monto_sin_pagos
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.terminal_id IN (101, 102)
    AND t.paid = true
    AND tr.ticket_id IS NULL
GROUP BY t.closing_date::date, t.terminal_id
HAVING COUNT(*) > 0
ORDER BY fecha, terminal_id;

-- 8. Resumen de transacciones vs tickets
SELECT '=== RESUMEN TRANSACCIONES VS TICKETS ===' as analisis;
WITH resumen_tickets AS (
    SELECT
        terminal_id,
        COUNT(*) as total_tickets,
        COUNT(CASE WHEN paid = true AND voided = false THEN 1 END) as pagados,
        ROUND(SUM(CASE WHEN paid = true AND voided = false THEN total_price - total_discount ELSE 0 END), 2) as ventas_tickets
    FROM public.ticket
    WHERE closing_date >= CURRENT_DATE - INTERVAL '7 days'
        AND terminal_id IN (101, 102)
    GROUP BY terminal_id
),
resumen_transacciones AS (
    SELECT
        t.terminal_id,
        COUNT(DISTINCT tr.id) as total_transacciones,
        COUNT(DISTINCT t.id) as tickets_con_pagos,
        ROUND(SUM(tr.amount), 2) as total_transacciones_monto
    FROM public.transactions tr
    JOIN public.ticket t ON tr.ticket_id = t.id
    WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
        AND t.terminal_id IN (101, 102)
        AND tr.amount > 0
    GROUP BY t.terminal_id
)
SELECT
    rt.terminal_id,
    rt.total_tickets,
    rt.pagados as tickets_pagados,
    rt.ventas_tickets,
    rtr.total_transacciones,
    rtr.tickets_con_pagos,
    rtr.total_transacciones_monto,
    ROUND(rt.ventas_tickets - rtr.total_transacciones_monto, 2) as diferencia_monto
FROM resumen_tickets rt
LEFT JOIN resumen_transacciones rtr ON rt.terminal_id = rtr.terminal_id
ORDER BY rt.terminal_id;