<?php

return new class extends \Illuminate\Database\Migrations\Migration {
  public function up(): void
  {
    \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_uom_factor(from_uom text, to_uom text)
RETURNS numeric AS $$
DECLARE v numeric := 1;
BEGIN
  IF from_uom IS NULL OR to_uom IS NULL OR lower(from_uom)=lower(to_uom) THEN
    RETURN 1;
  END IF;
  SELECT factor INTO v
    FROM selemti.cat_uom_conversion
   WHERE lower(from_uom)=lower($1) AND lower(to_uom)=lower($2)
   LIMIT 1;
  IF v IS NULL THEN
    RAISE EXCEPTION 'No hay conversión de % -> %', from_uom, to_uom;
  END IF;
  RETURN v;
END$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION selemti.fn_item_unit_cost_at(p_item_id bigint, p_at timestamp, p_target_uom text)
RETURNS numeric AS $$
DECLARE
  v_price    numeric;
  v_pack_qty numeric;
  v_pack_uom text;
  v_factor   numeric;
BEGIN
  SELECT price, pack_qty, pack_uom
    INTO v_price, v_pack_qty, v_pack_uom
  FROM selemti.item_vendor_prices
  WHERE item_id = p_item_id
    AND effective_from <= p_at
    AND (effective_to IS NULL OR effective_to > p_at)
  ORDER BY effective_from DESC
  LIMIT 1;

  IF v_price IS NULL THEN
    RETURN NULL;
  END IF;

  v_factor := selemti.fn_uom_factor(v_pack_uom, p_target_uom);
  RETURN (v_price / NULLIF(v_pack_qty,0)) * v_factor;
END$$ LANGUAGE plpgsql;
SQL);
  }

  public function down(): void
  {
    \Illuminate\Support\Facades\DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_item_unit_cost_at(bigint,timestamp,text)");
    \Illuminate\Support\Facades\DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_uom_factor(text,text)");
  }
};
