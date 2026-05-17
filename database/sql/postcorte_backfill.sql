-- One-time backfill for existing NULL postcorte rows
BEGIN;

UPDATE selemti.postcorte p
SET
    total_ventas_brutas     = t.ventas_brutas,
    total_descuentos_reales = t.descuentos,
    total_ventas_netas      = t.ventas_netas
FROM (
    SELECT
        pc.id AS postcorte_id,
        COALESCE(SUM(tk.sub_total), 0)      AS ventas_brutas,
        COALESCE(SUM(tk.total_discount), 0) AS descuentos,
        COALESCE(SUM(tk.total_price), 0)    AS ventas_netas
    FROM selemti.postcorte pc
    JOIN selemti.sesion_cajon sc ON sc.id = pc.sesion_id
    JOIN public.ticket tk ON tk.terminal_id = sc.terminal_id
        AND tk.create_date >= (sc.apertura_ts - interval '1 hour')
        AND tk.create_date <= (COALESCE(sc.cierre_ts, now()) + interval '2 hours')
        AND tk.voided = false
    WHERE pc.total_ventas_brutas IS NULL
    GROUP BY pc.id
) t
WHERE p.id = t.postcorte_id;

-- Ensure to verify the updated row count before committing!
-- COMMIT;
