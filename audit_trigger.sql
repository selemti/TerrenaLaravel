\o 'C:/xampp3/htdocs/TerrenaLaravel/tmp_trigger_audit.txt'
\echo '==== FUNCTION selemti.fn_postcorte_after_insert ===='
SELECT pg_get_functiondef(p.oid) 
FROM pg_proc p 
JOIN pg_namespace n ON n.oid = p.pronamespace 
WHERE n.nspname = 'selemti' AND p.proname = 'fn_postcorte_after_insert';

\echo '==== FUNCTION public.fn_postcorte_after_insert (if exists) ===='
SELECT pg_get_functiondef(p.oid) 
FROM pg_proc p 
JOIN pg_namespace n ON n.oid = p.pronamespace 
WHERE n.nspname = 'public' AND p.proname = 'fn_postcorte_after_insert';
\o
