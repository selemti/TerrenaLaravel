# Delegación de Tareas - Refactorización de Reportes
**Fecha**: 28 de noviembre de 2025
**Coordinador**: Claude Code
**Estado**: 🟢 Activo

---

## 📊 RESUMEN EJECUTIVO

Delegación de trabajo multi-agente para refactorizar los **3 reportes más complejos** del sistema siguiendo el patrón exitoso de `ItemModsReportService`.

**Objetivo**: Reducir ~100KB de código a servicios limpios y mantenibles.

---

## 🤝 DIVISIÓN DE RESPONSABILIDADES

### 1. QWEN - Análisis y Documentación
**Archivo de tarea**: `QWEN_TASK_REPORTES_ANALISIS.md`

**Responsabilidad**:
- 📖 Analizar 3 controladores grandes (42KB, 35KB, 26KB)
- 📝 Documentar lógica de negocio
- 🔍 Identificar problemas y oportunidades
- 📋 Crear plan de refactorización para CODEX

**Entregables**:
- `docs/CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md`
- `docs/CODE_REVIEW/SALES_DETAIL_ANALYSIS.md`
- `docs/CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md`

**Tiempo**: 4-6 horas
**Tipo**: SOLO lectura y documentación (NO código)

---

### 2. CODEX - Refactorización e Implementación
**Archivo de tarea**: `CODEX_TASK_REPORTES_REFACTOR.md`

**Responsabilidad**:
- 🏗️ Crear 3 Service layers siguiendo patrón ItemModsReportService
- ✂️ Reducir controladores de ~40KB a <200 líneas
- 🔧 Optimizar queries usando Query Builder
- ✅ Validar compatibilidad 100%
- 📝 Documentar refactorización

**Entregables**:
- 3 Services: `app/Services/Reports/*ReportService.php`
- 3 Controllers refactorizados
- 3 Exports actualizados
- 3 Documentos: `docs/REPORTS/*_REFACTOR.md`
- 3 Pull Requests separados

**Tiempo**: 10-13 horas
**Tipo**: Código backend (espera análisis de QWEN)

---

### 3. Claude Code - Coordinación
**Responsabilidad**:
- 📋 Crear prompts detallados para QWEN y CODEX
- 🔍 Revisar y validar entregables
- ✅ Aprobar Pull Requests
- 📊 Monitorear progreso
- 🎯 Asegurar calidad final

**Minimización de tokens**: Delegar ejecución a otros agentes

---

## 🎯 REPORTES OBJETIVO

| # | Reporte | Tamaño | QWEN | CODEX | Prioridad |
|---|---------|--------|------|-------|-----------|
| 1 | SalesExceptionsController | 42KB | Analizar | Refactor | 🔴 Urgente |
| 2 | SalesDetailController | 35KB | Analizar | Refactor | 🔴 Urgente |
| 3 | SalesSummaryController | 26KB | Analizar | Refactor | 🟡 Alta |
| **Total** | **3 reportes** | **103KB** | **3 análisis** | **3 refactors** | |

---

## 📅 TIMELINE

### Semana 1 (28 Nov - 4 Dic)

**Día 1-2: QWEN - Análisis**
- [x] Recibir tarea
- [ ] Analizar SalesExceptionsController
- [ ] Analizar SalesDetailController
- [ ] Analizar SalesSummaryController
- [ ] Entregar 3 análisis completos

**Día 3: Claude Code - Revisión**
- [ ] Revisar análisis de QWEN
- [ ] Dar feedback si es necesario
- [ ] Aprobar análisis
- [ ] Notificar a CODEX para comenzar

### Semana 2 (5-11 Dic)

**Día 4-6: CODEX - Refactor #1 (Exceptions)**
- [ ] Leer análisis de QWEN
- [ ] Crear SalesExceptionsReportService
- [ ] Refactorizar controller
- [ ] Actualizar export
- [ ] Validar con datos reales
- [ ] Documentar
- [ ] Crear PR #1

**Día 7-8: Claude Code - Revisión PR #1**
- [ ] Revisar código de CODEX
- [ ] Probar funcionalidad
- [ ] Aprobar o solicitar cambios
- [ ] Merge a main

### Semana 3 (12-18 Dic)

**Día 9-11: CODEX - Refactor #2 (Detail)**
- [ ] Crear SalesDetailReportService
- [ ] Refactorizar controller
- [ ] Validar
- [ ] Crear PR #2

**Día 12-13: CODEX - Refactor #3 (Summary)**
- [ ] Crear SalesSummaryReportService
- [ ] Refactorizar controller
- [ ] Validar
- [ ] Crear PR #3

**Día 14: Claude Code - Revisión Final**
- [ ] Revisar PRs #2 y #3
- [ ] Aprobar y merge
- [ ] Validación final del sistema
- [ ] Documentar lecciones aprendidas

---

## 📏 MÉTRICAS DE ÉXITO

### Código
- ✅ Controladores < 200 líneas cada uno (de 42KB, 35KB, 26KB)
- ✅ 3 Service layers creados
- ✅ 100% de queries usando Query Builder
- ✅ 0 breaking changes

### Documentación
- ✅ 3 análisis completos (QWEN)
- ✅ 3 documentos de refactorización (CODEX)
- ✅ Patrón replicable establecido

### Testing
- ✅ Funcionalidad validada con datos reales
- ✅ Exports funcionan igual
- ✅ KPIs coinciden con versión anterior

---

## 🔗 DEPENDENCIAS

```
QWEN Análisis
    ↓
    ├─→ SALES_EXCEPTIONS_ANALYSIS.md
    ├─→ SALES_DETAIL_ANALYSIS.md
    └─→ SALES_SUMMARY_ANALYSIS.md
        ↓
Claude Code Revisión
        ↓
CODEX Refactorización
        ↓
        ├─→ PR #1: Exceptions
        ├─→ PR #2: Detail
        └─→ PR #3: Summary
            ↓
Claude Code Aprobación
            ↓
✅ Merge a main
```

---

## 📋 CHECKLIST GENERAL

### QWEN - Análisis
- [ ] Leer QWEN_TASK_REPORTES_ANALISIS.md
- [ ] Analizar SalesExceptionsController.php
- [ ] Analizar SalesDetailController.php
- [ ] Analizar SalesSummaryController.php
- [ ] Crear 3 archivos markdown de análisis
- [ ] Notificar completado

### Claude Code - Revisión Análisis
- [ ] Recibir notificación de QWEN
- [ ] Leer 3 análisis
- [ ] Validar completitud
- [ ] Dar feedback o aprobar
- [ ] Notificar a CODEX

### CODEX - Refactorización
- [ ] Leer CODEX_TASK_REPORTES_REFACTOR.md
- [ ] Leer 3 análisis de QWEN
- [ ] Estudiar ItemModsReportService (patrón)
- [ ] Refactor SalesExceptionsController + Service
- [ ] Refactor SalesDetailController + Service
- [ ] Refactor SalesSummaryController + Service
- [ ] Crear 3 PRs separados
- [ ] Notificar completado

### Claude Code - Revisión Final
- [ ] Revisar PR #1 (Exceptions)
- [ ] Revisar PR #2 (Detail)
- [ ] Revisar PR #3 (Summary)
- [ ] Validar con datos reales
- [ ] Aprobar y merge
- [ ] Actualizar docs/REPORTS/README.md

---

## 🎓 LECCIONES APRENDIDAS (ItemModsReport)

### ✅ Qué funcionó bien
1. **Service Layer separado**: Lógica desacoplada del controller
2. **Query Builder**: Queries optimizados y testables
3. **Múltiples vistas**: fetch() con diferentes modos
4. **Filtros centralizados**: branch, terminal, dates
5. **KPIs calculados**: summarize() independiente
6. **Tests completos**: 11 tests de integración

### ⚠️ Qué evitar
1. SQL crudo (DB::select) - usar Query Builder
2. Lógica en controlador - mover a servicio
3. Queries en exports - recibir datos procesados
4. Código duplicado - extraer a métodos
5. Hard-coded values - usar constantes

### 🔄 Patrón a replicar
```
Controller (< 200 líneas)
    → Service (fetch + summarize)
        → Query Builder
            → PostgreSQL
```

---

## 📞 COMUNICACIÓN

### QWEN → Claude Code
**Canal**: Commit + notificación en PR
**Mensaje**: "QWEN: Análisis completado - 3 archivos en docs/CODE_REVIEW/"

### Claude Code → CODEX
**Canal**: GitHub comment en issue
**Mensaje**: "CODEX: Análisis aprobado, puedes comenzar refactorización"

### CODEX → Claude Code
**Canal**: Pull Request
**Mensaje**: "CODEX: PR #{n} listo - {Nombre} refactorizado"

---

## 🚨 ESCALACIÓN

Si hay problemas:

1. **QWEN bloqueado**: Claude Code ayuda con análisis difícil
2. **CODEX bloqueado**: Claude Code revisa y da feedback
3. **Breaking changes**: Claude Code interviene y coordina fix
4. **Timeline en riesgo**: Re-priorizar o extender

---

## 📊 PROGRESO ACTUAL

**Estado**: 🟡 En espera de QWEN

| Agente | Tarea | Estado | Progreso |
|--------|-------|--------|----------|
| Claude Code | Delegación | ✅ Completo | 100% |
| QWEN | Análisis | ⏳ Pendiente | 0% |
| CODEX | Refactorización | ⏸️ Esperando | 0% |

**Última actualización**: 28-Nov-2025 14:00

---

## 📁 ARCHIVOS DE COORDINACIÓN

```
docs/AI_COORDINATION/
├── DELEGACION_REPORTES.md (este archivo)
├── QWEN_TASK_REPORTES_ANALISIS.md (prompt para QWEN)
└── CODEX_TASK_REPORTES_REFACTOR.md (prompt para CODEX)

docs/CODE_REVIEW/ (QWEN creará aquí)
├── SALES_EXCEPTIONS_ANALYSIS.md
├── SALES_DETAIL_ANALYSIS.md
└── SALES_SUMMARY_ANALYSIS.md

docs/REPORTS/ (CODEX creará aquí)
├── SALES_EXCEPTIONS_REFACTOR.md
├── SALES_DETAIL_REFACTOR.md
└── SALES_SUMMARY_REFACTOR.md
```

---

**Creado por**: Claude Code
**Fecha**: 28-Nov-2025
**Versión**: 1.0
**Próxima revisión**: Cuando QWEN complete análisis
