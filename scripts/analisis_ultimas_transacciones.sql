-- ANÁLISIS DE ÚLTIMAS TRANSACCIONES Y COMPARACIÓN DE SALIDAS
-- Este script muestra las últimas transacciones y las compara con salidas esperadas

-- 1. Verificar última transacción registrada
SELECT 'ÚLTIMA TRANSACCIÓN REGISTRADA:' as info;
SELECT
    t.id,
    t.transaction_time::timestamp(0) as fecha_hora,
    t.terminal_id,
    t.ticket_id,
    t.payment_type,
    t.amount,
    ti.closing_date::timestamp(0) as fecha_ticket,
    ti.total_price,
    ti.voided,
    ti.paid
FROM public.transactions t
LEFT JOIN public.ticket ti ON t.ticket_id = ti.id
ORDER BY t.transaction_time DESC
LIMIT 10;

-- 2. Verificar último ticket (cerrado)
SELECT '';
SELECT 'ÚLTIMO TICKET CERRADO:' as info;
SELECT
    t.id,
    t.closing_date::timestamp(0) as fecha_cierre,
    t.terminal_id,
    t.folio_date,
    t.total_price,
    t.sub_total,
    t.total_discount,
    t.voided,
    t.paid,
    CASE
        WHEN t.voided = false AND t.paid = true THEN 'VÁLIDO'
        ELSE 'INVÁLIDO/ANULADO'
    END as status
FROM public.ticket t
WHERE t.closing_date IS NOT NULL
ORDER BY t.closing_date DESC
LIMIT 10;

-- 3. Comparación de tickets vs transacciones (últimos 7 días)
SELECT '';
SELECT 'COMPARACIÓN TICKETS VS TRANSACCIONES (ÚLTIMOS 7 DÍAS):' as info;
SELECT
    COUNT(DISTINCT t.id) as tickets_cerrados,
    COUNT(DISTINCT tr.id) as transacciones,
    COUNT(DISTINCT CASE WHEN t.voided = false AND t.paid = true THEN t.id END) as tickets_validos,
    SUM(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE 0 END) as monto_tickets_validos,
    SUM(tr.amount) as monto_total_transacciones,
    ROUND(AVG(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE NULL END), 2) as ticket_promedio,
    ROUND(AVG(tr.amount), 2) as transaccion_promedio
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.closing_date IS NOT NULL;

-- 4. Análisis por terminal (últimos 7 días)
SELECT '';
SELECT 'ANÁLISIS POR TERMINAL (ÚLTIMOS 7 DÍAS):' as info;
SELECT
    t.terminal_id,
    ter.name as nombre_terminal,
    COUNT(DISTINCT t.id) as tickets_cerrados,
    COUNT(DISTINCT tr.id) as transacciones,
    SUM(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE 0 END) as ventas_validas,
    SUM(tr.amount) as total_transacciones,
    COUNT(DISTINCT CASE WHEN t.voided = false AND t.paid = true THEN t.id END) as tickets_validos,
    ROUND(AVG(CASE WHEN t.voided = false AND t.paid = true THEN t.total_price ELSE NULL END), 2) as ticket_promedio
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
LEFT JOIN public.terminal ter ON t.terminal_id = ter.id
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.closing_date IS NOT NULL
GROUP BY t.terminal_id, ter.name
ORDER BY ventas_validas DESC;

-- 5. Últimos drawer_pull_report por terminal
SELECT '';
SELECT 'ÚLTIMOS CORTES DE CAJA POR TERMINAL:' as info;
SELECT
    dpr.terminal_id,
    dpr.report_time::timestamp(0) as fecha_corte,
    dpr.ticket_count,
    dpr.net_sales,
    dpr.totaldiscountamount,
    dpr.cash_receipt_amount,
    dpr.credit_card_receipt_amount,
    dpr.debit_card_receipt_amount,
    (dpr.cash_receipt_amount + dpr.credit_card_receipt_amount + dpr.debit_card_receipt_amount) as total_recibido,
    ROUND((dpr.totaldiscountamount / NULLIF(dpr.net_sales, 0) * 100), 2) as porcentaje_descuentos
FROM public.drawer_pull_report dpr
WHERE dpr.report_time >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY dpr.terminal_id, dpr.report_time DESC;

-- 6. Diferencias detectadas (tickets vs transacciones)
SELECT '';
SELECT 'DIFERENCIAS DETECTADAS (ÚLTIMOS 7 DÍAS):' as info;
SELECT
    'Tickets sin transacciones:' as tipo,
    COUNT(*) as cantidad,
    ROUND(SUM(t.total_price), 2) as monto_total
FROM public.ticket t
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.voided = false
    AND t.paid = true
    AND NOT EXISTS (SELECT 1 FROM public.transactions tr WHERE tr.ticket_id = t.id)

UNION ALL

SELECT
    'Transacciones sin ticket válido:' as tipo,
    COUNT(*) as cantidad,
    ROUND(SUM(tr.amount), 2) as monto_total
FROM public.transactions tr
LEFT JOIN public.ticket t ON tr.ticket_id = t.id
WHERE tr.transaction_time >= CURRENT_DATE - INTERVAL '7 days'
    AND (t.id IS NULL OR t.voided = true OR t.paid = false)

UNION ALL

SELECT
    'Tickets con múltiples transacciones:' as tipo,
    COUNT(*) as cantidad,
    ROUND(SUM(t.total_price), 2) as monto_total
FROM public.ticket t
WHERE t.closing_date >= CURRENT_DATE - INTERVAL '7 days'
    AND t.voided = false
    AND t.paid = true
    AND EXISTS (
        SELECT 1 FROM public.transactions tr
        WHERE tr.ticket_id = t.id
        GROUP BY tr.ticket_id
        HAVING COUNT(*) > 1
    );

-- 7. Validación de consistencia (fechas extremas)
SELECT '';
SELECT 'VALIDACIÓN DE CONSISTENCIA - FECHAS EXTREMAS:' as info;
SELECT
    'Primera transacción:' as tipo,
    MIN(transaction_time)::timestamp(0) as fecha,
    COUNT(*) as total
FROM public.transactions

UNION ALL

SELECT
    'Última transacción:' as tipo,
    MAX(transaction_time)::timestamp(0) as fecha,
    COUNT(*) as total
FROM public.transactions

UNION ALL

SELECT
    'Primer ticket cerrado:' as tipo,
    MIN(closing_date)::timestamp(0) as fecha,
    COUNT(*) as total
FROM public.ticket
WHERE closing_date IS NOT NULL

UNION ALL

SELECT
    'Último ticket cerrado:' as tipo,
    MAX(closing_date)::timestamp(0) as fecha,
    COUNT(*) as total
FROM public.ticket
WHERE closing_date IS NOT NULL;

-- 8. Resumen ejecutivo
SELECT '';
SELECT 'RESUMEN EJECUTIVO:' as info;
SELECT
    'Tickets totales en sistema:' as descripcion,
    COUNT(*) as total
FROM public.ticket

UNION ALL

SELECT
    'Tickets válidos (cerrados y pagados):' as descripcion,
    COUNT(*) as total
FROM public.ticket
WHERE voided = false AND paid = true AND closing_date IS NOT NULL

UNION ALL

SELECT
    'Transacciones totales:' as descripcion,
    COUNT(*) as total
FROM public.transactions

UNION ALL

SELECT
    'Diferencia (tickets - transacciones):' as descripcion,
    (SELECT COUNT(*) FROM public.ticket WHERE voided = false AND paid = true AND closing_date IS NOT NULL) -
    (SELECT COUNT(*) FROM public.transactions) as total;