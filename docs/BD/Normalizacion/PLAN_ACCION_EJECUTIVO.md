# Plan de Acción Ejecutivo - Mejoras BD selemti
**Proyecto**: TerrenaLaravel - Conversión a ERP Enterprise Grade
**Fecha**: 30 de octubre de 2025
**Estado**: En Progreso (Phase 1 Completada ✅)

---

## 🎯 Objetivo

Transformar la base de datos `selemti` de un sistema funcional pero fragmentado a un **ERP de restaurantes de clase enterprise** con:

- ✅ Integridad referencial completa
- ✅ Auditoría universal
- ✅ Performance optimizado
- ✅ Escalabilidad multi-tenant
- ✅ Zero downtime deployments

---

## 📊 Estado Actual vs Objetivo

| Aspecto | Actual | Objetivo | Progreso |
|---------|--------|----------|----------|
| Tablas con FKs completas | 55% | 100% | ████░░░░░░ 40% |
| Tablas con auditoría | 30% | 100% | ███░░░░░░░ 30% |
| Sistemas consolidados | 50% | 100% | ████░░░░░░ 40% |
| Índices estratégicos | 65% | 100% | ███████░░░ 70% |
| Performance queries | 70% | 95% | ██████░░░░ 60% |

---

## 🚀 Fases de Implementación

### ✅ FASE 1: Fundamentos (COMPLETADA)
**Duración**: 1 día
**Estado**: ✅ 100% Completada

#### Logros:
1. ✅ Consolidación de unidades de medida
   - Tabla canónica: `unidades_medida_legacy`
   - 22 unidades migradas
   - Vistas de compatibilidad creadas

2. ✅ Corrección de `inventory_snapshot`
   - Tipo cambiado: UUID → VARCHAR(20)
   - FK añadida: `inventory_snapshot.item_id` → `items.id`

3. ✅ FKs críticas iniciales
   - `pos_map` → `receta_cab`
   - `purchase_orders` → `cat_proveedores`
   - `inventory_snapshot` → `items`

#### Documentación:
- ✅ 4 scripts SQL ejecutados
- ✅ Reporte de verificación
- ✅ Checks de integridad pasados

---

### 🟡 FASE 2: Consolidación de Sistemas (EN PREPARACIÓN)
**Duración**: 3-4 semanas
**Estado**: 🟡 Scripts en generación

#### Objetivo:
Eliminar duplicación de sistemas legacy vs nuevo, consolidando en un único sistema coherente.

#### Submódulos:

##### **2.1 Consolidar Usuarios** (Semana 1)
**Tablas afectadas**:
- `usuario` (legacy) → `users` (canónico)
- `rol` (legacy) → `roles` (canónico)

**Trabajo**:
1. Migrar datos de `usuario` → `users`
2. Migrar `rol` → `roles`
3. Actualizar 18 FKs en tablas dependientes
4. Crear vistas de compatibilidad `v_usuario`, `v_rol`
5. Tests de integridad

**Impacto**: Alto - Sistema de autenticación
**Riesgo**: Medio - Requiere testing exhaustivo
**Rollback**: Disponible via vistas

##### **2.2 Consolidar Sucursales/Almacenes** (Semana 1-2)
**Tablas afectadas**:
- `sucursal` (legacy) → `cat_sucursales` (canónico)
- `bodega` + `almacen` (legacy) → `cat_almacenes` (canónico)

**Trabajo**:
1. Migrar `sucursal` → `cat_sucursales`
2. Unificar `bodega` + `almacen` → `cat_almacenes`
3. Actualizar 22 FKs
4. Crear vistas de compatibilidad
5. Tests de integridad

**Impacto**: Alto - Afecta inventario y ventas
**Riesgo**: Alto - Muchas dependencias
**Rollback**: Disponible via vistas

##### **2.3 Consolidar Items** (Semana 2-3)
**Tablas afectadas**:
- `insumo` (legacy) → `items` (canónico)
- `lote` (legacy) → `inventory_batch` (canónico)

**Trabajo**:
1. Migrar `insumo` → `items`
2. Migrar `lote` → `inventory_batch`
3. Actualizar 15+ FKs
4. Consolidar tablas relacionadas
5. Tests de integridad exhaustivos

**Impacto**: CRÍTICO - Corazón del inventario
**Riesgo**: Muy Alto - Requiere plan detallado
**Rollback**: Complejo - Backup crítico

##### **2.4 Consolidar Recetas** (Semana 3-4)
**Tablas afectadas**:
- `receta` (legacy) → `receta_cab` (canónico)
- `receta_insumo` (legacy) → `receta_det` (canónico)

**Trabajo**:
1. Migrar `receta` → `receta_cab`
2. Consolidar `receta_insumo` → `receta_det`
3. Actualizar sistema de versiones
4. Tests de costeo

**Impacto**: Alto - Sistema de producción
**Riesgo**: Medio - Depends de consolidación de items
**Rollback**: Disponible

#### Entregables Fase 2:
- [ ] 4 scripts de migración SQL
- [ ] Plan de rollback por submódulo
- [ ] Suite de tests de integridad
- [ ] Documentación de mapeos
- [ ] Vistas de compatibilidad
- [ ] Reporte de verificación final

---

### ⏭️ FASE 3: Integridad y Auditoría (PENDIENTE)
**Duración**: 2-3 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
- FKs completas en 100% de tablas transaccionales
- Auditoría universal (created_at, updated_at, created_by, deleted_at)
- Soft deletes implementados

#### Trabajo Principal:
1. Corregir 7 incompatibilidades de tipos
2. Añadir ~15 FKs faltantes
3. Añadir campos de auditoría a 82 tablas
4. Implementar soft deletes
5. Crear triggers para `updated_at`

#### Entregables:
- [ ] Scripts de corrección de tipos
- [ ] Scripts de FKs faltantes
- [ ] Scripts de auditoría universal
- [ ] Triggers automáticos
- [ ] Tests de compliance

---

### ⏭️ FASE 4: Optimización Performance (PENDIENTE)
**Duración**: 2 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
- 95% de queries <100ms
- Índices estratégicos completos
- Particionamiento de tablas históricas

#### Trabajo Principal:
1. Añadir 25 índices estratégicos
2. Particionar `mov_inv`, `audit_log` por fecha
3. Optimizar PKs compuestas
4. Query profiling y tuning

#### Entregables:
- [ ] Scripts de índices
- [ ] Scripts de particionamiento
- [ ] Benchmark antes/después
- [ ] Plan de mantenimiento

---

### ⏭️ FASE 5: Funcionalidades Enterprise (PENDIENTE)
**Duración**: 3-4 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
- Multi-tenant ready
- Event sourcing
- Data warehouse para reporting

#### Trabajo Principal:
1. Implementar multi-tenancy con RLS
2. Event store para auditoría avanzada
3. ETL a data warehouse separado

#### Entregables:
- [ ] Arquitectura multi-tenant
- [ ] Event sourcing framework
- [ ] Data warehouse schema
- [ ] ETL pipelines

---

## 📅 Timeline General

```
Noviembre 2025
├── Semana 1: Phase 2.1 (Usuarios)
├── Semana 2: Phase 2.2 (Sucursales/Almacenes)
├── Semana 3: Phase 2.3 (Items)
└── Semana 4: Phase 2.4 (Recetas)

Diciembre 2025
├── Semana 1-2: Phase 3 (Integridad + Auditoría)
└── Semana 3-4: Phase 4 (Performance)

Enero 2026
├── Semana 1-4: Phase 5 (Enterprise Features)
└── Semana 5: Testing final + Go Live
```

**Duración total estimada**: **10-14 semanas**

---

## 🎯 Métricas de Éxito (KPIs)

### Performance
- [ ] 95% de queries <100ms (actual: 70%)
- [ ] Zero queries >1s (actual: ~15%)
- [ ] Throughput 1000 TPS (actual: ~200 TPS)

### Calidad de Datos
- [ ] 100% FKs en tablas transaccionales (actual: 55%)
- [ ] 0% datos huérfanos (actual: ~5%)
- [ ] 100% auditoría (actual: 30%)

### Escalabilidad
- [ ] Multi-tenant capable
- [ ] Soportar 50+ sucursales simultáneas
- [ ] 10M+ transacciones/mes

### Operaciones
- [ ] Zero downtime deployments
- [ ] RPO <5 minutos
- [ ] RTO <30 minutos

---

## ⚠️ Riesgos Identificados

### Riesgo Alto (R1-R2)
| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|----|--------|---------|--------------|------------|
| R1 | Downtime prolongado | Alto | Media | Ventanas mantenimiento + rollback |
| R2 | Pérdida de datos | Crítico | Baja | Backups + dry-run staging |

### Riesgo Medio (R3-R5)
| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|----|--------|---------|--------------|------------|
| R3 | Incompatibilidad código | Medio | Alta | Vistas compatibilidad |
| R4 | Performance degradation | Medio | Media | Testing carga + monitoreo |
| R5 | Resistencia al cambio | Bajo | Media | Capacitación + docs |

---

## 📦 Entregables por Fase

### Fase 1 (Completada ✅)
- [x] Scripts SQL 01-04
- [x] Reporte de verificación
- [x] Análisis exhaustivo
- [x] Plan de acción ejecutivo

### Fase 2 (En Preparación 🟡)
- [ ] Scripts SQL 05-12 (consolidación)
- [ ] Plan de rollback
- [ ] Suite de tests
- [ ] Documentación mapeos

### Fase 3-5 (Pendiente 🔵)
- [ ] Scripts SQL 13-25
- [ ] Benchmarks
- [ ] Documentación técnica
- [ ] Guías operacionales

---

## 👥 Equipo Necesario

**Roles**:
- **Backend Senior Lead** (40h/semana) - Coordinación general
- **DBA PostgreSQL** (30h/semana) - Scripts SQL + tuning
- **QA Engineer** (20h/semana) - Tests + validación
- **DevOps** (10h/semana) - Staging + deploy

**Total horas estimadas**: **3,500 horas** (4 personas x 14 semanas x 62.5h promedio)

---

## 💰 Presupuesto Estimado

| Concepto | Costo Mensual | Total |
|----------|---------------|-------|
| Infraestructura staging | $200 | $700 |
| Herramientas (monitoring, backup) | $150 | $525 |
| Capacitación equipo | - | $2,000 |
| **Total** | **$350/mes** | **$3,225** |

*No incluye costos de personal (in-house)*

---

## 📞 Puntos de Decisión

### Decisión 1: ¿Iniciar Fase 2?
**Fecha límite**: 5 de noviembre de 2025
**Requisitos previos**:
- ✅ Phase 1 completada
- ⏳ Staging environment ready
- ⏳ Equipo asignado
- ⏳ Plan de rollback aprobado

### Decisión 2: ¿Go/No-Go Production?
**Fecha límite**: Fin de Fase 2
**Criterios**:
- [ ] Todos los tests pasados
- [ ] Performance aceptable
- [ ] Rollback testeado
- [ ] Sign-off de stakeholders

---

## 🚦 Estado Actual del Plan

**Última actualización**: 30 de octubre de 2025

| Fase | Estado | Progreso | Próximo Hito |
|------|--------|----------|--------------|
| Fase 1 | ✅ Completada | 100% | - |
| Fase 2 | 🟡 Preparación | 10% | Scripts generados |
| Fase 3 | 🔵 Pendiente | 0% | Inicio Fase 2 |
| Fase 4 | 🔵 Pendiente | 0% | Inicio Fase 3 |
| Fase 5 | 🔵 Pendiente | 0% | Inicio Fase 4 |

**Overall Progress**: ███░░░░░░░ **28%**

---

## 📚 Documentación Relacionada

- **Análisis Exhaustivo**: `Phase2_Analysis/ANALISIS_EXHAUSTIVO_BD_SELEMTI.md`
- **Fase 1 Completada**: `Phase1_Initial/REPORTE_NORMALIZACION_FINAL_20251030.md`
- **Scripts Fase 1**: `Phase1_Initial/01-04*.sql`
- **Catálogos**: `Phase2_Analysis/01-03*.txt`

---

## ✅ Siguiente Paso Inmediato

**AHORA**: Generar scripts SQL para Phase 2.1 (Consolidar Usuarios)

**Comando**:
```bash
# Ejecutar cuando esté listo:
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/Normalizacion/Phase2_Scripts/05_consolidar_usuarios.sql
```

---

**Mantenido por**: Claude Code AI + Equipo TerrenaLaravel
**Última revisión**: 30 de octubre de 2025
