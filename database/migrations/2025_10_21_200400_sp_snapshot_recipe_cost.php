<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
  public function up(): void {
    DB::unprepared(<<<'SQL'
CREATE OR REPLACE FUNCTION selemti.sp_snapshot_recipe_cost(p_recipe_id bigint, p_at timestamp)
RETURNS VOID AS $$
DECLARE
  v_batch numeric; v_portion numeric; v_bs numeric; v_y numeric;
  v_rv_id bigint;
BEGIN
  SELECT id INTO v_rv_id
    FROM selemti.recipe_versions
   WHERE recipe_id = p_recipe_id
     AND valid_from <= p_at
     AND (valid_to IS NULL OR valid_to > p_at)
   ORDER BY valid_from DESC LIMIT 1;

  SELECT batch_cost, portion_cost, batch_size, yield_portions
    INTO v_batch, v_portion, v_bs, v_y
    FROM selemti.fn_recipe_cost_at(p_recipe_id, p_at);

  INSERT INTO selemti.recipe_cost_history(recipe_id, recipe_version_id, snapshot_at, batch_cost, portion_cost, batch_size, yield_portions)
  VALUES (p_recipe_id, v_rv_id, p_at, v_batch, v_portion, v_bs, v_y);
END$$ LANGUAGE plpgsql;
SQL);
  }
  public function down(): void {
    DB::unprepared("DROP FUNCTION IF EXISTS selemti.sp_snapshot_recipe_cost(bigint,timestamp)");
  }
};
