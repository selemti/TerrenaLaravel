# Plan Maestro: Consolidación Diaria de Ventas + Refactorización de Reportes
**Fecha**: 28 de noviembre de 2025
**Coordinador**: Claude Code
**Estado**: 📋 **PLANIFICACIÓN COMPLETA**

---

## 🎯 VISIÓN GENERAL

Plan integral para mejorar el sistema de reportes de ventas mediante:
1. **Refactorización** de 3 controladores grandes (42KB, 35KB, 26KB) → Service layers
2. **Consolidación Diaria** de ventas (Data Mart) → 95% mejora en performance

**Objetivo final**: Reportes rápidos, escalables y mantenibles que soporten análisis históricos de años.

---

## 📊 ESTADO ACTUAL

### ✅ Completado por Claude Code

| Fase | Descripción | Estado | Archivos Generados |
|------|-------------|--------|-------------------|
| **1. ItemMods Report** | Service layer implementado y validado | ✅ Completo | ItemModsReportService.php + 11 tests |
| **2. Documentación** | README de 14 reportes del sistema | ✅ Completo | docs/REPORTS/README.md |
| **3. Delegación Inicial** | Prompts para refactorización | ✅ Completo | QWEN_TASK_REPORTES_ANALISIS.md, CODEX_TASK_REPORTES_REFACTOR.md |
| **4. Estrategia Consolidación** | Arquitectura Data Mart | ✅ Completo | DAILY_SALES_CONSOLIDATION_STRATEGY.md |
| **5. Delegación Consolidación** | Prompts técnicos detallados | ✅ Completo | QWEN_TASK_CONSOLIDATION_ANALYSIS.md, CODEX_TASK_CONSOLIDATION_IMPLEMENTATION.md |

### ✅ Completado por QWEN

| Tarea | Estado | Archivos Generados |
|-------|--------|-------------------|
| **Análisis de 3 reportes grandes** | ✅ Completo | SALES_EXCEPTIONS_ANALYSIS.md (8.8KB), SALES_DETAIL_ANALYSIS.md (8.5KB), SALES_SUMMARY_ANALYSIS.md (8KB) |

### ⏳ Pendiente

| Agente | Tarea | Estado | Tiempo Est. |
|--------|-------|--------|------------|
| **QWEN** | Análisis técnico de consolidación | ⏳ Pendiente | 4 horas |
| **CODEX** | Refactorización de 3 reportes | ⏸️ Esperando QWEN | 10-13 horas |
| **CODEX** | Implementación consolidación | ⏸️ Esperando análisis QWEN | 8-10 horas |

---

## 🗺️ ROADMAP COMPLETO

### Fase A: Refactorización de Reportes (PRIORIDAD 1)

```
┌─────────────────────────────────────────────────────────┐
│  QWEN - Análisis Técnico Consolidación                  │
│  Tarea: Validar estrategia y diseñar queries ETL        │
│  Archivo: CONSOLIDATION_TECHNICAL_ANALYSIS.md           │
│  Tiempo: 4 horas                                         │
│  Estado: ⏳ PENDIENTE                                    │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Refactor Reporte #1: SalesExceptions           │
│  Crear: SalesExceptionsReportService.php                │
│  Reducir: 42KB → < 200 líneas                           │
│  Tiempo: 4-5 horas                                       │
│  Estado: ⏸️ ESPERANDO ANÁLISIS QWEN                     │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code - Revisar PR #1                            │
│  Validar funcionalidad y aprobar merge                  │
│  Tiempo: 1 hora                                          │
│  Estado: ⏸️ ESPERANDO PR                                │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Refactor Reporte #2: SalesDetail               │
│  Crear: SalesDetailReportService.php                    │
│  Reducir: 35KB → < 200 líneas                           │
│  Tiempo: 4-5 horas                                       │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code - Revisar PR #2                            │
│  Validar y merge                                         │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Refactor Reporte #3: SalesSummary              │
│  Crear: SalesSummaryReportService.php                   │
│  Reducir: 26KB → < 200 líneas                           │
│  Tiempo: 2-3 horas                                       │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code - Revisar PR #3 y Cerrar Fase A            │
└─────────────────────────────────────────────────────────┘
```

**Tiempo total Fase A**: ~14-18 horas (distribuidas en 2-3 semanas)

---

### Fase B: Implementación de Consolidación Diaria (PRIORIDAD 2)

```
┌─────────────────────────────────────────────────────────┐
│  Prerrequisito: Fase A completada ✅                     │
│  + Análisis técnico QWEN completado ✅                   │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Infraestructura                                 │
│  Crear migración de 4 tablas consolidadas               │
│  Tiempo: 1 hora                                          │
│  Entregable: create_daily_sales_consolidation_tables    │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Service Layer                                   │
│  Implementar DailySalesConsolidationService              │
│  4 queries ETL según análisis QWEN                       │
│  Tiempo: 3 horas                                         │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Comando Laravel                                 │
│  ConsolidateDailySales command + scheduler               │
│  Tiempo: 1.5 horas                                       │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Backfill Histórico                              │
│  Consolidar 90 días: Sep 1 - Nov 27                     │
│  Tiempo: 1 hora                                          │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Validación                                      │
│  Probar comando, validar datos, performance              │
│  Tiempo: 1.5 horas                                       │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code - Revisar PR Consolidación                 │
│  Validar implementación y aprobar                        │
│  Tiempo: 2 horas                                         │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Fase B Completa: Data Mart Operacional ✅               │
└─────────────────────────────────────────────────────────┘
```

**Tiempo total Fase B**: ~10 horas (1-2 semanas)

---

### Fase C: Migración de Reportes a Consolidado (PRIORIDAD 3)

```
┌─────────────────────────────────────────────────────────┐
│  Prerrequisito: Fase B completada + 30 días operando ✅  │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Actualizar SalesMods Report                     │
│  Usar daily_item_sales + daily_modifier_sales            │
│  Performance: 15 seg → < 1 seg                           │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Actualizar SalesExceptions Report               │
│  Usar daily_sales_header para totales                   │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Actualizar SalesDetail Report                   │
│  Usar daily_item_sales + fallback a transaccional       │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  CODEX - Actualizar SalesSummary Report                  │
│  Usar daily_sales_header como fuente principal          │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Claude Code - Validación Performance                    │
│  Comparar antes/después, benchmarks                      │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Fase C Completa: Todos reportes optimizados ✅          │
└─────────────────────────────────────────────────────────┘
```

**Tiempo total Fase C**: ~6-8 horas (1 semana)

---

## 📁 ARCHIVOS DE COORDINACIÓN

### Estrategia y Documentación
```
docs/ARCHITECTURE/
├── DAILY_SALES_CONSOLIDATION_STRATEGY.md (✅ Completo - 28-Nov)
└── CONSOLIDATION_TECHNICAL_ANALYSIS.md (⏳ QWEN lo creará)

docs/REPORTS/
├── README.md (✅ Completo - 14 reportes documentados)
├── ITEMS_MODS_STRATEGY.md (✅ Completo - reporte de referencia)
└── CONSOLIDATION_IMPLEMENTATION.md (⏳ CODEX lo creará)
```

### Delegación de Tareas
```
docs/AI_COORDINATION/
├── PLAN_CONSOLIDACION_VENTAS.md (✅ Este archivo)
├── RESUMEN_EJECUTIVO.md (✅ Completo - resumen original)
│
├── QWEN_TASK_REPORTES_ANALISIS.md (✅ Completo - 3 análisis)
├── QWEN_TASK_CONSOLIDATION_ANALYSIS.md (✅ Completo - nuevo)
│
├── CODEX_TASK_REPORTES_REFACTOR.md (✅ Completo)
└── CODEX_TASK_CONSOLIDATION_IMPLEMENTATION.md (✅ Completo - nuevo)
```

### Análisis de QWEN
```
docs/CODE_REVIEW/
├── SALES_EXCEPTIONS_ANALYSIS.md (✅ Completo - 8.8KB)
├── SALES_DETAIL_ANALYSIS.md (✅ Completo - 8.5KB)
└── SALES_SUMMARY_ANALYSIS.md (✅ Completo - 8KB)
```

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

### Para QWEN (URGENTE)

**Tarea**: Análisis Técnico de Consolidación
**Archivo de instrucciones**: `docs/AI_COORDINATION/QWEN_TASK_CONSOLIDATION_ANALYSIS.md`
**Tiempo estimado**: 4 horas

**Qué hacer**:
1. Leer `DAILY_SALES_CONSOLIDATION_STRATEGY.md`
2. Explorar base de datos PostgreSQL con psql
3. Validar viabilidad de las 4 tablas propuestas
4. Diseñar queries ETL optimizados
5. Analizar casos especiales (misceláneos, descuentos 100%, etc.)
6. Crear `CONSOLIDATION_TECHNICAL_ANALYSIS.md`

**Entregable crítico**:
- Queries SQL validados para ETL
- Recomendaciones de índices
- Estimación de volumen de datos
- Identificación de riesgos

---

### Para CODEX (DESPUÉS DE QWEN)

**Tarea 1**: Refactorización de Reportes
**Archivo de instrucciones**: `docs/AI_COORDINATION/CODEX_TASK_REPORTES_REFACTOR.md`
**Tiempo estimado**: 10-13 horas
**Prerequisito**: ✅ QWEN completó análisis (ya hecho)

**Tarea 2**: Implementación de Consolidación
**Archivo de instrucciones**: `docs/AI_COORDINATION/CODEX_TASK_CONSOLIDATION_IMPLEMENTATION.md`
**Tiempo estimado**: 8-10 horas
**Prerequisito**: ⏳ QWEN complete análisis técnico de consolidación

---

### Para Claude Code (Coordinación)

**Tareas actuales**:
- ✅ Estrategia de consolidación definida
- ✅ Prompts detallados para QWEN y CODEX creados
- ✅ Plan maestro documentado

**Tareas futuras**:
- ⏸️ Revisar análisis técnico de QWEN
- ⏸️ Revisar y aprobar PRs de CODEX (3 refactors + 1 consolidación)
- ⏸️ Validar performance de consolidación con datos reales
- ⏸️ Coordinar migración de reportes a usar consolidado

---

## 📊 MÉTRICAS Y OBJETIVOS

### Refactorización de Reportes

| Reporte | Antes | Después | Objetivo |
|---------|-------|---------|----------|
| SalesExceptionsController | 42KB (896 líneas) | < 200 líneas | ✅ Reducir 78% |
| SalesDetailController | 35KB (~750 líneas) | < 200 líneas | ✅ Reducir 73% |
| SalesSummaryController | 26KB (~550 líneas) | < 200 líneas | ✅ Reducir 64% |

**Total**: ~2,196 líneas → ~600 líneas (73% reducción)

---

### Performance de Consolidación

| Operación | Antes (transaccional) | Después (consolidado) | Mejora |
|-----------|----------------------|----------------------|--------|
| Reporte 7 días | 5-10 seg | < 0.5 seg | 90-95% |
| Reporte 30 días | 15-30 seg | < 1 seg | 95-97% |
| Reporte 90 días | 45-90 seg | < 1.5 seg | 97-98% |
| Reporte 1 año | ❌ Inviable | < 3 seg | ∞ |

**Objetivo**: > 90% mejora en todos los casos

---

### Volumen de Datos (Estimado)

| Tabla | Registros/día | Registros/año | Tamaño (MB/año) |
|-------|---------------|---------------|----------------|
| daily_sales_header | ~10-15 | ~3,650-5,475 | ~0.5-1 MB |
| daily_item_sales | ~100-200 | ~36,500-73,000 | ~5-10 MB |
| daily_modifier_sales | ~50-100 | ~18,250-36,500 | ~3-5 MB |
| daily_misc_sales | ~10-30 | ~3,650-10,950 | ~0.5-1 MB |

**Total anual**: ~9-17 MB (extremadamente eficiente vs 100s de GBs transaccionales)

---

## ⏱️ TIMELINE COMPLETO

### Semana 1 (28 Nov - 4 Dic)
- **Día 1-2**: QWEN analiza consolidación técnica → `CONSOLIDATION_TECHNICAL_ANALYSIS.md`
- **Día 3**: Claude Code revisa análisis
- **Día 4-5**: CODEX refactoriza SalesExceptionsController → PR #1

### Semana 2 (5-11 Dic)
- **Día 6-7**: Claude Code revisa PR #1, CODEX ajusta
- **Día 8**: Merge PR #1
- **Día 9-10**: CODEX refactoriza SalesDetailController → PR #2
- **Día 11**: Claude Code revisa PR #2

### Semana 3 (12-18 Dic)
- **Día 12**: Merge PR #2
- **Día 13-14**: CODEX refactoriza SalesSummaryController → PR #3
- **Día 15**: Claude Code revisa PR #3
- **Día 16**: Merge PR #3
- **Día 17-18**: Buffer / ajustes

### Semana 4 (19-25 Dic - Navidad)
- **PAUSA** - No programar trabajo crítico

### Semana 5 (26 Dic - 1 Ene - Año Nuevo)
- **PAUSA** - No programar trabajo crítico

### Semana 6 (2-8 Ene)
- **Día 19-20**: CODEX implementa consolidación (migración + service)
- **Día 21**: CODEX crea comando Laravel + scheduler
- **Día 22**: CODEX hace backfill de 90 días

### Semana 7 (9-15 Ene)
- **Día 23-24**: CODEX valida y documenta
- **Día 25**: CODEX crea PR consolidación
- **Día 26-27**: Claude Code revisa y valida performance
- **Día 28**: Merge PR consolidación

### Semana 8+ (16 Ene+)
- **30 días operando**: Monitoreo de consolidación diaria
- **Migración de reportes**: Actualizar para usar consolidado
- **Optimizaciones**: Ajustes según comportamiento real

---

## 🚨 RIESGOS Y MITIGACIONES

### Riesgo 1: Análisis QWEN incompleto
- **Probabilidad**: Baja
- **Impacto**: Alto (bloquea CODEX)
- **Mitigación**: Prompts muy detallados, ejemplos claros, acceso a psql

### Riesgo 2: Refactorización rompe funcionalidad
- **Probabilidad**: Media
- **Impacto**: Alto
- **Mitigación**: Validación con datos reales, comparar outputs antes/después, tests

### Riesgo 3: Consolidación no mejora performance
- **Probabilidad**: Muy baja
- **Impacto**: Medio
- **Mitigación**: Benchmark antes de implementar, estrategia probada en la industria

### Riesgo 4: Datos consolidados incorrectos
- **Probabilidad**: Baja
- **Impacto**: Crítico
- **Mitigación**: Validación automatizada (compare transaccional vs consolidado), tests exhaustivos

### Riesgo 5: Timeline se extiende por festividades
- **Probabilidad**: Alta
- **Impacto**: Bajo
- **Mitigación**: Ya considerado en timeline (pausas en semanas 4-5)

---

## 💰 PRESUPUESTO DE TOKENS

### Tokens Utilizados (Claude Code)
```
Fase 1 (ItemMods + Tests):           ~40,000
Fase 2 (Documentación inicial):      ~10,000
Fase 3 (Commits):                     ~5,000
Fase 4 (Delegación reportes):        ~15,000
Fase 5 (Estrategia consolidación):   ~8,000
Fase 6 (Delegación consolidación):   ~15,000
─────────────────────────────────────────────
Total Claude Code:                    ~93,000 tokens
```

### Tokens Proyectados
```
QWEN (análisis consolidación):        ~10,000
CODEX (3 refactors):                  ~40,000
CODEX (consolidación):                ~25,000
Claude Code (revisiones):             ~20,000
─────────────────────────────────────────────
Total Proyecto:                       ~188,000 tokens
```

**Margen**: ~12,000 tokens (6% buffer) ✅ Bien dentro del límite de 200,000

---

## 📞 COMUNICACIÓN ENTRE AGENTES

### QWEN → Claude Code
**Cuando complete análisis técnico**:
- Commit `CONSOLIDATION_TECHNICAL_ANALYSIS.md`
- Mensaje: "QWEN: Análisis técnico de consolidación completado - validado con datos reales"

### CODEX → Claude Code
**Por cada PR**:
- Crear PR con branch `codex/refactor-{nombre}` o `codex/feature-consolidation`
- Mensaje: "CODEX: PR #{n} listo - {Reporte/Feature} refactorizado/implementado"
- Incluir evidencia de validación en PR description

### Claude Code → Usuario
**Actualizaciones regulares**:
- Después de merge de cada PR
- Al completar cada fase (A, B, C)
- Si hay blockers o riesgos

---

## 🎯 CRITERIOS DE ÉXITO FINALES

El proyecto será exitoso cuando:

### Refactorización (Fase A)
✅ 3 controladores reducidos a < 200 líneas cada uno
✅ 3 Service layers creados siguiendo patrón ItemModsReportService
✅ 100% funcionalidad mantenida (0 breaking changes)
✅ Código más mantenible y testeable

### Consolidación (Fase B)
✅ 4 tablas consolidadas creadas con índices
✅ Service ETL funcionando sin errores
✅ Consolidación diaria automática a las 3:00 AM
✅ 90 días históricos consolidados
✅ Validación muestra 100% match con datos transaccionales
✅ Performance > 90% mejora demostrada

### Migración (Fase C)
✅ Reportes principales usando consolidado
✅ Fallback a transaccional funcionando
✅ Performance global del sistema mejorada
✅ Reportes anuales viables

---

## 📚 REFERENCIAS

### Documentación Clave
- [Estrategia de Consolidación](../ARCHITECTURE/DAILY_SALES_CONSOLIDATION_STRATEGY.md)
- [README de Reportes](../REPORTS/README.md)
- [Patrón ItemMods](../REPORTS/ITEMS_MODS_STRATEGY.md)

### Prompts de Delegación
- [QWEN - Análisis Reportes](QWEN_TASK_REPORTES_ANALISIS.md) ✅
- [QWEN - Análisis Consolidación](QWEN_TASK_CONSOLIDATION_ANALYSIS.md) ⏳
- [CODEX - Refactor Reportes](CODEX_TASK_REPORTES_REFACTOR.md) ⏸️
- [CODEX - Implementar Consolidación](CODEX_TASK_CONSOLIDATION_IMPLEMENTATION.md) ⏸️

### Análisis Técnicos
- [SalesExceptions Analysis](../CODE_REVIEW/SALES_EXCEPTIONS_ANALYSIS.md) ✅
- [SalesDetail Analysis](../CODE_REVIEW/SALES_DETAIL_ANALYSIS.md) ✅
- [SalesSummary Analysis](../CODE_REVIEW/SALES_SUMMARY_ANALYSIS.md) ✅
- [Consolidation Technical Analysis](../ARCHITECTURE/CONSOLIDATION_TECHNICAL_ANALYSIS.md) ⏳

---

**Creado por**: Claude Code
**Fecha**: 28-Nov-2025
**Versión**: 1.0
**Próxima actualización**: Cuando QWEN complete análisis técnico

---

## 🏁 RESUMEN PARA USUARIO

**Lo que se ha logrado hoy**:
1. ✅ Estrategia completa de consolidación diaria definida
2. ✅ Prompts detallados para QWEN y CODEX creados
3. ✅ Plan maestro documentado con timeline de 8+ semanas
4. ✅ Coordinación multi-agente establecida

**Lo que sigue**:
1. ⏳ QWEN analiza la estrategia técnicamente (4 horas)
2. ⏸️ CODEX refactoriza 3 reportes (10-13 horas)
3. ⏸️ CODEX implementa consolidación (8-10 horas)
4. ⏸️ Claude Code revisa y valida todo

**Tu rol**:
- Iniciar QWEN con el prompt cuando estés listo
- Revisar PRs de CODEX (opcional, Claude Code lo hará)
- Aprobar merges finales

**Resultado final esperado**:
- Reportes 95% más rápidos
- Código 73% más limpio
- Sistema escalable para años de datos

🎉 **Todo listo para ejecutar el plan**
