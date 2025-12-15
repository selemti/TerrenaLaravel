-- Función para calcular descuentos reales de una sesión
-- Esto servirá para el postcorte y métricas futuras

DROP FUNCTION IF EXISTS public.fn_calcular_descuentos_reales_sesion(BIGINT);

CREATE OR REPLACE FUNCTION public.fn_calcular_descuentos_reales_sesion(p_sesion_id BIGINT)
RETURNS TABLE(
    total_descuentos_reales NUMERIC,
    total_descuentos_100 NUMERIC,
    total_descuentos_linea NUMERIC,
    tickets_con_descuento INTEGER,
    tickets_descuento_100 INTEGER,
    detalle_descuentos JSON
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_terminal_id INTEGER;
    v_apertura_ts TIMESTAMPTZ;
    v_cierre_ts TIMESTAMPTZ;
BEGIN
    -- Obtener datos de la sesión
    SELECT terminal_id, apertura_ts, COALESCE(cierre_ts, NOW()) AS cierre_ts
    INTO v_terminal_id, v_apertura_ts, v_cierre_ts
    FROM selemti.sesion_cajon
    WHERE id = p_sesion_id;

    RETURN QUERY
    SELECT
        COALESCE(SUM(t.total_discount), 0) as total_descuentos_reales,
        COALESCE(SUM(td.value), 0) as total_descuentos_100,
        COALESCE(SUM(COALESCE(tid.value, 0)), 0) as total_descuentos_linea,
        COUNT(CASE WHEN t.total_discount > 0 THEN 1 END) as tickets_con_descuento,
        COUNT(DISTINCT td.id) as tickets_descuento_100,
        json_build_object(
            'sesion_id', p_sesion_id,
            'terminal_id', v_terminal_id,
            'periodo', json_build_object(
                'apertura', v_apertura_ts,
                'cierre', v_cierre_ts
            ),
            'resumen', json_build_object(
                'total_tickets', COUNT(t.id),
                'tickets_con_descuento_header', COUNT(CASE WHEN t.total_discount > 0 THEN 1 END),
                'tickets_con_descuento_100', COUNT(DISTINCT td.id),
                'tickets_con_descuento_linea', COUNT(DISTINCT tid.id)
            )
        ) as detalle_descuentos
    FROM public.ticket t
    LEFT JOIN public.ticket_discount td ON t.id = td.ticket_id
    LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
    LEFT JOIN public.ticket_item_discount tid ON ti.id = tid.ticket_itemid
    WHERE t.terminal_id = v_terminal_id
      AND t.closing_date >= v_apertura_ts
      AND t.closing_date < v_cierre_ts
      AND t.voided = false;
END;
$$;

-- Función simplificada para obtener solo el total de descuentos reales
CREATE OR REPLACE FUNCTION public.fn_descuentos_reales_sesion(p_sesion_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_result NUMERIC;
BEGIN
    SELECT total_descuentos_reales INTO v_result
    FROM public.fn_calcular_descuentos_reales_sesion(p_sesion_id)
    LIMIT 1;

    RETURN COALESCE(v_result, 0);
END;
$$;

-- Vista para comparar drawer_pull vs descuentos reales
CREATE OR REPLACE VIEW public.vw_descuentos_drawer_vs_reales AS
SELECT
    dpr.id,
    dpr.report_time,
    dpr.terminal_id,
    dpr.totaldiscountamount as descuentos_drawer,
    dr.total_descuentos_reales,
    (dpr.totaldiscountamount - dr.total_descuentos_reales) as diferencia,
    CASE
        WHEN dpr.totaldiscountamount = dr.total_descuentos_reales THEN 'EXACTO'
        WHEN dpr.totaldiscountamount > dr.total_descuentos_reales THEN 'SOBRESTIMADO'
        ELSE 'SUBESTIMADO'
    END as estado,
    CASE
        WHEN dr.total_descuentos_reales > 0
        THEN ROUND(((dpr.totaldiscountamount - dr.total_descuentos_reales)::numeric / dr.total_descuentos_reales * 100), 2)
        ELSE 0
    END as porcentaje_error
FROM public.drawer_pull_report dpr
JOIN public.fn_calcular_descuentos_reales_sesion(
    (SELECT sc.id
     FROM selemti.sesion_cajon sc
     WHERE sc.terminal_id = dpr.terminal_id
       AND sc.apertura_ts <= dpr.report_time
       AND COALESCE(sc.cierre_ts, NOW()) > dpr.report_time
     ORDER BY sc.apertura_ts DESC LIMIT 1)::BIGINT
) dr ON true;

-- Función para diagnosticar problemas de descuentos por terminal y fecha
CREATE OR REPLACE FUNCTION public.fn_diagnosticar_descuentos_fecha(p_fecha DATE)
RETURNS TABLE(
    terminal_id INTEGER,
    drawer_reportado NUMERIC,
    calculado_reales NUMERIC,
    diferencia NUMERIC,
    estado TEXT,
    impacto_financiero NUMERIC,
    recomendacion TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH descuentos_terminal AS (
        SELECT
            dpr.terminal_id,
            dpr.totaldiscountamount as drawer_reportado,
            dr.total_descuentos_reales as calculado_reales,
            (dpr.totaldiscountamount - dr.total_descuentos_reales) as diferencia
        FROM public.drawer_pull_report dpr
        JOIN (
            SELECT
                sc.terminal_id,
                SUM(CASE WHEN t.total_discount > 0 THEN t.total_discount ELSE 0 END) as total_descuentos_reales
            FROM selemti.sesion_cajon sc
            JOIN public.ticket t ON t.terminal_id = sc.terminal_id
            WHERE t.closing_date::date = p_fecha
              AND t.closing_date >= sc.apertura_ts
              AND t.closing_date < COALESCE(sc.cierre_ts, NOW() + INTERVAL '1 day')
              AND t.voided = false
            GROUP BY sc.terminal_id
        ) dr ON dr.terminal_id = dpr.terminal_id
        WHERE dpr.report_time::date = p_fecha
          AND dpr.ticket_count > 0
    )
    SELECT
        terminal_id,
        drawer_reportado,
        calculado_reales,
        diferencia,
        CASE
            WHEN ABS(diferencia) < 1 THEN 'OK'
            WHEN ABS(diferencia) < 100 THEN 'ACEPTABLE'
            WHEN ABS(diferencia) < 500 THEN 'REVISAR'
            ELSE 'CRITICO'
        END as estado,
        ABS(diferencia) as impacto_financiero,
        CASE
            WHEN ABS(diferencia) < 1 THEN 'Sin acción requerida'
            WHEN ABS(diferencia) < 100 THEN 'Monitorear tendencia'
            WHEN ABS(diferencia) < 500 THEN 'Revisar configuración POS'
            ELSE 'Investigar urgentemente - posible error sistémico'
        END as recomendacion
    FROM descuentos_terminal
    ORDER BY ABS(diferencia) DESC;
END;
$$;