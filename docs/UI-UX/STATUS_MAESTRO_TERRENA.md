# Plan de Acción Ejecutivo - TerrenaLaravel ERP
**Proyecto**: TerrenaLaravel - Conversión a ERP Restaurantes Enterprise Grade
**Fecha**: 30 de octubre de 2025
**Estado**: En Progreso (Planificación Completa ✅)

---

## 🎯 Objetivo

Transformar TerrenaLaravel de un sistema funcional pero fragmentado a un **ERP de restaurantes de clase enterprise** con:


- ✅ Arquitectura modular y escalable
- ✅ UI/UX profesional y eficiente
- ✅ Procesos automatizados
- ✅ Integración completa entre módulos
- ✅ Zero downtime deployments

---

## 📊 Estado Actual vs Objetivo

| Módulo | Backend Completitud | Frontend Completitud | Objetivo | Progreso |
|--------|-------------------|-------------------|----------|----------|
| Inventario | 70% | 70% | 95% | ████████░░ 70% |
| Compras | 60% | 60% | 95% | ██████░░░░ 60% |
| Recetas | 50% | 50% | 95% | █████░░░░░ 50% |
| Producción | 30% | 30% | 90% | ███░░░░░░░ 30% |
| Caja Chica | 80% | 80% | 90% | ████████░░ 80% |
| Reportes | 40% | 40% | 90% | ████░░░░░░ 40% |
| Catálogos | 80% | 80% | 98% | ████████░░ 80% |
| Permisos | 80% | 80% | 98% | ████████░░ 80% |

**Overall Progress**: ██████░░░░ **60%**

---

## 🚀 Fases de Implementación

### ✅ FASE 1: Consolidación de Documentación (COMPLETADA)
**Duración**: 1 día
**Estado**: ✅ 100% Completada

#### Logros:
1. ✅ Definiciones de módulos consolidadas en `docs/UI-UX/definición/`
2. ✅ Status actual de cada módulo documentado
3. ✅ Identificación de gaps técnicos y funcionales
4. ✅ Creación de este plan maestro

#### Documentación Generada:
- ✅ `docs/UI-UX/Status/STATUS_Inventario.md` - Completitud 70%
- ✅ `docs/UI-UX/Status/STATUS_Compras.md` - Completitud 60%
- ✅ `docs/UI-UX/Status/STATUS_Recetas.md` - Completitud 50%
- ✅ `docs/UI-UX/Status/STATUS_Producción.md` - Completitud 30%
- ✅ `docs/UI-UX/Status/STATUS_CajaChica.md` - Completitud 80%
- ✅ `docs/UI-UX/Status/STATUS_Reportes.md` - Completitud 40%
- ✅ `docs/UI-UX/Status/STATUS_Catálogos.md` - Completitud 80%
- ✅ `docs/UI-UX/Status/STATUS_Permisos.md` - Completitud 80%

---

### 🟡 FASE 2: Foundation & Design System (EN PREPARACIÓN)
**Duración**: 2 semanas
**Estado**: 🟡 Scripts en generación

#### Objetivo:
Crear base sólida de componentes y design system para UI/UX consistente en todos los módulos.

#### Submódulos:

##### **2.1 Design System** (Semana 1)
**Componentes a crear**:
- `<x-button>`
- `<x-input>`
- `<x-select>`
- `<x-datepicker>`
- `<x-modal>`
- `<x-toast>`
- `<x-card>`
- `<x-table>`
- `<x-empty-state>`
- `<x-loading-skeleton>`

**Trabajo**:
1. Crear componentes Blade reusables
2. Configurar paleta de colores consistente
3. Definir tipografía y espaciado
4. Documentar uso con ejemplos
5. Tests de componentes críticos

**Impacto**: Muy Alto - Base de toda la UI
**Riesgo**: Bajo - No afecta backend
**Rollback**: Fácil - Componentes Blade

##### **2.2 Sistema de Validación Unificado** (Semana 1)
**Componentes afectados**:
- Validación inline con Alpine.js
- Mensajes de error consistentes
- Highlight de campos con error
- Tooltips de ayuda

**Trabajo**:
1. Validación inline con Alpine.js
2. Mensajes de error consistentes
3. Highlight de campos con error
4. Tooltips de ayuda
5. Tests de UX

**Impacto**: Alto - Afecta todos los forms
**Riesgo**: Medio - Cambios en UX
**Rollback**: Moderado - Cambios en Livewire

##### **2.3 Sistema de Notificaciones** (Semana 1)
**Componentes afectados**:
- Toast notifications (éxito/error/warning/info)
- Alpine.js store para toasts
- Auto-dismiss configurable

**Trabajo**:
1. Implementar toast notifications
2. Alpine.js store para toasts
3. Auto-dismiss configurable
4. Tests de UX

**Impacto**: Medio - Mejora UX
**Riesgo**: Bajo - No crítico
**Rollback**: Fácil - Componentes JS

##### **2.4 Frontend Completado** (Semana 2)
**Componentes afectados**:
- Actualización de todos los componentes Livewire existentes
- Implementación del design system
- Mejoras de UX

**Trabajo**:
1. Actualizar componentes existentes con design system
2. Implementar validación inline
3. Agregar sistema de notificaciones
4. Tests de funcionalidad

**Impacto**: CRÍTICO - UI completa del sistema
**Riesgo**: Medio - Cambios visibles para usuarios
**Rollback**: Moderado - Cambios extensos

#### Entregables Fase 2:
- [ ] 10+ componentes Blade reusables
- [ ] Documentación de design system
- [ ] Sistema de validación inline funcionando
- [ ] Sistema de notificaciones operativo
- [ ] Todos los componentes Livewire actualizados

---

### 🟡 FASE 3: Inventario Sólido (EN PREPARACIÓN)
**Duración**: 2 semanas
**Estado**: 🟡 Planificación

#### Objetivo:
Inventario con funcionalidades completas y UX profesional.

#### Submódulos:

##### **3.1 Alta de Ítems (Wizard 2 Pasos)** (Semana 1)
**Componentes afectados**:
- `Inventory/ItemsManage.php` → Actualizado
- `Inventory/InsumoCreate.php` → Rediseñado

**Trabajo**:
1. Paso 1: Datos maestros (nombre, categoría, UOM base)
2. Paso 2: Presentaciones/Proveedor (opcional)
3. Validación inline por campo
4. Preview de código CAT-SUB-##### antes de guardar
5. Botón "Crear y seguir con presentaciones"
6. Auto-sugerencias de nombres normalizados

**Impacto**: Alto - Funcionalidad crítica
**Riesgo**: Bajo - Mejora UX sin cambio lógica
**Rollback**: Fácil - Componente Livewire

##### **3.2 Proveedor-Insumo (Presentaciones)** (Semana 1)
**Componentes afectados**:
- `Inventory/ItemsManage.php` - Actualizado
- Nueva funcionalidad de presentaciones

**Trabajo**:
1. CRUD completo de proveedor-presentación
2. Plantilla rápida desde recepción
3. Auto-conversión UOM base ↔ compra
4. Tooltip mostrando factor de conversión

**Impacto**: Medio - Afecta compras
**Riesgo**: Bajo - Nueva funcionalidad
**Rollback**: Fácil - Componente Livewire

##### **3.3 Recepciones Posteables** (Semana 2)
**Componentes afectados**:
- `Inventory/ReceptionsIndex.php` - Actualizado
- `Inventory/ReceptionCreate.php` - Actualizado
- `Inventory/ReceptionDetail.php` - Actualizado

**Trabajo**:
1. Estados: Pre-validada → Aprobada → Posteada
2. Snapshot de costo al postear
3. Adjuntos múltiples (drag & drop)
4. Tolerancias de qty con control de discrepancias
5. Genera `mov_inv` automáticamente

**Impacto**: CRÍTICO - Proceso fundamental
**Riesgo**: Medio - Afecta stock
**Rollback**: Moderado - Lógica compleja

##### **3.4 UOM Assistant** (Semana 2)
**Componentes afectados**:
- `Catalogs/UomConversionIndex.php` - Actualizado

**Trabajo**:
1. Creación inversa automática (si creo kg→g, crear g→kg)
2. Validación de circularidad
3. Preview de conversión

**Impacto**: Medio - Mejora UX
**Riesgo**: Bajo - Funcionalidad auxiliar
**Rollback**: Fácil - Componente Livewire

#### Entregables Fase 3:
- [ ] Wizard de ítems funcional
- [ ] Recepciones con snapshot de costo
- [ ] UOM con conversiones automáticas
- [ ] Tests de integración
- [ ] Documentación de procesos

---

### ⏭️ FASE 4: Replenishment + Políticas (PENDIENTE)
**Duración**: 3-4 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
Motor de sugerencias de pedidos completo con políticas de stock configurables y motor de reposición.

#### Submódulos:

##### **4.1 UI de Políticas de Stock** (Semana 1)
**Componentes afectados**:
- `Catalogs/StockPolicyIndex.php` - Rediseñado

**Trabajo**:
1. CRUD por ítem/sucursal
2. Campos: Stock mínimo, Stock máximo, Safety stock, Lead time, Método de replenishment
3. Bulk import CSV
4. Export template

**Impacto**: Alto - Corazón del negocio
**Riesgo**: Medio - Lógica compleja
**Rollback**: Moderado - Funcionalidad crítica

##### **4.2 Motor de Replenishment** (Semana 2-4)
**Componentes afectados**:
- `ReplenishmentService.php` - Completado
- `Replenishment/Dashboard.php` - Actualizado

**Trabajo**:
1. Método 1: Min-Max básico
2. Método 2: Simple Moving Average (SMA)
3. Método 3: Consumo POS (últimos n días)
4. Integración con POS (read-only desde `public.*`)
5. Validación: considerar órdenes pendientes
6. Cálculo de cobertura (días)

**Impacto**: CRÍTICO - Corazón del valor de negocio
**Riesgo**: Alto - Lógica compleja
**Rollback**: Complejo - Motor central

##### **4.3 UI de Pedidos Sugeridos** (Semana 4)
**Componentes afectados**:
- `Replenishment/Dashboard.php` - Completado
- Nuevos endpoints API

**Trabajo**:
1. Botón "Generar Sugerencias"
2. Grilla editable con: Ítem, Stock actual, Stock min/max, Consumo promedio, Qty sugerida, Cobertura (días), Razón del cálculo
3. Filtros: sucursal, categoría, proveedor
4. Conversión 1-click: Sugerencia → Solicitud → Orden

**Impacto**: Alto - UI principal
**Riesgo**: Medio - Procesamiento complejo
**Rollback**: Moderado - Componente complejo

#### Entregables Fase 4:
- [ ] Motor de replenishment completo
- [ ] Políticas de stock configurables
- [ ] UI de sugerencias con razón del cálculo
- [ ] Jobs de procesamiento asincrónico
- [ ] Tests de motor con múltiples métodos

---

### ⏭️ FASE 5: Recetas + Versionado + Costos Pro (PENDIENTE)
**Duración**: 2 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
Recetas con versionado automático y snapshots de costo con sistema de alertas.

#### Trabajo Principal:
1. Versionado de recetas automático
2. Snapshots de costo automáticos
3. Alertas de costo con umbral configurable
4. Simulador de impacto
5. Comparación teórico vs real

#### Entregables:
- [ ] Versionado automático de recetas
- [ ] Snapshots de costo funcionando
- [ ] Alertas de costo operativas
- [ ] Simulador de impacto funcional
- [ ] Tests de costos

---

### ⏭️ FASE 6: Producción UI Operativa (PENDIENTE)
**Duración**: 1-2 semanas
**Estado**: 🔵 Planificación

#### Objetivo:
UI operativa completa para órdenes de producción con control de rendimiento y mermas.

#### Trabajo Principal:
1. Planificación por demanda (ventas POS), stock objetivo o calendario
2. Consumo teórico vs real
3. KPIs de producción (rendimiento, merma, costo por batch)
4. Cierre de OP con posteo a inventario

#### Entregables:
- [ ] UI operativa de producción completa
- [ ] Dashboard de KPIs funcionando
- [ ] Control de rendimiento y mermas
- [ ] Tests de producción

---

### ⏭️ FASE 7: Reportes + Quick Wins (PENDIENTE)
**Duración**: 1 semana
**Estado**: 🔵 Planificación

#### Objetivo:
Reportes exportables y quick wins de alto impacto para usuarios finales.

#### Trabajo Principal:
1. Export de reportes (CSV/PDF)
2. Drill-down en dashboard
3. Búsqueda global (Ctrl+K)
4. Acciones en lote

#### Entregables:
- [ ] Exports CSV/PDF funcionando
- [ ] Búsqueda global Ctrl+K
- [ ] Acciones en lote en tablas
- [ ] Tests de reportes

---

## 📅 Timeline General

```
Noviembre 2025
├── Semana 1: Phase 2.1-2.3 (Design System)
├── Semana 2: Phase 2.4 (Frontend Completado)
├── Semana 3: Phase 3.1-3.2 (Alta de Ítems + Presentaciones)
└── Semana 4: Phase 3.3-3.4 (Recepciones + UOM Assistant)

Diciembre 2025
├── Semana 1-2: Phase 4 (Replenishment)
├── Semana 3: Phase 5 (Recetas + Versionado)
└── Semana 4: Phase 6 (Producción UI)

Enero 2026
├── Semana 1: Phase 7 (Reportes + Quick Wins)
└── Semana 2: Testing final + Go Live
```

**Duración total estimada**: **10 semanas**

---

## 🎯 Métricas de Éxito (KPIs)

### UX
- [ ] 95% de tareas críticas <3 clicks (actual: ~60%)
- [ ] Validación inline en 100% de formularios
- [ ] Tiempo medio de tarea -30%
- [ ] 90% de usuarios satisfechos (NPS)

### Funcionalidad
- [ ] 100% de módulos con UI completa (actual: ~60%)
- [ ] 95% de endpoints con cobertura API (actual: ~75%)
- [ ] 0 procesos manuales críticos
- [ ] 100% de integración entre módulos

### Performance
- [ ] 95% de UI <2s carga (actual: ~70%)
- [ ] 95% de API <100ms (actual: ~70%)
- [ ] Zero downtime deployments
- [ ] 99.5% uptime

### Adopción
- [ ] 90% de usuarios usando nueva UI
- [ ] Zero resistencia al cambio
- [ ] Feedback positivo >80%

---

## ⚠️ Riesgos Identificados

### Riesgo Alto (R1-R2)
| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|----|--------|---------|--------------|------------|
| R1 | Resistencia al cambio UI | Medio | Media | Capacitación + gradual transition |
| R2 | Performance degradation | Alto | Baja | Testing carga + monitoreo |

### Riesgo Medio (R3-R5)
| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|----|--------|---------|--------------|------------|
| R3 | Complejidad técnica | Medio | Media | POCs + arquitectura modular |
| R4 | Integración módulos | Medio | Media | API clara + testing |
| R5 | Atraso en entregas | Medio | Media | Sprints cortos + tracking |

---

## 📦 Entregables por Fase

### Fase 1 (Completada ✅)
- [x] Definiciones de módulos
- [x] Status actual de cada módulo
- [x] Plan de acción ejecutivo
- [x] Este documento maestro

### Fase 2 (En Preparación 🟡)
- [ ] Design system completo
- [ ] Componentes reusables
- [ ] Validación inline
- [ ] Sistema de notificaciones

### Fase 3-7 (Pendiente 🔵)
- [ ] UI completa de inventario
- [ ] Motor de replenishment
- [ ] Versionado de recetas
- [ ] UI de producción
- [ ] Reportes completos

---

## 👥 Equipo Necesario

**Roles**:
- **Frontend Lead** (30h/semana) - Coordinación UI/UX
- **Backend Lead** (20h/semana) - Lógica de negocio
- **UI/UX Designer** (15h/semana) - Experiencia de usuario
- **QA Engineer** (20h/semana) - Tests + validación

**Total horas estimadas**: **3,500 horas** (4 personas x 10 semanas x 87.5h promedio)

---

## 💰 Presupuesto Estimado

| Concepto | Costo Mensual | Total |
|----------|---------------|-------|
| Infraestructura staging | $200 | $2,000 |
| Herramientas (testing, CI/CD) | $150 | $1,500 |
| Capacitación equipo | - | $2,000 |
| **Total** | **$350/mes** | **$5,500** |

*No incluye costos de personal (in-house)*

---

## 📞 Puntos de Decisión

### Decisión 1: ¿Iniciar Fase 2?
**Fecha límite**: 5 de noviembre de 2025
**Requisitos previos**:
- ✅ Phase 1 completada
- ⏳ Equipo asignado
- ⏳ Plan de implementación aprobado

### Decisión 2: ¿Go/No-Go Production?
**Fecha límite**: Fin de Fase 7
**Criterios**:
- [ ] Todos los tests pasados
- [ ] Performance aceptable
- [ ] UX testeada con usuarios
- [ ] Sign-off de stakeholders

---

## 🚦 Estado Actual del Plan

**Última actualización**: 30 de octubre de 2025

| Fase | Estado | Progreso | Próximo Hito |
|------|--------|----------|--------------|
| Fase 1 | ✅ Completada | 100% | - |
| Fase 2 | 🟡 Preparación | 10% | Design System completado |
| Fase 3 | 🔵 Pendiente | 0% | Inicio Fase 2 |
| Fase 4 | 🔵 Pendiente | 0% | Inicio Fase 3 |
| Fase 5 | 🔵 Pendiente | 0% | Inicio Fase 4 |
| Fase 6 | 🔵 Pendiente | 0% | Inicio Fase 5 |
| Fase 7 | 🔵 Pendiente | 0% | Inicio Fase 6 |

**Overall Progress**: ██████░░░░ **60%**

---

## 📚 Documentación Relacionada

- **Definiciones Módulos**: `docs/UI-UX/Definiciones/*.md` (detalles funcionales por módulo)
- **Status Módulos**: `docs/UI-UX/Status/*.md` (estado actual de backend/frontend por módulo)
- **Documentación Maestra**: `docs/UI-UX/MASTER/` (estructura completa del proyecto)
- **Fase 1 Completada**: Este documento
- **UI/UX Specs**: `docs/UI-UX/ANALISIS_PROYECTO_ACTUAL.md`
- **Plan Maestro**: `docs/UI-UX/PLAN_MAESTRO_UI_UX_ENTERPRISE.md`

---

## ✅ Siguiente Paso Inmediato

**AHORA**: Iniciar Fase 2 - Foundation & Design System

**Comando**:
```bash
# Empezar con diseño de componentes base
cd resources/views/components && mkdir -p ui forms tables
# Crear componentes reusables
```

---

**Mantenido por**: Equipo TerrenaLaravel
**Última revisión**: 30 de octubre de 2025