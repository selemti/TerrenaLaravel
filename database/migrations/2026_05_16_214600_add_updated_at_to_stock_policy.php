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
        FROM information_schema.tables
        WHERE table_schema = 'selemti'
          AND table_name = 'stock_policy'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'stock_policy'
          AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE selemti.stock_policy
            ADD COLUMN updated_at timestamp without time zone DEFAULT now() NOT NULL;
    END IF;
END $$;
SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'stock_policy'
          AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE selemti.stock_policy DROP COLUMN updated_at;
    END IF;
END $$;
SQL);
    }
};
