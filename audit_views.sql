\o 'C:/xampp3/htdocs/TerrenaLaravel/tmp_views.txt'
\echo '==== VW_POSTCORTES_CON_DESCUENTOS ===='
SELECT pg_get_viewdef('selemti.vw_postcortes_con_descuentos', true);

\echo '==== VW_CONCILIACION_SESION ===='
SELECT pg_get_viewdef('selemti.vw_conciliacion_sesion', true);

\echo '==== VW_DRAWER_RESUME (if exists) ===='
SELECT pg_get_viewdef('public.vw_drawer_resume', true);
\o
