<?php
/**
 * Script para inventariar objetos en esquema public para integración POS
 */

require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "INVENTARIO DE OBJETOS EN ESQUEMA PUBLIC\n";
echo "========================================\n\n";

try {
    // 1. Listar vistas en public
    echo "VISTAS EN ESQUEMA PUBLIC:\n";
    echo "-------------------------\n";
    
    $views = DB::select("
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
        ORDER BY table_name
    ");
    
    foreach ($views as $view) {
        echo "- {$view->table_name}\n";
    }
    
    echo "\nFUNCIONES/PROCEDIMIENTOS EN ESQUEMA PUBLIC:\n";
    echo "-------------------------------------------\n";
    
    $functions = DB::select("
        SELECT routine_name, routine_type
        FROM information_schema.routines
        WHERE specific_schema = 'public'
        ORDER BY routine_name
    ");
    
    foreach ($functions as $function) {
        echo "- {$function->routine_type}: {$function->routine_name}\n";
    }
    
    echo "\nTRIGGERS EN ESQUEMA PUBLIC:\n";
    echo "----------------------------\n";
    
    $triggers = DB::select("
        SELECT tg.tgname, c.relname AS table_name
        FROM pg_trigger tg
        JOIN pg_class c ON tg.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public'
        AND NOT tg.tgisinternal
        ORDER BY tg.tgname
    ");
    
    foreach ($triggers as $trigger) {
        echo "- Trigger: {$trigger->tgname} (en tabla: {$trigger->table_name})\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}