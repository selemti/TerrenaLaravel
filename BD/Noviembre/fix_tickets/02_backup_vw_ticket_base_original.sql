-- ============================================================================
-- BACKUP: Vista Original vw_ticket_base
-- Fecha: 06 Noviembre 2025
-- Propósito: Backup antes de aplicar correcciones
-- ============================================================================

-- Para restaurar la vista original, ejecutar este script
-- IMPORTANTE: Solo usar si necesitas revertir los cambios

DROP VIEW IF EXISTS public.vw_ticket_base CASCADE;

CREATE VIEW public.vw_ticket_base AS
SELECT
    t.id AS ticket_id,
    t.terminal_id,
    t.branch_key,
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    COALESCE(t.total_price, 0::double precision)::numeric(12,2) AS total_price,
    GREATEST(
        0::double precision,
        LEAST(
            COALESCE(
                t.total_discount,
                (
                    SELECT sum(COALESCE(ti.discount, COALESCE(ti.discount, 0::double precision))) AS sum
                    FROM ticket_item ti
                    WHERE ti.ticket_id = t.id
                ),
                0::double precision
            ),
            COALESCE(t.total_price, 0::double precision)
        )
    )::numeric(12,2) AS total_discount,
    COALESCE(
        (
            SELECT sum(g.amount) AS sum
            FROM gratuity g
            WHERE g.ticket_id = t.id
                AND COALESCE(g.refunded, false) = false
                AND COALESCE(g.paid, true) = true
        ),
        0::double precision
    )::numeric(12,2) AS tip_amount,
    COALESCE(t.service_charge, 0::double precision)::numeric(12,2) AS service_charges
FROM ticket t
WHERE t.paid = true
    AND t.voided = false;

-- ============================================================================
-- FIN DEL BACKUP
-- ============================================================================
