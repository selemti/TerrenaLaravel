-- Post-deploy verifications
SET search_path TO selemti, public;

-- 1) Version
SELECT version();

-- 2) Esquemas clave
SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('public','selemti','selempos');

-- 3) Tablas de caja/inventario mínimas
SELECT table_schema, table_name FROM information_schema.tables WHERE (table_schema, table_name) IN
  ( ('selemti','sesion_cajon'),('selemti','precorte'),('selemti','precorte_efectivo'),('selemti','postcorte') );

-- 4) Triggers de subtotal
SELECT n.nspname AS schema, c.relname AS table, t.tgname AS trigger
FROM pg_trigger t
JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE t.tgenabled='O' AND t.tgname IN ('pc_precorte_cash_count_biu','selempos_precorte_cash_biu');

-- 5) Vistas/funciones clave si existen
SELECT table_schema, table_name FROM information_schema.views WHERE table_schema='selemti' AND table_name LIKE 'vw_%';

-- 6) Índices recomendados
SELECT i.relname AS index_name, t.relname AS table
FROM pg_class t JOIN pg_index ix ON ix.indrelid=t.oid JOIN pg_class i ON i.oid=ix.indexrelid JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname IN ('selemti','public') AND (
  (t.relname='precorte_efectivo' AND i.relname ILIKE '%precorte%')
  OR (t.relname='precorte' AND i.relname ILIKE '%sesion%')
  OR (t.relname='ticket' AND (i.relname ILIKE '%closing%' OR i.relname ILIKE '%term%' ))
);
