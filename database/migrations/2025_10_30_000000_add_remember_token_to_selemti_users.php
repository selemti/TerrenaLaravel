<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        DB::statement(<<<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'users'
          AND column_name = 'remember_token'
    ) THEN
        ALTER TABLE selemti.users
        ADD COLUMN remember_token VARCHAR(100);
    END IF;
END;
$$;
SQL);
    }

    public function down(): void
    {
        DB::statement(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'users'
          AND column_name = 'remember_token'
    ) THEN
        ALTER TABLE selemti.users
        DROP COLUMN remember_token;
    END IF;
END;
$$;
SQL);
    }
};
