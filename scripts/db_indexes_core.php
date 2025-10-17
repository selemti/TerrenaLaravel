<?php
use Illuminate\Support\Facades\DB;

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

header('Content-Type: application/json');

$targets = [
    ['schema'=>'selemti','table'=>'sesion_cajon'],
    ['schema'=>'selemti','table'=>'precorte'],
    ['schema'=>'selemti','table'=>'precorte_efectivo'],
    ['schema'=>'selemti','table'=>'precorte_otros'],
    ['schema'=>'selemti','table'=>'postcorte'],
    ['schema'=>'public', 'table'=>'ticket'],
];

try {
    DB::statement("SET search_path TO selemti, public");

    $out = [];
    foreach ($targets as $t) {
        $rows = DB::select(<<<SQL
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
            WHERE n.nspname = ? AND t.relname = ?
            ORDER BY i.relname
        SQL, [$t['schema'],$t['table']]);
        $out[$t['schema'].'.'.$t['table']] = $rows;
    }

    echo json_encode(['ok'=>true,'indexes'=>$out], JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE);
    exit(0);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'error'=>$e->getMessage()]);
    exit(1);
}

