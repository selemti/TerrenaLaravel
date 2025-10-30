-- discover_schema_psql_v2.sql
-- Terrena · Descubrimiento avanzado del esquema de base de datos · psql 9.5+
-- Versión 2: Incluye información detallada de columnas, tipos, llaves foráneas y estadísticas
-- Uso: \i discover_schema_psql_v2.sql > schema_info.txt

/* =======================================================================
 1) Información general de esquemas
======================================================================== */
SELECT 
    schema_name,
    COUNT(*) as total_tables
FROM information_schema.tables 
WHERE table_schema IN ('public', 'selemti')
GROUP BY schema_name
ORDER BY schema_name;

/* =======================================================================
 2) Tablas en esquema 'public' con detalles
======================================================================== */
SELECT 
    t.table_name,
    pg_size_pretty(pg_total_relation_size('"' || t.table_schema || '"."' || t.table_name || '"')) as size,
    (xpath('/row/c/text()', 
          xmlquery(on overflow text 
                   passing xmlparse(document 
                     pg_size_pretty(pg_table_size('"' || t.table_name || '"')))))[1]).value as table_size,
    (xpath('/row/c/text()', 
          xmlquery(on overflow text 
                   passing xmlparse(document 
                     (SELECT count(*)::text FROM public.quote_ident(t.table_name)) 
                     RESCUING 0)))[1]).value as estimated_rows
FROM information_schema.tables t
WHERE t.table_schema = 'public'
ORDER BY t.table_name;

/* =======================================================================
 3) Tablas en esquema 'selemti' con detalles
======================================================================== */
SELECT 
    t.table_name,
    pg_size_pretty(pg_total_relation_size('"' || t.table_schema || '"."' || t.table_name || '"')) as size,
    (SELECT count(*) FROM selemti.quote_ident(t.table_name) LIMIT 1 
     RESCUING 0) as estimated_rows
FROM information_schema.tables t
WHERE t.table_schema = 'selemti'
ORDER BY t.table_name;

/* =======================================================================
 4) Columnas de tabla selemti.pos_map con tipos detallados
======================================================================== */
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'pos_map'
ORDER BY ordinal_position;

/* =======================================================================
 5) Columnas de tabla selemti.inventory_counts e inventory_count_lines
======================================================================== */
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_schema = 'selemti' 
  AND table_name IN ('inventory_counts', 'inventory_count_lines')
ORDER BY table_name, ordinal_position;

/* =======================================================================
 6) Columnas de tablas de costos de recetas
======================================================================== */
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_schema = 'selemti' 
  AND table_name IN ('recipe_cost_history', 'recipe_extended_cost_history')
ORDER BY table_name, ordinal_position;

/* =======================================================================
 7) Índices en tablas relevantes para rendimiento
======================================================================== */
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname IN ('public', 'selemti')
  AND tablename IN (
    'pos_map', 'inventory_counts', 'inventory_count_lines',
    'recipe_cost_history', 'recipe_extended_cost_history',
    'inv_consumo_pos', 'inv_consumo_pos_det', 'mov_inv', 'items'
  )
ORDER BY schemaname, tablename, indexname;

/* =======================================================================
 8) Llaves foráneas en esquema selemti
======================================================================== */
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
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
ORDER BY tc.table_name, kcu.column_name;

/* =======================================================================
 9) Secuencias en los esquemas relevantes
======================================================================== */
SELECT 
    sequence_schema,
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value,
    increment,
    cycle_option
FROM information_schema.sequences
WHERE sequence_schema IN ('public', 'selemti')
ORDER BY sequence_schema, sequence_name;

/* =======================================================================
 10) Estadísticas de uso de tablas (últimas operaciones)
======================================================================== */
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_tup_hot_upd,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname IN ('public', 'selemti')
ORDER BY schemaname, tablename;

/* =======================================================================
 11) Tipos de datos personalizados (si existen)
======================================================================== */
SELECT 
    t.typname AS type_name,
    n.nspname AS schema_name,
    t.typtype AS type_type,
    pg_catalog.obj_description(t.oid, 'pg_type') AS description
FROM pg_catalog.pg_type t
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid))
  AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
  AND n.nspname IN ('public', 'selemti')
ORDER BY schema_name, type_name;

/* =======================================================================
 12) Configuración de los servidores de datos (importante para integraciones)
======================================================================== */
SELECT 
    name,
    setting,
    unit,
    category,
    short_desc
FROM pg_settings
WHERE name IN (
    'max_connections', 'shared_buffers', 'effective_cache_size',
    'work_mem', 'maintenance_work_mem', 'checkpoint_completion_target',
    'wal_buffers', 'default_statistics_target', 'random_page_cost',
    'effective_io_concurrency', 'max_worker_processes', 'max_parallel_workers'
)
ORDER BY category, name;