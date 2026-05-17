<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'stock_policy'
          AND column_name = 'max_qty'
          AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE selemti.stock_policy
            ALTER COLUMN max_qty DROP NOT NULL,
            ALTER COLUMN max_qty DROP DEFAULT;
    END IF;
END $$;
SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
UPDATE selemti.stock_policy
SET max_qty = 0
WHERE max_qty IS NULL;

ALTER TABLE selemti.stock_policy
    ALTER COLUMN max_qty SET DEFAULT 0,
    ALTER COLUMN max_qty SET NOT NULL;
SQL);
    }
};
