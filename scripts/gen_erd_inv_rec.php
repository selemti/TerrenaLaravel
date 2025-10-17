<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

DB::statement("SET search_path TO selemti, public");

$filters = [
  'receta_%', 'unidades_%', 'stock_policy', 'proveedor', 'presentacion%', 'conversion%', 'uom%', 'sucursal%', 'almacen%'
];
$likeList = implode(' OR ', array_map(fn($p)=>"tc.table_name LIKE '".$p."'", $filters));

$fks = DB::select(<<<SQL
SELECT tc.table_schema AS child_schema, tc.table_name AS child_table,
       kcu.column_name AS child_column,
       ccu.table_schema AS parent_schema, ccu.table_name AS parent_table,
       ccu.column_name AS parent_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name=tc.constraint_name AND ccu.constraint_schema=tc.table_schema
WHERE tc.constraint_type='FOREIGN KEY'
  AND tc.table_schema IN ('public','selemti')
  AND ($likeList OR ccu.table_name LIKE 'receta_%' OR ccu.table_name LIKE 'unidades_%' OR ccu.table_name IN ('stock_policy','proveedor'))
ORDER BY tc.table_schema, tc.table_name, kcu.ordinal_position
SQL);

$ts = date('Ymd-His');
$out = __DIR__ . "/../docs/DOC_ERD_INVENTARIO_RECETAS-$ts.md";
$f = fopen($out, 'w');

fwrite($f, "ERD — Inventario y Recetas (Filtrado)\n\n");
fwrite($f, "Fecha: ".date('Y-m-d H:i')."\n\n");

fwrite($f, "```mermaid\n");
fwrite($f, "erDiagram\n");
foreach ($fks as $fk) {
  $child = strtoupper($fk->child_table);
  $parent = strtoupper($fk->parent_table);
  $label = $fk->child_column.' -> '.$fk->parent_column;
  fwrite($f, "  $child }o--|| $parent : \"$label\"\n");
}
fwrite($f, "```\n");

fclose($f);
echo $out, PHP_EOL;
