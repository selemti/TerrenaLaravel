<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$targets = [
  ['schema'=>'selemti','table'=>'sesion_cajon'],
  ['schema'=>'selemti','table'=>'precorte'],
  ['schema'=>'selemti','table'=>'precorte_efectivo'],
  ['schema'=>'selemti','table'=>'precorte_otros'],
  ['schema'=>'selemti','table'=>'postcorte'],
  ['schema'=>'public','table'=>'ticket'],
];

function q($sql,$params=[]){ return DB::select($sql,$params); }

DB::statement("SET search_path TO selemti, public");

foreach ($targets as $t) {
  $schema = $t['schema']; $table = $t['table'];
  echo "# {$schema}.{$table}\n\n";
  $cols = q("SELECT column_name, data_type, is_nullable, column_default, numeric_precision, numeric_scale, character_maximum_length FROM information_schema.columns WHERE table_schema=? AND table_name=? ORDER BY ordinal_position", [$schema,$table]);
  echo "## Columnas\n";
  foreach ($cols as $c) {
    $type = $c->data_type;
    if ($c->character_maximum_length) { $type .= '(' . $c->character_maximum_length . ')'; }
    if ($c->numeric_precision) { $type .= '(' . $c->numeric_precision . ',' . ($c->numeric_scale ?? 0) . ')'; }
    echo "- {$c->column_name}: {$type}; nullable=" . strtolower($c->is_nullable) . "; default=" . ($c->column_default ?? 'null') . "\n";
  }
  $pks = q("SELECT kcu.column_name FROM information_schema.table_constraints tco JOIN information_schema.key_column_usage kcu ON tco.constraint_name=kcu.constraint_name AND tco.table_schema=kcu.table_schema WHERE tco.constraint_type='PRIMARY KEY' AND tco.table_schema=? AND tco.table_name=? ORDER BY kcu.ordinal_position", [$schema,$table]);
  $pkcols = array_map(fn($r)=>$r->column_name, $pks);
  echo "\n## PK\n- " . (empty($pkcols)?'N/A':implode(', ',$pkcols)) . "\n";
  $fks = q("SELECT kcu.column_name, ccu.table_schema AS foreign_schema, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name=tc.constraint_name AND ccu.constraint_schema=tc.table_schema WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema=? AND tc.table_name=? ORDER BY kcu.ordinal_position", [$schema,$table]);
  echo "\n## FKs\n";
  if (!$fks) echo "- N/A\n"; else foreach ($fks as $fk) { echo "- {$fk->column_name} ? {$fk->foreign_schema}.{$fk->foreign_table}({$fk->foreign_column})\n"; }
  $idx = q("SELECT i.relname AS index_name, ix.indisunique, ix.indisprimary, pg_get_indexdef(i.oid) AS indexdef FROM pg_class t JOIN pg_namespace n ON n.oid=t.relnamespace JOIN pg_index ix ON ix.indrelid=t.oid JOIN pg_class i ON i.oid=ix.indexrelid WHERE n.nspname=? AND t.relname=? ORDER BY i.relname", [$schema,$table]);
  echo "\n## Índices\n";
  if (!$idx) echo "- N/A\n"; else foreach ($idx as $r) { $u=$r->indisunique?'UNIQUE':' '; $p=$r->indisprimary?'PK':' '; echo "- {$r->index_name} ({$u}{$p}) — {$r->indexdef}\n"; }
  echo "\n";
}
