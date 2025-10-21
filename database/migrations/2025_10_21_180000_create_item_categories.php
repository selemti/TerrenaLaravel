<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.item_categories (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    slug        VARCHAR(160) UNIQUE,
    codigo      VARCHAR(16) UNIQUE,
    descripcion TEXT,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    prefijo     VARCHAR(10),
    created_at  TIMESTAMP(0),
    updated_at  TIMESTAMP(0)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname='seq_cat_codigo') THEN
        CREATE SEQUENCE selemti.seq_cat_codigo START 1;
    END IF;
END$$;

CREATE OR REPLACE FUNCTION selemti.fn_gen_cat_codigo()
RETURNS trigger AS $$
BEGIN
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        NEW.codigo := 'CAT-' || lpad(nextval('selemti.seq_cat_codigo')::text, 4, '0');
    END IF;
    RETURN NEW;
END$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_item_categories_autocode') THEN
        CREATE TRIGGER trg_item_categories_autocode
        BEFORE INSERT ON selemti.item_categories
        FOR EACH ROW EXECUTE FUNCTION selemti.fn_gen_cat_codigo();
    END IF;
END$$;
SQL);
        DB::unprepared(<<<'SQL'
ALTER TABLE selemti.items
    ADD COLUMN IF NOT EXISTS category_id BIGINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema='selemti'
          AND table_name='items'
          AND constraint_name='items_category_fk'
    ) THEN
        ALTER TABLE selemti.items
        ADD CONSTRAINT items_category_fk
        FOREIGN KEY (category_id)
        REFERENCES selemti.item_categories(id)
        ON UPDATE CASCADE ON DELETE SET NULL;
    END IF;
END$$;
SQL);
    }
    public function down(): void {
        DB::unprepared("ALTER TABLE selemti.items DROP CONSTRAINT IF EXISTS items_category_fk");
        DB::unprepared("ALTER TABLE selemti.items DROP COLUMN IF EXISTS category_id");
        DB::unprepared("DROP TRIGGER IF EXISTS trg_item_categories_autocode ON selemti.item_categories");
        DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_gen_cat_codigo()");
        DB::unprepared("DROP SEQUENCE IF EXISTS selemti.seq_cat_codigo");
        DB::unprepared("DROP TABLE IF EXISTS selemti.item_categories");
    }
};
