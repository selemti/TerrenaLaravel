-- database/sql/views/vw_items_modifiers.sql
-- PG 9.5: Función dinámica para agrupar Ítems + Modificadores por fecha

SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

DROP FUNCTION IF EXISTS public.f_item_mods_on(date);

CREATE OR REPLACE FUNCTION public.f_item_mods_on(p_date date)
RETURNS TABLE(
  folio_date date,
  branch_key text,
  terminal_id integer,
  ticket_id integer,
  ticket_item_id integer,
  item_name text,
  modifier_name text,
  qty_item numeric(12,2),
  mods_count bigint,
  mods_total_amount numeric(12,2)
) AS $$
DECLARE
  ti_name_col text;
  ti_qty_col  text;
  ti_tot_col  text;
  ti_disc_col text;
  tim_name_col text;
  tim_amount_col text;
  has_rel boolean;
  sql text;
BEGIN
  -- Detectar columnas en ticket_item
  SELECT column_name INTO ti_name_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item'
    AND column_name IN ('item_name','name','display_name')
  LIMIT 1;

  SELECT column_name INTO ti_qty_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item'
    AND column_name IN ('item_quantity','quantity','qty')
  LIMIT 1;

  SELECT column_name INTO ti_tot_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item'
    AND column_name IN ('total_price','item_total','price','amount')
  LIMIT 1;

  SELECT column_name INTO ti_disc_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item'
    AND column_name IN ('discount','discount_amount')
  LIMIT 1;

  -- Detectar columnas en ticket_item_modifier
  SELECT column_name INTO tim_name_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item_modifier'
    AND column_name IN ('modifier_name','name','display_name','label')
  LIMIT 1;

  SELECT column_name INTO tim_amount_col
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='ticket_item_modifier'
    AND column_name IN ('price','extra_price','total_price','amount','unit_price')
  LIMIT 1;

  -- Verificar si existe la tabla relation
  has_rel := (to_regclass('public.ticket_item_modifier_relation') IS NOT NULL);

  IF ti_name_col IS NULL OR ti_qty_col IS NULL THEN
    RAISE EXCEPTION 'No se encontraron columnas esperadas en ticket_item (name/quantity). Revisa la instalación.';
  END IF;
  IF tim_name_col IS NULL THEN
    RAISE EXCEPTION 'No se encontraron columnas de nombre en ticket_item_modifier.';
  END IF;

  -- Construir SQL dinámico
  sql := 'SELECT
            COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
            t.branch_key,
            t.terminal_id,
            t.id AS ticket_id,
            ti.id AS ticket_item_id,
            ti.'||quote_ident(ti_name_col)||'::text AS item_name,
            tim.'||quote_ident(tim_name_col)||'::text AS modifier_name,
            COALESCE(ti.'||quote_ident(ti_qty_col)||',0)::numeric(12,2) AS qty_item,
            COUNT(*)::bigint AS mods_count,';

  IF tim_amount_col IS NULL THEN
    sql := sql || ' 0::numeric(12,2) AS mods_total_amount ';
  ELSE
    sql := sql || ' ROUND(SUM(COALESCE(tim.'||quote_ident(tim_amount_col)||',0))::numeric,2) AS mods_total_amount ';
  END IF;

  sql := sql || '
          FROM public.ticket t
          JOIN public.ticket_item ti ON ti.ticket_id = t.id ';

  IF has_rel THEN
    sql := sql || '
          JOIN public.ticket_item_modifier_relation r ON r.ticket_item_id = ti.id
          JOIN public.ticket_item_modifier tim ON tim.id = r.ticket_item_modifier_id ';
  ELSE
    sql := sql || '
          JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id ';
  END IF;

  sql := sql || '
          WHERE t.paid = TRUE AND t.voided = FALSE
            AND COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = $1
          GROUP BY 1,2,3,4,5,6,7,8
          ORDER BY item_name, modifier_name';

  RETURN QUERY EXECUTE sql USING p_date;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Wrapper a hoy
DROP VIEW IF EXISTS vw_item_mods_today;
CREATE VIEW vw_item_mods_today AS
SELECT * FROM public.f_item_mods_on(CURRENT_DATE);