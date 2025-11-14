<?php
require __DIR__ . '/../../vendor/autoload.php';

$app = require_once __DIR__ . '/../../bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Extrayendo información de la base de datos selemti...\n\n";

// 1. TABLAS
echo "1. Extrayendo tablas...\n";
$tables = DB::select("
    SELECT table_name, table_type 
    FROM information_schema.tables 
    WHERE table_schema = 'selemti' 
    ORDER BY table_name
");

$fp = fopen(__DIR__ . '/selemti_tables.csv', 'w');
fputcsv($fp, ['table_name', 'table_type'], '|');
foreach($tables as $t) {
    fputcsv($fp, [(string)$t->table_name, (string)$t->table_type], '|');
}
fclose($fp);
echo "   ✓ " . count($tables) . " tablas exportadas\n";

// 2. VISTAS
echo "2. Extrayendo vistas...\n";
$views = DB::select("
    SELECT table_name as view_name 
    FROM information_schema.views 
    WHERE table_schema = 'selemti' 
    ORDER BY table_name
");

$fp = fopen(__DIR__ . '/selemti_views.csv', 'w');
fputcsv($fp, ['view_name'], '|');
foreach($views as $v) {
    fputcsv($fp, [(string)$v->view_name], '|');
}
fclose($fp);
echo "   ✓ " . count($views) . " vistas exportadas\n";

// 3. FUNCIONES Y PROCEDIMIENTOS
echo "3. Extrayendo funciones y procedimientos...\n";
$routines = DB::select("
    SELECT routine_name, routine_type, data_type as return_type
    FROM information_schema.routines 
    WHERE routine_schema = 'selemti' 
    ORDER BY routine_type, routine_name
");

$fp = fopen(__DIR__ . '/selemti_routines.csv', 'w');
fputcsv($fp, ['routine_name', 'routine_type', 'return_type'], '|');
foreach($routines as $r) {
    fputcsv($fp, [(string)$r->routine_name, (string)$r->routine_type, (string)($r->return_type ?? 'void')], '|');
}
fclose($fp);
echo "   ✓ " . count($routines) . " rutinas exportadas\n";

// 4. FOREIGN KEYS
echo "4. Extrayendo foreign keys...\n";
$fks = DB::select("
    SELECT 
        tc.table_name,
        kcu.column_name,
        tc.constraint_name,
        ccu.table_name AS referenced_table_name,
        ccu.column_name AS referenced_column_name
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_schema = 'selemti'
    ORDER BY tc.table_name, kcu.column_name
");

$fp = fopen(__DIR__ . '/selemti_foreignkeys.csv', 'w');
fputcsv($fp, ['table_name', 'column_name', 'constraint_name', 'referenced_table_name', 'referenced_column_name'], '|');
foreach($fks as $fk) {
    fputcsv($fp, [
        (string)$fk->table_name, 
        (string)$fk->column_name, 
        (string)$fk->constraint_name,
        (string)$fk->referenced_table_name,
        (string)$fk->referenced_column_name
    ], '|');
}
fclose($fp);
echo "   ✓ " . count($fks) . " foreign keys exportadas\n";

// 5. TRIGGERS
echo "5. Extrayendo triggers...\n";
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

$fp = fopen(__DIR__ . '/selemti_triggers.csv', 'w');
fputcsv($fp, ['trigger_name', 'event_manipulation', 'event_object_table', 'action_timing'], '|');
foreach($triggers as $tr) {
    fputcsv($fp, [
        (string)$tr->trigger_name, 
        (string)$tr->event_manipulation, 
        (string)$tr->event_object_table,
        (string)$tr->action_timing
    ], '|');
}
fclose($fp);
echo "   ✓ " . count($triggers) . " triggers exportados\n";

// 6. COLUMNAS (solo tablas principales - primeras 50)
echo "6. Extrayendo columnas (muestra)...\n";
$columns = DB::select("
    SELECT 
        c.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        CASE 
            WHEN tc.constraint_type = 'PRIMARY KEY' THEN 'PRI'
            WHEN tc.constraint_type = 'UNIQUE' THEN 'UNI'
            ELSE ''
        END as column_key
    FROM information_schema.columns c
    LEFT JOIN information_schema.key_column_usage kcu 
        ON c.table_name = kcu.table_name 
        AND c.column_name = kcu.column_name
        AND c.table_schema = kcu.table_schema
    LEFT JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE c.table_schema = 'selemti'
        AND c.table_name IN (
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'selemti' AND table_type = 'BASE TABLE'
            ORDER BY table_name LIMIT 50
        )
    ORDER BY c.table_name, c.ordinal_position
");

$fp = fopen(__DIR__ . '/selemti_columns.csv', 'w');
fputcsv($fp, ['table_name', 'column_name', 'data_type', 'is_nullable', 'column_default', 'column_key'], '|');
foreach($columns as $col) {
    fputcsv($fp, [
        (string)$col->table_name, 
        (string)$col->column_name, 
        (string)$col->data_type,
        (string)$col->is_nullable,
        (string)($col->column_default ?? ''),
        (string)($col->column_key ?? '')
    ], '|');
}
fclose($fp);
echo "   ✓ " . count($columns) . " columnas exportadas\n";

echo "\n✅ Extracción completada!\n";
echo "Archivos generados en: " . __DIR__ . "/\n";
