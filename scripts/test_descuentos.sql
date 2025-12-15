-- Función simple para calcular descuentos reales de sesión
CREATE OR REPLACE FUNCTION public.fn_descuentos_reales_sesion_simple(p_sesion_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_terminal_id INTEGER;
    v_apertura_ts TIMESTAMPTZ;
    v_cierre_ts TIMESTAMPTZ;
    v_total_descuentos NUMERIC;
BEGIN
    -- Obtener datos de la sesión
    SELECT terminal_id, apertura_ts, COALESCE(cierre_ts, NOW()) AS cierre_ts
    INTO v_terminal_id, v_apertura_ts, v_cierre_ts
    FROM selemti.sesion_cajon
    WHERE id = p_sesion_id;

    -- Calcular total de descuentos reales
    SELECT COALESCE(SUM(t.total_discount), 0)
    INTO v_total_descuentos
    FROM public.ticket t
    WHERE t.terminal_id = v_terminal_id
      AND t.closing_date >= v_apertura_ts
      AND t.closing_date < v_cierre_ts
      AND t.voided = false
      AND t.total_discount > 0;

    RETURN COALESCE(v_total_descuentos, 0);
END;
$$;