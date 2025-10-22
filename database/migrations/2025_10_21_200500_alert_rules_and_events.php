<?php

return new class extends \Illuminate\Database\Migrations\Migration {
  public function up(): void
  {
    \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.alert_rules (
  id            BIGSERIAL PRIMARY KEY,
  recipe_id     BIGINT,
  category_id   BIGINT,
  threshold_pct NUMERIC(6,2) NOT NULL DEFAULT 10.0,
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  notes         TEXT
);

CREATE TABLE IF NOT EXISTS selemti.alert_events (
  id               BIGSERIAL PRIMARY KEY,
  recipe_id        BIGINT NOT NULL,
  snapshot_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  old_portion_cost NUMERIC(14,6),
  new_portion_cost NUMERIC(14,6),
  delta_pct        NUMERIC(8,4),
  created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  handled          BOOLEAN NOT NULL DEFAULT FALSE
);

DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_alert_events_recipe'
) THEN
  CREATE INDEX ix_alert_events_recipe ON selemti.alert_events(recipe_id, created_at);
END IF;
END$$;
SQL);
  }

  public function down(): void
  {
    \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ix_alert_events_recipe");
    \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.alert_events");
    \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.alert_rules");
  }
};
