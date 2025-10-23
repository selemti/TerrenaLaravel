# Terrena POS – Implementación v1.3

## Migraciones SQL
psql -U <user> -d <db> -f sql/2025_10_22_000001_caja_fondo.sql
psql -U <user> -d <db> -f sql/2025_10_22_000002_consumo_pos.sql
psql -U <user> -d <db> -f sql/2025_10_22_000003_triggers_pos.sql

## Variables .env sugeridas
POS_SYNC_INTERVAL_MIN=10
ALMACEN_DEFAULT_POR_SUCURSAL=true
CAJA_FONDO_MONEDA=MXN

## Tareas programadas
php artisan schedule:work

## Pruebas
php artisan test --testsuite=Feature