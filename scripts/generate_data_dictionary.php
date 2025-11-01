<?php

declare(strict_types=1);

$rootPath = realpath(__DIR__ . '/..');
if ($rootPath === false) {
    fwrite(STDERR, "No se pudo resolver la ruta raíz del proyecto.\n");
    exit(1);
}

require $rootPath . '/vendor/autoload.php';

if (class_exists(Dotenv\Dotenv::class) && file_exists($rootPath . '/.env')) {
    Dotenv\Dotenv::createImmutable($rootPath)->safeLoad();
}

$env = static function (string $key, ?string $default = null): ?string {
    $value = $_ENV[$key] ?? $_SERVER[$key] ?? getenv($key);

    if ($value === false || $value === null) {
        return $default;
    }

    $value = (string) $value;

    return $value !== '' ? $value : $default;
};

$schemas = ['selemti', 'public'];

try {
    $host = $env('DB_HOST', '127.0.0.1');
    $port = $env('DB_PORT', '5433');
    $database = $env('DB_DATABASE', 'pos');
    $username = $env('DB_USERNAME', 'postgres');
    $password = $env('DB_PASSWORD', '');

    $password = trim($password, "\"'");

    $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $host, $port, $database);
    $pdo = new PDO(
        $dsn,
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
    $pdo->exec('SET search_path TO selemti, public');
} catch (Throwable $exception) {
    fwrite(STDERR, "No se pudo conectar a PostgreSQL: " . $exception->getMessage() . "\n");
    exit(1);
}

$schemaList = implode(',', array_map(static fn ($value) => $pdo->quote($value), $schemas));

$tables = [];
$tableSql = <<<SQL
select
    t.table_schema,
    t.table_name,
    obj_description(c.oid) as description,
    c.reltuples::bigint as row_estimate
from information_schema.tables t
join pg_class c on c.oid = (quote_ident(t.table_schema) || '.' || quote_ident(t.table_name))::regclass
where t.table_type in ('BASE TABLE', 'PARTITIONED TABLE')
  and t.table_schema in (%s)
order by t.table_schema, t.table_name
SQL;
$tableSql = sprintf($tableSql, $schemaList);
$tableRows = $pdo->query($tableSql)->fetchAll();

foreach ($tableRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    $tables[$key] = [
        'schema' => $row['table_schema'],
        'name' => $row['table_name'],
        'description' => $row['description'] ?: null,
        'row_estimate' => $row['row_estimate'] !== null ? (int) round((float) $row['row_estimate']) : null,
        'columns' => [],
        'primary_key' => null,
        'foreign_keys' => [],
        'unique_constraints' => [],
        'check_constraints' => [],
        'indexes' => [],
        'flags' => [
            'faltan_indices_fk' => false,
            'campos_monetarios_no_uniformes' => false,
            'sin_timestamps' => false,
        ],
    ];
}

$columnSql = <<<SQL
select
    c.table_schema,
    c.table_name,
    c.column_name,
    c.ordinal_position,
    c.data_type,
    c.is_nullable,
    c.column_default,
    c.identity_generation,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.datetime_precision,
    pgd.description as comment
from information_schema.columns c
join pg_class cls on cls.oid = (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass
join pg_attribute att on att.attrelid = cls.oid and att.attname = c.column_name
left join pg_description pgd on pgd.objoid = cls.oid and pgd.objsubid = att.attnum
where c.table_schema in (%s)
order by c.table_schema, c.table_name, c.ordinal_position
SQL;
$columnSql = sprintf($columnSql, $schemaList);
$columnRows = $pdo->query($columnSql)->fetchAll();

foreach ($columnRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }

    $columnDefault = $row['column_default'];
    $sequenceName = null;
    if ($columnDefault !== null) {
        if (preg_match("/nextval\\('([^']+)'::regclass\\)/", $columnDefault, $matches)) {
            $sequenceName = $matches[1];
        }
    }

    $formattedType = $row['data_type'];
    if ($row['character_maximum_length'] !== null) {
        $formattedType .= '(' . $row['character_maximum_length'] . ')';
    } elseif ($row['numeric_precision'] !== null) {
        $formattedType .= '(' . $row['numeric_precision'];
        if ($row['numeric_scale'] !== null) {
            $formattedType .= ',' . $row['numeric_scale'];
        }
        $formattedType .= ')';
    } elseif ($row['datetime_precision'] !== null && stripos($row['data_type'], 'timestamp') !== false) {
        $formattedType .= '(' . $row['datetime_precision'] . ')';
    }

    $tables[$key]['columns'][] = [
        'name' => $row['column_name'],
        'type' => $formattedType,
        'raw_type' => $row['data_type'],
        'is_nullable' => $row['is_nullable'] === 'YES',
        'default' => $columnDefault,
        'identity' => $row['identity_generation'] ?: null,
        'sequence' => $sequenceName,
        'comment' => $row['comment'] ?: null,
    ];
}

$pkSql = <<<SQL
select
    nsp.nspname as table_schema,
    tbl.relname as table_name,
    con.conname,
    json_agg(att.attname order by ord.ordinality) as columns
from pg_constraint con
join pg_class tbl on tbl.oid = con.conrelid
join pg_namespace nsp on nsp.oid = tbl.relnamespace
join lateral generate_subscripts(con.conkey, 1) as ord(ordinality) on true
left join pg_attribute att on att.attrelid = con.conrelid and att.attnum = con.conkey[ord.ordinality]
where con.contype = 'p'
  and nsp.nspname in (%s)
group by nsp.nspname, tbl.relname, con.conname
SQL;
$pkSql = sprintf($pkSql, $schemaList);
$pkRows = $pdo->query($pkSql)->fetchAll();

$decodeJsonArray = static function ($value): array {
    if ($value === null || $value === '') {
        return [];
    }

    $decoded = json_decode((string) $value, true);
    if (!is_array($decoded)) {
        return [];
    }

    $filtered = array_filter(
        $decoded,
        static fn ($item) => $item !== null && $item !== '' && $item !== false
    );

    return array_values($filtered);
};

foreach ($pkRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }
    $tables[$key]['primary_key'] = [
        'name' => $row['conname'],
        'columns' => $decodeJsonArray($row['columns']),
    ];
}

$uniqueSql = <<<SQL
select
    nsp.nspname as table_schema,
    tbl.relname as table_name,
    con.conname,
    json_agg(att.attname order by ord.ordinality) as columns
from pg_constraint con
join pg_class tbl on tbl.oid = con.conrelid
join pg_namespace nsp on nsp.oid = tbl.relnamespace
join lateral generate_subscripts(con.conkey, 1) as ord(ordinality) on true
left join pg_attribute att on att.attrelid = con.conrelid and att.attnum = con.conkey[ord.ordinality]
where con.contype = 'u'
  and nsp.nspname in (%s)
group by nsp.nspname, tbl.relname, con.conname
SQL;
$uniqueSql = sprintf($uniqueSql, $schemaList);
$uniqueRows = $pdo->query($uniqueSql)->fetchAll();

foreach ($uniqueRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }
    $tables[$key]['unique_constraints'][] = [
        'name' => $row['conname'],
        'columns' => $decodeJsonArray($row['columns']),
    ];
}

$checkSql = <<<SQL
select
    nsp.nspname as table_schema,
    tbl.relname as table_name,
    con.conname,
    pg_get_constraintdef(con.oid, true) as definition
from pg_constraint con
join pg_class tbl on tbl.oid = con.conrelid
join pg_namespace nsp on nsp.oid = tbl.relnamespace
where con.contype = 'c'
  and nsp.nspname in (%s)
order by nsp.nspname, tbl.relname, con.conname
SQL;
$checkSql = sprintf($checkSql, $schemaList);
$checkRows = $pdo->query($checkSql)->fetchAll();

foreach ($checkRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }
    $tables[$key]['check_constraints'][] = [
        'name' => $row['conname'],
        'definition' => $row['definition'],
    ];
}

$fkSql = <<<SQL
select
    nsp.nspname as table_schema,
    tbl.relname as table_name,
    con.conname,
    nsf.nspname as foreign_schema,
    ftbl.relname as foreign_table,
    json_agg(src_att.attname order by ord.ordinality) as columns,
    json_agg(dest_att.attname order by ord.ordinality) as foreign_columns,
    pg_get_constraintdef(con.oid, true) as definition,
    con.confdeltype,
    con.confupdtype,
    con.confmatchtype
from pg_constraint con
join pg_class tbl on tbl.oid = con.conrelid
join pg_namespace nsp on nsp.oid = tbl.relnamespace
join pg_class ftbl on ftbl.oid = con.confrelid
join pg_namespace nsf on nsf.oid = ftbl.relnamespace
join lateral generate_subscripts(con.conkey, 1) as ord(ordinality) on true
left join pg_attribute src_att on src_att.attrelid = con.conrelid and src_att.attnum = con.conkey[ord.ordinality]
left join pg_attribute dest_att on dest_att.attrelid = con.confrelid and dest_att.attnum = con.confkey[ord.ordinality]
where con.contype = 'f'
  and nsp.nspname in (%s)
group by nsp.nspname, tbl.relname, con.conname, nsf.nspname, ftbl.relname, con.confdeltype, con.confupdtype, con.confmatchtype, con.oid
order by nsp.nspname, tbl.relname, con.conname
SQL;
$fkSql = sprintf($fkSql, $schemaList);
$fkRows = $pdo->query($fkSql)->fetchAll();

foreach ($fkRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }
    $tables[$key]['foreign_keys'][] = [
        'name' => $row['conname'],
        'columns' => $decodeJsonArray($row['columns']),
        'referenced_table' => $row['foreign_schema'] . '.' . $row['foreign_table'],
        'referenced_columns' => $decodeJsonArray($row['foreign_columns']),
        'definition' => $row['definition'],
        'on_delete' => $row['confdeltype'],
        'on_update' => $row['confupdtype'],
        'match_type' => $row['confmatchtype'],
    ];
}

$indexSql = <<<SQL
select
    nsp.nspname as table_schema,
    tbl.relname as table_name,
    idx.relname as index_name,
    am.amname as method,
    ix.indisunique,
    ix.indisprimary,
    ix.indisvalid,
    pg_get_expr(ix.indpred, ix.indrelid) as predicate,
    pg_get_indexdef(ix.indexrelid) as definition,
    json_agg(
        case
            when att.attname is not null then att.attname
            else pg_get_indexdef(ix.indexrelid, ord.ordinality::int, true)
        end
        order by ord.ordinality
    ) as columns
from pg_index ix
join pg_class tbl on tbl.oid = ix.indrelid
join pg_namespace nsp on nsp.oid = tbl.relnamespace
join pg_class idx on idx.oid = ix.indexrelid
join pg_am am on am.oid = idx.relam
left join lateral unnest(ix.indkey) with ordinality as ord(attnum, ordinality) on true
left join pg_attribute att on att.attrelid = tbl.oid and att.attnum = ord.attnum
where nsp.nspname in (%s)
group by nsp.nspname, tbl.relname, idx.relname, am.amname, ix.indisunique, ix.indisprimary, ix.indisvalid, ix.indpred, ix.indexrelid, ix.indrelid
order by nsp.nspname, tbl.relname, idx.relname
SQL;
$indexSql = sprintf($indexSql, $schemaList);
$indexRows = $pdo->query($indexSql)->fetchAll();

foreach ($indexRows as $row) {
    $key = $row['table_schema'] . '.' . $row['table_name'];
    if (!isset($tables[$key])) {
        continue;
    }
    $tables[$key]['indexes'][] = [
        'name' => $row['index_name'],
        'columns' => $decodeJsonArray($row['columns']),
        'is_unique' => (bool) $row['indisunique'],
        'is_primary' => (bool) $row['indisprimary'],
        'is_valid' => (bool) $row['indisvalid'],
        'is_partial' => $row['predicate'] !== null && $row['predicate'] !== '',
        'method' => $row['method'],
        'predicate' => $row['predicate'] ?: null,
        'definition' => $row['definition'],
    ];
}

foreach ($tables as $key => &$table) {
    $hasCreatedAt = false;
    $hasUpdatedAt = false;
    $monetaryTypes = [];
    $monetaryKeywords = ['monto', 'importe', 'total', 'subtotal', 'precio', 'costo', 'pago', 'pagos', 'saldo', 'valor', 'abono', 'cargo', 'venta'];

    foreach ($table['columns'] as $column) {
        $nameLower = strtolower($column['name']);
        if ($nameLower === 'created_at') {
            $hasCreatedAt = true;
        } elseif ($nameLower === 'updated_at') {
            $hasUpdatedAt = true;
        }

        $matchesKeyword = false;
        foreach ($monetaryKeywords as $keyword) {
            if (str_contains($nameLower, $keyword)) {
                $matchesKeyword = true;
                break;
            }
        }

        $monetaryTypesCandidates = ['numeric', 'decimal', 'money', 'double precision', 'real', 'integer', 'bigint', 'smallint'];
        if ($matchesKeyword || in_array(strtolower($column['raw_type']), $monetaryTypesCandidates, true)) {
            $monetaryTypes[strtolower($column['raw_type'])] = true;
        }
    }

    if (!($hasCreatedAt && $hasUpdatedAt)) {
        $table['flags']['sin_timestamps'] = true;
    }

    if (count($monetaryTypes) > 1) {
        $table['flags']['campos_monetarios_no_uniformes'] = true;
    }

    $table['flags']['faltan_indices_fk'] = false;
    $fkWithoutIndex = [];

    foreach ($table['foreign_keys'] as $fk) {
        $fkColumns = $fk['columns'] ?? [];
        if (!$fkColumns) {
            continue;
        }

        $hasSupportingIndex = false;
        foreach ($table['indexes'] as $index) {
            if (!$index['columns']) {
                continue;
            }

            $indexCols = $index['columns'];
            $prefix = array_slice($indexCols, 0, count($fkColumns));
            if ($prefix === $fkColumns) {
                $hasSupportingIndex = true;
                break;
            }
        }

        if (!$hasSupportingIndex) {
            $fkWithoutIndex[] = $fk['name'];
        }
    }

    if ($fkWithoutIndex) {
        $table['flags']['faltan_indices_fk'] = true;
        $table['fk_missing_indexes'] = $fkWithoutIndex;
    } else {
        $table['fk_missing_indexes'] = [];
    }
}
unset($table);

ksort($tables);

$bySchema = [];
foreach ($tables as $table) {
    $bySchema[$table['schema']][] = $table;
}

$date = (new DateTimeImmutable('now'))->format('Y-m-d');
$outputPath = $rootPath . '/docs/DATA_DICTIONARY-' . $date . '.md';

$lines = [];
$lines[] = '# Diccionario de Datos';
$lines[] = '';
$lines[] = '- Fecha de generación: ' . $date;
$lines[] = '- Esquemas analizados: ' . implode(', ', $schemas);
$lines[] = '- Search path: selemti, public';
$lines[] = '';

foreach ($bySchema as $schema => $tablesInSchema) {
    $lines[] = '## Diagrama ER - esquema ' . $schema;
    $lines[] = '```mermaid';
    $lines[] = 'erDiagram';

    foreach ($tablesInSchema as $table) {
        $alias = strtoupper($schema . '_' . str_replace('.', '_', $table['name']));
        $lines[] = "    {$alias} {";
        foreach ($table['columns'] as $column) {
            $colLine = '        ' . $column['type'] . ' ' . $column['name'];
            if ($table['primary_key'] && in_array($column['name'], $table['primary_key']['columns'], true)) {
                $colLine .= ' PK';
            }
            $lines[] = $colLine;
        }
        $lines[] = '    }';
    }

    foreach ($tablesInSchema as $table) {
        $alias = strtoupper($table['schema'] . '_' . str_replace('.', '_', $table['name']));
        foreach ($table['foreign_keys'] as $fk) {
            $ref = $fk['referenced_table'];
            if (!isset($tables[$ref])) {
                continue;
            }
            if ($tables[$ref]['schema'] !== $schema) {
                continue;
            }
            $refAlias = strtoupper($tables[$ref]['schema'] . '_' . str_replace('.', '_', $tables[$ref]['name']));
            $lines[] = "    {$refAlias} ||--o{ {$alias} : \"{$fk['name']}\"";
        }
    }

    $lines[] = '```';
    $lines[] = '';
}

$keywords = ['caja', 'cash', 'venta', 'sales', 'pago', 'payment', 'movimiento', 'movement'];
$focusedTables = [];
foreach ($tables as $key => $table) {
    foreach ($keywords as $keyword) {
        if (str_contains(strtolower($table['name']), $keyword)) {
            $focusedTables[$key] = $table;
            break;
        }
    }
}

if ($focusedTables) {
    $lines[] = '## Diagrama Global - caja/ventas/pagos/movimientos';
    $lines[] = '```mermaid';
    $lines[] = 'erDiagram';
    foreach ($focusedTables as $table) {
        $alias = strtoupper($table['schema'] . '_' . str_replace('.', '_', $table['name']));
        $lines[] = "    {$alias} {";
        foreach ($table['columns'] as $column) {
            $colLine = '        ' . $column['type'] . ' ' . $column['name'];
            if ($table['primary_key'] && in_array($column['name'], $table['primary_key']['columns'], true)) {
                $colLine .= ' PK';
            }
            $lines[] = $colLine;
        }
        $lines[] = '    }';
    }
    foreach ($focusedTables as $table) {
        $alias = strtoupper($table['schema'] . '_' . str_replace('.', '_', $table['name']));
        foreach ($table['foreign_keys'] as $fk) {
            $refKey = $fk['referenced_table'];
            if (!isset($focusedTables[$refKey])) {
                continue;
            }

            $refAlias = strtoupper($focusedTables[$refKey]['schema'] . '_' . str_replace('.', '_', $focusedTables[$refKey]['name']));
            $lines[] = "    {$refAlias} ||--o{ {$alias} : \"{$fk['name']}\"";
        }
    }
    $lines[] = '```';
    $lines[] = '';
}

$lines[] = '## Detalle de tablas';
$lines[] = '';

foreach ($tables as $table) {
    $lines[] = '### ' . $table['schema'] . '.' . $table['name'];
    $lines[] = '- Descripción: ' . ($table['description'] ?? 'sin comentario');
    $rowEstimate = $table['row_estimate'];
    $rowText = $rowEstimate === null ? 'desconocido' : '~' . number_format($rowEstimate);
    $lines[] = '- Filas estimadas: ' . $rowText;

    $flagLabels = [];
    if ($table['flags']['faltan_indices_fk']) {
        $label = 'faltan índices para FKs';
        if (!empty($table['fk_missing_indexes'])) {
            $label .= ' (' . implode(', ', $table['fk_missing_indexes']) . ')';
        }
        $flagLabels[] = $label;
    }
    if ($table['flags']['campos_monetarios_no_uniformes']) {
        $flagLabels[] = 'campos monetarios no uniformes';
    }
    if ($table['flags']['sin_timestamps']) {
        $flagLabels[] = 'sin timestamps';
    }
    $lines[] = '- Flags: ' . ($flagLabels ? implode(' | ', $flagLabels) : 'ninguno');
    $lines[] = '';

    $lines[] = '#### Columnas';
    $lines[] = '| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |';
    $lines[] = '| --- | --- | --- | --- | --- | --- |';
    foreach ($table['columns'] as $column) {
        $nullableText = $column['is_nullable'] ? 'Sí' : 'No';
        $defaultText = $column['default'] !== null ? str_replace(["\n", "\r"], ' ', $column['default']) : '';
        $identityText = $column['identity'] ?? ($column['sequence'] ?? '');
        $commentText = $column['comment'] ?? '';
        $lines[] = sprintf(
            '| %s | %s | %s | %s | %s | %s |',
            $column['name'],
            $column['type'],
            $nullableText,
            $defaultText,
            $identityText,
            str_replace(['|', "\n", "\r"], ['\|', ' ', ' '], $commentText)
        );
    }
    $lines[] = '';

    $lines[] = '#### Llave primaria';
    if ($table['primary_key']) {
        $lines[] = '- ' . $table['primary_key']['name'] . ': ' . implode(', ', $table['primary_key']['columns']);
    } else {
        $lines[] = '- No definida';
    }
    $lines[] = '';

    $lines[] = '#### Llaves foráneas';
    if ($table['foreign_keys']) {
        foreach ($table['foreign_keys'] as $fk) {
            $lines[] = '- ' . $fk['name'] . ': (' . implode(', ', $fk['columns']) . ') ➜ ' .
                $fk['referenced_table'] . ' (' . implode(', ', $fk['referenced_columns']) . ')';
        }
    } else {
        $lines[] = '- Sin llaves foráneas';
    }
    $lines[] = '';

    $lines[] = '#### Índices';
    if ($table['indexes']) {
        foreach ($table['indexes'] as $index) {
            $attributes = [];
            if ($index['is_primary']) {
                $attributes[] = 'PK';
            }
            if ($index['is_unique']) {
                $attributes[] = 'UNIQUE';
            }
            if ($index['is_partial']) {
                $attributes[] = 'PARCIAL';
            }
            if (!$index['is_valid']) {
                $attributes[] = 'INVALIDO';
            }
            $attributeText = $attributes ? ' [' . implode(', ', $attributes) . ']' : '';
            $predicateText = $index['predicate'] ? ' WHERE ' . $index['predicate'] : '';
            $lines[] = '- ' . $index['name'] . $attributeText . ' (' . implode(', ', $index['columns']) . ')'
                . ' USING ' . strtoupper($index['method']) . $predicateText;
        }
    } else {
        $lines[] = '- Sin índices';
    }
    $lines[] = '';

    $lines[] = '#### Restricciones UNIQUE';
    if ($table['unique_constraints']) {
        foreach ($table['unique_constraints'] as $constraint) {
            $lines[] = '- ' . $constraint['name'] . ': ' . implode(', ', $constraint['columns']);
        }
    } else {
        $lines[] = '- Sin restricciones UNIQUE adicionales';
    }
    $lines[] = '';

    $lines[] = '#### Restricciones CHECK';
    if ($table['check_constraints']) {
        foreach ($table['check_constraints'] as $constraint) {
            $lines[] = '- ' . $constraint['name'] . ': ' . $constraint['definition'];
        }
    } else {
        $lines[] = '- Sin restricciones CHECK';
    }
    $lines[] = '';
}

$markdown = implode("\n", $lines) . "\n";

if (false === file_put_contents($outputPath, $markdown)) {
    fwrite(STDERR, "No se pudo escribir el archivo {$outputPath}\n");
    exit(1);
}

echo "Diccionario generado en {$outputPath}\n";
