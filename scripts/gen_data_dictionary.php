<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::statement("SET search_path TO selemti, public");
$spath = DB::selectOne('SHOW search_path');

$schemas = ["public","selemti"];

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
SELECT tc.table_schema, tc.table_name, tc.constraint_name, kcu.column_name,
       ccu.table_schema AS foreign_table_schema, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema IN ('public','selemti')
ORDER BY tc.table_schema, tc.table_name, tc.constraint_name, kcu.ordinal_position
SQL);
$uniques = DB::select(<<<SQL
SELECT tc.table_schema, tc.table_name, tc.constraint_name, string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema
WHERE tc.constraint_type='UNIQUE' AND tc.table_schema IN ('public','selemti')
GROUP BY tc.table_schema, tc.table_name, tc.constraint_name
ORDER BY tc.table_schema, tc.table_name
SQL);
$checks = DB::select(<<<SQL
SELECT n.nspname AS table_schema, c.relname AS table_name, con.conname AS constraint_name, pg_get_constraintdef(con.oid, true) AS definition
FROM pg_constraint con
JOIN pg_class c ON c.oid=con.conrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE con.contype='c' AND n.nspname IN ('public','selemti')
ORDER BY n.nspname, c.relname, con.conname
SQL);
$indexes = DB::select(<<<SQL
SELECT n.nspname AS schema, t.relname AS table, i.relname AS index,
       ix.indisunique, ix.indisprimary,
       array_agg(a.attname ORDER BY k.ord) AS cols,
       pg_get_indexdef(i.oid) AS indexdef
FROM pg_class t
JOIN pg_namespace n ON n.oid=t.relnamespace
JOIN pg_index ix ON ix.indrelid=t.oid
JOIN pg_class i ON i.oid=ix.indexrelid
JOIN unnest(ix.indkey) WITH ORDINALITY AS k(attnum, ord) ON TRUE
JOIN pg_attribute a ON a.attrelid=t.oid AND a.attnum=k.attnum
WHERE n.nspname IN ('public','selemti')
GROUP BY n.nspname, t.relname, i.relname, ix.indisunique, ix.indisprimary, i.oid
ORDER BY n.nspname, t.relname, i.relname
SQL);
$approx = DB::select("SELECT n.nspname AS schema, c.relname AS table, c.reltuples::bigint AS approx_rows FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','selemti') AND c.relkind='r' ORDER BY 1,2");
$sequences = DB::select(<<<SQL
SELECT n.nspname AS schema, t.relname AS table, a.attname AS column,
       pg_get_serial_sequence(quote_ident(n.nspname)||'.'||quote_ident(t.relname), a.attname) AS sequence
FROM pg_class t
JOIN pg_namespace n ON n.oid=t.relnamespace
JOIN pg_attribute a ON a.attrelid=t.oid AND a.attnum>0 AND NOT a.attisdropped
WHERE n.nspname IN ('public','selemti')
ORDER BY n.nspname, t.relname, a.attname
SQL);

// Map data
$byTable = [];
foreach ($tables as $t) { $byTable[$t->table_schema][$t->table_name] = ['type'=>$t->table_type]; }
foreach ($columns as $c) { $byTable[$c->table_schema][$c->table_name]['cols'][] = $c; }
foreach ($pks as $r) { $byTable[$r->table_schema][$r->table_name]['pk'][] = $r->column_name; }
foreach ($fks as $r) { $byTable[$r->table_schema][$r->table_name]['fk'][] = $r; }
foreach ($uniques as $u) { $byTable[$u->table_schema][$u->table_name]['uq'][] = $u; }
foreach ($checks as $ck) { $byTable[$ck->table_schema][$ck->table_name]['ck'][] = $ck; }
$idxMap = [];
foreach ($indexes as $ix) { $idxMap[$ix->schema][$ix->table][] = $ix; }
$approxMap = [];
foreach ($approx as $r) { $approxMap[$r->schema][$r->table] = (int)$r->approx_rows; }
$seqMap = [];
foreach ($sequences as $s) { if ($s->sequence) $seqMap[$s->schema][$s->table][$s->column] = $s->sequence; }

// Helper: flag missing FK index
function hasIndexForFk($schema, $table, $col, $idxMap) {
  if (!isset($idxMap[$schema][$table])) return false;
  foreach ($idxMap[$schema][$table] as $ix) {
    $cols = $ix->cols ?? [];
    if (!is_array($cols)) continue;
    if (isset($cols[0]) && $cols[0] === $col) return true; // starts with FK column
  }
  return false;
}

$ts = date('Ymd-His');
$out = __DIR__ . "/../docs/DATA_DICTIONARY-".date('Ymd-HHmm').".md";
$f = fopen($out, 'w');

fwrite($f, "Data Dictionary — public y selemti\n\n");
fwrite($f, "Fecha: ".date('Y-m-d H:i')."\n\n");
fwrite($f, "search_path sesión: ".($spath->search_path ?? '')."\n\n");

foreach ($schemas as $schema) {
  fwrite($f, "# Esquema: $schema\n\n");
  if (empty($byTable[$schema])) { fwrite($f, "(sin tablas)\n\n"); continue; }
  foreach ($byTable[$schema] as $table => $info) {
    $rows = $approxMap[$schema][$table] ?? 0;
    fwrite($f, "## $schema.$table — filas aprox: $rows\n\n");
    fwrite($f, "- Tipo: ".($info['type'] ?? 'BASE TABLE')."\n\n");
    fwrite($f, "### Campos\n");
    foreach ($info['cols'] ?? [] as $c) {
      $type = $c->data_type;
      if ($c->character_maximum_length) { $type .= '('.$c->character_maximum_length.')'; }
      if ($c->numeric_precision) { $type .= '('.$c->numeric_precision.','.(($c->numeric_scale!==null)?$c->numeric_scale:0).')'; }
      fwrite($f, "- {$c->column_name}: $type; nullable=".strtolower($c->is_nullable)."; default=".($c->column_default ?? 'null')."\n");
    }
    fwrite($f, "\n### PK\n");
    $pk = $info['pk'] ?? [];
    fwrite($f, count($pk)? ('- '.implode(', ', $pk)."\n") : "- N/A\n");

    fwrite($f, "\n### FKs\n");
    if (!empty($info['fk'])) {
      foreach ($info['fk'] as $fk) {
        $flag = hasIndexForFk($schema, $table, $fk->column_name, $idxMap) ? '' : ' [FALTA ÍNDICE]';
        fwrite($f, "- {$fk->column_name} ? {$fk->foreign_table_schema}.{$fk->foreign_table_name}({$fk->foreign_column_name})$flag\n");
      }
    } else { fwrite($f, "- N/A\n"); }

    fwrite($f, "\n### Índices\n");
    if (!empty($idxMap[$schema][$table])) {
      foreach ($idxMap[$schema][$table] as $ix) {
        $u = $ix->indisunique ? 'UNIQUE' : '';
        $p = $ix->indisprimary ? 'PK' : '';
        $cols = is_array($ix->cols) ? implode(', ', $ix->cols) : '';
        fwrite($f, "- {$ix->index} ($u $p) — ($cols) — {$ix->indexdef}\n");
      }
    } else { fwrite($f, "- N/A\n"); }

    fwrite($f, "\n### Únicas\n");
    if (!empty($info['uq'])) {
      foreach ($info['uq'] as $u) { fwrite($f, "- {$u->constraint_name} — [{$u->columns}]\n"); }
    } else { fwrite($f, "- N/A\n"); }

    fwrite($f, "\n### Checks\n");
    if (!empty($info['ck'])) {
      foreach ($info['ck'] as $ck) { fwrite($f, "- {$ck->constraint_name}: {$ck->definition}\n"); }
    } else { fwrite($f, "- N/A\n"); }

    fwrite($f, "\n### Secuencias\n");
    if (!empty($seqMap[$schema][$table])) {
      foreach ($seqMap[$schema][$table] as $col=>$seq) { fwrite($f, "- $col ? $seq\n"); }
    } else { fwrite($f, "- N/A\n"); }

    // Flags rápidos
    $flags = [];
    // monetarios no uniformes (double precision en lugar de numeric)
    foreach (($info['cols'] ?? []) as $c) {
      if (strtolower($c->column_name) !== 'id' && $c->data_type === 'double precision') { $flags['monetario_no_uniforme'] = true; }
    }
    // timestamps ausentes (si no tiene created_at/updated_at)
    $colnames = array_map(fn($x)=>$x->column_name, $info['cols'] ?? []);
    if (!in_array('created_at',$colnames) && !in_array('updated_at',$colnames)) { $flags['sin_timestamps'] = true; }

    if (!empty($flags)) {
      fwrite($f, "\n### Flags\n");
      foreach ($flags as $k=>$_) { fwrite($f, "- $k\n"); }
    }

    fwrite($f, "\n");
  }
}

// ERDs
// Per schema
foreach ($schemas as $schema) {
  fwrite($f, "# ERD $schema\n\n");
  fwrite($f, "```mermaid\n");
  fwrite($f, "erDiagram\n");
  foreach ($fks as $fk) {
    if ($fk->table_schema !== $schema) continue;
    $child  = strtoupper($fk->table_name);
    $parent = strtoupper($fk->foreign_table_name);
    $label  = $fk->column_name.' -> '.$fk->foreign_column_name;
    fwrite($f, "  $child }o--|| $parent : \"$label\"\n");
  }
  fwrite($f, "```\n\n");
}

// Global de caja/ventas/pagos/movimientos (basado en nombres conocidos)
$known = [
  'selemti.sesion_cajon','selemti.precorte','selemti.precorte_efectivo','selemti.precorte_otros','selemti.postcorte','public.ticket'
];
fwrite($f, "# ERD Global (caja/ventas/pagos/movimientos)\n\n");
fwrite($f, "```mermaid\n");
fwrite($f, "flowchart LR\n");
foreach ($fks as $fk) {
  $child = $fk->table_schema.'.'.$fk->table_name;
  $parent = $fk->foreign_table_schema.'.'.$fk->foreign_table_name;
  if (!in_array($child,$known) && !in_array($parent,$known)) continue;
  $label = $fk->column_name.' -> '.$fk->foreign_column_name;
  fwrite($f, "  \"$child\" -->|$label| \"$parent\"\n");
}
fwrite($f, "```\n");

fclose($f);
echo $out, PHP_EOL;
