---
name: graphify
description: Turn any folder of files into a navigable knowledge graph
---

<!-- ⚠️ INVARIANTE CRÍTICO: DB_SCHEMA en phpunit.xml debe ser SOLO `selemti`. Nunca incluir `public`. Si se agrega `public`, RefreshDatabase borra las 108 tablas FloreantPOS. Ocurrió 2026-05-13. public es READ ONLY. Test guardián: tests/Unit/GuardRailsTest -->

# Workflow: graphify

Follow the graphify skill installed at ~/.agent/skills/graphify/SKILL.md to run the full pipeline.

If no path argument is given, use `.` (current directory).
