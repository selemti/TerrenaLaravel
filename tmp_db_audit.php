<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$tables = DB::select("SELECT table_name FROM information_schema.tables WHERE table_schema = 'selemti' AND table_type = 'BASE TABLE' ORDER BY table_name");

echo "# DICCIONARIO DE DATOS AUTO-GENERADO (selemti)\n\n";

foreach ($tables as $t) {
    echo "### TABLA: selemti.{$t->table_name}\n";
    $cols = DB::select("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = '{$t->table_name}' ORDER BY ordinal_position");
    
    echo "| Columna | Tipo | Null | Default |\n";
    echo "| :--- | :--- | :--- | :--- |\n";
    foreach ($cols as $c) {
        $default = $c->column_default ?: 'NULL';
        echo "| `{$c->column_name}` | `{$c->data_type}` | `{$c->is_nullable}` | `{$default}` |\n";
    }
    echo "\n";
}

echo "## FUNCIONES PL/pgSQL\n";
$procs = DB::select("SELECT proname, prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'selemti'");
foreach ($procs as $p) {
    echo "- **{$p->proname}**\n";
}

echo "\n## TRIGGERS\n";
$triggers = DB::select("SELECT tgname, relname FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'selemti'");
foreach ($triggers as $trg) {
    echo "- **{$trg->tgname}** en tabla **{$trg->relname}**\n";
}
