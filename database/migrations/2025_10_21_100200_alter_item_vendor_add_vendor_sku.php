<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
ALTER TABLE selemti.item_vendor
  ADD COLUMN IF NOT EXISTS vendor_sku           VARCHAR(120),
  ADD COLUMN IF NOT EXISTS vendor_descripcion   VARCHAR(255),
  ADD COLUMN IF NOT EXISTS currency_code        VARCHAR(10),
  ADD COLUMN IF NOT EXISTS lead_time_days       INTEGER,
  ADD COLUMN IF NOT EXISTS min_order_qty        NUMERIC(14,6),
  ADD COLUMN IF NOT EXISTS pack_qty             NUMERIC(14,6),
  ADD COLUMN IF NOT EXISTS pack_uom             VARCHAR(20);
CREATE INDEX IF NOT EXISTS ix_itemvendor_vendor_sku ON selemti.item_vendor(vendor_id, vendor_sku);
CREATE INDEX IF NOT EXISTS ix_itemvendor_preferente ON selemti.item_vendor(preferente);
SQL);
    }
    public function down(): void {
        DB::unprepared(<<<'SQL'
DROP INDEX IF EXISTS selemti.ix_itemvendor_vendor_sku;
DROP INDEX IF EXISTS selemti.ix_itemvendor_preferente;
ALTER TABLE selemti.item_vendor
  DROP COLUMN IF EXISTS vendor_sku,
  DROP COLUMN IF EXISTS vendor_descripcion,
  DROP COLUMN IF EXISTS currency_code,
  DROP COLUMN IF EXISTS lead_time_days,
  DROP COLUMN IF EXISTS min_order_qty,
  DROP COLUMN IF EXISTS pack_qty,
  DROP COLUMN IF EXISTS pack_uom;
SQL);
    }
};
