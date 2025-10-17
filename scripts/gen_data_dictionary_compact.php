<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::statement("SET search_path TO selemti, public");
$spath = DB::selectOne('SHOW search_path');

$schemas = ["public","selemti"];

$tables = DB::select("SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema IN ('public','selemti') AND table_type='BASE TABLE' ORDER BY table_schema, table_name");
$columns = DB::select("SELECT table_schema, table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema IN ('public','selemti') ORDER BY table_schema, table_name, ordinal_position");
$pks = DB::select(<<<SQL
SELECT kcu.table_schema, kcu.table_name, kcu.column_name, kcu.ordinal_position
FROM information_schema.table_constraints tco
JOIN information_schema.key_column_usage kcu
  ON tco.constraint_name=kcu.constraint_name AND tco.table_schema=kcu.table_schema
WHERE tco.constraint_type='PRIMARY KEY' AND kcu.table_schema IN ('public','selemti')
ORDER BY kcu.table_schema, kcu.table_name, kcu.ordinal_position
SQL);
$fks = DB::select(<<<SQL
SELECT tc.table_schema, tc.table_name, kcu.column_name,
       ccu.table_schema AS foreign_table_schema, ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name=tc.constraint_name AND ccu.constraint_schema=tc.table_schema
WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema IN ('public','selemti')
ORDER BY tc.table_schema, tc.table_name, kcu.ordinal_position
SQL);
$approx = DB::select("SELECT n.nspname AS schema, c.relname AS table, c.reltuples::bigint AS approx_rows FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','selemti') AND c.relkind='r' ORDER BY 1,2");

$byTable = [];
foreach ($tables as $t) { $byTable[$t->table_schema][$t->table_name] = []; }
foreach ($columns as $c) { $byTable[$c->table_schema][$c->table_name]['cols'][] = $c; }
foreach ($pks as $r) { $byTable[$r->table_schema][$r->table_name]['pk'][] = $r->column_name; }
foreach ($fks as $r) { $byTable[$r->table_schema][$r->table_name]['fk'][] = $r; }
$approxMap = [];
foreach ($approx as $r) { $approxMap[$r->schema][$r->table] = (int)$r->approx_rows; }

$ts = date('Ymd-HHmm');
$outPublic = __DIR__ . "/../docs/DATA_DICTIONARY_COMPACT_PUBLIC-$ts.md";
$outSelemti= __DIR__ . "/../docs/DATA_DICTIONARY_COMPACT_SELEMTI-$ts.md";

function writeSchemaCompact($schema, $path, $byTable, $approxMap, $spath) {
  $f = fopen($path, 'w');
  fwrite($f, "Data Dictionary (Compact) — $schema\n\n");
  fwrite($f, "Fecha: ".date('Y-m-d H:i')."\n\n");
  fwrite($f, "search_path sesión: ".($spath->search_path ?? '')."\n\n");
  foreach (($byTable[$schema] ?? []) as $table => $info) {
    $rows = $approxMap[$schema][$table] ?? 0;
    $cols = $info['cols'] ?? [];
    $pk   = $info['pk'] ?? [];
    $fks  = $info['fk'] ?? [];
    // flags
    $hasTimestamps = in_array('created_at', array_map(fn($x)=>$x->column_name, $cols)) || in_array('updated_at', array_map(fn($x)=>$x->column_name, $cols));
    $flags = [];
    if (!$hasTimestamps) $flags[] = 'sin_timestamps';
    fwrite($f, "## $schema.$table — ~ $rows filas\n\n");
    if (!empty($flags)) fwrite($f, "- Flags: ".implode(', ', $flags)."\n\n");
    fwrite($f, "- PK: ".(empty($pk)?'N/A':implode(', ', $pk))."\n");
    fwrite($f, "- FKs: ".(empty($fks)?'N/A':(string)count($fks))."\n");
    fwrite($f, "- Columnas (nombre: tipo, null)\n");
    foreach ($cols as $c) {
      fwrite($f, "  - {$c->column_name}: {$c->data_type}, ".strtolower($c->is_nullable)."\n");
    }
    // Listar FKs resumidas
    if (!empty($fks)) {
      fwrite($f, "- FKs detalle\n");
      foreach ($fks as $fk) {
        fwrite($f, "  - {$fk->column_name} ? {$fk->foreign_table_schema}.{$fk->foreign_table_name}\n");
      }
    }
    fwrite($f, "\n");
  }
  fclose($f);
}

writeSchemaCompact('public', $outPublic, $byTable, $approxMap, $spath);
writeSchemaCompact('selemti', $outSelemti, $byTable, $approxMap, $spath);

echo $outPublic, PHP_EOL, $outSelemti, PHP_EOL;
?>
