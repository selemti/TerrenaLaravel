## ⚠️ INVARIANTE CRÍTICO

`DB_SCHEMA` en `phpunit.xml` debe ser **solo `selemti`**. Nunca incluir `public`.
Si se agrega `public`, `RefreshDatabase` → `migrate:fresh` → `dropAllTables()` borra las 108 tablas FloreantPOS (`ticket`, `terminal`, `cash_drawer`…) en cada test run. **Ocurrió 2026-05-13, requirió restore desde producción.**
El schema `public` es **READ ONLY** — nunca escribir, alterar ni borrar nada en él.
Test guardián: `tests/Unit/GuardRailsTest` — no eliminarlo ni saltarlo.

---

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- If the graphify MCP server is active, utilize tools like `query_graph`, `get_node`, and `shortest_path` for precise architecture navigation instead of falling back to `grep`
- If the MCP server is not active, the CLI equivalents are `graphify query "<question>"`, `graphify path "<A>" "<B>"`, and `graphify explain "<concept>"` — prefer these over grep for cross-module questions
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
