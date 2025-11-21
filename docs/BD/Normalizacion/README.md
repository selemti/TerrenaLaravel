# 📘 Normalización y Mejoras de Base de Datos - TerrenaLaravel

**Proyecto**: Conversión a ERP Enterprise Grade
**Fecha inicio**: 30 de octubre de 2025
**Estado**: 🟡 En Progreso (Phase 1 Completada ✅)

---

## 🎯 Objetivo

Transformar el esquema `selemti` de PostgreSQL 9.5 en un sistema de base de datos de clase enterprise para un ERP de restaurantes de alto nivel, con:

- ✅ Integridad referencial completa (100%)
- ✅ Auditoría universal
- ✅ Performance optimizado (<100ms queries)
- ✅ Escalabilidad multi-tenant
- ✅ Zero datos huérfanos

---

## 📊 Estado Actual

| Métrica | Actual | Objetivo | Progreso |
|---------|--------|----------|----------|
| **Fase completada** | 1 de 5 | 5 de 5 | ████░░░░░░ 40% |
| **FKs completas** | 55% | 100% | ████░░░░░░ 40% |
| **Auditoría** | 30% | 100% | ███░░░░░░░ 30% |
| **Performance** | 70% | 95% | ██████░░░░ 60% |

---

## 📁 Estructura de Documentación

```
docs/BD/Normalizacion/
├── README.md (este archivo)
├── PLAN_ACCION_EJECUTIVO.md ← Plan general y timeline
│
├── Phase1_Initial/ (✅ COMPLETADA)
│   ├── reporte_checks_normalizacion_20251030.md
│   ├── REPORTE_NORMALIZACION_FINAL_20251030.md
│   ├── 01_consolidar_unidades_selemti.sql
│   ├── 02_fix_inventory_snapshot_type.sql
│   ├── 03_add_missing_fks_selemti.sql
│   └── 04_verify_normalizacion.sql
│
├── Phase2_Analysis/ (🟡 EN PROGRESO)
│   ├── ANALISIS_EXHAUSTIVO_BD_SELEMTI.md ← Análisis detallado
│   ├── 01_table_catalog.txt
│   ├── 02_constraints_catalog.txt
│   └── 03_indexes_catalog.txt
│
├── Phase3_Improvements/ (⏭️ PENDIENTE)
│   ├── 05_consolidar_usuarios.sql
│   ├── 06_consolidar_sucursales.sql
│   ├── 07_consolidar_almacenes.sql
│   ├── 08_consolidar_items.sql
│   ├── 09_consolidar_recetas.sql
│   ├── 10_fix_type_incompatibilities.sql
│   ├── 11_add_remaining_fks.sql
│   ├── 12_add_audit_fields.sql
│   ├── 13_add_strategic_indexes.sql
│   └── 14_partition_historical_tables.sql
│
├── Scripts/ (Scripts de utilidad)
│   ├── verify_all.sql
│   ├── rollback_phase2.sql
│   ├── rollback_phase3.sql
│   └── health_check.sql
│
└── Reports/ (Reportes generados)
    ├── performance_before_after.md
    ├── data_migration_summary.md
    └── final_verification_report.md
```

---

## 📖 Guía de Lectura

### 🚀 Empezar Aquí

**Si eres nuevo en el proyecto**:
1. Lee el **PLAN_ACCION_EJECUTIVO.md** para entender el panorama general
2. Lee **Phase2_Analysis/ANALISIS_EXHAUSTIVO_BD_SELEMTI.md** para los detalles técnicos
3. Revisa **Phase1_Initial/REPORTE_NORMALIZACION_FINAL_20251030.md** para ver qué ya está hecho

**Si vas a trabajar en implementación**:
1. Revisa la fase correspondiente en el Plan de Acción
2. Lee los scripts SQL con comentarios detallados
3. Ejecuta los scripts de verificación antes y después

**Si necesitas rollback**:
1. Ve a `Scripts/rollback_phase{N}.sql`
2. Sigue las instrucciones en el header del script
3. Verifica con `Scripts/health_check.sql`

---

## 🎯 Fases del Proyecto

### ✅ Fase 1: Fundamentos (COMPLETADA)
**Duración**: 1 día
**Estado**: 100% Completada

**Logros**:
- ✅ Consolidación de unidades de medida
- ✅ Corrección tipo `inventory_snapshot.item_id`
- ✅ FKs críticas añadidas (3)
- ✅ Vistas de compatibilidad

**Documentación**:
- `Phase1_Initial/REPORTE_NORMALIZACION_FINAL_20251030.md`

---

### 🟡 Fase 2: Consolidación de Sistemas (EN PREPARACIÓN)
**Duración estimada**: 3-4 semanas
**Estado**: Scripts en generación

**Objetivos**:
1. Consolidar `usuario` → `users`
2. Consolidar `sucursal` → `cat_sucursales`
3. Consolidar `bodega/almacen` → `cat_almacenes`
4. Consolidar `insumo` → `items`
5. Consolidar `receta` → `receta_cab`

**Documentación**:
- `Phase2_Analysis/ANALISIS_EXHAUSTIVO_BD_SELEMTI.md`
- `PLAN_ACCION_EJECUTIVO.md` (sección Fase 2)

---

### ⏭️ Fase 3: Integridad y Auditoría (PENDIENTE)
**Duración estimada**: 2-3 semanas

**Objetivos**:
- Corregir incompatibilidades de tipos
- Añadir FKs faltantes (~15)
- Auditoría universal (created_at, updated_at, etc.)
- Soft deletes

---

### ⏭️ Fase 4: Optimización Performance (PENDIENTE)
**Duración estimada**: 2 semanas

**Objetivos**:
- 25 índices estratégicos
- Particionamiento de tablas históricas
- Query optimization
- 95% queries <100ms

---

### ⏭️ Fase 5: Funcionalidades Enterprise (PENDIENTE)
**Duración estimada**: 3-4 semanas

**Objetivos**:
- Multi-tenant architecture
- Event sourcing
- Data warehouse para reporting

---

## 🛠️ Cómo Ejecutar Scripts

### Requisitos Previos
```bash
# 1. Hacer backup
pg_dump -h localhost -p 5433 -U postgres -d pos > backup_$(date +%Y%m%d).sql

# 2. Verificar conexión
psql -h localhost -p 5433 -U postgres -d pos -c "SELECT version();"
```

### Ejecutar Script de Fase
```bash
# Fase 1 (ejemplo - ya ejecutada)
psql -h localhost -p 5433 -U postgres -d pos -f Phase1_Initial/01_consolidar_unidades_selemti.sql

# Fase 2 (cuando esté lista)
psql -h localhost -p 5433 -U postgres -d pos -f Phase3_Improvements/05_consolidar_usuarios.sql
```

### Verificar Resultado
```bash
# Verificación general
psql -h localhost -p 5433 -U postgres -d pos -f Scripts/verify_all.sql

# Health check
psql -h localhost -p 5433 -U postgres -d pos -f Scripts/health_check.sql
```

### Rollback (si es necesario)
```bash
# Rollback de fase específica
psql -h localhost -p 5433 -U postgres -d pos -f Scripts/rollback_phase2.sql

# O restaurar backup completo
psql -h localhost -p 5433 -U postgres -d pos < backup_20251030.sql
```

---

## 📊 Problemas Identificados

### 🔴 Críticos (Resolver en Fase 2)
1. **Sistemas duplicados** - usuario/users, sucursal/cat_sucursales, etc.
2. **6 tablas de unidades** - Consolidar en 1 tabla canónica (✅ ya hecho)
3. **Incompatibilidad de tipos** - 7 casos detectados

### 🟠 Altos (Resolver en Fase 3)
4. **FKs faltantes** - ~15 tablas sin integridad referencial
5. **PKs complejas** - pos_map con 4 columnas en PK
6. **Campos redundantes** - ~12 campos calculables

### 🟡 Medios (Resolver en Fase 4)
7. **Índices faltantes** - ~25 índices estratégicos necesarios
8. **Sin auditoría** - 70% de tablas sin tracking
9. **Performance** - 15% de queries >1s

---

## 📈 Métricas de Éxito

### Objetivos Cuantitativos

| KPI | Baseline | Meta | Actual |
|-----|----------|------|--------|
| FKs completas | 55% | 100% | 58% |
| Datos huérfanos | 5% | 0% | 4% |
| Queries <100ms | 70% | 95% | 72% |
| Tablas con auditoría | 30% | 100% | 32% |
| Downtime por deploy | 30min | 0min | 25min |

### Objetivos Cualitativos
- [ ] Código backend simplificado (menos if/else por tabla legacy)
- [ ] Confianza en datos (integridad garantizada)
- [ ] Escalabilidad probada (50+ sucursales)
- [ ] Documentación completa (100% tablas documentadas)

---

## 👥 Equipo y Responsabilidades

| Rol | Responsabilidad | Tiempo |
|-----|----------------|--------|
| **Backend Lead** | Coordinación general, review scripts | 40h/sem |
| **DBA PostgreSQL** | Escritura scripts SQL, tuning | 30h/sem |
| **QA Engineer** | Tests, validación integridad | 20h/sem |
| **DevOps** | Staging, deploy, monitoring | 10h/sem |

---

## ⚠️ Riesgos y Mitigaciones

### Top 3 Riesgos

| Riesgo | Impacto | Prob | Mitigación |
|--------|---------|------|------------|
| **R1: Downtime prolongado** | Alto | Media | Ventanas mantenimiento + rollback tested |
| **R2: Pérdida de datos** | Crítico | Baja | Backups múltiples + dry-run staging |
| **R3: Breaking changes en código** | Medio | Alta | Vistas compatibilidad + feature flags |

---

## 📞 Contacto y Soporte

**Documentación mantenida por**: Claude Code AI + Equipo TerrenaLaravel

**Para preguntas**:
- Revisar primero el `PLAN_ACCION_EJECUTIVO.md`
- Luego el `ANALISIS_EXHAUSTIVO_BD_SELEMTI.md`
- Si aún hay dudas, consultar con Backend Lead

---

## 📅 Timeline

```
Octubre 2025
└── Semana 4: ✅ Fase 1 completada

Noviembre 2025
├── Semana 1: 🟡 Fase 2.1 (Usuarios)
├── Semana 2: ⏭️ Fase 2.2 (Sucursales/Almacenes)
├── Semana 3: ⏭️ Fase 2.3 (Items)
└── Semana 4: ⏭️ Fase 2.4 (Recetas)

Diciembre 2025
├── Semana 1-2: ⏭️ Fase 3 (Integridad)
└── Semana 3-4: ⏭️ Fase 4 (Performance)

Enero 2026
└── Semana 1-4: ⏭️ Fase 5 (Enterprise Features)
```

---

## 🚀 Próximos Pasos

### Inmediatos (Esta Semana)
1. [ ] Revisar y aprobar análisis exhaustivo
2. [ ] Generar scripts SQL para Fase 2.1
3. [ ] Setup staging environment
4. [ ] Plan de testing

### Corto Plazo (Próximas 2 Semanas)
5. [ ] Ejecutar Fase 2.1 (Usuarios)
6. [ ] Ejecutar Fase 2.2 (Sucursales)
7. [ ] Verificación de integridad

### Mediano Plazo (1-2 Meses)
8. [ ] Completar Fase 2 completa
9. [ ] Iniciar Fase 3
10. [ ] Performance baseline

---

## ✅ Checklist de Inicio

Antes de ejecutar cualquier script de mejora:

- [ ] Backup de base de datos creado
- [ ] Staging environment funcionando
- [ ] Scripts revisados por DBA
- [ ] Plan de rollback documentado
- [ ] Tests de integridad preparados
- [ ] Ventana de mantenimiento coordinada
- [ ] Equipo notificado
- [ ] Monitoring activo

---

## 📚 Referencias

- **PostgreSQL 9.5 Docs**: https://www.postgresql.org/docs/9.5/
- **Laravel 12 Database**: https://laravel.com/docs/12.x/database
- **Livewire 3**: https://livewire.laravel.com/docs/3.x

---

**Última actualización**: 30 de octubre de 2025
**Versión del documento**: 1.0
**Estado del proyecto**: 🟡 En Progreso (28% completado)
