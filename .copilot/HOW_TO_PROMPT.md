# ⚠️ INVARIANTE CRÍTICO — LEER PRIMERO

`DB_SCHEMA` en `phpunit.xml` debe ser **solo `selemti`**. Nunca incluir `public`.
Si se agrega `public`, `RefreshDatabase` → `migrate:fresh` → `dropAllTables()` borra las 108 tablas FloreantPOS (`ticket`, `terminal`, `cash_drawer`…) en cada test run. **Ocurrió 2026-05-13, requirió restore desde producción.**
El schema `public` es **READ ONLY** — nunca escribir, alterar ni borrar nada en él.
Test guardián: `tests/Unit/GuardRailsTest` — no eliminarlo ni saltarlo.

---

# Cómo pedirle cosas a Copilot (y no quemar tokens)

- Usa `@workspace` + rutas específicas (máximo 5 archivos).
- Pide **cambios incrementales** (“aplica diff en estos 2 archivos”), no refactors masivos.
- Pega SOLO el fragmento de esquema o SQL necesario (no todo el dump).
- Pide “generar Livewire component + Blade + route” en una rama nueva y con nombres de archivo exactos.
- Rechaza invenciones: “Si una columna no existe, detente y propone variante basada en discover_schema_psql_v2.sql”.
- Antes de test: “valida contra verification_queries_psql_v5.sql (bloques X, Y)”.
