# 🤖 ÍNDICE DE DELEGACIÓN A IAs

**Última actualización**: 31 de octubre de 2025

---

## 🎯 Propósito

Instrucciones claras para delegar tareas a IAs (Claude, Qwen, ChatGPT) de forma eficiente y con resultados consistentes.

---

## 📚 Documentos Disponibles

| Documento | Descripción | Estado |
|-----------|-------------|--------|
| `PROMPTS_CLAUDE.md` | Prompts específicos y contexto para Claude | ⏳ Por crear |
| `PROMPTS_QWEN.md` | Prompts específicos y contexto para Qwen | ⏳ Por crear |
| `TAREAS_BACKEND.md` | Tareas delegables para backend (services, models, API) | ⏳ Por crear |
| `TAREAS_FRONTEND.md` | Tareas delegables para frontend (Livewire, Blade, JS) | ⏳ Por crear |
| `CHECKLIST_VALIDACION.md` | Cómo validar el trabajo generado por IA | ⏳ Por crear |

---

## 🎯 Principios de Delegación

### ✅ Buenas Tareas para IA
- Crear componentes Blade siguiendo design system
- Generar endpoints API RESTful
- Escribir tests unitarios
- Crear migraciones/seeders
- Documentar código existente
- Refactorizar siguiendo patrones

### ❌ Malas Tareas para IA
- Decisiones arquitectónicas complejas
- Lógica de negocio crítica sin specs
- Debugging de problemas complejos (mejor pair programming)
- Optimización de performance sin métricas

---

## 📋 Template de Delegación

```markdown
### Tarea: {Nombre}

**Contexto**:
- Módulo: {módulo}
- Fase: {fase del roadmap}
- Dependencias: {otros módulos/componentes}

**Objetivo**:
{Descripción clara del resultado esperado}

**Specs Técnicas**:
- Modelos involucrados: {...}
- Rutas/Endpoints: {...}
- Validaciones: {...}
- Permisos: {...}

**Criterios de Aceptación**:
- [ ] Funcionalidad X implementada
- [ ] Tests pasando
- [ ] Documentación actualizada

**Referencias**:
- Código similar: {...}
- Documentación: {...}

**Estimación**: {XS|S|M|L|XL}
```

---

## 🔄 Workflow de Delegación

1. **Seleccionar tarea** de `TAREAS_{BACKEND|FRONTEND}.md`
2. **Preparar contexto** con docs relevantes de MASTER/
3. **Ejecutar con IA** usando prompts específicos
4. **Validar resultado** con `CHECKLIST_VALIDACION.md`
5. **Integrar** y commitear
6. **Actualizar documentación** si necesario

---

## 🎯 Prioridad de Creación

1. **🔴 CRÍTICO** (Crear esta semana)
   - `TAREAS_FRONTEND.md` - Necesario para Fase 2 (Design System)
   - `CHECKLIST_VALIDACION.md` - Asegurar calidad

2. **🟡 ALTO** (Crear próxima semana)
   - `PROMPTS_CLAUDE.md` - Optimizar interacciones
   - `TAREAS_BACKEND.md` - Acelerar desarrollo backend

---

**Mantenido por**: Equipo TerrenaLaravel
