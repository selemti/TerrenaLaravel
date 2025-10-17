BEGIN;

-- =========================================
-- FASE 0: Verificación previa para evitar errores
-- =========================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.kitchen_ticket_item
        WHERE ticket_item_id IS NULL
        LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Existen filas con ticket_item_id NULL en kitchen_ticket_item. Corrija antes de continuar.';
    END IF;
END $$;

-- =========================================
-- FASE 1.A) Tabla contador por día y sucursal
-- =========================================
CREATE TABLE IF NOT EXISTS public.daily_folio_counter (
    folio_date   DATE    NOT NULL,
    branch_key   TEXT    NOT NULL,
    last_value   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (folio_date, branch_key)
);
ALTER TABLE public.daily_folio_counter OWNER TO floreant;

-- =========================================
-- FASE 1.B) Columnas nuevas en ticket (idempotente para PG 9.5)
-- =========================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'ticket'
        AND column_name = 'folio_date'
    ) THEN
        ALTER TABLE public.ticket ADD COLUMN folio_date DATE;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'ticket'
        AND column_name = 'branch_key'
    ) THEN
        ALTER TABLE public.ticket ADD COLUMN branch_key TEXT;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'ticket'
        AND column_name = 'daily_folio'
    ) THEN
        ALTER TABLE public.ticket ADD COLUMN daily_folio INTEGER;
    END IF;
END $$;

-- Constraint para daily_folio positivo (idempotente)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'ck_ticket_daily_folio_positive'
        AND conrelid = 'public.ticket'::regclass
    ) THEN
        ALTER TABLE public.ticket
        ADD CONSTRAINT ck_ticket_daily_folio_positive
        CHECK (daily_folio IS NULL OR daily_folio > 0);
    END IF;
END $$;

-- Índices no-únicos para consultas rápidas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'ix_ticket_folio_date'
    ) THEN
        CREATE INDEX ix_ticket_folio_date ON public.ticket (folio_date);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'ix_ticket_branch_key'
    ) THEN
        CREATE INDEX ix_ticket_branch_key ON public.ticket (branch_key);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'ix_ticket_item_ticket_pg'
    ) THEN
        CREATE INDEX ix_ticket_item_ticket_pg ON public.ticket_item (ticket_id, pg_id);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'ix_kitchen_ticket_item_item_id'
    ) THEN
        CREATE INDEX ix_kitchen_ticket_item_item_id ON public.kitchen_ticket_item (ticket_item_id);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'ix_kitchen_ticket_ticket_id'
    ) THEN
        CREATE INDEX ix_kitchen_ticket_ticket_id ON public.kitchen_ticket (ticket_id);
    END IF;
END $$;

-- Constraint para ticket_item_id NOT NULL en kitchen_ticket_item
ALTER TABLE public.kitchen_ticket_item
    ALTER COLUMN ticket_item_id SET NOT NULL;

-- =========================================
-- FASE 1.C) Función trigger con normalización consistente
-- =========================================
CREATE OR REPLACE FUNCTION public.assign_daily_folio()
RETURNS TRIGGER AS $$
DECLARE
    v_branch   TEXT;
    v_date     DATE;
    v_next     INTEGER;
BEGIN
    IF NEW.terminal_id IS NULL THEN
        RAISE EXCEPTION 'No se puede crear ticket sin terminal_id';
    END IF;
    IF NEW.create_date IS NULL THEN
        NEW.create_date := NOW();
    END IF;
    v_date := (NEW.create_date AT TIME ZONE 'America/Mexico_City')::DATE;
    SELECT COALESCE(NULLIF(UPPER(BTRIM(t.location)), ''), '') INTO v_branch
    FROM public.terminal t
    WHERE t.id = NEW.terminal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Terminal % no existe en la base de datos', NEW.terminal_id;
    END IF;
    IF NEW.daily_folio IS NOT NULL AND NEW.folio_date IS NOT NULL AND NEW.branch_key IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.ticket
            WHERE folio_date = NEW.folio_date
            AND branch_key = NEW.branch_key
            AND daily_folio = NEW.daily_folio
            AND id != NEW.id
        ) THEN
            RAISE EXCEPTION 'Folio % ya existe para % en %', NEW.daily_folio, NEW.branch_key, NEW.folio_date;
        END IF;
        RETURN NEW;
    END IF;
    WITH up AS (
        INSERT INTO public.daily_folio_counter (folio_date, branch_key, last_value)
        VALUES (v_date, v_branch, 1)
        ON CONFLICT (folio_date, branch_key)
        DO UPDATE SET last_value = public.daily_folio_counter.last_value + 1
        RETURNING last_value
    )
    SELECT last_value INTO v_next FROM up;
    NEW.folio_date := v_date;
    NEW.branch_key := v_branch;
    NEW.daily_folio := v_next;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;
ALTER FUNCTION public.assign_daily_folio() OWNER TO floreant;

-- Trigger (PG 9.5 => EXECUTE PROCEDURE)
DROP TRIGGER IF EXISTS trg_assign_daily_folio ON public.ticket;
CREATE TRIGGER trg_assign_daily_folio
BEFORE INSERT ON public.ticket
FOR EACH ROW EXECUTE PROCEDURE public.assign_daily_folio();

-- =========================================
-- FASE 1.E) kds_notify para notificaciones KDS/voceo
-- =========================================
CREATE OR REPLACE FUNCTION public.kds_notify() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_ticket_id   INT;
    v_pg_id       INT;
    v_item_id     INT;
    v_status      TEXT;
    v_total       INT;
    v_ready       INT;
    v_done        INT;
    v_type        TEXT;
    v_daily_folio INT;
    v_branch_key  TEXT;
    v_folio_fmt   TEXT;
BEGIN
    IF TG_TABLE_NAME = 'kitchen_ticket_item' THEN
        IF NEW.ticket_item_id IS NULL THEN
            RAISE EXCEPTION 'ticket_item_id no puede ser NULL en kitchen_ticket_item';
        END IF;
        v_item_id := NEW.ticket_item_id;
        SELECT ti.ticket_id, ti.pg_id INTO v_ticket_id, v_pg_id
        FROM ticket_item ti WHERE ti.id = v_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket_item % no existe', v_item_id;
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket % no existe', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, '0');
        v_status := UPPER(COALESCE(NEW.status, ''));
        v_type := CASE WHEN TG_OP = 'INSERT' THEN 'item_upsert' ELSE 'item_status' END;
        PERFORM pg_notify(
            'kds_event',
            json_build_object(
                'type',        v_type,
                'ticket_id',   v_ticket_id,
                'pg',          v_pg_id,
                'item_id',     v_item_id,
                'status',      v_status,
                'daily_folio', v_daily_folio,
                'branch_key',  v_branch_key,
                'folio_fmt',   v_folio_fmt,
                'ts',          NOW()
            )::TEXT
        );
    ELSIF TG_TABLE_NAME = 'ticket_item' THEN
        v_item_id := NEW.id;
        v_ticket_id := NEW.ticket_id;
        v_pg_id := NEW.pg_id;
        IF v_ticket_id IS NULL THEN
            RAISE EXCEPTION 'ticket_id no puede ser NULL en ticket_item';
        END IF;
        SELECT daily_folio, branch_key INTO v_daily_folio, v_branch_key
        FROM ticket WHERE id = v_ticket_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ticket % no existe', v_ticket_id;
        END IF;
        v_folio_fmt := LPAD(COALESCE(v_daily_folio, 0)::TEXT, 4, '0');
        v_status := UPPER(COALESCE(NEW.status, ''));
        v_type := CASE WHEN TG_OP = 'INSERT' THEN 'item_insert' ELSE 'item_status' END;
        PERFORM pg_notify(
            'kds_event',
            json_build_object(
                'type',        v_type,
                'ticket_id',   v_ticket_id,
                'pg',          v_pg_id,
                'item_id',     v_item_id,
                'status',      v_status,
                'daily_folio', v_daily_folio,
                'branch_key',  v_branch_key,
                'folio_fmt',   v_folio_fmt,
                'ts',          NOW()
            )::TEXT
        );
    END IF;
    IF v_ticket_id IS NOT NULL AND v_pg_id IS NOT NULL THEN
        WITH s AS (
            SELECT
                ti.id AS item_id,
                UPPER(COALESCE(kti.status, ti.status, '')) AS st
            FROM ticket_item ti
            LEFT JOIN kitchen_ticket_item kti ON kti.ticket_item_id = ti.id
            WHERE ti.ticket_id = v_ticket_id AND ti.pg_id = v_pg_id
            GROUP BY ti.id, st
        )
        SELECT
            COUNT(DISTINCT item_id) AS total,
            COUNT(DISTINCT item_id) FILTER (WHERE st IN ('READY', 'DONE')) AS ready,
            COUNT(DISTINCT item_id) FILTER (WHERE st = 'DONE') AS done
        INTO v_total, v_ready, v_done
        FROM s;
        IF v_total > 0 AND v_total = v_ready THEN
            PERFORM pg_notify(
                'kds_event',
                json_build_object(
                    'type',        'ticket_all_ready',
                    'ticket_id',   v_ticket_id,
                    'pg',          v_pg_id,
                    'daily_folio', v_daily_folio,
                    'branch_key',  v_branch_key,
                    'folio_fmt',   v_folio_fmt,
                    'ts',          NOW()
                )::TEXT
            );
        END IF;
        IF v_total > 0 AND v_total = v_done THEN
            PERFORM pg_notify(
                'kds_event',
                json_build_object(
                    'type',        'ticket_all_done',
                    'ticket_id',   v_ticket_id,
                    'pg',          v_pg_id,
                    'daily_folio', v_daily_folio,
                    'branch_key',  v_branch_key,
                    'folio_fmt',   v_folio_fmt,
                    'ts',          NOW()
                )::TEXT
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
ALTER FUNCTION public.kds_notify() OWNER TO floreant;

-- Triggers para kds_notify (PG 9.5 => EXECUTE PROCEDURE)
DROP TRIGGER IF EXISTS trg_kds_notify_ti ON public.ticket_item;
CREATE TRIGGER trg_kds_notify_ti
AFTER INSERT OR UPDATE OF status ON public.ticket_item
FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();

DROP TRIGGER IF EXISTS trg_kds_notify_kti ON public.kitchen_ticket_item;
CREATE TRIGGER trg_kds_notify_kti
AFTER INSERT OR UPDATE OF status ON public.kitchen_ticket_item
FOR EACH ROW EXECUTE PROCEDURE public.kds_notify();

-- =========================================
-- FASE 1.F) Vista KDS con prioridad voceo
-- =========================================
CREATE OR REPLACE VIEW public.kds_orders_enhanced AS
SELECT
    kt.id AS kitchen_ticket_id,
    kt.ticket_id,
    kt.create_date AS kds_created_at,
    kt.sequence_number,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    LPAD(t.daily_folio::TEXT, 4, '0') AS folio_display,
    t.number_of_guests,
    t.ticket_type,
    term.name AS terminal_name,
    CASE
        WHEN t.daily_folio BETWEEN 1 AND 20 THEN 'PRIORITARIO'
        WHEN t.daily_folio BETWEEN 21 AND 50 THEN 'NORMAL'
        ELSE 'ALTO_VOLUMEN'
    END AS prioridad_voceo
FROM public.kitchen_ticket kt
JOIN public.ticket t ON t.id = kt.ticket_id
LEFT JOIN public.terminal term ON t.terminal_id = term.id;
ALTER VIEW public.kds_orders_enhanced OWNER TO floreant;

-- =========================================
-- FASE 1.G) Vista para reportes/inventarios
-- =========================================
CREATE OR REPLACE VIEW public.ticket_folio_complete AS
SELECT
    t.id,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    t.total_price,
    t.paid_amount,
    t.create_date,
    TO_CHAR(t.folio_date, 'DD/MM/YYYY') AS folio_date_txt,
    LPAD(t.daily_folio::TEXT, 4, '0') AS folio_display,
    COALESCE(term.location, 'DEFAULT') AS sucursal_completa,
    term.name AS terminal_name,
    TO_CHAR(t.folio_date, 'YYYY-MM') AS periodo_mes,
    EXTRACT(HOUR FROM t.create_date) AS hora_venta, -- Asume que create_date está en hora local
    -- Si necesitas forzar zona (e.g., BD en UTC), usa: EXTRACT(HOUR FROM t.create_date AT TIME ZONE 'America/Mexico_City')
    EXTRACT(DOW FROM t.folio_date) AS dia_semana,
    CASE
        WHEN t.voided THEN 'CANCELADO'
        WHEN t.paid_amount > 0 THEN 'PAGADO'
        ELSE 'PENDIENTE'
    END AS status_simple
FROM public.ticket t
LEFT JOIN public.terminal term ON t.terminal_id = term.id;
ALTER VIEW public.ticket_folio_complete OWNER TO floreant;

-- =========================================
-- FASE 1.H) Función helper para Java/Jaspersoft
-- =========================================
CREATE OR REPLACE FUNCTION public.get_ticket_folio_info(p_ticket_id INTEGER)
RETURNS TABLE(
    daily_folio INTEGER,
    folio_date DATE,
    branch_key TEXT,
    folio_date_txt TEXT,
    folio_display TEXT,
    sucursal_completa TEXT,
    terminal_name TEXT
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        t.daily_folio,
        t.folio_date,
        t.branch_key,
        TO_CHAR(t.folio_date, 'DD/MM/YYYY') AS folio_date_txt,
        LPAD(t.daily_folio::TEXT, 4, '0') AS folio_display,
        COALESCE(term.location, 'DEFAULT') AS sucursal_completa,
        term.name AS terminal_name
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.id = p_ticket_id;
$$;
ALTER FUNCTION public.get_ticket_folio_info(integer) OWNER TO floreant;

-- =========================================
-- FASE 1.I) Stats diarias para inventarios
-- =========================================
CREATE OR REPLACE FUNCTION public.get_daily_stats(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    sucursal TEXT,
    total_ordenes INTEGER,
    total_ventas NUMERIC,
    primer_orden TIME,
    ultima_orden TIME,
    promedio_por_hora NUMERIC
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        tfc.branch_key,
        COUNT(*)::INTEGER AS total_ordenes,
        SUM(tfc.total_price)::NUMERIC AS total_ventas,
        MIN(tfc.create_date::TIME) AS primer_orden,
        MAX(tfc.create_date::TIME) AS ultima_orden,
        ROUND(
            (COUNT(*)::NUMERIC /
            GREATEST(EXTRACT(EPOCH FROM (MAX(tfc.create_date) - MIN(tfc.create_date))) / 3600.0, 1))::NUMERIC,
            2
        ) AS promedio_por_hora
    FROM public.ticket_folio_complete tfc
    WHERE tfc.folio_date = p_date
    AND tfc.status_simple != 'CANCELADO'
    GROUP BY tfc.branch_key
    ORDER BY tfc.branch_key;
$$;
ALTER FUNCTION public.get_daily_stats(date) OWNER TO floreant;

-- =========================================
-- FASE 2.A) Backfill histórico (determinista, opcional)
-- =========================================
-- COMENTADO: Ejecutar manualmente después si es necesario, para evitar fallos
/*
WITH sub AS (
    SELECT
        t.id,
        COALESCE(UPPER(BTRIM(term.location)), 'DEFAULT') AS branch_key,
        DATE(t.create_date AT TIME ZONE 'America/Mexico_City') AS folio_date,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(UPPER(BTRIM(term.location)), 'DEFAULT'),
                         DATE(t.create_date AT TIME ZONE 'America/Mexico_City')
            ORDER BY t.create_date ASC, t.id ASC
        ) AS row_num
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.daily_folio IS NULL
)
UPDATE public.ticket t
SET
    folio_date = sub.folio_date,
    branch_key = sub.branch_key,
    daily_folio = sub.row_num
FROM sub
WHERE t.id = sub.id;
*/

-- =========================================
-- FASE 2.B) Reset smart multi-sucursal
-- =========================================
CREATE OR REPLACE FUNCTION public.reset_daily_folio_smart(p_branch TEXT DEFAULT NULL)
RETURNS TABLE(branch_reset TEXT, tickets_affected INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date DATE := CURRENT_DATE;
    v_branch TEXT;
    v_has_rows BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.daily_folio_counter
        WHERE folio_date = v_current_date
        AND (p_branch IS NULL OR branch_key = UPPER(BTRIM(p_branch)))
    ) INTO v_has_rows;
    IF NOT v_has_rows THEN
        branch_reset := 'none';
        tickets_affected := 0;
        RETURN NEXT;
        RETURN;
    END IF;
    FOR v_branch IN
        SELECT DISTINCT
            CASE
                WHEN p_branch IS NULL THEN dfc.branch_key
                ELSE UPPER(BTRIM(p_branch))
            END
        FROM public.daily_folio_counter dfc
        WHERE dfc.folio_date = v_current_date
        AND (p_branch IS NULL OR dfc.branch_key = UPPER(BTRIM(p_branch)))
    LOOP
        IF EXISTS (
            SELECT 1 FROM public.ticket
            WHERE branch_key = v_branch
            AND folio_date = v_current_date
        ) THEN
            RAISE NOTICE 'ADVERTENCIA: Sucursal % ya tiene % tickets hoy - NO reseteable',
                v_branch,
                (SELECT COUNT(*) FROM public.ticket WHERE branch_key = v_branch AND folio_date = v_current_date);
            CONTINUE;
        END IF;
        DELETE FROM public.daily_folio_counter
        WHERE branch_key = v_branch AND folio_date = v_current_date;
        branch_reset := v_branch;
        tickets_affected := 0;
        RETURN NEXT;
    END LOOP;
    RETURN;
END
$$;
ALTER FUNCTION public.reset_daily_folio_smart(text) OWNER TO floreant;

-- =========================================
-- FASE 3) Índice único parcial post-backfill
-- =========================================
DO $$
BEGIN
    DROP INDEX IF EXISTS public.ux_ticket_dailyfolio;
    CREATE UNIQUE INDEX ux_ticket_dailyfolio
    ON public.ticket (folio_date, branch_key, daily_folio)
    WHERE daily_folio IS NOT NULL;
END $$;

-- =========================================
-- Permisos
-- =========================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_folio_counter TO floreant;
GRANT SELECT ON public.ticket_folio_complete, public.kds_orders_enhanced TO floreant;
GRANT EXECUTE ON FUNCTION public.assign_daily_folio() TO floreant;
GRANT EXECUTE ON FUNCTION public.get_daily_stats(date) TO floreant;
GRANT EXECUTE ON FUNCTION public.get_ticket_folio_info(integer) TO floreant;
GRANT EXECUTE ON FUNCTION public.reset_daily_folio_smart(text) TO floreant;

COMMIT;

-- =========================================
-- Post-Deploy: Normalizar branch_key
-- =========================================
UPDATE public.terminal SET location = UPPER(BTRIM(location)) WHERE location IS NOT NULL;
UPDATE public.ticket SET branch_key = UPPER(BTRIM(branch_key)) WHERE branch_key IS NOT NULL;

-- =========================================
-- Backfill Manual (Ejecutar si es necesario)
-- =========================================
/*
-- Ejecutar en batches si hay muchos tickets, e.g., por mes
WITH sub AS (
    SELECT
        t.id,
        COALESCE(UPPER(BTRIM(term.location)), 'DEFAULT') AS branch_key,
        DATE(t.create_date AT TIME ZONE 'America/Mexico_City') AS folio_date,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(UPPER(BTRIM(term.location)), 'DEFAULT'),
                         DATE(t.create_date AT TIME ZONE 'America/Mexico_City')
            ORDER BY t.create_date ASC, t.id ASC
        ) AS row_num
    FROM public.ticket t
    LEFT JOIN public.terminal term ON t.terminal_id = term.id
    WHERE t.daily_folio IS NULL
    AND t.create_date BETWEEN '2025-01-01' AND '2025-01-31'
)
UPDATE public.ticket t
SET
    folio_date = sub.folio_date,
    branch_key = sub.branch_key,
    daily_folio = sub.row_num
FROM sub
WHERE t.id = sub.id;
*/