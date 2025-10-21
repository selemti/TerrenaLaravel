<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades.DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
INSERT INTO selemti.item_categories (nombre, slug, codigo, created_at, updated_at)
SELECT DISTINCT
       NULLIF(TRIM(categoria_id),'') AS nombre,
       lower(regexp_replace(NULLIF(TRIM(categoria_id),''), '\s+', '-', 'g')) AS slug,
       NULLIF(TRIM(categoria_id),'') AS codigo,
       now(), now()
FROM selemti.items
WHERE categoria_id IS NOT NULL AND TRIM(categoria_id) <> ''
  AND NOT EXISTS (
       SELECT 1 FROM selemti.item_categories c WHERE c.codigo = selemti.items.categoria_id
  );
SQL);

        DB::unprepared(<<<'SQL'
UPDATE selemti.items i
SET category_id = c.id
FROM selemti.item_categories c
WHERE i.categoria_id IS NOT NULL
  AND i.categoria_id = c.codigo
  AND (i.category_id IS NULL OR i.category_id <> c.id);
SQL);
    }
    public function down(): void {
        DB::unprepared("UPDATE selemti.items SET category_id = NULL");
    }
};
