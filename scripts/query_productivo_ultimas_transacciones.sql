-- QUERY PARA BD PRODUCTIVA - ANÁLISIS DE ÚLTIMAS TRANSACCIONES Y SALIDAS
-- Versión optimizada para ejecución en producción

-- 1. ÚLTIMA TRANSACCIÓN REGISTRADA
SELECT
    'ÚLTIMA TRANSACCIÓN:' as tipo,
    t.id,
    t.transaction_time,
    t.terminal_id,
    t.ticket_id,
    t.payment_type,
    t.amount,
    ti.closing_date,
    ti.total_price,
    ti.voided,
    ti.paid
FROM public.transactions t
LEFT JOIN public.ticket ti ON t.ticket_id = ti.id
ORDER BY t.transaction_time DESC
LIMIT 1;

-- 2. ÚLTIMO TICKET CERRADO
SELECT
    'ÚLTIMO TICKET:' as tipo,
    t.id,
    t.closing_date,
    t.terminal_id,
    t.total_price,
    t.voided,
    t.paid
FROM public.ticket t
WHERE t.closing_date IS NOT NULL
ORDER BY t.closing_date DESC
LIMIT 1;

-- 3. COMPARACIÓN GENERAL (HOY)
SELECT
    'RESUMEN DÍA ACTUAL:' as tipo,
    COUNT(DISTINCT t.id) as_tickets_cerrados,
    COUNT(DISTINCT tr.id) as_transacciones,
    SUM(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE 0 END) as ventas_validas,
    SUM(tr.amount) as total_transacciones,
    COUNT(DISTINCT CASE WHEN t.voided = false AND t.paid = true THEN t.id END) as tickets_validos
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.closing_date >= CURRENT_DATE
    AND t.closing_date IS NOT NULL;

-- 4. ANÁLISIS POR TERMINAL (HOY)
SELECT
    'POR TERMINAL HOY:' as tipo,
    t.terminal_id,
    COUNT(DISTINCT t.id) as tickets,
    COUNT(DISTINCT tr.id) as transacciones,
    SUM(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE 0 END) as ventas,
    SUM(tr.amount) as monto_transacciones
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.closing_date >= CURRENT_DATE
    AND t.closing_date IS NOT NULL
GROUP BY t.terminal_id
ORDER BY ventas DESC;

-- 5. ÚLTIMOS 10 TICKETS VS TRANSACCIONES
SELECT
    'ÚLTIMOS 10 REGISTROS:' as tipo,
    'TICKET' as origen,
    t.id,
    t.closing_date,
    t.terminal_id,
    t.total_price as monto,
    t.voided,
    t.paid,
    NULL as payment_type
FROM public.ticket t
WHERE t.closing_date IS NOT NULL
ORDER BY t.closing_date DESC
LIMIT 10

UNION ALL

SELECT
    'ÚLTIMOS 10 REGISTROS:' as tipo,
    'TRANSACCIÓN' as origen,
    tr.id,
    tr.transaction_time,
    tr.terminal_id,
    tr.amount as monto,
    NULL as voided,
    NULL as paid,
    tr.payment_type
FROM public.transactions tr
ORDER BY tr.transaction_time DESC
LIMIT 10;

-- 6. RESUMEN TOTAL DEL SISTEMA
SELECT
    'TOTAL SISTEMA:' as tipo,
    'Todos los tiempos' as periodo,
    COUNT(*) as tickets_totales,
    COUNT(CASE WHEN voided = false AND paid = true THEN 1 END) as tickets_validos,
    SUM(total_price) as monto_total_tickets
FROM public.ticket
WHERE closing_date IS NOT NULL

UNION ALL

SELECT
    'TOTAL SISTEMA:' as tipo,
    'Todos los tiempos' as periodo,
    COUNT(*) as transacciones_totales,
    NULL as tickets_validos,
    SUM(amount) as monto_total_transacciones
FROM public.transactions;