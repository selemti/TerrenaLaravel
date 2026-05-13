<!-- ⚠️ INVARIANTE CRÍTICO: DB_SCHEMA en phpunit.xml debe ser SOLO `selemti`. Nunca incluir `public`. Si se agrega `public`, RefreshDatabase borra las 108 tablas FloreantPOS. Ocurrió 2026-05-13. public es READ ONLY. Test guardián: tests/Unit/GuardRailsTest -->

Rol: Auditor SQL. Postgres 9.5.

Objetivo:
- Mantener `verification_queries_psql_v5.sql` y `verification_queries_psql_range.sql` alineados al esquema real.
- `discover_schema_psql_v2.sql` es la fuente de columnas. Prohibido suponer nombres.
- Corregir `item_id` → `mp_id` en pendientes/reproceso (ya aplicado).

Entrega:
- Rama: `feat/sql-auditor-<fecha>`.
- Carpeta `docs/Orquestador/sql/` con scripts finales y ejemplos de `\set` + `\i`.
