-- Functions
SELECT n.nspname as schema, p.proname as function_name 
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'selemti') AND p.proname LIKE 'fn_%';

-- Views
SELECT schemaname, viewname 
FROM pg_views 
WHERE schemaname IN ('public', 'selemti');

-- Triggers
SELECT event_object_schema as schema, event_object_table as table_name, trigger_name 
FROM information_schema.triggers 
WHERE event_object_schema IN ('public', 'selemti');
