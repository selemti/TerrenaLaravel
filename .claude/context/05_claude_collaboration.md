# Claude CLI · Colaboración híbrida

## Configuración inicial
- **Contexto base**: prepara un snippet de 280-320 palabras con el resumen del dominio (usa `.claude/context/*.md`), la tabla o modelo clave y el objetivo inmediato. Reutiliza el mismo bloque para subsecciones consecutivas.
- **Plantilla de prompt**: `Objetivo → Inputs relevantes → Restricciones técnicas → Entregables`. Define en “Entradas” los archivos y líneas que debe considerar (ej. `app/Models/Inv/InventoryReception.php:L1-L200`).
- **Gestión de memoria**: después de cada ciclo guarda un extracto de 8-10 bullets en `docs/SESSION_NOTES.md`; úsalo para rehidratar sesiones sin recargar PDFs completos.
- **Auditoría local**: solicita siempre que Claude incluya un checklist `Verificar` con pasos ejecutables (tests, comandos artisan, seeders) para que yo los ejecute antes del commit.

## División de trabajo
| Dominio | Claude CLI (sesión local) | Revisión Git (yo) |
| --- | --- | --- |
| **Recepciones de inventario** | Bosquejar migraciones faltantes (headers, lines, attachments) con validaciones referenciales, diseñar flujo Livewire paso a paso y detallar reglas de aprobación dual. | Ajustar migraciones al esquema PG 9.5, conectar servicios `ReceptionService`, fixtures de precios históricos y subir seeds/factories con pruebas feature (`ReceptionFlowTest`). |
| **Movimientos y conteos** | Definir tipos de movimientos (`IN/OUT/ADJ/PROD_*`), políticas, wireframes Livewire para `MovementsIndex` y `Counts`. | Implementar repositorios y policies, consolidar filtros sucursal/almacén, conectar kardex y pruebas de valorización. |
| **Producción y mermas** | Diagramar flujo solicitud→producción→consumo, detallar triggers de consumo automático y catálogo de mermas. | Codificar listeners/observers, validar contra tablas `receta_version`, `merma_tipo`, asegurar reversas y registrar pruebas.
| **Costeo extendido** | Modelar cálculo MP+MO+CIF y estructura de snapshots. | Integrar jobs cron, cache y endpoints históricos, validar cálculo por porción/batch.
| **Ventas & menú** | Elaborar ETL POS→backoffice, mapeo PLU↔receta y reglas Star/Plowhorse/Puzzle/Dog. | Instrumentar pipelines `etl_pos_sync`, dashboards Livewire y exportes CSV/PDF.
| **Caja chica** | Detallar estados y formularios de fondo de caja, arqueo y alertas. | Montar modelos `CajaFondo`, Livewire UI y políticas, con pruebas de diferencias.
| **Alertas, reportes, seguridad, integraciones** | Producir matrices de alertas, plantillas de reportes y mapas de permisos. | Implementar canales (email/Slack), motor de reportes y auditoría NOM-151, además de endpoints externos.

## Estrategia por sprint
1. **Planificación**: Selecciona 2-3 módulos del cuadro, define entregables y prompts compactos para Claude.
2. **Iteración Claude**: Recibe diseños, validaciones y pseudocódigo. Limita cada respuesta a ≤350 palabras solicitando “Divide por archivos y concluye con resumen de 5 bullets”.
3. **Integración Git**: Implemento/ajusto, ejecuto pruebas (`php artisan test --filter=Reception`, `npm run lint`) y documento hallazgos.
4. **Retroalimentación**: Regreso a Claude con fallas concretas (logs, assertions) y pido correcciones parciales.
5. **Cierre**: Actualizamos `docs/SESSION_NOTES.md`, priorizamos siguiente sprint y registramos pendientes en Issues/Projects.

## Buen uso de tokens
- Prefiere referencias (`Ver app/Services/Inventory/ReceptionService`) antes de pegar archivos completos; comparte solo funciones/consultas críticas.
- Pide resúmenes intermedios (“Resume en 120 palabras lo entregado”) para reusar como contexto compacto.
- Rompe tareas grandes en subtareas secuenciales y confirma cada una antes de abrir otra para evitar cortes de sesión.
- Mantén un glosario de términos clave y IDs de tablas para enlazar rápidamente sin reexplicar.
