<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
ALTER TABLE selemti.items
  ADD COLUMN IF NOT EXISTS item_code VARCHAR(32);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ux_items_item_code'
    ) THEN
        CREATE UNIQUE INDEX ux_items_item_code ON selemti.items(item_code);
    END IF;
END$$;
SQL);
    }
    public function down(): void {
        DB::unprepared("DROP INDEX IF EXISTS selemti.ux_items_item_code");
        DB::unprepared("ALTER TABLE selemti.items DROP COLUMN IF EXISTS item_code");
    }
};
