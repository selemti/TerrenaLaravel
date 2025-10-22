<?php

return new class extends \Illuminate\Database\Migrations\Migration {
  public function up(): void
  {
    \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.recipe_versions (
  id           BIGSERIAL PRIMARY KEY,
  recipe_id    BIGINT NOT NULL,
  version_no   INTEGER NOT NULL,
  notes        TEXT,
  valid_from   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  valid_to     TIMESTAMP WITHOUT TIME ZONE,
  created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ux_recipe_version'
) THEN
  CREATE UNIQUE INDEX ux_recipe_version ON selemti.recipe_versions(recipe_id, version_no);
END IF;
END$$;

CREATE TABLE IF NOT EXISTS selemti.recipe_version_items (
  id                BIGSERIAL PRIMARY KEY,
  recipe_version_id BIGINT NOT NULL,
  item_id           BIGINT NOT NULL,
  qty               NUMERIC(14,6) NOT NULL,
  uom_receta        VARCHAR(20) NOT NULL
);

DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_rvi_rv'
) THEN
  CREATE INDEX ix_rvi_rv ON selemti.recipe_version_items(recipe_version_id);
END IF;
END$$;

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

DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_rch_recipe_at'
) THEN
  CREATE INDEX ix_rch_recipe_at ON selemti.recipe_cost_history(recipe_id, snapshot_at);
END IF;
END$$;
SQL);
  }

  public function down(): void
  {
    \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ix_rch_recipe_at");
    \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_cost_history");
    \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ix_rvi_rv");
    \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_version_items");
    \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ux_recipe_version");
    \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.recipe_versions");
  }
};
