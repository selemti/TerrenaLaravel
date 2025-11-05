-- ═══════════════════════════════════════════════════════════════════════════════
-- ANÁLISIS PROFUNDO DE DISCREPANCIAS EN VENTAS - OCTUBRE 2025
-- ═══════════════════════════════════════════════════════════════════════════════
-- Basado en hallazgos del 1 de octubre
-- Objetivo: Identificar patrones en todo el mes
-- ═══════════════════════════════════════════════════════════════════════════════

SET search_path TO public, selemti;

-- ───────────────────────────────────────────────────────────────────────────────
-- 1. RESUMEN DIARIO DE DRAWER PULLS VS REALIDAD
-- ───────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS temp_drawer_analysis;
CREATE TEMP TABLE temp_drawer_analysis AS
SELECT 
    dp.drawer_pull_date::date AS fecha,
    dp.drawer_pull_ticket_count AS tickets_reportados,
    COUNT(DISTINCT t.id) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS tickets_pagados_reales,
    COUNT(DISTINCT t.id) AS tickets_totales,
    
    dp.drawer_pull_net_sales AS ventas_netas_reportadas,
    COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)) 
        FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0) AS ventas_netas_reales,
    
    dp.drawer_pull_cash_receipt AS efectivo_reportado,
    COALESCE(SUM(tx.amount) 
        FILTER (WHERE tx.payment_type = 'CASH' 
                AND tx.voided = FALSE 
                AND tx.transaction_type = 'CREDIT'
                AND t.paid = TRUE 
                AND t.voided = FALSE), 0) AS efectivo_real,
    
    -- Diferencias
    dp.drawer_pull_ticket_count - COUNT(DISTINCT t.id) FILTER (WHERE t.paid = TRUE AND t.voided = FALSE) AS diff_tickets,
    dp.drawer_pull_net_sales - COALESCE(SUM(t.total_price - COALESCE(t.total_discount, 0)) 
        FILTER (WHERE t.paid = TRUE AND t.voided = FALSE), 0) AS diff_ventas_netas,
    dp.drawer_pull_cash_receipt - COALESCE(SUM(tx.amount) 
        FILTER (WHERE tx.payment_type = 'CASH' 
                AND tx.voided = FALSE 
                AND tx.transaction_type = 'CREDIT'
                AND t.paid = TRUE 
                AND t.voided = FALSE), 0) AS diff_efectivo,
    
    dp.terminal_id
FROM public.drawer_pull_report dp
LEFT JOIN public.ticket t ON t.terminal_id = dp.terminal_id
    AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = dp.drawer_pull_date::date
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE dp.drawer_pull_date >= '2025-10-01' 
  AND dp.drawer_pull_date < '2025-11-01'
GROUP BY dp.id, dp.drawer_pull_date, dp.drawer_pull_ticket_count, 
         dp.drawer_pull_net_sales, dp.drawer_pull_cash_receipt, dp.terminal_id
ORDER BY dp.drawer_pull_date;

SELECT 
    fecha,
    terminal_id,
    tickets_reportados,
    tickets_pagados_reales,
    diff_tickets,
    ROUND(ventas_netas_reportadas, 2) AS ventas_reportadas,
    ROUND(ventas_netas_reales, 2) AS ventas_reales,
    ROUND(diff_ventas_netas, 2) AS diff_ventas,
    ROUND(efectivo_reportado, 2) AS efectivo_reportado,
    ROUND(efectivo_real, 2) AS efectivo_real,
    ROUND(diff_efectivo, 2) AS diff_efectivo
FROM temp_drawer_analysis
WHERE ABS(diff_tickets) > 0 OR ABS(diff_ventas_netas) > 1 OR ABS(diff_efectivo) > 1
ORDER BY ABS(diff_ventas_netas) DESC;

-- ───────────────────────────────────────────────────────────────────────────────
-- 2. TICKETS CON DESCUENTOS DEL 100% (PATRÓN CRÍTICO)
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
    t.id AS ticket_id,
    t.terminal_id,
    t.total_price AS total_antes_desc,
    COALESCE(t.total_discount, 0) AS descuento,
    t.total_price - COALESCE(t.total_discount, 0) AS total_neto,
    ROUND((COALESCE(t.total_discount, 0) / NULLIF(t.total_price, 0) * 100), 2) AS porcentaje_desc,
    t.paid AS pagado,
    t.voided AS anulado,
    t.create_date,
    t.closing_date,
    (SELECT STRING_AGG(ti.item_name || ' ($' || ti.total_price || ')', ', ')
     FROM public.ticket_item ti
     WHERE ti.ticket_id = t.id) AS items
FROM public.ticket t
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
  AND t.total_price > 0
  AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99  -- Descuento >= 99%
ORDER BY fecha, t.id;

-- ───────────────────────────────────────────────────────────────────────────────
-- 3. TICKETS NO PAGADOS PERO CERRADOS
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
    t.id AS ticket_id,
    t.terminal_id,
    t.total_price,
    COALESCE(t.total_discount, 0) AS descuento,
    t.total_price - COALESCE(t.total_discount, 0) AS neto,
    t.paid,
    t.voided,
    t.closing_date IS NOT NULL AS cerrado,
    (SELECT COUNT(*) FROM public.transactions tx WHERE tx.ticket_id = t.id) AS num_transacciones,
    (SELECT COALESCE(SUM(tx.amount), 0) 
     FROM public.transactions tx 
     WHERE tx.ticket_id = t.id 
       AND tx.voided = FALSE 
       AND tx.transaction_type = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')) AS total_pagado
FROM public.ticket t
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
  AND t.paid = FALSE
  AND t.voided = FALSE
  AND t.total_price > 0
ORDER BY fecha, t.total_price DESC;

-- ───────────────────────────────────────────────────────────────────────────────
-- 4. TICKETS ANULADOS CON TRANSACCIONES (PATRÓN ID 15319)
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
    t.id AS ticket_id,
    t.total_price,
    t.paid,
    t.voided,
    COUNT(tx.id) AS num_transacciones,
    COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'CASH'), 0) AS cash,
    COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'REFUND'), 0) AS refund,
    COALESCE(SUM(tx.amount) FILTER (WHERE tx.payment_type = 'VOID_TRANS'), 0) AS void_trans,
    COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE AND tx.transaction_type = 'CREDIT'), 0) AS total_creditos,
    STRING_AGG(DISTINCT tx.payment_type || '($' || tx.amount || ')', ', ') AS detalle_transacciones
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
  AND t.voided = TRUE
HAVING COUNT(tx.id) > 0
GROUP BY t.id, t.folio_date, t.closing_date, t.create_date, t.total_price, t.paid, t.voided
ORDER BY fecha, COUNT(tx.id) DESC;

-- ───────────────────────────────────────────────────────────────────────────────
-- 5. TRANSACCIONES CON MONTO $0 (PATRÓN ID 15527)
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
    t.id AS ticket_id,
    t.total_price,
    t.paid,
    tx.id AS transaction_id,
    tx.payment_type,
    tx.transaction_type,
    tx.amount,
    tx.voided,
    tx.transaction_time
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
  AND tx.amount = 0
  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')
ORDER BY fecha, t.id;

-- ───────────────────────────────────────────────────────────────────────────────
-- 6. PAYMENT_VS_NET_MISMATCH - Detalle de Discrepancias
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
    t.id AS ticket_id,
    t.total_price AS total_bruto,
    COALESCE(t.total_discount, 0) AS descuento,
    t.total_price - COALESCE(t.total_discount, 0) AS neto_calculado,
    COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                      AND tx.transaction_type = 'CREDIT'
                                      AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0) AS total_pagado,
    (t.total_price - COALESCE(t.total_discount, 0)) - 
        COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                          AND tx.transaction_type = 'CREDIT'
                                          AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0) AS diferencia,
    t.paid,
    t.voided,
    STRING_AGG(tx.payment_type || '($' || tx.amount || ')', ', ') AS detalle_pagos
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
  AND t.paid = TRUE
  AND t.voided = FALSE
GROUP BY t.id, t.folio_date, t.closing_date, t.create_date, 
         t.total_price, t.total_discount, t.paid, t.voided
HAVING ABS((t.total_price - COALESCE(t.total_discount, 0)) - 
           COALESCE(SUM(tx.amount) FILTER (WHERE tx.voided = FALSE 
                                             AND tx.transaction_type = 'CREDIT'
                                             AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0)) > 0.01
ORDER BY ABS(diferencia) DESC;

-- ───────────────────────────────────────────────────────────────────────────────
-- 7. RESUMEN DE EXCEPCIONES POR DÍA
-- ───────────────────────────────────────────────────────────────────────────────
SELECT 
    fecha,
    COUNT(*) FILTER (WHERE descuento_100) AS tickets_desc_100_pct,
    COUNT(*) FILTER (WHERE no_pagado_cerrado) AS tickets_no_pagados_cerrados,
    COUNT(*) FILTER (WHERE anulado_con_pagos) AS tickets_anulados_con_pagos,
    COUNT(*) FILTER (WHERE pago_cero) AS transacciones_monto_cero,
    COUNT(*) FILTER (WHERE payment_mismatch) AS payment_vs_net_mismatch,
    SUM(total_price) FILTER (WHERE descuento_100) AS monto_desc_100,
    SUM(total_price) FILTER (WHERE no_pagado_cerrado) AS monto_no_pagado
FROM (
    SELECT 
        COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS fecha,
        t.total_price,
        (t.total_price > 0 AND COALESCE(t.total_discount, 0) >= t.total_price * 0.99) AS descuento_100,
        (t.paid = FALSE AND t.voided = FALSE AND t.total_price > 0) AS no_pagado_cerrado,
        (t.voided = TRUE AND EXISTS(SELECT 1 FROM transactions tx WHERE tx.ticket_id = t.id)) AS anulado_con_pagos,
        (EXISTS(SELECT 1 FROM transactions tx 
                WHERE tx.ticket_id = t.id 
                  AND tx.amount = 0 
                  AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS'))) AS pago_cero,
        (ABS((t.total_price - COALESCE(t.total_discount, 0)) - 
             COALESCE((SELECT SUM(tx.amount) 
                       FROM transactions tx 
                       WHERE tx.ticket_id = t.id 
                         AND tx.voided = FALSE 
                         AND tx.transaction_type = 'CREDIT'
                         AND tx.payment_type NOT IN ('REFUND', 'VOID_TRANS')), 0)) > 0.01
         AND t.paid = TRUE AND t.voided = FALSE) AS payment_mismatch
    FROM public.ticket t
    WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) >= '2025-10-01'
      AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) < '2025-11-01'
) excepciones
GROUP BY fecha
ORDER BY fecha;
