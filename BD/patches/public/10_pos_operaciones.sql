-- POS operaciones: funciones de conciliación y triggers auxiliares
BEGIN;
SET search_path = public, pg_catalog;

CREATE OR REPLACE FUNCTION public.fn_correct_drawer_report(report_date date)
RETURNS TABLE(
  terminal_id integer,
  original_total_revenue numeric,
  corrected_neto_tickets numeric,
  adjustment numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    dr.terminal_id,
    dr.total_revenue::numeric(12,2) AS original_total_revenue,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS corrected_neto_tickets,
    (SUM(t.total_price - t.total_discount) - dr.total_revenue)::numeric(12,2) AS adjustment
  FROM public.drawer_pull_report dr
  JOIN public.ticket t
    ON t.terminal_id = dr.terminal_id
   AND t.closing_date::date = dr.report_time::date
  WHERE dr.report_time::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY dr.terminal_id, dr.total_revenue;
END;
$$;


CREATE OR REPLACE FUNCTION public.fn_daily_reconciliation(report_date date)
RETURNS TABLE(
  terminal_id integer,
  tickets_count integer,
  transactions_count integer,
  ticket_net_total numeric,
  transactions_total numeric,
  difference numeric,
  status text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.terminal_id,
    COUNT(DISTINCT t.id) AS tickets_count,
    COUNT(tx.id) FILTER (
      WHERE tx.voided = FALSE
        AND tx.transaction_type = 'CREDIT'
        AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    ) AS transactions_count,
    SUM(t.total_price - t.total_discount)::numeric(12,2) AS ticket_net_total,
    SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount ELSE 0 END
    )::numeric(12,2) AS transactions_total,
    (SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount ELSE 0 END
    ) - SUM(t.total_price - t.total_discount))::numeric(12,2) AS difference,
    CASE
      WHEN SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount ELSE 0 END
      ) = SUM(t.total_price - t.total_discount)
      THEN 'OK'
      ELSE 'DISCREPANCY'
    END AS status
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.terminal_id;
END;
$$;


CREATE OR REPLACE FUNCTION public.fn_reconciliation_detail(report_date date)
RETURNS TABLE(
  ticket_id integer,
  terminal_id integer,
  ticket_number integer,
  ticket_total numeric,
  ticket_discount numeric,
  ticket_neto numeric,
  transactions_sum numeric,
  discrepancy numeric,
  discrepancy_type text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.terminal_id,
    t.daily_folio,
    t.total_price::numeric(12,2),
    t.total_discount::numeric(12,2),
    (t.total_price - t.total_discount)::numeric(12,2) AS ticket_neto,
    COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0)::numeric(12,2) AS transactions_sum,
    (COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount))::numeric(12,2) AS discrepancy,
    CASE
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount END
      ), 0) > (t.total_price - t.total_discount) THEN 'OVERSTATED'
      WHEN COALESCE(SUM(
        CASE
          WHEN tx.voided = FALSE
           AND tx.transaction_type = 'CREDIT'
           AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
          THEN tx.amount END
      ), 0) < (t.total_price - t.total_discount) THEN 'UNDERSTATED'
      ELSE 'OK'
    END AS discrepancy_type
  FROM public.ticket t
  LEFT JOIN public.transactions tx
    ON tx.ticket_id = t.id
  WHERE t.closing_date::date = report_date
    AND t.paid = TRUE
    AND t.voided = FALSE
  GROUP BY t.id, t.terminal_id, t.daily_folio, t.total_price, t.total_discount
  HAVING COALESCE(SUM(
    CASE
      WHEN tx.voided = FALSE
       AND tx.transaction_type = 'CREDIT'
       AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN tx.amount END
  ), 0) <> (t.total_price - t.total_discount)
  ORDER BY ABS(
    COALESCE(SUM(
      CASE
        WHEN tx.voided = FALSE
         AND tx.transaction_type = 'CREDIT'
         AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
        THEN tx.amount END
    ), 0) - (t.total_price - t.total_discount)
  ) DESC;
END;
$$;

  CREATE INDEX IF NOT EXISTS idx_transactions_time
      ON public.transactions (transaction_time);

  -- Si la tabla es muy grande, puedes usar un índice BRIN en vez del BTREE:
  -- CREATE INDEX IF NOT EXISTS idx_transactions_time_brin
  --     ON public.transactions USING brin (transaction_time);

  CREATE INDEX IF NOT EXISTS idx_ticket_closing_date
      ON public.ticket (closing_date);

  CREATE INDEX IF NOT EXISTS idx_ticket_item_ticket
      ON public.ticket_item (ticket_id);

  CREATE INDEX IF NOT EXISTS idx_pos_map_plu
      ON selemti.pos_map (plu);


DROP TRIGGER IF EXISTS trg_assign_daily_folio ON public.ticket;
CREATE TRIGGER trg_assign_daily_folio
BEFORE INSERT ON public.ticket
FOR EACH ROW EXECUTE PROCEDURE public.assign_daily_folio();


DROP TRIGGER IF EXISTS trg_kds_notify_kti ON public.kitchen_ticket_item;
CREATE TRIGGER trg_kds_notify_kti
AFTER INSERT OR UPDATE ON public.kitchen_ticket_item
FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();


DROP TRIGGER IF EXISTS trg_kds_notify_ti ON public.ticket_item;
CREATE TRIGGER trg_kds_notify_ti
AFTER INSERT OR UPDATE ON public.ticket_item
FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();


COMMIT;
