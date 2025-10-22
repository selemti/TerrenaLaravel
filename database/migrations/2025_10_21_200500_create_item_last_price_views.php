<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        DB::unprepared(<<<'SQL'
CREATE OR REPLACE VIEW selemti.vw_item_last_price AS
WITH last_price AS (
  SELECT
    ivp.item_id,
    ivp.vendor_id,
    ivp.price,
    ivp.pack_qty,
    ivp.pack_uom,
    ivp.effective_from,
    ROW_NUMBER() OVER (PARTITION BY ivp.item_id, ivp.vendor_id ORDER BY ivp.effective_from DESC) AS rn
  FROM selemti.item_vendor_prices ivp
  WHERE ivp.effective_to IS NULL
)
SELECT lp.item_id, lp.vendor_id, lp.price, lp.pack_qty, lp.pack_uom, lp.effective_from
FROM last_price lp
WHERE lp.rn = 1;
SQL);

        DB::unprepared(<<<'SQL'
CREATE OR REPLACE VIEW selemti.vw_item_last_price_pref AS
SELECT i.id AS item_id,
       pv.vendor_id,
       lp.price,
       lp.pack_qty,
       lp.pack_uom,
       lp.effective_from
FROM selemti.items i
LEFT JOIN selemti.item_vendor pv
  ON pv.item_id = i.id AND COALESCE(pv.preferente, false) = true
LEFT JOIN selemti.vw_item_last_price lp
  ON lp.item_id = i.id AND lp.vendor_id = pv.vendor_id;
SQL);
    }

    public function down(): void
    {
        DB::unprepared('DROP VIEW IF EXISTS selemti.vw_item_last_price_pref;');
        DB::unprepared('DROP VIEW IF EXISTS selemti.vw_item_last_price;');
    }
};
