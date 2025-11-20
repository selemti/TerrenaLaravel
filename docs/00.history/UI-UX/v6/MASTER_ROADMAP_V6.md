# MASTER_ROADMAP_V6

> Orden lógico de implementación para guiar a las IAs (CLI) minimizando tokens y re-trabajo.

## 0) Baseline
- Repositorio: C:\xampp3\htdocs\TerrenaLaravel
- Docs orquestador: docs/Orquestador (scripts v6)
- Esquemas: `public.*` (solo lectura), `selemti.*` (ERP)
- Ramas:
  - `feat/permissions-matrix-v6`
  - `feat/ui-costos-auditor-<YYYYMMDD>`

## 1) Permisos y plantillas (este paquete)
1. Aplicar `SEED_PLANTILLAS_V6.sql` o `PERMISSIONS_SEEDER_V6.php`.
2. Conectar policies middleware por prefijo de ruta.
3. Ocultar botones/acciones según `UI_GATING_MAP_V6.md`.

## 2) POS Mapping + Auditoría v6
- Validar con `verification_queries_psql_v6.sql` (bloques 1, 1.b y 2).
- UI PosMap: filtros por `tipo`, `plu`, vigencias; CRUD con guardas.
- Botón “Auditar POS” ejecuta consultas v6 y guarda evidencia en `docs/Orquestador/evidencias/`.

## 3) Conteos físicos
- UI listar/abrir/cerrar.
- Validación automática “0 abiertos” (bloque 8 v6) al cerrar.
- Evidencias `Conteos_Evidencia_<fecha>.md`.

## 4) Costos de recetas
- Confirmar Cron 01:10 `recetas:recalcular-costos` (timezone MX).
- Al snapshot: registro en `recipe_cost_history` y log en `Costos_Scheduler_Log_<fecha>.md`.
- Botón manual para snapshot sobre receta.

## 5) Snapshots de inventario
- Servicio `generateDailySnapshot` ya alineado; exponer botón UI con permiso `inventory.snapshot.generate`.
- Reporte `Snapshot_Report_<branch>_<date>.md` (ya tienes ejemplo).

## 6) Producción
- Ordenes de producción: cerrar OP → consumir MP + producir PT; registro en `mov_inv`.
- Validaciones mínimas: stock suficiente, política de merma/yield.

## 7) Compras / Sugerido
- Catálogos dinámicos, sugerido por rotación y cobertura; órdenes con aprobación.

## 8) Reportes / KPIs
- Dashboard consolidado: costo, margen, rotación, variación vs teórico.

## 9) Cierre Diario (Orquestador)
- Ejecuta pipeline: POS sync → consumo teórico → movimientos operativos → conteos → snapshot.
- Semáforos por sucursal/fecha. Logs en canal `daily_close`.

## Entregables diarios
- PR con rama correspondiente.
- Evidencias en docs/Orquestador/evidencias/ (screens + output SQL/MD).
- Checklist de permisos verificados (de esta matriz).
