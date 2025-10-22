<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.item_category_counters (
    category_id BIGINT PRIMARY KEY,
    last_val    BIGINT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMP(0)
);

CREATE OR REPLACE FUNCTION selemti.fn_assign_item_code()
RETURNS trigger AS $$
DECLARE
    v_prefijo text;
    v_next    bigint;
BEGIN
    IF NEW.category_id IS NULL THEN
        RETURN NEW;
    END IF;
    IF NEW.item_code IS NOT NULL AND NEW.item_code <> '' THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(NULLIF(TRIM(prefijo),''), 'C') INTO v_prefijo
    FROM selemti.item_categories WHERE id=NEW.category_id;

    INSERT INTO selemti.item_category_counters(category_id,last_val,updated_at)
    VALUES (NEW.category_id,1,now())
    ON CONFLICT(category_id) DO UPDATE
        SET last_val = selemti.item_category_counters.last_val + 1,
            updated_at = now()
    RETURNING last_val INTO v_next;

    NEW.item_code := v_prefijo || '-' || lpad(v_next::text,5,'0');
    RETURN NEW;
END$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_items_assign_code') THEN
        CREATE TRIGGER trg_items_assign_code
        BEFORE INSERT ON selemti.items
        FOR EACH ROW EXECUTE PROCEDURE selemti.fn_assign_item_code();
    END IF;
END$$;
SQL);
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::unprepared("DROP TRIGGER IF EXISTS trg_items_assign_code ON selemti.items");
        \Illuminate\Support\Facades\DB::unprepared("DROP FUNCTION IF EXISTS selemti.fn_assign_item_code()");
        \Illuminate\Support\Facades\DB::unprepared("DROP TABLE IF EXISTS selemti.item_category_counters");
    }
};
