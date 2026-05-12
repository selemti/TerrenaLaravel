\o 'C:/xampp3/htdocs/TerrenaLaravel/tmp_db_usage.txt'
\echo '==== TABLE STATISTICS ===='
SELECT relname as table_name,
       n_live_tup as active_rows,
       n_tup_ins as total_inserts,
       n_tup_upd as total_updates
FROM pg_stat_user_tables
WHERE schemaname = 'selemti'
ORDER BY n_tup_ins DESC LIMIT 40;

\echo '==== SELEMTI TRIGGERS ===='
SELECT event_object_table AS table_name, trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'selemti'
ORDER BY table_name;
\o
