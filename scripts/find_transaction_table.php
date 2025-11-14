<?php

require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$tables = DB::select("SELECT tablename FROM pg_tables WHERE schemaname='public' AND (tablename LIKE '%trans%' OR tablename LIKE '%ticket%') ORDER BY tablename");
echo "Tablas relacionadas con ticket y transacciones:\n";
foreach ($tables as $t) {
    echo "- {$t->tablename}\n";
}
