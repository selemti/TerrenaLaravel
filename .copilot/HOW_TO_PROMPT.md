# Cómo pedirle cosas a Copilot (y no quemar tokens)

- Usa `@workspace` + rutas específicas (máximo 5 archivos).
- Pide **cambios incrementales** (“aplica diff en estos 2 archivos”), no refactors masivos.
- Pega SOLO el fragmento de esquema o SQL necesario (no todo el dump).
- Pide “generar Livewire component + Blade + route” en una rama nueva y con nombres de archivo exactos.
- Rechaza invenciones: “Si una columna no existe, detente y propone variante basada en discover_schema_psql_v2.sql”.
- Antes de test: “valida contra verification_queries_psql_v5.sql (bloques X, Y)”.
