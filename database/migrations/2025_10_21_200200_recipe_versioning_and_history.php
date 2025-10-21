<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades.DB;

return new class extends Migration {
  public function up(): void {
    DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.recipe_versions (
  id           BIGSERIAL PRIMARY KEY,
  recipe_id    BIGINT NOT NULL,
  version_no   INTEGER NOT NULL,
  notes        TEXT,
  valid_from   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  valid_to     TIMESTAMP WITHOUT TIME ZONE,
  created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_recipe_version ON selemti.recipe_versions(recipe_id, version_no);

CREATE TABLE IF NOT EXISTS selemti.recipe_version_items (
  id                BIGSERIAL PRIMARY KEY,
  recipe_version_id BIGINT NOT NULL,
  item_id           BIGINT NOT NULL,
  qty               NUMERIC(14,6) NOT NULL,
  uom_receta        VARCHAR(20) NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_rvi_rv ON selemti.recipe_version_items(recipe_version_id);

CREATE TABLE IF NOT EXISTS selemti.recipe_cost_history (
  id               BIGSERIAL PRIMARY KEY,
  recipe_id        BIGINT NOT NULL,
  recipe_version_id BIGINT,
  snapshot_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  currency_code    VARCHAR(10) DEFAULT 'MXN',
  batch_cost       NUMERIC(14,6),
  portion_cost     NUMERIC(14,6),
  batch_size       NUMERIC(14,6),
  yield_portions   NUMERIC(14,6),
  notes            TEXT,
  created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_rch_recipe_at ON selemti.recipe_cost_history(recipe_id, snapshot_at);
SQL);
  }
  public function down(): void {
    DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_cost_history");
    DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_version_items");
    DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_versions");
  }
};
