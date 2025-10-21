<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades.DB;

return new class extends Migration {
  public function up(): void {
    DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.item_vendor_prices (
  id             BIGSERIAL PRIMARY KEY,
  item_id        BIGINT NOT NULL,
  vendor_id      BIGINT NOT NULL,
  price          NUMERIC(14,6) NOT NULL,
  currency_code  VARCHAR(10) DEFAULT 'MXN',
  pack_qty       NUMERIC(14,6) NOT NULL DEFAULT 1,
  pack_uom       VARCHAR(20) NOT NULL,
  notes          TEXT,
  source         VARCHAR(40),
  effective_from TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  effective_to   TIMESTAMP WITHOUT TIME ZONE,
  created_by     BIGINT,
  created_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ivp_item ON selemti.item_vendor_prices(item_id);
CREATE INDEX IF NOT EXISTS ix_ivp_vendor ON selemti.item_vendor_prices(vendor_id);
CREATE INDEX IF NOT EXISTS ix_ivp_validity ON selemti.item_vendor_prices(item_id, effective_from, effective_to);

CREATE OR REPLACE FUNCTION selemti.fn_ivp_upsert_close_prev()
RETURNS trigger AS $$
BEGIN
  UPDATE selemti.item_vendor_prices
     SET effective_to = NEW.effective_from
   WHERE item_id=NEW.item_id
     AND vendor_id=NEW.vendor_id
     AND effective_to IS NULL
     AND effective_from < NEW.effective_from;
  RETURN NEW;
END$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_ivp_close_prev') THEN
    CREATE TRIGGER trg_ivp_close_prev
      BEFORE INSERT ON selemti.item_vendor_prices
      FOR EACH ROW EXECUTE FUNCTION selemti.fn_ivp_upsert_close_prev();
  END IF;
END$$;
SQL);
  }
  public function down(): void {
    DB::unprepared("DROP TRIGGER IF EXISTS trg_ivp_close_prev ON selemti.item_vendor_prices");
    DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_ivp_upsert_close_prev()");
    DB::unprepared("DROP TABLE IF EXISTS selemti.item_vendor_prices");
  }
};
