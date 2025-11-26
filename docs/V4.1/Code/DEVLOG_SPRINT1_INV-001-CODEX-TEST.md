# DEVLOG SPRINT 1 - INV-001-CODEX-TEST

**Task_ID:** INV-001-CODEX-TEST  
**Épica:** INV-001 (Motor de Replenishment)  
**IA:** CODEX (Backend Tests)  
**Fecha:** 2025-11-25  
**Estado:** POR_VALIDAR (tests creados, ejecución bloqueada por falta de driver SQLite en entorno)

---

## Objetivo
Crear cobertura básica de integración para el motor de Replenishment (MIN_MAX, POS_CONSUMPTION y API de listado), sin modificar la lógica existente salvo hallazgo de bug evidente.

## Cambios realizados
- **tests/Feature/Purchasing/ReplenishmentTest.php** (nuevo)
  - Monta entorno de pruebas en memoria usando conexión `pgsql` y adjuntando schema `selemti` (tablas mínimas: items, inv_stock_policy, mov_inv, inv_consumo_pos, inv_consumo_pos_det, replenishment_suggestions, auth básica).
  - **Caso MIN_MAX:** stock por debajo del mínimo genera sugerencia de compra usando `reorder_qty`.
  - **Caso POS_CONSUMPTION:** consumo histórico expandido (inv_consumo_pos_det) se usa para el promedio diario y produce sugerencia urgente sin stock.
  - **Caso API:** GET `/api/purchasing/replenishment/suggestions` responde 200 y estructura esperada bajo `auth:sanctum`.

## Validaciones
- `php -l tests/Feature/Purchasing/ReplenishmentTest.php`
- `php artisan test --testsuite=Feature --filter ReplenishmentTest` **falló**: `PDOException: could not find driver` (el entorno solo tiene `pdo_pgsql`, no `pdo_sqlite`; no hay base Postgres accesible para tests). Las pruebas quedan pendientes de ejecución en un entorno con driver disponible.

## Notas y próximos pasos
- Ejecutar el suite en entorno con driver disponible (`pdo_pgsql` apuntando a BD de pruebas o agregar `pdo_sqlite`) para validar los casos recién agregados.
- No se cambió la lógica de `ReplenishmentService`; las pruebas buscan detectar regresiones en algoritmos y API.

