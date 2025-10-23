# Claude CLI · Colaboración híbrida

## Configuración inicial
- Resume en 200-240 palabras el contexto usando `.claude/context/*.md` y la sección de `docs/v3/README.md` vinculada.
- Formula el prompt como `Objetivo → Entradas → Restricciones → Entregables → Checklist`, citando rutas y rangos, y exige bloque `Verificar`.
- Tras cada iteración guarda 5-7 bullets en `docs/SESSION_NOTES.md` para rehidratar futuras sesiones.

### Plantilla sugerida
```
Objetivo: {tarea puntual}.
Entradas: {.claude/context/03_inventory_module.md, docs/v3/README.md §X, app/...}.
Restricciones: Laravel 12 + Livewire 3, PG 9.5 + SQLite.
Entregables: {lista}. Checklist «Verificar»: {tests/comandos}.
Límite: 300 palabras; cierra con 5 bullets resumen reutilizable.
```

## División de trabajo
| Dominio | Claude CLI (local) | Yo (Git) |
| --- | --- | --- |
| Recepciones | Migraciones, flujo Livewire, aprobaciones duales. | Ajustes dual DB, servicios, seeds, tests feature. |
| Movimientos & conteos | Tipos IN/OUT/ADJ/PROD, wireframes `MovementsIndex`/`Counts`. | Repositorios, policies, filtros, valorización. |
| Producción & mermas | Flujo solicitud→producción→consumo, triggers, catálogo mermas. | Listeners, reversas, QA integral. |
| Costeo extendido | Fórmulas MP+MO+CIF, snapshots deseados. | Cron jobs, históricos, endpoints. |
| Ventas & menú | ETL POS→backoffice, reglas Star/Plowhorse/Puzzle/Dog. | `etl_pos_sync`, dashboards, exportes. |
| Caja chica | Formularios y alertas críticas. | Modelos, Livewire, auditoría. |
| Alertas/Reportes/Seguridad | Matrices alertas, permisos, layout reportes. | Canales productivos, motor configurable, NOM-151, APIs. |

**Asignación inmediata**
- Claude: bosquejar migraciones pendientes, flujos Livewire, pseudo-servicios, matrices permisos/alertas.
- Yo: integrar en ramas feature, probar en PostgreSQL/SQLite, documentar hallazgos.
- Compartido: mover resúmenes/checklists a `docs/SESSION_NOTES.md` o nuevos briefs (≤320 palabras) en `.claude/context/`.

## Ciclo operativo
1. Define 2-3 entregables y dependencias antes de cada sesión.
2. Ejecuta el prompt, valida el checklist, sintetiza la salida en ≤90 palabras.
3. Integro y corro `php artisan test --filter=Reception`, `npm run lint` u otros; regreso con ajustes y próximos pasos.

## Optimización de tokens
- Usa referencias en lugar de pegar archivos completos; comparte solo bloques críticos.
- Divide tareas grandes, solicita resúmenes parciales y aclara que Claude trabaje con snippets aislados.

## Sincronización
- Conserva outputs en archivos temporales (`*_claude.sql`, `*_draft.md`) y entrégalos junto al resumen y checklist.
- Actualiza el prompt con el commit base vigente (`considera cambios hasta abc123`) y marca archivos nuevos cuando aún no existan en Git.
- Al cerrar un módulo comparte: objetivo cumplido, archivos generados, dependencias pendientes y bloque `Verificar` para la integración.
