-- ============================================================================
-- Vista: Sales Mix (Mezcla de formas de pago)
-- Prioridad: CRÍTICA
-- ============================================================================
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- Función: Sales Mix por fecha
CREATE OR REPLACE FUNCTION public.f_sales_mix_payment_on(p_date date)
RETURNS TABLE(
  folio_date date,
  branch_key text,
  normalized_payment text,
  total numeric(12,2)
) 
LANGUAGE sql STABLE AS
$$
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  COALESCE(t.branch_key, 'UNKNOWN')::text AS branch_key,
  selemti.fn_normalizar_forma_pago(
    tx.payment_type, 
    tx.transaction_type, 
    tx.payment_sub_type, 
    tx.custom_payment_name
  ) AS normalized_payment,
  ROUND(SUM(
    CASE
      WHEN tx.voided = FALSE 
        AND UPPER(tx.transaction_type) = 'CREDIT'
        AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
      THEN COALESCE(tx.amount, 0) 
      ELSE 0 
    END
  )::numeric, 2) AS total
FROM public.ticket t
JOIN public.transactions tx ON tx.ticket_id = t.id
WHERE t.paid = TRUE 
  AND t.voided = FALSE
  AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = p_date
GROUP BY 1, 2, 3
HAVING SUM(
  CASE
    WHEN tx.voided = FALSE 
      AND UPPER(tx.transaction_type) = 'CREDIT'
      AND tx.payment_type NOT IN ('REFUND','VOID_TRANS')
    THEN COALESCE(tx.amount, 0) 
    ELSE 0 
  END
) > 0;
$$;

-- Vista: Sales Mix Hoy
CREATE OR REPLACE VIEW public.vw_sales_mix_payment_today AS
SELECT * FROM public.f_sales_mix_payment_on(CURRENT_DATE);

SELECT 'Sales Mix creado exitosamente' as status;
