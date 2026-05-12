WITH sesiones AS (
    SELECT id, terminal_id, apertura_ts, cierre_ts
    FROM selemti.sesion_cajon
    WHERE cierre_ts IS NOT NULL
)
SELECT t.id AS ticket_id,
       t.terminal_id,
       t.create_date,
       t.closing_date,
       s.id AS sesion_id,
       s.apertura_ts,
       s.cierre_ts
FROM public.ticket t
JOIN sesiones s ON s.terminal_id = t.terminal_id
WHERE t.closing_date Is NOT NULL
  AND t.create_date >= (s.apertura_ts - INTERVAL '12 hours')
  AND t.create_date <= (s.cierre_ts + INTERVAL '12 hours')
  AND (t.closing_date < s.apertura_ts OR t.closing_date >= s.cierre_ts)
LIMIT 5;
