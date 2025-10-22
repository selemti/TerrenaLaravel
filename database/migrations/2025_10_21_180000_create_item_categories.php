<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        // 1) Tabla + secuencia + función + trigger (PG 9.5 usa EXECUTE PROCEDURE)
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
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
        FOR EACH ROW EXECUTE PROCEDURE selemti.fn_gen_cat_codigo();
    END IF;
END$$;
SQL);

        // 2) Añadir columna category_id a items (sin IF NOT EXISTS nativo)
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='items' AND column_name='category_id'
) THEN
  ALTER TABLE selemti.items ADD COLUMN category_id BIGINT;
END IF;
END$$;
SQL);

        // 3) FK sólo si no existe (compatible 9.5)
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
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

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::unprepared("ALTER TABLE selemti.items DROP CONSTRAINT IF EXISTS items_category_fk");

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='items' AND column_name='category_id'
) THEN
  ALTER TABLE selemti.items DROP COLUMN category_id;
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared("DROP TRIGGER IF EXISTS trg_item_categories_autocode ON selemti.item_categories");
        \Illuminate\Support\Facades\DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_gen_cat_codigo()");
        \Illuminate\Support\Facades\DB::unprepared("DROP SEQUENCE IF EXISTS selemti.seq_cat_codigo");
        \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.item_categories");
    }
};
