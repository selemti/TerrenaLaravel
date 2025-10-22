<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
WITH base AS (
  SELECT i.id, i.category_id, c.prefijo,
         ROW_NUMBER() OVER (PARTITION BY i.category_id ORDER BY i.id) AS rn
  FROM selemti.items i
  JOIN selemti.item_categories c ON c.id = i.category_id
  WHERE (i.item_code IS NULL OR i.item_code = '')
),
tops AS (
  SELECT category_id, MAX(rn) AS maxrn FROM base GROUP BY category_id
),
seed AS (
  INSERT INTO selemti.item_category_counters(category_id,last_val,updated_at)
  SELECT t.category_id, t.maxrn, now()
  FROM tops t
  ON CONFLICT (category_id) DO NOTHING
  RETURNING category_id
)
UPDATE selemti.items i
SET item_code = b.prefijo || '-' || lpad(b.rn::text,5,'0')
FROM base b
WHERE i.id = b.id;
SQL);
    }

    public function down(): void {/* sin reversa de códigos asignados */}
};
