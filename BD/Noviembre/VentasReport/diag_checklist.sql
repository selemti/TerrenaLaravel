-- database/sql/diagnostics/diag_checklist.sql
-- Validación rápida post-deploy (PG 9.5)

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- Días recientes con datos (tickets válidos)
SELECT closing_date::date AS d, COUNT(*) AS tickets
FROM public.ticket
WHERE paid = TRUE AND voided = FALSE
GROUP BY 1 ORDER BY 1 DESC LIMIT 15;

-- Ventas por terminal (top 10)
SELECT * FROM vw_sales_by_terminal ORDER BY folio_date DESC, tickets DESC LIMIT 10;

-- Mix de pago (hoy)
SELECT * FROM vw_sales_mix_payment_today;

-- Neto vs cobros (anomalias top 10)
SELECT * FROM vw_diag_neto_vs_cobros ORDER BY ABS(diff) DESC LIMIT 10;

-- Paid sin cobros (top 10)
SELECT * FROM vw_diag_paid_but_no_payments ORDER BY neto DESC LIMIT 10;

-- Reconciliación de cajón vs efectivo (hoy / puede ser vacío)
SELECT * FROM vw_diag_drawer_vs_cash_transactions;

-- Resumen operativo (hoy)
SELECT * FROM vw_daily_diagnostics_summary;

-- Resumen operativo (día con datos)
-- Ajusta la fecha a un día con ventas válidas detectado arriba
-- SELECT * FROM public.f_daily_diagnostics_summary_on('2025-10-24');

-- Ítems + Modificadores (día con datos)
-- SELECT * FROM public.f_item_mods_on('2025-10-24') ORDER BY item_name, modifier_name;