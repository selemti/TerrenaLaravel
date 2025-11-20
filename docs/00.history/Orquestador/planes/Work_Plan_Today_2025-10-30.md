# PLAN DIARIO DETALLADO · Orquestador v6 · 2025-10-30

> Objetivo del día: Cerrar el ciclo **POS → Consumo → Reproceso → Snapshot → Conteos → Costos de Receta** con evidencias y UIs alineadas a **verification_queries_psql_v6.sql** y sin cambios de esquema.

## 0) Convenciones y rutas
- Repo: `C:\xampp3\htdocs\TerrenaLaravel`
- Docs orquestador: `docs\Orquestador\`
- SQL verificación v6: `docs\Orquestador\sql\verification_queries_psql_v6.sql`
- Descubrimiento: `docs\Orquestador\sql\discover_schema_psql_v2.sql`
- Ramas sugeridas: 
  - `feat/orq-v6-ui-mappings`
  - `feat/orq-v6-counts-close`
  - `feat/orq-v6-cost-scheduler`
  - `feat/orq-v6-sql-auditor`
- Timezone: `America/Mexico_City`
- PostgreSQL local: `psql -h localhost -p 5433 -U postgres -d pos`

## 1) POS Mapping UI (Componente + CRUD + filtros)
**Meta:** Operativa la UI para `selemti.pos_map` (tipo MENU/MODIFIER), con filtros por `plu`, `tipo`, vigencia y buscador.
- Archivos target:
  - `app/Livewire/PosMap/Index.php`
  - `resources/views/livewire/pos-map/index.blade.php`
  - `routes/web.php` (ruta `/pos-map` si no existe)
  - Doc evidencia: `docs/Orquestador/UI_Mapping_README.md`
- Datos reales (sin DDL): columnas detectadas en `selemti.pos_map`: `plu text`, `tipo text`, `receta_id text`, `receta_version_id int`, `valid_from date`, `valid_to date`, `vigente_desde timestamptz`, `meta json`, `sys_from ts`, `sys_to ts`.
- Filtros mínimos (front): `plu`, `tipo`, rango fecha (`valid_from`-`valid_to` o `vigente_desde`), texto libre.
- Acciones: Alta/edición (validar que `receta_id` sea numérico al guardar → castear a `bigint` en back antes de consumirlo), baja lógica (si aplica con vigencias; **no** DELETE real si hay bitemporalidad).
- Integración auditoría:
  - Botón “Ver pendientes” → ejecuta **Bloques 1 y 1.b** de `verification_queries_psql_v6.sql` y muestra tabla con **ventas/modificadores sin mapa** del día (parámetros: `:bdate`, `:sucursal_key`, opcional `:terminal_id`).
- Smoke test (CLI):
  ```ps1
  psql -h localhost -p 5433 -U postgres -d pos -f docs/Orquestador/sql/verification_queries_psql_v6.sql
  ```
- Criterios de aceptación (DoD):
  1. Lista filtra por `plu` y `tipo` en < 500ms datasets pequeños.
  2. Crear/editar mapa crea vigencia válida (no vacíos mutuamente excluyentes).
  3. Botón “Pendientes” refleja **0 filas** tras mapear casos reales del día.

## 2) Conteos físicos (listar/cerrar) + validación SQL
**Meta:** Operativa la UI de conteos para listar, abrir/cerrar y validar “0 abiertos” por v6.
- Archivos target:
  - `app/Livewire/InventoryCount/Index.php` (ya existe: sólo añadir acción cerrar + validación)
  - `resources/views/livewire/inventory-count/index.blade.php`
  - Evidencia: `docs/Orquestador/Conteos_Evidencia_2025-10-30.md`
- Flujo:
  1. Listar `selemti.inventory_counts` con filtros: `estado`, `sucursal_id`, `programado_para`/`iniciado_en` rango.
  2. Acción “Cerrar” → invoca servicio existente (no DDL; actualizar `estado` a `CERRADO`/`CLOSED` y `cerrado_en`).
  3. Validar con **Bloque 8** v6 que el día quede sin abiertos.
- Smoke test:
  ```ps1
  psql ... -v bdate='2025-10-30' -v sucursal_key='1' -f docs/Orquestador/sql/verification_queries_psql_v6.sql
  ```
- DoD:
  - Cerrar ítem actualiza vista sin recargar página (Livewire event).
  - Bloque 8 retorna 0 filas para la sucursal y fecha cerrada.

## 3) Recalculo de costos de receta (scheduler 01:10) + evidencia
**Meta:** Confirmar que el job `recetas:recalcular-costos` corre a 01:10 MX, registra snapshots en `selemti.recipe_cost_history`.
- Archivos target:
  - `app/Console/Kernel.php` (ya programado a 01:10)
  - Servicio: `app/RecalcularCostosRecetasService.php` (usa `recipe_cost_history` y/o `recipe_extended_cost_history`)
  - Log evidencia: `storage/logs/laravel.log` → export a `docs/Orquestador/Costos_Scheduler_Log_2025-10-30.md`
- Verificaciones SQL (v6, bloque 6 adaptado a rango si aplica): hay snapshots `snapshot_at::date = :bdate`.
- DoD:
  - Al ejecutar manual: `php artisan recetas:recalcular-costos --date=2025-10-30` añade snapshots y evidencia en MD.
  - Si no hay cambios, log “sin cambios” y 0 nuevas filas.

## 4) Orquestación: expandidos sin movimientos y pendientes _det
**Meta:** Confirmar idempotencia y pendientes acotados.
- Verificación con v6:
  - Bloque 2: pendientes en `inv_consumo_pos/_det` (ajustar columna `d.item_id` → **no existe**; dejar campos: `d.id, d.cantidad, d.uom_id, d.procesado/requiere_reproceso`)
  - Bloque 3: expandidos sin `mov_inv` (join por `sucursal_id TEXT` y `ref_id/ref_tipo`).
- DoD: 0 expandidos sin movimientos; pendientes sólo los válidos para reproceso.

## 5) Auditor SQL (range + discover v2)
**Meta:** Scripts robustos para fechas/rango y descubrimiento.
- Asegurar presencia de:
  - `docs/Orquestador/sql/verification_queries_psql_v6.sql`
  - `docs/Orquestador/sql/verification_queries_psql_range.sql`
  - `docs/Orquestador/sql/discover_schema_psql_v2.sql`
- Quick run:
  ```ps1
  psql ... -v bdate='2025-10-30' -v sucursal_key='1' -f docs/Orquestador/sql/verification_queries_psql_v6.sql
  psql ... -v bdate_from='2025-10-30' -v bdate_to='2025-10-30' -v sucursal_key='1' -f docs/Orquestador/sql/verification_queries_psql_range.sql
  psql ... -f docs/Orquestador/sql/discover_schema_psql_v2.sql
  ```
- DoD: 0 errores de sintaxis; salidas coherentes con datos reales.

## 6) Dashboard de orquestación
**Meta:** Alinear tarjetas/indicadores con v6 sin tocar servicios.
- Checar `app/Inventory/OrquestadorPanel.php` (ok según sesiones previas).
- Añadir enlaces a: `/pos-map`, `/inventory-counts`, y botón “Auditar hoy” → ejecuta v6 y muestra modales con resultados.

## 7) Git, despliegue local y rollback
- Ramas por módulo (ver arriba), PRs hacia `integrate/web-prs-20251023-1922` o `main` según tu flujo.
- Commits sugeridos:
  - `feat(pos-map): ui filtros+crud compatible v6`
  - `feat(counts): cerrar+validar bloque8 v6`
  - `chore(auditor): scripts v6 range+discover`
  - `docs(orq): evidencias 2025-10-30`
- Rollback: revert PR; conservar scripts SQL v6 (read-only).

## 8) Evidencia mínima a generar
- `docs/Orquestador/UI_Mapping_README.md` (capturas + cómo correr bloque 1/1.b)
- `docs/Orquestador/Conteos_Evidencia_2025-10-30.md`
- `docs/Orquestador/Costos_Scheduler_Log_2025-10-30.md`
- `docs/Orquestador/Snapshot_Report_2025-10-30.md` (si ejecutas snapshot hoy)

## 9) Checklist de cierre (Go/No-Go)
- [ ] Bloque 1 y 1.b → 0 filas tras mapear
- [ ] Bloque 2 → pendientes esperados (sin `item_id` inexistente)
- [ ] Bloque 3 → 0 expandidos sin `mov_inv`
- [ ] Bloque 4 → cobertura snapshot OK
- [ ] Bloque 5 → 0 negativos o documentados
- [ ] Bloque 6 → snapshots presentes a la fecha
- [ ] Bloque 8 → 0 conteos abiertos después de cerrar
- [ ] UIs accesibles desde dashboard y rutas existentes
