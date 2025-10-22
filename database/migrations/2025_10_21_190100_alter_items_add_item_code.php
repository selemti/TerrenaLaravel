<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        // Columna item_code (compatible 9.5)
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='items' AND column_name='item_code'
) THEN
  ALTER TABLE selemti.items ADD COLUMN item_code VARCHAR(32);
END IF;
END$$;
SQL);

        // Índice único con chequeo manual (por compatibilidad)
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
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

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.ux_items_item_code");
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='items' AND column_name='item_code'
) THEN
  ALTER TABLE selemti.items DROP COLUMN item_code;
END IF;
END$$;
SQL);
    }
};
