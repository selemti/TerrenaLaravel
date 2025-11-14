<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Extrayendo información de BD...\n";

// 1. Tablas
echo "1. Tablas... ";
$tables = DB::select("
    SELECT table_name, table_type 
    FROM information_schema.tables 
    WHERE table_schema = 'selemti' 
    ORDER BY table_name
");
file_put_contents('BD/audit/selemti_tables.csv', "table_name|table_type\n");
foreach($tables as $t) {
    file_put_contents('BD/audit/selemti_tables.csv', "{$t->table_name}|{$t->table_type}\n", FILE_APPEND);
}
echo count($tables) . " OK\n";

// 2. Vistas
echo "2. Vistas... ";
$views = DB::select("
    SELECT table_name as view_name 
    FROM information_schema.views 
    WHERE table_schema = 'selemti' 
    ORDER BY table_name
");
file_put_contents('BD/audit/selemti_views.csv', "view_name\n");
foreach($views as $v) {
    file_put_contents('BD/audit/selemti_views.csv', "{$v->view_name}\n", FILE_APPEND);
}
echo count($views) . " OK\n";

// 3. Funciones y procedimientos
echo "3. Funciones/procedimientos... ";
$routines = DB::select("
    SELECT routine_name, routine_type, data_type as return_type
    FROM information_schema.routines 
    WHERE routine_schema = 'selemti' 
    ORDER BY routine_type, routine_name
");
file_put_contents('BD/audit/selemti_routines.csv', "routine_name|routine_type|return_type\n");
foreach($routines as $r) {
    $return = $r->return_type ?? 'void';
    file_put_contents('BD/audit/selemti_routines.csv', "{$r->routine_name}|{$r->routine_type}|{$return}\n", FILE_APPEND);
}
echo count($routines) . " OK\n";

// 4. Foreign keys
echo "4. Foreign keys... ";
$fks = DB::select("
    SELECT 
        table_name,
        column_name,
        constraint_name,
        referenced_table_name,
        referenced_column_name
    FROM information_schema.key_column_usage
    WHERE table_schema = 'selemti' 
        AND referenced_table_name IS NOT NULL
    ORDER BY table_name, column_name
");
file_put_contents('BD/audit/selemti_foreignkeys.csv', "table_name|column_name|constraint_name|referenced_table_name|referenced_column_name\n");
foreach($fks as $fk) {
    file_put_contents('BD/audit/selemti_foreignkeys.csv', "{$fk->table_name}|{$fk->column_name}|{$fk->constraint_name}|{$fk->referenced_table_name}|{$fk->referenced_column_name}\n", FILE_APPEND);
}
echo count($fks) . " OK\n";

// 5. Triggers
echo "5. Triggers... ";
$triggers = DB::select("
    SELECT 
        trigger_name,
        event_manipulation,
        event_object_table,
        action_timing
    FROM information_schema.triggers
    WHERE trigger_schema = 'selemti'
    ORDER BY event_object_table, trigger_name
");
file_put_contents('BD/audit/selemti_triggers.csv', "trigger_name|event_manipulation|event_object_table|action_timing\n");
foreach($triggers as $tr) {
    file_put_contents('BD/audit/selemti_triggers.csv', "{$tr->trigger_name}|{$tr->event_manipulation}|{$tr->event_object_table}|{$tr->action_timing}\n", FILE_APPEND);
}
echo count($triggers) . " OK\n";

// 6. Columnas (solo tablas BASE, limitar a primeras 50 tablas)
echo "6. Columnas (muestra)... ";
$columns = DB::select("
    SELECT 
        t.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        c.character_maximum_length
    FROM information_schema.tables t
    JOIN information_schema.columns c 
        ON t.table_name = c.table_name 
        AND t.table_schema = c.table_schema
    WHERE t.table_schema = 'selemti'
        AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name, c.ordinal_position
    LIMIT 500
");
file_put_contents('BD/audit/selemti_columns_sample.csv', "table_name|column_name|data_type|is_nullable|column_default|max_length\n");
foreach($columns as $col) {
    $default = str_replace(["\n", "\r", "|"], " ", $col->column_default ?? '');
    $maxlen = $col->character_maximum_length ?? '';
    file_put_contents('BD/audit/selemti_columns_sample.csv', "{$col->table_name}|{$col->column_name}|{$col->data_type}|{$col->is_nullable}|{$default}|{$maxlen}\n", FILE_APPEND);
}
echo count($columns) . " OK\n";

echo "\n✅ Extracción completada. Archivos en BD/audit/\n";
