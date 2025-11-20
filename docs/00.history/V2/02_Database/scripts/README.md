# Scripts SQL (`docs/V2/02_Database/scripts/`)

Guarda aquí los scripts versionados que acompañan a las migraciones de Laravel (por ejemplo, vistas complejas de inventario, procedimientos de caja, seeds masivos).

## Convenciones

- Usa prefijos por módulo, ej. `inventory__create_views.sql`, `caja__precorte_dashboard.sql`.
- Documenta en `schema_public.md` o `schema_selemti.md` la finalidad de cada script y el ambiente donde se aplica.
- Evita subir respaldos completos (`backup_*.sql`) o deploys obsoletos; archívalos en `assets/legacy/` si deben conservarse.
- Cuando un script se convierta en migración, elimina la versión manual o márcala como deprecada.

## Pendiente por migrar

- `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql`
- `BD/post_deploy_verify_v4.sql`
- `D:/Tavo/2025/UX/Inventarios/selemti_deploy_inventarios_FINAL_v2.sql`
- `D:/Tavo/2025/UX/Cortes/precorte_conciliacion_*.sql`
- `D:/Tavo/2025/UX/00. Recetas/Query Recetas/*.sql`

Confirma la vigencia de cada archivo antes de copiarlo aquí.
