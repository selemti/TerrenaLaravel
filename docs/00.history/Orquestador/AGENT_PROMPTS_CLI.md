
# Prompts de Agentes (CLI) · Correr en tu entorno
> Todos los agentes trabajan **sin DDL** y con el esquema validado. Copia/pega tal cual.

## A1 · Verificación integral del día
**Herramienta:** psql  
```
\set bdate 2025-10-29
\set sucursal_key '1'
\i verification_queries_psql_v6.sql
```
**Esperado:** 7 secciones con resultados útiles. `0 filas` en “sin mapa” implica cobertura completa.

## A2 · Orquestador de cierre
**Herramienta:** Artisan  
```
php artisan close:daily --date=2025-10-29 --branch=1 --verbose
```
**Comportamiento:** idempotente. Revisa logs de canal `daily_close`.

## A3 · Reproceso POS puntual de un ticket
**Herramienta:** Artisan (si existe comando) o psql para identificar y luego endpoint interno.
```
-- localizar candidatos (ya en v6, bloque 7)
```
**Acción:** ejecutar tu servicio de reproceso sobre `ticket_id` y validar `mov_inv` (ref_tipo='AJUSTE_REPROCESO_POS').

## A4 · Auditoría de mapeos
**Herramienta:** psql  
- Usa bloques 1 y 1.b para listar gaps.
- Insertar mapeos válidos vía UI existente o script controlado (si ya lo tienes).

## A5 · Recalculo de costos (01:10)
**Herramienta:** Artisan (ya en Kernel)
```
php artisan recetas:recalcular-costos --date=2025-10-29 --branch=1 --dry-run
```
**Verifica:** snapshots en `recipe_cost_history` o `recipe_extended_cost_history`.

## A6 · Conteos abiertos del día
**Herramienta:** psql (bloque 8 de v6)  
Cierra desde tu UI/servicio donde corresponde.

## A7 · Snapshots
**Herramienta:** Artisan (dentro del cierre) o comando dedicado si lo creaste  
Verifica en `selemti.inventory_snapshot` por `(snapshot_date, branch_id)`.
