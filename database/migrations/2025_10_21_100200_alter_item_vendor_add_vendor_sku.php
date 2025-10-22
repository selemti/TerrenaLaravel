<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        // === COLUMNS ===
        foreach ([
            ['vendor_sku','VARCHAR(120)'],
            ['vendor_descripcion','VARCHAR(255)'],
            ['currency_code','VARCHAR(10)'],
            ['lead_time_days','INTEGER'],
            ['min_order_qty','NUMERIC(14,6)'],
            ['pack_qty','NUMERIC(14,6)'],
            ['pack_uom','VARCHAR(20)'],
        ] as [$col, $type]) {
            \Illuminate\Support\Facades\DB::unprepared("
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='item_vendor' AND column_name='{$col}'
) THEN
  ALTER TABLE selemti.item_vendor ADD COLUMN {$col} {$type};
END IF;
END$$;");
        }

        // === INDEXES ===
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_itemvendor_vendor_sku'
) THEN
  CREATE INDEX ix_itemvendor_vendor_sku ON selemti.item_vendor(vendor_id, vendor_sku);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_itemvendor_preferente'
) THEN
  CREATE INDEX ix_itemvendor_preferente ON selemti.item_vendor(preferente);
END IF;
END$$;
SQL);
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ix_itemvendor_vendor_sku");
        \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ix_itemvendor_preferente");

        foreach ([
            'vendor_sku','vendor_descripcion','currency_code','lead_time_days',
            'min_order_qty','pack_qty','pack_uom'
        ] as $col) {
            \Illuminate\Support\Facades\DB::unprepared("
DO $$
BEGIN
IF EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='item_vendor' AND column_name='{$col}'
) THEN
  ALTER TABLE selemti.item_vendor DROP COLUMN {$col};
END IF;
END$$;");
        }
    }
};
