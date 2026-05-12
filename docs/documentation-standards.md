---
description: Estándares para documentación técnica y AI specs en TerrenaLaravel. Define qué documentar, cuándo actualizarlo, y cómo el agente aprende del feedback del usuario.
alwaysApply: true
---

# Documentation Standards — TerrenaLaravel

---

## 1. Tipos de documentación

| Tipo | Ubicación | Idioma | Propósito |
|------|-----------|--------|-----------|
| Documentación técnica del sistema | `docs/2026/` | Español | Estado del sistema, arquitectura, módulos |
| Estándares y convenciones | `docs/` | Inglés/Español mixto | Reglas para agentes y desarrolladores |
| Specs de OpenSpec | `specs/` | Inglés | Proposals, designs, tasks, scenarios |
| Configuración de agentes | `CLAUDE.md`, `.gemini/GEMINI.md` | Español | Instrucciones específicas por agente |
| Skills | `.claude/skills/` | Inglés | Workflows reutilizables para agentes |
| Memoria del agente | `.claude/memory/` | Español/Inglés | Contexto persistente entre sesiones |

---

## 2. Cuándo actualizar documentación

**Antes de hacer commit o PR**, el agente DEBE revisar qué documentación debe actualizarse.

| Si cambió... | Actualizar... |
|-------------|---------------|
| Un endpoint de API | `docs/2026/03_RUTAS_Y_API.md` |
| Un módulo (Caja, Inventario, etc.) | `docs/2026/04_MODULOS/<MODULO>.md` |
| La base de datos (migración nueva) | `docs/2026/02_BASE_DE_DATOS.md` |
| Una arquitectura o servicio | `docs/2026/01_ARQUITECTURA.md` |
| Un bug conocido o pendiente | `docs/2026/05_PENDIENTES_Y_BUGS.md` |
| Skills o configuración de agentes | Archivo específico del skill o CLAUDE.md |

Usar el skill `update-docs` para ejecutar este proceso de forma sistemática.

---

## 3. Proceso de actualización

1. Revisar todos los cambios recientes del codebase (`git diff`)
2. Identificar qué archivos de docs se ven afectados
3. Actualizar cada archivo afectado manteniendo consistencia con el resto
4. Verificar que los cambios estén reflejados con precisión
5. Reportar qué archivos fueron actualizados y qué cambió

---

## 4. AI Specs — Aprendizaje continuo del agente

El agente DEBE aprender del feedback del usuario durante las interacciones y actualizar las reglas cuando corresponda.

### Cuándo actualizar reglas

- El usuario corrige un comportamiento: *"no hagas X"*, *"siempre haz Y"*
- El usuario confirma que un enfoque no obvio fue correcto: aceptarlo sin pushback equivale a validarlo
- Se descubre una restricción nueva del sistema (ej. PG 9.5 no soporta cierta sintaxis)
- Se agrega un patrón nuevo que todos los agentes deben seguir

### Anti-patrones a evitar

- **Omitir el proceso de aprobación**: No modificar reglas sin que el usuario lo apruebe (excepto memory)
- **Cambios no vinculados**: Proponer cambios de reglas sin conectarlos al feedback específico que los originó
- **Scope creep**: No actualizar múltiples reglas no relacionadas al mismo tiempo
- **Cambios sin notificar**: Siempre confirmar al usuario qué regla se actualizó y por qué
- **Cambios proactivos sin feedback**: Las reglas se actualizan reactivamente ante feedback, no por iniciativa propia

### Dónde guardar aprendizajes

| Tipo de aprendizaje | Dónde guardarlo |
|--------------------|-----------------|
| Preferencia del usuario (comportamiento del agente) | `.claude/memory/feedback_*.md` |
| Dato sobre el usuario (rol, experiencia) | `.claude/memory/user_*.md` |
| Contexto del proyecto | `.claude/memory/project_*.md` |
| Regla que aplica a todos los agentes | `docs/base-standards.md` |
| Regla específica de Claude | `CLAUDE.md` |
| Regla específica de Gemini | `.gemini/GEMINI.md` |

---

## 5. Formato de documentación técnica

- Usar Markdown con headers `##` y `###`
- Tablas para comparaciones y mappings
- Bloques de código con lenguaje explícito (` ```php `, ` ```sql `, etc.)
- Fechas en formato `YYYY-MM-DD`
- Estado de módulos con emojis de semáforo: ✅ completo, 🔄 en progreso, ❌ pendiente

---

## 6. Documentación de OpenSpec

Cada change en `specs/<change-name>/` debe incluir:

| Artefacto | Propósito |
|-----------|-----------|
| `proposal.md` | Qué se va a construir y por qué |
| `design.md` | Cómo se va a construir (arquitectura, decisiones) |
| `specs.md` | Requisitos funcionales y no-funcionales |
| `scenarios.md` | Casos de uso y edge cases |
| `tasks.md` | Lista de tareas ordenadas con estado |
| `reports/` | Reportes de testing generados por el agente |

**Regla**: Nunca archivar un change sin que todos estos artefactos estén actualizados y reflejen el estado final de la implementación.
