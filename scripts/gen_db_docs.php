<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::statement("SET search_path TO selemti, public");

$schemas = ['public','selemti'];

$tables = DB::select("SELECT table_schema, table_name, table_type FROM information_schema.tables WHERE table_schema IN ('public','selemti') AND table_type='BASE TABLE' ORDER BY table_schema, table_name");
$columns = DB::select("SELECT table_schema, table_name, column_name, data_type, is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale FROM information_schema.columns WHERE table_schema IN ('public','selemti') ORDER BY table_schema, table_name, ordinal_position");
$pks = DB::select(<<<SQL
SELECT kcu.table_schema, kcu.table_name, tco.constraint_name, kcu.column_name, kcu.ordinal_position
FROM information_schema.table_constraints tco
JOIN information_schema.key_column_usage kcu
  ON tco.constraint_name=kcu.constraint_name
 AND tco.table_schema=kcu.table_schema
WHERE tco.constraint_type='PRIMARY KEY' AND kcu.table_schema IN ('public','selemti')
ORDER BY kcu.table_schema, kcu.table_name, kcu.ordinal_position
SQL);
$fks = DB::select(<<<SQL
SELECT tc.table_schema, tc.table_name, tc.constraint_name,
       kcu.column_name,
       ccu.table_schema AS foreign_table_schema,
       ccu.table_name   AS foreign_table_name,
       ccu.column_name  AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema IN ('public','selemti')
ORDER BY tc.table_schema, tc.table_name, tc.constraint_name, kcu.ordinal_position
SQL);
$indexes = DB::select(<<<SQL
SELECT n.nspname  AS schema,
       t.relname  AS table,
       i.relname  AS index,
       ix.indisunique,
       ix.indisprimary,
       pg_get_indexdef(i.oid) AS indexdef
FROM pg_class t
JOIN pg_namespace n ON n.oid = t.relnamespace
JOIN pg_index ix    ON ix.indrelid = t.oid
JOIN pg_class i     ON i.oid = ix.indexrelid
WHERE n.nspname IN ('public','selemti')
ORDER BY n.nspname, t.relname, i.relname
SQL);
$approx = DB::select("SELECT n.nspname AS schema, c.relname AS table, c.reltuples::bigint AS approx_rows FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','selemti') AND c.relkind='r' ORDER BY 1,2");

// Grouping
$byTable = [];
foreach ($tables as $t) { $byTable[$t->table_schema][$t->table_name] = [ 'type'=>$t->table_type ]; }
foreach ($columns as $c) { $byTable[$c->table_schema][$c->table_name]['cols'][] = $c; }
foreach ($pks as $r) { $byTable[$r->table_schema][$r->table_name]['pk'][] = $r->column_name; }
foreach ($fks as $r) { $byTable[$r->table_schema][$r->table_name]['fk'][] = $r; }
foreach ($indexes as $r) { $byTable[$r->schema][$r->table]['idx'][] = $r; }
$approxMap = [];
foreach ($approx as $r) { $approxMap[$r->schema][$r->table] = (int)$r->approx_rows; }

$ts = date('Ymd-His');
$out = __DIR__ . "/../docs/DOC_DB_PUBLIC_Y_SELEMTI-FULL-$ts.md";
$f = fopen($out, 'w');

fwrite($f, "DB — Inventario Completo (public, selemti)\n\n");
fwrite($f, "Fecha: ".date('Y-m-d H:i')."\n\n");

// Summary per schema
foreach ($schemas as $s) {
  $count = isset($byTable[$s]) ? count($byTable[$s]) : 0;
  fwrite($f, "Esquema $s — $count tablas\n");
}

fwrite($f, "\n");

// Per schema list
foreach ($schemas as $schema) {
  fwrite($f, "## Esquema: $schema\n\n");
  if (empty($byTable[$schema])) { fwrite($f, "(sin tablas)\n\n"); continue; }
  foreach ($byTable[$schema] as $table => $info) {
    $rows = $approxMap[$schema][$table] ?? 0;
    fwrite($f, "### $schema.$table (filas aprox: $rows)\n\n");
    fwrite($f, "- Tipo: ".$info['type']."\n");
    fwrite($f, "\n#### Columnas\n");
    foreach ($info['cols'] ?? [] as $c) {
      $type = $c->data_type;
      if ($c->character_maximum_length) { $type .= '('.$c->character_maximum_length.')'; }
      if ($c->numeric_precision) { $type .= '('.$c->numeric_precision.','.(($c->numeric_scale!==null)?$c->numeric_scale:0).')'; }
      fwrite($f, "- {$c->column_name}: $type; nullable=".strtolower($c->is_nullable)."; default=".($c->column_default ?? 'null')."\n");
    }
    fwrite($f, "\n#### PK\n");
    $pk = $info['pk'] ?? [];
    fwrite($f, count($pk)? ('- '.implode(', ', $pk)."\n") : "- N/A\n");

    fwrite($f, "\n#### FKs\n");
    if (!empty($info['fk'])) {
      foreach ($info['fk'] as $fk) {
        fwrite($f, "- {$fk->column_name} ? {$fk->foreign_table_schema}.{$fk->foreign_table_name}({$fk->foreign_column_name})\n");
      }
    } else {
      fwrite($f, "- N/A\n");
    }

    fwrite($f, "\n#### Índices\n");
    if (!empty($info['idx'])) {
      foreach ($info['idx'] as $ix) {
        $u = $ix->indisunique ? 'UNIQUE' : '';
        $p = $ix->indisprimary ? 'PK' : '';
        fwrite($f, "- {$ix->index} ($u $p) — {$ix->indexdef}\n");
      }
    } else {
      fwrite($f, "- N/A\n");
    }

    fwrite($f, "\n");
  }
}

fclose($f);

echo $out, PHP_EOL;

