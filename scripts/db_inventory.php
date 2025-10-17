<?php
// Read-only DB inventory for schemas public and selemti
// Outputs a single JSON with tables, columns, pks, fks, indexes

use Illuminate\Support\Facades\DB;

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

header('Content-Type: application/json');

try {
    // Session-only search_path
    DB::statement("SET search_path TO selemti, public");

    $schemas = ['public','selemti'];

    $tables = DB::select(<<<SQL
        SELECT table_schema, table_name, table_type
        FROM information_schema.tables
        WHERE table_schema IN ('public','selemti')
        ORDER BY table_schema, table_name
    SQL);

    $columns = DB::select(<<<SQL
        SELECT table_schema, table_name, column_name, data_type,
               is_nullable, column_default, character_maximum_length,
               numeric_precision, numeric_scale
        FROM information_schema.columns
        WHERE table_schema IN ('public','selemti')
        ORDER BY table_schema, table_name, ordinal_position
    SQL);

    $pks = DB::select(<<<SQL
        SELECT kcu.table_schema, kcu.table_name, tco.constraint_name,
               kcu.column_name, kcu.ordinal_position
        FROM information_schema.table_constraints tco
        JOIN information_schema.key_column_usage kcu
          ON tco.constraint_name = kcu.constraint_name
         AND tco.constraint_schema = kcu.constraint_schema
         AND tco.table_schema = kcu.table_schema
        WHERE tco.constraint_type = 'PRIMARY KEY'
          AND kcu.table_schema IN ('public','selemti')
        ORDER BY kcu.table_schema, kcu.table_name, tco.constraint_name, kcu.ordinal_position
    SQL);

    $fks = DB::select(<<<SQL
        SELECT tc.table_schema, tc.table_name, tc.constraint_name,
               kcu.column_name,
               ccu.table_schema AS foreign_table_schema,
               ccu.table_name   AS foreign_table_name,
               ccu.column_name  AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
         AND ccu.constraint_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema IN ('public','selemti')
        ORDER BY tc.table_schema, tc.table_name, tc.constraint_name, kcu.ordinal_position
    SQL);

    $indexes = DB::select(<<<SQL
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
        WHERE n.nspname IN ('public','selemti')
        ORDER BY n.nspname, t.relname, i.relname
    SQL);

    $approx = DB::select(<<<SQL
        SELECT n.nspname AS schema, c.relname AS table, c.reltuples::bigint AS approx_rows
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname IN ('public','selemti') AND c.relkind='r'
        ORDER BY n.nspname, c.relname
    SQL);

    echo json_encode([
        'ok' => true,
        'tables'  => $tables,
        'columns' => $columns,
        'pks'     => $pks,
        'fks'     => $fks,
        'indexes' => $indexes,
        'approx_rows' => $approx, // estimaciones; no es COUNT(*)
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit(0);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'error'=>$e->getMessage()]);
    exit(1);
}

