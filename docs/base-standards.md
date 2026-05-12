---
description: Reglas y lineamientos de desarrollo para TerrenaLaravel, aplicables a todos los agentes de IA (Claude, Gemini, Codex). Este documento es la fuente de verdad única para estándares cross-agente.
alwaysApply: true
---

# TerrenaLaravel — Base Standards

> Fuente de verdad única para todos los agentes. Cuando CLAUDE.md, GEMINI.md o codex.md entren en conflicto con este documento, este documento prevalece para principios generales; los archivos específicos de cada agente prevalecen para su configuración de rol y herramientas.

---

## 1. Principios Core

- **Una tarea a la vez**: Trabajar en baby steps. Nunca avanzar más de un paso sin confirmar que el anterior es correcto.
- **Spec primero, código después**: Ante cualquier cambio, actualizar primero los artefactos de spec (proposal, tasks.md, scenarios) y luego codear. Nunca hacer fix directo de código sin actualizar la spec.
- **TDD cuando aplica**: Iniciar con tests que fallen para cualquier funcionalidad nueva, según los detalles de la tarea.
- **Nombrado claro**: Variables, funciones y clases con nombres descriptivos que no requieran comentario.
- **Cambios incrementales**: Preferir cambios pequeños y enfocados sobre modificaciones grandes y complejas.
- **Cuestionar suposiciones**: Siempre cuestionar supuestos e inferencias antes de implementar.
- **Detección de patrones**: Detectar y señalar código repetido antes de agregar más del mismo.

---

## 2. Idioma

- **Código en inglés**: Variables, funciones, clases, comentarios de código, mensajes de error, logs.
- **Commits en inglés**: Títulos y cuerpo de commits siempre en inglés.
- **Documentación técnica**: `docs/`, `ai-specs/`, specs de OpenSpec — en inglés.
- **Comunicación con el usuario**: En español (el usuario es hispanohablante).
- **Blade/UI**: Textos de interfaz en español (el sistema es para uso local en México).

---

## 3. Estándares por área

| Área | Documento de referencia |
|------|------------------------|
| Arquitectura y módulos | `CLAUDE.md` — sección Architecture |
| Base de datos dual-schema | `CLAUDE.md` — sección Dual Database Architecture |
| Pipeline de UOM | `.claude/skills/terrena-context/SKILL.md` |
| API responses y backend | `docs/backend-standards.md` |
| Livewire, Blade, Bootstrap | `docs/frontend-standards.md` |
| Testing y simulaciones | `.claude/skills/terrena-simulate/SKILL.md` |
| Coordinación multi-agente | `.claude/skills/terrena-agent-protocol/SKILL.md` |
| Documentación técnica | `docs/documentation-standards.md` |

---

## 4. Skills del proyecto

- Los skills viven en `.claude/skills/`.
- Cuando una solicitud corresponda a un skill disponible, cargarlo y seguirlo antes de cualquier otra acción.
- También cargar archivos referenciados dentro del skill (ej. `references/*.md`) cuando el skill los requiera.

**Skills disponibles:**

| Skill | Cuándo usarlo |
|-------|---------------|
| `terrena-context` | Al iniciar cualquier tarea en TerrenaLaravel |
| `terrena-agent-protocol` | Al coordinar múltiples agentes en paralelo |
| `terrena-simulate` | Para validar lógica de inventario sin tocar producción |
| `adversarial-review` | Post-implementación, antes de archivar un change |
| `enrich-us` | Antes de implementar — enriquecer tarea con detalle técnico |
| `commit` | Para crear commits y PRs estandarizados |
| `code-auditing` | Auditorías de calidad, seguridad, deuda técnica |
| `explain` | Para explicar conceptos con modelo mental |
| `update-docs` | Después de cada cambio — actualizar documentación |
| `opsx:propose` | Proponer un nuevo change con todos sus artefactos |
| `opsx:apply` | Implementar tasks de un change |
| `opsx:archive` | Archivar un change completo |

---

## 5. Modelo para planeación (Planning Model)

Los workflows de planeación deben correr con **Claude Opus** (razonamiento amplio).

Aplica a:
- `enrich-us`
- `opsx:propose`
- `superpowers:writing-plans`
- `superpowers:brainstorming`

Antes de iniciar estos workflows, verificar que la sesión usa Opus. Si no, cambiar el modelo antes de continuar.

---

## 6. Ciclo de vida de un change (spec-driven)

```
enrich-us          → definir bien la tarea antes de codear
opsx:propose       → generar proposal + design + tasks.md
opsx:apply         → implementar task por task
adversarial-review → atacar la implementación desde perspectiva adversarial
commit             → commit + PR estandarizado
update-docs        → actualizar docs/ afectados
opsx:archive       → archivar el change
```

**Regla crítica**: Cuando aparezca un fix o cambio después de `opsx:apply` y antes de `opsx:archive`, tratarlo como actualización de spec, no como fix informal:
1. Actualizar artefactos del change afectados (scenarios, specs, tasks.md)
2. Luego implementar código
3. Re-verificar contra artefactos actualizados antes de archivar

---

## 7. Testing — el agente ejecuta, nunca delega

El agente de IA **DEBE ejecutar todos los tests él mismo**. Nunca pedirle al usuario que corra tests, comandos curl, o pruebas E2E.

**Para considerar una tarea completada, el agente debe haber:**
1. Ejecutado los unit tests relevantes y verificado que pasan
2. Probado endpoints con curl (para cambios en API)
3. Verificado el estado de la base de datos antes y después
4. Restaurado el estado de la DB si se crearon/modificaron/borraron registros de prueba
5. Documentado los resultados

Ver `docs/openspec-tasks-mandatory-steps.md` para el proceso completo de testing.

---

## 8. Reglas críticas de TerrenaLaravel

- **Schema `public` es READ-ONLY**: FloreantPOS production. Nunca escribir, alterar ni eliminar sin confirmación explícita del usuario.
- **Conexión PostgreSQL explícita**: Todo modelo que use PG debe tener `protected $connection = 'pgsql'` y tabla con prefijo `selemti.`.
- **UOM en base units**: Todo `mov_inv` e `inventory_batch` DEBE estar en unidades base (KG, L, PZ). Usar `UomConversionService::resolveToBase()`.
- **Transacciones en operaciones multi-tabla**: Siempre usar `DB::transaction()`.
- **Layout correcto**: `terrena.blade.php` para Bootstrap 5 (nuevo). `app.blade.php` solo para legacy Tailwind.
- **URLs con named routes**: Nunca hardcodear URLs. El proyecto corre en subdirectorio `/TerrenaLaravel`.

---

## 9. Integridad de symlinks y portabilidad multi-agente

- **Fuente canónica**: Los artefactos reutilizables viven en `ai-specs/` o `.claude/skills/`.
- Los archivos de configuración de cada agente (CLAUDE.md, GEMINI.md) no duplican contenido — referencian este documento.
- Cuando se renombra o mueve un archivo referenciado, actualizar todas las referencias antes de dar el cambio por completo.

---

## 10. Actualización de este documento

Este documento se actualiza cuando:
- El usuario corrige un comportamiento del agente (feedback explícito o implícito)
- Se establece una nueva convención de equipo
- Se agrega un nuevo skill o herramienta al proyecto

Usar el skill `claude-md-management:revise-claude-md` para capturar aprendizajes de la sesión.
