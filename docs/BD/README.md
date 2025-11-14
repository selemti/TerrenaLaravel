# Documentación de Base de Datos

## Carpetas principales

- `docs/BD/Normalizacion/` – Estrategias y bitácoras de normalización (incluye `README_UOM_NORMALIZATION.md`, `UOM_NORMALIZATION_SUMMARY.md`, `VERIFICATION_LOG.txt`).
- `docs/docs/docs/BD/NoviembreDocsDocsDocs/` – Paquete de auditorías y planes ejecutados en noviembre (subcarpetas `10_11_2025/`, `VentasReport/`, etc.).
- `docs/BD/HistorialDeploys/` – Documentación legacy de despliegues (`DEPLOY_*`, checklist históricos).
- `docs/BD/Auditoria/` – Reportes de comparación y restauración de BD.
- `docs/BD/patches_docs/` – README y notas asociadas a los scripts de `BD/patches/`.
- `docs/BD/scripts/` – Documentación y ayudas para los scripts SQL/automatizaciones.

## Scripts vs. Documentación

Los archivos SQL/backup siguen viviendo en la carpeta raíz `BD/`, mientras que sus manuales y reportes se han movido a `docs/BD/**`.  
Si encuentras referencias antiguas del tipo `BD/<archivo>.md`, actualízalas a la nueva ruta dentro de `docs/BD/`.
