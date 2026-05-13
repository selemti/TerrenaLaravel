# ⚠️ INVARIANTE CRÍTICO — LEER PRIMERO

`DB_SCHEMA` en `phpunit.xml` debe ser **solo `selemti`**. Nunca incluir `public`.
Si se agrega `public`, `RefreshDatabase` → `migrate:fresh` → `dropAllTables()` borra las 108 tablas FloreantPOS (`ticket`, `terminal`, `cash_drawer`…) en cada test run. **Ocurrió 2026-05-13, requirió restore desde producción.**
El schema `public` es **READ ONLY** — nunca escribir, alterar ni borrar nada en él.
Test guardián: `tests/Unit/GuardRailsTest` — no eliminarlo ni saltarlo.
