-- ============================================================
-- Vista: selemti.vw_sesion_dpr  (versión 2 — 2026-04-09)
-- ============================================================
-- CAMBIO: Ventana extendida a cierre_ts + 2 horas para cubrir
-- DPRs generados fuera de tiempo (desfase de zona horaria en
-- Floreant POS o corte manual posterior al cierre de sesión).
--
-- Versión anterior usaba: COALESCE(cierre_ts, now())
-- Esta versión usa:       COALESCE(cierre_ts + INTERVAL '2 hours', now())
-- ============================================================

CREATE OR REPLACE VIEW selemti.vw_sesion_dpr AS
WITH s AS (
    SELECT
        sesion_cajon.id,
        sesion_cajon.terminal_id,
        sesion_cajon.cajero_usuario_id,
        sesion_cajon.apertura_ts,
        -- Tolerancia de 2 horas para DPRs tardíos (desfase Floreant o corte manual)
        COALESCE(sesion_cajon.cierre_ts + INTERVAL '2 hours', now()) AS fin_ts
    FROM selemti.sesion_cajon
)
SELECT
    s.id AS sesion_id,
    dpr.id,
    dpr.report_time,
    dpr.reg,
    dpr.ticket_count,
    dpr.begin_cash,
    dpr.net_sales,
    dpr.sales_tax,
    dpr.cash_tax,
    dpr.total_revenue,
    dpr.gross_receipts,
    dpr.giftcertreturncount,
    dpr.giftcertreturnamount,
    dpr.giftcertchangeamount,
    dpr.cash_receipt_no,
    dpr.cash_receipt_amount,
    dpr.credit_card_receipt_no,
    dpr.credit_card_receipt_amount,
    dpr.debit_card_receipt_no,
    dpr.debit_card_receipt_amount,
    dpr.refund_receipt_count,
    dpr.refund_amount,
    dpr.receipt_differential,
    dpr.cash_back,
    dpr.cash_tips,
    dpr.charged_tips,
    dpr.tips_paid,
    dpr.tips_differential,
    dpr.pay_out_no,
    dpr.pay_out_amount,
    dpr.drawer_bleed_no,
    dpr.drawer_bleed_amount,
    dpr.drawer_accountable,
    dpr.cash_to_deposit,
    dpr.variance,
    dpr.delivery_charge,
    dpr.totalvoidwst,
    dpr.totalvoid,
    dpr.totaldiscountcount,
    dpr.totaldiscountamount,
    dpr.totaldiscountsales,
    dpr.totaldiscountguest,
    dpr.totaldiscountpartysize,
    dpr.totaldiscountchecksize,
    dpr.totaldiscountpercentage,
    dpr.totaldiscountratio,
    dpr.user_id,
    dpr.terminal_id
FROM s
JOIN public.drawer_pull_report dpr
    ON  dpr.terminal_id  = s.terminal_id
    AND dpr.report_time >= s.apertura_ts
    AND dpr.report_time  < s.fin_ts;

ALTER TABLE selemti.vw_sesion_dpr OWNER TO postgres;
