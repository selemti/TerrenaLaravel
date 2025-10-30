# Prompts · Ejecución rápida por CLI

## POS · Ventas/mods sin mapa (día actual)
```
psql -h localhost -p 5433 -U postgres -d pos
\set bdate 2025-10-29
\set sucursal_key '1'
\i verification_queries_psql_v5.sql
```
Interpretación: si 1) y 1.b) devuelven filas, completar mapeos en `selemti.pos_map`.

## Cierre diario (Artisan)
```
cd C:\xampp3\htdocs\TerrenaLaravel
php artisan close:daily --date=2025-10-29 --branch='1' -vvv
```
Verificar logs del canal `daily_close` y volver a correr los bloques 3,4,5 del SQL v5.

## Reproceso POS (si existe comando)
```
php artisan pos:reprocess --date=2025-10-29 --branch='1' -vvv
```
Revalidar bloque 7).

## Re-cálculo costos 01:10 (manual)
```
php artisan recetas:recalcular-costos --date=2025-10-29 -vvv
```
Revisar inserciones en `selemti.recipe_cost_history` (`snapshot_at::date = 2025-10-29`).
