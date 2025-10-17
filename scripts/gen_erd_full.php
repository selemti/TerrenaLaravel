<?php
use Illuminate\Support\Facades\DB;

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::statement("SET search_path TO selemti, public");

// Get all FKs for both schemas
$fks = DB::select(<<<SQL
SELECT
  tc.table_schema      AS child_schema,
  tc.table_name        AS child_table,
  kcu.column_name      AS child_column,
  ccu.table_schema     AS parent_schema,
  ccu.table_name       AS parent_table,
  ccu.column_name      AS parent_column,
  tc.constraint_name   AS constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema IN ('public','selemti')
ORDER BY tc.table_schema, tc.table_name, kcu.ordinal_position
SQL);

// Collect tables per schema
$tables = DB::select(<<<SQL
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('public','selemti') AND table_type='BASE TABLE'
ORDER BY table_schema, table_name
SQL);

$bySchemaTables = [];
foreach ($tables as $t) {
  $bySchemaTables[$t->table_schema][] = $t->table_name;
}

// Group FKs per schema (child schema)
$perSchema = [ 'public'=>[], 'selemti'=>[] ];
foreach ($fks as $fk) {
  $perSchema[$fk->child_schema][] = $fk;
}

$ts = date('Ymd-His');
$out = __DIR__ . "/../docs/DOC_ERD-FULL-$ts.md";
$f = fopen($out, 'w');

fwrite($f, "ERD Completo — public y selemti (Mermaid)\n\n");
fwrite($f, "Fecha: ".date('Y-m-d H:i')."\n\n");

// Helper to emit a schema section
$emitSchema = function($schema) use ($f, $bySchemaTables, $perSchema) {
  fwrite($f, "## Esquema: $schema\n\n");
  // Optional: listar entidades
  $list = $bySchemaTables[$schema] ?? [];
  if (!empty($list)) {
    fwrite($f, "Tablas ($schema): ".implode(', ', $list)."\n\n");
  }
  fwrite($f, "```mermaid\n");
  fwrite($f, "erDiagram\n");
  foreach ($perSchema[$schema] ?? [] as $fk) {
    // child many-to-one parent
    $child  = strtoupper($fk->child_table);
    $parent = strtoupper($fk->parent_table);
    $label  = $fk->child_column.' -> '.$fk->parent_column;
    fwrite($f, "  $child }o--|| $parent : \"$label\"\n");
  }
  fwrite($f, "```\n\n");
};

// Sections per schema
$emitSchema('selemti');
$emitSchema('public');

// Global cross-schema (if any)
$cross = array_filter($fks, function($fk){ return $fk->child_schema !== $fk->parent_schema; });
if (!empty($cross)) {
  fwrite($f, "## Global (Cross-schema)\n\n");
  fwrite($f, "```mermaid\n");
  fwrite($f, "flowchart LR\n");
  foreach ($cross as $fk) {
    $child  = $fk->child_schema.'.'.$fk->child_table;
    $parent = $fk->parent_schema.'.'.$fk->parent_table;
    $label  = $fk->child_column.' -> '.$fk->parent_column;
    fwrite($f, "  \"$child\" -->|$label| \"$parent\"\n");
  }
  fwrite($f, "```\n\n");
}

fclose($f);
echo $out, PHP_EOL;
