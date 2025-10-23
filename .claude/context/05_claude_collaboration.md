# Claude CLI · Colaboración híbrida

## Configuración inicial
- Mantén un resumen maestro (≤220 palabras) en `docs/SESSION_NOTES.md` con el estado backend/frontend y últimos commits.
- Antes de cada sesión con Claude, envía: objetivo puntual, rutas de referencia (`resources/views/...`, `app/Http/Livewire/...`), contrato de APIs relevantes y commit base.
- Usa la plantilla `Objetivo → Entradas → Restricciones → Entregables → Checklist Verificar`, exigiendo un bloque final "Resumen reutilizable" (≤5 bullets, ≤80 palabras).
- Repite a Claude que trabaja solo en archivos locales sin git, y que el backend se mantiene en este repositorio.

### Prompt tipo (frontend)
```
Objetivo: {feature UI específica} conectada a {endpoint/service backend}.
Entradas: {.claude/context/00_project_overview.md, docs/v3/README.md §X, resources/views/... , app/Http/Livewire/...}.
Restricciones: Laravel 12, Livewire 3, Tailwind, API JSON protegida por JWT.
Entregables: {componentes Blade/Livewire, estados, validaciones UI}.
Checklist Verificar: {casos UX, eventos, contratos con backend}.
Límite: 280 palabras + bloque "Resumen reutilizable".
```

## División de trabajo
| Dominio | Claude CLI (frontend local) | Yo (backend con Git) |
| --- | --- | --- |
| Recepciones | Diseñar Livewire forms, adjuntos UI, estados aprobados/rechazados, validaciones en cliente. | Migraciones dual DB, servicios, eventos, pruebas feature, endpoints REST. |
| Movimientos & conteos | Dashboards Kardex, componentes Counts, filtros visuales, accesibilidad. | Policies, repositorios, cálculos de valorización, sincronía multialmacén. |
| Producción & mermas | Flujos UI paso a paso, tablas dinámicas, alerts. | Workflows, triggers PG/SQLite, auditoría, reversas. |
| Costeo & BI | Tableros comparativos, gráficos, export UX. | Cron snapshots, cálculos MP+MO+CIF, APIs de reportes. |
| Ventas & menú | Layout dashboards Star/Plowhorse, drill-downs, export selectors. | ETL POS, agregaciones, recomendaciones, endpoints. |
| Caja & alertas | Formularios, estados visuales, timeline de alertas. | Modelos, colas, motores de alerta, NOM-151, notificaciones. |

## Flujo operativo sin conflictos
1. Yo publico commit hash y listado de endpoints/listeners listos en `docs/SESSION_NOTES.md`.
2. Claude trabaja en copia local; al terminar, entrega snippets por archivo con rutas claras + checklist Verificar.
3. Importo los fragmentos relevantes, adapto a backend y subo commits; documento diferencias en el resumen maestro.
4. Para cambios locales tuyos, vuelve a pegar solo los fragmentos actualizados con fecha y commit base al arrancar nueva sesión.

## Optimización de tokens
- Referencia archivos por secciones (`sed -n` o `rg`) en lugar de pegar todo; usa pseudocódigo cuando el HTML sea repetitivo.
- Solicita iteraciones por componente (vista, estado, interacción) y valida cada checklist antes de seguir.
- Pide a Claude autogenerar diffs sintéticos (`FILE: ruta
+ cambio`) para acelerar integración.
- Mantén histórico reducido: guarda resúmenes de sesión anteriores y reenvíalos solo si cambiaron dependencias.

## Sincronización
- Anota decisiones clave en `docs/SESSION_NOTES.md` y distribúyelas a Claude como contexto mínimo.
- Cuando reciba nueva API/back de mi parte, crea un bloque "Backend actualizado" con endpoints y contratos; así evitas contextos obsoletos.
- Al finalizar cada módulo, consolidamos: checklist cumplida, archivos validados, pendientes y próximos pasos.
