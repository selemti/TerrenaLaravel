<?php
use Illuminate\Support\Facades\DB;
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
try {
    DB::statement("SET search_path TO selemti, public");
    $ver = DB::selectOne('select version()');
    $spath = DB::selectOne('show search_path');
    echo json_encode([
        'ok'=>true,
        'version'=>$ver->version ?? null,
        'search_path'=>$spath->search_path ?? null,
    ], JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT), PHP_EOL;
} catch (Throwable $e) {
    echo json_encode(['ok'=>false,'error'=>$e->getMessage()]), PHP_EOL;
}
