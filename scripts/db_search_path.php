<?php
// Session-only search_path set and verification (read-only aside from session GUC)
// Usage: php scripts/db_search_path.php

use Illuminate\Support\Facades\DB;

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

try {
    $before = DB::selectOne('SHOW search_path');
    fwrite(STDOUT, "BEFORE search_path: " . ($before->search_path ?? '') . PHP_EOL);

    DB::statement('SET search_path TO selemti, public');

    $after = DB::selectOne('SHOW search_path');
    fwrite(STDOUT, "AFTER  search_path: " . ($after->search_path ?? '') . PHP_EOL);
    exit(0);
} catch (Throwable $e) {
    fwrite(STDERR, '[ERROR] ' . $e->getMessage() . PHP_EOL);
    exit(1);
}

