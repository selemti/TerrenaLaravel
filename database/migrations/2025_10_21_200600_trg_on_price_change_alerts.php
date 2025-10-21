<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
  public function up(): void {
    DB::unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.fn_recipes_using_item(p_item_id bigint, p_at timestamp)
RETURNS TABLE(recipe_id bigint) AS $$
BEGIN
  RETURN QUERY
    SELECT DISTINCT rv.recipe_id
    FROM selemti.recipe_versions rv
    JOIN selemti.recipe_version_items rvi ON rvi.recipe_version_id = rv.id
    WHERE rvi.item_id = p_item_id
      AND rv.valid_from <= p_at
      AND (rv.valid_to IS NULL OR rv.valid_to > p_at);
END$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION selemti.fn_after_price_insert_alert()
RETURNS trigger AS $$
DECLARE
  r_id bigint;
  v_now timestamp := COALESCE(NEW.effective_from, now());
  v_old numeric; v_new numeric; v_delta numeric; v_rule numeric;
BEGIN
  FOR r_id IN SELECT recipe_id FROM selemti.fn_recipes_using_item(NEW.item_id, v_now)
  LOOP
    SELECT portion_cost INTO v_new FROM selemti.fn_recipe_cost_at(r_id, v_now);
    SELECT portion_cost INTO v_old
      FROM selemti.recipe_cost_history
      WHERE recipe_id = r_id AND snapshot_at < v_now
      ORDER BY snapshot_at DESC LIMIT 1;

    PERFORM selemti.sp_snapshot_recipe_cost(r_id, v_now);

    IF v_old IS NOT NULL AND v_new IS NOT NULL AND v_old > 0 THEN
      v_delta := ((v_new - v_old)/v_old) * 100.0;

      SELECT COALESCE((
        SELECT threshold_pct
        FROM selemti.alert_rules
        WHERE active = TRUE
          AND (recipe_id = r_id OR category_id IS NOT NULL)
        ORDER BY recipe_id NULLS LAST
        LIMIT 1
      ), 10.0) INTO v_rule;

      IF v_delta >= v_rule THEN
        INSERT INTO selemti.alert_events(recipe_id, snapshot_at, old_portion_cost, new_portion_cost, delta_pct)
        VALUES (r_id, v_now, v_old, v_new, v_delta);
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_ivp_after_insert') THEN
    CREATE TRIGGER trg_ivp_after_insert
      AFTER INSERT ON selemti.item_vendor_prices
      FOR EACH ROW EXECUTE FUNCTION selemti.fn_after_price_insert_alert();
  END IF;
END$$;
SQL);
  }
  public function down(): void {
    DB::unprepared("DROP TRIGGER IF EXISTS trg_ivp_after_insert ON selemti.item_vendor_prices");
    DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_after_price_insert_alert()");
    DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_recipes_using_item(bigint,timestamp)");
  }
};
