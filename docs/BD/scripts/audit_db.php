<?php

/**
 * Auditoría exhaustiva de base de datos PostgreSQL
 * Identifica tablas duplicadas y legacy
 */

// Conexión a PostgreSQL
$conn = pg_connect('host=localhost port=5433 dbname=pos user=postgres password=urmikz');

if (! $conn) {
    exit('Error de conexión: '.pg_last_error());
}

echo "=== AUDITORÍA DE BASE DE DATOS PostgreSQL ===\n";
echo 'Fecha: '.date('Y-m-d H:i:s')."\n\n";

// 1. Obtener todas las tablas de selemti
$query_selemti = "
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname = 'selemti'
    ORDER BY tablename;
";

// 2. Obtener todas las tablas de public
$query_public = "
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename;
";

echo "=== TABLAS EN SCHEMA SELEMTI ===\n";
$result_selemti = pg_query($conn, $query_selemti);
$selemti_tables = [];
while ($row = pg_fetch_assoc($result_selemti)) {
    $selemti_tables[] = $row['tablename'];
    echo "- selemti.{$row['tablename']}\n";
}
echo "\nTotal tablas selemti: ".count($selemti_tables)."\n\n";

echo "=== TABLAS EN SCHEMA PUBLIC ===\n";
$result_public = pg_query($conn, $query_public);
$public_tables = [];
while ($row = pg_fetch_assoc($result_public)) {
    $public_tables[] = $row['tablename'];
    echo "- public.{$row['tablename']}\n";
}
echo "\nTotal tablas public: ".count($public_tables)."\n\n";

echo 'TOTAL TABLAS: '.(count($selemti_tables) + count($public_tables))."\n\n";

// 3. Contar registros en cada tabla y obtener estructura
echo "=== ANÁLISIS DETALLADO DE TABLAS SELEMTI ===\n\n";

$analysis = [];

foreach ($selemti_tables as $table) {
    // Contar registros
    $count_query = "SELECT COUNT(*) as total FROM selemti.\"$table\"";
    $count_result = pg_query($conn, $count_query);
    $count = pg_fetch_assoc($count_result)['total'];

    // Obtener columnas
    $columns_query = "
        SELECT column_name, data_type, character_maximum_length, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'selemti' AND table_name = '$table'
        ORDER BY ordinal_position;
    ";
    $columns_result = pg_query($conn, $columns_query);
    $columns = [];
    while ($col = pg_fetch_assoc($columns_result)) {
        $columns[] = $col;
    }

    // Obtener FKs
    $fk_query = "
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'selemti'
            AND tc.table_name = '$table';
    ";
    $fk_result = pg_query($conn, $fk_query);
    $fks = [];
    while ($fk = pg_fetch_assoc($fk_result)) {
        $fks[] = $fk;
    }

    $analysis[$table] = [
        'schema' => 'selemti',
        'count' => $count,
        'columns' => $columns,
        'fks' => $fks,
    ];

    echo "Tabla: selemti.$table\n";
    echo "  Registros: $count\n";
    echo '  Columnas ('.count($columns)."):\n";
    foreach ($columns as $col) {
        echo "    - {$col['column_name']} ({$col['data_type']})";
        if ($col['character_maximum_length']) {
            echo "({$col['character_maximum_length']})";
        }
        echo "\n";
    }
    if (count($fks) > 0) {
        echo "  Foreign Keys:\n";
        foreach ($fks as $fk) {
            echo "    - {$fk['column_name']} -> {$fk['foreign_table_schema']}.{$fk['foreign_table_name']}({$fk['foreign_column_name']})\n";
        }
    }
    echo "\n";
}

// 4. Análisis de tablas public (solo conteo y columnas principales)
echo "\n=== ANÁLISIS DETALLADO DE TABLAS PUBLIC (Floreant POS) ===\n\n";

foreach ($public_tables as $table) {
    // Contar registros
    $count_query = "SELECT COUNT(*) as total FROM public.\"$table\"";
    $count_result = pg_query($conn, $count_query);
    $count = pg_fetch_assoc($count_result)['total'];

    // Obtener solo nombres de columnas
    $columns_query = "
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = '$table'
        ORDER BY ordinal_position;
    ";
    $columns_result = pg_query($conn, $columns_query);
    $columns = [];
    while ($col = pg_fetch_assoc($columns_result)) {
        $columns[] = $col['column_name'];
    }

    echo "Tabla: public.$table\n";
    echo "  Registros: $count\n";
    echo '  Columnas: '.implode(', ', $columns)."\n\n";
}

// 5. Identificar duplicados potenciales
echo "\n=== IDENTIFICACIÓN DE TABLAS DUPLICADAS ===\n\n";

// Patrones de duplicación
$duplicate_groups = [
    'users' => ['public.users', 'selemti.users', 'selemti.usuario'],
    'roles' => ['selemti.rol', 'selemti.roles'],
    'sucursales' => ['selemti.sucursal', 'selemti.cat_sucursales'],
    'almacenes' => ['selemti.almacen', 'selemti.cat_almacenes'],
    'proveedores' => ['selemti.proveedor', 'selemti.cat_proveedores'],
    'unidades' => [
        'selemti.unidad_medida_legacy',
        'selemti.unidades_medida_legacy',
        'selemti.cat_unidades',
        'selemti.uom',
        'selemti.unit_of_measure',
    ],
    'conversiones' => [
        'selemti.conversion_unidad',
        'selemti.conversiones_unidad_legacy',
        'selemti.uom_conversion_legacy',
        'selemti.uom_conversions',
    ],
    'recetas' => ['selemti.receta', 'selemti.receta_cab'],
    'caja_chica' => [
        'selemti.caja_fondo',
        'selemti.cash_funds',
        'selemti.caja_chica',
    ],
];

foreach ($duplicate_groups as $group_name => $tables) {
    echo "GRUPO: $group_name\n";
    foreach ($tables as $table_full) {
        [$schema, $table] = explode('.', $table_full);

        // Verificar si existe
        if (($schema === 'selemti' && in_array($table, $selemti_tables)) ||
            ($schema === 'public' && in_array($table, $public_tables))) {

            $count_query = "SELECT COUNT(*) as total FROM $schema.\"$table\"";
            $count_result = pg_query($conn, $count_query);
            $count = pg_fetch_assoc($count_result)['total'];

            echo "  ✓ $table_full - $count registros\n";
        } else {
            echo "  ✗ $table_full - NO EXISTE\n";
        }
    }
    echo "\n";
}

// 6. Tablas con sufijo _legacy
echo "\n=== TABLAS CON SUFIJO _legacy ===\n\n";
foreach ($selemti_tables as $table) {
    if (strpos($table, '_legacy') !== false) {
        $count_query = "SELECT COUNT(*) as total FROM selemti.\"$table\"";
        $count_result = pg_query($conn, $count_query);
        $count = pg_fetch_assoc($count_result)['total'];

        echo "- selemti.$table - $count registros\n";
    }
}

pg_close($conn);

echo "\n=== AUDITORÍA COMPLETADA ===\n";
